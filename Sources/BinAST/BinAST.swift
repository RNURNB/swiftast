import Foundation
import SwiftAST
//import Runtime

class ASTGenerationError:Error {
    public init(_ msg:String) {
        print(msg)
    }
}

public enum BinaryOperationType: Int {
    case plus=1
    case minus
    case mult
    case floatDiv
    case integerDiv
}

public enum UnaryOperationType: Int {
    case plus=1
    case minus
}

public enum ConditionType: Int {
    case equals=1
    case lessThan
    case greaterThan
}


public protocol ASTDelegate {
    func generateASTBase(_ ast: ASTBase) throws
    
    func generateASTType(_ ast: ASTType) throws
    
    func generateASTType_TryIndexedType(_ ast: ASTType.TryIndexedType) throws
    
    func generateString(_ ast: String) throws
    
    func generateBool(_ ast: Bool) throws
    
    func generateInt(_ ast: Int) throws
    
    func generateDouble(_ ast: Double) throws
    
    func generateASTTypeIdentifier_TypeName(_ ast: ASTTypeIdentifier.TypeName) throws
    
    func generateASTTypeIdentifier(_ ast: ASTTypeIdentifier) throws
    
    func generateASTProtocolCompositionType(_ ast: ASTProtocolCompositionType) throws
    
    func generateASTGenericWhereClause_Requirement(_ ast: ASTGenericWhereClause.Requirement) throws
    
    func generateASTGenericWhereClause(_ ast: ASTGenericWhereClause) throws
    
    func generateASTTypeInheritanceClause(_ ast: ASTTypeInheritanceClause) throws
    
    func generateFunctionResult(_ ast: FunctionResult) throws
    
    func generateFunctionSignature(_ ast: FunctionSignature) throws
    
    func generateMember(_ ast: Member) throws
    
    func generateASTTypeAnnotation(_ ast: ASTTypeAnnotation) throws
    
    func generateASTGenericArgumentClause(_ ast: ASTGenericArgumentClause) throws
    
    func generateDictionaryEntry(_ ast: DictionaryEntry) throws
    
    func generatePlaygroundLiteral(_ ast: PlaygroundLiteral) throws
    
    func generateASTGenericParameterClause(_ ast: ASTGenericParameterClause) throws
    
    func generateUnaryOperation(_ ast: UnaryOperation) throws
    
    func generateBinaryOperation(_ ast: BinaryOperation) throws
    
    func generateVariable(_ ast: Variable) throws
    
    func generateVariableDeclaration(_ ast: VariableDeclaration) throws
    
    func generateTypealiasDeclaration(_ ast: TypealiasDeclaration) throws
    
    func generateImportDeclaration(_ ast: ImportDeclaration) throws
    
    func generateWillSetDidSetBlock(_ ast: WillSetDidSetBlock) throws
    
    func generateGetterSetterKeywordBlock(_ ast: GetterSetterKeywordBlock) throws
    
    func generateMethodMember(_ ast: MethodMember) throws
    
    func generateAssociativityTypeMember(_ ast: AssociativityTypeMember) throws
    
    func generateClassDeclaration(_ ast: ClassDeclaration) throws
    
    func generateStructDeclaration(_ ast: StructDeclaration) throws
    
    func generateProtocolDeclaration(_ ast: ProtocolDeclaration) throws
    
    func generateFunctionDeclaration(_ ast: FunctionDeclaration) throws
    
    func generateIdentifierExpression(_ ast: IdentifierExpression) throws
    
    func generateSubscriptMember(_ ast: SubscriptMember) throws
    
    func generateLiteral(_ ast: Literal) throws
    
    func generateExplicitMemberExpression(_ ast: ExplicitMemberExpression) throws
    
    func generateScope(_ ast: Scope) throws
    
    func generateASTModule(_ ast: ASTModule) throws
    
    func generateCompound(_ ast: Compound) throws
    
    func generateNoOp(_ ast: NoOp) throws
    
    func generateAssignment(_ ast: Assignment) throws
    
    func generateReturnStatement(_ ast: ReturnStatement) throws
    
    func generateClosureExpression(_ ast: ClosureExpression) throws
    
    func generateFunctionCallExpression(_ ast: FunctionCallExpression) throws
    
    func generateCodeBlock(_ ast: CodeBlock) throws
    
    
    //public func generate(delegate: ASTDelegate) throws {delegate.generateASTBase(self)}
}
public protocol AST {
    var next:AST? {get set}
    var previous:AST? {get set}
    
    func copy() -> AST
    
    func replace(name: String, with: AST) -> AST
    
    func archive(data: SCLData) throws
    
    static func unarchive(data: SCLData, instance:AST?) throws -> AST
    
    func runDeclarations(isTopLevel:Bool) throws
        func generate(delegate: ASTDelegate) throws

    func exec() throws -> Value

    func getType() throws -> ASTType
    
}

public class ASTLocation: SourceLocatable, CustomStringConvertible {
    public var module:ASTModule?
    public var file:Int
    public var line:Int
    public var column:Int

    public var description: String {
        if module != nil {
            return "file: \(filename), line: \(line) column: \(column)"
        }
        return "file: \(file), line: \(line) column: \(column)"
    }

    public var filename:String {
        if module != nil {
            return module!.filesmap[file]!
        }
        return ""
    }
    
    public var sourceRange: SourceRange { 
        let l=SourceLocation(identifier: module != nil ? module!.filesmap[file]! : "", line:line, column: column)
        return SourceRange(start:l, end:l)
    }

    public init() {
        self.module = nil
        self.file = -1
        self.line = -1
        self.column = -1
    }
    
    public init(file:Int, line: Int, column: Int) {
        self.module=file<0 ? nil : ASTModule.current
        self.file=file
        self.line=line
        self.column=column
    }
    
    public init(location: SourceLocatable) {
        let id=location.sourceLocation.identifier
        let m=ASTModule.current
        self.module=m
        var file:Int?=m.files[id]
        if file==nil {file=m.files.count+1;m.files[id]=file!;m.filesmap[file!]=id}
        self.file=file!
        self.line=location.sourceLocation.line
        self.column=location.sourceLocation.column
    }
}

public struct Attribute {
    public struct ArgumentClause {
        public enum BalancedToken {
            case token(String)
            case parenthesis([BalancedToken])
            case square([BalancedToken])
            case brace([BalancedToken])

            public var textDescription: String {
                switch self {
                    case .token(let tokenString):
                        return tokenString
                    case .parenthesis(let tokens):
                        return "(\(tokens.textDescription))"
                    case .square(let tokens):
                        return "[\(tokens.textDescription)]"
                    case .brace(let tokens):
                        return "{\(tokens.textDescription)}"
                }
            }

            public func copy() -> BalancedToken {
                switch self {
                    case .token(let s):
                        return .token(s)
                    case .parenthesis(let bt):
                        var btc:[BalancedToken]=[]
                        for b in bt {btc.append(b.copy())}
                        return .parenthesis(btc)
                    case .square(let bt):
                        var btc:[BalancedToken]=[]
                        for b in bt {btc.append(b.copy())}
                        return .square(btc)
                    case .brace(let bt):
                        var btc:[BalancedToken]=[]
                        for b in bt {btc.append(b.copy())}
                        return .brace(btc)
                }
            }
        }

        public let balancedTokens: [BalancedToken]

        public init(balancedTokens: [BalancedToken] = []) {
            self.balancedTokens = balancedTokens
        }

        public func copy() -> ArgumentClause {
            var btc:[BalancedToken]=[]
            for b in balancedTokens {
                btc.append(b.copy())
            }
            return ArgumentClause(balancedTokens: btc)
        }
    }

    public let name: String
    public let argumentClause: ArgumentClause?

    public init(name: String, argumentClause: ArgumentClause? = nil) {
        self.name = name
        self.argumentClause = argumentClause
    }

    public func copy() -> Attribute {
        let ac:ArgumentClause?=self.argumentClause?.copy()
        return Attribute(name: name, argumentClause: ac)
    }    
}

extension Collection where Iterator.Element == Attribute.ArgumentClause.BalancedToken {
  public var textDescription: String {
    return self.map({ $0.textDescription }).joined()
  }
}

public enum Modifier:Int {
    case `class` = 1
    case convenience
    case dynamic
    case final
    case infix
    case lazy
    case optional
    case override
    case postfix
    case prefix
    case required
    case `static`
    case unowned
    case unownedSafe
    case unownedUnsafe
    case weak
    case `private` 
    case privateSet 
    case `fileprivate`
    case fileprivateSet 
    case `internal`
    case internalSet 
    case `public`
    case publicSet 
    case `open`
    case openSet 
    case mutating
    case nonmutating
}

func archiveBalancedToken(data: SCLData, _ bt:Attribute.ArgumentClause.BalancedToken) {
    switch bt {
        case .token(let s):
            data.writeWord(0)
            data.writeShortString(s)
        case .parenthesis(let l):
            data.writeWord(1)
            data.writeWord(UInt16(l.count))
            for bt in l {archiveBalancedToken(data: data, bt)}
        case .square(let l):
            data.writeWord(2)
            data.writeWord(UInt16(l.count))
            for bt in l {archiveBalancedToken(data: data, bt)}
        case .brace(let l):
            data.writeWord(3)
            data.writeWord(UInt16(l.count))
            for bt in l {archiveBalancedToken(data: data, bt)}
    }
}

func unarchiveBalancedToken(data: SCLData) -> Attribute.ArgumentClause.BalancedToken {
    let i=Int(data.readWord())
    if i==0 {return .token(data.readShortString()!)}
    else if i==1 {
        let c=Int(data.readWord());
        var bts:[Attribute.ArgumentClause.BalancedToken]=[]
        for _ in 0..<c {
            bts.append(unarchiveBalancedToken(data: data))
        }
        return .parenthesis(bts)
    }
    else if i==2 {
        let c=Int(data.readWord());
        var bts:[Attribute.ArgumentClause.BalancedToken]=[]
        for _ in 0..<c {
            bts.append(unarchiveBalancedToken(data: data))
        }
        return .square(bts)
    }
    else if i==3 {
        let c=Int(data.readWord());
        var bts:[Attribute.ArgumentClause.BalancedToken]=[]
        for _ in 0..<c {
            bts.append(unarchiveBalancedToken(data: data))
        }
        return .brace(bts)
    }
    else {return .token("")}
}

func archiveAttributes(data: SCLData, _ a:[Attribute]) {
    data.writeWord(UInt16(a.count))
    for aa in a {
        data.writeShortString(aa.name)
        if aa.argumentClause != nil {
            data.writeBool(true)
            data.writeWord(UInt16(aa.argumentClause!.balancedTokens.count))
            for bt in aa.argumentClause!.balancedTokens {
                archiveBalancedToken(data:data, bt)
            }
        }
        else {data.writeBool(false)}
    }
}

func unarchiveAttributes(data: SCLData) -> [Attribute] {
    var result:[Attribute]=[]

    let i=Int(data.readWord())
    for _ in 0..<i {
        let name=data.readShortString()!
        var ac:Attribute.ArgumentClause?=nil
        if data.readBool() {
            let c=Int(data.readWord())
            var bts:[Attribute.ArgumentClause.BalancedToken]=[]
            for _ in 0..<c {
                bts.append(unarchiveBalancedToken(data: data))
            }
            ac=Attribute.ArgumentClause(balancedTokens:bts)
        }
        result.append(Attribute(name: name, argumentClause: ac))
    }

    return result
}

func archiveModifiers(data: SCLData, _ m:[Modifier]) {
    data.writeWord(UInt16(m.count))
    for mm in m {
        data.writeWord(UInt16(mm.rawValue))
    }
}

func unarchiveModifiers(data: SCLData) -> [Modifier] {
    var result:[Modifier]=[]

    let i=Int(data.readWord())
    for _ in 0..<i {
        let m=Int(data.readWord())
        result.append(Modifier(rawValue:m)!)
    }

    return result
}


public class ASTBase: AST {
    public var location: ASTLocation
    public var next:AST?=nil
    public var previous:AST?=nil
    public var needsDecl:Bool=true
    public var modifiers:[Modifier]=[]
    public var attributes:[Attribute]=[]
    public var parent:Scope?
    
    public init() {
        parent=nil
        location=ASTLocation(location: SourceLocation(identifier: "", line: -1, column: -1))
    }
    
    public init(file:Int, line: Int, column: Int) {
        parent=nil
        location=ASTLocation(file:file, line:line, column:column)
    }
    
    public init(location: SourceLocatable) {
        
        self.location=ASTLocation(location:location)
    }
    
    open func archive(data: SCLData) throws {
        //this call is only valid if we are not the root
        if data.isRoot {
            throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("ASTBase archive called for \(type(of:self))"), sourceLocatable: location)
        }
        
        var m = -1
        if location.module != nil {m=location.module!.index}
        let tuple=DataExt(pair: (m,location.file,location.line,location.column))
        var i=data.extratuples[tuple]
        if i==nil {
            i=data.extratuples.count+1
            data.extratuples[tuple]=i
        }
        data.writeInt(i!)

        archiveModifiers(data: data, modifiers)
        archiveAttributes(data: data, attributes)
    }
    
    public static func unarchive(data: SCLData, instance:AST?=nil) throws -> AST {

        if instance==nil {
            throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("ASTBase unarchive called for \(type(of:self))"), sourceLocatable: SourceLocation(identifier: "", line: -1, column: -1))
        }
        
        let i=instance as! ASTBase
        
        let l=data.readInt()
        if let tuple=data.extratuplesmap[l] {
            i.location.module=data.importmapping[tuple.pair.p]
            i.location.file=tuple.pair.q
            i.location.line=tuple.pair.r
            i.location.column=tuple.pair.s
        }

        i.modifiers=unarchiveModifiers(data: data)
        i.attributes=unarchiveAttributes(data: data)
        
        return instance!
    }
    
    open func runDeclarations(isTopLevel:Bool) throws {}
    
    public func generate(delegate: ASTDelegate) throws {try delegate.generateASTBase(self)}

    open func exec() throws -> Value {runtimeNilValue}
    
    open func copy() -> AST {
        return self
    }
    
    open func replace(name: String, with: AST) -> AST {
        return self
    }

    open func getType() throws -> ASTType {
        throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("ASTBase getType called for \(type(of:self))"), sourceLocatable: location)
    }
}

/*public enum Number: AST {
    case integer(Int)
    case real(Double)
    
    public func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.Number.rawValue))}
    }
    
    public static func unarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i=instance != nil ? instance as! Number : try ASTFromTag(data: data) as! Number
        
        return i
    }
}*/

extension String: AST {
    public var next:AST? {get {return nil} set(newvalue) {}}
    public var previous:AST? {get {return nil} set(newvalue) {}}
    
    public func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.String.rawValue))}
        data.writeShortString(self)
    }
    
    public static func unarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        var i=instance != nil ? instance as! String : try ASTFromTag(data: data) as! String
        
        i=data.readShortString()!
        
        return i
    }
    
    public func copy() -> AST {return self}
    
    public func replace(name: String, with: AST) -> AST {return self}
    
    public func runDeclarations(isTopLevel:Bool) {}
    
    public func generate(delegate: ASTDelegate) throws {try delegate.generateString(self)}

    public func exec() throws -> Value {
        var v=RuntimeValue(string:self)
        v.type=RuntimeSwiftType(.string,RuntimeSwiftType_Literal)
        return v
    }

    public func getType() -> ASTType {return StringType}
}

extension Bool: AST {
    public var next:AST? {get {return nil} set(newvalue) {}}
    public var previous:AST? {get {return nil} set(newvalue) {}}
    
    public func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.Bool.rawValue))}
        data.writeBool(self)
    }
    
    public static func unarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        var i=instance != nil ? instance as! Bool : try ASTFromTag(data: data) as! Bool
        
        i=data.readBool()
        
        return i
    }
    
    public func copy() -> AST {return self}
    
    public func replace(name: String, with: AST) -> AST {return self}
    
    public func runDeclarations(isTopLevel:Bool) {}
    
    public func generate(delegate: ASTDelegate) throws {try delegate.generateBool(self)}

    public func exec() throws -> Value {
        var v=RuntimeValue(bool:self)
        v.type=RuntimeSwiftType(.bool,RuntimeSwiftType_Literal)
        return v
    }

    public func getType() -> ASTType {return BoolType}
}

extension Int: AST {
    public var next:AST? {get {return nil} set(newvalue) {}}
    public var previous:AST? {get {return nil} set(newvalue) {}}
    
    public func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.Int.rawValue))}
        data.writeInt(self)
    }
    
    public static func unarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        var i=instance != nil ? instance as! Int : try ASTFromTag(data: data) as! Int
        
        i=data.readInt()
        
        return i
    }
    
    public func copy() -> AST {return self}
    
    public func replace(name: String, with: AST) -> AST {return self}
    
    public func runDeclarations(isTopLevel:Bool) {}
    
    public func generate(delegate: ASTDelegate) throws {try delegate.generateInt(self)}

    public func exec() throws -> Value {
        var v=RuntimeValue(int:self)
        v.type=RuntimeSwiftType(.int,RuntimeSwiftType_Literal)
        return v
    }

    public func getType() -> ASTType {return IntType}
}

extension Double: AST {
    public var next:AST? {get {return nil} set(newvalue) {}}
    public var previous:AST? {get {return nil} set(newvalue) {}}
    
    public func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.Double.rawValue))}
        data.writeDouble(self)
    }
    
    public static func unarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        var i=instance != nil ? instance as! Double : try ASTFromTag(data: data) as! Double
        
        i=data.readDouble()
        
        return i
    }
    
    public func copy() -> AST {return self}
    
    public func replace(name: String, with: AST) -> AST {return self}
    
    public func runDeclarations(isTopLevel:Bool) {}
    
    public func generate(delegate: ASTDelegate) throws {try delegate.generateDouble(self)}

    public func exec() throws -> Value {
        var v=RuntimeValue(double:self)
        v.type=RuntimeSwiftType(.double,RuntimeSwiftType_Literal)
        return v
    }

    public func getType() -> ASTType {return DoubleType}
}

public protocol Declaration: AST {
}

public class UnaryOperation: ASTBase {
    public var operation: UnaryOperationType
    public var operand: AST
    
    public override init() {
        operation = .minus
        operand=NoOp()
        super.init()
    }

    init(location: SourceLocatable, operation: UnaryOperationType, operand: AST) {
        self.operation = operation
        self.operand = operand
        super.init(location: location)
    }
    
    public override func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.UnaryOperation.rawValue))}
        
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true
        
        data.writeInt(operation.rawValue)
        try operand.archive(data:data)
        
        data.isRoot=root
    }
    
    public static func UnaryOperationunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i:UnaryOperation=instance != nil ? instance as! UnaryOperation : try ASTFromTag(data: data) as! UnaryOperation
        
        try _=ASTBase.unarchive(data: data, instance: i)
        
        i.operation=UnaryOperationType(rawValue: data.readInt())!
        i.operand=try ASTFromTag(data: data)
        
        return i
    }
    
    public override func copy() -> AST {return UnaryOperation(location: location, operation: operation, operand: operand.copy())}
    
    public override func replace(name: String, with: AST) -> AST {return self}

    public override func exec() throws -> Value {
        //todo
        runtimeNilValue
    }

    public override func getType() throws -> ASTType {return try operand.getType()}
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateUnaryOperation(self)}
}

public class BinaryOperation: ASTBase {
    public var left: AST
    public var operation: BinaryOperationType
    public var right: AST
    
    public override init() {
        operation = .minus
        left=NoOp()
        right=NoOp()
        super.init()
    }

    init(location: SourceLocatable, left: AST, operation: BinaryOperationType, right: AST) {
        self.left = left
        self.operation = operation
        self.right = right
        super.init(location: location)
    }
    
    public override func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.BinaryOperation.rawValue))}
        
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true
        
        data.writeInt(operation.rawValue)
        try left.archive(data:data)
        try right.archive(data:data)
        
        data.isRoot=root
    }
    
    public static func BinaryOperationunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i:BinaryOperation=instance != nil ? instance as! BinaryOperation : try ASTFromTag(data: data) as! BinaryOperation
        
        try _=ASTBase.unarchive(data: data, instance: i)
        
        i.operation=BinaryOperationType(rawValue: data.readInt())!
        i.left=try ASTFromTag(data: data)
        i.right=try ASTFromTag(data: data)
        
        return i
    }
    
    public override func copy() -> AST {return BinaryOperation(location: location, left: left.copy(), operation: operation, right: right.copy())}
    
    public override func replace(name: String, with: AST) -> AST {return self}

    public override func exec() throws -> Value {
        //todo
        runtimeNilValue
    }

    public override func getType() throws -> ASTType {return try left.getType()} //??
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateBinaryOperation(self)}
}

public class Variable: ASTBase, RuntimeVariable {
    public var name: String
    public var isConstant: Bool
    public var isCell: Bool = false
    public var typeAnnotation:ASTTypeAnnotation
    public var getterSetterKeywordBlock:GetterSetterKeywordBlock?
    public var willSetDidSetBlock: WillSetDidSetBlock?
    public var value:Value?=nil
    public var modifyAccessorMangledName:String?=nil
    public var decl: VariableDeclaration?=nil //runtime only
    public var pdecl: FunctionSignature.Parameter?=nil //runtime only
        
    public override init() {
        name=""
        self.isConstant = true
        self.typeAnnotation=ASTTypeAnnotation()
        self.getterSetterKeywordBlock=nil
        self.willSetDidSetBlock=nil
        super.init()
    }


    init(name: String,typeAnnotation: ASTTypeAnnotation, isConstant: Bool, attributes: [Attribute], modifiers: [Modifier], 
         location: SourceLocatable, getterSetterKeywordBlock:GetterSetterKeywordBlock?=nil, willSetDidSetBlock: WillSetDidSetBlock?=nil) {
        self.name = name
        self.isConstant = isConstant
        self.typeAnnotation = typeAnnotation
        self.getterSetterKeywordBlock=getterSetterKeywordBlock
        self.willSetDidSetBlock=willSetDidSetBlock
        super.init(location: location)
        self.attributes = attributes
        self.modifiers = modifiers
    }

    public func setValue(value:RuntimeValue?) {self.value=value}
    
    public override func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.Variable.rawValue))}
        
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true
        
        data.writeShortString(name)

        data.writeBool(isConstant)
        try typeAnnotation.archive(data: data)
        
        if getterSetterKeywordBlock != nil {
            data.writeBool(true)
            try getterSetterKeywordBlock!.archive(data: data)
        }
        else {data.writeBool(false)}

        if willSetDidSetBlock != nil {
            data.writeBool(true)
            try willSetDidSetBlock!.archive(data: data)
        }
        else {data.writeBool(false)}
        
        if modifyAccessorMangledName != nil {
            data.writeBool(true)
            data.writeString(modifyAccessorMangledName!)
        }
        else {data.writeBool(false)}
        
        data.isRoot=root
    }
    
    public static func Variableunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i:Variable=instance != nil ? instance as! Variable : try ASTFromTag(data: data) as! Variable
        
        try _=ASTBase.unarchive(data: data, instance: i)
        
        i.name=data.readShortString()!

        i.isConstant=data.readBool()
        i.typeAnnotation=try ASTFromTag(data: data) as! ASTTypeAnnotation
        if data.readBool() {
            i.getterSetterKeywordBlock=(try ASTFromTag(data: data) as! GetterSetterKeywordBlock)
        }
        if data.readBool() {
            i.willSetDidSetBlock=(try ASTFromTag(data: data) as! WillSetDidSetBlock)
        }
        
        if data.readBool() {
            i.modifyAccessorMangledName=data.readString()!
        }
        
        return i
    }
    
    public override func copy() -> AST {
        var a:[Attribute]=[]
        for aa in attributes {a.append(aa.copy())}
        var m:[Modifier]=[]
        for mm in modifiers {m.append(mm)}
        
        return Variable(name: name,typeAnnotation: typeAnnotation.copy() as! ASTTypeAnnotation, isConstant: isConstant, 
                        attributes: a, modifiers: m, location: location, 
                        getterSetterKeywordBlock: getterSetterKeywordBlock?.copy() as? GetterSetterKeywordBlock,
                        willSetDidSetBlock: willSetDidSetBlock?.copy() as? WillSetDidSetBlock)
    }
    
    public override func replace(name: String, with: AST) -> AST {if name==name {return with};return self}
    
    public override func runDeclarations(isTopLevel:Bool) throws {
        //ignore
        //remove this from list for further execution
        if previous != nil {
            previous!.next=next
            next?.previous=previous
        }
    }

    public override func exec() throws -> Value {
        return RuntimeValue(variable:self)
    }

    public override func getType() -> ASTType {return typeAnnotation.type}
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateVariable(self)}
}

public class VariableDeclaration: ASTBase, Declaration {
    public var variable: Variable
    public var typeAnnotation: ASTTypeAnnotation
    public var isConstant: Bool
    public var initializer: AST?
    
    public override init() {
        variable=Variable()
        typeAnnotation=ASTTypeAnnotation()
        self.isConstant = true
        self.initializer=nil
        super.init()
    }
    
    init(variable: Variable, typeAnnotation: ASTTypeAnnotation, isConstant: Bool, initializer: AST?, 
         attributes: [Attribute], modifiers: [Modifier], location: SourceLocatable) {
        self.variable = variable
        self.typeAnnotation = typeAnnotation
        self.isConstant = isConstant
        super.init(location:location)
        variable.decl=self
        self.attributes = attributes
        self.modifiers = modifiers
        self.initializer=initializer
    }
    
    public override func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.VariableDeclaration.rawValue))}
        
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true
        
        try variable.archive(data: data)
        try typeAnnotation.archive(data: data)
        data.writeBool(isConstant)
        if initializer != nil {
            data.writeBool(true)
            try initializer!.archive(data: data)
        }
        else {data.writeBool(false)}

        data.isRoot=root
    }
    
    public static func VariableDeclarationunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i:VariableDeclaration=instance != nil ? instance as! VariableDeclaration : try ASTFromTag(data: data) as! VariableDeclaration
        
        _=try ASTBase.unarchive(data: data, instance: i)
        
        i.variable=try ASTFromTag(data: data) as! Variable
        i.typeAnnotation=try ASTFromTag(data: data) as! ASTTypeAnnotation
        i.isConstant=data.readBool()
        if data.readBool() {
            i.initializer=try ASTFromTag(data: data)
        }
        
        return i
    }
    
    public override func copy() -> AST {
        var a:[Attribute]=[]
        for aa in attributes {a.append(aa.copy())}
        var m:[Modifier]=[]
        for mm in modifiers {m.append(mm)}
        
        return VariableDeclaration(variable: variable.copy() as! Variable,typeAnnotation: typeAnnotation.copy() as! ASTTypeAnnotation, 
                                   isConstant: isConstant, initializer: initializer?.copy(), attributes: a, modifiers: m, location: location)
    }
    
    public override func replace(name: String, with: AST) -> AST {return self}
    
    public override func runDeclarations(isTopLevel:Bool) throws {
        //let oldNeedsDecl=needsDecl
        if !isTopLevel || needsDecl {
            needsDecl = !isTopLevel;
            try! ASTModule.current.declareVar(variable: variable)
        }

        //we run the initializer declarations to see if all identifiers are present
        try initializer?.runDeclarations(isTopLevel: isTopLevel)

        //remove this from list for further execution
        if (isTopLevel) {
            //if we have an initializer, execute it on the top level
            if /*oldNeedsDecl &&*/ initializer != nil {
                var v=variable as RuntimeVariable
                try doVarAssignment(variable:&v, expr:initializer!, initializer:true)
                variable.value=v.value //might have changed due to assingment, if its a struct
            }

            if previous != nil {
                previous!.next=next
                next?.previous=previous
            }
        }
    }

    public override func getType() -> ASTType {return typeAnnotation.type}
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateVariableDeclaration(self)}
}

public class TypealiasDeclaration: ASTBase, Declaration {
    public var alias:AliasType
    public var context:Scope?=nil //runtime only
    
    public override init() {
        alias=AliasType()
        super.init()
    }

    
    public init(name:String, assignment:ASTType, attributes: [Attribute], modifiers: [Modifier], generic:ASTGenericParameterClause?, location: SourceLocatable) {
        self.alias=AliasType(name: name, attributes: attributes, modifiers: modifiers, location: location, assignment: assignment, generic: generic)
        self.context=ASTModule.current

        super.init(location:location)

        self.attributes=attributes
        self.modifiers=modifiers
    }

    public override func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.TypealiasDeclaration.rawValue))}
        
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true
        
        try alias.archive(data: data)
        
        data.isRoot=root
    }
    
    public static func TypealiasDeclarationunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i=instance != nil ? instance as! TypealiasDeclaration : try ASTFromTag(data: data) as! TypealiasDeclaration
        
        try _=ASTBase.unarchive(data: data, instance: i)
        
        i.alias=try ASTFromTag(data: data) as! AliasType
        
        return i
    }
    
    public override func copy() -> AST {
        var a:[Attribute]=[]
        for aa in attributes {a.append(aa.copy())}
        var m:[Modifier]=[]
        for mm in modifiers {m.append(mm)}
        
        let ta = TypealiasDeclaration()
        ta.attributes=a
        ta.modifiers=m
        ta.location=location
        ta.alias=self.alias.copy() as! AliasType
        return ta
    }
    
    public override func replace(name: String, with: AST) -> AST {return self}
    
    public override func runDeclarations(isTopLevel:Bool) throws {
        if !isTopLevel || needsDecl {needsDecl = !isTopLevel;try ASTModule.current.declareType(type: alias)}
        
        //print("typealias decl ",alias," previous=",previous," next=",next," isTopLevel=",isTopLevel)
        
        //remove this from list for further execution
        if (isTopLevel) {
            if previous != nil {
                previous!.next=next
                next?.previous=previous
            }
        }
    }

    public override func getType() -> ASTType {return alias.getType()}
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateTypealiasDeclaration(self)}
}

public class ImportDeclaration: Scope, Declaration {
    public var module:String
    public var imports:[String]? //nil to import all
    public var handle:ASTModule?=nil
    
    public override init() {
        module=""
        imports=nil
        super.init()
    }

    public init(module:String, location: SourceLocatable, kind:String?=nil, name:String?=nil) {
        self.module=module
        self.imports=nil
        if kind != nil {
            if imports == nil {imports=[]}
            self.imports!.append(kind!+"."+name!)
        }
        super.init(parent:ASTModule.current.currentScope,location:location)
        self.origin=self
    }
    
    public override func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.ImportDeclaration.rawValue))}
        
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true
        
        data.writeShortString(module)
        data.writeInt(handle != nil ? handle!.index : -1)
        data.writeWord(imports != nil ? UInt16(imports!.count) : 0)
        if imports != nil {for i in imports! {data.writeShortString(i)}}
        
        data.isRoot=root
    }
    
    public static func ImportDeclarationunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i=instance != nil ? instance as! ImportDeclaration : try ASTFromTag(data: data) as! ImportDeclaration
        
        try _=Scope.Scopeunarchive(data: data, instance: i)
        
        i.module=data.readShortString()!
        let m=data.readInt()
        if m>=0 {i.handle=data.importmapping[m]!}
        let c=Int(data.readWord()) 
        if c>0 {i.imports=[]}
        for _ in 0..<c {i.imports!.append(data.readShortString()!)}
        
        return i
    }
    
    public override func copy() -> AST {
        //return ImportDeclaration(module: module, location: location)
        return self
    }
    
    public override func replace(name: String, with: AST) -> AST {return self}
    
    public override func runDeclarations(isTopLevel:Bool) {
        //print("rundecl import ",module)

        //ignore
        if previous != nil {
            previous!.next=next
            next?.previous=previous
        }
    }

    public override func getType() -> ASTType {return VoidType}
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateImportDeclaration(self)}
}

public class ASTTypeIdentifier : AST {
    public struct TypeName: AST {
        public var name: String
        public var genericArgumentClause: ASTGenericArgumentClause?

        public var next:AST? {get {return nil} set(newvalue) {}}
        public var previous:AST? {get {return nil} set(newvalue) {}}

        public init() {name="";genericArgumentClause=nil}

        public init(name: String, genericArgumentClause: ASTGenericArgumentClause? = nil) {
            self.name = name
            self.genericArgumentClause = genericArgumentClause
        }

        public func archive(data: SCLData) throws {
            if data.isRoot {data.writeWord(UInt16(ArchiveType.TypeName.rawValue))}
      
            let root=data.isRoot
            data.isRoot=true

            data.writeShortString(name)
            if genericArgumentClause != nil {
                data.writeBool(true)
                try genericArgumentClause!.archive(data: data)
            }
            else {data.writeBool(false)}
      
            data.isRoot=root
        }
  
        public static func unarchive(data: SCLData, instance:AST?=nil) throws -> AST {
            var i:TypeName=instance != nil ? instance as! TypeName : try ASTFromTag(data: data) as! TypeName
            
            i.name=data.readShortString()!
            if data.readBool() {
                    i.genericArgumentClause=(try ASTFromTag(data: data) as! ASTGenericArgumentClause)
            }

            return i
        }
  
        public func copy() -> AST {
            return TypeName(name: name , genericArgumentClause: genericArgumentClause?.copy() as? ASTGenericArgumentClause)
        }
        
        public func replace(name: String, with: AST) -> AST {if self.name==name {return with};return self}
  
        public func runDeclarations(isTopLevel:Bool) {}
        
        public func generate(delegate: ASTDelegate) throws {try delegate.generateASTTypeIdentifier_TypeName(self)}
        
        public func exec() throws -> Value {runtimeNilValue}

        public func getType() -> ASTType {return VoidType} //??
    }

    public var next:AST? {get {return nil} set(newvalue) {}}
    public var previous:AST? {get {return nil} set(newvalue) {}}

    public var names: [TypeName]

    public init(names: [TypeName] = []) {
        self.names = names
    }

    public func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.ASTTypeIdentifier.rawValue))}
      
        let root=data.isRoot
        data.isRoot=true
      
        data.writeWord(UInt16(names.count))
        for n in names {
              try n.archive(data: data)
        }
      
        data.isRoot=root
    }
  
    public static func unarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i:ASTTypeIdentifier=instance != nil ? instance as! ASTTypeIdentifier : try ASTFromTag(data: data) as! ASTTypeIdentifier
      
        let c=Int(data.readWord())
        for _ in 0..<c {
              i.names.append(try ASTFromTag(data: data) as! TypeName)
        }
        
          return i
    }
  
    public func copy() -> AST {
        var a:[TypeName]=[]
        for n in names {
              a.append(n.copy() as! TypeName)
        }
          return ASTTypeIdentifier(names: a)
    }
  
    public func replace(name: String, with: AST) -> AST {
        //todo
          return self
    }
  
    public func runDeclarations(isTopLevel:Bool) {}
    
    public func generate(delegate: ASTDelegate) throws {try delegate.generateASTTypeIdentifier(self)}

    public func exec() throws -> Value {runtimeNilValue}
 
    public func getType() -> ASTType {return VoidType} //??
}

public class ASTProtocolCompositionType : AST {
    public var protocolTypes: [ASTType]

    public var next:AST? {get {return nil} set(newvalue) {}}
    public var previous:AST? {get {return nil} set(newvalue) {}}

    public init() {protocolTypes=[]}

    public init(protocolTypes: [ASTType]) {
        self.protocolTypes = protocolTypes
    }

    public func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.ASTProtocolCompositionType.rawValue))}
      
        let root=data.isRoot
        data.isRoot=true
      
        data.writeWord(UInt16(protocolTypes.count))
        for pt in protocolTypes {
              try pt.archive(data: data)
        }
      
        data.isRoot=root
    }
  
    public static func unarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i:ASTProtocolCompositionType=instance != nil ? instance as! ASTProtocolCompositionType : try ASTFromTag(data: data) as! ASTProtocolCompositionType
      
        let c=Int(data.readWord())
        for _ in 0..<c {
              i.protocolTypes.append(try ASTFromTag(data: data) as! ASTType)
        }
        
          return i
    }
  
    public func copy() -> AST {
        var a:[ASTType]=[]
        for pt in protocolTypes {
              a.append(pt.copy() as! ASTType)
        }
          return ASTProtocolCompositionType(protocolTypes: a)
    }
  
    public func replace(name: String, with: AST) -> AST {return self}
  
    public func runDeclarations(isTopLevel:Bool) {}
    
    public func generate(delegate: ASTDelegate) throws {try delegate.generateASTProtocolCompositionType(self)}

    public func exec() throws -> Value {runtimeNilValue}

    public func getType() -> ASTType {return VoidType} //??
}

public struct ASTGenericWhereClause: AST {
    public enum Requirement: AST {
        case typeConformance(ASTTypeIdentifier, ASTTypeIdentifier)
        case protocolConformance(ASTTypeIdentifier, ASTProtocolCompositionType)
        case sameType(ASTTypeIdentifier, ASTType)

        public init() {self = .typeConformance(ASTTypeIdentifier(),ASTTypeIdentifier())}

        public var next:AST? {get {return nil} set(newvalue) {}}
        public var previous:AST? {get {return nil} set(newvalue) {}}

        public func archive(data: SCLData) throws {
            if data.isRoot {data.writeWord(UInt16(ArchiveType.Requirement.rawValue))}
      
              let root=data.isRoot
            data.isRoot=true

            switch self {
                case .typeConformance(let id1, let id2):
                    data.writeWord(1)
                    try id1.archive(data: data)
                    try id2.archive(data: data)
                case .protocolConformance(let id, let ct):
                    data.writeWord(2)
                    try id.archive(data: data)
                    try ct.archive(data: data)
                case .sameType(let id, let t): 
                    data.writeWord(3)
                    try id.archive(data: data)
                    try t.archive(data: data)
            }
                  
            data.isRoot=root
        }
  
        public static func unarchive(data: SCLData, instance:AST?=nil) throws -> AST {
            var i:Requirement=instance != nil ? instance as! Requirement : try ASTFromTag(data: data) as! Requirement
             
            let k=data.readWord()
            if k==1 {
                  let id1=(try ASTFromTag(data: data) as! ASTTypeIdentifier)
                let id2=(try ASTFromTag(data: data) as! ASTTypeIdentifier)
                i = .typeConformance(id1,id2)
            }
            else if k==2 {
                  let id=(try ASTFromTag(data: data) as! ASTTypeIdentifier)
                let ct=(try ASTFromTag(data: data) as! ASTProtocolCompositionType)
                i = .protocolConformance(id,ct)
            }
            else if k==3 {
                  let id=(try ASTFromTag(data: data) as! ASTTypeIdentifier)
                let t=(try ASTFromTag(data: data) as! ASTType)
                i = .sameType(id,t)
            }

            return i
        }
  
        public func copy() -> AST {
            switch self {
                case .typeConformance(let id1, let id2):return Requirement.typeConformance(id1,id2)
                case .protocolConformance(let id, let ct):return Requirement.protocolConformance(id,ct)
                case .sameType(let id, let t): return Requirement.sameType(id,t)
            }
        }
        
        public func replace(name: String, with: AST) -> AST {return self}
        
        public func runDeclarations(isTopLevel:Bool) {}
        
        public func generate(delegate: ASTDelegate) throws {try delegate.generateASTGenericWhereClause_Requirement(self)}

        public func exec() throws -> Value {runtimeNilValue}

        public func getType() -> ASTType {return VoidType} //??
    }

    public var next:AST? {get {return nil} set(newvalue) {}}
    public var previous:AST? {get {return nil} set(newvalue) {}}

    public var requirementList: [Requirement]

    public init() {requirementList=[]}

    public init(requirementList: [Requirement]) {
        self.requirementList = requirementList
    }
      
    public func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.ASTGenericWhereClause.rawValue))}
      
          let root=data.isRoot
        data.isRoot=true
      
        data.writeWord(UInt16(requirementList.count))
        for req in requirementList {
            try req.archive(data: data)
        }
      
        data.isRoot=root
    }
  
    public static func unarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        var i:ASTGenericWhereClause=instance != nil ? instance as! ASTGenericWhereClause : try ASTFromTag(data: data) as! ASTGenericWhereClause
      
          let c=Int(data.readWord())
        for _ in 0..<c {
            i.requirementList.append(try ASTFromTag(data: data) as! Requirement)
        }
        
        return i
    }
  
    public func copy() -> AST {
        var a:[Requirement]=[]
        for req in requirementList {
            a.append(req.copy() as! Requirement)
        }
        return ASTGenericWhereClause(requirementList: a)
    }
  
    public func replace(name: String, with: AST) -> AST {return self}
  
    public func runDeclarations(isTopLevel:Bool) {}
    
    public func generate(delegate: ASTDelegate) throws {try delegate.generateASTGenericWhereClause(self)}

    public func exec() throws -> Value {runtimeNilValue}

    public func getType() throws -> ASTType {return VoidType}
}

public struct ASTTypeInheritanceClause:AST {
    public var classRequirement: Bool
    public var typeInheritanceList: [ASTTypeIdentifier]
    public var next:AST? {get {return nil} set(newvalue) {}}
    public var previous:AST? {get {return nil} set(newvalue) {}}
    
    public init() {classRequirement=false;typeInheritanceList=[]}

    public init(classRequirement: Bool = false, typeInheritanceList: [ASTTypeIdentifier] = []) {
        self.classRequirement = classRequirement
        self.typeInheritanceList = typeInheritanceList
    }

    public func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.ASTTypeInheritanceClause.rawValue))}
      
        let root=data.isRoot
        data.isRoot=true
      
        data.writeBool(classRequirement)
        data.writeWord(UInt16(typeInheritanceList.count))
        for t in typeInheritanceList {
            try t.archive(data: data)
        }
      
        data.isRoot=root
    }
  
    public static func unarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        var i:ASTTypeInheritanceClause=instance != nil ? instance as! ASTTypeInheritanceClause : try ASTFromTag(data: data) as! ASTTypeInheritanceClause
      
        i.classRequirement=data.readBool()
        let c=Int(data.readWord())
        for _ in 0..<c {
            i.typeInheritanceList.append(try ASTFromTag(data: data) as! ASTTypeIdentifier)
        }
        
        return i
    }
  
    public func copy() -> AST {
        var a:[ASTTypeIdentifier]=[]
        for t in typeInheritanceList {
            a.append(t.copy() as! ASTTypeIdentifier)
        }
        return ASTTypeInheritanceClause(classRequirement: classRequirement, typeInheritanceList:a)
    }
    
    public func replace(name: String, with: AST) -> AST {return self}
  
    public func runDeclarations(isTopLevel:Bool) {}
    
    public func generate(delegate: ASTDelegate) throws {try delegate.generateASTTypeInheritanceClause(self)}

    public func exec() throws -> Value {runtimeNilValue}

    public func getType() throws -> ASTType {return VoidType}
}

public class WillSetDidSetBlock: ASTBase {
    public struct WillSetClause {
        public let attributes: [Attribute]
        public let name: String?
        public let codeBlock: CodeBlock

        public init(attributes: [Attribute] = [], name: String? = nil, codeBlock: CodeBlock) {
            self.attributes = attributes
            self.name = name
            self.codeBlock = codeBlock
        }

        public func copy() -> WillSetClause {
            var a:[Attribute]=[]
            for aa in attributes {a.append(aa.copy())}
            return WillSetClause(attributes: a, name: name, codeBlock: codeBlock.copy() as! CodeBlock)
        }
    }

    public struct DidSetClause {
        public let attributes: [Attribute]
        public let name: String?
        public let codeBlock: CodeBlock

        public init(attributes: [Attribute] = [],  name: String? = nil, codeBlock: CodeBlock) {
            self.attributes = attributes
            self.name = name
            self.codeBlock = codeBlock
        }

        public func copy() -> DidSetClause {
            var a:[Attribute]=[]
            for aa in attributes {a.append(aa.copy())}
            return DidSetClause(attributes: a, name: name, codeBlock: codeBlock.copy() as! CodeBlock)
        }
    }

    public var willSetClause: WillSetClause?
    public var didSetClause: DidSetClause?

    public override init() {
        self.willSetClause = nil
        self.didSetClause = nil
        super.init()
    }

    public init(willSetClause: WillSetClause?, didSetClause: DidSetClause? = nil) {
        self.willSetClause = willSetClause
        self.didSetClause = didSetClause
        super.init()
    }

    public override func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.WillSetDidSetBlock.rawValue))}
      
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true
        
        if willSetClause != nil {
            data.writeBool(true)
            
            if willSetClause!.name != nil {
                data.writeBool(true)
                data.writeShortString(willSetClause!.name!)
            }
            else {data.writeBool(false)}
            archiveAttributes(data:data, willSetClause!.attributes)
            
            try willSetClause!.codeBlock.archive(data:data)
        }
        else {data.writeBool(false)}
        
        if didSetClause != nil {
            data.writeBool(true)
            
            if didSetClause!.name != nil {
                data.writeBool(true)
                data.writeShortString(didSetClause!.name!)
            }
            else {data.writeBool(false)}
            archiveAttributes(data:data, didSetClause!.attributes)
            
            try didSetClause!.codeBlock.archive(data:data)
        }
        else {data.writeBool(false)}
      
        data.isRoot=root
    }
  
    public static func WillSetDidSetBlockunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i:WillSetDidSetBlock=instance != nil ? instance as! WillSetDidSetBlock : try ASTFromTag(data: data) as! WillSetDidSetBlock
        
        _=try ASTBase.unarchive(data: data, instance: i)
        
        if data.readBool() 
        {
            var name:String?=nil
            if data.readBool() {name=data.readShortString()!}
            let a=unarchiveAttributes(data:data)
            let block=(try ASTFromTag(data: data) as! CodeBlock)

            i.willSetClause=WillSetClause(attributes: a, name: name, codeBlock: block)
        }

        if data.readBool() {
            var name:String?=nil
            if data.readBool() {name=data.readShortString()!}
            let a=unarchiveAttributes(data:data)
            let block=(try ASTFromTag(data: data) as! CodeBlock)
            
            i.didSetClause=DidSetClause(attributes: a, name: name, codeBlock: block)
        }
        
        return i
    }
    
    public override func copy() -> AST {
        return WillSetDidSetBlock(willSetClause: willSetClause?.copy(), didSetClause: didSetClause?.copy())
    }
    
    public override func replace(name: String, with: AST) -> AST {return self}

    public override func getType() throws -> ASTType {return VoidType}
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateWillSetDidSetBlock(self)}
}

public class GetterSetterKeywordBlock: ASTBase {
    public struct GetterKeywordClause {
        public var attributes: [Attribute]
        public var mutationModifier: Modifier?
        public var name:String?
        public var block:CodeBlock?
        public var mangledName:String?=nil

        public init(name: String?, block:CodeBlock?, attributes: [Attribute] = [], mutationModifier: Modifier? = nil) {
          self.name = name
          self.attributes = attributes
          self.mutationModifier = mutationModifier
        }
        
        public func copy() -> GetterKeywordClause {
            var a:[Attribute]=[]
            for aa in attributes {a.append(aa.copy())}
            return GetterKeywordClause(name: name, block: block?.copy() as? CodeBlock, attributes: a, mutationModifier: mutationModifier)
        }
    }

    public struct SetterKeywordClause {
        public let attributes: [Attribute]
        public let mutationModifier: Modifier?
        public var name:String?
        public var block:CodeBlock?
        public var mangledName:String?=nil

        public init(name: String?, block:CodeBlock?, attributes: [Attribute] = [], mutationModifier: Modifier? = nil) {
              self.name = name
              self.attributes = attributes
              self.mutationModifier = mutationModifier
        }
        
        public func copy() -> SetterKeywordClause {
            var a:[Attribute]=[]
            for aa in attributes {a.append(aa.copy())}
            return SetterKeywordClause(name: name, block: block?.copy() as? CodeBlock, attributes: a, mutationModifier: mutationModifier)
        }
    }

    public var getter: GetterKeywordClause
    public var setter: SetterKeywordClause?
    
    public override init() {
        getter=GetterKeywordClause(name: nil, block:nil)
        setter=nil
        super.init()
    }

    public init(getter: GetterKeywordClause, setter: SetterKeywordClause? = nil) {
        self.getter = getter
        self.setter = setter
        super.init()
    }
  
    public override func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.GetterSetterKeywordBlock.rawValue))}
      
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true
        
        if getter.name != nil {
            data.writeBool(true)
            data.writeShortString(getter.name!)
        }
        else {data.writeBool(false)}
        archiveAttributes(data:data, getter.attributes)
        if getter.block != nil {
            data.writeBool(true)
            try getter.block!.archive(data:data)
        }
        else {data.writeBool(false)}
        if getter.mutationModifier != nil {
            data.writeBool(true)
            data.writeWord(UInt16(getter.mutationModifier!.rawValue))
        }
        else {data.writeBool(false)}
        if getter.mangledName != nil {
            data.writeBool(true)
            data.writeString(getter.mangledName!)
        }
        else {data.writeBool(false)}
        
        if setter != nil {
            data.writeBool(true)
            if setter!.name != nil {
                data.writeBool(true)
                data.writeShortString(setter!.name!)
            }
            else {data.writeBool(false)}
            archiveAttributes(data:data, setter!.attributes)
            if setter!.block != nil {
                data.writeBool(true)
                try setter!.block!.archive(data:data)
            }
            else {data.writeBool(false)}
            if setter!.mutationModifier != nil {
                data.writeBool(true)
                data.writeWord(UInt16(setter!.mutationModifier!.rawValue))
            }
            else {data.writeBool(false)}
            if setter!.mangledName != nil {
                data.writeBool(true)
                data.writeString(setter!.mangledName!)
            }
            else {data.writeBool(false)}
        }
        else {data.writeBool(false)}
      
        data.isRoot=root
    }
  
    public static func GetterSetterKeywordBlockunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i:GetterSetterKeywordBlock=instance != nil ? instance as! GetterSetterKeywordBlock : try ASTFromTag(data: data) as! GetterSetterKeywordBlock
        
        _=try ASTBase.unarchive(data: data, instance: i)
        
        if data.readBool() {i.getter.name=data.readShortString()!}
        i.getter.attributes=unarchiveAttributes(data:data)
        if data.readBool() {
            i.getter.block=(try ASTFromTag(data: data) as! CodeBlock)
        }
        if data.readBool() {i.getter.mutationModifier=Modifier(rawValue:Int(data.readWord()))}
        if data.readBool() {i.getter.mangledName=data.readString()!}
        
        if data.readBool() {
            var name:String?=nil
            if data.readBool() {name=data.readShortString()!}
            let a=unarchiveAttributes(data:data)
            var block:CodeBlock?=nil
            if data.readBool() {
                block=(try ASTFromTag(data: data) as! CodeBlock)
            }
            var m:Modifier?=nil
            if data.readBool() {
                m=Modifier(rawValue:Int(data.readWord()))
            }
            i.setter=SetterKeywordClause(name: name, block: block, attributes: a, mutationModifier: m)
            if data.readBool() {i.setter!.mangledName=data.readString()!}
        }
        
        return i
    }
    
    public override func copy() -> AST {
        return GetterSetterKeywordBlock(getter: getter.copy(), setter: setter?.copy())
    }
    
    public override func replace(name: String, with: AST) -> AST {return self}

    public override func getType() throws -> ASTType {return VoidType}
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateGetterSetterKeywordBlock(self)}
}

public class PropertyMember: VariableDeclaration {
    public var name: String
    //public var typeAnnotation: ASTTypeAnnotation
    public var getterSetterKeywordBlock: GetterSetterKeywordBlock?
    //public var isConstant: Bool
    //public var initializer: AST?
    public var context:Scope?=nil //runtime only
    
    public override init() {
        self.name=""
        //self.typeAnnotation=ASTTypeAnnotation()
        self.getterSetterKeywordBlock=nil
        //self.isConstant=false
        //self.initializer=nil
        super.init()
    }
    
    public init(name: String, typeAnnotation: ASTTypeAnnotation, isConstant: Bool, initializer: AST?, location: SourceLocatable, 
                getterSetterKeywordBlock: GetterSetterKeywordBlock?, attributes: [Attribute], modifiers: [Modifier]) {
        self.name=name
        //self.typeAnnotation=typeAnnotation
        self.getterSetterKeywordBlock=getterSetterKeywordBlock
        //self.isConstant=isConstant
        //self.initializer=initializer
        //super.init(location: location)
        let v=Variable(name: name,typeAnnotation: typeAnnotation, isConstant: isConstant, attributes: attributes, modifiers: modifiers, 
                       location: location, getterSetterKeywordBlock:getterSetterKeywordBlock)
        super.init(variable: v, typeAnnotation: typeAnnotation, isConstant: isConstant, initializer: initializer, 
                   attributes: attributes, modifiers: modifiers, location: location)
        //self.attributes=attributes
        //self.modifiers=modifiers
    }
    
    public override func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.PropertyMember.rawValue))}
      
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true
        
        data.writeShortString(name)
        //try typeAnnotation.archive(data: data)
        if getterSetterKeywordBlock != nil {
            data.writeBool(true)
            try getterSetterKeywordBlock!.archive(data: data)
        }
        else {data.writeBool(false)}
        /*data.writeBool(isConstant)
        if initializer != nil {
            data.writeBool(true)
            try initializer!.archive(data: data)
        }
        else {data.writeBool(false)}*/
        
        data.isRoot=root
    }

    public static func PropertyMemberunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i:PropertyMember=instance != nil ? instance as! PropertyMember : try ASTFromTag(data: data) as! PropertyMember
        
        _=try VariableDeclaration.VariableDeclarationunarchive(data: data, instance: i)
        
        i.name=data.readShortString()!
        //i.typeAnnotation=(try ASTFromTag(data: data) as! ASTTypeAnnotation)
        if data.readBool() {
            i.getterSetterKeywordBlock=(try ASTFromTag(data: data) as! GetterSetterKeywordBlock)
        }
        /*i.isConstant=data.readBool()
        if data.readBool() {
            i.initializer=try ASTFromTag(data: data)
        }*/
        
        return i
    }
    
    public override func copy() -> AST {
        var a:[Attribute]=[]
        for aa in attributes {a.append(aa.copy())}
        var m:[Modifier]=[]
        for mm in modifiers {m.append(mm)}
        
        return PropertyMember(name: name, typeAnnotation: typeAnnotation.copy() as! ASTTypeAnnotation, isConstant: isConstant, initializer: initializer,
                              location: location, getterSetterKeywordBlock: getterSetterKeywordBlock?.copy() as? GetterSetterKeywordBlock, 
                              attributes: a, modifiers: m)
    }
    
    public override func replace(name: String, with: AST) -> AST {return self}
    
    public override func runDeclarations(isTopLevel:Bool) throws {}
    
    public override func exec() throws -> Value {runtimeNilValue}
}

public struct FunctionResult:AST {
    public var attributes: [Attribute]
    public var type: ASTType
    public var next:AST? {get {return nil} set(newvalue) {}}
    public var previous:AST? {get {return nil} set(newvalue) {}}

    public init(attributes: [Attribute] = [], type: ASTType) {
        self.attributes = attributes
        self.type = type
    }
    
    public init() {
        attributes=[]
        type=ASTType()
    }
    
    public func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.FunctionResult.rawValue))}
      
        let root=data.isRoot
        data.isRoot=true
        
        archiveAttributes(data: data, attributes)
        try type.archive(data:data)
        
        data.isRoot=root
    }

    public static func unarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        var i:FunctionResult=instance != nil ? instance as! FunctionResult : try ASTFromTag(data: data) as! FunctionResult
        
        i.attributes=unarchiveAttributes(data: data)
        i.type=(try ASTFromTag(data: data) as! ASTType)
        
        return i
    }
    
    public func copy() -> AST {
        var a:[Attribute]=[]
        for aa in attributes {a.append(aa.copy())}
        
        return FunctionResult(attributes: a, type: type.copy() as! ASTType)
    }
    
    public func replace(name: String, with: AST) -> AST {return self}
    
    public func runDeclarations(isTopLevel:Bool) throws {}
    
    public func generate(delegate: ASTDelegate) throws {try delegate.generateFunctionResult(self)}
    
    public func exec() throws -> Value {runtimeNilValue}

    public func getType() throws -> ASTType {return type}
    
}

public enum ThrowsKind: Int {
    case nothrowing=0
    case throwing
    case rethrowing
}

public struct FunctionSignature:AST {
    public struct Parameter {
        public var externalName: String?
        public var localName: String
        public var typeAnnotation: ASTTypeAnnotation
        public var defaultArgumentClause: AST?
        public var isVarargs: Bool
        public var variable: Variable
    
        public init() {
            externalName=nil
            localName=""
            typeAnnotation=ASTTypeAnnotation()
            defaultArgumentClause=nil
            isVarargs=false
            variable=Variable()
            self.variable.pdecl=self
        }

        public init(externalName: String? = nil, localName: String, typeAnnotation: ASTTypeAnnotation) {
            self.externalName = externalName
            self.localName = localName
            self.typeAnnotation = typeAnnotation
            self.defaultArgumentClause = nil
            self.isVarargs = false
            self.variable=Variable(name: localName,typeAnnotation: typeAnnotation, isConstant: false, attributes: [], 
                                   modifiers: [], location: ASTLocation())
            self.variable.pdecl=self
            self.variable.isCell=typeAnnotation.isInOutParameter
        }

        public init(externalName: String? = nil, localName: String, typeAnnotation: ASTTypeAnnotation, isVarargs: Bool = false) {
            self.externalName = externalName
            self.localName = localName
            self.typeAnnotation = typeAnnotation
            self.defaultArgumentClause = nil
            self.isVarargs = isVarargs
            self.variable=Variable(name: localName,typeAnnotation: typeAnnotation, isConstant: false, attributes: [], 
                                   modifiers: [], location: ASTLocation())
            self.variable.pdecl=self
            self.variable.isCell=typeAnnotation.isInOutParameter
        }

        public init(externalName: String? = nil, localName: String, typeAnnotation: ASTTypeAnnotation, defaultArgumentClause: AST? = nil) {
            self.externalName = externalName
            self.localName = localName
            self.typeAnnotation = typeAnnotation
            self.defaultArgumentClause = defaultArgumentClause
            self.isVarargs = false
            self.variable=Variable(name: localName,typeAnnotation: typeAnnotation, isConstant: false, attributes: [], 
                                   modifiers: [], location: ASTLocation())
            self.variable.pdecl=self
            self.variable.isCell=typeAnnotation.isInOutParameter
        }
        
        func archive(data: SCLData) throws {
            if externalName != nil {
                data.writeBool(true)
                data.writeShortString(externalName!)
            }
            else {data.writeBool(false)}
            
            data.writeShortString(localName)
            try typeAnnotation.archive(data: data)
            
            if defaultArgumentClause != nil {
                data.writeBool(true)
                try defaultArgumentClause!.archive(data: data)
            }
            else {data.writeBool(false)}
            
            data.writeBool(isVarargs)
        }
        
        public static func unarchive(data: SCLData) throws -> Parameter {
            var externalName:String?=nil
            if data.readBool() {externalName=data.readShortString()!}
            
            let localName=data.readShortString()!
            let ta:ASTTypeAnnotation=(try ASTFromTag(data: data) as! ASTTypeAnnotation)
            
            var defaultArgumentClause:AST?=nil
            if data.readBool() {
                defaultArgumentClause=try ASTFromTag(data: data)
            }
            let isVarargs=data.readBool()
            
            var p=Parameter(externalName: externalName, localName: localName, typeAnnotation: ta, defaultArgumentClause: defaultArgumentClause)
            p.isVarargs=isVarargs
            
            return p
        }
        
        public func copy() -> Parameter {
            var p=Parameter(externalName: externalName, localName: localName, typeAnnotation: typeAnnotation.copy() as! ASTTypeAnnotation, 
                            defaultArgumentClause: defaultArgumentClause?.copy())
            p.isVarargs=isVarargs
            return p
        }
    }

    public var parameterList: [Parameter]
    public var throwsKind: ThrowsKind
    public var result: FunctionResult?
    public var next:AST? {get {return nil} set(newvalue) {}}
    public var previous:AST? {get {return nil} set(newvalue) {}}
  
    public init() {
        parameterList=[]
        throwsKind = .nothrowing
        result=nil
    }

    public init(parameterList: [Parameter] = [], throwsKind: ThrowsKind = .nothrowing, result: FunctionResult? = nil) {
        self.parameterList = parameterList
        self.throwsKind = throwsKind
        self.result = result
    }
    
    public func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.FunctionSignature.rawValue))}
      
        let root=data.isRoot
        data.isRoot=true
        
        data.writeWord(UInt16(parameterList.count))
        for p in parameterList {
            try p.archive(data: data)
        }
        data.writeWord(UInt16(throwsKind.rawValue))
        if result != nil {
            data.writeBool(true)
            try result!.archive(data: data)
        }
        else {data.writeBool(false)}
        
        data.isRoot=root
    }

    public static func unarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        var i:FunctionSignature=instance != nil ? instance as! FunctionSignature : try ASTFromTag(data: data) as! FunctionSignature
        
        let c=Int(data.readWord())
        for _ in 0..<c {
            let p=try Parameter.unarchive(data:data)
            i.parameterList.append(p)
        }
        i.throwsKind=ThrowsKind(rawValue: Int(data.readWord()))!
        if data.readBool() {i.result=(try ASTFromTag(data: data) as! FunctionResult)}
        
        return i
    }
    
    public func copy() -> AST {
        var pl:[Parameter]=[]
        for p in parameterList {pl.append(p.copy())}
        
        return FunctionSignature(parameterList: pl, throwsKind: throwsKind, result: result?.copy() as? FunctionResult)
    }
    
    public func replace(name: String, with: AST) -> AST {return self}
    
    public func runDeclarations(isTopLevel:Bool) throws {}
    
    public func generate(delegate: ASTDelegate) throws {try delegate.generateFunctionSignature(self)}
    
    public func exec() throws -> Value {runtimeNilValue}

    public func getType() throws -> ASTType {return (try result?.getType()) ?? VoidType}
}

public class MethodMember: FunctionDeclaration {
    
    public override init() {
        super.init()
    }

    public init(name: String, body: CodeBlock?, location: SourceLocatable, attributes: [Attribute] = [], modifiers: [Modifier] = [], 
                genericParameter: ASTGenericParameterClause? = nil, signature: FunctionSignature, genericWhere: ASTGenericWhereClause? = nil) {
        super.init(name: name, body: body, location: location, attributes: attributes, modifiers: modifiers, 
                   genericParameterClause: genericParameter, signature: signature, genericWhereClause: genericWhere)
    }
    
    public override func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.MethodMember.rawValue))}
      
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true
        
        data.isRoot=root
    }

    public static func MethodMemberunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i:MethodMember=instance != nil ? instance as! MethodMember : try ASTFromTag(data: data) as! MethodMember
    
        _=try FunctionDeclaration.FunctionDeclarationunarchive(data: data, instance: i)
        
        return i
    }
    
    public override func copy() -> AST {
        var a:[Attribute]=[]
        for aa in attributes {a.append(aa.copy())}
        var m:[Modifier]=[]
        for mm in modifiers {m.append(mm)}
        
        return MethodMember(name: name, body: body?.copy() as? CodeBlock, location: location, attributes: a, modifiers: m, 
                            genericParameter: genericParameterClause?.copy() as? ASTGenericParameterClause, signature: signature.copy() as! FunctionSignature, 
                            genericWhere: genericWhereClause?.copy() as? ASTGenericWhereClause)
    }
    
    public override func replace(name: String, with: AST) -> AST {return self}
    
    public override func runDeclarations(isTopLevel:Bool) throws {}
    
    public override func exec() throws -> Value {
        return try body?.exec() ?? runtimeNilValue
    }
}

public class InitializerDeclaration : FunctionDeclaration {
    public enum InitKind: Int {
        case nonfailable=0
        case optionalFailable
        case implicitlyUnwrappedFailable
    }

    public var kind: InitKind
    public var type: ASTType?=nil //Class Type
    
    public override init() {
        self.kind = .nonfailable
        super.init()
    }

    public init(
        body: CodeBlock?,
        location: SourceLocatable,
        attributes: [Attribute] = [], modifiers: [Modifier] = [],
        kind: InitKind = .nonfailable,
        genericParameterClause: ASTGenericParameterClause? = nil,
        parameterList: [FunctionSignature.Parameter] = [],
        throwsKind: ThrowsKind = .nothrowing,
        genericWhereClause: ASTGenericWhereClause? = nil
    ) {
        self.kind = kind
        let signature=FunctionSignature(parameterList: parameterList, throwsKind: throwsKind, result: nil)
        super.init(name: "init", body: body, location: location, attributes: attributes, modifiers: modifiers,
                   genericParameterClause: genericParameterClause, signature: signature, genericWhereClause: genericWhereClause) 
    }
    
    public override func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.InitializerDeclaration.rawValue))}
      
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true
        
        data.writeWord(UInt16(kind.rawValue))
        
        data.isRoot=root
    }

    public static func InitializerDeclarationunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i:InitializerDeclaration=instance != nil ? instance as! InitializerDeclaration : try ASTFromTag(data: data) as! InitializerDeclaration
    
        _=try FunctionDeclaration.FunctionDeclarationunarchive(data: data, instance: i)
        
        i.kind=InitKind(rawValue:Int(data.readWord()))!

        return i
    }
    
    public override func copy() -> AST {
        var a:[Attribute]=[]
        for aa in attributes {a.append(aa.copy())}
        var m:[Modifier]=[]
        for mm in modifiers {m.append(mm)}
        var pl:[FunctionSignature.Parameter]=[]
        for p in signature.parameterList {pl.append(p.copy())}
        
        let i = InitializerDeclaration(body: body?.copy() as? CodeBlock, location: location, attributes: a, modifiers: m, kind: kind,
                                      genericParameterClause: genericParameterClause?.copy() as? ASTGenericParameterClause, 
                                      parameterList: pl, throwsKind: signature.throwsKind,
                                      genericWhereClause: genericWhereClause?.copy() as? ASTGenericWhereClause)
        i.type=type?.copy() as? ASTType
        return i
    }
    
    public override func replace(name: String, with: AST) -> AST {return self}
    
    public override func runDeclarations(isTopLevel:Bool) throws {}
    
    public override func exec() throws -> Value {runtimeNilValue}

    public override func getType() throws -> ASTType {return type ?? VoidType}
}

public class InitializerMember: InitializerDeclaration {
    
    public override init() {
        super.init()
    }

    public init(
      body: CodeBlock?,
      location: SourceLocatable,
      attributes: [Attribute] = [],
      modifiers: [Modifier] = [],
      kind: InitializerDeclaration.InitKind = .nonfailable,
      genericParameter: ASTGenericParameterClause?,
      parameterList: [FunctionSignature.Parameter],
      throwsKind: ThrowsKind = .nothrowing,
      genericWhere: ASTGenericWhereClause? 
    ) {
        super.init(body: body, location: location, attributes: attributes, modifiers: modifiers, 
                   genericParameterClause: genericParameter, genericWhereClause: genericWhere)
    }
    
    public override func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.InitializerMember.rawValue))}
      
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true
        
        data.isRoot=root
    }

    public static func InitializerMemberunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i:InitializerMember=instance != nil ? instance as! InitializerMember : try ASTFromTag(data: data) as! InitializerMember
    
        _=try InitializerDeclaration.InitializerDeclarationunarchive(data: data, instance: i)
        
        return i
    }
    
    public override func copy() -> AST {
        var a:[Attribute]=[]
        for aa in attributes {a.append(aa.copy())}
        var m:[Modifier]=[]
        for mm in modifiers {m.append(mm)}
        var pl:[FunctionSignature.Parameter]=[]
        for p in signature.parameterList {pl.append(p.copy())}
        
        return InitializerMember(body: body?.copy() as? CodeBlock, location: location, attributes: a, modifiers: m, kind: kind, 
                                 genericParameter: genericParameterClause?.copy() as? ASTGenericParameterClause,
                                 parameterList: pl, throwsKind: signature.throwsKind, genericWhere: genericWhereClause?.copy() as? ASTGenericWhereClause)
    }
    
    public override func replace(name: String, with: AST) -> AST {return self}
    
    public override func runDeclarations(isTopLevel:Bool) throws {}
    
    public override func exec() throws -> Value {runtimeNilValue}

    public override func getType() throws -> ASTType {return VoidType}
}

public class SubscriptMember: ASTBase {
    public var genericParameter: ASTGenericParameterClause?
    public var parameterList: [FunctionSignature.Parameter]
    public var resultAttributes: [Attribute]
    public var resultType: ASTType
    public var genericWhere: ASTGenericWhereClause?
    public var getterSetterKeywordBlock: GetterSetterKeywordBlock
    public var context:Scope?=nil //runtime only

    public override init() {
        self.genericParameter = nil
        self.parameterList = []
        self.resultAttributes = []
        self.resultType = ASTType()
        self.genericWhere = nil
        self.getterSetterKeywordBlock = GetterSetterKeywordBlock()
        super.init()
    }

    public init(
      resultType: ASTType,
      location: SourceLocatable,
      attributes: [Attribute] = [],
      modifiers: [Modifier] = [],
      genericParameter: ASTGenericParameterClause? = nil,
      parameterList: [FunctionSignature.Parameter] = [],
      resultAttributes: [Attribute] = [],
      genericWhere: ASTGenericWhereClause? = nil,
      getterSetterKeywordBlock: GetterSetterKeywordBlock
    ) {
      self.genericParameter = genericParameter
      self.parameterList = parameterList
      self.resultAttributes = resultAttributes
      self.resultType = resultType
      self.genericWhere = genericWhere
      self.getterSetterKeywordBlock = getterSetterKeywordBlock
      super.init(location: location)
      self.attributes = attributes
      self.modifiers = modifiers
    }

    public override func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.SubscriptMember.rawValue))}
      
        let root=data.isRoot
        try super.archive(data: data)
        data.isRoot=true
        
        if genericParameter != nil {
            data.writeBool(true)
            try genericParameter!.archive(data: data)
        }
        else {data.writeBool(false)}
        
        data.writeWord(UInt16(parameterList.count))
        for p in parameterList {try p.archive(data: data)}
        
        archiveAttributes(data: data, resultAttributes)
        
        try resultType.archive(data: data)
        
        if genericWhere != nil {
            data.writeBool(true)
            try genericWhere!.archive(data: data)
        }
        else {data.writeBool(false)}
        
        try getterSetterKeywordBlock.archive(data: data)
        
        data.isRoot=root
    }

    public static func SubscriptMemberunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i:SubscriptMember=instance != nil ? instance as! SubscriptMember : try ASTFromTag(data: data) as! SubscriptMember
    
        _=try ASTBase.unarchive(data: data, instance: i)
        
        if data.readBool() {
            i.genericParameter=(try ASTFromTag(data: data) as! ASTGenericParameterClause)
        }
        
        let c=Int(data.readWord())
        for _ in 0..<c {
            i.parameterList.append(try FunctionSignature.Parameter.unarchive(data: data))
        }
        
        i.resultAttributes=unarchiveAttributes(data: data)
        
        i.resultType=try ASTFromTag(data: data) as! ASTType
        
        if data.readBool() {
            i.genericWhere=(try ASTFromTag(data: data) as! ASTGenericWhereClause)
        }
        
        i.getterSetterKeywordBlock=try ASTFromTag(data: data) as! GetterSetterKeywordBlock
        
        return i
    }
    
    public override func copy() -> AST {
        var a:[Attribute]=[]
        for aa in attributes {a.append(aa.copy())}
        var m:[Modifier]=[]
        for mm in modifiers {m.append(mm)}
        var a1:[Attribute]=[]
        for aa in resultAttributes {a1.append(aa.copy())}
        var pl: [FunctionSignature.Parameter] = []
        for p in parameterList {pl.append(p.copy())}
        
        return SubscriptMember(resultType: resultType.copy() as! ASTType, location: location, attributes: a, modifiers: m,
                               genericParameter: genericParameter?.copy() as? ASTGenericParameterClause, parameterList: pl, resultAttributes: a1,
                               genericWhere: genericWhere?.copy() as? ASTGenericWhereClause, 
                               getterSetterKeywordBlock: getterSetterKeywordBlock.copy() as! GetterSetterKeywordBlock)
    }
    
    public override func replace(name: String, with: AST) -> AST {return self}
    
    public override func runDeclarations(isTopLevel:Bool) throws {}
    
    public override func exec() throws -> Value {runtimeNilValue}

    public override func getType() -> ASTType {return resultType}
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateSubscriptMember(self)}
}

public class AssociativityTypeMember: ASTBase {
    public var name: String
    public var typeInheritance: ASTTypeInheritanceClause?
    public var assignmentType: ASTType?
    public var genericWhere: ASTGenericWhereClause?
    public var context:Scope?=nil //runtime only
    
    public override init() {
        self.name = ""
        self.typeInheritance = nil
        self.assignmentType = nil
        self.genericWhere = nil
        super.init()
    }

    public init(
      name: String,
      location: SourceLocatable,
      attributes: [Attribute] = [],
      accessLevelModifier: Modifier? = nil,
      typeInheritance: ASTTypeInheritanceClause? = nil,
      assignmentType: ASTType? = nil,
      genericWhere: ASTGenericWhereClause? = nil
    ) {
      self.name = name
      self.typeInheritance = typeInheritance
      self.assignmentType = assignmentType
      self.genericWhere = genericWhere
      super.init(location: location)
      self.attributes = attributes
      if accessLevelModifier != nil {self.modifiers = [accessLevelModifier!]}
    }
    
    public override func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.AssociativityTypeMember.rawValue))}
      
        let root=data.isRoot
        try super.archive(data: data)
        data.isRoot=true
        
        data.writeShortString(name)
        
        if typeInheritance != nil {
            data.writeBool(true)
            try typeInheritance!.archive(data: data)
        }
        else {data.writeBool(false)}
        
        if assignmentType != nil {
            data.writeBool(true)
            try assignmentType!.archive(data: data)
        }
        else {data.writeBool(false)}
        
        if genericWhere != nil {
            data.writeBool(true)
            try genericWhere!.archive(data: data)
        }
        else {data.writeBool(false)}
        
        data.isRoot=root
    }

    public static func AssociativityTypeMemberunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i:AssociativityTypeMember=instance != nil ? instance as! AssociativityTypeMember : try ASTFromTag(data: data) as! AssociativityTypeMember
    
        _=try ASTBase.unarchive(data: data, instance: i)
        
        if data.readBool() {
            i.typeInheritance=try ASTFromTag(data: data) as? ASTTypeInheritanceClause
        }
        
        if data.readBool() {
            i.assignmentType=try ASTFromTag(data: data) as? ASTType
        }
        
        if data.readBool() {
            i.genericWhere=try ASTFromTag(data: data) as? ASTGenericWhereClause
        }
        
        return i
    }
    
    public override func copy() -> AST {
        var a:[Attribute]=[]
        for aa in attributes {a.append(aa.copy())}
        var accessLevelModifier:Modifier?=nil
        if modifiers.count>0 {accessLevelModifier=modifiers[0]}
        
        return AssociativityTypeMember(name: name, location: location, attributes: a, accessLevelModifier: accessLevelModifier,
                                       typeInheritance: typeInheritance?.copy() as? ASTTypeInheritanceClause, 
                                       assignmentType: assignmentType?.copy() as? ASTType, genericWhere: genericWhere?.copy() as? ASTGenericWhereClause)
    }
    
    public override func replace(name: String, with: AST) -> AST {return self}
    
    public override func runDeclarations(isTopLevel:Bool) throws {}
    
    public override func exec() throws -> Value {runtimeNilValue}

    public override func getType() throws -> ASTType {return assignmentType ?? VoidType}
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateAssociativityTypeMember(self)}
}

public enum Member: AST {
    case general(AST)
    case property(PropertyMember)
    case method(MethodMember)
    case initializer(InitializerMember)
    case `subscript`(SubscriptMember)
    case associatedType(AssociativityTypeMember)
    //case compilerControl(CompilerControlStatement)
    
    public var next:AST? {get {return nil} set(newvalue) {}}
    public var previous:AST? {get {return nil} set(newvalue) {}}
        
    public init() {self = .general(NoOp())}
    
    public func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.Member.rawValue))}
      
        let root=data.isRoot
        data.isRoot=true
        
        switch self {
            case .general(let a):
                data.writeWord(0)
                try a.archive(data: data)
            case .property(let pm):
                data.writeWord(1)
                try pm.archive(data: data)
            case .method(let mm):
                data.writeWord(2)
                try mm.archive(data: data)
            case .initializer(let im):
                data.writeWord(3)
                try im.archive(data: data)
            case .`subscript`(let sm):
                data.writeWord(4)
                try sm.archive(data: data)
            case .associatedType(let am):
                data.writeWord(5)
                try am.archive(data: data)
            //case .compilerControl(CompilerControlStatement)
        }
    
        data.isRoot=root
    }
  
    public static func unarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        var i:Member=instance != nil ? instance as! Member : try ASTFromTag(data: data) as! Member
        
        let k=data.readWord()
        if k==1 {
            i = .property((try ASTFromTag(data: data)) as! PropertyMember)
        }
        else if k==2 {
            i = .method((try ASTFromTag(data: data)) as! MethodMember)
        }
        else if k==3 {
            i = .initializer((try ASTFromTag(data: data)) as! InitializerMember)
        }
        else if k==4 {
            i = .`subscript`((try ASTFromTag(data: data)) as! SubscriptMember)
        }
        else if k==5 {
            i = .associatedType((try ASTFromTag(data: data)) as! AssociativityTypeMember)
        }
        else {
            i = .general(try ASTFromTag(data: data))
        }
        
        return i
    }
    
    public func copy() -> AST {
        switch self {
            case .general(let decl):
                return Member.general(decl.copy()) 
            case .property(let pm):
                return Member.property(pm.copy() as! PropertyMember) 
            case .method(let mm):
                return Member.method(mm.copy() as! MethodMember) 
            case .initializer(let im):
                return Member.initializer(im.copy() as! InitializerMember) 
            case .`subscript`(let sm):
                return Member.subscript(sm.copy() as! SubscriptMember) 
            case .associatedType(let am):
                return Member.associatedType(am.copy() as! AssociativityTypeMember) 
        }
    }
    
    public func replace(name: String, with: AST) -> AST {return self}
    
    public func runDeclarations(isTopLevel:Bool) throws {
        switch self {
            case .general(let decl):
                try decl.runDeclarations(isTopLevel: isTopLevel)
            case .property(let pm):
                try pm.runDeclarations(isTopLevel: isTopLevel)
            case .method(let mm):
                try mm.runDeclarations(isTopLevel: isTopLevel)
            case .initializer(let im):
                try im.runDeclarations(isTopLevel: isTopLevel)
            case .`subscript`(let sm):
                try sm.runDeclarations(isTopLevel: isTopLevel)
            case .associatedType(let am):
                try am.runDeclarations(isTopLevel: isTopLevel)
        }
    }
    
    public func generate(delegate: ASTDelegate) throws {try delegate.generateMember(self)}

    public func exec() throws -> Value {runtimeNilValue}

    public func getType() throws -> ASTType {
        switch self {
            case .general(let ast):
                return try ast.getType()
            case .property(let pm):
                return pm.getType()
            case .method(let mm):
                return try mm.getType()
            case .initializer(let im):
                return try im.getType()
            case .`subscript`(let sm):
                return sm.getType()
            case .associatedType(let am):
                return try am.getType()
        }
    }
}


public class ClassDeclaration: Scope, Declaration {
    public var impl: ClassType
    
    public override init() {
        impl=ClassType()
        super.init()
        self.origin=self
    }
    
    public init(name:String, members: [Member], location: SourceLocatable, isFinal:Bool, attributes: [Attribute], accessLevelModifier: Modifier?, 
                typeInheritanceClause: ASTTypeInheritanceClause?, generic: ASTGenericParameterClause?, genericWhere: ASTGenericWhereClause? ) {
        self.impl=ClassType(name: name, members: members, location: location, isFinal:isFinal, attributes: attributes, accessLevelModifier: accessLevelModifier,  
                            typeInheritanceClause: typeInheritanceClause, generic: generic, genericWhere: genericWhere)
                            
        super.init(parent:ASTModule.current.currentScope,location:location)
        
        self.impl.decl=self
        self.context=ASTModule.current
        self.origin=self
        self.attributes=attributes
        if accessLevelModifier != nil {self.modifiers=[accessLevelModifier!]}
        
        //create scope entries for members
        for m in self.impl.members {
            //print("declare class member:",m)
            switch m {
                case .property(let pm):
                    try? self.declareVar(variable: pm.variable)
                case .method(let mm):
                    //print("declare class func:",mm.name)
                    try? self.declareFunc(function: mm)
                case .initializer(let im):
                    //print("declare class initializer:",im.name)
                    try? self.declareFunc(function: im)
                case .`subscript`(_/*let sm*/):
                    _=1 //todo?
                case .associatedType(_/*let am*/):
                    _=1 //todo
                case .general(_/*let ast*/):
                    _=1
            }
        }
        
        try! ASTModule.current.declareType(type: impl)
        needsDecl=false
    }
    
    public override func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.ClassDeclaration.rawValue))}
        
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true

        try impl.archive(data: data)

        data.isRoot=root
    }
    
    public static func ClassDeclarationunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i=instance != nil ? instance as! ClassDeclaration : try ASTFromTag(data: data) as! ClassDeclaration
        
        try _=Scope.Scopeunarchive(data: data, instance: i)
        
        i.impl=(try ASTFromTag(data: data) as! ClassType)
        i.impl.decl=i

        //also set context member of declaration and impl
        i.context=ASTModule.current.currentScope
        i.impl.context=i.context
        
        //restore scope declarations
        for m in i.impl.members {
            //print("declare class member:",m)
            switch m {
                case .property(let pm):
                    try i.declareVar(variable: pm.variable)
                case .method(let mm):
                    //print("declare class func:",mm.name)
                    try i.declareFunc(function: mm)
                case .initializer(let im):
                    //print("declare class initializer:",im.name)
                    try i.declareFunc(function: im)
                case .`subscript`(_/*let sm*/):
                    _=1 //todo?
                case .associatedType(_/*let am*/):
                    _=1 //todo
                case .general(_/*let ast*/):
                    _=1
            }
        }
        //todo restore types in scope, these are not stored within members

        return i
    }
    
    public override func copy() -> AST {
        let cd=ClassDeclaration()
        cd.attributes=attributes
        cd.modifiers=modifiers
        cd.location=location
        cd.impl=impl.copy() as! ClassType
        cd.impl.decl=cd
        
        return cd
    }
    
    public override func replace(name: String, with: AST) -> AST {
        //todo
        return self
    }

    public override func runDeclarations(isTopLevel:Bool) throws {
        //print("classDeclaration run for ",self.impl," isTopLevel:",isTopLevel," needsDecl:",needsDecl," on Scope ",ASTModule.current.currentScope)

        if !isTopLevel || needsDecl {needsDecl = !isTopLevel;try ASTModule.current.declareType(type: impl)}
        
        if impl.mangledName != nil {
            //hosted type
            impl.nativeType=registeredClasses[impl.module!.name+"."+impl.name]
        }
        
        //remove this from list for further execution
        if (isTopLevel) {
            if previous != nil {
                previous!.next=next
                next?.previous=previous
            }
        }
    }
    
    public override func getType() throws -> ASTType {return impl}
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateClassDeclaration(self)}
}

public class StructDeclaration: Scope, Declaration {
    public var impl: StructType
    
    public override init() {
        impl=StructType()
        super.init()
        self.origin=self
    }
    
    public init(name:String, members: [Member], location: SourceLocatable, attributes: [Attribute], accessLevelModifier: Modifier?, 
                typeInheritanceClause: ASTTypeInheritanceClause?, generic: ASTGenericParameterClause?, genericWhere: ASTGenericWhereClause?) {
        self.impl=StructType(name: name, members: members, location: location, attributes: attributes, accessLevelModifier: accessLevelModifier, 
                             typeInheritanceClause: typeInheritanceClause, generic: generic, genericWhere: genericWhere)
        
        super.init(parent:ASTModule.current.currentScope,location:location)
        
        self.impl.decl=self
        self.context=ASTModule.current
        self.origin=self
        self.attributes=attributes
        if accessLevelModifier != nil {self.modifiers=[accessLevelModifier!]}
        
        //create scope entries for members
        for m in self.impl.members {
            //print("declare struct member:",m)
            switch m {
                case .property(let pm):
                    try? self.declareVar(variable: pm.variable)
                case .method(let mm):
                    //print("declare struct func:",mm.name)
                    try? self.declareFunc(function: mm)
                case .initializer(let im):
                    //print("declare struct initializer:",im.name)
                    try? self.declareFunc(function: im)
                case .`subscript`(_/*let sm*/):
                    _=1 //todo?
                case .associatedType(_/*let am*/):
                    _=1 //todo
                case .general(_/*let ast*/):
                    _=1
            }
        }
        
        try! ASTModule.current.declareType(type: impl)
        needsDecl=false
    }
    
    public override func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.StructDeclaration.rawValue))}
        
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true

        try impl.archive(data: data)

        data.isRoot=root
    }
    
    public static func StructDeclarationunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        //print("struct decl unarchive")
    
        let i=instance != nil ? instance as! StructDeclaration : try ASTFromTag(data: data) as! StructDeclaration
        
        try _=Scope.Scopeunarchive(data: data, instance: i)

        i.impl=(try ASTFromTag(data: data) as! StructType)
        i.impl.decl=i

        //also set context member of declaration and impl
        i.context=ASTModule.current.currentScope
        i.impl.context=i.context
        
        //restore scope declarations
        for m in i.impl.members {
            //print("declare class member:",m)
            switch m {
                case .property(let pm):
                    try i.declareVar(variable: pm.variable)
                case .method(let mm):
                    //print("declare class func:",mm.name)
                    try i.declareFunc(function: mm)
                case .initializer(let im):
                    //print("declare class initializer:",im.name)
                    try i.declareFunc(function: im)
                case .`subscript`(_/*let sm*/):
                    _=1 //todo?
                case .associatedType(_/*let am*/):
                    _=1 //todo
                case .general(_/*let ast*/):
                    _=1
            }
        }
        //todo restore types in scope, these are not stored within members
        
        //print("struct decl unarchive done")
        
        return i
    }
    
    public override func copy() -> AST {
        let sd=StructDeclaration()
        sd.attributes=attributes
        sd.modifiers=modifiers
        sd.location=location
        sd.impl=impl.copy() as! StructType
        sd.impl.decl=sd
        
        return sd
    }
    
    public override func replace(name: String, with: AST) -> AST {
        //todo
        return self
    }
    
    public override func runDeclarations(isTopLevel:Bool) throws {
        if !isTopLevel || needsDecl {needsDecl = !isTopLevel;try ASTModule.current.declareType(type: impl)}
        
        //print("structdecl decl")
        
        if impl.mangledName != nil {
            //hosted type
            impl.nativeType=registeredClasses[impl.module!.name+"."+impl.name]
        }
        
        //remove this from list for further execution
        if (isTopLevel) {
            if previous != nil {
                previous!.next=next
                next?.previous=previous
            }
        }
        
        //print("structdecl decl done")
    }

    public override func getType() throws -> ASTType {return impl}
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateStructDeclaration(self)}
}

public class ASTTypeAnnotation : AST {
    public var type: ASTType
    public var attributes: [Attribute]
    public var isInOutParameter: Bool
    public var next:AST? {get {return nil} set(newvalue) {}}
    public var previous:AST? {get {return nil} set(newvalue) {}}

    public init() {type=ASTType();attributes=[];isInOutParameter=false}

    public init(type: ASTType, attributes: [Attribute] = [], isInOutParameter: Bool = false) {
        self.type = type
        self.attributes = attributes
        self.isInOutParameter = isInOutParameter
    }

    public func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.ASTTypeAnnotation.rawValue))}
      
        let root=data.isRoot
        data.isRoot=true
    
        try type.archive(data: data)
        archiveAttributes(data: data, attributes)
        data.writeBool(isInOutParameter)
        
        data.isRoot=root
    }
  
    public static func unarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i:ASTTypeAnnotation=instance != nil ? instance as! ASTTypeAnnotation : try ASTFromTag(data: data) as! ASTTypeAnnotation
      
        i.type=(try ASTFromTag(data: data) as! ASTType)
        i.attributes=unarchiveAttributes(data: data)
        i.isInOutParameter=data.readBool()
        
        return i
    }
  
    public func copy() -> AST {
        var a:[Attribute]=[]
        for aa in attributes {
              a.append(aa.copy())
        }
        return ASTTypeAnnotation(type: type.copy() as! ASTType,attributes: a, isInOutParameter: isInOutParameter)
    }
  
    public func replace(name: String, with: AST) -> AST {return self}
  
    public func runDeclarations(isTopLevel:Bool) {}
    
    public func generate(delegate: ASTDelegate) throws {try delegate.generateASTTypeAnnotation(self)}

    public func exec() throws -> Value {runtimeNilValue}

    public func getType() throws -> ASTType {return type}
}

public class ProtocolDeclaration: Scope, Declaration {
    public var impl: ProtocolType
    
    public override init() {
        impl=ProtocolType()
        super.init()
        self.origin=self
    }
    
    public init(name:String, members: [Member], location: SourceLocatable, attributes: [Attribute], accessLevelModifier: Modifier?, 
                typeInheritanceClause: ASTTypeInheritanceClause?) {
        self.impl=ProtocolType(name: name, members: members, location: location, attributes: attributes, accessLevelModifier: accessLevelModifier, 
                               typeInheritanceClause: typeInheritanceClause)
                               
        super.init(parent:ASTModule.current.currentScope,location:location)
        
        self.impl.decl=self
        self.context=ASTModule.current
        self.origin=self
        self.attributes=attributes
        if accessLevelModifier != nil {self.modifiers=[accessLevelModifier!]}
        
        //create scope entries for members
        for m in self.impl.members {
            //print("declare proto member:",m)
            switch m {
                case .property(let pm):
                    try? self.declareVar(variable: pm.variable)
                case .method(let mm):
                    //print("declare proto func:",mm.name)
                    try? self.declareFunc(function: mm)
                case .initializer(let im):
                    //print("declare proto initializer:",im.name)
                    try? self.declareFunc(function: im)
                case .`subscript`(_/*let sm*/):
                    _=1 //todo?
                case .associatedType(_/*let am*/):
                    _=1 //todo
                case .general(_/*let ast*/):
                    _=1
            }
        }
        
        try! ASTModule.current.declareType(type: impl)
        needsDecl=false
    }
    
    public override func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.ProtocolDeclaration.rawValue))}
        
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true

        try impl.archive(data: data)

        data.isRoot=root
    }
    
    public static func ProtocolDeclarationunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i=instance != nil ? instance as! ProtocolDeclaration : try ASTFromTag(data: data) as! ProtocolDeclaration
        
        try _=Scope.Scopeunarchive(data: data, instance: i)

        i.impl=(try ASTFromTag(data: data) as! ProtocolType)
        i.impl.decl=i

        //also set context member of declaration and impl
        i.context=ASTModule.current.currentScope
        i.impl.context=i.context
        
        //restore scope declarations
        for m in i.impl.members {
            //print("declare class member:",m)
            switch m {
                case .property(let pm):
                    try i.declareVar(variable: pm.variable)
                case .method(let mm):
                    //print("declare class func:",mm.name)
                    try i.declareFunc(function: mm)
                case .initializer(let im):
                    //print("declare class initializer:",im.name)
                    try i.declareFunc(function: im)
                case .`subscript`(_/*let sm*/):
                    _=1 //todo?
                case .associatedType(_/*let am*/):
                    _=1 //todo
                case .general(_/*let ast*/):
                    _=1
            }
        }
        //todo restore types in scope, these are not stored within members
        
        return i
    }
    
    public override func copy() -> AST {
        let pd=ProtocolDeclaration()
        pd.attributes=attributes
        pd.modifiers=modifiers
        pd.location=location
        pd.impl=impl.copy() as! ProtocolType
        pd.impl.decl=pd
        
        return pd
    }
    
    public override func replace(name: String, with: AST) -> AST {return self}
    
    public override func runDeclarations(isTopLevel:Bool) throws {
        if !isTopLevel || needsDecl {needsDecl = !isTopLevel;try ASTModule.current.declareType(type: impl)}
        
        if impl.mangledName != nil {
            //hosted type
            impl.nativeType=registeredClasses[impl.module!.name+"."+impl.name]
        }
        
        //remove this from list for further execution
        if (isTopLevel) {
            if previous != nil {
                previous!.next=next
                next?.previous=previous
            }
        }
    }

    public override func getType() throws -> ASTType {return impl}
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateProtocolDeclaration(self)}
}

protocol Expression: AST {

}

public struct ASTGenericArgumentClause: AST {
    public var next:AST? {get {return nil} set(newvalue) {}}
    public var previous:AST? {get {return nil} set(newvalue) {}}
      
    public var argumentList: [ASTType]
  
    public init() {
        argumentList=[]
    }

    public init(argumentList: [ASTType]) {
        self.argumentList = argumentList
    }
  
    public func archive(data: SCLData) throws {
          if data.isRoot {data.writeWord(UInt16(ArchiveType.ASTGenericArgumentClause.rawValue))}
      
        let root=data.isRoot
        data.isRoot=true
      
        data.writeWord(UInt16(argumentList.count))
        for type in argumentList {
              try type.archive(data: data)
        }
      
        data.isRoot=root
    }
  
    public static func unarchive(data: SCLData, instance:AST?=nil) throws -> AST {
          var i:ASTGenericArgumentClause=instance != nil ? instance as! ASTGenericArgumentClause : try ASTFromTag(data: data) as! ASTGenericArgumentClause
      
        let c=Int(data.readWord())
        for _ in 0..<c {
            i.argumentList.append(try ASTFromTag(data: data) as! ASTType)
        }
            
          return i
      }
  
    public func copy() -> AST {
        var a:[ASTType]=[]
        for type in argumentList {
            a.append(type.copy() as! ASTType)
        }
        return ASTGenericArgumentClause(argumentList: a)
    }
  
    public func replace(name: String, with: AST) -> AST {return self}
  
    public func runDeclarations(isTopLevel:Bool) {}
    
    public func generate(delegate: ASTDelegate) throws {try delegate.generateASTGenericArgumentClause(self)}

    public func exec() throws -> Value {runtimeNilValue}

    public func getType() throws -> ASTType {return VoidType}
}

public class IdentifierExpression: ASTBase, Expression {
    public enum IdentiferKind {
        case identifier(String, ASTGenericArgumentClause?)
        case implicitParameterName(Int, ASTGenericArgumentClause?)
        case bindingReference(String)
    }

    public var kind:IdentiferKind
    public var impl:[AST]?
    public var isFree: Bool=false
    public var isGlobal: Bool = false

    public override init() {
        kind = .bindingReference("")
        impl=nil
        super.init()
    }

    public init(kind: IdentiferKind, location: SourceLocatable) {
        self.kind=kind
        super.init(location: location)
    }

    public override func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.IdentifierExpression.rawValue))}

        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true
        
        switch kind {
            case .identifier(let id, let ac):
                data.writeWord(1)
                data.writeShortString(id)
                if ac != nil {
                    data.writeBool(true)
                    try ac!.archive(data: data)
                }
                else {data.writeBool(false)}
            case .implicitParameterName(let i, let ac):
                data.writeWord(2)
                data.writeInt(i)
                if ac != nil {
                    data.writeBool(true)
                    try ac!.archive(data: data)
                }
                else {data.writeBool(false)}
            case .bindingReference(let id):
                data.writeWord(3)
                data.writeShortString(id)
        }

        data.isRoot=root
    }
    
    public static func IdentifierExpressionunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i=instance != nil ? instance as! IdentifierExpression : try ASTFromTag(data: data) as! IdentifierExpression
        
        try _=ASTBase.unarchive(data: data, instance: i)
        
        let k=data.readWord()
        if k==1 {
            let id=data.readShortString()!
            var ac:ASTGenericArgumentClause?=nil
            if data.readBool() {
                ac=(try ASTFromTag(data: data) as! ASTGenericArgumentClause)
            }
            i.kind = .identifier(id,ac)
        }
        else if k==2 {
            let ii=data.readInt()
            var ac:ASTGenericArgumentClause?=nil
            if data.readBool() {
                ac=(try ASTFromTag(data: data) as! ASTGenericArgumentClause)
            }
            i.kind = .implicitParameterName(ii,ac)
        }
        else if k==3 {
            let id=data.readShortString()!
            i.kind = .bindingReference(id)
        }
       
        return i
    }

    public override func copy() -> AST {
        switch kind {
            case .identifier(let s, let ac):
                return IdentifierExpression(kind: .identifier(s,ac?.copy() as? ASTGenericArgumentClause), location: location)
            case .implicitParameterName(let i, let ac):
                return IdentifierExpression(kind: .implicitParameterName(i,ac?.copy() as? ASTGenericArgumentClause), location: location)
            case .bindingReference(let s):
                return IdentifierExpression(kind: .bindingReference(s), location: location)
        }
    }
    
    public override func replace(name: String, with: AST) -> AST {return self}
    
    public override func runDeclarations(isTopLevel:Bool) throws {
        if impl==nil {
           var name="\(self)"
           switch kind {
               case .identifier(let id, let gac):
                   name=id
                   if gac==nil {
                        var funcScopeDepth=0
                        let i=try ASTModule.current.findVar(name: id, location:self.location,funcScopeDepth: &funcScopeDepth)
                        if i != nil {
                            impl=[i!]
                            if funcScopeDepth == -1 {self.isGlobal=true} //global var
                            if funcScopeDepth>1 {self.isFree=true} //declared outside of current function
                        }
                   }

                   if impl == nil {
                       //TODO Check for "." in name?
                       impl=try ASTModule.current.findFunc(name: id, location:self.location, genericArgs: gac != nil ? [gac!.argumentList] : nil)
                       if impl==nil {
                            let i=try ASTModule.current.findType(name: id, location:self.location, genericArgs: gac != nil ? [gac!.argumentList] : nil)
                            if i != nil {impl=[i!]}
                       }
                   }
               case .implicitParameterName(_/*let i*/,_/*let gac*/):
                    _="todo"
               case .bindingReference(_/*let id*/):
                    //name=id
                    _="todo"
           }
                
           if impl==nil {
               throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.cannotFind(name), sourceLocatable: self.location)
           }
        }
    }

    public override func exec() throws -> Value {
        if impl==nil || impl!.count==0 {
            throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("Identifier impl nil"), sourceLocatable: self.location)        
        }
    
        let ii=impl![0]
        if impl!.count==1 {
            if let v=ii as? Variable {
                return RuntimeValue(variable:v)
            }

            if let f=ii as? FunctionDeclaration {
                return RuntimeValue(function:f)
            }

            if let t=ii as? ASTType {
                return RuntimeValue(type:t)
            }
        }
        else {
            //assume all elements have the same type
            if ii is Variable /*let v=ii as? Variable*/ {
                var vl:[Variable]=[]
                for v in impl! {
                    if let vv=v as? Variable {
                        vl.append(vv)
                    }
                    else {
                        throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("Variable list invalid \(impl!)"), sourceLocatable: self.location)        
                    }
                }
                return RuntimeValue(variableList:vl)
            }

            if ii is FunctionDeclaration /*let f=ii as? FunctionDeclaration*/ {
                var fl:[FunctionDeclaration]=[]
                for f in impl! {
                    if let ff=f as? FunctionDeclaration {
                        fl.append(ff)
                    }
                    else {
                        throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("Function list invalid \(impl!)"), sourceLocatable: self.location)        
                    }
                }
                return RuntimeValue(functionList:fl)
            }

            if ii is ASTType /*let t=ii as? ASTType*/ {
                var tl:[ASTType]=[]
                for t in impl! {
                    if let tt=t as? ASTType {
                        tl.append(tt)
                    }
                    else {
                        throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("Type list invalid \(impl!)"), sourceLocatable: self.location)        
                    }
                }
                return RuntimeValue(typeList:tl)
            }
        }

        throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("Identifier unhandled impl:\(impl!) of type \(type(of:impl!))"), sourceLocatable: self.location)
    }

    public override func getType() throws -> ASTType {
        if impl != nil {
            if impl!.count==1 {
                return try impl![0].getType()
            }

            throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("IdentifierExpression getType is ambiguous:\(impl!)"), sourceLocatable: self.location)
        }

        throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("IdentifierExpression getType, no type"), sourceLocatable: self.location)
    }
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateIdentifierExpression(self)}
}

public class DictionaryEntry: AST {
    public var next:AST?=nil
    public var previous:AST?=nil

    public var key: AST
    public var value: AST
    public var type: ASTType
    public var location: ASTLocation

    public init() {
        self.key = NoOp()
        self.value = NoOp()
        self.type = ASTType()
        self.location=ASTLocation()
    }

    public init(key: AST, value: AST, location: SourceLocatable) {
        self.key=key
        self.value=value
        self.type=DictionaryType(name: "", key: try! key.getType(), value: try! value.getType(), location: location, attributes: [], accessLevelModifier: nil)
        self.location=ASTLocation(location:location)
    }

    public func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.DictionaryEntry.rawValue))}

        try key.archive(data: data)
        try value.archive(data: data)
    }

    public static func unarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i:DictionaryEntry=instance != nil ? instance as! DictionaryEntry : try ASTFromTag(data: data) as! DictionaryEntry
                     
        i.key=try ASTFromTag(data: data) 
        i.value=try ASTFromTag(data: data) 

        return i
    }
    
    public func copy() -> AST {
        return DictionaryEntry(key: key.copy(), value: value.copy(), location: location)
    }
    
    public func replace(name: String, with: AST) -> AST {return self}
    
    public func runDeclarations(isTopLevel:Bool) {}
    
    public func generate(delegate: ASTDelegate) throws {try delegate.generateDictionaryEntry(self)}

    public func exec() throws -> Value {runtimeNilValue}

    public func getType() throws -> ASTType {return type} 
}

public enum PlaygroundLiteral: AST {
    public var next:AST? {get {return nil} set(newvalue) {}}
    public var previous:AST? {get {return nil} set(newvalue) {}}

    case color(AST, AST, AST, AST)
    case file(AST)
    case image(AST)

    public init() {
        self = .file(NoOp())
    }

    public func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.PlaygroundLiteral.rawValue))}

        switch self {
            case .color(let e, let e1, let e2, let e3):
                data.writeWord(0)
                try e.archive(data: data)
                try e1.archive(data: data)
                try e2.archive(data: data)
                try e3.archive(data: data)
            case .file(let e):
                data.writeWord(1)
                try e.archive(data: data)
            case .image(let e):
                data.writeWord(2)
                try e.archive(data: data)
        }
    }

    public static func unarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        var i:PlaygroundLiteral=instance != nil ? instance as! PlaygroundLiteral : try ASTFromTag(data: data) as! PlaygroundLiteral
       
        let k=data.readWord()
        if k==0 {
            let e=try ASTFromTag(data: data) 
            let e1=try ASTFromTag(data: data) 
            let e2=try ASTFromTag(data: data) 
            let e3=try ASTFromTag(data: data) 
            i = .color(e,e1,e2,e3)
        }
        else if k==2 {i = .image(try ASTFromTag(data: data))}
        else {i = .file(try ASTFromTag(data: data))}

        return i
    }
    
    public func copy() -> AST {
        switch self {
            case .color(let a1, let a2, let a3, let a4): return PlaygroundLiteral.color(a1.copy(), a2.copy(), a3.copy(), a4.copy())
            case .file(let a): return PlaygroundLiteral.file(a.copy())
            case .image(let a): return PlaygroundLiteral.image(a.copy())
        }
    }
    
    public func replace(name: String, with: AST) -> AST {return self}
    
    public func runDeclarations(isTopLevel:Bool) {}
    
    public func generate(delegate: ASTDelegate) throws {try delegate.generatePlaygroundLiteral(self)}

    public func exec() throws -> Value {runtimeNilValue}

    public func getType() throws -> ASTType {return VoidType} 
}


public class FunctionDeclaration : ASTBase, RuntimeFunctionDeclaration {
    public var name: String
    public var genericParameterClause: ASTGenericParameterClause?
    public var signature: FunctionSignature
    public var genericWhereClause: ASTGenericWhereClause?
    public var body: CodeBlock?
    
    public var executor:(_ args:[Value]) throws -> Value = {args in return runtimeNilValue}  

    public var mangledName:String?=nil //runtime only
    public var resolvedSymbol:UInt64=0 //runtime only
    //public var cif:Pffi_cif=nil //runtime only
    public var context:Scope?=nil //runtime only
    
    public override init() {
        self.name=""
        self.genericParameterClause=nil
        self.genericWhereClause=nil
        self.signature=FunctionSignature()
        self.body=nil
        super.init()
        executor = { args in 
            self.enter(args:args)
            let r = try self.body?.exec() ?? runtimeNilValue
            self.leave()
            return r
        } 
    }

    public init(
        name: String,
        body: CodeBlock? = nil,
        location: SourceLocatable,
        attributes: [Attribute] = [],
        modifiers: [Modifier] = [],
        genericParameterClause: ASTGenericParameterClause? = nil,
        signature: FunctionSignature,
        genericWhereClause: ASTGenericWhereClause? = nil
        
      ) {
        self.name = name
        self.genericParameterClause = genericParameterClause
        self.signature = signature
        self.genericWhereClause = genericWhereClause
        self.body = body
        super.init(location: location)
        self.attributes=attributes
        self.modifiers=modifiers
        executor = { args in 
            self.enter(args:args)
            let r = try self.body?.exec() ?? runtimeNilValue
            self.leave()
            return r
        } 
    }
   
    func enter(args:[Value]) {
        //todo generate scope and push parameter nanes with args values (mind 'let' and inout args)
    }
    
    func leave() {
        //todo exit scope
    }
   
    public override func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.FunctionDeclaration.rawValue))}
      
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true
        
        data.writeShortString(name)
        if genericParameterClause != nil {
            data.writeBool(true)
            try genericParameterClause!.archive(data: data)
        }
        else {data.writeBool(false)}
        try signature.archive(data: data)
        if genericWhereClause != nil {
            data.writeBool(true)
            try genericWhereClause!.archive(data: data)
        }
        else {data.writeBool(false)}
        
        if body != nil && mangledName==nil { //skip body for external functions
            data.writeBool(true)
            try body!.archive(data: data)
        }
        else {data.writeBool(false)}
        
        if mangledName != nil {
            data.writeBool(true)
            data.writeString(mangledName!)
        }
        else {data.writeBool(false)}
        
        data.isRoot=root
    }

    public static func FunctionDeclarationunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i:FunctionDeclaration=instance != nil ? instance as! FunctionDeclaration : try ASTFromTag(data: data) as! FunctionDeclaration
    
        _=try ASTBase.unarchive(data: data, instance: i)
        
        i.name=data.readShortString()!
        if data.readBool() {
            i.genericParameterClause=(try ASTFromTag(data: data) as! ASTGenericParameterClause)
        }
        i.signature=(try ASTFromTag(data: data) as! FunctionSignature)
        if data.readBool() {
            i.genericWhereClause=(try ASTFromTag(data: data) as! ASTGenericWhereClause)
        }
        
        if data.readBool() {
            i.body=(try ASTFromTag(data: data) as! CodeBlock)
        }
        
        if data.readBool() {i.mangledName=data.readString()!}

        if i.mangledName != nil {i.body=nil} //clear body for external funcs
        
        return i
    }
    
    public override func copy() -> AST {
        var a:[Attribute]=[]
        for aa in attributes {a.append(aa.copy())}
        var m:[Modifier]=[]
        for mm in modifiers {m.append(mm)}
        
        return FunctionDeclaration(name: name, body: body?.copy() as? CodeBlock, location: location, attributes: a, modifiers: m, 
                                   genericParameterClause: genericParameterClause?.copy() as? ASTGenericParameterClause, 
                                   signature: signature.copy() as! FunctionSignature, 
                                   genericWhereClause: genericWhereClause?.copy() as? ASTGenericWhereClause)
    }
    
    public override func replace(name: String, with: AST) -> AST {
        //todo
        return self
    }
    
    public override func runDeclarations(isTopLevel:Bool) throws {
        if !isTopLevel || needsDecl {needsDecl = !isTopLevel;try ASTModule.current.declareFunc(function: self)}
        
        //print("typealias decl ",alias," previous=",previous," next=",next," isTopLevel=",isTopLevel)
        
        //remove this from list for further execution
        if (isTopLevel) {
            if previous != nil {
                previous!.next=next
                next?.previous=previous
            }
        }
    }
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateFunctionDeclaration(self)}
    
    public override func exec() throws -> Value {
        //return try body?.exec() ?? runtimeNilValue
        //must call via FunctionCallExpression
        throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("FunctionDeclaration exec called directly"), sourceLocatable: self.location)
    }

    public override func getType() throws -> ASTType {return try signature.getType()} 
}

public class Literal: ASTBase {
    public enum Kind {
        case `nil`
        case boolean(Bool)
        case integer(Int, String)
        case floatingPoint(Double, String)
        case staticString(String, String)
        case interpolatedString([AST], String)
        case array([AST])
        case dictionary([DictionaryEntry])
        case playground(PlaygroundLiteral)
    }

    public var kind:Kind
    public var value:Value?=nil
            
    public override init() {
        kind = .nil
        super.init()
    }

    public override init(location: SourceLocatable) {
        kind = .nil
        super.init(location: location)
    }

    public init(kind: Kind, location: SourceLocatable) {
        self.kind=kind
        super.init(location: location)
    }
        
    public override func archive(data: SCLData) throws {
        //print("archiveLiteral in \(ASTModule.current)")

        if data.isRoot {data.writeWord(UInt16(ArchiveType.Literal.rawValue))}

        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true

        switch kind {
            case .nil: data.writeWord(0)
            case .boolean(let b):
                data.writeWord(1)
                data.writeBool(b)
            case .integer(let i, let s):
                data.writeWord(2)
                data.writeInt(i)
                data.writeShortString(s)
            case .floatingPoint(let d, let s):
                data.writeWord(3)
                data.writeDouble(d)
                data.writeShortString(s)
            case .staticString(let s, let s1):
                data.writeWord(4)
                data.writeShortString(s)
                data.writeShortString(s1)
            case .interpolatedString(let e, let s):
                data.writeWord(5)
                data.writeInt(e.count)
                for ee in e {try ee.archive(data: data)}
                data.writeShortString(s)
            case .array(let e):
                data.writeWord(6)
                data.writeInt(e.count)
                for ee in e {try ee.archive(data: data)}
            case .dictionary(let e):
                data.writeWord(7)
                data.writeInt(e.count)
                for ee in e {try ee.archive(data: data)}
            case .playground(let pg):
                data.writeWord(8)
                try pg.archive(data: data)
        }

        data.isRoot=root
    }
    
    public static func Literalunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        //print("unarchiveLiteral in \(ASTModule.current)")
        let i:Literal=instance != nil ? instance as! Literal : try ASTFromTag(data: data) as! Literal
        
        _=try ASTBase.unarchive(data: data, instance: i)

        //print("unarchiveLiteral ASTBase ok")

        let k=data.readWord()
        if k==0 {i.kind = .nil}
        else if k==1 {i.kind = .boolean(data.readBool())}
        else if k==2 {
            let ii=data.readInt()
            let s=data.readShortString()!
            i.kind = .integer(ii,s)
        }
        else if k==3 {
            let d=data.readDouble()
            let s=data.readShortString()!
            i.kind = .floatingPoint(d,s)
        }
        else if k==4 {
            let s=data.readShortString()!
            let s1=data.readShortString()!
            i.kind = .staticString(s,s1)
        }
        else if k==5 {
            let c=data.readWord()
            var a:[AST]=[]
            for _ in 0..<c {a.append(try ASTFromTag(data: data))}
            let s=data.readShortString()!
            i.kind = .interpolatedString(a,s)
        }
        else if k==6 {
            let c=data.readWord()
            var a:[AST]=[]
            for _ in 0..<c {a.append(try ASTFromTag(data: data))}
            i.kind = .array(a)
        }
        else if k==7 {
            let c=data.readWord()
            var a:[DictionaryEntry]=[]
            for _ in 0..<c {a.append(try ASTFromTag(data: data) as! DictionaryEntry)}
            i.kind = .dictionary(a)
        }
        else if k==7 {i.kind = .playground(try ASTFromTag(data: data) as! PlaygroundLiteral)}
        else {i.kind = .nil}

        return i
    }
    
    public override func copy() -> AST {
        switch kind {
            case .`nil`:
                return Literal(kind: .nil, location: location)
            case .boolean(let b):
                return Literal(kind: .boolean(b), location: location)
            case .integer(let i, let s):
                return Literal(kind: .integer(i, s), location: location)
            case .floatingPoint(let d, let s):
                return Literal(kind: .floatingPoint(d,s), location: location)
            case .staticString(let s, let s1):
                return Literal(kind: .staticString(s,s1), location: location)
            case .interpolatedString(let a, let s):
                var aa:[AST]=[]
                for aaa in a {aa.append(aaa.copy())}
                return Literal(kind: .interpolatedString(aa,s), location: location)
            case .array(let a):
                var aa:[AST]=[]
                for aaa in a {aa.append(aaa.copy())}
                return Literal(kind: .array(aa), location: location)
            case .dictionary(let d):
                var dd:[DictionaryEntry]=[]
                for ddd in d {dd.append(ddd.copy() as! DictionaryEntry)}
                return Literal(kind: .dictionary(dd), location: location)
            case .playground(let pg):
                return Literal(kind: .playground(pg.copy() as! PlaygroundLiteral), location: location)
        }
    }
    
    public override func replace(name: String, with: AST) -> AST {return self}
    
    public override func runDeclarations(isTopLevel:Bool) {}

    public override func exec() throws -> Value {
        if value != nil {return value!} //precalculated

        //one time initialization
        switch kind {
            case .nil: 
                value = runtimeNilValue
            case .boolean(let b):
                value=RuntimeValue(bool:b)
                value!.type=RuntimeSwiftType(.bool,RuntimeSwiftType_Literal)
            case .integer(let i, _):
                value=RuntimeValue(int:i)
                value!.type=RuntimeSwiftType(.int,RuntimeSwiftType_Literal)
            case .floatingPoint(let d, _):
                value=RuntimeValue(double:d)
                value!.type=RuntimeSwiftType(.double,RuntimeSwiftType_Literal)
            case .staticString(let s, _):
                value=RuntimeValue(string:s)
                value!.type=RuntimeSwiftType(.string,RuntimeSwiftType_Literal)
            case .interpolatedString(let e, _):
                //value = .literal(.interpolatedString(e))
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("todo interpolated string literal"), sourceLocatable: self.location)
            case .array(let e):
               //value = .literal(.array(e))
               throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("todo array literal"), sourceLocatable: self.location)
            case .dictionary(let e):
                //value = .literal(.dictionary(e))
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("todo dictionary literal"), sourceLocatable: self.location)
            case .playground(let pg):
                //value = .literal(.playground(pg))
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("todo playground literal"), sourceLocatable: self.location)
        }

        return value!
    }

    public override func getType() throws -> ASTType {
        switch kind {
            case .`nil`: return PointerType
            case .boolean(_): return BoolType
            case .integer(_, _): return IntType
            case .floatingPoint(_, _): return DoubleType
            case .staticString(_, _): return StringType
            case .interpolatedString(_, _): return VoidType //??
            case .array(_): return VoidType //TODO
            case .dictionary(let d): 
                if d.count==1 {return try d[0].getType()}
                return VoidType //??
            case .playground(_): return VoidType
        }
    }
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateLiteral(self)}
    
}

public class ExplicitMemberExpression : ASTBase {
    public enum Kind {
        case tuple(AST, Int)
        case namedType(AST, String)
        case generic(AST, String, ASTGenericArgumentClause)
        case argument(AST, String, [String])
    }

    public var kind: Kind
    
    public override init() {
        kind = .tuple(NoOp(),0)
        super.init()
    }

    public init(kind: Kind, location: SourceLocatable) {
        self.kind = kind
        super.init(location: location)
    }
    
    public override func archive(data: SCLData) throws {
        //print("archiveLiteral in \(ASTModule.current)")

        if data.isRoot {data.writeWord(UInt16(ArchiveType.ExplicitMemberExpression.rawValue))}

        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true

        switch kind {
            case .tuple(let ast, let index):
                data.writeWord(1)
                try ast.archive(data: data)
                data.writeInt(index)
            case .namedType(let ast, let name):
                data.writeWord(2)
                try ast.archive(data: data)
                data.writeShortString(name)
            case .generic(let ast, let name, let genericArgumentClause):
                data.writeWord(3)
                try ast.archive(data: data)
                data.writeShortString(name)
                try genericArgumentClause.archive(data: data)
            case .argument(let ast, let name, let args):
                data.writeWord(4)
                try ast.archive(data: data)
                data.writeShortString(name)
                data.writeWord(UInt16(args.count))
                for a in args {
                    data.writeShortString(a)
                }
        }

        data.isRoot=root
    }
    
    public static func ExplicitMemberExpressionunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        //print("unarchiveLiteral in \(ASTModule.current)")
        let i:ExplicitMemberExpression=instance != nil ? instance as! ExplicitMemberExpression : try ASTFromTag(data: data) as! ExplicitMemberExpression
        
        _=try ASTBase.unarchive(data: data, instance: i)

        //print("unarchiveLiteral ASTBase ok")

        let k=data.readWord()
        if k==1 {
            let ast=try ASTFromTag(data: data)
            let index=data.readInt()
            i.kind = .tuple(ast,index)
        }
        else if k==2 {
            let ast=try ASTFromTag(data: data)
            let name=data.readShortString()!
            i.kind = .namedType(ast,name)
        }
        else if k==3 {
            let ast=try ASTFromTag(data: data)
            let name=data.readShortString()!
            let g=try ASTFromTag(data: data) as! ASTGenericArgumentClause
            i.kind = .generic(ast,name,g)   
        }
        else if k==4 {
            let ast=try ASTFromTag(data: data)
            let name=data.readShortString()!
            var a:[String]=[]
            let c=Int(data.readWord())
            for _ in 0..<c {a.append(data.readShortString()!)}
            i.kind = .argument(ast,name,a)   
        }

        return i
    }
    
    public override func copy() -> AST {
        switch kind {
            case .tuple(let ast, let index):
                return ExplicitMemberExpression(kind: .tuple(ast.copy(),index), location: location)
            case .namedType(let ast, let name):
                return ExplicitMemberExpression(kind: .namedType(ast.copy(),name), location: location)
            case .generic(let ast, let name, let genericArgumentClause):
                return ExplicitMemberExpression(kind: .generic(ast.copy(),name,genericArgumentClause.copy() as! ASTGenericArgumentClause), location: location)
            case .argument(let ast, let name, let args):
                return ExplicitMemberExpression(kind: .argument(ast.copy(),name, args), location: location)
        }
    }
    
    public override func replace(name: String, with: AST) -> AST {return self}
    
    public override func runDeclarations(isTopLevel:Bool) throws {
        switch kind {
            case .tuple(let ast, _):
                try ast.runDeclarations(isTopLevel: isTopLevel)
            case .namedType(let ast, _):
                try ast.runDeclarations(isTopLevel: isTopLevel)
            case .generic(let ast, _, _):
                try ast.runDeclarations(isTopLevel: isTopLevel)
            case .argument(let ast, _, _):
                try ast.runDeclarations(isTopLevel: isTopLevel)
         
        }
    }

    public override func exec() throws -> Value {
        switch kind {
            case .tuple(let ast, let index):
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("todo ExplicitMemberExpression tuple from \(ast)"), sourceLocatable: self.location)
            case .namedType(let ast, let name):
                //throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("todo ExplicitMemberExpression namedType from \(ast)"), sourceLocatable: self.location)
                let e=try ast.exec()
                switch e.type.0 {
                    case .variable:
                        if let v=e.value as? Variable {
                            //print("name:\(v.name), type:",v.typeAnnotation.type)
                            if let t=v.typeAnnotation.type as? StructOrClassType {
                                return try t.getField(instance: v, name: name)
                            }
                            throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("todo ExplicitMemberExpression variable from \(v):\(name)"), sourceLocatable: self.location)
                        }

                        throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("todo ExplicitMemberExpression namedType from \(e):\(name)"), sourceLocatable: self.location)
                    default:
                        throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("todo ExplicitMemberExpression namedType from \(e):\(name)"), sourceLocatable: self.location)
                }
                
            case .generic(let ast, let name, let genericArgumentClause):
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("todo ExplicitMemberExpression generic from \(ast)"), sourceLocatable: self.location)
            case .argument(let ast, let name, let args):
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("todo ExplicitMemberExpression argument from \(ast)"), sourceLocatable: self.location)
        }
    }

    public override func getType() throws -> ASTType {
        switch kind {
            case .tuple(let ast, let index):
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("todo ExplicitMemberExpression type tuple from \(ast)"), sourceLocatable: self.location)
            case .namedType(let ast, let name):
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("todo ExplicitMemberExpression type namedType from \(ast)"), sourceLocatable: self.location)
            case .generic(let ast, let name, let genericArgumentClause):
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("todo ExplicitMemberExpression type generic from \(ast)"), sourceLocatable: self.location)
            case .argument(let ast, let name, let args):
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("todo ExplicitMemberExpression type argument from \(ast)"), sourceLocatable: self.location)
        }
        
        
    }
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateExplicitMemberExpression(self)}
      
}

public typealias Operator = String
// TODO: operator will have its own dedicated class when it becomes more complicated














