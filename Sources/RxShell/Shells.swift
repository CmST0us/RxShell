//
// Created by eki on 23-11-25.
//

import Foundation

public struct Shells {
    public let commands: [Shell]

    public var environment: [String: String]

    public let workingDirectory: String

    public var verbose: Bool

    public init(workingDirectory: String = "", verbose: Bool = false, environment: [String: String] = [:], @ShellsBuilder _ shells: () -> [Shell]) {
        self.environment = environment
        self.workingDirectory = workingDirectory
        self.verbose = verbose
        commands = shells()
    }

    public var action: ShellAction {
        commands.reduce(ShellAction.just(.bypass)) { (partialResult: ShellAction, shell: Shell) -> ShellAction in
            partialResult.flatMap { _ in
                let process = Process()
                process.environment = self.environment
                process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
                return shell.action(process: process, verbose: verbose)
            }
        }
    }
}