#!/data/data/com.termux/files/usr/bin/bash
# YangYang AI - safe cache cleanup menu
# Only offers npm and pip cache cleanup. Never touches configs, projects, or story memory.
set +e
echo "=========================================="
echo " YangYang AI 용량 정리"
echo "=========================================="
echo "보호: Hermes/OpenClaw/Codex 설정, 프로젝트, YangYang AI 메모리"
echo
show_size() {
  label="$1"; shift
  printf '%-18s ' "$label"
  du -sh "$@" 2>/dev/null | awk '{s+=$1; print $0;}' | head -n 1
}
echo "[검사] 캐시 용량 (있는 항목만 표시)"
for p in "$HOME/.npm" "$HOME/.cache/pip" "$HOME/.cache"; do
  [ -e "$p" ] && du -sh "$p" 2>/dev/null
done
echo
echo "1) npm 캐시 정리"
echo "2) Python pip 캐시 정리"
echo "3) 종료"
printf "선택: "
read -r choice
case "$choice" in
  1)
    if command -v npm >/dev/null 2>&1; then
      echo "npm 캐시만 정리합니다. 프로젝트와 설정은 건드리지 않습니다."
      printf "정말 진행할까? (y/N): "; read -r confirm
      case "$confirm" in
        y|Y) npm cache clean --force ;;
        *) echo "취소됨" ;;
      esac
    else echo "npm이 설치되어 있지 않습니다."; fi
    ;;
  2)
    if command -v python >/dev/null 2>&1; then
      echo "pip 다운로드 캐시만 정리합니다. 설치된 패키지는 삭제하지 않습니다."
      printf "정말 진행할까? (y/N): "; read -r confirm
      case "$confirm" in
        y|Y) python -m pip cache purge ;;
        *) echo "취소됨" ;;
      esac
    else echo "Python이 설치되어 있지 않습니다."; fi
    ;;
  3|"") echo "종료";;
  *) echo "잘못된 선택";;
esac
echo
echo "현재 홈 저장공간:"
df -h "$HOME" 2>/dev/null
