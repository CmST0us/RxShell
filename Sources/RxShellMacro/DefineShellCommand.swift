//
// Created by eki on 23-11-25.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct DefineShellCommand: DeclarationMacro {
    public static func expansion<Node, Context>(of node: Node, in context: Context) throws -> [DeclSyntax] where Node: FreestandingMacroExpansionSyntax, Context: MacroExpansionContext {
        return [""]
    }
}