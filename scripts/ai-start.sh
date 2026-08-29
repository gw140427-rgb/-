#!/data/data/com.termux/files/usr/bin/bash

BASE="$HOME/YangYang_AI"
MEMORY="$BASE/memory"

echo "=========================================="
echo "       YangYang AI Shared Memory"
echo "=========================================="

if [ ! -f "$MEMORY/AI_CONTEXT.md" ]; then
    echo "AI_CONTEXT.md가 없습니다."
    exit 1
fi

echo
echo "===== 공식 AI 컨텍스트 ====="
cat "$MEMORY/AI_CONTEXT.md"

echo
echo "===== 구조화된 메모리 ====="

if [ -f "$MEMORY/story_memory.json" ]; then
    cat "$MEMORY/story_memory.json"
else
    echo "story_memory.json이 없습니다."
fi

echo
echo "=========================================="
echo "       Memory Loaded"
echo "=========================================="
