import requests
import json
import re

SANDBOX_API_URL = "http://172.22.1.105:8080/run_code"


def execute_code_in_sandbox(code: str) -> str:
    """
    调用外部沙盒API执行Python代码。

    Args:
        code: 从模型输出中提取的纯Python代码字符串。

    Returns:
        执行结果（stdout），如果出错则返回错误信息。
    """
    payload = {"code": code, "language": "python"}
    headers = {"Content-Type": "application/json"}

    response = requests.post(
        SANDBOX_API_URL, headers=headers, data=json.dumps(payload), timeout=10
    )
    response.raise_for_status()

    result = response.json()

    if result.get("status") == "Success" and result.get("run_result"):
        run_info = result["run_result"]
        if run_info.get("status") == "Finished":
            return run_info.get("stdout", "")
        else:
            return f"Execution failed with status: {run_info.get('status')}\nStderr: {run_info.get('stderr', '')}"
    else:
        return f"{result}"


if __name__ == "__main__":
    hello_world_code = 'print("Hello, world!")'
    print(f"Executing code:\n---\n{hello_world_code}\n---")
    output = execute_code_in_sandbox(hello_world_code)
    print(f"Result:\n---\n{output}\n---")

    error_code = "print(1 / 0)"
    print(f"Executing code with error:\n---\n{error_code}\n---")
    output = execute_code_in_sandbox(error_code)
    print(f"Result:\n---\n{output}\n---")
