# Hermes 현재 설치 상태 복구
set -e

HERMES_DIR="$HOME/.hermes/hermes-agent"

echo "=== Hermes 복구 시작 ==="

# 저장소가 이미 있으면 그대로 사용
if [ ! -d "$HERMES_DIR" ]; then
    echo "[ERROR] Hermes 저장소가 없습니다:"
    echo "$HERMES_DIR"
    exit 1
fi

cd "$HERMES_DIR"

echo "[OK] Hermes 저장소 발견"
git status --short

# Python 3.13이 이미 설치되어 있는지 확인
PY313=""

for p in \
    "$PREFIX/bin/python3.13" \
    "$PREFIX/bin/python3.13m" \
    "$HOME/.local/bin/python3.13"
do
    if [ -x "$p" ]; then
        PY313="$p"
        break
    fi
done

if [ -z "$PY313" ]; then
    echo
    echo "[ERROR] Python 3.13이 없습니다."
    echo
    echo "현재 Python:"
    python --version
    echo
    echo "먼저 Termux에 Python 3.13을 준비해야 합니다."
    echo "기존 Python 3.14는 삭제하지 마세요."
    exit 2
fi

echo "[OK] Python 3.13 발견:"
"$PY313" --version

# 기존 실패한 venv만 제거
if [ -d "$HERMES_DIR/venv" ]; then
    echo "[INFO] 기존 실패 venv 제거"
    rm -rf "$HERMES_DIR/venv"
fi

echo "[INFO] 새 Hermes venv 생성"

"$PY313" -m venv "$HERMES_DIR/venv"

source "$HERMES_DIR/venv/bin/activate"

echo "[OK] Hermes venv:"
python --version

# Android API level
export ANDROID_API_LEVEL="$(getprop ro.build.version.sdk)"

echo "[OK] ANDROID_API_LEVEL=$ANDROID_API_LEVEL"

# 기본 빌드 도구
python -m pip install --upgrade pip setuptools wheel

# Hermes 공식 Termux 방식
echo
echo "=== Hermes 설치 ==="

python -m pip install \
    -e '.[termux]' \
    -c constraints-termux.txt

# Termux PATH에 hermes 연결
ln -sf \
    "$HERMES_DIR/venv/bin/hermes" \
    "$PREFIX/bin/hermes"

echo
echo "=== 검사 ==="

command -v hermes
hermes --version

echo
echo "Hermes 설치 완료."
echo
echo "다음 명령:"
echo "  hermes doctor"
echo "  hermes"
