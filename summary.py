# -*- coding: utf-8 -*-

import pyperclip
import os

# --- 请在这里配置 ---

# 脚本所在的目录，作为所有相对路径的基准
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# 1. 配置项目分区、路径和要包含的文件类型
#    - title: 在输出中显示的分区标题
#    - paths: 一个列表，包含文件或目录的相对路径
#    - extensions: 当 path 是一个目录时，只包含这些后缀名的文件
PROJECT_SECTIONS = [
    {
        "title": "HarmonyOS ArkTS 核心逻辑与UI页面",
        "paths": [
            "./entry/src/main/ets/entryability",
            "./entry/src/main/ets/pages",
            "./entry/src/main/ets/entrybackupability",
            "./entry/src/main/ets/common",
            "./entry/src/main/ets/components",
        ],
        "extensions": [".ets"]  # ArkTS 文件
    },
    {
        "title": "HarmonyOS 配置文件",
        "paths": [
            "./entry/src/main/resources/base/profile/main_pages.json",
            "./entry/src/main/module.json5",
            "./build-profile.json5",
        ],
        "extensions": [".json", ".json5"]
    },
    # 如果您有其他模块或库，可以像下面这样添加新的分区
    # {
    #     "title": "我的自定义库",
    #     "paths": ["./mylibrary/src/main/ets"],
    #     "extensions": [".ets", ".ts"]
    # }
]

# 2. 您希望在最后附加给 AI 的指令
PROMPT_INSTRUCTIONS = """
不论你进行如何修改，一定保证不会破坏已有的功能。
对于 ArkTS (.ets) 代码，如果只改动一个函数或组件，请给出完整的函数或@Component组件的代码，并清晰地指出我应该在哪个文件中进行替换。
对于 JSON 配置文件，请给出修改后的完整文件内容。
千万不要省略代码，要确保我可以直接复制粘贴来使用。
"""

# 3. 输出的 .md 文件名 (可选, 用于本地备份)
OUTPUT_FILENAME = "project_summary.md"

# --- 配置结束 ---


def process_file(file_path):
    """读取单个文件内容，并格式化为Markdown代码块"""
    try:
        # 从文件后缀名推断语言类型
        lang = os.path.splitext(file_path)[1].lstrip('.')
        if lang == 'ets':
            lang = 'typescript' # .ets 在很多高亮工具中可以被识别为 typescript
        
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            # 规范化路径显示，使用正斜杠
            relative_path = os.path.relpath(file_path, BASE_DIR).replace('\\', '/')
            return f"```{lang}\n// File: {relative_path}\n\n{content}\n```\n\n"
    except FileNotFoundError:
        print(f"  [警告] 文件未找到: {file_path}")
        return f"--- [警告] 文件未找到: {os.path.relpath(file_path, BASE_DIR).replace('\\', '/')} ---\n\n"
    except Exception as e:
        print(f"  [错误] 读取文件失败: {file_path}, 原因: {e}")
        return f"--- [错误] 读取文件失败: {os.path.relpath(file_path, BASE_DIR).replace('\\', '/')}, 原因: {e} ---\n\n"

def process_directory(dir_path, extensions):
    """递归地处理目录下的所有符合后缀名的文件"""
    text_content = ""
    if not os.path.isdir(dir_path):
        print(f"  [警告] 目录未找到: {dir_path}")
        return f"--- [警告] 目录未找到: {os.path.relpath(dir_path, BASE_DIR).replace('\\', '/')} ---\n\n"
    
    for root, _, files in os.walk(dir_path):
        for file in sorted(files): # 排序以保证输出顺序稳定
            if any(file.endswith(ext) for ext in extensions):
                file_path = os.path.join(root, file)
                print(f"  [处理中] {file_path}")
                text_content += process_file(file_path)
    return text_content

def get_summary():
    """根据配置生成项目内容的摘要"""
    final_text = []
    
    print("--- 开始生成项目摘要 ---")
    
    for section in PROJECT_SECTIONS:
        title = section.get("title", "未命名分区")
        paths = section.get("paths", [])
        extensions = section.get("extensions", [])
        
        print(f"\n--- 正在处理分区: {title} ---")
        final_text.append(f"--- {title} ---\n\n")
        
        for path in paths:
            full_path = os.path.join(BASE_DIR, path)
            if os.path.isdir(full_path):
                final_text.append(process_directory(full_path, extensions))
            elif os.path.isfile(full_path):
                print(f"  [处理中] {full_path}")
                final_text.append(process_file(full_path))
            else:
                print(f"  [警告] 路径未找到: {full_path}")
                final_text.append(f"--- [警告] 路径未找到: {path} ---\n\n")

    # 添加最后的指令
    final_text.append(PROMPT_INSTRUCTIONS)
    
    return "".join(final_text)

if __name__ == "__main__":
    summary_content = get_summary()
    
    # 将内容写入本地文件，方便检查
    try:
        with open(os.path.join(BASE_DIR, OUTPUT_FILENAME), "w", encoding='utf-8') as file:
            file.write(summary_content)
        print(f"\n摘要已成功保存到: {OUTPUT_FILENAME}")
    except Exception as e:
        print(f"\n[错误] 无法写入文件 {OUTPUT_FILENAME}, 原因: {e}")
        
    # 将内容发送到剪切板
    try:
        pyperclip.copy(summary_content)
        print("✅ 内容已成功复制到剪切板！")
    except pyperclip.PyperclipException as e:
        print(f"❌ 无法复制到剪切板: {e}")
        print("这通常发生在没有图形界面的服务器环境中。")