#!/data/data/com.termux/files/usr/bin/bash

set -u

echo "=========================================="
echo " YangYang AI - Hermes Repair"
echo "=========================================="

# Termux 확인
if [ -z "${PREFIX:-}" ]; then
    echo "[ERROR] Termux에서 실행해야 합니다."
    exit 1
fi

echo "[OK] Termux detected"

# proot-distro 확인
if ! command -v proot-distro >/dev/null 2>&1; then
    echo "[INSTALL] proot-distro"
    pkg install -y proot-distro || exit 1
fi

# Debian 확인
if ! proot-distro list 2>/dev/null | grep -q "debian"; then
    echo "[INSTALL] Debian"
    proot-distro install debian || exit 1
else
    echo "[OK] Debian installed"
fi

echo
echo "=========================================="
echo " Debian / Python 3.13 / Hermes"
echo "=========================================="

proot-distro login debian -- bash -s <<'DEBIAN'

set -e

echo "[1/5] Updating Debian"

apt update

echo "[2/5] Installing Python 3.13"

apt install -y \
    python3.13 \
    python3.13-venv \
    python3.13-dev \
    build-essential \
    git \
    curl \
    ca-certificates

echo
echo "[CHECK] Python"

python3.13 --version

echo
echo "[3/5] Preparing Hermes repository"

mkdir -p "$HOME/.hermes"

if [ -d "$HOME/.hermes/hermes-agent/.git" ]; then
    cd "$HOME/.hermes/hermes-agent"

    echo "[UPDATE] Hermes repository"

    git fetch origin
    git reset --hard origin/main
else
    echo "[CLONE] Hermes repository"

    git clone \
        https://github.com/NousResearch/hermes-agent.git \
        "$HOME/.hermes/hermes-agent"

    cd "$HOME/.hermes/hermes-agent"
fi

echo
echo "[4/5] Creating Python 3.13 environment"

rm -rf venv

python3.13 -m venv venv

source venv/bin/activate

echo "Python:"
python --version

python -m pip install --upgrade pip setuptools wheel

echo
echo "[5/5] Installing Hermes"

if python -m pip install -e '.[termux-all]'; then
    echo "[OK] Hermes termux profile installed"
else
    echo "[WARN] termux-all profile failed"
    echo "[INFO] Trying normal Hermes installation"

    python -m pip install -e .
fi

echo
echo "=========================================="
echo " Hermes Test"
echo "=========================================="

if command -v hermes >/dev/null 2>&1; then
    echo "[OK] Hermes installed"
    hermes --help
else
    echo "[ERROR] Hermes command not found"
    exit 1
fi

DEBIAN

STATUS=$?

echo
echo "=========================================="

if [ "$STATUS" -eq 0 ]; then
    echo " Hermes Repair SUCCESS"
    echo "=========================================="
    echo
    echo "Hermes 실행:"
    echo
    echo "proot-distro login debian"
    echo "source ~/.hermes/hermes-agent/venv/bin/activate"
    echo "hermes"
else
    echo " Hermes Repair FAILED"
    echo "=========================================="
    echo
    echo "위의 오류 메시지를 확인하세요."
fi

exit "$STATUS"
