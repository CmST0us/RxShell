//
// Created by eki on 23-11-25.
//

import Foundation

@resultBuilder
public enum ShellsBuilder {
    public static func buildBlock(_ components: Shell...) -> [Shell] {
        components
    }

    public static func buildEither(first component: Shell) -> Shell {
        component
    }

    public static func buildEither(second component: Shell) -> Shell {
        component
    }

    public static func buildArray(_ components: [Shell]) -> [Shell] {
        components
    }
}