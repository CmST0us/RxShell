//
// Created by eki on 23-11-25.
//

import Foundation
import SwiftSyntaxMacros
import SwiftCompilerPlugin

@main
struct RxShellMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CreateShell.self,
        DefineShellCommand.self
    ]
}