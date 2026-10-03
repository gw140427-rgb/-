#!/usr/bin/env bash
# YangYang AI - Debian PRoot AI installer
# Safe to rerun. Does not remove Termux data or existing Debian AI data.
set -Eeuo pipefail

REPO="https://github.com/gw140427-rgb/-/raw/refs/heads/main"
BASE="$HOME/YangYang_AI"

echo
echo "=========================================="
echo " YangYang AI - Debian AI Installer"
echo "=========================================="

if ! grep -qiE 'debian|ubuntu' /etc/os-release 2>/dev/null; then
  echo "[ERROR] Debian/Ubuntu 환경이 아닙니다."
  exit 1
fi

mkdir -p "$BASE/memory" "$BASE/scripts" "$BASE/logs"

# Debian PRoot에서 다른 apt/dpkg 작업이 끝날 때까지 기다립니다.
wait_for_apt() {
  local i=0 cmd busy
  while :; do
    busy=0
    for p in /proc/[0-9]*; do
      [ -r "$p/cmdline" ] || continue
      cmd="$(tr '\0' ' ' < "$p/cmdline" 2>/dev/null || true)"
      case "$cmd" in
        *apt-get*|*apt\ *|*dpkg*) busy=1; break ;;
      esac
    done
    [ "$busy" -eq 0 ] && break
    i=$((i+1))
    if [ "$i" -gt 60 ]; then
      echo "[ERROR] apt/dpkg 작업이 60회(약 2분) 이상 끝나지 않았습니다."
      ps -ef 2>/dev/null | grep -E '[a]pt|[d]pkg' || true
      return 1
    fi
    echo "[WAIT] 다른 apt/dpkg 작업이 끝날 때까지 대기합니다... ($i/60)"
    sleep 2
  done
}

finish_dpkg() {
  dpkg --configure -a >/dev/null 2>&1 || true
}

echo "[1/4] Debian 기본 도구"
wait_for_apt || exit 1
finish_dpkg
apt-get update
wait_for_apt || exit 1
DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl git bash coreutils findutils python3 python3-venv python3-pip

# CA 번들이 설치/복구됐는지 확인합니다.
if [ ! -s /etc/ssl/certs/ca-certificates.crt ]; then
  echo "[ERROR] /etc/ssl/certs/ca-certificates.crt를 복구하지 못했습니다."
  exit 1
fi

echo
echo "=========================================="
echo " Debian AI 도구 설치 선택"
echo "=========================================="
echo "  1) Hermes Agent"
echo "  2) OpenClaw"
echo "  3) OpenCode"
echo "  4) 모두 설치"
echo "  5) 모두 건너뛰기"

if [ -r /dev/tty ]; then
  printf "선택 [1-5, 기본값 4]: "
  read -r AI_CHOICE </dev/tty || AI_CHOICE="4"
else
  AI_CHOICE="4"
fi

INSTALL_HERMES=0
INSTALL_OPENCLAW=0
INSTALL_OPENCODE=0

case "$AI_CHOICE" in
  1) INSTALL_HERMES=1 ;;
  2) INSTALL_OPENCLAW=1 ;;
  3) INSTALL_OPENCODE=1 ;;
  4|"") INSTALL_HERMES=1; INSTALL_OPENCLAW=1; INSTALL_OPENCODE=1 ;;
  5) ;;
  *) echo "[WARN] 잘못된 선택입니다. 모두 설치합니다."; INSTALL_HERMES=1; INSTALL_OPENCLAW=1; INSTALL_OPENCODE=1 ;;
esac

echo
echo "[2/4] 선택된 AI 도구"
[ "$INSTALL_HERMES" -eq 1 ] && echo "  [✓] Hermes Agent"
[ "$INSTALL_OPENCLAW" -eq 1 ] && echo "  [✓] OpenClaw"
[ "$INSTALL_OPENCODE" -eq 1 ] && echo "  [✓] OpenCode"
[ "$INSTALL_HERMES" -eq 0 ] && [ "$INSTALL_OPENCLAW" -eq 0 ] && [ "$INSTALL_OPENCODE" -eq 0 ] && echo "  [--] AI 도구 없음"

install_hermes() {
  echo
  echo "----- Hermes Agent (공식 Linux 설치기) -----"
  if command -v hermes >/dev/null 2>&1; then
    echo "[OK] Hermes already installed"
    hermes --version 2>/dev/null || true
    return 0
  fi

  if curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash; then
    export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"
    echo "[OK] Hermes 설치 완료"
    hermes --version 2>/dev/null || true
  else
    echo "[WARN] Hermes 설치 실패"
    return 1
  fi
}

install_openclaw() {
  echo
  echo "----- OpenClaw (공식 Linux 설치기) -----"
  if command -v openclaw >/dev/null 2>&1; then
    echo "[OK] OpenClaw already installed"
    openclaw --version 2>/dev/null || true
    return 0
  fi

  if curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | bash -s -- --no-onboard; then
    export PATH="/usr/local/bin:$HOME/.local/bin:$HOME/.openclaw/bin:$PATH"
    echo "[OK] OpenClaw 설치 완료"
    openclaw --version 2>/dev/null || true
  else
    echo "[WARN] OpenClaw 설치 실패"
    return 1
  fi
}

install_opencode() {
  echo
  echo "----- OpenCode (공식 설치기) -----"
  if command -v opencode >/dev/null 2>&1; then
    echo "[OK] OpenCode already installed"
    opencode --version 2>/dev/null || true
    return 0
  fi

  if curl -fsSL https://opencode.ai/install | bash; then
    export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"
    echo "[OK] OpenCode 설치 완료"
    opencode --version 2>/dev/null || true
  else
    echo "[WARN] OpenCode 설치 실패"
    return 1
  fi
}

[ "$INSTALL_HERMES" -eq 1 ] && install_hermes || true
[ "$INSTALL_OPENCLAW" -eq 1 ] && install_openclaw || true
[ "$INSTALL_OPENCODE" -eq 1 ] && install_opencode || true

echo
echo "[3/4] YangYang AI 메모리/스크립트"

download() {
  local rel="$1"
  local dest="$2"
  local tmp
  tmp="$(mktemp)"
  echo "[DOWNLOAD] $rel"

  if curl --fail --location --silent --show-error "$REPO/$rel" -o "$tmp" && [ -s "$tmp" ]; then
    mv "$tmp" "$dest"
    echo "[OK] $dest"
  else
    rm -f "$tmp"
    echo "[WARN] 다운로드 실패: $rel"
  fi
}

for f in AI_CONTEXT.md AI_INSTRUCTIONS.md story_memory.json ai_family.md independent_life.md mars_exploration.md yangyang_city.md korean_independence.md; do
  download "memory/$f" "$BASE/memory/$f"
done

for f in ai-start.sh ai-control.sh ai-clean.sh memory-update.py; do
  download "scripts/$f" "$BASE/scripts/$f"
done

chmod +x "$BASE"/scripts/*.sh 2>/dev/null || true

echo
echo "[4/4] 설치 확인"
echo "OS: $(. /etc/os-release && echo "$PRETTY_NAME")"
echo "Arch: $(uname -m)"
python3 --version
git --version
command -v hermes >/dev/null 2>&1 && hermes --version 2>/dev/null || echo "[--] Hermes"
command -v openclaw >/dev/null 2>&1 && openclaw --version 2>/dev/null || echo "[--] OpenClaw"
command -v opencode >/dev/null 2>&1 && opencode --version 2>/dev/null || echo "[--] OpenCode"

echo
echo "=========================================="
echo " Debian AI 설치 완료"
echo "=========================================="
echo "메모리: $BASE/memory"
echo "Termux의 기존 AI 설정은 변경하지 않았습니다."
