#!/data/data/com.termux/files/usr/bin/bash
# YangYang AI - read-only status dashboard
# Does not install, stop, restart, or modify any service/configuration.

set +e
BASE="$HOME/YangYang_AI"

line() { printf '%s\n' "------------------------------------------"; }
section() { echo; line; echo "$1"; line; }
check_tool() {
    name="$1"
    if command -v "$name" >/dev/null 2>&1; then
        printf '[설치됨] %s: ' "$name"
        "$name" --version 2>/dev/null | head -n 1
    else
        printf '[없음]   %s\n' "$name"
    fi
}

clear 2>/dev/null || true
echo "=========================================="
echo "       YangYang AI 통합 관제실"
echo "=========================================="
echo "모드: 읽기 전용 (설정 변경 없음)"
echo "시간: $(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 확인 불가)"

section "1. 기기 / 실행 환경"
echo "OS: $(uname -s 2>/dev/null)"
echo "아키텍처: $(uname -m 2>/dev/null)"
echo "커널: $(uname -r 2>/dev/null)"
echo "Termux PREFIX: ${PREFIX:-감지 안 됨}"

section "2. AI 도구 설치 상태"
check_tool hermes
check_tool openclaw
check_tool opencode
check_tool codex
check_tool node
check_tool npm
check_tool python
check_tool git

section "3. 메모리 / 저장 공간"
if command -v free >/dev/null 2>&1; then
    free -h 2>/dev/null || free -m 2>/dev/null
else
    echo "RAM 정보: free 명령 없음"
fi
echo
echo "Termux 홈 저장 공간:"
df -h "$HOME" 2>/dev/null || echo "df 정보 확인 실패"
echo
echo "YangYang AI 폴더:"
if [ -d "$BASE" ]; then
    du -sh "$BASE" 2>/dev/null || echo "폴더 크기 확인 실패"
else
    echo "아직 없음: $BASE"
fi

section "4. 서비스 프로세스 (참고용)"
if command -v pgrep >/dev/null 2>&1; then
    for pattern in 'openclaw' 'hermes' 'opencode'; do
        if pgrep -af "$pattern" 2>/dev/null; then :; else
            echo "$pattern 관련 프로세스가 보이지 않음"
        fi
    done
else
    echo "pgrep 명령 없음 — 프로세스 검사는 생략"
fi

section "5. 메모리 파일"
for file in \
    "$BASE/memory/AI_CONTEXT.md" \
    "$BASE/memory/AI_INSTRUCTIONS.md" \
    "$BASE/memory/story_memory.json"; do
    if [ -s "$file" ]; then
        echo "[있음] $file"
    else
        echo "[없음/비어 있음] $file"
    fi
done

section "관제실 종료"
echo "이 화면은 상태를 조회했을 뿐, 도구나 설정을 변경하지 않았습니다."
echo "다시 실행: bash ~/YangYang_AI/scripts/ai-control.sh"
