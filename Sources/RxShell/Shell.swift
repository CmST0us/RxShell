//
// Created by eki on 23-11-25.
//

import Foundation
import RxSwift

public enum ShellError: Error {
    case noPipe
    case error(code: Int, message: String)

    var code: Int {
        switch self {
        case .noPipe:
            return -1
        case .error(let code, _):
            return code
        }
    }

    public var message: String {
        switch self {
        case .noPipe:
            return "unknown"
        case .error(_, let message):
            return message
        }
    }
}

public enum ShellResult {
    case bypass
    case string(value: String)

    public var message: String {
        switch self {
        case .string(let message):
            return message
        default:
            return ""
        }
    }
}

public typealias ShellAction = Single<ShellResult>

public func Command(_ command: String) -> Shell {
    return Shell(process: command, arguments: [])
}

public func Commands(@ShellsBuilder _ commands: () -> [Shell]) -> Shell {
    let command = commands().map { shell -> String in
        shell.command
    }.joined(separator: " && ")
    return Command(command)
}

public func Commands(@ArgumentBuilder _ commands: () -> [String]) -> Shell {
    let command = commands().map { s -> Shell in
        return Command(s)
    }.map { shell -> String in
        shell.command
    }.joined(separator: " && ")
    return Command(command)
}

public struct Shell {

    public let process: String

    public let arguments: [String]

    public init(process: String, arguments: [String]) {
        self.process = process
        self.arguments = arguments
    }

    public func run(process processContext: Process = Process(), verbose: Bool = false) -> Result<ShellResult, ShellError> {
        do {
            let result = try processContext.launchBash(with: command, verbose: verbose)
            return .success(.string(value: result))
        } catch let shellError as ShellOutError {
            return .failure(.error(code: Int(shellError.terminationStatus), message: shellError.message))
        } catch {
            return .failure(.error(code: -1, message: "Command: \(command), \(error.localizedDescription)"))
        }
    }

    public var command: String {
        "\(self.process) \(arguments.joined(separator: " "))"
    }

    public var action: ShellAction {
        return action(process: Process())
    }

    public func action(process: Process, verbose: Bool = false) -> ShellAction {
        return .create { observer in
            switch self.run(process: process, verbose: verbose) {
            case .success(let result):
                observer(.success(result))
            case .failure(let error):
                observer(.failure(error))
            }
            return Disposables.create()
        }
    }

    public static func path(_ path: String, @ArgumentBuilder _ arguments: () -> [String]) -> Shell {
        return Shell(process: path, arguments: arguments())
    }
}

// MARK: Shell Command
extension Shell {
    public static func cd(@ArgumentBuilder _ argument: () -> [String]) -> Shell {
        return path("cd", argument)
    }

    public static func ls(@ArgumentBuilder _ argument: () -> [String]) -> Shell {
        return path("ls", argument)
    }

    public static func removeFileIfExist(_ path: String) -> Shell {
        return Command("if [ -f \(path) ]; then rm -f \(path); fi")
    }

    public static func removeDirectoryIfExist(_ path: String) -> Shell {
        return Command("if [ -d \(path) ]; then rm -rf \(path); fi")
    }
}