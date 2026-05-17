import Cocoa
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?
    var lastSourceID: String = ""
    let settingsPath = "/tmp/.mousecursor_settings.json"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.action = #selector(showMenu(_:))
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        updateInputSource()

        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            self.updateInputSource()
        }
    }

    @objc func showMenu(_ sender: Any?) {
        let menu = NSMenu()

        let idleHideItem = NSMenuItem(
            title: "이동 중 숨김",
            action: #selector(toggleIdleHide(_:)),
            keyEquivalent: ""
        )
        idleHideItem.state = isIdleHideEnabled() ? .on : .off
        menu.addItem(idleHideItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "종료",
            action: #selector(quitApp(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc func toggleIdleHide(_ sender: NSMenuItem) {
        var settings = readSettings()
        settings["idleHide"] = !(settings["idleHide"] as? Bool ?? true)
        writeSettings(settings)
    }

    @objc func quitApp(_ sender: NSMenuItem) {
        NSApp.terminate(nil)
    }

    func isIdleHideEnabled() -> Bool {
        return readSettings()["idleHide"] as? Bool ?? true
    }

    func readSettings() -> [String: Any] {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: settingsPath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ["enabled": true, "idleHide": true]
        }
        return json
    }

    func writeSettings(_ settings: [String: Any]) {
        if let data = try? JSONSerialization.data(withJSONObject: settings) {
            try? data.write(to: URL(fileURLWithPath: settingsPath))
        }
    }

    func updateInputSource() {
        guard let currentSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return }
        guard let sourceIDPtr = TISGetInputSourceProperty(currentSource, kTISPropertyInputSourceID) else { return }
        let sourceID = Unmanaged<CFString>.fromOpaque(sourceIDPtr).takeUnretainedValue() as String

        if sourceID == lastSourceID { return }
        lastSourceID = sourceID

        let isKorean = sourceID.contains("Korean")
        let image = createStatusImage(isKorean: isKorean)

        DispatchQueue.main.async {
            self.statusItem.button?.image = image
        }
    }

    func createStatusImage(isKorean: Bool) -> NSImage {
        let height: CGFloat = 22
        let baseWidth: CGFloat = 80
        let width: CGFloat = baseWidth * 8

        let bgColor: NSColor = isKorean
            ? NSColor(calibratedRed: 0.0, green: 0.2, blue: 0.5, alpha: 1.0)
            : NSColor(calibratedRed: 0.92, green: 0.22, blue: 0.22, alpha: 1.0)

        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()

        let bgRect = NSRect(x: 0, y: 0, width: width, height: height)
        let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: 6, yRadius: 6)
        bgColor.setFill()
        bgPath.fill()

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
