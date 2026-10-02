#!/usr/bin/env bash
# YangYang AI - Debian PRoot setup
# Safe to rerun; does not remove user data or modify Termux installations.
set -Eeuo pipefail

REPO="https://raw.githubusercontent.com/gw140427-rgb/-/main"
BASE="$HOME/YangYang_AI"

echo "=========================================="
echo " YangYang AI - Debian Installer"
echo "=========================================="

if ! grep -qiE 'debian|ubuntu' /etc/os-release 2>/dev/null; then
  echo "[ERROR] Debian/Ubuntu 환경이 아닙니다. proot-distro login debian 으로 접속하세요."
  exit 1
fi

mkdir -p "$BASE/memory" "$BASE/scripts" "$BASE/logs"

echo "[1/3] 패키지 목록 업데이트"
apt-get update
echo "[2/3] 기본 도구 설치"
DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl git python3 python3-venv python3-pip nodejs npm bash coreutils findutils

download() {
  local rel="$1"
  local dest="$2"
  local tmp
  tmp="$(mktemp)"
  echo "[DOWNLOAD] $rel"
  if curl --fail --location --silent --show-error "$REPO/$rel" -o "$tmp"; then
    if [ -s "$tmp" ]; then
      mv "$tmp" "$dest"
      echo "[OK] $dest"
    else
      rm -f "$tmp"
      echo "[WARN] 빈 파일이라 건너뜀: $rel"
    fi
  else
    rm -f "$tmp"
    echo "[WARN] 다운로드 실패: $rel"
  fi
}

echo "[3/3] YangYang AI 메모리/스크립트"
for f in AI_CONTEXT.md AI_INSTRUCTIONS.md story_memory.json ai_family.md independent_life.md mars_exploration.md yangyang_city.md korean_independence.md; do
  download "memory/$f" "$BASE/memory/$f"
done
for f in ai-start.sh ai-control.sh ai-clean.sh memory-update.py; do
  download "scripts/$f" "$BASE/scripts/$f"
done
chmod +x "$BASE"/scripts/*.sh 2>/dev/null || true

echo
echo "설치 확인:"
python3 --version
node --version 2>/dev/null || echo "[WARN] Node.js 실행 확인 필요"
npm --version 2>/dev/null || true
git --version
echo "메모리 위치: $BASE/memory"
echo "기존 Termux 앱/설정은 변경하지 않았습니다."
echo "OpenClaw/Hermes/OpenCode는 별도 설치하지 않았습니다."
echo "=========================================="
echo " Debian 기본 환경 준비 완료"
echo "=========================================="
