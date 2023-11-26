//
// Created by eki on 23-11-25.
//

import Foundation

@resultBuilder
public enum ArgumentBuilder {
    public static func buildBlock(_ components: String...) -> [String] {
        components
    }

    public static func buildOptional(_ component: String?) -> String {
        component ?? ""
    }

    public static func buildEither(first component: String) -> String {
        component
    }

    public static func buildEither(second component: String) -> String {
        component
    }

    public static func buildArray(_ components: [String]) -> [String] {
        components
    }
}