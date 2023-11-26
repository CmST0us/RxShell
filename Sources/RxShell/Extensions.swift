//
// Created by eki on 23-11-26.
//

import Foundation

public struct ShellOutError: Swift.Error {
    /// The termination status of the command that was run
    public let terminationStatus: Int32
    /// The error message as a UTF8 string, as returned through `STDERR`
    public var message: String { return errorData.shellOutput() }
    /// The raw error buffer data, as returned through `STDERR`
    public let errorData: Data
    /// The raw output buffer data, as retuned through `STDOUT`
    public let outputData: Data
    /// The output of the command as a UTF8 string, as returned through `STDOUT`
    public var output: String { return outputData.shellOutput() }
}

extension ShellOutError: CustomStringConvertible {
    public var description: String {
        return """
               ShellOut encountered an error
               Status code: \(terminationStatus)
               Message: "\(message)"
               Output: "\(output)"
               """
    }
}

extension ShellOutError: LocalizedError {
    public var errorDescription: String? {
        return description
    }
}


extension Data {
    func shellOutput() -> String {
        guard let output = String(data: self, encoding: .utf8) else {
            return ""
        }

        guard !output.hasSuffix("\n") else {
            let endIndex = output.index(before: output.endIndex)
            return String(output[..<endIndex])
        }

        return output

    }
}

extension String {
    var escapingSpaces: String {
        return replacingOccurrences(of: " ", with: "\\ ")
    }

    func appending(argument: String) -> String {
        return "\(self) \"\(argument)\""
    }

    func appending(arguments: [String]) -> String {
        return appending(argument: arguments.joined(separator: "\" \""))
    }

    mutating func append(argument: String) {
        self = appending(argument: argument)
    }

    mutating func append(arguments: [String]) {
        self = appending(arguments: arguments)
    }
}

extension FileHandle {
    var isStandard: Bool {
        return self === FileHandle.standardOutput ||
                self === FileHandle.standardError ||
                self === FileHandle.standardInput
    }
}

extension Process {

    @discardableResult func launchBash(with command: String, verbose: Bool = false) throws -> String {
        executableURL = URL(fileURLWithPath: "/bin/bash")
        arguments = ["-c", "\(command)"]

        // Because FileHandle's readabilityHandler might be called from a
        // different queue from the calling queue, avoid a data race by
        // protecting reads and writes to outputData and errorData on
        // a single dispatch queue.
        let outputQueue = DispatchQueue(label: "bash-output-queue")

        var outputData = Data()
        var errorData = Data()

        let outputPipe: Pipe
        if let currentOutputPipe = standardOutput as? Pipe {
            outputPipe = currentOutputPipe
        } else {
            let newOutputPipe = Pipe()
            standardOutput = newOutputPipe
            outputPipe = newOutputPipe
        }
        var outputPipeDataObserver: NSObjectProtocol!
        outputPipeDataObserver  = NotificationCenter.default.addObserver(
                forName: Notification.Name.NSFileHandleDataAvailable,
                object: outputPipe.fileHandleForReading,
                queue: nil) { notification in
            outputQueue.sync {
                let data = outputPipe.fileHandleForReading.availableData
                guard data.count > 0 else {
                    NotificationCenter.default.removeObserver(outputPipeDataObserver as Any)
                    return
                }

                if verbose,
                   let line = String(data: data, encoding: .utf8) {
                    print(line, terminator: "")
                }
                outputData.append(data)

                outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
            }
        }
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()

        let errorPipe: Pipe
        if let currentErrorPipe = standardError as? Pipe {
            errorPipe = currentErrorPipe
        } else {
            let newErrorPipe = Pipe()
            standardError = newErrorPipe
            errorPipe = newErrorPipe
        }
        var errorPipeDataObserver: NSObjectProtocol!
        errorPipeDataObserver  = NotificationCenter.default.addObserver(
                forName: Notification.Name.NSFileHandleDataAvailable,
                object: errorPipe.fileHandleForReading,
                queue: nil) { notification in
            outputQueue.sync {
                let data = errorPipe.fileHandleForReading.availableData
                guard data.count > 0 else {
                    NotificationCenter.default.removeObserver(errorPipeDataObserver as Any)
                    return
                }

                if verbose,
                   let line = String(data: data, encoding: .utf8) {
                    print(line, terminator: "")
                }
                errorData.append(data)

                errorPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
            }
        }
        errorPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()

        /* Now input pipe does not used
            let inputPipe: Pipe
            if let currentInputPipe = standardInput as? Pipe {
                inputPipe = currentInputPipe
            } else {
                let newInputPipe = Pipe()
                standardInput = newInputPipe
                inputPipe = newInputPipe
            }
        */

        try run()

        waitUntilExit()

        // Block until all writes have occurred to outputData and errorData,
        // and then read the data back out.
        return try outputQueue.sync {
            if terminationStatus != 0 {
                throw ShellOutError(
                        terminationStatus: terminationStatus,
                        errorData: errorData,
                        outputData: outputData
                )
            }
            return outputData.shellOutput()
        }
    }
}
