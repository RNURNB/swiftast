import Foundation
import SwiftAST

public class Scope: ASTBase, Identifiable {
    public var declaredTypes:[String:ASTType]=[:]
    public var declaredVars:[String:Variable]=[:]
    public var declaredFuncs:[String:[FunctionDeclaration]]=[:]
    public var declaredScopes:[String:Scope]=[:]
    public var origin:AST?=nil
    public var ast:AST?=nil
    public var index:Int = -1 //archiving/unarchiving index
    var typesLocked:Bool=false
    public let id=UUID()
    public var context:Scope?=nil //runtime only
    
    public override init() {
        super.init()
    }
    
    public init(parent:Scope?) {
        super.init(file:-1, line: -1, column: -1)
        self.parent=parent
    }
    
    public init(parent:Scope?, location:SourceLocatable) {
        super.init(location:location)
        self.parent=parent
    }
    
    public override func archive(data: SCLData) throws {
        //this call is only valid if we are not the root
        if data.isRoot {
            throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("Scope archive called for \(type(of:self))"), sourceLocatable: location)
        }
        
        try super.archive(data:data)
    }
    
    public func checkAccessLevel(name: String, id: ASTBase, location: SourceLocatable, raiseError: Bool=true) throws -> Bool {
        if let _=id.modifiers.firstIndex(of:.`private`) {
            if let s=declaredScopes[name] {
                if let m = s as? ASTModule {
                    //if private on module level, module must be current
                    if m.name != ASTModule.current.name {
                        if !raiseError {return false}
                        throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.inaccessibleElement(name,"private"), sourceLocatable: location)
                    }
                }
                else {
                    //if private on scope level, scope must be on stack
                    var s1:Scope?=self
                    var ok=false
                    while s1 != nil {
                        if s.id==s1!.id {ok=true;break}
                        s1=s1!.parent
                    }
                    if !ok {
                        if !raiseError {return false}
                        throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.inaccessibleElement(name,"private"), sourceLocatable: location)
                    }
                }
            }
        }
        
        if let _=id.modifiers.firstIndex(of:.fileprivate) {
            if let s=declaredScopes[name] {
                //if fileprivate, file must be current, means modules must match too
                var ss:Scope?=s
                while !(ss is ASTModule) {
                    ss=ss!.parent
                    if ss==nil {
                        if !raiseError {return false}
                        throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.inaccessibleElement(name,"fileprivate"), sourceLocatable: location)
                    }
                }
                let m=ss as! ASTModule
                if m.name != ASTModule.current.name {
                    if !raiseError {return false}
                    throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.inaccessibleElement(name,"fileprivate"), sourceLocatable: location)
                }
                
                if id.location.filename != location.sourceLocation.identifier {
                    if !raiseError {return false}
                    throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.inaccessibleElement(name,"fileprivate"), sourceLocatable: location)
                }
            }
        }
        
        if let _=id.modifiers.firstIndex(of:.internal) {
            if let s=declaredScopes[name] {
                //if internal, module must be current
                var ss:Scope?=s
                while !(ss is ASTModule) {
                    ss=ss!.parent
                    if ss==nil {
                        if !raiseError {return false}
                        throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.inaccessibleElement(name,"fileprivate"), sourceLocatable: location)
                    }
                }
                let m=ss as! ASTModule
                if m.name != ASTModule.current.name {
                    if !raiseError {return false}
                    throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.inaccessibleElement(name,"fileprivate"), sourceLocatable: location)
                }
            }
        }

        return true
    }
    
    public static func Scopeunarchive(data: SCLData, instance:AST?=nil) throws -> AST {
        if instance==nil {
            throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("Scope unarchive called for \(type(of:self))"), sourceLocatable: SourceLocation(identifier: "", line: -1, column: -1))
        }
        
        return try ASTBase.unarchive(data:data, instance: instance)
    }

    public func SpecializeFunction(_ f: FunctionDeclaration, genericArgs ga:[ASTType], location: SourceLocatable) throws -> FunctionDeclaration {
        //print("SpecializeFunction \(f) with genericArgs:",ga," and parameters:",f.genericParameterClause)

        if ga.count==0  {
           throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.missingSpecializationFuncArguments(f.name), sourceLocatable: location)
        }
                
        if f.genericParameterClause == nil || f.genericParameterClause!.parameterList.count == 0 {
            throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.cannotSpecializeNonGenericFunc(f.name), sourceLocatable: location)
        }
                
        if f.genericParameterClause!.parameterList.count != ga.count {
            throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.illegalNumberOfFuncSpecializationArguments(f.name), sourceLocatable: location)
        }
                
        var idx=0
        var n=f.name+"<"
        for gaa in ga {n=n+gaa.name+","}
        n.removeLast()
        n=n+">"
        if let ff=try f.parent?.findFunc(name: n, location:location, genericArgs:nil, recurse: false) {
            //already specialized for these args in this scope
            //return r
            if ff.count != 1 {
                //mehrdeutig
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.illegalNumberOfFuncSpecializationArguments(n), sourceLocatable: location)
            }
            return ff[0]
        } 
            
        var af=f.copy() as! FunctionDeclaration
        af.name=n
        af.genericParameterClause=nil
                
        for gp in f.genericParameterClause!.parameterList {
            let repl=ga[idx]
                    
            switch gp {
                case .identifier(let identifier):
                    //replace ident
                    //print("replace ",identifier," with ",repl," in ",assignment)
                    af=af.replace(name: identifier,with: repl) as! FunctionDeclaration
                case .typeConformance(let identifier, let type):
                    //replace ident and check for type conformance
                    af=af.replace(name: identifier,with: repl) as! FunctionDeclaration
                case .protocolConformance(let identifier, let proto):
                    //replace ident and check for protocol conformance
                    af=af.replace(name: identifier,with: repl) as! FunctionDeclaration
            }
                        
            idx=idx+1
        }

        //print("Adding generic specialized type ",n,":",assignment)
        try f.parent!.declareFunc(function: af)
        af.needsDecl=false

        return af
    }
    
    public func findFunc(name: String, location: SourceLocatable, genericArgs: [[ASTType]]? = nil, recurse:Bool=true) throws -> [FunctionDeclaration]? {
        //print("try find var '",name,"' in ",self)
        
        let n=name
        if let i=n.firstIndex(of:".") {
            //check for . (class local type)?
            //call findType with recurse false
            let t=String(n[..<i])
            var n=String(n[i...])
            n.removeFirst()
            let type=try findType(name:t, location: location, genericArgs: nil, recurse: false)
            
            if type != nil {try _=checkAccessLevel(name: t, id: type!, location: location)}
            
            //print("found type: ",type," with decl:",type?.decl," finding \(n) in ", type?.decl?.declaredFuncs)
            
            return try type?.decl?.findFunc(name: n, location: location, genericArgs: genericArgs, recurse: false)
        }
        
        if var result=declaredFuncs[n] {
            //check result access level
            var r:[FunctionDeclaration]=[]
            let hasGenericArgs:Bool=false
            for f in result {
                //print("found func:",f.name," with params ",f.genericParameterClause)

                if !(try checkAccessLevel(name: n, id: f, location: location, raiseError: false)) {
                    //remove func from result
                }
                else 
                {
                    if genericArgs==nil && f.genericParameterClause==nil {
                        r.append(f)
                    }
                    else if genericArgs != nil && f.genericParameterClause != nil {
                        if genericArgs!.count==0 || genericArgs![0].count==0 {
                            continue //ignore
                        }
                        if genericArgs![0].count==f.genericParameterClause!.parameterList.count {r.append(f)}
                    }
                    else if f.genericParameterClause != nil {
                        //throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.missingSpecializationFuncArguments(f.name), sourceLocatable: location)
                        //still append, since parameter specialisation may happen later
                        r.append(f)
                    }
                    //else remove func from result, no matching generic args
                }
            }
            result=r
            if result.count==0 //all candidates are invisible 
            {
                if !recurse {return nil}
        
                //recursive parent search for type
                return try parent?.findFunc(name: n, location:location, genericArgs: genericArgs)
            }
            
            if genericArgs==nil /*&& result.genericParameterClause==nil*/ {
                return result
            }
              
            r=[]
            //TODO this needs to be reworked to throw a error, if the last candidate function fails instead of returning nil
            for f in result {
                guard let ga=genericArgs else {
                    if recurse==false {return result} //only a query
                    throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.missingSpecializationFuncArguments(n), sourceLocatable: location)
                }

                if ga.count==0 || ga[0].count==0 {
                    throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.missingSpecializationFuncArguments(n), sourceLocatable: location)
                }

                if f.genericParameterClause == nil || f.genericParameterClause!.parameterList.count == 0 {
                    continue //ignore this func
                    //throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.cannotSpecializeNonGenericFunc(n), sourceLocatable: location)
                }
                
                if f.genericParameterClause!.parameterList.count != ga[0].count {
                    continue //ignore this func
                    //throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.illegalNumberOfFuncSpecializationArguments(n), sourceLocatable: location)
                }
         
                let af=try SpecializeFunction(f, genericArgs: ga[0], location: location)
                r.append(af)
            }

            return r.count > 0 ? r : nil
        }
        
        if !recurse {return nil}
        
        //recursive parent search for type
        return try parent?.findFunc(name: n, location:location, genericArgs: genericArgs)
    }
    
    public func findVar(name: String, location: SourceLocatable, recurse:Bool=true) throws -> Variable? {
        //print("try find var '",name,"' in ",self)
        
        let n=name
        if let i=n.firstIndex(of:".") {
            //check for . (class local type)?
            //call findType with recurse false
            let t=String(n[..<i])
            var n=String(n[i...])
            n.removeFirst()
            let type=try findType(name:t, location: location, genericArgs: nil, recurse: false)
            
            if type != nil {try _=checkAccessLevel(name: t, id: type!, location: location)}
            
            //print("found type: ",type," with decl:",type?.decl)
            
            return try type?.decl?.findVar(name: n, location: location, recurse: false)
        }
        
        if let result=declaredVars[n] {
            //check result access level
            try _=checkAccessLevel(name: n, id: result, location: location)

            return result
        }
        
        if !recurse {return nil}
        
        //recursive parent search for type
        return try parent?.findVar(name: n, location:location)
    }
    
    public func findType(name: String, location: SourceLocatable, genericArgs: [[ASTType]]? = nil, recurse:Bool=true) throws -> ASTType? {
        //print("try find type '",name,"' in ",self)
        
        let n=name
        if let i=n.firstIndex(of:".") {
            //check for . (class local type)?
            //call findType with recurse false
            let t=String(n[..<i])
            var n=String(n[i...])
            n.removeFirst()
            let type=try findType(name:t, location: location, genericArgs: nil, recurse: false)
            
            if type != nil {try _=checkAccessLevel(name: t, id: type!, location: location)}
            
            //print("found type: ",type," with decl:",type?.decl)
            
            return try type?.decl?.findType(name: n, location: location, genericArgs: genericArgs, recurse: false)
        }
        
        if let result=declaredTypes[n] {
            //check result access level
            try _=checkAccessLevel(name: n, id: result, location: location)

            //if result has generic args, we must have parameters
            //print("found:",n)
            
            if let gt=result as? AliasType {
                if gt.dummy {return result}
                
                if genericArgs==nil && gt.generic==nil {
                    return gt/*.assignment*/
                }
                
                guard let ga=genericArgs else {
                    if recurse==false {return gt} //only a query
                    throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.missingSpecializationArguments(n), sourceLocatable: location)
                }
                
                if ga.count==0 || ga[0].count==0 {
                    throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.missingSpecializationArguments(n), sourceLocatable: location)
                }
                
                if gt.generic == nil || gt.generic!.parameterList.count == 0 {
                    throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.cannotSpecializeNonGenericType(n), sourceLocatable: location)
                }
                
                if gt.generic!.parameterList.count != ga[0].count {
                    throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.illegalNumberOfSpecializationArguments(n), sourceLocatable: location)
                }
                
                var idx=0
                var assignment=gt.assignment.copy() as! ASTType
                var n=n+"<"
                for gaa in ga[0] {n=n+gaa.name+","}
                n.removeLast()
                n=n+">"
                if let r=try self.findType(name: n, location:location, genericArgs:nil, recurse: false) {
                    //already specialized for these args in this scope
                    if let a=r as? AliasType, a.generic==nil {return a.assignment}
                    return r
                } 
                
                for gp in gt.generic!.parameterList {
                    let repl=ga[0][idx]
                    
                    switch gp {
                        case .identifier(let identifier):
                            //replace ident
                            //print("replace ",identifier," with ",repl," in ",assignment)
                            assignment=assignment.replace(name: identifier,with: repl) as! ASTType
                        case .typeConformance(let identifier, let type):
                            //replace ident and check for type conformance
                            assignment=assignment.replace(name: identifier,with: repl) as! ASTType
                        case .protocolConformance(let identifier, let proto):
                            //replace ident and check for protocol conformance
                            assignment=assignment.replace(name: identifier,with: repl) as! ASTType
                    }
                    
                    idx=idx+1
                }
                //print("Adding generic specialized type ",n,":",assignment)
                let at=AliasType(name:n, attributes: gt.attributes, modifiers: gt.modifiers, location: location, assignment: assignment, generic: nil)
                try ASTModule.current.declareType(type: at)
                at.needsDecl=false
                
                return assignment
            }
            else if genericArgs != nil && genericArgs!.count>0 {
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.cannotSpecializeNonGenericType(n), sourceLocatable: location)
            }
            
            return result
        }
        
        if !recurse {return nil}
        
        //recursive parent search for type
        return try parent?.findType(name: n, location:location, genericArgs: genericArgs)
    }
    
    open func addType(type: ASTType) throws {
        if !typesLocked {
            try parent?.addType(type: type) //until we find a module
        }
    }
    
    open func declareType(type: ASTType) throws {
        //check if already declared
        /*if type.module != nil {
            if try type.module!.findType(name: type.name, location: type.location, genericArgs: nil, recurse:false) != nil {
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.invalidRedeclaration(type.name), sourceLocatable: type.location)
            }
        }*/
        if try ASTModule.current.currentScope.findType(name: type.name, location: type.location, genericArgs: nil, recurse:false) != nil {
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.invalidRedeclaration(type.name), sourceLocatable: type.location)
        }
        if try ASTModule.current.currentScope.findVar(name: type.name, location: type.location, recurse:false) != nil {
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.invalidRedeclaration(type.name), sourceLocatable: type.location)
        }
        if try ASTModule.current.currentScope.findFunc(name: type.name, location: type.location, genericArgs: nil, recurse:false) != nil {
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.invalidRedeclaration(type.name), sourceLocatable: type.location)
        }

        type.parent=self
        declaredTypes[type.name]=type
        declaredScopes[type.name]=self
    }
    
    open func declareVar(variable: Variable) throws {
        //check if already declared
        /*if type.module != nil {
            if try type.module!.findType(name: type.name, location: type.location, genericArgs: nil, recurse:false) != nil {
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.invalidRedeclaration(type.name), sourceLocatable: type.location)
            }
        }*/
        if try ASTModule.current.currentScope.findVar(name: variable.name, location: variable.location, recurse:false) != nil {
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.invalidRedeclaration(variable.name), sourceLocatable: variable.location)
        }
        if try ASTModule.current.currentScope.findType(name: variable.name, location: variable.location, genericArgs: nil, recurse:false) != nil {
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.invalidRedeclaration(variable.name), sourceLocatable: variable.location)
        }
        if try ASTModule.current.currentScope.findFunc(name: variable.name, location: variable.location, genericArgs: nil, recurse:false) != nil {
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.invalidRedeclaration(variable.name), sourceLocatable: variable.location)
        }
        
        variable.parent=self
        declaredVars[variable.name]=variable
        declaredScopes[variable.name]=self
    }
    
    open func declareFunc(function: FunctionDeclaration) throws {
        //check if already declared
        /*if type.module != nil {
            if try type.module!.findType(name: type.name, location: type.location, genericArgs: nil, recurse:false) != nil {
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.invalidRedeclaration(type.name), sourceLocatable: type.location)
            }
        }*/
        if try ASTModule.current.currentScope.findFunc(name: function.name, location: function.location, genericArgs: nil, recurse:false) != nil {
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.invalidRedeclaration(function.name), sourceLocatable: function.location)
        }
        if try ASTModule.current.currentScope.findVar(name: function.name, location: function.location, recurse:false) != nil {
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.invalidRedeclaration(function.name), sourceLocatable: function.location)
        }
        if try ASTModule.current.currentScope.findType(name: function.name, location: function.location, genericArgs: nil, recurse:false) != nil {
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.invalidRedeclaration(function.name), sourceLocatable: function.location)
        }

        var ff=declaredFuncs[function.name]
        if ff==nil {ff=[function]}
        else {ff!.append(function)}
        
        function.parent=self
        declaredFuncs[function.name]=ff!
        declaredScopes[function.name]=self
    }
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateScope(self)}
}

public class ASTModule: Scope, CustomStringConvertible {
    public var name: String
    var scopes:[Scope]=[]
    public var currentScope:Scope {scopes.last ?? self}
    var files:[String:Int]=[:] //source files
    var filesmap:[Int:String]=[:]
    var imports:[String:ImportDeclaration]=[:]
    var types:[ASTType]=[]
    //var modules:[ASTModule]=[] //imported modules
    
    public static var current:ASTModule {BinAST.currentModule}
    
    public var description: String {return "module "+name}
    
    public init(name: String, parent:Scope?=nil) {
        self.name=name
        super.init(parent:parent)
    }
    
    static func assert(_ value:Bool, msg:String) throws {
        if !value {
            throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("module assertion failed: \(msg)"), sourceLocatable: SourceLocation(identifier: "", line: -1, column: -1))
        }
    }
    
    public func pushScope(origin: AST) {
        let s=Scope(parent:currentScope)
        s.origin=origin
        scopes.append(s)
    }
    
    public func pushScope(scope: Scope, origin: AST) {
        scope.parent=currentScope
        scope.origin=origin
        scopes.append(scope)
    }
    
    public func popScope() {
        scopes.last?.declaredTypes=[:]
        scopes.last?.declaredVars=[:]
        scopes.last?.declaredScopes=[:]
        scopes.removeLast()
    }
    
    public override func addType(type: ASTType) throws {
        if typesLocked {return}
        
        //double check
        if type.module != nil {
            throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("ASTModule added duplicate type \(type). already added in module \(type.module!.name)"), sourceLocatable: type.location)
        }
        type.module=self
        types.append(type)
    }
    
    public override func declareType(type: ASTType) throws {
        if currentScope is ASTModule {
            /*if type.module != nil {
                if try type.module!.findType(name: type.name, location: type.location, genericArgs: nil, recurse:false) != nil {
                    throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.invalidRedeclaration(type.name), sourceLocatable: type.location)
                }
            }*/
            if try currentScope.findType(name: type.name, location: type.location, genericArgs: nil, recurse:false) != nil {
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.invalidRedeclaration(type.name), sourceLocatable: type.location)
            }
            if try currentScope.findFunc(name: type.name, location: type.location, genericArgs: nil, recurse:false) != nil {
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.invalidRedeclaration(type.name), sourceLocatable: type.location)
            }
            if try currentScope.findVar(name: type.name, location: type.location, recurse:false) != nil {
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.invalidRedeclaration(type.name), sourceLocatable: type.location)
            }
            
            type.parent=self.currentScope
            declaredTypes[type.name]=type
            declaredScopes[type.name]=self
            return
        }
        try currentScope.declareType(type: type)
    }
    
    public override func declareVar(variable: Variable) throws {
        if currentScope is ASTModule {
            if try currentScope.findVar(name: variable.name, location: variable.location, recurse:false) != nil {
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.invalidRedeclaration(variable.name), sourceLocatable: variable.location)
            }
            if try currentScope.findFunc(name: variable.name, location: variable.location, genericArgs: nil, recurse:false) != nil {
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.invalidRedeclaration(variable.name), sourceLocatable: variable.location)
            }
            if try currentScope.findType(name: variable.name, location: variable.location, genericArgs: nil, recurse:false) != nil {
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.invalidRedeclaration(variable.name), sourceLocatable: variable.location)
            }
            
            variable.parent=self.currentScope
            declaredVars[variable.name]=variable
            declaredScopes[variable.name]=self
            return
        }
        try currentScope.declareVar(variable: variable)
    }
    
    public override func declareFunc(function: FunctionDeclaration) throws {
        if currentScope is ASTModule {
            if try currentScope.findFunc(name: function.name, location: function.location, genericArgs: nil, recurse:false) != nil {
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.invalidRedeclaration(function.name), sourceLocatable: function.location)
            }
            if try currentScope.findVar(name: function.name, location: function.location, recurse:false) != nil {
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.invalidRedeclaration(function.name), sourceLocatable: function.location)
            }
            if try currentScope.findType(name: function.name, location: function.location, genericArgs: nil, recurse:false) != nil {
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.invalidRedeclaration(function.name), sourceLocatable: function.location)
            }

            var ff=declaredFuncs[function.name]
            if ff==nil {ff=[function]}
            else {ff!.append(function)}
            
            function.parent=self.currentScope
            declaredFuncs[function.name]=ff!
            declaredScopes[function.name]=self
            return
        }
        try currentScope.declareFunc(function: function)
    }
    
    public func addImport(module: String, location: SourceLocatable, kind:String?=nil, name:String?=nil) throws -> ImportDeclaration {
        var m=imports[module]
        if m != nil {
            if m!.imports != nil {
                if kind == nil {m!.imports=nil} //whole module
                else {m!.imports!.append(kind!+"."+name!)}
            }
        }
        else {
            m=ImportDeclaration(module: module, location: location, kind: kind, name: name)
            imports[module]=m!
            
            m!.handle=try doImport(module: module, location: location)

            //add to scope stack
            //print("add scope ",m!.handle!," for ",ASTModule.current.currentScope)
            ASTModule.current.scopes.append(m!.handle!)
        }
        
        return m!
    }
    
    public func archive(path:String) throws {
        let data=SCLData()
        
        //set index for all current modules
        //var i=0
        //for m in modules {m.index=i;i=i+1}
        
        data.writeShortString("BC") //magic
        data.writeWord(1) //version
        data.writeShortString(name)
        
        //write all imports
        data.writeWord(UInt16(imports.count))
        for (m,decl) in imports {
            data.writeShortString(m)
            if decl.handle != nil {
                if decl.handle!.index<0 {
                    throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("Unindexed module: \(m)"), sourceLocatable: decl.location)
                }
                data.writeInt(decl.handle!.index) //0=swift, 1=main, 2.. = imports
            }
            else {data.writeInt(-1)}
            if decl.imports != nil {
                data.writeWord(UInt16(decl.imports!.count))
                for i in decl.imports! {data.writeShortString(i)}
            }
            data.writeWord(0)
        }
        
        //write all files
        data.writeWord(UInt16(files.count))
        for (m,i) in files {
            data.writeShortString(m)
            data.writeInt(i)
        }
        
        let extraofs=data.ofs
        let iextraofs=data.data.index(data.data.startIndex, offsetBy:extraofs)
        //print("write extra ofs ",extraofs)
        data.writeInt(0) //extra data offset, patched later
        
        //clear index for all current types to force archiving
        for t in types {t.index = -1}
        
        //write all decls
        try ast?.archive(data: data)
        
        //patch extra data ofs
        let o=data.ofs
        data.ofs=extraofs
        //print("patch extra ofs ",o," at ",data.ofs)
        //data.writeInt(o)
        let d=SCLData()
        d.writeInt(o)
        //let r=ClosedRange<Data.Index>(min:iextraofs,max:data.data.index(iextraofs,offsetBy:8))
        data.data.replaceSubrange(iextraofs...iextraofs+7,with:d.data)
        data.ofs=o
        data.writeInt(data.extratuples.count)
        for (d,i) in data.extratuples {
            data.writeInt(d.pair.p)
            data.writeInt(d.pair.q)
            data.writeInt(d.pair.r)
            data.writeInt(d.pair.s)
            data.writeInt(i)
        }
        
        try data.save(toFile: path)
    }
    
    func doImport(module: String, location: SourceLocatable) throws -> ASTModule {
        //print("doImport:",module)
        
        //search module list
        //print("import ",module," all modules:",allModules)
        for mm in allModules {
            //print("found module ",module)
            if mm.name == module {return mm}
        }
            
        //execute import
            
        //todo find and import module
        //m!.handle=ASTModule...
        var path=module+".bc"
        if !FileManager.default.fileExists(atPath:path) {
            //ckeck,include dirs
            if let inc=options["-I"] {
                let incs=inc.components(separatedBy:";")
                for i in incs {
                    if FileManager.default.fileExists(atPath:i+"/"+path) {
                        path=i+"/"+path
                        break
                    }
                }
            }
             
            if !FileManager.default.fileExists(atPath:path) {
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.noSuchModule(module), sourceLocatable: location)
            }
        }
        
        let m=try ASTModule.unarchive(path: path)

        //push this on scope stack
        //print("doImport push scope stack:",m)
        //ASTModule.current.scopes.append(m)

        return m
    }
    
    public static func unarchive(path: String) throws -> ASTModule {
        //print("unarchive module:",path)
        
        let data=try SCLData(contentsOfFile: path)
        
        let l=SourceLocation(identifier: "", line: -1, column: -1)
        
        if data.readShortString()! != "BC" {
            throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("bytecode format error in \(path)"), sourceLocatable: l)
        }
        let version=data.readWord()
        data.version=Int(version)
        
        let m=ASTModule(name:data.readShortString()!)
        m.parent=ASTModule.current.currentScope
        
        for mm in allModules {
            if mm.name == m.name {
                throw DiagnosticPool.shared.appendFatal(kind: ParserErrorKind.internalError("duplicate module import \(m.name)"), sourceLocatable: l)
            }
        }
        m.index=allModules.count
        m.parent=ASTModule.current.parent
        allModules.append(m)
        let oldCurrentModule=currentModule
        currentModule=m
        
        //ASTModule.current.scopes.append(m)
        
        //read all imports
        let ic=Int(data.readWord())
        for _ in 0..<ic {
            let n=data.readShortString()!
            let decli=data.readInt()
            
            let decl=ImportDeclaration(module:n, location: l)
            m.imports[n]=decl
            
            let iic=Int(data.readWord())
            for _ in 0..<iic {
                if decl.imports==nil {decl.imports=[]}
                decl.imports!.append(data.readShortString()!)
            }
            
            decl.handle=try m.doImport(module: n, location: l)
            data.importmapping[decli]=decl.handle!
        }
        
        //print("imports processed")
        
        //read all files
        let fc=Int(data.readWord())
        for _ in 0..<fc {
            let n=data.readShortString()!
            let filei=data.readInt()
            m.files[n]=filei
            m.filesmap[filei]=n
        }
        
        //print("files processed")
        
        let extraofs=data.readInt()
        let o=data.ofs
        data.ofs=extraofs
        let tc=data.readInt()
        //print("getting ",tc," extra datas at ofs ",extraofs)
        for _ in 0..<tc {
            let p=data.readInt()
            let q=data.readInt()
            let r=data.readInt()
            let s=data.readInt()
            let i=data.readInt()
            let tuple=DataExt(pair: (p,q,r,s))
            data.extratuplesmap[i]=tuple
        }
        data.ofs=o
        
        //print("extra data processed")
        
        //read all decls
        m.ast=try ASTFromTag(data:data)
        
        //print("exec ast of ",m,":")
        //print(try m.ast?.printTree(execMode:true))
        
        //run all declartionsfor this module
        //print("import runDeclarations for scope ",ASTModule.current)
        try m.ast?.runDeclarations(isTopLevel:true)
        
        //print("exec ast of ",m," after decls:")
        //print(try m.ast?.printTree(execMode:true))
        
        //print("imported module:",m," current=",oldCurrentModule)
        
        oldCurrentModule.parent=m
        currentModule=oldCurrentModule
        //keep module on scope stack, for searching
        //ASTModule.current.scopes.append(m)
        
        return m
    }
    
    public override func generate(delegate: ASTDelegate) throws {try delegate.generateASTModule(self)}
}

























