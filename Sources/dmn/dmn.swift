import Cocoa
import ArgumentParser

struct Command: Codable {
    let executable: String
    let arguments: [String]
}

@discardableResult
func shell(_ exec: String, args: [String], mode isDark: Bool) -> Int32 {
    let task = Process()
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
public struct dmn: ParsableCommand {
    public init() {}

    private var commandsFiles: [URL] = []

    public func callback() {
        let commands = commandsFiles.flatMap { path in
            do {
                print("[callback] Reading from \(path.absoluteString)")
                let data = try Data(contentsOf: path)
                print("[callback] Read contents of \(path.absoluteString)")
                let commands: [Command] = try JSONDecoder().decode([Command].self, from: data)
                print("[callback] Decoded \(commands.count) command(s) from \(path.absoluteString)")
                return commands
            } catch {
                print("[callback] Error while reading/decoding \(path.absoluteString); skipping")
                return []
            }
        }
        print("[callback] Decoded \(commands.count) command(s) to run")

        let isDark: Bool
        if #available(macOS 10.14, *) {
            if #available(macOS 11, *) {
                isDark = NSAppearance.currentDrawing().bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            } else {
                isDark = NSAppearance.current.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            }
        } else {
            isDark = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
        }
        print("[callback] isDark: \(isDark)")

        for command in commands {
            print("[callback] Running command `\(command.executable)` with argument(s) '\(command.arguments.joined(separator: "', '"))'")
            shell(command.executable, args: command.arguments.map { $0.replacingOccurrences(of: "{}", with: isDark ? "dark" : "light")}, mode: isDark)
        }
        fflush(stdout)
        fflush(stderr)
    }

    private static var observation: NSKeyValueObservation?
    private mutating func registerCallbacks() {
        if #available(macOS 10.14, *) {
            print("Registering appearance change callback")
            Self.observation = NSApplication.shared.observe(\.effectiveAppearance) { [self] (app, _) in
                callback()
            }
        } else {
            print("Registering legacy theme change callback")
            DistributedNotificationCenter.default.addObserver(
                    forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
                    object: nil,
                    queue: nil) { [self] (notification) in
                callback()
            }
        }
        print("Registering wake callback")
        NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: nil) { [self] (notification) in
            callback()
        }
    }

    @Option var extraCommandsFile: [String] = []
    @Flag var ignoreUserCommandsFile: Bool = false

    public mutating func run() throws {
        commandsFiles = extraCommandsFile.map(URL.init(fileURLWithPath:))
        if !ignoreUserCommandsFile {
            let dir = ProcessInfo.processInfo.environment["XDG_CONFIG_DIR", default: "~/.config"]
            let url = URL(fileURLWithPath: dir.replacingOccurrences(of: "~", with: FileManager.default.homeDirectoryForCurrentUser.absoluteString)).appendingPathComponent("dmn").appendingPathComponent("commands.json")
            commandsFiles.append(url)
        }
        print("[setup] Detected \(commandsFiles.count) file(s):")
        print(commandsFiles.map { "- " + $0.absoluteString }.joined(separator: "\n"))

        callback()
        registerCallbacks()
        NSApplication.shared.run()
    }
}
