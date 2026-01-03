#!/usr/bin/env python
# -*- coding: utf-8 -*-

import json
import requests
import fire
import logging
import os

# --- 配置日志 ---
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def _send_test_request(url: str, trajectory_id: str, action: str, test_name: str):
    """
    辅助函数，用于发送测试请求、处理响应并打印结果。
    """
    logger.info(f"--- 正在运行测试: {test_name} ---")

    # 构造与服务器 API 一致的 payload
    payload = {
        "trajectory_ids": [trajectory_id],
        "actions": [action],
        "extra_fields": [{}],
    }

    logger.info(f"发送的 Action: {action}")

    try:
        # 增加超时时间以适应可能较慢的代码执行
        response = requests.post(url, json=payload, timeout=40)
        response.raise_for_status()  # 如果状态码是 4xx 或 5xx，则抛出异常

        result = response.json()
        logger.info(f"已收到对 '{test_name}' 的响应")

        # 打印从服务器返回的 observation
        if "observations" in result and len(result["observations"]) > 0:
            observation = result["observations"][0]
            # 服务器返回的结果已经用 <tool_response> 包装好，直接打印即可
            logger.info(
                f"\n--- {test_name} 的结果 ---\n{observation}\n" + "-" * 60 + "\n"
            )
        else:
            logger.error(f"在对 '{test_name}' 的响应中未找到 observation: {result}")

        return result

    except requests.exceptions.Timeout:
        logger.error(f"请求超时: {test_name}")
    except requests.exceptions.RequestException as e:
        logger.error(f"请求错误 '{test_name}': {e}")
    except Exception as e:
        logger.error(f"发生意外错误 '{test_name}': {e}")

    logger.info("-" * 60 + "\n")  # 在测试失败时也打印分隔符
    return None


def test_all_tools(
    url: str,
    trajectory_id: str = "test-integrated-tool-002",
):
    """
    为 IntegratedTool 服务器运行一系列全面的测试。
    """
    if not url:
        logger.error(
            "必须提供服务器 URL。请使用 --url=http://<your_host>:<port>/get_observation"
        )
        return

    # =======================================================
    # 1. 测试搜索功能
    # =======================================================
    print("\n" + "=" * 20 + "  Testing Search Tools  " + "=" * 20)

    # 1.1 测试 text_search
    action = '<tool_call>{"name": "text_search", "arguments": {"query": "Latest news on AI"}}</tool_call>'
    _send_test_request(url, trajectory_id, action, "Text Search (正常查询)")

    # 1.2 测试 url_scrape
    action = '<tool_call>{"name": "url_scrape", "arguments": {"url": "https://www.python.org/"}}</tool_call>'
    _send_test_request(url, trajectory_id, action, "URL Scrape (正常抓取)")

    # 1.3 测试 image_search
    action = f'<tool_call>{{"name": "image_search", "arguments": {{"image_path": "{"/data_r1v4/data_r1v4/peng.xia/mm-dr/benchmark/hle/images/0.jpg"}"}}}}</tool_call>'
    _send_test_request(url, trajectory_id, action, "Image Search (正常查询)")

    # =======================================================
    # 2. 测试 Python 代码执行功能
    # =======================================================
    print("\n" + "=" * 20 + "  Testing python_code Tool  " + "=" * 20)

    # 2.1 测试简单执行
    code = "print('Hello from the sandboxed environment!')"
    action = f'<tool_call>{{"name": "python_code", "arguments": {{"code": {json.dumps(code)}}}}}</tool_call>'
    _send_test_request(url, trajectory_id, action, "Python (简单执行)")

    # 2.2 测试多行代码和计算
    code = (
        "x = 15\ny = 30\nresult = x + y\nprint(f'The sum of {x} and {y} is {result}')"
    )
    action = f'<tool_call>{{"name": "python_code", "arguments": {{"code": {json.dumps(code)}}}}}</tool_call>'
    _send_test_request(url, trajectory_id, action, "Python (多行与计算)")

    # 2.3 测试语法错误
    code = "print('This code has an unclosed parenthesis'"
    action = f'<tool_call>{{"name": "python_code", "arguments": {{"code": {json.dumps(code)}}}}}</tool_call>'
    _send_test_request(url, trajectory_id, action, "Python (语法错误)")

    # 2.4 测试运行时错误
    code = "result = 100 / 0\nprint(result)"
    action = f'<tool_call>{{"name": "python_code", "arguments": {{"code": {json.dumps(code)}}}}}</tool_call>'
    _send_test_request(url, trajectory_id, action, "Python (运行时错误)")

    # 2.5 测试安全限制：禁止的导入
    code = "import subprocess\nsubprocess.run(['ls', '-l'])"
    action = f'<tool_call>{{"name": "python_code", "arguments": {{"code": {json.dumps(code)}}}}}</tool_call>'
    _send_test_request(url, trajectory_id, action, "Python (安全限制-禁止的导入)")

    # 2.6 测试超时
    code = "import time\nprint('Testing timeout mechanism...')\ntime.sleep(30)\nprint('This line should never be executed!')"
    action = f'<tool_call>{{"name": "python_code", "arguments": {{"code": {json.dumps(code)}}}}}</tool_call>'
    _send_test_request(url, trajectory_id, action, "Python (超时)")

    # 2.7 测试无效参数
    action = '<tool_call>{"name": "python_code", "arguments": {"script": "print(1+1)"}}</tool_call>'
    _send_test_request(url, trajectory_id, action, "Python (无效参数-缺少'code')")

    logger.info("所有测试已完成。")


def main():
    """
    测试脚本的主入口。

    如何运行 (假设服务器运行在本地 5000 端口):

        python test_mm_deepresearch.py --url=http://localhost:5210/get_observation

    请将 URL 替换为您的服务器实际监听的地址和端口。
    """
    fire.Fire(test_all_tools)


if __name__ == "__main__":
    main()
