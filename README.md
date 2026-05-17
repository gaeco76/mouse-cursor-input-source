# Mouse Cursor Input Source

macOS에서 현재 키보드 입력 소스(한글/영문)에 따라 마우스 커서 색상을 변경하고, 메뉴 바에 입력 소스 상태를 표시하는 도구입니다. 웹 기반 설정 패널을 통해 ON/OFF 및 세부 동작을 제어할 수 있습니다.

## 기능

- **커서 색상 변경**: 한글 입력 시 파란색, 영문 입력 시 빨간색 커서 표시
- **이동 중 숨김**: 마우스 이동 시 커서를 숨기고 멈추면 다시 표시
- **메뉴 바 동작**: 메뉴 바에 현재 입력 소스 색상으로 상태 표시
- **시작 프로그램 등록**: 로그인 시 자동 실행
- **웹 제어 패널**: 브라우저에서 http://127.0.0.1:5001 로 접속하여 설정

## 프로젝트 구조

```
mouse-cursor-input-source/
├── MouseCursorInputSource/
│   ├── main.swift              # 커서 오버레이 앱 (Swift)
│   └── webapp/
│       ├── app.py              # Flask 웹 서버
│       ├── requirements.txt
│       └── templates/
│           └── index.html      # 웹 설정 UI
├── InputSourceMenu/
│   └── main.swift              # 메뉴 바 앱 (Swift)
├── install.sh                  # 설치 스크립트
└── README.md
```

## 요구사항

- macOS 12.0 이상
- Swift 5.9 이상
- Python 3.10 이상

## 설치 방법

### 1. 저장소 클론

```bash
git clone https://github.com/<username>/mouse-cursor-input-source.git
cd mouse-cursor-input-source
```

### 2. 설치 스크립트 실행

```bash
chmod +x install.sh
./install.sh
```

또는 수동으로 설치:

```bash
# 1. 커서 앱 빌드
cd MouseCursorInputSource
swiftc -o MouseCursorInputSource main.swift -framework Cocoa -framework Carbon
open MouseCursorInputSource.app

# 2. 메뉴 바 앱 빌드
cd ../InputSourceMenu
swiftc -o InputSourceChecker main.swift -framework Cocoa -framework Carbon
./InputSourceChecker &

# 3. 웹 서버 실행
cd ../MouseCursorInputSource/webapp
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python app.py &
```

### 3. 웹 설정 패널 접속

브라우저에서 http://127.0.0.1:5001 에 접속합니다.

## 웹 설정 패널

| 기능 | 설명 |
|------|------|
| 커서 색상 변경 | 한글/영문에 따라 커서 색상 변경 ON/OFF |
| 이동 중 숨김 | 마우스 이동 시 커서 숨김 / 멈추면 표시 |
| 메뉴 바 동작 | 메뉴 바 입력 소스 표시 ON/OFF |
| 시작 프로그램 등록 | 로그인 시 자동 실행 |

## 설정 파일

앱 설정은 `/tmp/.mousecursor_settings.json`에 저장됩니다:

```json
{
  "enabled": true,
  "idleHide": true
}
```

## 주의사항

- **커서 복구**: 앱이 강제 종료되어 시스템 커서가 사라진 경우, 터미널에서 `tput cnorm`를 실행하세요.
- **중복 실행**: 수동 실행과 LaunchAgent 동시 실행을 피하세요. 웹 패널에서 "시작 프로그램 등록"을 사용하는 것을 권장합니다.

## 라이선스

MIT License
