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

# Keep the Debian commands ahead of Termux host binaries in PRoot.
# This changes only this installer process, not the user's shell configuration.
TERMUX_PREFIX="/data/data/com.termux/files/usr"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
echo
echo "========== 실행 환경 사전 검사 =========="
TERMUX_LEAK=0
for name in python3 node npm curl git; do
    path="$(command -v "$name" 2>/dev/null || true)"
    if [ -n "$path" ]; then
        printf '[CHECK] %-8s %s\n' "$name" "$path"
        case "$path" in
            "$TERMUX_PREFIX"/*) TERMUX_LEAK=1 ;;
        esac
    else
        printf '[CHECK] %-8s Debian 경로에서 미발견\n' "$name"
    fi
done
if [ "$TERMUX_LEAK" -eq 1 ]; then
    echo "[WARN] Termux 경로 혼입이 남아 있습니다. PATH를 확인하세요."
    exit 1
fi
echo "[OK] Debian PATH 우선 검사 통과"

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
echo "2) Hermes Agent 설치"
echo "3) OpenClaw 설치"
echo "4) Codex 설치"
echo "5) OpenCode 설치"
echo "6) 상태 검사"
echo "7) 취소"
if [ -r /dev/tty ]; then
    read -r -p "선택 [1-7]: " CHOICE </dev/tty
else
    echo "[ERROR] 터미널 입력을 사용할 수 없습니다."
    exit 1
fi

case "$CHOICE" in
    1|2|3|4|5) ;;
    6) show_status; exit 0 ;;
    *) echo "취소했습니다."; exit 0 ;;
esac

export DEBIAN_FRONTEND=noninteractive
 
# Individual AI tool installers
if [ "$CHOICE" != "1" ]; then
    case "$CHOICE" in
        2)
            echo "[INFO] Hermes Agent 설치기를 실행합니다."
            echo "[WARN] PRoot Debian에서는 일부 기능/의존성이 제한될 수 있습니다."
            curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
            ;;
        3)
            echo "[INFO] OpenClaw 공식 설치기를 실행합니다."
            curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | bash -s -- --no-prompt --no-onboard
            ;;
        4)
            echo "[INFO] Codex CLI 설치를 위해 Node.js/npm이 필요합니다."
            if ! command -v npm >/dev/null 2>&1; then
                apt-get update && apt-get install -y nodejs npm
            fi
            npm install -g @openai/codex
            ;;
        5)
            echo "[INFO] OpenCode 공식 설치기를 실행합니다."
            curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path
            ;;
    esac
    echo
    echo "[INFO] 설치 명령 실행 후 상태 검사:"
    for name in hermes openclaw codex opencode; do
        command -v "$name" >/dev/null 2>&1 && echo "[OK] $name" || echo "[--] $name 명령을 찾지 못함"
    done
    exit 0
fi

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
