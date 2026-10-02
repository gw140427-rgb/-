#!/usr/bin/env bash
# YangYang AI - Podroid / Alpine Linux installer
# Standalone script: does not run Termux pkg/APT setup.

set -u

REPO="https://github.com/gw140427-rgb/-/raw/refs/heads/main"
BASE="$HOME/YangYang_AI"
mkdir -p "$BASE/logs"
LOG_FILE="$BASE/logs/podroid-install-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo
echo "=========================================="
echo "   YangYang AI - Podroid Installer"
echo "=========================================="

if [ ! -f /etc/alpine-release ] || ! command -v apk >/dev/null 2>&1; then
    echo "[ERROR] Alpine Linux 환경이 아닙니다. Podroid에서 실행하세요."
    exit 1
fi
echo "[OK] Alpine Linux detected: $(cat /etc/alpine-release)"

show_status() {
    echo
    echo "========== Podroid 상태 검사 =========="
    echo "OS: Alpine $(cat /etc/alpine-release)"
    for name in bash curl git python3 pip3 node npm hermes openclaw opencode; do
        if command -v "$name" >/dev/null 2>&1; then
            printf '[OK] %-10s ' "$name"
            "$name" --version 2>/dev/null | head -n 1 || true
        else
            echo "[--] $name 미설치"
        fi
    done
    echo "메모리 경로: $BASE/memory"
    [ -d "$BASE/memory" ] && ls -1 "$BASE/memory" || echo "메모리 폴더 없음"
    echo "로그: $LOG_FILE"
}

echo
echo "========== Podroid 전용 메뉴 =========="
echo "1) 기본 도구 + YangYang 메모리"
echo "2) OpenClaw 설치 시도"
echo "3) OpenCode 설치 시도"
echo "4) 상태 검사"
echo "5) 취소"
if [ -r /dev/tty ]; then
    read -r -p "선택 [1-5]: " CHOICE </dev/tty
else
    echo "[ERROR] 터미널 입력을 사용할 수 없습니다."
    exit 1
fi

case "$CHOICE" in
    1|2|3) ;;
    4) show_status; exit 0 ;;
    *) echo "취소했습니다."; exit 0 ;;
esac

echo
echo "[INFO] Alpine 패키지 목록 업데이트"
apk update || { echo "[ERROR] apk update 실패"; exit 1; }

echo "[INFO] 기본 도구 설치"
apk add bash curl git python3 py3-pip nodejs npm ca-certificates coreutils findutils grep sed tar gzip || {
    echo "[ERROR] 기본 도구 설치 실패"
    exit 1
}

if [ "$CHOICE" = "2" ]; then
    echo
    echo "[INFO] OpenClaw 공식 설치기를 실행합니다."
    echo "[WARN] Alpine/가상환경에서는 일부 기능이나 백그라운드 서비스가 제한될 수 있습니다."
    if curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | bash -s -- --no-prompt --no-onboard; then
        export PATH="$HOME/.local/bin:$PATH"
        command -v openclaw >/dev/null 2>&1 && openclaw --version || echo "[WARN] 설치 후 openclaw 명령을 찾지 못했습니다."
    else
        echo "[WARN] OpenClaw 설치기가 실패했습니다. 오류 내용을 확인하세요."
    fi
    exit 0
fi

if [ "$CHOICE" = "3" ]; then
    echo
    echo "[INFO] OpenCode 공식 설치기를 실행합니다."
    if curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path; then
        export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"
        command -v opencode >/dev/null 2>&1 && opencode --version || echo "[WARN] 설치 후 opencode 명령을 찾지 못했습니다."
    else
        echo "[WARN] OpenCode 설치기가 실패했습니다. 이 환경의 바이너리 호환성을 확인하세요."
    fi
    exit 0
fi

mkdir -p "$BASE/memory" "$BASE/scripts"

download() {
    url="$1"
    file="$2"
    echo "[DOWNLOAD] $(basename "$file")"
    if curl -fL "$url" -o "$file"; then
        echo "[OK] $file"
    else
        echo "[WARN] 다운로드 실패: $url"
    fi
}

for file in AI_CONTEXT.md AI_INSTRUCTIONS.md story_memory.json ai_family.md independent_life.md mars_exploration.md yangyang_city.md korean_independence.md; do
    download "$REPO/memory/$file" "$BASE/memory/$file"
done
for file in ai-start.sh ai-control.sh ai-clean.sh memory-update.py; do
    download "$REPO/scripts/$file" "$BASE/scripts/$file"
done
chmod +x "$BASE"/scripts/*.sh 2>/dev/null || true

echo
echo "[OK] Podroid 기본 도구 + 메모리 준비 완료"
echo "Python: $(python3 --version 2>/dev/null || true)"
echo "Node: $(node --version 2>/dev/null || true)"
echo "설치 위치: $BASE"
echo "상태 검사: bash $BASE/scripts/../podroid-install.sh"
echo "로그: $LOG_FILE"
