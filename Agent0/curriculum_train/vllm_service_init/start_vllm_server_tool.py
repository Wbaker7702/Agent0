#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
This script enhances the LLM's problem-solving capabilities by integrating a code execution tool.
It processes each question through a multi-turn conversational approach, allowing the model to generate, execute, and reason based on code output.
The generation process for each of the 10 candidates is now a stateful, iterative loop.

Setup Instructions:
    # 1. Install required libraries
    pip install stopit flask vllm transformers torch requests

    # 2. Ensure the code execution sandbox API is running and accessible.

    # 3. Run the server
    python your_server_file_name.py --port 5000 --model_path Qwen/Qwen3-4B-Base
"""

from flask import Flask, request, jsonify
import vllm
import argparse
import json
import os
import threading
import time
import torch
from transformers import AutoTokenizer
from mathruler.grader import extract_boxed_content, grade_answer
import stopit
import requests
import re
from concurrent.futures import ThreadPoolExecutor
from tqdm import tqdm

# ---------------------------- Code Execution Tool --------------------------- #

SANDBOX_API_URLS = [
    "IP1:PORT1/run_code",
    "IP2:PORT2/run_code",
    "IP3:PORT3/run_code",
    "IP4:PORT4/run_code",
]

api_counter_lock = threading.Lock()
api_counter = 0


def execute_code_in_sandbox(code: str) -> str:
    """
    Calls an external sandbox API to execute Python code, with load balancing.
    """
    global api_counter
    with api_counter_lock:
        target_url = SANDBOX_API_URLS[api_counter % len(SANDBOX_API_URLS)]
        api_counter += 1

    try:
        payload = {"code": code, "language": "python"}
        headers = {"Content-Type": "application/json"}
        response = requests.post(
            target_url, headers=headers, data=json.dumps(payload), timeout=20
        )
        response.raise_for_status()
        result = response.json()

        if result.get("status") == "Success" and result.get("run_result"):
            run_info = result["run_result"]
            if run_info.get("status") == "Finished":
                stdout = run_info.get("stdout", "")
                return stdout if stdout else "[No output]"
            else:
                stderr = run_info.get("stderr", "")
                return f"Execution failed with status: {
                    run_info.get('status')}\nStderr: {stderr}"
        else:
            return f"API Error: {result}"
    except Exception as e:
        return f"Execution Error: {e}"


# ---------------------------- Initial Setup --------------------------------- #

parser = argparse.ArgumentParser()
parser.add_argument("--port", type=str, default="5000")
parser.add_argument("--model_path", type=str, default="Qwen/Qwen3-4B-Base")
parser.add_argument(
    "--gpu_mem_util",
    type=float,
    default=0.8,
    help="The maximum GPU memory utilization fraction for vLLM.",
)
args = parser.parse_args()


print("[init] Loading model...")
tokenizer = AutoTokenizer.from_pretrained(args.model_path)
model = vllm.LLM(
    model=args.model_path,
    tokenizer=args.model_path,
    gpu_memory_utilization=args.gpu_mem_util,
)

sampling_params_single_turn = vllm.SamplingParams(
    max_tokens=2048,
    temperature=0.7,
    top_p=0.9,
    n=1,
    stop_token_ids=[tokenizer.eos_token_id],
)

SYSTEM_PROMPT = (
    "Solve the following problem step by step. You now have the ability to selectively write executable Python code to enhance your reasoning process.\n"
    "First, provide your reasoning and write a self-contained Python code block wrapped in ```python ... ``` to help you calculate the answer. You must use the `print()` function to output the results.\n"
    "After you write the code block, STOP. I will execute it for you.\n"
    "I will then provide the output under 'Code execution result:'. You must use this result (even if it's an error) to continue your reasoning and provide the final answer.\n"
    "The final answer must be enclosed in \\boxed{...}."
    "Code Format:\n"
    "Each code snippet is wrapped between ```. You need to use print() to output intermediate results.\n"
    "Answer Format:\n"
    "The last part of your response should be: \\boxed{...}")

# ---------------------------- GPU Idle Worker ------------------- #
stop_event = threading.Event()
pause_event = threading.Event()


def gpu_idle_worker():
    print("[idle_worker] GPU idle worker started.")
    running = True
    while not stop_event.is_set():
        if pause_event.is_set():
            if running:
                running = False
            time.sleep(0.1)
            continue
        else:
            if not running:
                running = True
        try:
            a = torch.rand((2000, 2000), dtype=torch.float32, device="cuda")
            b = torch.rand((2000, 2000), dtype=torch.float32, device="cuda")
            torch.matmul(a, b)
            torch.cuda.synchronize()
        except RuntimeError:
            time.sleep(1)
    print("[idle_worker] GPU idle worker stopped.")


idle_thread = threading.Thread(target=gpu_idle_worker, daemon=True)
idle_thread.start()


# ---------------------------- Core Logic (Refactored) ----------------------- #
@stopit.threading_timeoutable(default="TIMED_OUT")
def grade_answer_with_timeout(res1, res2):
    return grade_answer(res1, res2)


sandbox_executor = ThreadPoolExecutor(max_workers=64)


def generate_with_tool_use(
        question: str,
        num_candidates: int = 10,
        max_turns: int = 4):
    """
    Generates answers using a multi-turn conversation loop (up to max_turns).
    Handles code execution and history updates dynamically.
    """
    # Initialize conversation history for all candidates
    conversations = [
        [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": question},
        ]
        for _ in range(num_candidates)
    ]
    final_assistant_messages = [""] * num_candidates
    active_indices = list(range(num_candidates))

    for turn in range(max_turns):
        if not active_indices:
            break

        # Prepare prompts only for active candidates
        prompts = [
            tokenizer.apply_chat_template(
                conversations[i], tokenize=False, add_generation_prompt=True
            )
            for i in active_indices
        ]

        # Batch generate
        responses = model.generate(
            prompts,
            sampling_params_single_turn,
            use_tqdm=False)

        tasks_to_run = []
        indices_with_code = set()

        # Step 1: Process model outputs
        for i, response in enumerate(responses):
            original_index = active_indices[i]
            model_output = response.outputs[0].text.strip()

            # Clean up potential incomplete code blocks
            code_block_start_tag = "```python"
            code_block_end_tag = "```"
            start_index = model_output.find(code_block_start_tag)
            if start_index != -1:
                end_index = model_output.find(
                    code_block_end_tag, start_index + len(code_block_start_tag)
                )
                if end_index != -1:
                    model_output = model_output[: end_index +
                                                len(code_block_end_tag)]

            # Update history
            conversations[original_index].append(
                {"role": "assistant", "content": model_output}
            )

            # Check for Code
            code_match = re.search(
                r"```python\n(.*?)\n```",
                model_output,
                re.DOTALL)

            # Check for Boxed Answer
            has_boxed = r"\boxed" in model_output

            if code_match and not has_boxed:
                # Found code, no final answer yet -> Queue for execution
                code_to_run = (code_match.group(1) or "").strip()
                if code_to_run:
                    future = sandbox_executor.submit(
                        execute_code_in_sandbox, code_to_run
                    )
                    tasks_to_run.append((future, original_index))
                    indices_with_code.add(original_index)
                else:
                    # Empty code block, treat as text step
                    pass
            elif has_boxed:
                # Found answer -> Mark as finished
                final_assistant_messages[original_index] = model_output
            else:
                # Pure text reasoning -> Will continue to next turn if logic requires,
                # or strictly speaking, we keep it active to allow further
                # reasoning.
                pass

        # Step 2: Collect Sandbox Results
        results_map = {}
        for future, idx in tasks_to_run:
            try:
                results_map[idx] = future.result()
            except Exception as e:
                results_map[idx] = f"Sandbox Error: {e}"

        # Step 3: Prepare next turn indices
        next_active_indices = []
        for i, response in enumerate(responses):
            original_index = active_indices[i]

            # If we already found a boxed answer, this candidate is done.
            if final_assistant_messages[original_index]:
                continue

            # If it had code, append result and keep active
            if original_index in indices_with_code:
                exec_result = results_map.get(
                    original_index, "Result not found.")
                tool_feedback = f"Code execution result: {exec_result}"
                conversations[original_index].append(
                    {"role": "user", "content": tool_feedback}
                )
                next_active_indices.append(original_index)

            # If it was just text (and no boxed), we keep it active for the next turn
            # (assuming it needs more steps), unless it was the last turn.
            else:
                next_active_indices.append(original_index)

        active_indices = next_active_indices

    # Fill in any candidates that didn't finish with \boxed with their last
    # output
    for i in range(num_candidates):
        if not final_assistant_messages[i]:
            # Use the last assistant message as the best effort result
            # Traverse backwards to find the last assistant message
            for msg in reversed(conversations[i]):
                if msg["role"] == "assistant":
                    final_assistant_messages[i] = msg["content"]
                    break

    return final_assistant_messages


def consolidate_and_grade(question, golden_answer, assistant_messages):
    """Consolidates and grades LLM outputs for a single question."""
    results = [extract_boxed_content(msg) for msg in assistant_messages]

    answer_counts = {}
    for res in results:
        if not res:
            continue
        matched = False

        for exist_ans in list(answer_counts.keys()):
            if res == exist_ans or (
                "no " in res.lower() and "no " in exist_ans.lower()
            ):
                answer_counts[exist_ans] += 1
                matched = True
                break

            try:
                is_match = False
                match_result_1 = grade_answer_with_timeout(
                    res, exist_ans, timeout=20)
                if match_result_1 and match_result_1 != "TIMED_OUT":
                    is_match = True

                if not is_match:
                    match_result_2 = grade_answer_with_timeout(
                        exist_ans, res, timeout=20
                    )
                    if match_result_2 and match_result_2 != "TIMED_OUT":
                        is_match = True

                if is_match:
                    answer_counts[exist_ans] += 1
                    matched = True
                    break

            except Exception:
                continue

        if not matched:
            answer_counts[res] = 1

    if not answer_counts:
        majority_ans, max_count = "", 0
    else:
        majority_ans = max(answer_counts, key=answer_counts.get)
        max_count = answer_counts[majority_ans]

    score = max_count / len(assistant_messages) if assistant_messages else 0.0

    return {
        "question": question,
        "answer": majority_ans,
        "score": (
            score if grade_answer(
                majority_ans,
                golden_answer) and score > 0.1 else 0),
        "all_outputs": assistant_messages,
        "extracted_results": results,
    }


# ---------------------------- Flask Application --------------------------- #
app = Flask(__name__)


@app.route("/hello", methods=["GET"])
def hello():
    pause_event.set()
    torch.cuda.synchronize()

    name = request.args.get("name", "None")

    with open(name, "r") as f:
        data = json.load(f)
    os.remove(name)

    questions = [item.get("question", "") for item in data]
    answers = [item.get("answer", "") for item in data]

    results_all = []

    # Using TQDM for clean progress visualization
    progress_bar = tqdm(
        zip(questions, answers),
        total=len(questions),
        desc=f"Processing {os.path.basename(name)}",
    )

    for q, a in progress_bar:
        try:
            if q and a:
                # Multi-turn generation
                final_assistant_messages = generate_with_tool_use(
                    q, max_turns=4)

                # Consolidate and Grade
                item = consolidate_and_grade(q, a, final_assistant_messages)
                results_all.append(item)
            else:
                results_all.append(
                    {
                        "question": q,
                        "answer": a,
                        "score": -1,
                        "all_outputs": [],
                        "extracted_results": [],
                    }
                )
        except Exception as e:
            # Only printing critical errors to not mess up TQDM too much
            print(f"\n[server] Error processing question: {str(e)}")
            results_all.append(
                {
                    "question": q,
                    "answer": a,
                    "score": -1,
                    "error": f"unhandled exception: {str(e)}",
                }
            )

    out_path = name.replace(".json", "_results.json")
    with open(out_path, "w") as f:
        json.dump(results_all, f, indent=4)

    pause_event.clear()
    return jsonify(
        {"message": f"Processed {name}, results saved to {out_path}."})


# ------------------------- Main Application Entrypoint --------------------------- #
if __name__ == "__main__":
    try:
        app.run(host="127.0.0.1", port=int(args.port), threaded=True)
    finally:
        stop_event.set()
        if idle_thread.is_alive():
            idle_thread.join()
        print("[main] Application shutdown complete.")
