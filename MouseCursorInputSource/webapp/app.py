import os
import subprocess
import plistlib
import json
from flask import Flask, render_template, jsonify

app = Flask(__name__)

# 프로젝트 루트 경로 자동 탐지 (app.py 기준: .../MouseCursorInputSource/webapp/app.py)
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

APP_NAME = "MouseCursorInputSource"
APP_PATH = os.path.join(PROJECT_ROOT, "MouseCursorInputSource", "MouseCursorInputSource.app")
MENUBAR_NAME = "InputSourceChecker"
MENUBAR_PATH = os.path.join(PROJECT_ROOT, "InputSourceMenu", "InputSourceChecker")
LAUNCH_LABEL = "com.user.mousecursorinputsource"
LAUNCH_PLIST = os.path.expanduser(f"~/Library/LaunchAgents/{LAUNCH_LABEL}.plist")
SETTINGS_PATH = "/tmp/.mousecursor_settings.json"

DEFAULT_SETTINGS = {"enabled": True, "idleHide": True}

def is_running():
    result = subprocess.run(["pgrep", "-x", APP_NAME], capture_output=True)
    return result.returncode == 0

def is_menubar_running():
    result = subprocess.run(["pgrep", "-x", MENUBAR_NAME], capture_output=True)
    return result.returncode == 0

def is_launch_enabled():
    return os.path.exists(LAUNCH_PLIST)

def read_settings():
    try:
        with open(SETTINGS_PATH, "r") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return DEFAULT_SETTINGS.copy()

def write_settings(settings):
    with open(SETTINGS_PATH, "w") as f:
        json.dump(settings, f)

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/api/status")
def status():
    settings = read_settings()
    return jsonify({
        "running": is_running(),
        "launch_enabled": is_launch_enabled(),
        "idle_hide": settings.get("idleHide", True),
        "menubar_running": is_menubar_running()
    })

@app.route("/api/start")
def start_app():
    if not is_running():
        subprocess.Popen(["open", APP_PATH])
    return jsonify({"success": True, "running": True})

@app.route("/api/stop")
def stop_app():
    subprocess.run(["killall", APP_NAME], capture_output=True)
    return jsonify({"success": True, "running": False})

@app.route("/api/toggle_idle_hide")
def toggle_idle_hide():
    settings = read_settings()
    settings["idleHide"] = not settings.get("idleHide", True)
    write_settings(settings)
    return jsonify({"success": True, "idle_hide": settings["idleHide"]})

@app.route("/api/start_menubar")
def start_menubar():
    if not is_menubar_running():
        subprocess.Popen([MENUBAR_PATH], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return jsonify({"success": True, "menubar_running": True})

@app.route("/api/stop_menubar")
def stop_menubar():
    subprocess.run(["killall", MENUBAR_NAME], capture_output=True)
    return jsonify({"success": True, "menubar_running": False})

@app.route("/api/enable_launch")
def enable_launch():
    os.makedirs(os.path.dirname(LAUNCH_PLIST), exist_ok=True)
    binary_path = os.path.join(APP_PATH, "Contents/MacOS", APP_NAME)
    plist = {
        "Label": LAUNCH_LABEL,
        "ProgramArguments": [binary_path],
        "RunAtLoad": True,
        "KeepAlive": False
    }
    with open(LAUNCH_PLIST, "wb") as f:
        plistlib.dump(plist, f)
    subprocess.run(["launchctl", "load", LAUNCH_PLIST], capture_output=True)
    return jsonify({"success": True, "launch_enabled": True})

@app.route("/api/disable_launch")
def disable_launch():
    if os.path.exists(LAUNCH_PLIST):
        subprocess.run(["launchctl", "unload", LAUNCH_PLIST], capture_output=True)
        os.remove(LAUNCH_PLIST)
    return jsonify({"success": True, "launch_enabled": False})

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5001, debug=False)
