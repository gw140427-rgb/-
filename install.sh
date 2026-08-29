#!/data/data/com.termux/files/usr/bin/bash

# ==========================================================
# YangYang AI - All-in-One Termux Installer
#
# Installs:
#   - Termux base tools
#   - Python / Node.js
#   - Hermes Agent
#   - OpenClaw
#   - OpenCode
#   - YangYang shared memory
#   - AI helper scripts
#
# Repository:
#   https://github.com/gw140427-rgb/-
# ==========================================================

set -u

REPO="https://raw.githubusercontent.com/gw140427-rgb/-/main"
BASE="$HOME/YangYang_AI"

export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PREFIX/bin:$PATH"

echo
echo "=========================================="
echo "        YangYang AI Installer"
echo "=========================================="
echo

# ----------------------------------------------------------
# Termux 확인
# ----------------------------------------------------------

if [ -z "${PREFIX:-}" ]; then
    echo "[ERROR] 이 설치기는 Termux용입니다."
    exit 1
fi

echo "[OK] Termux detected"
echo

# ----------------------------------------------------------
# 기본 패키지
# ----------------------------------------------------------

echo "=========================================="
echo "[1/7] Termux 기본 패키지"
echo "=========================================="

pkg update -y || true
pkg upgrade -y || true

pkg install -y \
    git \
    curl \
    wget \
    python \
    nodejs \
    clang \
    make \
    cmake \
    rust \
    pkg-config \
    openssl \
    libffi \
    ripgrep \
    ffmpeg \
    jq \
    unzip \
    zip \
    tar \
    rsync \
    openssh \
    tmux \
    htop \
    tree

echo

# ----------------------------------------------------------
# Android 저장소
# ----------------------------------------------------------

echo "=========================================="
echo "[2/7] Android 저장소"
echo "=========================================="

termux-setup-storage 2>/dev/null || true

echo

# ----------------------------------------------------------
# Python
# ----------------------------------------------------------

echo "=========================================="
echo "[3/7] Python"
echo "=========================================="

python --version || true
python -m pip --version || true

python -m pip install --upgrade pip setuptools wheel || true

echo

# ----------------------------------------------------------
# Hermes Agent
# ----------------------------------------------------------

echo "=========================================="
echo "[4/7] Hermes Agent"
echo "=========================================="

if command -v hermes >/dev/null 2>&1; then
    echo "[OK] Hermes already installed"
else
    echo "공식 Hermes 설치기를 실행합니다."

    if curl -fsSL \
        https://hermes-agent.nousresearch.com/install.sh \
        | bash; then

        echo "[OK] Hermes 설치 완료"

    else

        echo "[WARN] Hermes 설치 실패"
        echo "       나머지 설치는 계속합니다."

    fi
fi

export PATH="$HOME/.local/bin:$PATH"

echo

# ----------------------------------------------------------
# OpenClaw
# ----------------------------------------------------------

echo "=========================================="
echo "[5/7] OpenClaw"
echo "=========================================="

if command -v openclaw >/dev/null 2>&1; then

    echo "[OK] OpenClaw already installed"

else

    echo "공식 OpenClaw 설치기를 실행합니다."
    echo "Termux/Android는 공식 지원 범위와 차이가 있을 수 있습니다."

    if curl -fsSL \
        --proto '=https' \
        --tlsv1.2 \
        https://openclaw.ai/install.sh \
        | bash -s -- --no-prompt --no-onboard; then

        echo "[OK] OpenClaw 설치 완료"

    else

        echo "[WARN] OpenClaw 설치 실패"
        echo "       Termux 환경에서 지원되지 않는 부분일 수 있습니다."
        echo "       나머지 설치는 계속합니다."

    fi
fi

echo

# ----------------------------------------------------------
# OpenCode
# ----------------------------------------------------------

echo "=========================================="
echo "[6/7] OpenCode"
echo "=========================================="

if command -v opencode >/dev/null 2>&1; then

    echo "[OK] OpenCode already installed"

else

    echo "공식 OpenCode 설치기를 실행합니다."

    if curl -fsSL \
        https://opencode.ai/install \
        | bash; then

        echo "[OK] OpenCode 설치 완료"

    else

        echo "[WARN] OpenCode 설치 실패"
        echo "       나머지 설치는 계속합니다."

    fi
fi

export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"

echo

# ----------------------------------------------------------
# YangYang AI Memory
# ----------------------------------------------------------

echo "=========================================="
echo "[7/7] YangYang AI Memory"
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
        echo "[ERROR] 다운로드 실패"
        echo "        $URL"
        return 1
    fi
}

# 공통 메모리

download \
    "$REPO/memory/AI_CONTEXT.md" \
    "$BASE/memory/AI_CONTEXT.md"

download \
    "$REPO/memory/story_memory.json" \
    "$BASE/memory/story_memory.json"

# 세계관

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

# AI 스크립트

download \
    "$REPO/scripts/ai-start.sh" \
    "$BASE/scripts/ai-start.sh"

download \
    "$REPO/scripts/memory-update.py" \
    "$BASE/scripts/memory-update.py"

chmod +x "$BASE/scripts/ai-start.sh"

echo

# ----------------------------------------------------------
# PATH 저장
# ----------------------------------------------------------

if ! grep -q 'YangYang_AI' "$HOME/.bashrc" 2>/dev/null; then

    cat >> "$HOME/.bashrc" <<'EOF'

# YangYang AI
export YANGYANG_AI="$HOME/YangYang_AI"
export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"
EOF

fi

export YANGYANG_AI="$BASE"

echo

# ----------------------------------------------------------
# JSON 검사
# ----------------------------------------------------------

echo "=========================================="
echo "JSON 검사"
echo "=========================================="

if [ -f "$BASE/memory/story_memory.json" ]; then

    if python - "$BASE/memory/story_memory.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    json.load(f)

print("JSON OK")
PY
    then
        echo "[OK] story_memory.json"
    else
        echo "[ERROR] story_memory.json 문법 오류"
    fi

else

    echo "[WARN] story_memory.json 없음"

fi

echo

# ----------------------------------------------------------
# 프로그램 검사
# ----------------------------------------------------------

echo "=========================================="
echo "프로그램 검사"
echo "=========================================="

check_command() {

    NAME="$1"

    if command -v "$NAME" >/dev/null 2>&1; then
        echo "[OK] $NAME"
        "$NAME" --version 2>/dev/null | head -n 1 || true
    else
        echo "[--] $NAME"
    fi
}

check_command python
check_command node
check_command npm
check_command git
check_command hermes
check_command openclaw
check_command opencode

echo

# ----------------------------------------------------------
# 메모리 검사
# ----------------------------------------------------------

echo "=========================================="
echo "YangYang AI Memory"
echo "=========================================="

if [ -d "$BASE/memory" ]; then
    find "$BASE/memory" -maxdepth 1 -type f -printf '%f\n' 2>/dev/null \
        || ls -1 "$BASE/memory"
fi

echo

echo "=========================================="
echo "설치 완료"
echo "=========================================="

echo
echo "설치 위치:"
echo "$BASE"

echo
echo "공통 AI 메모리:"
echo "$BASE/memory/AI_CONTEXT.md"

echo
echo "새 터미널을 열거나:"
echo
echo "source ~/.bashrc"

echo
echo "메모리 확인:"
echo
echo "cat ~/YangYang_AI/memory/AI_CONTEXT.md"

echo
echo "AI 도구 확인:"
echo
echo "hermes --help"
echo "openclaw --help"
echo "opencode --help"

echo
echo "=========================================="
