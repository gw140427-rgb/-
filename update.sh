#!/data/data/com.termux/files/usr/bin/bash

# ==========================================================
# YangYang AI - Safe Updater
# YangYang 파일 업데이트 + 선택적 Hermes 업데이트
# ==========================================================

set -u

REPO="https://raw.githubusercontent.com/gw140427-rgb/-/main"
BASE="$HOME/YangYang_AI"

echo
echo "=========================================="
echo "       YangYang AI Updater"
echo "=========================================="
echo

# Termux 확인
if [ -z "${PREFIX:-}" ]; then
    echo "[ERROR] Termux에서 실행해야 합니다."
    echo "[INFO] Debian/PRoot에서는 실행하지 마세요."
    exit 1
fi
echo "[OK] Termux detected"
echo

# 필수 도구 확인
for CMD in curl python; do
    if ! command -v "$CMD" >/dev/null 2>&1; then
        echo "[ERROR] 필수 명령어가 없습니다: $CMD"
        exit 1
    fi
done

mkdir -p "$BASE/memory" "$BASE/scripts"

# 안전한 다운로드: 성공한 경우에만 기존 파일 교체
download() {
    URL="$1"
    FILE="$2"
    TMP="$FILE.tmp"

    echo "[UPDATE] $(basename "$FILE")"
    if curl -fsSL "$URL" -o "$TMP"; then
        mv "$TMP" "$FILE"
        echo "[OK] 저장 완료"
    else
        rm -f "$TMP"
        echo "[WARN] 다운로드 실패: $(basename "$FILE") (기존 파일 유지)"
        return 1
    fi
}

FAILED=0
echo "=========================================="
echo "YangYang 메모리 업데이트"
echo "=========================================="

for NAME in AI_CONTEXT.md AI_INSTRUCTIONS.md story_memory.json ai_family.md independent_life.md mars_exploration.md yangyang_city.md korean_independence.md; do
    download "$REPO/memory/$NAME" "$BASE/memory/$NAME" || FAILED=1
done

echo
echo "=========================================="
echo "AI 스크립트 업데이트"
echo "=========================================="

download "$REPO/scripts/ai-start.sh" "$BASE/scripts/ai-start.sh" || FAILED=1
download "$REPO/scripts/memory-update.py" "$BASE/scripts/memory-update.py" || FAILED=1
[ ! -f "$BASE/scripts/ai-start.sh" ] || chmod +x "$BASE/scripts/ai-start.sh"

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
    print("[ERROR] story_memory.json:", e)
    sys.exit(1)
PY
    then
        :
    else
        echo "[WARN] JSON 형식을 확인하세요. 파일은 자동 삭제하지 않았습니다."
        FAILED=1
    fi
else
    echo "[--] story_memory.json 없음"
fi

echo
echo "설치 상태 확인"
echo "=========================================="
for CMD in hermes openclaw opencode codex; do
    if command -v "$CMD" >/dev/null 2>&1; then
        echo "[OK] $CMD: $(command -v "$CMD")"
        "$CMD" --version 2>/dev/null | head -n 1 || true
    else echo "[--] $CMD 미설치 또는 PATH에서 미발견"; fi
done

ask_update() {
    printf "%s 실행할까? [y/N]: " "$1"
    read -r ANSWER
    case "$ANSWER" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

echo
echo "AI 프로그램 업데이트"
echo "=========================================="
if command -v hermes >/dev/null 2>&1; then
    if ask_update "Hermes 업데이트"; then hermes update || { echo "[WARN] Hermes 실패"; FAILED=1; }; fi
fi
if command -v openclaw >/dev/null 2>&1; then
    if ask_update "OpenClaw 업데이트"; then openclaw update || { echo "[WARN] OpenClaw 실패"; FAILED=1; }; fi
fi
if command -v opencode >/dev/null 2>&1; then
    if ask_update "OpenCode 업데이트"; then opencode upgrade || { echo "[WARN] OpenCode 실패"; FAILED=1; }; fi
fi
if command -v codex >/dev/null 2>&1; then
    if ask_update "Codex 업데이트"; then
        if command -v npm >/dev/null 2>&1; then npm install -g @openai/codex@latest || { echo "[WARN] Codex 실패"; FAILED=1; }
        else echo "[WARN] npm 없음"; FAILED=1; fi
    fi
else
    echo "[INFO] Codex 미설치"
    if command -v npm >/dev/null 2>&1 && ask_update "Codex 설치"; then
        npm install -g @openai/codex@latest || { echo "[WARN] Codex 설치 실패"; FAILED=1; }
    fi
fi

echo "       업데이트 작업 종료"
else
    echo "       일부 작업 확인 필요"
fi
echo "=========================================="
echo "YangYang AI: $BASE"
echo "메모리: $BASE/memory"
echo "스크립트: $BASE/scripts"
echo
echo "※ 이 스크립트는 OpenClaw/OpenCode/Codex를 재설치하지 않습니다."
echo "※ Hermes 업데이트는 사용자가 y를 선택한 경우에만 실행됩니다."
