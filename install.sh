#!/data/data/com.termux/files/usr/bin/bash

# ==========================================================
# YangYang AI - All-in-One Termux Installer
#
# Installs:
#   - Termux base tools
#   - Python 3.13 / pip / venv
#   - Node.js / npm
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
# [1/7] 기본 패키지
# ----------------------------------------------------------

echo "=========================================="
echo "[1/7] Termux 기본 패키지"
echo "=========================================="

echo "[INFO] 패키지 목록 업데이트"

if ! pkg update -y; then
    echo
    echo "[ERROR] pkg update 실패"
    echo
    echo "현재 Termux APT 상태를 먼저 확인해야 합니다."
    echo "이 단계에서 중단합니다."
    exit 1
fi

echo
echo "[INFO] 기본 패키지 업그레이드"

pkg upgrade -y || {
    echo "[WARN] pkg upgrade 실패"
    echo "설치를 계속 시도합니다."
}

echo
echo "[INFO] TUR 저장소 추가"

if ! pkg install -y tur-repo; then
    echo "[ERROR] tur-repo 설치 실패"
    exit 1
fi

echo
echo "[INFO] 기본 도구 설치"

pkg install -y \
    git \
    curl \
    wget \
    python \
    python3.13 \
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
    tree \
    || {
        echo
        echo "[ERROR] 기본 패키지 설치 실패"
        exit 1
    }

echo
echo "[OK] 기본 패키지 설치 완료"
echo

# ----------------------------------------------------------
# [2/7] Android 저장소
# ----------------------------------------------------------

echo "=========================================="
echo "[2/7] Android 저장소"
echo "=========================================="

termux-setup-storage 2>/dev/null || true

echo "[OK] Android 저장소 권한 요청 완료"
echo

# ----------------------------------------------------------
# [3/7] Python
# ----------------------------------------------------------

echo "=========================================="
echo "[3/7] Python"
echo "=========================================="

PYTHON="python3.13"

if ! command -v "$PYTHON" >/dev/null 2>&1; then
    echo "[ERROR] python3.13을 찾을 수 없습니다."
    exit 1
fi

echo
echo "기본 Python:"
python --version || true

echo
echo "Hermes Python:"
"$PYTHON" --version

echo
echo "Python 3.13 pip:"
"$PYTHON" -m pip --version || true

echo
echo "[INFO] Python 3.13 pip 업데이트"

"$PYTHON" -m pip install --upgrade \
    pip \
    setuptools \
    wheel \
    || {
        echo "[WARN] pip 업데이트 실패"
        echo "Python 자체는 계속 사용합니다."
    }

echo
echo "[OK] Python 3.13 준비 완료"
echo

# ----------------------------------------------------------
# [4/7] Hermes Agent (공식 Termux APT)
# ----------------------------------------------------------

echo "=========================================="
echo "[4/7] Hermes Agent"
echo "=========================================="

export PATH="$HOME/.local/bin:$PREFIX/bin:$PATH"

if command -v hermes >/dev/null 2>&1; then
    echo "[OK] Hermes already installed"
    hermes --version 2>/dev/null || true
else
    echo "[INFO] 공식 Termux APT 저장소를 설정합니다."
    echo "[WARN] 공식 문서상 stable 채널은 현재 복구 중이므로 canary를 사용합니다."
    echo "[INFO] 기존 Hermes 설정과 OpenClaw/Codex 데이터는 삭제하지 않습니다."

    if ! pkg install -y curl gnupg; then
        echo "[WARN] curl/gnupg 설치 실패. Hermes 설치를 건너뜁니다."
    else
        KEYRING="$PREFIX/etc/apt/keyrings/hermes-agent.asc"
        SOURCES="$PREFIX/etc/apt/sources.list.d/hermes-agent.list"
        mkdir -p "$PREFIX/etc/apt/keyrings" "$PREFIX/etc/apt/sources.list.d"

        if curl -fsSL "https://hermes-assets.nousresearch.com/releases/termux/canary/key.asc" -o "$KEYRING"; then
            # Primary public-key fingerprint (not the signing subkey fingerprint)
            ACTUAL_FPR="$(gpg --batch --with-colons --show-keys "$KEYRING" 2>/dev/null | awk -F: '
                $1=="pub" { want=1; next }
                want && $1=="fpr" { print toupper($10); exit }
            ')"
            EXPECTED_FPR="C572B5FDD1A29CCFA9A912B6840B0848E139156D"

            if [ "$ACTUAL_FPR" = "$EXPECTED_FPR" ]; then
                echo "[OK] Hermes 저장소 서명 키 확인 완료"
                printf '%s\n' \
                    "deb [signed-by=$KEYRING] https://hermes-assets.nousresearch.com/releases/termux/canary hermes-canary main" \
                    > "$SOURCES"

                if pkg update; then
                    if pkg install -y hermes-agent; then
                        echo "[OK] Hermes 패키지 설치 완료"
                    else
                        echo "[WARN] hermes-agent 설치 실패. 공식 패키지 상태를 확인하세요."
                    fi
                else
                    echo "[WARN] 저장소 목록 갱신 실패. Hermes 설치를 건너뜁니다."
                fi
            else
                echo "[ERROR] Hermes 키 지문 불일치. 안전을 위해 설치를 중단합니다."
                echo "기대값: $EXPECTED_FPR"
                echo "실제값: ${ACTUAL_FPR:-확인 실패}"
                rm -f "$KEYRING"
            fi
        else
            echo "[WARN] Hermes 저장소 키 다운로드 실패. 설치를 건너뜁니다."
        fi
    fi
fi

export PATH="$HOME/.local/bin:$PREFIX/bin:$PATH"

echo
echo "Hermes 확인:"
if command -v hermes >/dev/null 2>&1; then
    hermes --version 2>/dev/null || true
else
    echo "[--] Hermes 미설치 (Termux 공식 패키지 상태 확인 필요)"
fi

echo

# [5/7] OpenClaw
# ----------------------------------------------------------

echo "=========================================="
echo "[5/7] OpenClaw"
echo "=========================================="

echo
echo "Node.js 확인:"

NODE_OK=0

if command -v node >/dev/null 2>&1; then

    NODE_VERSION="$(node --version 2>/dev/null || true)"

    echo "$NODE_VERSION"

    NODE_MAJOR="$(printf '%s\n' "$NODE_VERSION" | sed 's/^v//' | cut -d. -f1)"

    if [ -n "$NODE_MAJOR" ] && [ "$NODE_MAJOR" -ge 24 ]; then
        NODE_OK=1
        echo "[OK] Node.js 버전이 OpenClaw 설치 조건에 맞습니다."
    else
        echo "[WARN] Node.js 버전이 OpenClaw 최신 요구사항보다 낮을 수 있습니다."
    fi

else

    echo "[ERROR] Node.js가 없습니다."

fi

echo

if command -v openclaw >/dev/null 2>&1; then

    echo "[OK] OpenClaw already installed"
    openclaw --version 2>/dev/null || true

else

    if [ "$NODE_OK" -eq 1 ]; then

        echo "공식 OpenClaw 설치기를 실행합니다."
        echo "Termux/Android 환경에서는 일부 기능이 제한될 수 있습니다."
        echo

        if curl -fsSL \
            --proto '=https' \
            --tlsv1.2 \
            https://openclaw.ai/install.sh \
            | bash -s -- --no-prompt --no-onboard; then

            echo
            echo "[OK] OpenClaw 설치 완료"

        else

            echo
            echo "[WARN] OpenClaw 설치 실패"
            echo "Termux 환경에서 지원되지 않는 부분일 수 있습니다."
            echo "나머지 설치는 계속합니다."

        fi

    else

        echo "[WARN] Node.js 조건 미충족"
        echo "OpenClaw 설치를 건너뜁니다."

    fi

fi

export PATH="$HOME/.local/bin:$PATH"

echo

# ----------------------------------------------------------
# [6/7] OpenCode
# ----------------------------------------------------------

echo "=========================================="
echo "[6/7] OpenCode"
echo "=========================================="

export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"

if command -v opencode >/dev/null 2>&1; then

    echo "[OK] OpenCode already installed"
    opencode --version 2>/dev/null || true

else

    echo "공식 OpenCode 설치기를 실행합니다."
    echo

    if curl -fsSL \
        https://opencode.ai/install \
        | bash; then

        echo
        echo "[OK] OpenCode 설치 완료"

    else

        echo
        echo "[WARN] OpenCode 설치 실패"
        echo "나머지 설치는 계속합니다."

    fi

fi

export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"

echo

# ----------------------------------------------------------
# [7/7] YangYang AI Memory
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

echo
echo "----- 공통 메모리 -----"

download \
    "$REPO/memory/AI_CONTEXT.md" \
    "$BASE/memory/AI_CONTEXT.md"

download \
    "$REPO/memory/AI_INSTRUCTIONS.md" \
    "$BASE/memory/AI_INSTRUCTIONS.md" || true || true

download \
    "$REPO/memory/story_memory.json" \
    "$BASE/memory/story_memory.json" || true

echo
echo "----- 세계관 -----"

download \
    "$REPO/memory/ai_family.md" \
    "$BASE/memory/ai_family.md" || true

download \
    "$REPO/memory/independent_life.md" \
    "$BASE/memory/independent_life.md" || true

download \
    "$REPO/memory/mars_exploration.md" \
    "$BASE/memory/mars_exploration.md" || true

download \
    "$REPO/memory/yangyang_city.md" \
    "$BASE/memory/yangyang_city.md" || true

download \
    "$REPO/memory/korean_independence.md" \
    "$BASE/memory/korean_independence.md" || true

echo
echo "----- AI 스크립트 -----"

download \
    "$REPO/scripts/ai-start.sh" \
    "$BASE/scripts/ai-start.sh" || true

download \
    "$REPO/scripts/ai-control.sh" \
    "$BASE/scripts/ai-control.sh" || true

download \
    "$REPO/scripts/ai-clean.sh" \
    "$BASE/scripts/ai-clean.sh" || true

download \
    "$REPO/scripts/memory-update.py" \
    "$BASE/scripts/memory-update.py" || true

chmod +x "$BASE/scripts/ai-start.sh" 2>/dev/null || true
chmod +x "$BASE/scripts/ai-control.sh" 2>/dev/null || true
chmod +x "$BASE/scripts/ai-clean.sh" 2>/dev/null || true

echo

# ----------------------------------------------------------
# PATH 저장
# ----------------------------------------------------------

if ! grep -q 'YangYang AI' "$HOME/.bashrc" 2>/dev/null; then

    cat >> "$HOME/.bashrc" <<'EOF'

# YangYang AI
export YANGYANG_AI="$HOME/YangYang_AI"
export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"
EOF

fi

export YANGYANG_AI="$BASE"

echo "[OK] YangYang AI PATH 설정 완료"
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

try:
    with open(sys.argv[1], encoding="utf-8") as f:
        json.load(f)

    print("JSON OK")

except Exception as e:
    print("JSON ERROR:", e)
    sys.exit(1)
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
check_command python3.13
check_command node
check_command npm
check_command git
check_command curl
check_command hermes
check_command openclaw
check_command opencode

echo

# ----------------------------------------------------------
# Python 버전 목록
# ----------------------------------------------------------

echo "=========================================="
echo "Python 환경"
echo "=========================================="

echo "기본 Python:"
python --version 2>/dev/null || true

echo "Python 3.13:"
python3.13 --version 2>/dev/null || true

echo

# ----------------------------------------------------------
# Node.js / npm
# ----------------------------------------------------------

echo "=========================================="
echo "Node.js 환경"
echo "=========================================="

node --version 2>/dev/null || true
npm --version 2>/dev/null || true

echo

# ----------------------------------------------------------
# 메모리 검사
# ----------------------------------------------------------

echo "=========================================="
echo "YangYang AI Memory"
echo "=========================================="

if [ -d "$BASE/memory" ]; then

    find "$BASE/memory" \
        -maxdepth 1 \
        -type f \
        -printf '%f\n' 2>/dev/null \
        || ls -1 "$BASE/memory"

fi

echo

# ----------------------------------------------------------
# 완료
# ----------------------------------------------------------

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
echo "Python 3.13:"
echo "python3.13 --version"

echo
echo "Hermes:"
echo "hermes --help"

echo
echo "OpenClaw:"
echo "openclaw --help"

echo
echo "OpenCode:"
echo "opencode --help"

echo
echo "새 터미널을 열거나:"
echo
echo "source ~/.bashrc"

echo
echo "메모리 확인:"
echo
echo "cat ~/YangYang_AI/memory/AI_CONTEXT.md"

echo
echo "=========================================="
echo " YangYang AI 설치 프로그램 종료"
echo "=========================================="
