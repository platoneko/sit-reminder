import CoreGraphics
import Foundation

guard CommandLine.arguments.count >= 2, let pid = Int32(CommandLine.arguments[1]) else {
    fputs("usage: assert-onscreen.swift <pid>\n", stderr)
    exit(2)
}

let info = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as! [[String: Any]]
var anyWindow = false
var onscreen = false
for w in info {
    let owner = w[kCGWindowOwnerPID as String] as? Int32 ?? -1
    if owner != pid { continue }
    anyWindow = true
    let visible = w[kCGWindowIsOnscreen as String] as? Bool ?? false
    let bounds = w[kCGWindowBounds as String] as? [String: Any] ?? [:]
    let height = bounds["Height"] as? Double ?? 0
    let width = bounds["Width"] as? Double ?? 0
    // Ignore menubar/titlebar strips; require a real dialog-sized window.
    if visible && width >= 200 && height >= 80 {
        onscreen = true
        print("onscreen dialog pid=\(pid) size=\(Int(width))x\(Int(height))")
    }
}

if !anyWindow {
    fputs("FAIL: no windows for pid \(pid)\n", stderr)
    exit(1)
}
if !onscreen {
    fputs("FAIL: pid \(pid) has windows but none are onscreen dialogs\n", stderr)
    exit(1)
}
print("PASS")
