import Foundation
import SwiftAST
//import Runtime

public class ASTType: ASTBase, CustomStringConvertible, Hashable, RuntimeType {
    public var name:String 
    public var module: ASTModule?=nil
    public var swiftType:Any.Type?
    public var runtimeType: RuntimeSwiftType?
    public var index:Int = -1 //archiving/unarchiving index
    public var nativeType:Any.Type?=nil
    
    public var context:Scope?=nil //runtime only
    public var isGlobal: Bool = false
    public var decl:Scope?=nil

    public class TryIndexedType: AST {
        public var next:AST? {get {return nil} set(newvalue) {}}
        public var previous:AST? {get {return nil} set(newvalue) {}}
        
        public func archive(data: SCLData) throws {
            //dummy
        }
        
        static func archive(data: SCLData, instance:ASTType) throws -> Bool {
            data.writeWord(UInt16(ArchiveType.TryIndexedType.rawValue))
            if instance.index>=0 {
                //throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("Unindexed type: \(name)"), sourceLocatable: location)
                //indexed archive
                data.writeBool(false)
                data.writeWord(UInt16(instance.index))
                return false
            }
        
            //full archive
            data.writeBool(true)
            instance.index=data.typeIndex
            data.typeIndex=data.typeIndex+1
            data.writeWord(UInt16(instance.index))
        
            //try ASTModule.assert(instance.module != nil,msg: "missing module in type \(instance)")
            if instance.module == nil {data.writeWord(65535)}
            else {
                data.writeWord(UInt16(instance.module!.index))
            
                if instance.module!.index != 1 { //index 0 is swift, index >1 are imported modules
                    data.writeShortString(instance.name)
                    return false
                } 
            }
            return true
        }
    
        public static func unarchive(data: SCLData, instance:AST?) throws -> AST {
            if data.readBool()==false {
                //indexed mode
                let i=Int(data.readWord())
                return data.types[i]!
            }
            
            //full unarchive
            let i=Int(data.readWord())
            let m=data.readWord() //module index
            
            if m == 65535 {return try ASTFromTag(data: data, typeIndex: i)}
            
            if m != 1 {
                let m:ASTModule = m==0/*Swift*/ ? allModules[0] : data.importmapping[Int(m)]!
                let name=data.readShortString()!
                
                //we come from imported module
                var dummy=0
                let t=try m.findType(name: name, location: SourceLocation(identifier: "", line: -1, column: -1), funcScopeDepth: &dummy, genericArgs: nil, recurse:false) 
                try ASTModule.assert( t != nil,msg: "imported type \(name) from imported module \(m.name) not found")
                
                data.types[i] = t!
                    
                return t!
            }
            
            return try ASTFromTag(data: data, typeIndex: i)
        }
        
        public func copy() -> AST {return self}
        
        public func replace(name: String, with: AST) -> AST {return self}
        
        public func runDeclarations(isTopLevel:Bool) {}
        
        public func generate(delegate: ASTDelegate) throws {try delegate.generateASTType_TryIndexedType(self)}        

        public func exec() throws -> Value {runtimeNilValue}

        public func getType() throws -> ASTType {return VoidType} //??
    }
        
    public var description: String {
        if let at=self as? AliasType {
            return at.name + " aka " + at.assignment.description
        }
        return name
    }
    
    public override init() {
        name=""
        swiftType=nil
        runtimeType=nil
        super.init(location: SourceLocation(identifier: "", line: -1, column: -1))
        try! ASTModule.current.addType(type:self)
    }
    
    init(swiftType: Any.Type, runtimeType: RuntimeSwiftType?=nil, location: SourceLocatable?=nil) {
        self.name=String(describing:swiftType)
        self.swiftType=swiftType
        self.runtimeType=runtimeType
        self.context=ASTModule.current
        super.init(location: location != nil ? location! : SourceLocation(identifier: "", line: -1, column: -1))
        try! ASTModule.current.addType(type:self)
    }
    
    init(name:String, location: SourceLocatable) {
        self.name=name
        self.swiftType=nil
        self.runtimeType=nil
        super.init(location: location)
        try! ASTModule.current.addType(type:self)
    }

    public func findType(name: String) -> ASTType? {
        if self.name==name {return self}

        return nil
    }
    
    open func getRuntimeType() throws -> RuntimeSwiftType {
        if runtimeType != nil {return runtimeType!}
        
        throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("Runtime type not set for \(self): \(name)"), sourceLocatable: location)  
    }
    
    public func fullArchive(data: SCLData) throws -> Bool {
        return try TryIndexedType.archive(data: data, instance: self)
    }
    
    public override func archive(data: SCLData) throws {
        if data.isRoot {
            if try !self.fullArchive(data: data) {return}
            data.writeWord(UInt16(ArchiveType.ASTType.rawValue))
        }
        
        data.writeShortString(self.name)
        
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=root
    }
    
    public static func ASTTypeunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i=instance != nil ? instance as! ASTType : try ASTFromTag(data: data) as! ASTType
        
        i.name=data.readShortString()!
        
        return try ASTBase.unarchive(data: data, instance: i)
    }
    
    open func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        if swiftType != nil {hasher.combine("\(swiftType!)")}
    }
    
    public static func ==(lhs: ASTType, rhs: ASTType) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
       
    public override func copy() -> AST {
        if swiftType != nil {return ASTType(swiftType: swiftType!)}
        return ASTType(name:name, location: self.location)
    }
    
    public override func replace(name: String, with: AST) -> AST {
        if self.name==name {return with}
        return self
    }

    static func get(type atype:Type) throws -> ASTType {
        var n:String?=nil
        var genericArguments:[[ASTType]]=[] //list per name element, e.g Type<B>.Another<C,D>
        var names:[String]=[]
        var hasGenericArguments=false
        if let ti=atype as? TypeIdentifier {
            //print("ti is TypeIdentifier")
            for nn in ti.names {
                //print("ti name:",nn)
                if nn.genericArgumentClause != nil {
                    var a:[ASTType]=[]
                    for ga in nn.genericArgumentClause!.argumentList {
                        a.append(try ASTType.get(type:ga))
                    }
                    genericArguments.append(a)
                    hasGenericArguments=a.count>0
                }
                else {genericArguments.append([])}
                
                names.append(nn.name.textDescription)
            }
            n=names.map({ "\($0)" }).joined(separator: ".")
        }
        else if atype is AnyType {n="Swift.AnyType"}
        
        if n==nil {
            throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("Unhandled AST type:\(type(of:atype)) for value:\(atype)"), sourceLocatable: atype)
            
        }
        
        var result:ASTType?=nil
        if !hasGenericArguments || genericArguments[0].count==0 {
            if let i=n!.firstIndex(of:".") {
                //search with module prefix
                let m=String(n![..<i])
                var n=String(n![i...])
                n.removeFirst()
            
                for mm in allModules {
                    if mm.name==m {
                        var dummy=0
                        if let t=try mm.findType(name: n, location: atype, funcScopeDepth: &dummy, genericArgs: hasGenericArguments ? Array(genericArguments[1...]) : nil ) {
                            result=t
                            break
                        }
                        throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.noTypeNamedInModule(n,m), sourceLocatable: atype)
                    }
                }
            }
        }
        
        if result==nil {
            //search all loaded modules for this type
            for m in allModules {
                var dummy=0
                if let t=try m.findType(name: n!, location: atype, funcScopeDepth: &dummy, genericArgs: hasGenericArguments ? genericArguments : nil) {result=t;break}
            }
        
            if result==nil {throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.noTypeNamed(n!), sourceLocatable: atype)}
        }
        
        return result!
    }

    public override func getType() throws -> ASTType {return self}
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateASTType(self)}
}

public struct ASTGenericParameterClause: AST {
    public var next:AST? {get {return nil} set(newvalue) {}}
    public var previous:AST? {get {return nil} set(newvalue) {}}
      
    public enum ASTGenericParameter {
        case identifier(String)
        case typeConformance(String, ASTType)
        case protocolConformance(String, ASTType)
    }

    public var parameterList: [ASTGenericParameter]
  
    public init() {
        parameterList=[]
    }

    public init(parameterList: [ASTGenericParameter]) {
        self.parameterList = parameterList
    }
  
    public func archive(data: SCLData) throws {
        if data.isRoot {data.writeWord(UInt16(ArchiveType.ASTGenericParameterClause.rawValue))}
      
        let root=data.isRoot
        data.isRoot=true
      
        data.writeWord(UInt16(parameterList.count))
        for p in parameterList {
            switch p {
                case .identifier(let identifier):
                    data.writeWord(0)
                    data.writeShortString(identifier)
                case .typeConformance(let identifier, let type):
                    data.writeWord(1)
                    data.writeShortString(identifier)
                    try type.archive(data: data)
                case .protocolConformance(let identifier, let proto):
                    data.writeWord(2)
                      data.writeShortString(identifier)
                      try proto.archive(data: data)
              }
        }
      
          data.isRoot=root
    }
  
    public static func unarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        var i:ASTGenericParameterClause=instance != nil ? instance as! ASTGenericParameterClause : try ASTFromTag(data: data) as! ASTGenericParameterClause
      
        let c=Int(data.readWord())
        for _ in 0..<c {
            let k=Int(data.readWord())
            let identifier=data.readShortString()!
            if k==2 {i.parameterList.append(.protocolConformance(identifier, try ASTFromTag(data: data) as! ASTType))}
            else if k==1 {i.parameterList.append(.typeConformance(identifier, try ASTFromTag(data: data) as! ASTType))}
              else {i.parameterList.append(.identifier(identifier))}
        }
        
          return i
    }
  
    public func copy() -> AST {
        var a:[ASTGenericParameter]=[]
        for aa in parameterList {
            switch aa {
                case .identifier(let identifier):
                    a.append(.identifier(identifier))
                case .typeConformance(let identifier, let type):
                    a.append(.typeConformance(identifier, type.copy() as! ASTType))
                case .protocolConformance(let identifier, let proto):
                      a.append(.protocolConformance(identifier, proto.copy() as! ASTType))
              }
        }
        return ASTGenericParameterClause(parameterList: a)
    }
  
    public func replace(name: String, with: AST) -> AST {return self}
  
    public func runDeclarations(isTopLevel:Bool) {}
    
    public func generate(delegate: ASTDelegate) throws {try delegate.generateASTGenericParameterClause(self)}

    public func exec() throws -> Value {runtimeNilValue}

    public func getType() throws -> ASTType {return VoidType}
}

public class GenericType: ASTType { //placeholder for generic args
    public var generic: ASTGenericParameterClause?
    public var dummy: Bool
    
    public override init() {
        generic=nil
        dummy=true
        super.init()
    }
    
    public init(name: String, location: SourceLocatable, dummy:Bool=true, generic:ASTGenericParameterClause?=nil) {
        self.generic=generic
        self.dummy=dummy
        super.init(name:name, location: location)
    }
    
    public override func archive(data: SCLData) throws {
        //print("archiving GenericType generic=",generic," root=",data.isRoot)
        
        if data.isRoot {
            if try !self.fullArchive(data: data) {return}
            data.writeWord(UInt16(ArchiveType.GenericType.rawValue))
        }
        
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true
    
        data.writeBool(generic != nil)
        try generic?.archive(data:data)
        data.writeBool(dummy)
        
        //print("archived GenericType")
        
        data.isRoot=root
    }
    
    public static func GenericTypeunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i:GenericType=instance != nil ? instance as! GenericType : try ASTFromTag(data: data) as! GenericType
        
        try _=ASTType.ASTTypeunarchive(data: data, instance: i)
        
        if data.readBool() {i.generic=(try ASTFromTag(data: data) as! ASTGenericParameterClause)}
        i.dummy=data.readBool()
        
        return i
    }
    
    public override func hash(into hasher: inout Hasher) {
        super.hash(into:&hasher)
        hasher.combine(dummy)
        if generic != nil {
            for aa in generic!.parameterList {
              switch aa {
                  case .identifier(let identifier):
                      hasher.combine(".identifier:"+identifier)
                  case .typeConformance(let identifier, let type):
                      hasher.combine(".typeConformance:"+identifier)
                      hasher.combine(type.hashValue)
                  case .protocolConformance(let identifier, let proto):
                      hasher.combine(".protocolConformance:"+identifier)
                      hasher.combine(proto.hashValue)
              }
          }
        }
    }
    
    public override func copy() -> AST {
        let g=generic?.copy() as? ASTGenericParameterClause
        return GenericType(name:name, location: self.location, dummy:dummy,generic:g)
    }
    
    public override func replace(name: String, with: AST) -> AST {
        guard let with=with as? ASTType else {return self}
    
        if generic != nil {
            var idx=0
            for aa in generic!.parameterList {
              switch aa {
                  case .identifier(var identifier):
                      if identifier==name {
                          identifier=with.name
                          generic!.parameterList[idx] = .identifier(identifier)
                      }
                  case .typeConformance(var identifier, let type):
                      if identifier==name {identifier=with.name}
                      generic!.parameterList[idx] = .typeConformance(identifier, type.replace(name: name, with: with) as! ASTType)
                  case .protocolConformance(var identifier, let proto):
                      if identifier==name {identifier=with.name}
                      generic!.parameterList[idx] = .protocolConformance(identifier, proto.replace(name: name, with: with) as! ASTType)
              }
              idx=idx+1
            }
        }
        return super.replace(name: name, with: with)
    }
}

public class AliasType: GenericType {
    var assignment: ASTType
    
    public override init() {
        assignment=ASTType()
        super.init()
    }
    
    public init(name: String, attributes: [Attribute], modifiers: [Modifier], location: SourceLocatable, assignment: ASTType, generic:ASTGenericParameterClause?) {
        self.assignment=assignment
        super.init(name:name, location: location, dummy:false, generic:generic)
        self.attributes=attributes
        self.modifiers=modifiers
    }
    
    public override func archive(data: SCLData) throws {
        if data.isRoot {
            if try !self.fullArchive(data: data) {return}
            data.writeWord(UInt16(ArchiveType.AliasType.rawValue))
        }
        
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true
        
        try assignment.archive(data: data)
        
        data.isRoot=root
    }
    
    public static func AliasTypeunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i=instance != nil ? instance as! AliasType : try ASTFromTag(data: data) as! AliasType
        
        try _=GenericType.GenericTypeunarchive(data: data, instance: i)
        
        i.assignment=try ASTFromTag(data: data) as! ASTType
        
        return i
    }
    
    public override func hash(into hasher: inout Hasher) {
        super.hash(into:&hasher)
        hasher.combine(assignment.hashValue)
    }
    
    public override func copy() -> AST {
        let g=generic?.copy() as? ASTGenericParameterClause
        let a=assignment.copy() as! ASTType
        return AliasType(name:name, attributes: attributes, modifiers: modifiers, location: self.location, assignment: a, generic:g)
    }
    
    public override func replace(name: String, with: AST) -> AST {
        assignment=assignment.replace(name: name, with: with) as! ASTType
        return super.replace(name: name, with: with)
    }

    public override func getType() -> ASTType {return assignment} //or self?
}

/*public struct RuntimeProperty: RuntimeVariable {
    var property: PropertyInfo
    var instance: RuntimeValue

    public var name: String {
        property.name
    }
    public var isConstant: Bool {
        return false
    }

    public var value:RuntimeValue? {
        let v=try! property.get(from: instance.value)
        return Value(anyvalue: v)
    }

    public mutating func setValue(value:RuntimeValue?) {
        try! property.set(value: value!.value, on: &instance.value)
    }
}

public struct RuntimeMethod: RuntimeFunctionDeclaration {
    var function: FunctionDeclaration
    var instance: RuntimeValue

    public var name: String {
        return function.name
    }
}
*/

public class StructOrClassType: GenericType {
    public var genericWhere: ASTGenericWhereClause?
    public var typeInheritanceClause: ASTTypeInheritanceClause?
    public var members:[Member]
    public var vtable:[(String,UInt8)]?=nil 
    public var mangledName:String?=nil
    //var typeInfo:TypeInfo?=nil
    //var nativeProperties:[String:PropertyInfo]=[:]
    
    public override init() {
        genericWhere=nil
        typeInheritanceClause=nil
        members=[]
        super.init()
    }
    
    public init(name: String, members: [Member], location: SourceLocatable, typeInheritanceClause: ASTTypeInheritanceClause?,
                generic:ASTGenericParameterClause?, genericWhere: ASTGenericWhereClause?) {
        self.genericWhere=genericWhere
        self.typeInheritanceClause=typeInheritanceClause
        self.members=members
        super.init(name:name, location: location, dummy:false, generic:generic)
    }

    public func getField(instance inst: AST, name: String) throws -> Value {
        let value=try inst.exec()
        var instance:Value?=nil
        if value.type.0 == . variable {
            if let v=value.value as? Variable {
                //print("is variable with value=",value)
                instance=v.value
            }
        }

        if instance==nil {
            throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("StructOrClassType getField: cannot retrieve \(name). No instance for \(inst)"), sourceLocatable: location)        
        }

        //check for method
        var dummy=0
        if let f=try self.decl?.findFunc(name: name, location: location, funcScopeDepth: &dummy, genericArgs: nil, recurse:false) {
            /*if f.count==1 {
                return Value(function: RuntimeMethod(function: f[0], instance: instance!))
            }

            var l:[RuntimeFunctionDeclaration]=[]
            for ff in f {
                l.append(RuntimeMethod(function: ff, instance: instance!))
            }
            return Value(functionList: l)*/
        }

        //check for properties
        if mangledName != nil { //external type
            /*if let p=nativeProperties[name] {
                let pv=RuntimeProperty(property: p, instance: instance!)
                return Value(variable: pv)
            }

            if nativeType != nil {
                if typeInfo==nil {
                    typeInfo = try Runtime.typeInfo(of: nativeType!)
                }
            }

            if typeInfo != nil {
                let property = try typeInfo!.property(named: name)
                if property != nil {
                    //print("property=",property)
                    nativeProperties[name]=property!
                    
                    let pv=RuntimeProperty(property: property!, instance: instance!)
                    return Value(variable: pv)
                }
            }*/

            throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("StructOrClassType getField: cannot retrieve \(name)"), sourceLocatable: location)
        }

        //TODO
        return Value(int:66)
    }
    
    public override func getRuntimeType() throws -> RuntimeSwiftType {
        if runtimeType != nil {return runtimeType!}
        
        //todo create struct rt type and store in runtimeType
        
        throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("Runtime type not set for struct \(self): \(name)"), sourceLocatable: location)  
    }
    
    public override func archive(data: SCLData) throws {
        //this call is only valid if we are not the root
        if data.isRoot {
            throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("StructOrClassType archive called"), sourceLocatable: location)
        }
       
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true
        
        if genericWhere != nil {
            data.writeBool(true)
            try genericWhere!.archive(data:data)
        }
        else {data.writeBool(false)}
        
        if typeInheritanceClause != nil {
            data.writeBool(true)
            try typeInheritanceClause!.archive(data:data)
        }
        else {data.writeBool(false)}

        data.writeWord(UInt16(members.count)) 
        for m in members {
            switch m {
                case .general(let ast):
                    data.writeWord(0)
                    try ast.archive(data: data)
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
                //case compilerControl(CompilerControlStatement)
            }
        }

        if vtable != nil {
            data.writeBool(true)
            data.writeInt(vtable!.count)
            for vt in vtable! {
                data.writeString(vt.0)
                data.writeByte(vt.1)
            }
        }
        else {data.writeBool(false)}
        
        if mangledName != nil {
            data.writeBool(true)
            data.writeString(mangledName!)
        }
        else {data.writeBool(false)}

        data.isRoot=root
    }
    
    public static func StructOrClassTypeunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i=instance != nil ? instance as! StructOrClassType : try ASTFromTag(data: data) as! StructOrClassType
        
        try GenericType.GenericTypeunarchive(data: data, instance: i)

        if data.readBool() {
            i.genericWhere=(try ASTFromTag(data: data) as! ASTGenericWhereClause)
        }

        if data.readBool() {
            i.typeInheritanceClause=(try ASTFromTag(data: data) as! ASTTypeInheritanceClause)
        }

        let c=Int(data.readWord())
        for _ in 0..<c {
            let k=data.readWord()

            if k==0 {
                let m=try ASTFromTag(data: data)
                i.members.append(.general(m))
            }
            else if k==1 {
                let m=(try ASTFromTag(data: data) as! PropertyMember)
                i.members.append(.property(m))
            }
            else if k==2 {
                let m=(try ASTFromTag(data: data) as! MethodMember)
                i.members.append(.method(m))
            }
            else if k==3 {
                let m=(try ASTFromTag(data: data) as! InitializerMember)
                m.type=i
                i.members.append(.initializer(m))
            }
            else if k==4 {
                let m=(try ASTFromTag(data: data) as! SubscriptMember)
                i.members.append(.`subscript`(m))
            }
            else if k==5 {
                let m=(try ASTFromTag(data: data) as! AssociativityTypeMember)
                i.members.append(.associatedType(m))
            }
        }

        i.context=ASTModule.current.currentScope

        if data.readBool() {
            i.vtable=[]
            let c=data.readInt()
            for _ in 0..<c {
                var vt:(String,UInt8)
                vt.0=data.readString()!
                vt.1=data.readByte()
                i.vtable!.append(vt)}
        }
        
        if data.readBool() {
            i.mangledName=data.readString()!
        }

        return i
    }
    
    public override func hash(into hasher: inout Hasher) {
        super.hash(into:&hasher) 
    }
    
    public override func copy() -> AST {
        let g=generic?.copy() as? ASTGenericParameterClause
        let gw=genericWhere?.copy() as? ASTGenericWhereClause
        let ti=typeInheritanceClause?.copy() as? ASTTypeInheritanceClause
        var cmembers:[Member]=[]
        for m in members {cmembers.append(m.copy() as! Member)}
        return StructOrClassType(name:name, members: cmembers, location: self.location, typeInheritanceClause: ti, generic:g, genericWhere: gw)
    }
    
    public override func replace(name: String, with: AST) -> AST {
        return super.replace(name: name, with: with)
    }
}

public class StructType: StructOrClassType {
    
    public override init() {
        super.init()
    }
    
    public init(name: String, members: [Member], location: SourceLocatable, attributes: [Attribute], accessLevelModifier: Modifier?, 
                typeInheritanceClause: ASTTypeInheritanceClause?, generic:ASTGenericParameterClause?, genericWhere: ASTGenericWhereClause?) {
        super.init(name:name, members: members, location: location, typeInheritanceClause: typeInheritanceClause, generic:generic, genericWhere: genericWhere)
        self.attributes=attributes
        if accessLevelModifier != nil {self.modifiers=[accessLevelModifier!]}
    }
    
    public override func archive(data: SCLData) throws {
        if data.isRoot {
            if try !self.fullArchive(data: data) {return}
            data.writeWord(UInt16(ArchiveType.StructType.rawValue))
        }
        
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true
        
        data.isRoot=root
    }
    
    public static func StructTypeunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i=instance != nil ? instance as! StructType : try ASTFromTag(data: data) as! StructType
        
        try _=StructOrClassType.StructOrClassTypeunarchive(data: data, instance: i)

        return i
    }

    public override func copy() -> AST {
        let g=generic?.copy() as? ASTGenericParameterClause
        let gw=genericWhere?.copy() as? ASTGenericWhereClause
        let ti=typeInheritanceClause?.copy() as? ASTTypeInheritanceClause
        var a:[Attribute]=[]
        for aa in attributes {a.append(aa.copy())}
        var accessLevelModifier: Modifier?=nil
        if modifiers.count>0 {accessLevelModifier=modifiers[0]}
        
        var cmembers:[Member]=[]
        for m in members {cmembers.append(m.copy() as! Member)}
        return StructType(name:name, members: cmembers, location: self.location, attributes: a, accessLevelModifier: accessLevelModifier, 
                          typeInheritanceClause:ti, generic:g, genericWhere: gw)
    }
    
    public override func replace(name: String, with: AST) -> AST {
        return super.replace(name: name, with: with)
    }
}


public class ClassType: StructOrClassType {
    var isFinal:Bool

    public override init() {
        isFinal=false
        super.init()
        runtimeType=class_rt_type
    }
    
    public init(name: String, members: [Member], location: SourceLocatable, isFinal:Bool, attributes: [Attribute], accessLevelModifier: Modifier?, 
                typeInheritanceClause: ASTTypeInheritanceClause?, generic:ASTGenericParameterClause?, genericWhere: ASTGenericWhereClause?) {
        self.isFinal=isFinal
        super.init(name:name, members: members, location: location, typeInheritanceClause: typeInheritanceClause, generic:generic, genericWhere: genericWhere)
        self.attributes=attributes
        if accessLevelModifier != nil {self.modifiers=[accessLevelModifier!]}
        runtimeType=class_rt_type
    }
    
    public override func archive(data: SCLData) throws {
        if data.isRoot {
            if try !self.fullArchive(data: data) {return}
            data.writeWord(UInt16(ArchiveType.ClassType.rawValue))
        }
        
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true
        
        data.writeBool(isFinal)
        
        data.isRoot=root
    }
    
    public static func ClassTypeunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i=instance != nil ? instance as! ClassType : try ASTFromTag(data: data) as! ClassType
        
        try _=StructOrClassType.StructOrClassTypeunarchive(data: data, instance: i)

        i.isFinal=data.readBool()

        return i
    }
    
    public override func copy() -> AST {
        let g=generic?.copy() as? ASTGenericParameterClause
        let gw=genericWhere?.copy() as? ASTGenericWhereClause
        let ti=typeInheritanceClause?.copy() as? ASTTypeInheritanceClause
        var a:[Attribute]=[]
        for aa in attributes {a.append(aa.copy())}
        var accessLevelModifier: Modifier?=nil
        if modifiers.count>0 {accessLevelModifier=modifiers[0]}
        
        var cmembers:[Member]=[]
        for m in members {cmembers.append(m.copy() as! Member)}
        return ClassType(name:name, members: cmembers, location: self.location, isFinal: isFinal, attributes: a, accessLevelModifier: accessLevelModifier, 
                         typeInheritanceClause:ti, generic:g, genericWhere: gw)
    }
    
    public override func replace(name: String, with: AST) -> AST {
        return super.replace(name: name, with: with)
    }
}

public class ProtocolType: StructOrClassType {
    
    public override init() {
        super.init()
        runtimeType=class_rt_type
    }
    
    public init(name:String, members: [Member], location: SourceLocatable, attributes: [Attribute], accessLevelModifier: Modifier?, 
                typeInheritanceClause: ASTTypeInheritanceClause?) {
        super.init(name:name, members: members, location: location, typeInheritanceClause: typeInheritanceClause, generic:nil, genericWhere: nil)
        self.attributes=attributes
        if accessLevelModifier != nil {self.modifiers=[accessLevelModifier!]}
        runtimeType=class_rt_type
    }
    
    public override func archive(data: SCLData) throws {
        if data.isRoot {
            if try !self.fullArchive(data: data) {return}
            data.writeWord(UInt16(ArchiveType.ProtocolType.rawValue))
        }
        
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true
        
        data.isRoot=root
    }
    
    public static func ProtocolTypeunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i=instance != nil ? instance as! ProtocolType : try ASTFromTag(data: data) as! ProtocolType
        
        try _=StructOrClassType.StructOrClassTypeunarchive(data: data, instance: i)

        return i
    }
    
    public override func copy() -> AST {
        var a:[Attribute]=[]
        for aa in attributes {a.append(aa.copy())}
        let ti=typeInheritanceClause?.copy() as? ASTTypeInheritanceClause
        var accessLevelModifier: Modifier?=nil
        if modifiers.count>0 {accessLevelModifier=modifiers[0]}
        
        var cmembers:[Member]=[]
        for m in members {cmembers.append(m.copy() as! Member)}
        return ProtocolType(name:name, members: cmembers, location: self.location,  attributes: a, accessLevelModifier: accessLevelModifier, 
                            typeInheritanceClause: ti)
    }
    
    public override func replace(name: String, with: AST) -> AST {
        return super.replace(name: name, with: with)
    }
}

public class EnumType: StructOrClassType {
    var isIndirect:Bool
    
    public override init() {
        isIndirect=false
        super.init()
        runtimeType=class_rt_type
    }
    
    public init(name: String, members: [Member],  isIndirect: Bool, location: SourceLocatable, attributes: [Attribute], accessLevelModifier: Modifier?, 
                typeInheritanceClause: ASTTypeInheritanceClause?, generic:ASTGenericParameterClause?, genericWhere: ASTGenericWhereClause?) {
        self.isIndirect=isIndirect
        super.init(name:name, members: members, location: location, typeInheritanceClause: typeInheritanceClause, generic:generic, genericWhere: genericWhere)
        self.attributes=attributes
        if accessLevelModifier != nil {self.modifiers=[accessLevelModifier!]}
        runtimeType=class_rt_type
    }
    
    public override func archive(data: SCLData) throws {
        if data.isRoot {
            if try !self.fullArchive(data: data) {return}
            data.writeWord(UInt16(ArchiveType.EnumType.rawValue))
        }
        
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true
        
        data.writeBool(isIndirect)
        
        data.isRoot=root
    }
    
    public static func EnumTypeunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i: EnumType = instance != nil ? instance as! EnumType : try ASTFromTag(data: data) as! EnumType
        
        try _=StructOrClassType.StructOrClassTypeunarchive(data: data, instance: i)

        i.isIndirect=data.readBool()

        return i
    }

    public override func copy() -> AST {
        let g=generic?.copy() as? ASTGenericParameterClause
        let gw=genericWhere?.copy() as? ASTGenericWhereClause
        let ti=typeInheritanceClause?.copy() as? ASTTypeInheritanceClause
        var a:[Attribute]=[]
        for aa in attributes {a.append(aa.copy())}
        var accessLevelModifier: Modifier?=nil
        if modifiers.count>0 {accessLevelModifier=modifiers[0]}
        
        var cmembers:[Member]=[]
        for m in members {cmembers.append(m.copy() as! Member)}
        return EnumType(name:name, members: cmembers, isIndirect: isIndirect, location: self.location, attributes: a, accessLevelModifier: accessLevelModifier, 
                        typeInheritanceClause:ti, generic:g, genericWhere: gw)
    }
    
    public override func replace(name: String, with: AST) -> AST {
        return super.replace(name: name, with: with)
    }
}


public class DictionaryType: ASTType {
    public var key: ASTType
    public var value: ASTType

    public override init() {
        key=ASTType()
        value=ASTType()
        super.init()
    }
    
    public init(name: String, key: ASTType, value: ASTType, location: SourceLocatable, attributes: [Attribute], accessLevelModifier: Modifier?) {
        self.key=key
        self.value=value
        super.init(name:name, location: location)
        self.attributes=attributes
        if accessLevelModifier != nil {self.modifiers=[accessLevelModifier!]}
        runtimeType=dictionary_rt_type
    }
    
    public override func archive(data: SCLData) throws {
        if data.isRoot {
            if try !self.fullArchive(data: data) {return}
            data.writeWord(UInt16(ArchiveType.DictionaryType.rawValue))
        }
        
        let root=data.isRoot
        data.isRoot=false
        try super.archive(data: data)
        data.isRoot=true
        
        try key.archive(data: data)
        try value.archive(data: data)
        
        data.isRoot=root
    }
    
    public static func DictionaryTypeunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        let i: DictionaryType=instance != nil ? instance as! DictionaryType : try ASTFromTag(data: data) as! DictionaryType
        
        try _=ASTType.ASTTypeunarchive(data: data, instance: i)

        i.key=try ASTFromTag(data: data) as! ASTType
        i.value=try ASTFromTag(data: data) as! ASTType

        return i 
    }

    public override func copy() -> AST {
        var a:[Attribute]=[]
        for aa in attributes {a.append(aa.copy())}
        var accessLevelModifier: Modifier?=nil
        if modifiers.count>0 {accessLevelModifier=modifiers[0]}
        
        return DictionaryType(name:name, key: key.copy() as! ASTType, value: value.copy() as! ASTType, 
                              location: self.location, attributes: a, accessLevelModifier: accessLevelModifier) 
    }
    
    public override func replace(name: String, with: AST) -> AST {
        return super.replace(name: name, with: with) //??
    }
}















