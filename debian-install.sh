#!/usr/bin/env bash
# YangYang AI - Debian (PRoot) installer
# Debian only. Does not use Termux pkg or Alpine apk.

set -u

REPO="https://raw.githubusercontent.com/gw140427-rgb/-/main"
BASE="$HOME/YangYang_AI"
mkdir -p "$BASE/logs"
LOG_FILE="$BASE/logs/debian-install-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo
echo "=========================================="
echo "   YangYang AI - Debian Installer"
echo "=========================================="

if ! command -v apt-get >/dev/null 2>&1 || ! grep -qi debian /etc/os-release 2>/dev/null; then
    echo "[ERROR] Debian 환경이 아닙니다. Debian PRoot에서 실행하세요."
    exit 1
fi
echo "[OK] Debian detected: $(. /etc/os-release; echo "${PRETTY_NAME:-Debian}")"
echo "[INFO] 기존 Hermes/OpenClaw/Codex 설정과 데이터는 삭제하지 않습니다."

show_status() {
    echo
    echo "========== Debian 상태 검사 =========="
    for name in python3 pip3 node npm git curl bash hermes openclaw opencode codex; do
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
echo "========== Debian 전용 메뉴 =========="
echo "1) 기본 도구 + YangYang 메모리"
echo "2) 상태 검사"
echo "3) 취소"
if [ -r /dev/tty ]; then
    read -r -p "선택 [1-3]: " CHOICE </dev/tty
else
    echo "[ERROR] 터미널 입력을 사용할 수 없습니다."
    exit 1
fi

case "$CHOICE" in
    1) ;;
    2) show_status; exit 0 ;;
    *) echo "취소했습니다."; exit 0 ;;
esac

export DEBIAN_FRONTEND=noninteractive
echo
echo "[INFO] apt 패키지 목록 업데이트"
apt-get update || { echo "[ERROR] apt-get update 실패"; exit 1; }

echo "[INFO] 기본 도구 설치"
apt-get install -y ca-certificates curl git bash python3 python3-venv python3-pip build-essential pkg-config || {
    echo "[ERROR] 기본 도구 설치 실패"
    exit 1
}

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
echo "[INFO] Node.js는 기존 버전/설정 보호를 위해 자동 변경하지 않습니다."
echo "[INFO] Codex, Hermes, OpenClaw, OpenCode는 자동 재설치하지 않습니다."
echo
echo "[OK] Debian 기본 도구 + 메모리 준비 완료"
python3 --version 2>/dev/null || true
node --version 2>/dev/null || echo "[--] Node.js 미설치"
echo "설치 위치: $BASE"
echo "상태 검사: bash $HOME/debian-install.sh"
echo "로그: $LOG_FILE"
