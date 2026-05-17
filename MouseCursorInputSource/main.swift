import Cocoa
import Carbon
import CoreGraphics

class AppDelegate: NSObject, NSApplicationDelegate {
    var cursorWindow: NSWindow!
    var cursorImageView: NSImageView!
    var timer: Timer?
    var mouseTrackingTimer: Timer?
    var lastSourceID: String = ""
    var monitor: Any?

    // 설정 파일
    let settingsPath = "/tmp/.mousecursor_settings.json"
    var settings: [String: Bool] = ["enabled": true, "idleHide": true]

    // 마우스 멈춤 감지
    var lastMouseMoveTime = Date()
    var isCustomCursorVisible = false
    let idleThreshold: TimeInterval = 0.15

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        setupCursorWindow()
        setupMouseTracking()
        startInputSourcePolling()
        startSettingsPolling()

        updateCursorVisibility()
    }

    func applicationWillTerminate(_ notification: Notification) {
        showSystemCursor()
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
        mouseTrackingTimer?.invalidate()
    }

    // MARK: - 설정 파일 읽기
    func readSettings() {
        guard FileManager.default.fileExists(atPath: settingsPath),
              let data = FileManager.default.contents(atPath: settingsPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Bool] else { return }
        settings = json
    }

    func startSettingsPolling() {
        readSettings()
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.readSettings()
        }
    }

    // MARK: - 커서 윈도우 설정
    func setupCursorWindow() {
        let size = NSSize(width: 32, height: 32)
        cursorWindow = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        cursorWindow.backgroundColor = .clear
        cursorWindow.isOpaque = false
        cursorWindow.level = .init(rawValue: Int(CGWindowLevelForKey(.cursorWindow)) + 1)
        cursorWindow.ignoresMouseEvents = true
        cursorWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        cursorWindow.hasShadow = false

        cursorImageView = NSImageView(frame: NSRect(origin: .zero, size: size))
        cursorImageView.imageScaling = .scaleNone
        cursorWindow.contentView = cursorImageView

        updateCursorImage()
    }

    // MARK: - 마우스 추적
    func setupMouseTracking() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]) { [weak self] _ in
            self?.lastMouseMoveTime = Date()
            self?.updateCursorPosition()
        }

        mouseTrackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0/120.0, repeats: true) { [weak self] _ in
            self?.updateCursorPosition()
            self?.updateCursorVisibility()
        }

        updateCursorPosition()
    }

    func updateCursorPosition() {
        let loc = NSEvent.mouseLocation
        let size = cursorWindow.frame.size
        let origin = NSPoint(x: loc.x, y: loc.y - size.height + 4)
        cursorWindow.setFrameOrigin(origin)
    }

    func updateCursorVisibility() {
        let enabled = settings["enabled"] ?? true
        let idleHide = settings["idleHide"] ?? true

        if !enabled {
            if isCustomCursorVisible { hideCustomCursor() }
            return
        }

        let idleTime = Date().timeIntervalSince(lastMouseMoveTime)
        let shouldShow = idleHide ? (idleTime >= idleThreshold) : true

        if shouldShow && !isCustomCursorVisible {
            showCustomCursor()
        } else if !shouldShow && isCustomCursorVisible {
            hideCustomCursor()
        }
    }

    func showCustomCursor() {
        cursorWindow.alphaValue = 1.0
        cursorWindow.orderFront(nil)
        NSCursor.hide()
        isCustomCursorVisible = true
    }

    func hideCustomCursor() {
        cursorWindow.alphaValue = 0.0
        cursorWindow.orderOut(nil)
        NSCursor.unhide()
        isCustomCursorVisible = false
    }

    // MARK: - 입력 소스 감지
    func startInputSourcePolling() {
        updateInputSource()
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.updateInputSource()
        }
    }

    func updateInputSource() {
        guard let currentSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return }
        guard let sourceIDPtr = TISGetInputSourceProperty(currentSource, kTISPropertyInputSourceID) else { return }
        let sourceID = Unmanaged<CFString>.fromOpaque(sourceIDPtr).takeUnretainedValue() as String

        if sourceID == lastSourceID { return }
        lastSourceID = sourceID

        DispatchQueue.main.async {
            self.updateCursorImage()
        }
    }

    func updateCursorImage() {
        let isKorean = lastSourceID.contains("Korean")
        let fillColor: NSColor = isKorean
            ? NSColor(calibratedRed: 0.0, green: 0.2, blue: 0.5, alpha: 1.0)
            : NSColor(calibratedRed: 0.92, green: 0.22, blue: 0.22, alpha: 1.0)
        cursorImageView.image = createMacOSArrowCursor(fillColor: fillColor)
    }

    func createMacOSArrowCursor(fillColor: NSColor) -> NSImage {
        let size = NSSize(width: 28, height: 28)
        let image = NSImage(size: size)
        image.lockFocus()

        let transform = NSAffineTransform()
        transform.translateX(by: 0, yBy: size.height)
        transform.scaleX(by: 1, yBy: -1)
        transform.concat()

        let path = NSBezierPath()
        path.move(to: NSPoint(x: 0, y: 0))
        path.line(to: NSPoint(x: 17, y: 17))
        path.line(to: NSPoint(x: 12, y: 17))
        path.line(to: NSPoint(x: 14, y: 23))
        path.line(to: NSPoint(x: 10, y: 23))
        path.line(to: NSPoint(x: 8, y: 17))
        path.line(to: NSPoint(x: 0, y: 17))
        path.close()

        let shadowPath = path.copy() as! NSBezierPath
        shadowPath.transform(using: AffineTransform(translationByX: 1, byY: -1))
        NSColor.black.withAlphaComponent(0.25).setFill()
        shadowPath.fill()

        fillColor.setFill()
        path.fill()

        NSColor.black.setStroke()
        path.lineWidth = 1.5
        path.stroke()

        let highlightPath = path.copy() as! NSBezierPath
        highlightPath.transform(using: AffineTransform(translationByX: 0, byY: 0.5))
        NSColor.white.withAlphaComponent(0.35).setStroke()
        highlightPath.lineWidth = 0.5
        highlightPath.stroke()

        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    func showSystemCursor() {
        NSCursor.unhide()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
