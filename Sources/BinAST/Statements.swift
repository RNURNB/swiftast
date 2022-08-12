import Foundation
import SwiftAST
//import Runtime

protocol Statement: Declaration {
}

public class Compound: ASTBase, Declaration {
    public var children: [AST]
    public var dummy:Bool
    public var start:AST?=nil

    public override init() {
        children=[]
        dummy=true
        super.init()
    }
    
    init(children: [AST], location: SourceLocatable, dummy: Bool=false) {
        self.children = children
        var previous:AST?=nil
        for var i in children {
            if i is NoOp && previous != nil {continue} //silently ignore
            i.previous=previous
            previous?.next=i
            previous=i
        }
        self.dummy=dummy //dummy compounds do not have their own scope
        super.init(location: location)
    }
    
    public override func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.Compound.rawValue))}
        
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=root
        
        data.writeWord(UInt16(children.count))
        for e in children {try e.archive(data:data)}
    }
    
    public static func Compoundunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i:Compound=instance != nil ? instance as! Compound : try ASTFromTag(data: data) as! Compound
        
        try _=ASTBase.unarchive(data: data, instance: i)
        
        let c=Int(data.readWord())
        var previous:AST?=nil
        for _ in 0..<c {
            var e=try ASTFromTag(data:data)
            i.children.append(e)
            e.previous=previous
            previous?.next=e
            previous=e
        }
        
        return i
    }
    
    public override func copy() -> AST {
        var c:[AST]=[]
        for cc in children {c.append(cc.copy())}
        return Compound(children: c, location: location, dummy: dummy)
    }
    
    public override func replace(name: String, with: AST) -> AST {return self}
    
    public override func runDeclarations(isTopLevel:Bool) throws {
        var s=children.first
        while s != nil {
            try s!.runDeclarations(isTopLevel:isTopLevel)
            s=s!.next
        }
        start=children.first

        //remove ignored nodes
        if start is NoOp {start=start!.next}
        if start is ImportDeclaration {start=start!.next}
    }

    public override func exec() throws -> Value {
        var s=start
        while s != nil {
            try _=s!.exec()
            s=s!.next
        }
        return runtimeNilValue
    }

    public override func getType() throws -> ASTType {return VoidType}
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateCompound(self)}
}

public class NoOp: ASTBase, Statement {
    
    public override init() {
        super.init()
    }
    
    public override func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.NoOp.rawValue))}
    }
    
    public static func NoOpunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i=instance != nil ? instance as! NoOp : try ASTFromTag(data: data) as! NoOp
        
        return i
    }
    
    public override func copy() -> AST {return self}
    
    public override func replace(name: String, with: AST) -> AST {return self}
    
    public override func runDeclarations(isTopLevel:Bool) {
        //remove this from list for further execution
        //print("execute noop. previous=",previous," next=",next)
        if previous != nil {
            previous!.next=next
            next?.previous=previous
        }
    }

    public override func getType() throws -> ASTType {return VoidType}
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateNoOp(self)}
}

func doVarAssignment(variable:inout RuntimeVariable, expr: AST, initializer: Bool=false) throws {
    //print("exec Assignment ",try variable.dbgvalue(),try variable.children(execMode:true)," = ", try expr.dbgvalue(),try expr.children(execMode:true))
    //print("old value:",variable.value)

    //TODO check types

    var e=try expr.exec()
    if e.type.0 == . variable {
        e=(e.value as! RuntimeVariable).value!
    }

    variable.setValue(value: e)
    if initializer {
        if let v=variable as? Variable {
            //TODO how to handle var x:Any=...? vs. var x=...
            if v.typeAnnotation.type.swiftType==AnyType.self {v.typeAnnotation.type=try expr.getType()}
        }
    }

    //print("assignment result:",variable.value!)
}

public class Assignment: ASTBase, Statement {
    public var lhs: AST
    public var rhs: AST 

    public override init() {
        lhs = NoOp()
        rhs = NoOp()
        super.init()
    }
    
    public init(lhs: AST, rhs: AST, location: SourceLocatable) {
        self.lhs=lhs
        self.rhs=rhs

        super.init(location: location)
    }

    public override func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.Assignment.rawValue))}

        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true

        try lhs.archive(data: data)
        try rhs.archive(data: data)

        data.isRoot=root
    }
    
    public static func Assignmentunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i=instance != nil ? instance as! Assignment : try ASTFromTag(data: data) as! Assignment
        
        try _=ASTBase.unarchive(data: data, instance: i)

        i.lhs=try ASTFromTag(data: data)
        i.rhs=try ASTFromTag(data: data)
        
        return i
    }
    
    public override func copy() -> AST {
        return Assignment(lhs: lhs.copy(), rhs: rhs.copy(), location: location)
    }
    
    public override func replace(name: String, with: AST) -> AST {return self}
    
    public override func runDeclarations(isTopLevel:Bool) throws {
        //if we compile a library, no top level statements are allowed
        if isTopLevel {
            let fn=location.filename
            if options["primary-file"] != NSString(string:fn).lastPathComponent {
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.expressionsAtTopLevel, sourceLocatable: self.location)
            }
        }

        try lhs.runDeclarations(isTopLevel:isTopLevel)
        try rhs.runDeclarations(isTopLevel:isTopLevel)

        if let i=lhs as? IdentifierExpression {
            //print("i=\(i) impl=",i.impl)
            if let v=i.impl as? Variable {
                if v.isConstant {
                    throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.cannotAssign(v.name), sourceLocatable: self.location)
                }
            }
        }

        //print("Assignment ",lhs," = ", rhs," location:",location.filename)
    }

    public override func exec() throws -> Value {
        var v=try lhs.exec()

        if v.type.0 == .variable {
            var vv=v.value as! RuntimeVariable
            try doVarAssignment(variable:&vv, expr:rhs)
            v.value=vv //might have changed due to assingment, if its a struct
            return runtimeNilValue //Assignments do not return any value
        }
        
        throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("Assignment exec error for \(lhs):\(v)"), sourceLocatable: location)
    }

    public override func getType() throws -> ASTType {return VoidType}
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateAssignment(self)}
}


public class CodeBlock : ASTBase, Statement {
    public var statements: [AST]
    public var start:AST?=nil
    
    public override init() {
        statements = []
        super.init()
    }

    public init(statements: [AST], location: SourceLocatable) {
        self.statements = statements
        super.init(location: location)
    }
    
    public override func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.CodeBlock.rawValue))}
      
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true
        
        data.writeWord(UInt16(statements.count))
        for s in statements {
            try s.archive(data: data)
        }
        
        data.isRoot=root
    }

    public static func CodeBlockunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i:CodeBlock=instance != nil ? instance as! CodeBlock : try ASTFromTag(data: data) as! CodeBlock
    
        _=try ASTBase.unarchive(data: data, instance: i)
        
        let c=Int(data.readWord())
        for _ in 0..<c {
            i.statements.append(try ASTFromTag(data: data))
        }
        
        return i
    }
    
    public override func copy() -> AST {
        var c:[AST]=[]
        for cc in statements {c.append(cc.copy())}
        return CodeBlock(statements: c, location: location)
    }
    
    public override func replace(name: String, with: AST) -> AST {return self}
    
    public override func runDeclarations(isTopLevel:Bool) throws {
        /*var s=statements.first
        while s != nil {
            try s!.runDeclarations(isTopLevel:isTopLevel)
            s=s!.next
        }*/
        start=statements.first
        if start is NoOp {start=start!.next}
    }
    
    public override func exec() throws -> Value {
        var s=start
        while s != nil {
            try _=s!.exec()
            s=s!.next
        }
        return runtimeNilValue
    }

    public override func getType() throws -> ASTType {return VoidType}
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateCodeBlock(self)}
}

public class ReturnStatement : ASTBase, Statement {
    public var expression: AST?

    public override init() {
        expression=nil
        super.init()
    }

    public init(expression: AST?, location: SourceLocatable) {
        self.expression = expression
        super.init(location: location)
    }

    public override func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.ReturnStatement.rawValue))}
      
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true
        
        if expression != nil {
            data.writeBool(true)
            try expression!.archive(data:data)
        }
        else {data.writeBool(false)}
        
        data.isRoot=root
    }

    public static func ReturnStatementunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i:ReturnStatement=instance != nil ? instance as! ReturnStatement : try ASTFromTag(data: data) as! ReturnStatement
    
        _=try ASTBase.unarchive(data: data, instance: i)
        
        if data.readBool() {i.expression=try ASTFromTag(data: data)}

        return i
    }
    
    public override func copy() -> AST {
        return ReturnStatement(expression: expression?.copy(), location: location)
    }
    
    public override func replace(name: String, with: AST) -> AST {return self}
    
    public override func runDeclarations(isTopLevel:Bool) throws {
        try expression?.runDeclarations(isTopLevel: isTopLevel)
    }
    
    public override func exec() throws -> Value {
        var result:Value = runtimeNilValue

        if expression != nil {
            result = try expression!.exec()
        }
        
        //TODO return
        return result
    }
    
    public override func getType() throws -> ASTType {return (try expression?.getType()) ?? VoidType}
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateReturnStatement(self)}

}

public class ClosureExpression : ASTBase {
    public struct Signature {
        public struct CaptureItem {
            public enum Specifier : String {
                case weak
                case unowned
                case unownedSafe = "unowned(safe)"
                case unownedUnsafe = "unowned(unsafe)"
            }

            public var specifier: Specifier?
            public var expression: AST

            public init(specifier: Specifier? = nil, expression: AST) {
                self.specifier = specifier
                self.expression = expression
            }
        }
    
        public enum ParameterClause {
            public struct Parameter {
                public var name: String
                public var typeAnnotation: ASTTypeAnnotation?
                public var isVarargs: Bool
    
                public init(name: String, typeAnnotation: ASTTypeAnnotation? = nil, isVarargs: Bool = false) {
                    self.name = name
                    self.typeAnnotation = typeAnnotation
                    self.isVarargs = isVarargs
                }
            }
    
            case parameterList([Parameter])
            case identifierList([String])
        }
    
        public var captureList: [CaptureItem]?
        public var parameterClause: ParameterClause?
        public var canThrow: Bool
        public var functionResult: FunctionResult?
    
        public init(captureList: [CaptureItem]) {
            self.captureList = captureList
            self.parameterClause = nil
            self.canThrow = false
            self.functionResult = nil
        }
    
        public init(captureList: [CaptureItem]? = nil, parameterClause: ParameterClause, canThrow: Bool = false, functionResult: FunctionResult? = nil) {
            self.captureList = captureList
            self.parameterClause = parameterClause
            self.canThrow = canThrow
            self.functionResult = functionResult
        }

        public func copy() -> Signature {
            let cl:[CaptureItem]?=nil

            let pc:ParameterClause?=nil

            var fr:FunctionResult?=nil
            if self.functionResult != nil {fr=self.functionResult!.copy() as! FunctionResult}

            if pc==nil {
                var r:Signature
                if cl==nil {r=Signature(captureList: []);r.captureList=nil}
                else {r=Signature(captureList:cl!)}
                r.canThrow=canThrow
                r.functionResult=fr
                return r
            }
            return Signature(captureList: cl, parameterClause: pc!, canThrow: canThrow, functionResult: fr)
        }
    }
    
    public var signature: Signature?
    public var statements: [AST]?
    
    public override init() {
        signature=nil
        statements=[]
        super.init()
    }

    public init(signature: Signature? = nil, statements: [AST]? = nil, location: SourceLocatable) {
        self.signature = signature
        self.statements = statements
        super.init(location: location)
    }

    public override func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.ClosureExpression.rawValue))}
      
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true

        if signature != nil {
            data.writeBool(true)

            if signature!.captureList != nil {
                data.writeBool(true)
                data.writeWord(UInt16(signature!.captureList!.count))
                for ci in signature!.captureList! {
                    if ci.specifier != nil {
                        data.writeBool(true)
                        data.writeShortString(ci.specifier!.rawValue)
                    }
                    else {data.writeBool(false)}

                    try ci.expression.archive(data: data)
                }
            }
            else {data.writeBool(false)}

            if signature!.parameterClause != nil {
                data.writeBool(true)

                switch signature!.parameterClause! {
                    case .parameterList(let pl):
                        data.writeWord(1)
                        data.writeWord(UInt16(pl.count))
                        for p in pl {
                            data.writeShortString(p.name)
                            if p.typeAnnotation != nil {
                                data.writeBool(true)
                                try p.typeAnnotation!.archive(data: data)
                            }
                            else {data.writeBool(false)}
                            data.writeBool(p.isVarargs)
                        }
                    case .identifierList(let il):
                        data.writeWord(2)
                        data.writeWord(UInt16(il.count))
                        for s in il {data.writeShortString(s)}
                }
            }
            else {data.writeBool(false)}

            data.writeBool(signature!.canThrow)

            if signature!.functionResult != nil {
                data.writeBool(true)
                try signature!.functionResult!.archive(data: data)
            }
            else {data.writeBool(false)}
        }
        else {data.writeBool(false)}

        if statements != nil {
            data.writeBool(true)
            data.writeWord(UInt16(statements!.count))
            for s in statements! {try s.archive(data:data)}
        }
        else {data.writeBool(false)}
        
        data.isRoot=root
    }

    public static func ClosureExpressionunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i:ClosureExpression=instance != nil ? instance as! ClosureExpression : try ASTFromTag(data: data) as! ClosureExpression
    
        _=try ASTBase.unarchive(data: data, instance: i)

        if data.readBool() {
            i.signature=Signature(captureList: [])
            
            if data.readBool() {
                let c=Int(data.readWord())
                for _ in 0..<c {
                    var spec:Signature.CaptureItem.Specifier?=nil
                    if data.readBool() {
                        spec=Signature.CaptureItem.Specifier(rawValue:data.readShortString()!)
                    }

                    let expr=try ASTFromTag(data: data)
                    i.signature!.captureList!.append(Signature.CaptureItem(specifier: spec, expression: expr))
                }
            }
            else {i.signature!.captureList=nil}
            
            if data.readBool() {
                if data.readWord()==1 {
                    var pl:[Signature.ParameterClause.Parameter]=[]

                    let c=Int(data.readWord())
                    for _ in 0..<c {
                        let name=data.readShortString()!
                        var ta:ASTTypeAnnotation?=nil
                        if data.readBool() {
                            ta=(try ASTFromTag(data: data) as! ASTTypeAnnotation)
                        }
                        let isVarargs=data.readBool()
                        pl.append(Signature.ParameterClause.Parameter(name: name, typeAnnotation: ta, isVarargs:isVarargs))
                    }

                    i.signature!.parameterClause = .parameterList(pl)
                }
                else {
                    var a:[String]=[]
                    let c=Int(data.readWord())
                    for _ in 0..<c {a.append(data.readShortString()!)}

                    i.signature!.parameterClause = .identifierList(a)
                }
            }

            i.signature!.canThrow=data.readBool()

            if data.readBool() {
                i.signature!.functionResult=(try ASTFromTag(data: data) as! FunctionResult)
            }

        }

        if data.readBool() {
            let c=Int(data.readWord())
            i.statements=[]
            for _ in 0..<c {
                i.statements!.append(try ASTFromTag(data: data))
            }
        }

        return i
    }
    
    public override func copy() -> AST {
        var s:[AST]?=nil
        if statements != nil {
            s=[]
            for ss in statements! {s!.append(ss.copy())}
        }
        return ClosureExpression(signature: signature?.copy(), statements: s, location: self.location)
    }
    
    public override func replace(name: String, with: AST) -> AST {return self}
    
    public override func runDeclarations(isTopLevel:Bool) throws {}
    
    public override func exec() throws -> Value {
        let result:Value = runtimeNilValue

        //TODO
        
        return result
    }

    public override func getType() throws -> ASTType {return signature?.functionResult?.type ?? VoidType}
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateClosureExpression(self)}
}

#if WINDOWS
//test only
public class User/*:CustomStringConvertible*/ {
  public init(/*id:Int, username:String="ENUERNK", email:String="rene.nuernberger@web.de"*/) {
        print("User init called with email=",self.email)
        self.email="rene.nuernberger@web.de"
        print("new email=",self.email)
      /*self.id=id
      self.username=username
      self.email=email*/
        //print("new email:",self.email)
        //var mySelf = self
      //print("self in init=",MemoryAddress(of:mySelf)/*UnsafeMutableRawPointer(&mySelf)*/)
  }

  var id: Int=0
  var username: String=""
  public var email: String="default"

  public var description: String {
    return "User: id:\(id) username:\(username) email: \(email)"
  }

  public func test1(_ i:Int) -> Int {
    print("test 1 func. arg=", i)
    return i
  }

  public func test2(arg1:Int, arg2: Int) -> Int {
     print("test 2 func. arg1=", arg1, " arg2=", arg2)
     return 66 //arg1+arg2
    //return 6 //arg1+arg2
  }
}
#endif

public class FunctionCallExpression : ASTBase {
    public enum Argument {
        case expression(AST)
        case namedExpression(String, AST)
        case memoryReference(AST)
        case namedMemoryReference(String, AST)
        case `operator`(Operator)
        case namedOperator(String, Operator)

        public func copy() -> Argument {
            switch self {
                case .expression(let ast):
                    return .expression(ast.copy())
                case .namedExpression(let name, let ast):
                    return .namedExpression(name,ast.copy())
                case .memoryReference(let ast):
                    return .memoryReference(ast.copy())
                case .namedMemoryReference(let name, let ast):
                    return .namedMemoryReference(name,ast.copy())
                case .`operator`(let op):
                    return .`operator`(op.copy() as! Operator)
                case .namedOperator(let name, let op):
                    return .namedOperator(name, op.copy() as! Operator)
                    
            }
        }
    }

    public var postfixExpression: AST
    public var argumentClause: [Argument]?
    public var trailingClosure: ClosureExpression?

    public var resolvedTarget: FunctionDeclaration?=nil

    public override init() {
        postfixExpression=NoOp()
        argumentClause=nil
        trailingClosure=nil
        super.init()
    }
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateFunctionCallExpression(self)}
    
    public init(postfixExpression: AST, argumentClause: [Argument]?, trailingClosure: ClosureExpression?=nil, location: SourceLocatable) {
        self.postfixExpression = postfixExpression
        self.argumentClause = argumentClause
        self.trailingClosure = trailingClosure
        super.init(location: location)
    }    

    public override func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.FunctionCallExpression.rawValue))}
      
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true

        try postfixExpression.archive(data: data)

        if argumentClause != nil {
            data.writeBool(true)
            data.writeWord(UInt16(argumentClause!.count))
            for a in argumentClause! {
                switch a {
                    case .expression(let ast):
                        data.writeWord(1)
                        try ast.archive(data: data)
                    case .namedExpression(let name, let ast):
                        data.writeWord(2)
                        data.writeShortString(name)
                        try ast.archive(data: data)
                    case .memoryReference(let ast):
                        data.writeWord(3)
                        try ast.archive(data: data)
                    case .namedMemoryReference(let name, let ast):
                        data.writeWord(4)
                        data.writeShortString(name)
                        try ast.archive(data: data)
                    case .`operator`(let op):
                        data.writeWord(5)
                        try op.archive(data: data)
                    case .namedOperator(let name, let op):
                        data.writeWord(6)
                        data.writeShortString(name)
                        try op.archive(data: data)
                }
            }
        }
        else {data.writeBool(false)}

        if trailingClosure != nil {
            data.writeBool(true)
            try trailingClosure!.archive(data: data)
        }
        else {data.writeBool(false)}

        data.isRoot=root
    }

    public static func FunctionCallExpressionunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i:FunctionCallExpression=instance != nil ? instance as! FunctionCallExpression : try ASTFromTag(data: data) as! FunctionCallExpression
    
        _=try ASTBase.unarchive(data: data, instance: i)

        i.postfixExpression=try ASTFromTag(data: data)

        if data.readBool() {
            i.argumentClause = []
            let c=Int(data.readWord())
            for _ in 0..<c {
                let k=data.readWord()
                if k == 1 {
                    let ast=try ASTFromTag(data: data)
                    i.argumentClause!.append(.expression(ast))
                }
                else if k == 2 {
                    let name=data.readShortString()!
                    let ast=try ASTFromTag(data: data)
                    i.argumentClause!.append(.namedExpression(name,ast))
                }
                else if k == 3 {
                    let ast=try ASTFromTag(data: data)
                    i.argumentClause!.append(.memoryReference(ast))
                }
                else if k == 4 {
                    let name=data.readShortString()!
                    let ast=try ASTFromTag(data: data)
                    i.argumentClause!.append(.namedMemoryReference(name,ast))
                }
                else if k == 5 {
                    let op=try ASTFromTag(data: data) as! Operator
                    i.argumentClause!.append(.`operator`(op))
                }
                else if k == 6 {
                    let name=data.readShortString()!
                    let op=try ASTFromTag(data: data) as! Operator
                    i.argumentClause!.append(.namedOperator(name,op))
                }
            }
        }

        if data.readBool() {
            i.trailingClosure=(try ASTFromTag(data: data) as! ClosureExpression)
        }

        return i
    }
    
    public override func copy() -> AST {
        var ac:[Argument]?=nil
        if argumentClause != nil {
            ac=[]
            for a in argumentClause! {ac!.append(a.copy())}
        }
        return FunctionCallExpression(postfixExpression: postfixExpression.copy(), argumentClause: ac, 
                                      trailingClosure: trailingClosure?.copy() as? ClosureExpression, location: self.location)
    }
    
    public override func replace(name: String, with: AST) -> AST {return self}
    
    public override func runDeclarations(isTopLevel:Bool) throws {
        //print("function call decl postfixExpression=",postfixExpression," of type:",type(of:postfixExpression))

        //run decls on function to see, if the identifiers are present
        try postfixExpression.runDeclarations(isTopLevel: isTopLevel)

        //run decls on arguments
        if argumentClause != nil {
            for a in argumentClause! {
                switch a {
                    case .expression(let ast):
                        try ast.runDeclarations(isTopLevel: isTopLevel)
                    case .namedExpression(let name, let ast):
                        try ast.runDeclarations(isTopLevel: isTopLevel)
                    case .memoryReference(let ast):
                        try ast.runDeclarations(isTopLevel: isTopLevel)
                    case .namedMemoryReference(let name, let ast):
                        try ast.runDeclarations(isTopLevel: isTopLevel)
                    case .`operator`(let op):
                        op.runDeclarations(isTopLevel: isTopLevel)
                    case .namedOperator(let name, let op):
                        op.runDeclarations(isTopLevel: isTopLevel)
                }
            }
        }
    }

    public func checkParameters(function: FunctionDeclaration) throws -> Bool {
        //TODO result type check?

        /*let function:FunctionDeclaration
        if f is FunctionDeclaration {function=f as! FunctionDeclaration}
        else if f is RuntimeMethod {function=(f as! RuntimeMethod).function}
        else {
            throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("checkParameters for illegal function decl:\(f)"), sourceLocatable: self.location)
        }*/

        let argcount=(argumentClause?.count ?? 0) + (trailingClosure != nil ? 1 : 0)
        if function.signature.parameterList.count != argcount {
            //check varargs
            var ok=false
            for p in function.signature.parameterList {
                if p.isVarargs {ok=true;break}
            }
            if (!ok) {return false}
        }

        var pi=0
        if argumentClause != nil {
            for a in argumentClause! {
                var aname:String?=nil
                var atype: ASTType?=nil

                switch a {
                    case .expression(let ast):
                        atype=try ast.getType()
                    case .namedExpression(let name, let ast):
                        aname=name
                        atype=try ast.getType()
                    case .memoryReference(let ast):
                        atype=try ast.getType()
                    case .namedMemoryReference(let name, let ast):
                        aname=name
                        atype=try ast.getType()
                    case .`operator`(let op):
                        atype=op.getType() //TODO Operator is of type String, type of expression is ???
                    case .namedOperator(let name, let op):
                        aname=name
                        atype=op.getType() //TODO Operator is of type String, type of expression is ???
                }

                let p=function.signature.parameterList[pi]
                var pname=p.externalName
                if pname==nil {pname=p.localName}
                let ptype=p.typeAnnotation.type

                if p.isVarargs {
                    return true //skip rest varargs
                }

                //print("atype=",atype," ptype=",ptype)

                if pname != "_" {
                    if aname == nil {
                        return false
                    }

                    if pname != aname! {
                        return false
                    }
                }
                else if aname != nil {
                    return false
                }

                //TODO check types
                //recognize genericParameterClause here too since arg types maybe specialization arguments

                pi=pi+1
            }
        }
        if trailingClosure != nil {
            let a=trailingClosure!
            let p=function.signature.parameterList[pi]

            let atype=try a.getType()
            let ptype=p.typeAnnotation.type

            //TODO check types
        }

        return true
    }

    func SpecializeFunction(_ f:FunctionDeclaration, location: SourceLocatable) throws -> FunctionDeclaration? {
        if f.genericParameterClause==nil {return f}

        var identifiers:[String]=[]
        for gp in f.genericParameterClause!.parameterList {
            switch gp {
                case .identifier(let identifier):
                    //replace ident
                    //print("replace ",identifier)
                    identifiers.append(identifier)
                case .typeConformance(let identifier, let type):
                    //replace ident and check for type conformance
                    throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("todo SpecializeFunction typeConformance"), sourceLocatable: self.location)
                case .protocolConformance(let identifier, let proto):
                    //replace ident and check for protocol conformance
                    throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("todo SpecializeFunction protocolConformance"), sourceLocatable: self.location)
            }
        }

        var idtypes:[String:ASTType]=[:]
        if argumentClause != nil {
            for a in argumentClause! {
                switch a {
                    case .expression(let ast):
                        let tt=try ast.getType()
                        for n in identifiers {
                            let t=tt.findType(name:n)
                            if t != nil {
                                idtypes[n]=t
                            }
                        }
                    case .namedExpression(_, let ast):
                        let tt=try ast.getType()
                        for n in identifiers {
                            let t=tt.findType(name:n)
                            if t != nil {
                                idtypes[n]=t
                            }
                        }
                    case .memoryReference(let ast):
                        let tt=try ast.getType()
                        for n in identifiers {
                            let t=tt.findType(name:n)
                            if t != nil {
                                idtypes[n]=t
                            }
                        }
                    case .namedMemoryReference(_, let ast):
                        let tt=try ast.getType()
                        for n in identifiers {
                            let t=tt.findType(name:n)
                            if t != nil {
                                idtypes[n]=t
                            }
                        }
                    case .`operator`(let op):
                           throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("todo SpecializeFunction:\(f)"), sourceLocatable: self.location)
                    case .namedOperator(_, let op):
                           throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("todo SpecializeFunction:\(f)"), sourceLocatable: self.location)
                }
            }
        }

        var argtypes:[ASTType]=[]
        for a in identifiers {
            let p=idtypes[a]
            if p != nil {argtypes.append(p!)}
        }
        if argtypes.count != identifiers.count {return nil}

        return try f.parent!.SpecializeFunction(f, genericArgs: argtypes, location: location)
    }
    
    public override func exec() throws -> Value {
        let result:Value = runtimeNilValue

        let callee=try postfixExpression.exec()

        let instance:Any?=nil

        //print("function call ",resolvedTarget!.name," has generic args:",resolvedTarget!.genericParameterClause)

        //print("exec function call for: ",callee)
        switch callee.type.0 {
            case .type:
                if resolvedTarget == nil {
                    let t=callee.value as! ASTType
                    if t is StructOrClassType {
                        if t is ProtocolType {
                            //Cast to protocol??
                            throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("protocol \(t) is not callable"), sourceLocatable: self.location)
                        }
    
                        //find constructor
                        guard let c=try t.decl?.findFunc(name: "init", location: location, genericArgs: nil, recurse:false) else {
                            throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.noAccessibleInitializers(t.name), sourceLocatable: self.location)
                        }
                        
                        //check argument matching
                        var initializer: FunctionDeclaration?=nil
                        for f in c {
                            if try checkParameters(function:f) {
                                if initializer != nil {
                                    throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.ambiguiousInitializer(t.name), sourceLocatable: self.location)
                                }
                                initializer=f
                            }
                        }
    
                        if initializer==nil {
                            throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.noAccessibleInitializers(t.name), sourceLocatable: self.location)
                        }
    
                        //print("Constructor call:",initializer!)

                        resolvedTarget=initializer
                    }
                    else {
                        throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("type \(t) is not callable"), sourceLocatable: self.location)
                    }
                }
            //case .typeList
        
            case .function:
                if resolvedTarget == nil {
                    if let fff=callee.value as? RuntimeFunctionDeclaration {
                        var f:FunctionDeclaration?=nil
                        if fff is FunctionDeclaration {f=fff as! FunctionDeclaration}
                        /*else if let m=fff as? RuntimeMethod {
                            f=m.function
                            instance=m.instance.value
                        }*/
                        else {
                            throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("\(callee) is not callable:\(fff)"), sourceLocatable: self.location)
                        }

                        if f!.genericParameterClause != nil {
                            f=try self.SpecializeFunction(f!, location: location)
                            if f == nil {
                                //throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("\(callee) is not callable"), sourceLocatable: self.location)
                                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.illegalNumberOfFuncSpecializationArguments(fff.name), sourceLocatable: location)
                            }
                        }

                        //check argument matching
                        var function: FunctionDeclaration?=nil
                        if try checkParameters(function:f!) {
                            if fff is FunctionDeclaration {function=fff as! FunctionDeclaration}
                            /*else if let m=fff as? RuntimeMethod {
                                function=m.function
                                instance=m.instance.value
                            }*/
                        }
    
                        if function==nil {
                            throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.cannotFind(fff.name), sourceLocatable: self.location)
                        }
    
                        //print("function call:",initializer!)

                        resolvedTarget=function
                    }
                }

            case . functionList:
                if let ff=callee.value as? [RuntimeFunctionDeclaration] {
                    //check argument matching
                    var function: FunctionDeclaration?=nil
                    for fff in ff {
                        var f:FunctionDeclaration?=nil
                        if fff is FunctionDeclaration {f=fff as! FunctionDeclaration}
                        /*else if let m=fff as? RuntimeMethod {
                            f=m.function
                            instance=m.instance.value
                        }*/
                        else {
                            throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("\(callee) is not callable:\(fff)"), sourceLocatable: self.location)
                        }

                        if f!.genericParameterClause != nil {
                            f=try self.SpecializeFunction(f!, location: location)
                            if f == nil {
                                //throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("\(callee) is not callable"), sourceLocatable: self.location)
                                continue
                            }
                        }

                        if try checkParameters(function:f!) {
                            if function != nil {
                                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.ambiguiousFunction(fff.name), sourceLocatable: self.location)
                            }
                            if fff is FunctionDeclaration {function=fff as! FunctionDeclaration}
                            /*else if let m=fff as? RuntimeMethod {
                                function=m.function
                                instance=m.instance.value
                            }*/
                        }
                    }
    
                    if function==nil {
                        throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.cannotFind(ff[0].name), sourceLocatable: self.location)
                    }
    
                    //print("Constructor call:",initializer!)

                    resolvedTarget=function
                }

            //case .variable
            //case . variableList

            default:
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("\(callee) is not callable"), sourceLocatable: self.location)
        } //switch

        if resolvedTarget == nil {
            throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("\(callee) is not callable"), sourceLocatable: self.location)
        }

        //get all arguments
        var args:[Value]=[]
        if argumentClause != nil {
            for a in argumentClause! {
                switch a {
                    case .expression(let ast):
                        //TODO handle inout
                        var e=try ast.exec()
                        if e.type.0 == . variable {
                            e=(e.value as! RuntimeVariable).value!
                        }
                        args.append(e)
                    case .namedExpression(_, let ast):
                        //TODO handle inout
                        var e=try ast.exec()
                        if e.type.0 == . variable {
                            e=(e.value as! RuntimeVariable).value!
                        }
                        args.append(e)
                    case .memoryReference(let ast):
                        //TODO handle inout
                        var e=try ast.exec()
                        if e.type.0 == . variable {
                            e=(e.value as! RuntimeVariable).value!
                        }
                        args.append(e)
                    case .namedMemoryReference(_, let ast):
                        //TODO handle inout
                        var e=try ast.exec()
                        if e.type.0 == . variable {
                            e=(e.value as! RuntimeVariable).value!
                        }
                        args.append(e)
                    case .`operator`(let op):
                        throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("todo op call:\(resolvedTarget!)"), sourceLocatable: self.location)
                    case .namedOperator(_, let op):
                        throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("todo op call:\(resolvedTarget!)"), sourceLocatable: self.location)
                }
            }
        }

        //print("resolvedTarget:",resolvedTarget," body=",resolvedTarget?.body," cif=",resolvedTarget?.cif)
        let rettype=try resolvedTarget!.getType()

        /*if resolvedTarget!.body==nil && resolvedTarget!.cif==nil {
            //check for external func
            if resolvedTarget!.resolvedSymbol==0 {
                if resolvedTarget!.mangledName != nil {
                    resolvedTarget!.resolvedSymbol=symbolAdressOf(name: resolvedTarget!.mangledName!)
                }
                    
                if resolvedTarget!.resolvedSymbol==0 {
                    #if WINDOWS
                    if callee.type.0 == .type { //constructor
                        if let t=callee.value as? ASTType {
                            if t.name=="User" {
                                registeredClasses[t.module!.name+"."+t.name]=User.self
                                t.nativeType=User.self
                                return Value(object: User()) 
                            }
                        }
                    }
                    else if resolvedTarget!.mangledName=="$s4USER4UserC5test1yySiF" { //User.test1(int:Int) -> Int
                        return Value(int:(instance as! User).test1(1))
                    }
                    #endif

                    if callee.type.0 == .type { //constructor
                        throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("initializer \(resolvedTarget!.name) is not present for \(callee):\(resolvedTarget!.mangledName)"), sourceLocatable: self.location)
                    }
                    else {
                        throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("function \(resolvedTarget!.name) is not present for \(callee):\(resolvedTarget!.mangledName)"), sourceLocatable: self.location)
                    }
                }
            }

            //build cif
            resolvedTarget!.cif=alloc_ffi()
            var argTypes: [Pffi_type] = []
            //build arg types
            //print("building args")
            for p in resolvedTarget!.signature.parameterList {
                //if p.isVarargs {ok=true;break}
                //todo
                let t=p.typeAnnotation.type.runtimeType?.1
                if t==nil {
                    throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("function \(resolvedTarget!.name)  has illegal parameter type for \(p)"), sourceLocatable: self.location)
                }
                argTypes.append(t!)
            }
            
            if rettype.runtimeType?.1==nil {
                    throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("function \(resolvedTarget!.name)  has illegal result type for \(rettype)"), sourceLocatable: self.location)
            }
            //print("prepping_cif")
            let status=prep_ffi(cif: resolvedTarget!.cif, returnType: rettype.runtimeType!.1 , argTypes: argTypes) 
            //print("got cif")
        }

        if resolvedTarget!.cif != nil { //external call
            if callee.type.0 == .type { //constructor
                var ut:Any.Type?=nil
                if let t=callee.value as? ASTType {
                    ut=t.nativeType //registeredClasses[t.module!.name+"."+t.name]
                }
                        
                if ut==nil {
                    throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("class \(callee.value) not registered"), sourceLocatable: self.location)
                }
                let o=try createInstance(of: ut! , constructor: nil) 
                call_ffi_method (cif: resolvedTarget!.cif!, addr:resolvedTarget!.resolvedSymbol, this: o, args:&args, 
                                returnType: void_rt_type/*rettype.runtimeType!*/)
                if callee.value is StructType {return Value(struct: o)}
                if callee.value is EnumType {return Value(enum: o)}
                return Value(object: o as! AnyObject) 
            }
            else  { //func
                //print("call_ffi")
                return call_ffi_method (cif: resolvedTarget!.cif!, addr:resolvedTarget!.resolvedSymbol, this: instance, args:&args, 
                                        returnType: rettype.runtimeType!)
            }
        } //external call
        */

        //throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("todo call:\(resolvedTarget!)"), sourceLocatable: self.location)
        //todo?
        return try resolvedTarget!.executor(args) 
    }
    
    public override func getType() throws -> ASTType {return try postfixExpression.getType()}
 }






















