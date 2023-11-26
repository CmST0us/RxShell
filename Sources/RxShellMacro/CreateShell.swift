//
// Created by eki on 23-11-25.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct CreateShell: DeclarationMacro {
    public static func expansion<Node, Context>(of node: Node, in context: Context) throws -> [DeclSyntax] where Node: FreestandingMacroExpansionSyntax, Context: MacroExpansionContext {
        let name = node.argumentList.first!
                .expression
                .as(StringLiteralExprSyntax.self)!
                .segments
                .first!
                .as(StringSegmentSyntax.self)!
                .content.text
        return ["""
                public static func \(raw: name)(@ArgumentBuilder _ argument: () -> [String]) -> Shell {
                    return path("\(raw: name)", argument)
                }
                """]
    }
}