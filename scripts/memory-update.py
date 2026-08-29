#!/usr/bin/env python3

import json
from pathlib import Path
from datetime import datetime

BASE = Path.home() / "YangYang_AI"
MEMORY = BASE / "memory" / "story_memory.json"

def load():
    with open(MEMORY, "r", encoding="utf-8") as f:
        return json.load(f)

def save(data):
    with open(MEMORY, "w", encoding="utf-8") as f:
        json.dump(
            data,
            f,
            ensure_ascii=False,
            indent=2
        )

def show():
    data = load()

    print("\n=== YangYang AI Worlds ===\n")

    for key, world in data["worlds"].items():
        print(f"[{key}]")
        print(f"이름: {world['name']}")
        print(f"상태: {world.get('current_state', '확인 필요')}")
        print()

def update_state(world_name, new_state):
    data = load()

    if world_name not in data["worlds"]:
        print("존재하지 않는 세계관입니다.")
        return

    data["worlds"][world_name]["current_state"] = new_state

    data["metadata"] = {
        "last_updated": datetime.now().isoformat()
    }

    save(data)

    print("메모리 업데이트 완료.")

if __name__ == "__main__":
    show()
