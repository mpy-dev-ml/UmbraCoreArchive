import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct ErrorMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ErrorMacro.self,
        ErrorCaseMacro.self
    ]
}

public struct ErrorMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Implementation for @Error macro
        []
    }
}

public struct ErrorCaseMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Implementation for @ErrorCase macro
        []
    }
}
