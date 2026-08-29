# ==========================================================
# YangYang AI - Memory Repository
# ==========================================================

REPO="https://raw.githubusercontent.com/gw140427-rgb/-/main"
BASE="$HOME/YangYang_AI"

echo
echo "=========================================="
echo "       YangYang AI Memory 설치"
echo "=========================================="

mkdir -p "$BASE/memory"
mkdir -p "$BASE/scripts"

download() {
    URL="$1"
    FILE="$2"

    echo "[DOWNLOAD] $FILE"

    if curl -fL "$URL" -o "$FILE"; then
        echo "[OK] $FILE"
    else
        echo "[ERROR] 다운로드 실패: $FILE"
        return 1
    fi
}

# ----------------------------------------------------------
# 공통 메모리
# ----------------------------------------------------------

download \
    "$REPO/memory/AI_CONTEXT.md" \
    "$BASE/memory/AI_CONTEXT.md"

download \
    "$REPO/memory/story_memory.json" \
    "$BASE/memory/story_memory.json"

# ----------------------------------------------------------
# 세계관
# ----------------------------------------------------------

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

# ----------------------------------------------------------
# AI Scripts
# ----------------------------------------------------------

download \
    "$REPO/scripts/ai-start.sh" \
    "$BASE/scripts/ai-start.sh"

download \
    "$REPO/scripts/memory-update.py" \
    "$BASE/scripts/memory-update.py"

chmod +x "$BASE/scripts/ai-start.sh"

# ----------------------------------------------------------
# JSON 검사
# ----------------------------------------------------------

echo
echo "JSON 메모리 검사..."

if command -v python >/dev/null 2>&1; then
    python - <<'PY'
import json
from pathlib import Path

p = Path.home() / "YangYang_AI/memory/story_memory.json"

try:
    with p.open(encoding="utf-8") as f:
        json.load(f)
    print("[OK] story_memory.json 정상")
except Exception as e:
    print("[ERROR] story_memory.json 오류")
    print(e)
PY
fi

# ----------------------------------------------------------
# 설치 결과
# ----------------------------------------------------------

echo
echo "=========================================="
echo "       YangYang AI 설치 결과"
echo "=========================================="

echo
echo "[Memory]"
ls -lh "$BASE/memory"

echo
echo "[Scripts]"
ls -lh "$BASE/scripts"

echo
echo "설치 위치:"
echo "$BASE"

echo
echo "메모리 확인:"
echo "cat ~/YangYang_AI/memory/AI_CONTEXT.md"

echo
echo "완료."
