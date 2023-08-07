import Cocoa

struct Command: Codable {
    let executable: String
    let arguments: [String]
}

@discardableResult
func shell(_ exec: String, args: [String]) -> Int32 {
    let task = Process()
    let isDark = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
    var env = ProcessInfo.processInfo.environment
    env["DARKMODE"] = isDark ? "1" : "0"
    env["MODE"] = isDark ? "dark" : "light"
    task.environment = env
    task.launchPath = exec
    task.arguments = args
    task.standardError = FileHandle.standardError
    task.standardOutput = FileHandle.standardOutput
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}

@main
public struct dmn {
    public static func callback() throws {
        let dir = ProcessInfo.processInfo.environment["XDG_CONFIG_DIR", default: "~/.config"]
        print("[callback] Reading from \(dir)")
        let url = URL(fileURLWithPath: dir.replacingOccurrences(of: "~", with: FileManager.default.homeDirectoryForCurrentUser.absoluteString)).appendingPathComponent("dmn").appendingPathComponent("commands.json")
        let data = try Data(contentsOf: url)
        print("[callback] Read contents of \(url)")
        let commands: [Command] = try JSONDecoder().decode([Command].self, from: data)
        print("[callback] Decoded \(commands.count) command(s) to run")

        let isDark = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"

        for command in commands {
            print("[callback] Running command `\(command.executable)` with argument(s) '\(command.arguments.joined(separator: "', '"))'")
            shell(command.executable, args: command.arguments.map { $0.replacingOccurrences(of: "{}", with: isDark ? "dark" : "light")})
        }
    }

    private static var observation: NSKeyValueObservation?
    public static func main() {
        try! callback()

        if #available(macOS 10.14, *) {
            print("Registering appearance change callback")
            observation = NSApplication.shared.observe(\.effectiveAppearance) { (app, _) in
                try! callback()
            }
        } else {
            print("Registering legacy theme change callback")
            DistributedNotificationCenter.default.addObserver(
                    forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
                    object: nil,
                    queue: nil) { (notification) in
                try! callback()
            }
        }
        print("Registering wake callback")
        NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: nil) { (notification) in
            try! callback()
        }
        NSApplication.shared.run()
    }
}
