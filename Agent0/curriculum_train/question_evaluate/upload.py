import argparse
import json
import os
import sys

from datasets import Dataset

try:
    STORAGE_PATH = os.environ["STORAGE_PATH"]
    print(f"STORAGE_PATH is: {STORAGE_PATH}", file=sys.stderr)
except KeyError:
    print("Error: STORAGE_PATH environment variable not set.", file=sys.stderr)
    sys.exit(1)


parser = argparse.ArgumentParser()
parser.add_argument("--max_score", type=float, default=0.7)
parser.add_argument("--min_score", type=float, default=0.3)
parser.add_argument(
    "--experiment_name",
    type=str,
    default="Qwen_Qwen3-4B-Base_all")
args = parser.parse_args()

datas = []
for i in range(8):
    file_path = (
        f"{STORAGE_PATH}/generated_question/{args.experiment_name}_{i}_results.json"
    )
    try:
        with open(file_path, "r") as f:
            data = json.load(f)
            datas.extend(data)
    except FileNotFoundError:
        print(
            f"Warning: File {file_path} not found, skipping.",
            file=sys.stderr)
        continue

print("Cleaning up temporary JSON files...", file=sys.stderr)
for i in range(8):
    file_path = (
        f"{STORAGE_PATH}/generated_question/{args.experiment_name}_{i}_results.json"
    )
    try:
        os.remove(file_path)
    except FileNotFoundError:
        pass

filtered_datas = [
    {"problem": data["question"], "answer": data["answer"], "score": data["score"]}
    for data in datas
    if args.min_score <= data.get("score", 0) <= args.max_score and data.get("answer")
]

print(f"Filtered down to {len(filtered_datas)} samples.", file=sys.stderr)

if filtered_datas:
    train_dataset = Dataset.from_list(filtered_datas)

    save_dir = f"{STORAGE_PATH}/generated_question/{args.experiment_name}"
    os.makedirs(save_dir, exist_ok=True)

    save_path = f"{save_dir}/train.parquet"

    train_dataset.to_parquet(save_path)

    print(save_path)
else:
    print("Warning: No data to save after filtering.", file=sys.stderr)
