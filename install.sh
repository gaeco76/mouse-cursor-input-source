#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "📦 Mouse Cursor Input Source 설치를 시작합니다..."
echo "   설치 경로: $SCRIPT_DIR"

# 1. 커서 오버레이 앱 빌드
echo ""
echo "🔨 [1/4] 커서 오버레이 앱 빌드 중..."
cd "$SCRIPT_DIR/MouseCursorInputSource"
if [ ! -d "MouseCursorInputSource.app" ]; then
    mkdir -p MouseCursorInputSource.app/Contents/MacOS
fi
swiftc -o MouseCursorInputSource main.swift -framework Cocoa -framework Carbon
cp MouseCursorInputSource MouseCursorInputSource.app/Contents/MacOS/
echo "   ✅ MouseCursorInputSource.app 생성 완료"

# 2. 메뉴 바 앱 빌드
echo ""
echo "🔨 [2/4] 메뉴 바 앱 빌드 중..."
cd "$SCRIPT_DIR/InputSourceMenu"
mkdir -p InputSourceChecker.app/Contents/MacOS
swiftc -o InputSourceChecker main.swift -framework Cocoa -framework Carbon
cp InputSourceChecker InputSourceChecker.app/Contents/MacOS/
echo "   ✅ InputSourceChecker.app 생성 완료"

# 3. Python 가상환경 및 Flask 설치
echo ""
echo "🐍 [3/4] 웹 서버 환경 설정 중..."
cd "$SCRIPT_DIR/MouseCursorInputSource/webapp"
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi
source .venv/bin/activate
pip install -q -r requirements.txt
echo "   ✅ Flask 설치 완료"

# 4. LaunchAgent 설정 (선택)
echo ""
echo "🚀 [4/4] LaunchAgent 등록 (선택사항)"
LAUNCH_PLIST="$HOME/Library/LaunchAgents/com.user.mousecursorinputsource.plist"
if [ ! -f "$LAUNCH_PLIST" ]; then
    cat > "$LAUNCH_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.mousecursorinputsource</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SCRIPT_DIR/MouseCursorInputSource/MouseCursorInputSource.app/Contents/MacOS/MouseCursorInputSource</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
EOF
    launchctl load "$LAUNCH_PLIST" 2>/dev/null || true
    echo "   ✅ LaunchAgent 등록 완료 (로그인 시 자동 실행)"
else
    echo "   ℹ️ LaunchAgent가 이미 등록되어 있습니다"
fi

echo ""
echo "🎉 설치 완료!"
echo ""
echo "실행 방법:"
echo "  1. 웹 서버: cd '$SCRIPT_DIR/MouseCursorInputSource/webapp' && source .venv/bin/activate && python app.py"
echo "  2. 메뉴 바: '$SCRIPT_DIR/InputSourceMenu/InputSourceChecker &'"
echo "  3. 웹 설정: http://127.0.0.1:5001"
