import Foundation
import SwiftAST

enum ArchiveType:Int {
    case ASTType=1
    case TryIndexedType
    //case Number
    case String
    case Bool
    case Int
    case Double
    case UnaryOperation
    case BinaryOperation
    case Variable
    case VariableDeclaration
    case TypealiasDeclaration
    case ImportDeclaration
    case ClassDeclaration
    case StructDeclaration
    case ProtocolDeclaration
    case Compound
    case NoOp
    case ASTGenericParameterClause
    case ASTGenericArgumentClause
    case GenericType
    case AliasType
    case StructType
    case ClassType
    case ProtocolType
    case Assignment
    case IdentifierExpression
    case Literal
    case PlaygroundLiteral
    case DictionaryEntry
    case ASTTypeIdentifier
    case ASTProtocolCompositionType
    case ASTGenericWhereClause
    case TypeName
    case Requirement
    case ASTTypeAnnotation
    case ASTTypeInheritanceClause
    case Member
    case GetterSetterKeywordBlock
    case PropertyMember
    case FunctionResult
    case FunctionSignature
    case MethodMember
    case InitializerMember
    case InitializerDeclaration
    case CodeBlock
    case SubscriptMember
    case AssociativityTypeMember
    case FunctionDeclaration
    case EnumType
    case ReturnStatement
    case ClosureExpression
    case FunctionCallExpression
    case WillSetDidSetBlock
    case DictionaryType
    case ExplicitMemberExpression
}

func ASTFromTag(data: SCLData, typeIndex:Int = -1) throws -> AST {
    let tag=Int(data.readWord())
    let l=SourceLocation(identifier: "", line: -1, column: -1)
    
    if let t=ArchiveType(rawValue:tag) {
        switch t {
            case .ASTType: 
                //we should never see ASTType import without TryIndexedType
                try ASTModule.assert(typeIndex >= 0,msg: "ASTType import without TryIndexedType")
                let t=ASTType()
                data.types[typeIndex]=t
                return try ASTType.ASTTypeunarchive(data: data, instance: t)
            case .TryIndexedType: 
                try ASTModule.assert(typeIndex == -1,msg: "TryIndexedType import as indexed")
                return try ASTType.TryIndexedType.unarchive(data: data, instance:nil)
            //case .Number: return Number.unarchive(data: data, instance:Number())
            case .String: 
                try ASTModule.assert(typeIndex == -1,msg: "String import as indexed")
                return try String.unarchive(data: data, instance:String())
            case .Bool: 
                try ASTModule.assert(typeIndex == -1,msg: "Bool import as indexed")
                return try Bool.unarchive(data: data, instance:Bool())
            case .Int: 
                try ASTModule.assert(typeIndex == -1,msg: "Int import as indexed")
                return try Int.unarchive(data: data, instance:Int())
            case .Double: 
                try ASTModule.assert(typeIndex == -1,msg: "Double import as indexed")
                return try Int.unarchive(data: data, instance:Double())
                
            case .UnaryOperation: 
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try UnaryOperation.UnaryOperationunarchive(data: data, instance:UnaryOperation())
            case .BinaryOperation: 
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try BinaryOperation.BinaryOperationunarchive(data: data, instance:BinaryOperation())

            case .Variable: 
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try Variable.Variableunarchive(data: data, instance:Variable())
            case .IdentifierExpression: 
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try IdentifierExpression.IdentifierExpressionunarchive(data: data, instance:IdentifierExpression())
            case .Literal: 
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try Literal.Literalunarchive(data: data, instance:Literal())
            case .PlaygroundLiteral: 
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try PlaygroundLiteral.unarchive(data: data, instance:PlaygroundLiteral())
            case .DictionaryEntry:
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try DictionaryEntry.unarchive(data: data, instance:DictionaryEntry())
            case .VariableDeclaration: 
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try VariableDeclaration.VariableDeclarationunarchive(data: data, instance:VariableDeclaration())
            case .TypealiasDeclaration: 
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try TypealiasDeclaration.TypealiasDeclarationunarchive(data: data, instance:TypealiasDeclaration())
            case .ImportDeclaration: 
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try ImportDeclaration.ImportDeclarationunarchive(data: data, instance:ImportDeclaration())
            case .ClassDeclaration: 
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try ClassDeclaration.ClassDeclarationunarchive(data: data, instance:ClassDeclaration())
            case .StructDeclaration: 
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try StructDeclaration.StructDeclarationunarchive(data: data, instance:StructDeclaration())
            case .ProtocolDeclaration: 
                return try ProtocolDeclaration.ProtocolDeclarationunarchive(data: data, instance:ProtocolDeclaration())
            case .Compound: 
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try Compound.Compoundunarchive(data: data, instance:Compound())
            case .NoOp: 
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try NoOp.NoOpunarchive(data: data, instance:NoOp())
            case .ASTGenericParameterClause: 
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try ASTGenericParameterClause.unarchive(data: data, instance:ASTGenericParameterClause())
            case .ASTGenericArgumentClause: 
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try ASTGenericArgumentClause.unarchive(data: data, instance:ASTGenericArgumentClause())
            case .ASTTypeIdentifier:
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try ASTTypeIdentifier.unarchive(data: data, instance:ASTTypeIdentifier())
            case .ASTProtocolCompositionType:
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try ASTProtocolCompositionType.unarchive(data: data, instance:ASTProtocolCompositionType())
            case .ASTGenericWhereClause:
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try ASTGenericWhereClause.unarchive(data: data, instance:ASTGenericWhereClause())
            case .TypeName:
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try ASTTypeIdentifier.TypeName.unarchive(data: data, instance:ASTTypeIdentifier.TypeName())
            case .Requirement:
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try ASTGenericWhereClause.Requirement.unarchive(data: data, instance:ASTGenericWhereClause.Requirement())
            case .ASTTypeAnnotation:
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try ASTTypeAnnotation.unarchive(data: data, instance:ASTTypeAnnotation())
            case .ASTTypeInheritanceClause:
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try ASTTypeInheritanceClause.unarchive(data: data, instance:ASTTypeInheritanceClause())
            case .Member:  
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try Member.unarchive(data: data, instance:Member())
            case .GetterSetterKeywordBlock: 
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try GetterSetterKeywordBlock.GetterSetterKeywordBlockunarchive(data: data, instance:GetterSetterKeywordBlock())
            case .WillSetDidSetBlock:
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try WillSetDidSetBlock.WillSetDidSetBlockunarchive(data: data, instance:WillSetDidSetBlock())
            case .PropertyMember:
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try PropertyMember.PropertyMemberunarchive(data: data, instance:PropertyMember())
            case .FunctionResult:  
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try FunctionResult.unarchive(data: data, instance:FunctionResult())  
            case .FunctionSignature:
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try FunctionSignature.unarchive(data: data, instance:FunctionSignature())  
            case .MethodMember:
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try MethodMember.MethodMemberunarchive(data: data, instance:MethodMember()) 
            case .FunctionDeclaration:
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try FunctionDeclaration.FunctionDeclarationunarchive(data: data, instance:FunctionDeclaration()) 
            case .InitializerMember:
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try InitializerMember.InitializerMemberunarchive(data: data, instance:InitializerMember())  
            case .InitializerDeclaration:
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try InitializerDeclaration.InitializerDeclarationunarchive(data: data, instance:InitializerDeclaration())  
            case .SubscriptMember:  
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try SubscriptMember.SubscriptMemberunarchive(data: data, instance:SubscriptMember()) 
            case .AssociativityTypeMember:  
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try AssociativityTypeMember.AssociativityTypeMemberunarchive(data: data, instance:AssociativityTypeMember()) 
            
            //types
            case .GenericType: 
                try ASTModule.assert(typeIndex >= 0,msg: "GenericType import without TryIndexedType")
                let t=GenericType()
                data.types[typeIndex]=t
                return try GenericType.GenericTypeunarchive(data: data, instance:t)
            case .AliasType: 
                try ASTModule.assert(typeIndex >= 0,msg: "AliasType import without TryIndexedType")
                let t=AliasType()
                data.types[typeIndex]=t
                return try AliasType.AliasTypeunarchive(data: data, instance:t)
            case .StructType: 
                try ASTModule.assert(typeIndex >= 0,msg: "StructType import without TryIndexedType")
                let t=StructType()
                data.types[typeIndex]=t
                return try StructType.StructTypeunarchive(data: data, instance:t)
            case .ClassType: 
                try ASTModule.assert(typeIndex >= 0,msg: "ClassType import without TryIndexedType")
                let t=ClassType()
                data.types[typeIndex]=t
                return try ClassType.ClassTypeunarchive(data: data, instance:t)
            case .ProtocolType: 
                try ASTModule.assert(typeIndex >= 0,msg: "ProtocolType import without TryIndexedType")
                let t=ProtocolType()
                data.types[typeIndex]=t
                return try ProtocolType.ProtocolTypeunarchive(data: data, instance:t)
            case .EnumType: 
                try ASTModule.assert(typeIndex >= 0,msg: "EnumType import without TryIndexedType")
                let t=EnumType()
                data.types[typeIndex]=t
                return try EnumType.EnumTypeunarchive(data: data, instance:t)
            case .DictionaryType:
                try ASTModule.assert(typeIndex >= 0,msg: "DictionaryType import without TryIndexedType")
                let t=DictionaryType()
                data.types[typeIndex]=t
                return try DictionaryType.DictionaryTypeunarchive(data: data, instance:t)

            //Expressions
            case .ClosureExpression:
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try ClosureExpression.ClosureExpressionunarchive(data: data, instance:ClosureExpression())
            case .FunctionCallExpression:
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try FunctionCallExpression.FunctionCallExpressionunarchive(data: data, instance:FunctionCallExpression())

            //statements
            case .Assignment: 
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try Assignment.Assignmentunarchive(data: data, instance:Assignment())
            case .CodeBlock:
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try CodeBlock.CodeBlockunarchive(data: data, instance:CodeBlock())
            case .ReturnStatement:
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try ReturnStatement.ReturnStatementunarchive(data: data, instance:ReturnStatement())
            case .ExplicitMemberExpression:   
                try ASTModule.assert(typeIndex == -1,msg: "expected a type, not \(t)")
                return try ExplicitMemberExpression.ExplicitMemberExpressionunarchive(data: data, instance:ExplicitMemberExpression()) 
        }
    }
    else {
        throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("Illegal AST tag \(tag) at offset \(data.ofs)"), sourceLocatable: l)
    }
}


































