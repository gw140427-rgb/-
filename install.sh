#!/data/data/com.termux/files/usr/bin/bash

# ==========================================================
# YangYang AI
# Multi-AI Termux Installer
# ==========================================================

set -u

REPO="https://raw.githubusercontent.com/USERNAME/yangyang-ai/main"
BASE="$HOME/YangYang_AI"

echo "=========================================="
echo "       YangYang AI Installer"
echo "=========================================="
echo

# Termux 확인
if [ -z "${PREFIX:-}" ]; then
    echo "이 스크립트는 Termux에서 실행해야 합니다."
    exit 1
fi

# ----------------------------------------------------------
# 기본 패키지
# ----------------------------------------------------------

echo "[1/8] Termux 기본 환경"

pkg update -y
pkg upgrade -y

pkg install -y \
    git curl wget \
    python nodejs \
    clang make cmake rust \
    pkg-config libffi openssl \
    ripgrep ffmpeg jq \
    nano vim \
    unzip zip tar rsync \
    openssh \
    proot proot-distro \
    tmux htop tree

# ----------------------------------------------------------
# 저장소
# ----------------------------------------------------------

echo
echo "[2/8] Android 저장소"

termux-setup-storage 2>/dev/null || true

# ----------------------------------------------------------
# Python
# ----------------------------------------------------------

echo
echo "[3/8] Python"

python -m pip install --upgrade pip setuptools wheel

python -m pip install \
    requests \
    aiohttp \
    pyyaml \
    rich \
    psutil

# ----------------------------------------------------------
# Node
# ----------------------------------------------------------

echo
echo "[4/8] Node.js"

node --version
npm --version

npm config set fund false
npm config set audit false

# ----------------------------------------------------------
# Hermes
# ----------------------------------------------------------

echo
echo "[5/8] Hermes Agent"

export PATH="$HOME/.local/bin:$PREFIX/bin:$PATH"

if command -v hermes >/dev/null 2>&1; then
    echo "Hermes 이미 설치됨"
else
    curl -fsSL \
        https://hermes-agent.nousresearch.com/install.sh \
        | bash || echo "Hermes 설치 실패"
fi

# ----------------------------------------------------------
# OpenClaw
# ----------------------------------------------------------

echo
echo "[6/8] OpenClaw"

if command -v openclaw >/dev/null 2>&1; then
    echo "OpenClaw 이미 설치됨"
else
    curl -fsSL \
        --proto '=https' \
        --tlsv1.2 \
        https://openclaw.ai/install.sh \
        | bash -s -- --no-onboard \
        || echo "OpenClaw 설치 실패"
fi

# ----------------------------------------------------------
# OpenCode
# ----------------------------------------------------------

echo
echo "[7/8] OpenCode"

if command -v opencode >/dev/null 2>&1; then
    echo "OpenCode 이미 설치됨"
else
    curl -fsSL \
        https://opencode.ai/install \
        | bash || echo "OpenCode 설치 실패"
fi

# ----------------------------------------------------------
# 기타 AI 도구
# ----------------------------------------------------------

echo
echo "[8/8] 기타 AI 도구"

# Ollama
if ! command -v ollama >/dev/null 2>&1; then
    echo "Ollama 설치 시도..."
    curl -fsSL https://ollama.com/install.sh | sh \
        || echo "Ollama 설치 실패 또는 Termux 미지원"
fi

# llmfit
if ! command -v llmfit >/dev/null 2>&1; then
    if command -v cargo >/dev/null 2>&1; then
        cargo install llmfit \
            || echo "llmfit 설치 실패"
    fi
fi

# SillyTavern
if [ ! -d "$HOME/SillyTavern" ]; then
    git clone --depth 1 \
        https://github.com/SillyTavern/SillyTavern.git \
        "$HOME/SillyTavern" \
        || echo "SillyTavern 설치 실패"
fi

# ----------------------------------------------------------
# YangYang AI Memory
# ----------------------------------------------------------

echo
echo "=========================================="
echo "       Multi-AI Memory 설치"
echo "=========================================="

mkdir -p "$BASE/memory/stories"
mkdir -p "$BASE/scripts"
mkdir -p "$BASE/config"

download() {
    URL="$1"
    FILE="$2"

    echo "다운로드: $FILE"

    curl -fsSL "$URL" -o "$FILE" \
        || echo "다운로드 실패: $FILE"
}

download \
    "$REPO/memory/AI_CONTEXT.md" \
    "$BASE/memory/AI_CONTEXT.md"

download \
    "$REPO/memory/story_memory.json" \
    "$BASE/memory/story_memory.json"

download \
    "$REPO/memory/stories/yangyang_city.md" \
    "$BASE/memory/stories/yangyang_city.md"

download \
    "$REPO/memory/stories/independent_life.md" \
    "$BASE/memory/stories/independent_life.md"

download \
    "$REPO/memory/stories/mars_exploration.md" \
    "$BASE/memory/stories/mars_exploration.md"

download \
    "$REPO/scripts/ai-start.sh" \
    "$BASE/scripts/ai-start.sh"

download \
    "$REPO/scripts/memory-update.py" \
    "$BASE/scripts/memory-update.py"

chmod +x "$BASE/scripts/ai-start.sh"

# ----------------------------------------------------------
# PATH
# ----------------------------------------------------------

touch "$HOME/.bashrc"

if ! grep -q 'YangYang_AI' "$HOME/.bashrc"; then
    echo 'export YANGYANG_AI="$HOME/YangYang_AI"' >> "$HOME/.bashrc"
fi

if ! grep -q 'HOME/.local/bin' "$HOME/.bashrc"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

export YANGYANG_AI="$BASE"
export PATH="$HOME/.local/bin:$PREFIX/bin:$PATH"

# ----------------------------------------------------------
# 결과
# ----------------------------------------------------------

echo
echo "=========================================="
echo "          설치 결과"
echo "=========================================="

for CMD in python node npm git ssh hermes openclaw opencode ollama llmfit
do
    if command -v "$CMD" >/dev/null 2>&1; then
        echo "[OK] $CMD"
    else
        echo "[--] $CMD"
    fi
done

echo
echo "SillyTavern:"
if [ -d "$HOME/SillyTavern" ]; then
    echo "[OK]"
else
    echo "[--]"
fi

echo
echo "Multi-AI Memory:"
echo "$BASE/memory/AI_CONTEXT.md"
echo "$BASE/memory/story_memory.json"

echo
echo "스토리:"
ls -1 "$BASE/memory/stories" 2>/dev/null || true

echo
echo "=========================================="
echo "       YangYang AI 설치 완료"
echo "=========================================="
echo
echo "새 터미널을 열거나:"
echo
echo "source ~/.bashrc"
echo
echo "AI 공통 메모리:"
echo
echo "cat ~/YangYang_AI/memory/AI_CONTEXT.md"
echo
echo "완료."
