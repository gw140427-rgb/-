#!/data/data/com.termux/files/usr/bin/bash

# ==========================================================
# YangYang AI - Update Only
# 전체 재설치 없이 YangYang AI 파일만 업데이트
# ==========================================================

set -u

REPO="https://raw.githubusercontent.com/gw140427-rgb/-/main"
BASE="$HOME/YangYang_AI"

echo
echo "=========================================="
echo "       YangYang AI Updater"
echo "=========================================="
echo

# ----------------------------------------------------------
# Termux 확인
# ----------------------------------------------------------

if [ -z "${PREFIX:-}" ]; then
    echo "[ERROR] Termux에서 실행해야 합니다."
    exit 1
fi

echo "[OK] Termux detected"
echo

# ----------------------------------------------------------
# 기본 디렉터리
# ----------------------------------------------------------

mkdir -p "$BASE/memory"
mkdir -p "$BASE/scripts"

# ----------------------------------------------------------
# 다운로드 함수
# ----------------------------------------------------------

download() {
    URL="$1"
    FILE="$2"

    echo "[UPDATE] $(basename "$FILE")"

    if curl -fL "$URL" -o "$FILE.tmp"; then
        mv "$FILE.tmp" "$FILE"
        echo "[OK]"
    else
        rm -f "$FILE.tmp"
        echo "[WARN] 업데이트 실패: $(basename "$FILE")"
    fi
}

# ----------------------------------------------------------
# 메모리 업데이트
# ----------------------------------------------------------

echo "=========================================="
echo "메모리 업데이트"
echo "=========================================="

download \
    "$REPO/memory/AI_CONTEXT.md" \
    "$BASE/memory/AI_CONTEXT.md"

download \
    "$REPO/memory/story_memory.json" \
    "$BASE/memory/story_memory.json"

# ----------------------------------------------------------
# 세계관 업데이트
# ----------------------------------------------------------

echo
echo "=========================================="
echo "세계관 업데이트"
echo "=========================================="

download \
    "$REPO/memory/ai_family.md" \
    "$BASE/memory/ai_family.md"

download \
    "$REPO/memory/independent_life.md" \
    "$BASE/memory/independent_life.md"

download \
    "$REPO/memory/mars_exploration.md" \
    "$BASE/memory/mars_exploration.md"

download \
    "$REPO/memory/yangyang_city.md" \
    "$BASE/memory/yangyang_city.md"

download \
    "$REPO/memory/korean_independence.md" \
    "$BASE/memory/korean_independence.md"

# ----------------------------------------------------------
# AI 스크립트 업데이트
# ----------------------------------------------------------

echo
echo "=========================================="
echo "AI 스크립트 업데이트"
echo "=========================================="

download \
    "$REPO/scripts/ai-start.sh" \
    "$BASE/scripts/ai-start.sh"

download \
    "$REPO/scripts/memory-update.py" \
    "$BASE/scripts/memory-update.py"

chmod +x "$BASE/scripts/ai-start.sh" 2>/dev/null || true

# ----------------------------------------------------------
# JSON 검사
# ----------------------------------------------------------

echo
echo "=========================================="
echo "JSON 검사"
echo "=========================================="

if [ -f "$BASE/memory/story_memory.json" ]; then
    if python - "$BASE/memory/story_memory.json" <<'PY'
import json
import sys

try:
    with open(sys.argv[1], encoding="utf-8") as f:
        json.load(f)

    print("[OK] story_memory.json")

except Exception as e:
    print("[ERROR] JSON 오류:", e)
    sys.exit(1)
PY
    then
        :
    else
        echo "[WARN] JSON 파일을 확인하세요."
    fi
fi

# ----------------------------------------------------------
# 설치된 프로그램 확인
# ----------------------------------------------------------

echo
echo "=========================================="
echo "설치된 AI 프로그램 확인"
echo "=========================================="

for CMD in hermes openclaw opencode; do
    if command -v "$CMD" >/dev/null 2>&1; then
        echo "[OK] $CMD"
    else
        echo "[--] $CMD 미설치"
    fi
done

# ----------------------------------------------------------
# 완료
# ----------------------------------------------------------

echo
echo "=========================================="
echo "       업데이트 완료"
echo "=========================================="

echo
echo "YangYang AI:"
echo "$BASE"

echo
echo "메모리:"
echo "$BASE/memory"

echo
echo "스크립트:"
echo "$BASE/scripts"

echo
echo "※ 이 업데이트기는 Hermes/OpenClaw/OpenCode를"
echo "   재설치하지 않습니다."
echo
