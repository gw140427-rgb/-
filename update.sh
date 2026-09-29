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
echo "=========================================="
echo "설치된 AI 프로그램 확인"
echo "=========================================="
for CMD in hermes openclaw opencode codex; do
    if command -v "$CMD" >/dev/null 2>&1; then
        echo "[OK] $CMD: $(command -v "$CMD")"
    else
        echo "[--] $CMD 미발견 (이 환경의 PATH 기준)"
    fi
done

echo
echo "=========================================="
echo "Hermes 업데이트 (선택)"
echo "=========================================="
if command -v hermes >/dev/null 2>&1; then
    printf "Hermes를 지금 업데이트할까? [y/N]: "
    read -r ANSWER
    case "$ANSWER" in
        y|Y|yes|YES)
            echo "[INFO] Hermes 자체 업데이트를 실행합니다."
            echo "[INFO] 실패하면 출력 내용을 확인하고 재설치하지 마세요."
            hermes update || {
                echo "[WARN] Hermes 업데이트 실패. 설정/데이터는 이 스크립트에서 삭제하지 않았습니다."
                FAILED=1
            }
            ;;
        *)
            echo "[SKIP] Hermes 업데이트 건너뜀"
            ;;
    esac
else
    echo "[SKIP] Hermes 명령어가 이 Termux 환경의 PATH에서 발견되지 않았습니다."
fi

echo
echo "=========================================="
if [ "$FAILED" -eq 0 ]; then
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
