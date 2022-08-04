import Foundation
import SwiftAST
//import Runtime

/*
public enum LiteralValue {
    case `nil`
    case boolean(Bool)
    case integer(Int)
    case floatingPoint(Double)
    case staticString(String)
    case interpolatedString([AST])
    case array([AST])
    case dictionary([DictionaryEntry])
    case playground(PlaygroundLiteral)
    //case tuple([AST])
}

public enum Value {
    case `nil`
    case literal(LiteralValue)
    case variable(Variable)
    case variableList([AST]) //should be variables
    indirect case expression(Value, ASTType)
    case `class`(AnyObject)
    case `struct`(Any)
    case dictionary(Any)
    case tuple(Any)
    case array(Any)
    case type(ASTType)
    case typeList([AST]) //should be types
    case function(AST)
    case functionList([AST]) //should be functions
}
*/
public typealias Value = RuntimeValue 
