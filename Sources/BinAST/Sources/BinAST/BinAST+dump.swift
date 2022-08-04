import Foundation
import SwiftAST

extension BinaryOperationType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .minus:
            return "-"
        case .plus:
            return "+"
        case .mult:
            return "*"
        case .floatDiv:
            return "//"
        case .integerDiv:
            return "/"
        }
    }
}

extension UnaryOperationType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .minus:
            return "-"
        case .plus:
            return "+"
        }
    }
}

extension ConditionType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .equals:
            return "="
        case .greaterThan:
            return ">"
        case .lessThan:
            return "<"
        }
    }
}

extension AST {
    func dbgvalue() throws -> String { 
        switch self {
        /*case let number as Number:
            return "\(number)"*/
        case let unaryOperation as UnaryOperation:
            return "u\(unaryOperation.operation)"
        case let binaryOperation as BinaryOperation:
            return "\(binaryOperation.operation)"
        case is NoOp:
            return "noOp"
        case let variable as Variable:
            return variable.name
        case is Compound:
            return "compound"

        case is VariableDeclaration:
            return "var decl"
        case is ClassDeclaration:
            return "class decl"
        case is StructDeclaration:
            return "struct decl"
        case is ProtocolDeclaration:
            return "protocol decl"
        case is ASTTypeAnnotation:
            return "type annotation"
        case is TypealiasDeclaration:
            return "typealias decl"
        case is ImportDeclaration:
            return "import decl"

        case is IdentifierExpression:
            return "IdentifierExpression"
        case is FunctionCallExpression:
            return "FunctionCall"
        case is Literal:
            return "Literal"
        case is ExplicitMemberExpression: 
            return "ExplicitMemberExpression"
        
        case let string as String:
            return string
        case let boolean as Bool:
            return boolean ? "true" : "false"
        case let int as Int:
            return "\(int)"
        case let double as Double:
            return "\(double)"
        
        case is GenericType:
            return "GenericType"

        case is Assignment:
            return "Assignment"

        default:
            throw ASTGenerationError("BinAST dump missed AST case \(type(of:self)):\(self)")
        }
    }

    func children(execMode:Bool) throws -> [AST] { 
        switch self {
        /*case is Number:
            return []*/
        case let unaryOperation as UnaryOperation:
            return [unaryOperation.operand]
        case let binaryOperation as BinaryOperation:
            return [binaryOperation.left, binaryOperation.right]
        case is NoOp:
            return []
        case is Variable:
            return []
        case let compound as Compound:
            if execMode {
                //use execution linked list
                var result:[AST]=[]
                var s=compound.start
                while s != nil {
                    result.append(s!)
                    s=s!.next
                }
                return result
            }
            return compound.children
        
        case let variableDeclaration as VariableDeclaration:
            return [variableDeclaration.variable, variableDeclaration.typeAnnotation]
        case let classDeclaration as ClassDeclaration:
            return [classDeclaration.impl]
        case let structDeclaration as StructDeclaration:
            return [structDeclaration.impl]
        case let protocolDeclaration as ProtocolDeclaration:
            return [protocolDeclaration.impl]

        case let typeAnnotation as ASTTypeAnnotation:
            return [typeAnnotation.type]
        case let typealiasDeclaration as TypealiasDeclaration:
            return [typealiasDeclaration.alias.name,typealiasDeclaration.alias.assignment] //todo generic
        case let importDeclaration as ImportDeclaration:
            if importDeclaration.imports != nil {return [importDeclaration.module, "\(importDeclaration.imports!)"]}
            return [importDeclaration.module]
        
        case is String:
            return []
        case is Bool:
            return []
        case is Int: 
            return []
        case is Double: 
            return []

        case let identifier as IdentifierExpression:
            switch identifier.kind {
                case .identifier(let id, _):
                    return [id]
                case .implicitParameterName(let i, _):
                    return [i]
                case .bindingReference(let id):
                    return [id]
            }

        case let fc as FunctionCallExpression:
            if fc.argumentClause != nil {
                var r:[AST]=[]
                r.append(fc.postfixExpression)
                //for a in fc.argumentClause! {r.append(a)}
                return r
            }
            return [fc.postfixExpression]
            
                    case let em as ExplicitMemberExpression: 
            switch em.kind {
                case .tuple(let ast, let int):
                    return [ast,int]
                case .namedType(let ast, let name):
                    return [ast,name]
                case .generic(let ast, let name, let ac):
                    return [ast,name]
                case .argument(let ast, let name, let a):
                    return [ast,name]
            }

        case let literal as Literal:
            switch literal.kind {
                case .nil: return ["nil"]
                case .boolean(let b): return [b]
                case .integer(let i, let s): return [i,s]
                case .floatingPoint(let d, let s): return [d,s]
                case .staticString(let s, let s1): return [s,s1]
                case .interpolatedString(let e, _): return e
                case .array(let e): return e
                case .dictionary(let d): return d
                case .playground(let l): return [l]
            }
        
        case let generic as GenericType:
            return [generic.name]

        case let assignment as Assignment:
            return [assignment.lhs, assignment.rhs]

        default:
           throw ASTGenerationError("BinAST dump missed AST case \(type(of:self)):\(self)")
        }
        
    }

    func treeLines(execMode:Bool,_ nodeIndent: String = "", _ childIndent: String = "") throws -> [String] {
        let c=try children(execMode:execMode)
        return try [nodeIndent + dbgvalue()]
            + c.enumerated().map { ( $0 < c.count - 1, $1) }
            .flatMap { $0 ? try $1.treeLines(execMode:execMode,"┣╸", "┃ ") : try $1.treeLines(execMode:execMode,"┗╸", "  ") }
            .map { childIndent + $0 }
    }

    public func printTree(execMode:Bool=true) throws { print(try treeLines(execMode:execMode).joined(separator: "\n")) }
}





















