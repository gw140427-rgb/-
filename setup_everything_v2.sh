#!/bin/bash

set -e

echo "=================================================="
echo "🖥️ [1/6] GUI, ADB, noVNC(웹 접속), tmux 패키지 설치..."
echo "=================================================="
apt update && apt upgrade -y
apt install -y xfce4 xfce4-terminal tigervnc-standalone-server \
               android-tools-adb python3 python3-pip python3-venv \
               scrot xdotool wget curl git nodejs npm novnc websockify tmux

echo "=================================================="
echo "📦 [2/6] Python 가상환경 및 AI/텔레그램 라이브러리 설치..."
echo "=================================================="
python3 -m venv ~/ai_env
source ~/ai_env/bin/activate
pip install --upgrade pip
pip install pyautogui opencv-python pillow requests \
            google-generativeai openai anthropic \
            python-telegram-bot telethon

echo "=================================================="
echo "🦙 [3/6] Hermes + OpenClaw + Claude Code + Codex 실물 설치..."
echo "=================================================="
cd ~

# 1. Hermes Agent
if [ ! -d "hermes-agent" ]; then
  git clone https://github.com/NousResearch/Hermes-Function-Calling.git hermes-agent || \
  git clone https://github.com/NousResearch/Hermes-LLM.git hermes-agent
fi
pip install -r ~/hermes-agent/requirements.txt || true

# 2. OpenClaw CLI
npm install -g openclaw-cli || npm install -g openclaw || true
if [ ! -d "openclaw" ]; then
  git clone https://github.com/openclaw/openclaw.git openclaw || mkdir -p openclaw
fi

# 3. Claude Code CLI
npm install -g @anthropic-ai/claude-code || true

# 4. OpenAI Codex CLI
npm install -g openai-codex || npm install -g openai || true

echo "=================================================="
echo "📂 [4/6] 텔레그램 토큰 설정 및 멀티 에이전트 엔진 생성..."
echo "=================================================="
mkdir -p ~/ai_agent/config
mkdir -p ~/ai_agent/core

# 토큰 파일 저장
cat << 'EOF' > ~/ai_agent/config/telegram_tokens.json
{
  "bots": [
    {"name": "Codex Bot (코드 생성)", "token": "8676742387:AAHA23dwRTCXGHI38Cf9JosN_EyI8KBmcDs"},
    {"name": "OpenClaw Bot (GUI/브라우저)", "token": "8836266879:AAGWDqFwwBBd3Kb7OqPd4nb2W2lYta4XVlU"},
    {"name": "Claude Code Bot (터미널 제어)", "token": "8672793471:AAGUexDEKlSgtfwMtWVrgOmibTefPUOXMwk"},
    {"name": "Hermes Bot (자율 추론)", "token": "8699706830:AAGGzRmNSxHlJ_vqQFB9fNV8VoIh0hdXCeE"},
    {"name": "ADB Phone Bot (폰 제어)", "token": "8945688211:AAEVifDWEB7oNvq_ZsDnI81iTlkPv5N4Czk"}
  ]
}
EOF

# 멀티 에이전트 메인 제어 코드
cat << 'EOF' > ~/ai_agent/core/telegram_multi_agents.py
import os
import json
import asyncio
import subprocess
import logging
from telegram import Update
from telegram.ext import ApplicationBuilder, MessageHandler, filters, ContextTypes

CONFIG_PATH = os.path.expanduser("~/ai_agent/config/telegram_tokens.json")
logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO)

async def handle_codex(update: Update, context: ContextTypes.DEFAULT_TYPE):
    prompt = update.message.text
    await update.message.reply_text(f"💻 [Codex] 코드 생성 중...")
    proc = await asyncio.create_subprocess_shell(
        f"source ~/ai_env/bin/activate && python3 -c \"import openai; print(openai.Completion.create(engine='code-davinci-002', prompt='''{prompt}''', max_tokens=500)['choices'][0]['text'])\"",
        stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
    )
    stdout, stderr = await proc.communicate()
    output = stdout.decode() if stdout else stderr.decode()
    await update.message.reply_text(f"📝 [Codex Output]:\n```python\n{output[:1500]}\n```", parse_mode="Markdown")

async def handle_openclaw(update: Update, context: ContextTypes.DEFAULT_TYPE):
    task = update.message.text
    await update.message.reply_text(f"🦀 [OpenClaw] 작업 실행: '{task}'")
    proc = await asyncio.create_subprocess_shell(
        f"openclaw-cli --task '{task}'",
        stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
    )
    stdout, stderr = await proc.communicate()
    os.system("scrot ~/vnc_screen.png")
    await update.message.reply_text(f"✅ [OpenClaw] 완료!\n```\n{stdout.decode()[:1000]}\n```", parse_mode="Markdown")
    if os.path.exists(os.path.expanduser("~/vnc_screen.png")):
        with open(os.path.expanduser("~/vnc_screen.png"), 'rb') as photo:
            await update.message.reply_photo(photo=photo, caption="📸 OpenClaw 작업 GUI 스크린샷")

async def handle_claude(update: Update, context: ContextTypes.DEFAULT_TYPE):
    task = update.message.text
    await update.message.reply_text(f"🧠 [Claude Code] CLI 연동 진행: '{task}'")
    proc = await asyncio.create_subprocess_shell(
        f"claude '{task}'",
        stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
    )
    stdout, stderr = await proc.communicate()
    output_msg = stdout.decode() if stdout else "작업 완료"
    await update.message.reply_text(f"📝 [Claude Code] 보고서:\n```\n{output_msg[:1500]}\n```", parse_mode="Markdown")

async def handle_hermes(update: Update, context: ContextTypes.DEFAULT_TYPE):
    prompt = update.message.text
    await update.message.reply_text(f"🦙 [Hermes] 자율 추론 실행...")
    proc = await asyncio.create_subprocess_shell(
        f"source ~/ai_env/bin/activate && python3 ~/hermes-agent/main.py --prompt '{prompt}'",
        stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
    )
    stdout, stderr = await proc.communicate()
    await update.message.reply_text(f"💡 [Hermes] 결과:\n{stdout.decode()[:1500]}")

async def handle_phone(update: Update, context: ContextTypes.DEFAULT_TYPE):
    cmd = update.message.text
    await update.message.reply_text(f"📱 [ADB Phone] 실행: '{cmd}'")
    if "캡처" in cmd or "screen" in cmd:
        os.system("adb shell screencap -p /sdcard/screen.png && adb pull /sdcard/screen.png ~/phone_screen.png")
        if os.path.exists(os.path.expanduser("~/phone_screen.png")):
            with open(os.path.expanduser("~/phone_screen.png"), 'rb') as photo:
                await update.message.reply_photo(photo=photo, caption="📸 실시간 스마트폰 화면")
    else:
        res = subprocess.getoutput(f"adb shell {cmd}")
        await update.message.reply_text(f"📱 [ADB Output]:\n```\n{res}\n```", parse_mode="Markdown")

async def start_bot_engine(token, handler_func, bot_name):
    print(f"🚀 [{bot_name}] 가동 중...")
    app = ApplicationBuilder().token(token).build()
    app.add_handler(MessageHandler(filters.TEXT & (~filters.COMMAND), handler_func))
    await app.initialize()
    await app.start()
    await app.updater.start_polling()
    await asyncio.Event().wait()

async def main():
    with open(CONFIG_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)
    bots = data["bots"]
    handlers = [handle_codex, handle_openclaw, handle_claude, handle_hermes, handle_phone]
    tasks = [start_bot_engine(bots[i]["token"], handlers[i], bots[i]["name"]) for i in range(len(bots))]
    print("🔥 5대 AI 에이전트 군단 동시 가동 시작!")
    await asyncio.gather(*tasks)

if __name__ == '__main__':
    asyncio.run(main())
EOF

echo "=================================================="
echo "🌐 [5/6] GUI 및 Web 접속 서버(noVNC) 구동 스크립트 생성..."
echo "=================================================="
cat << 'EOF' > ~/start_gui.sh
#!/bin/bash
export DISPLAY=:1
vncserver -kill :1 2>/dev/null || true
vncserver :1 -geometry 1280x720 -depth 24
websockify --web=/usr/share/novnc/ 6080 localhost:5901 &
echo "✨ VNC GUI 서버 가동 완료!"
echo "👉 폰 브라우저 접속 주소: http://localhost:6080/vnc.html"
EOF
chmod +x ~/start_gui.sh

echo "=================================================="
echo "⚡ [6/6] 단축 명령어(Alias) 및 tmux 분할 모니터링 등록..."
echo "=================================================="
cat << 'EOF' >> ~/.bashrc

# --- AI System Control Aliases ---
alias run-gui='~/start_gui.sh'
alias run-telegram='source ~/ai_env/bin/activate && python3 ~/ai_agent/core/telegram_multi_agents.py'
alias run-agents-view='tmux new-session -s agents -d "source ~/ai_env/bin/activate && python3 ~/ai_agent/core/telegram_multi_agents.py" \; split-window -h "claude" \; split-window -v "openclaw-cli" \; select-pane -t 0 \; split-window -v "source ~/ai_env/bin/activate && python3 ~/hermes-agent/main.py" \; attach-session -t agents'

alias hermes='source ~/ai_env/bin/activate && python3 ~/hermes-agent/main.py'
alias openclaw='openclaw-cli'
alias claude-code='claude'
alias codex='openai'
EOF

echo ""
echo "🎉 건우야 설치 완성됐다 ㅋㅋㅋㅋ!"
echo "👉 바로 사용하기:"
echo "  1) source ~/.bashrc"
echo "  2) run-gui           (웹 브라우저로 컴퓨터 GUI 볼 수 있게 띄우기: http://localhost:6080/vnc.html)"
echo "  3) run-telegram      (5개 AI 텔레그램 봇 모니터링 가동)"
echo "  4) run-agents-view   (Termux 안에서 터미널 화면 4분할해서 애들 일하는 거 실시간 보기)"
