import Foundation
import SwiftAST
//import Runtime

var allModules:[ASTModule]=[ASTModule(name: "Swift")] //modules (0=Swift, 1=current)
var currentModule: ASTModule = allModules[0]

public var registeredClasses:[String:Any.Type]=[:]

var options:[String:String]=[:]

public func setOption(option:String, value: String) {
    options[option]=value
}

let VoidType=ASTType(swiftType:Void.self, runtimeType:void_rt_type)

let PointerType=ASTType(swiftType:Void.self, runtimeType:pointer_rt_type)

let Int8Type=ASTType(swiftType:Int8.self, runtimeType:int8_rt_type)
let Int16Type=ASTType(swiftType:Int16.self, runtimeType:int16_rt_type)
let Int32Type=ASTType(swiftType:Int32.self, runtimeType:int32_rt_type)
let Int64Type=ASTType(swiftType:Int64.self, runtimeType:int_rt_type)
let IntType=ASTType(swiftType:Int.self, runtimeType:int_rt_type)

let UInt8Type=ASTType(swiftType:UInt8.self, runtimeType:uint8_rt_type)
let UInt16Type=ASTType(swiftType:UInt16.self, runtimeType:uint16_rt_type)
let UInt32Type=ASTType(swiftType:UInt32.self, runtimeType:uint32_rt_type)
let UInt64Type=ASTType(swiftType:UInt64.self, runtimeType:uint_rt_type)
let UIntType=ASTType(swiftType:UInt.self, runtimeType:uint_rt_type)

let FloatType=ASTType(swiftType:Float.self, runtimeType:float_rt_type)
let DoubleType=ASTType(swiftType:Double.self, runtimeType:double_rt_type)

let CharacterType=ASTType(swiftType:Character.self, runtimeType:character_rt_type)
let StringType=ASTType(swiftType:String.self, runtimeType:string_rt_type)

let BoolType=ASTType(swiftType:Bool.self, runtimeType:bool_rt_type)

let TAnyType=ASTType(swiftType:Any.self, runtimeType:pointer_rt_type)

let AnyObjectType=ASTType(swiftType:AnyObject.self, runtimeType:class_rt_type)

let TypeType=ASTType(swiftType:Type.self, runtimeType:type_rt_type)

let AnyTypeType=ASTType(swiftType:AnyType.self, runtimeType:type_rt_type)

public func InitBinASTGenerator() throws {
    if allModules.count != 1 {
        allModules=[ASTModule(name: "Swift")]
    }
    
    options=[:]
    DiagnosticPool.shared.clear()
    
    let swift=allModules[0]
    swift.index=0 //always index 0
    currentModule=swift
    
    //register default types
    try swift.declareType(type:VoidType)

    try swift.declareType(type:Int8Type)
    try swift.declareType(type:Int16Type)
    try swift.declareType(type:Int32Type)
    try swift.declareType(type:Int64Type)
    try swift.declareType(type:IntType)
    try swift.declareType(type:UInt8Type)
    try swift.declareType(type:UInt16Type)
    try swift.declareType(type:UInt32Type)
    try swift.declareType(type:UInt64Type)
    try swift.declareType(type:UIntType)
    try swift.declareType(type:FloatType)
    try swift.declareType(type:DoubleType)
    try swift.declareType(type:CharacterType)
    try swift.declareType(type:StringType)
    try swift.declareType(type:BoolType)
    try swift.declareType(type:AnyObjectType)
    try swift.declareType(type:TypeType)
    try swift.declareType(type:AnyTypeType) //??

    let printsig=FunctionSignature(parameterList:[FunctionSignature.Parameter(externalName: nil, localName: "...", typeAnnotation: ASTTypeAnnotation(type: TAnyType ), isVarargs: true)])
    let printf = FunctionDeclaration(name: "print", body: CodeBlock(), location: ASTLocation(), attributes: [], modifiers: [], 
                                    genericParameterClause: nil, signature: printsig, genericWhereClause: nil)
    printf.context=ASTModule.current
    printf.executor={args in 
        var s:String=""
        for a in args {s=s+"\(a.value)"}
        print(s)
        return runtimeNilValue
    }
    try ASTModule.current.declareFunc(function: printf)
    printf.needsDecl=false
    
    //print("all modules:",allModules)
}

public func generateBinAST(module:String, files:[TopLevelDeclaration]) throws -> AST {
    var result:AST?=nil
    
    let m=ASTModule(name: module, parent:ASTModule.current.currentScope)
    m.parent=ASTModule.current
    m.index=allModules.count
    allModules.append(m)
    currentModule=m
    
    //print("generateBinAST ",module," all modules:",allModules)
    
    let defsl=SourceLocation(identifier: "", line: -1, column: -1)
    
    var previous:AST?=nil
    for file in files {
        var a=try file.ast()
        previous?.next=a
        a.previous=previous
        previous=a
        if result==nil {result=a}
        else if let c=result as? Compound, c.dummy==true {c.children.append(a)}
        else {
            let sl:SourceLocatable?=a as? SourceLocatable
            result=Compound(children: [result!,a], location: sl != nil ? sl! : defsl, dummy:true)
        }
    }
    
    m.ast=result
    
    return result!
}

public func generateBinAST(module:String, file:TopLevelDeclaration) throws -> AST {
    return try generateBinAST(module:module, files:[file])
}

protocol BinASTRepresentable {
  func ast() throws -> AST 
}

func getModifiers(modifiers: DeclarationModifiers) -> [Modifier] {
    var result:[Modifier]=[]
    for m in modifiers {
        switch m {
            case .class: result.append(.class)
            case .convenience: result.append(.convenience)
            case .dynamic: result.append(.dynamic)
            case .final: result.append(.final)
            case .infix: result.append(.infix)
            case .lazy: result.append(.lazy)
            case .optional: result.append(.optional)
            case .override: result.append(.override)
            case .postfix: result.append(.postfix)
            case .prefix: result.append(.prefix)
            case .required: result.append(.required)
            case .static: result.append(.static)
            case .unowned: result.append(.unowned)
            case .unownedSafe: result.append(.unownedSafe)
            case .unownedUnsafe: result.append(.unownedUnsafe)
            case .weak: result.append(.weak)
            case .accessLevel(let modifier):
                switch (modifier) {
                    case .`private`: result.append(.`private`)
                    case .privateSet: result.append(.privateSet)
                    case .`fileprivate`: result.append(.`fileprivate`)
                    case .fileprivateSet: result.append(.fileprivateSet)
                    case .`internal`: result.append(.`internal`)
                    case .internalSet: result.append(.internalSet)
                    case .`public`: result.append(.`public`)
                    case .publicSet: result.append(.publicSet)
                    case .`open`: result.append(.`open`)
                    case .openSet: result.append(.openSet)
                }
            case .mutation(let modifier):
                switch (modifier) {
                    case .mutating: result.append(.mutating)
                    case .nonmutating: result.append(.nonmutating)
                }
        }
    } //for

    return result
}

func getBalancedToken(bt:SwiftAST.Attribute.ArgumentClause.BalancedToken) -> Attribute.ArgumentClause.BalancedToken {
    switch bt {
        case .token(let s):
            return .token(s)
        case .parenthesis(let l):
            var tl:[Attribute.ArgumentClause.BalancedToken]=[]
            for t in l {
                tl.append(getBalancedToken(bt:t))                
            }
            return .parenthesis(tl)
        case .square(let l):
            var tl:[Attribute.ArgumentClause.BalancedToken]=[]
            for t in l {
                tl.append(getBalancedToken(bt:t))                
            }
            return .square(tl)
        case .brace(let l):
            var tl:[Attribute.ArgumentClause.BalancedToken]=[]
            for t in l {
                tl.append(getBalancedToken(bt:t))                
            }
            return .brace(tl)
    }
}

func getAttributes(attributes: SwiftAST.Attributes) -> [Attribute] {
    var result:[Attribute]=[]
    for a in attributes {
        var ac:Attribute.ArgumentClause?=nil
        if a.argumentClause != nil {
            var bt:[Attribute.ArgumentClause.BalancedToken]=[]
            for b in a.argumentClause!.balancedTokens {
                bt.append(getBalancedToken(bt:b))
            }
            ac=Attribute.ArgumentClause(balancedTokens: bt)
        }
        result.append(Attribute(name: a.name.textDescription, argumentClause: ac))
    } //for

    return result
}

func getGetterSetterKeywordBlock(_ gs:SwiftAST.GetterSetterKeywordBlock) -> BinAST.GetterSetterKeywordBlock {
    var mutationModifier: Modifier?=nil
    if gs.getter.mutationModifier != nil {
        switch gs.getter.mutationModifier! {
            case .mutating: mutationModifier = .mutating
            case .nonmutating: mutationModifier = .nonmutating
        }
    }
    let a=getAttributes(attributes: gs.getter.attributes)
    let getter=BinAST.GetterSetterKeywordBlock.GetterKeywordClause(name: nil, block: nil, attributes: a, mutationModifier: mutationModifier)
    var setter:BinAST.GetterSetterKeywordBlock.SetterKeywordClause?=nil
    if gs.setter != nil {
        var mutationModifier: Modifier?=nil
        if gs.setter!.mutationModifier != nil {
            switch gs.setter!.mutationModifier! {
                case .mutating: mutationModifier = .mutating
                case .nonmutating: mutationModifier = .nonmutating
            }
        }
        let a=getAttributes(attributes: gs.setter!.attributes)
        setter=BinAST.GetterSetterKeywordBlock.SetterKeywordClause(name: nil, block: nil, attributes: a, mutationModifier: mutationModifier)
    }
    
    return BinAST.GetterSetterKeywordBlock(getter: getter, setter: setter)
}


extension TopLevelDeclaration : BinASTRepresentable {
  public func ast() throws -> AST { 
    let body = try statements.map { try $0.ast() }

    if body.count==1 {return body[0]}
    return Compound(children:body, location: self, dummy:true)
  }
}


extension ConstantDeclaration : BinASTRepresentable {
  public func ast() throws -> AST { 
      let attrs=getAttributes(attributes: attributes)
      let mod=getModifiers(modifiers: modifiers)
      
      var result:AST=NoOp()
      
      for p in initializerList {
            //print("initializer:",p.initializerExpression)
            if let ip=p.pattern as? IdentifierPattern {
                //print("parse type:",ip.typeAnnotation)

                let tat=try ASTType.get(type:ip.typeAnnotation?.type ?? AnyType())
                let tattrs=ip.typeAnnotation != nil ? getAttributes(attributes: ip.typeAnnotation!.attributes) : []
                let ta=ASTTypeAnnotation(type: tat, attributes: tattrs, isInOutParameter: ip.typeAnnotation != nil ? ip.typeAnnotation!.isInOutParameter : false)

                let v=Variable(name: ip.identifier.textDescription, typeAnnotation: ta, isConstant:true, attributes: attrs, modifiers: mod, location: self)        
                let initializer=try p.initializerExpression?.ast()
                let vv = VariableDeclaration(variable: v, typeAnnotation: ta, isConstant: true, initializer: initializer, attributes: attrs, modifiers: mod, location:self)
                
                try ASTModule.current.declareVar(variable: v)
                vv.needsDecl=false
                
                if let c=result as? Compound {c.children.append(vv)}
                else if result is NoOp {result=vv}
                else {result=Compound(children:[vv], location: self)}
            }
            else {
                throw ASTGenerationError("Unknown AST variable pattern type:\(type(of:self))->\(self) in \(sourceRange.ttyDescription)")
            }
      }
      return result
  }
}

extension SwiftAST.VariableDeclaration : BinASTRepresentable {
  public func ast() throws -> AST { 
     let attrs=getAttributes(attributes: attributes)
     let mod=getModifiers(modifiers: modifiers)
     
     var result:AST=NoOp()

     switch body {
        case .initializerList(let inits):
            for p in inits {
                //print("initializer:",p.initializerExpression)
                if let ip=p.pattern as? IdentifierPattern {
                    //print("parse type:",ip.typeAnnotation)

                    let tat=try ASTType.get(type:ip.typeAnnotation?.type ?? AnyType())
                    let tattrs=ip.typeAnnotation != nil ? getAttributes(attributes: ip.typeAnnotation!.attributes) : []
                    let ta=ASTTypeAnnotation(type: tat, attributes: tattrs, isInOutParameter: ip.typeAnnotation != nil ? ip.typeAnnotation!.isInOutParameter : false)
                    
                    let v=Variable(name: ip.identifier.textDescription, typeAnnotation: ta, isConstant: false, 
                                   attributes: attrs, modifiers: mod, location: self, getterSetterKeywordBlock: nil, willSetDidSetBlock: nil)        
                    let initializer=try p.initializerExpression?.ast()
                    let vv = VariableDeclaration(variable: v, typeAnnotation: ta, isConstant: false, initializer: initializer, 
                                                 attributes: attrs, modifiers: mod, location:self)
                    
                    try ASTModule.current.declareVar(variable: v)
                    vv.needsDecl=false
                    
                    if let c=result as? Compound {c.children.append(vv)}
                    else if result is NoOp {result=vv}
                    else {result=Compound(children:[vv], location: self)}
                }
                else {
                    throw ASTGenerationError("Unknown AST variable pattern type:\(type(of:self))->\(self) in \(sourceRange.ttyDescription)")
                }
            }
        case let .codeBlock(name, typeAnnotation, codeBlock):
            let block=try codeBlock.ast() as! CodeBlock
            //the code block acts as getter
            let tat=try ASTType.get(type:typeAnnotation.type)
            let tattrs=getAttributes(attributes: typeAnnotation.attributes) 
            let ta=ASTTypeAnnotation(type: tat, attributes: tattrs, isInOutParameter: typeAnnotation.isInOutParameter)

            let mutationModifier: Modifier?=nil
            let a=getAttributes(attributes: self.attributes)
            let getter=BinAST.GetterSetterKeywordBlock.GetterKeywordClause(name: nil, block: block, attributes: a, mutationModifier: mutationModifier)
            let gs=BinAST.GetterSetterKeywordBlock(getter: getter, setter: nil)
            
            let v=Variable(name: name.textDescription, typeAnnotation: ta, isConstant: gs.setter==nil, 
                           attributes: [], modifiers: [], location: self, getterSetterKeywordBlock: gs, willSetDidSetBlock: nil)        
            let vv = VariableDeclaration(variable: v, typeAnnotation: ta, isConstant: gs.setter==nil, initializer: nil, 
                                         attributes: attrs, modifiers: mod, location:self)
                    
            try ASTModule.current.declareVar(variable: v)
            vv.needsDecl=false
                    
            if let c=result as? Compound {c.children.append(vv)}
            else if result is NoOp {result=vv}
            else {result=Compound(children:[vv], location: self)}

        case let .getterSetterBlock(name, typeAnnotation, gs):
            let tat=try ASTType.get(type:typeAnnotation.type)
            let tattrs=getAttributes(attributes: typeAnnotation.attributes) 
            let ta=ASTTypeAnnotation(type: tat, attributes: tattrs, isInOutParameter: typeAnnotation.isInOutParameter)

             var mutationModifier: Modifier?=nil
             if gs.getter.mutationModifier != nil {
                switch gs.getter.mutationModifier! {
                    case .mutating: mutationModifier = .mutating
                    case .nonmutating: mutationModifier = .nonmutating
                }
             }
             let a=getAttributes(attributes: gs.getter.attributes)
             let gettercode=try gs.getter.codeBlock.ast() as! CodeBlock
             let getter=BinAST.GetterSetterKeywordBlock.GetterKeywordClause(name: name.textDescription, block: gettercode , attributes: a, mutationModifier: mutationModifier)
             var setter:BinAST.GetterSetterKeywordBlock.SetterKeywordClause?=nil
             if gs.setter != nil {
                var mutationModifier: Modifier?=nil
                if gs.setter!.mutationModifier != nil {
                    switch gs.setter!.mutationModifier! {
                        case .mutating: mutationModifier = .mutating
                        case .nonmutating: mutationModifier = .nonmutating
                    }
                }
                let a=getAttributes(attributes: gs.setter!.attributes)
                let settercode=try gs.setter!.codeBlock.ast() as! CodeBlock
                setter=BinAST.GetterSetterKeywordBlock.SetterKeywordClause(name: gs.setter!.name?.textDescription, block: settercode , attributes: a, mutationModifier: mutationModifier)
             }
    
             let gettersetter = BinAST.GetterSetterKeywordBlock(getter: getter, setter: setter)

             let v=Variable(name: name.textDescription, typeAnnotation: ta, isConstant: gettersetter.setter==nil, 
                           attributes: [], modifiers: [], location: self, getterSetterKeywordBlock: gettersetter, willSetDidSetBlock: nil)        
             let vv = VariableDeclaration(variable: v, typeAnnotation: ta, isConstant: gettersetter.setter==nil, initializer: nil, 
                                         attributes: attrs, modifiers: mod, location:self)
                    
             try ASTModule.current.declareVar(variable: v)
             vv.needsDecl=false
                    
             if let c=result as? Compound {c.children.append(vv)}
             else if result is NoOp {result=vv}
             else {result=Compound(children:[vv], location: self)}

        case let .getterSetterKeywordBlock(name, typeAnnotation, block):
            let tat=try ASTType.get(type:typeAnnotation.type)
            let tattrs=getAttributes(attributes: typeAnnotation.attributes) 
            let ta=ASTTypeAnnotation(type: tat, attributes: tattrs, isInOutParameter: typeAnnotation.isInOutParameter)
            let gs=getGetterSetterKeywordBlock(block)
            
            let v=Variable(name: name.textDescription, typeAnnotation: ta, isConstant: gs.setter==nil, 
                           attributes: [], modifiers: [], location: self, getterSetterKeywordBlock: gs, willSetDidSetBlock: nil)        
            let vv = VariableDeclaration(variable: v, typeAnnotation: ta, isConstant: gs.setter==nil, initializer: nil, 
                                         attributes: attrs, modifiers: mod, location:self)
                    
            try ASTModule.current.declareVar(variable: v)
            vv.needsDecl=false
                    
            if let c=result as? Compound {c.children.append(vv)}
            else if result is NoOp {result=vv}
            else {result=Compound(children:[vv], location: self)}
        case let .willSetDidSetBlock(name, typeAnnotation, initExpr, block):
            let tat=try ASTType.get(type:typeAnnotation?.type ?? AnyType())
            let tattrs=typeAnnotation != nil ? getAttributes(attributes: typeAnnotation!.attributes) : []
            let ta=ASTTypeAnnotation(type: tat, attributes: tattrs, isInOutParameter: typeAnnotation != nil ? typeAnnotation!.isInOutParameter : false)

            var willSetClause:BinAST.WillSetDidSetBlock.WillSetClause?=nil
            if block.willSetClause != nil {
                let a=getAttributes(attributes: block.willSetClause!.attributes)
                willSetClause=BinAST.WillSetDidSetBlock.WillSetClause(attributes: a, name: block.willSetClause!.name?.textDescription, 
                                                                      codeBlock: try block.willSetClause!.codeBlock.ast() as! CodeBlock)
            }
            var didSetClause:BinAST.WillSetDidSetBlock.DidSetClause?=nil
            if block.didSetClause != nil {
                let a=getAttributes(attributes: block.didSetClause!.attributes)
                didSetClause=BinAST.WillSetDidSetBlock.DidSetClause(attributes: a, name: block.didSetClause!.name?.textDescription, 
                                                                    codeBlock: try block.didSetClause!.codeBlock.ast() as! CodeBlock)
            }
    
            let wsds = BinAST.WillSetDidSetBlock(willSetClause: willSetClause, didSetClause: didSetClause)

            let initializer=try initExpr?.ast()

            let v=Variable(name: name.textDescription, typeAnnotation: ta, isConstant: false, 
                           attributes: [], modifiers: [], location: self, getterSetterKeywordBlock: nil, willSetDidSetBlock: wsds)        
            let vv = VariableDeclaration(variable: v, typeAnnotation: ta, isConstant: false, initializer: initializer, 
                                         attributes: attrs, modifiers: mod, location:self)
                    
            try ASTModule.current.declareVar(variable: v)
            vv.needsDecl=false
                    
            if let c=result as? Compound {c.children.append(vv)}
            else if result is NoOp {result=vv}
            else {result=Compound(children:[vv], location: self)}
        default:
            throw ASTGenerationError("Unknown AST variable type:\(type(of:self))->\(self) in \(sourceRange.ttyDescription)")
     }

     return result
  }
}

func getGenericParameterClause(_ gp:GenericParameterClause, olddeclaredTypes:inout [String:ASTType],
                               location: SourceLocatable) throws -> ASTGenericParameterClause? {
          var a:[ASTGenericParameterClause.ASTGenericParameter]=[]
          for g in gp.parameterList {
              switch g {
                  case .identifier(let identifier):
                      let name=identifier.textDescription
                      olddeclaredTypes[name]=ASTModule.current.currentScope.declaredTypes[name]
                      
                      ASTModule.current.currentScope.typesLocked=true //prevent adding to 'types'
                      ASTModule.current.currentScope.declaredTypes[name]=GenericType(name: name, location: location)
                      ASTModule.current.currentScope.typesLocked=false //restore
                      
                      a.append(.identifier(name))
                  case .typeConformance(let identifier, let typeIdentifier):
                      let name=identifier.textDescription
                      olddeclaredTypes[name]=ASTModule.current.currentScope.declaredTypes[name]
                      
                      ASTModule.current.currentScope.typesLocked=true //prevent adding to 'types'
                      ASTModule.current.currentScope.declaredTypes[name]=GenericType(name: name, location: location)
                      ASTModule.current.currentScope.typesLocked=false //restore
                      
                      a.append(.typeConformance(name, try ASTType.get(type: typeIdentifier)))
                  case .protocolConformance(let identifier, let protocolCompositionType):
                      let name=identifier.textDescription
                      olddeclaredTypes[name]=ASTModule.current.currentScope.declaredTypes[name]
                      
                      ASTModule.current.currentScope.typesLocked=true //prevent adding to 'types'
                      ASTModule.current.currentScope.declaredTypes[name]=GenericType(name: name, location: location)
                      ASTModule.current.currentScope.typesLocked=false //restore
                      
                      let p=try ASTType.get(type: protocolCompositionType)
                      //todo check for protocol
                      a.append(.protocolConformance(name, p))
              }
          }
          if a.count>0 {return ASTGenericParameterClause(parameterList:a)}
          return nil
}

func getGenericArgumentClause(_ ga:GenericArgumentClause) throws -> ASTGenericArgumentClause? {
          var a:[ASTType]=[]
          for g in ga.argumentList {
              a.append(try ASTType.get(type: g))
          }
          if a.count>0 {return ASTGenericArgumentClause(argumentList:a)}
          return nil
}

func getGenericWhereClause(_ gw:GenericWhereClause) throws -> ASTGenericWhereClause? {
            var rr:[ASTGenericWhereClause.Requirement]=[]
            for r in gw.requirementList {
                switch r {
                    case .typeConformance(let id1, let id2):    
                        var tn1:[ASTTypeIdentifier.TypeName]=[]
                        for n in id1.names {
                            let name=n.name.textDescription
                            var ga:ASTGenericArgumentClause?=nil
                            if n.genericArgumentClause != nil {ga=try getGenericArgumentClause(n.genericArgumentClause!)}
                            tn1.append(ASTTypeIdentifier.TypeName(name: name, genericArgumentClause: ga))
                        }
                        let ti1=ASTTypeIdentifier(names:tn1)
                        var tn2:[ASTTypeIdentifier.TypeName]=[]
                        for n in id2.names {
                            let name=n.name.textDescription
                            var ga:ASTGenericArgumentClause?=nil
                            if n.genericArgumentClause != nil {ga=try getGenericArgumentClause(n.genericArgumentClause!)}
                            tn2.append(ASTTypeIdentifier.TypeName(name: name, genericArgumentClause: ga))
                        }
                        let ti2=ASTTypeIdentifier(names:tn2)
                        rr.append(.typeConformance(ti1,ti2))
                    case .protocolConformance(let id, let type):
                        var tn:[ASTTypeIdentifier.TypeName]=[]
                        for n in id.names {
                            let name=n.name.textDescription
                            var ga:ASTGenericArgumentClause?=nil
                            if n.genericArgumentClause != nil {ga=try getGenericArgumentClause(n.genericArgumentClause!)}
                            tn.append(ASTTypeIdentifier.TypeName(name: name, genericArgumentClause: ga))
                        }
                        let ti=ASTTypeIdentifier(names:tn)
                        var types:[ASTType]=[]
                        for t in type.protocolTypes {
                            types.append(try ASTType.get(type: t))
                        }
                        rr.append(.protocolConformance(ti,ASTProtocolCompositionType(protocolTypes:types)))
                    case .sameType(let id, let type):
                        var tn:[ASTTypeIdentifier.TypeName]=[]
                        for n in id.names {
                            let name=n.name.textDescription
                            var ga:ASTGenericArgumentClause?=nil
                            if n.genericArgumentClause != nil {ga=try getGenericArgumentClause(n.genericArgumentClause!)}
                            tn.append(ASTTypeIdentifier.TypeName(name: name, genericArgumentClause: ga))
                        }
                        let ti=ASTTypeIdentifier(names:tn)
                        rr.append(.sameType(ti, try ASTType.get(type: type)))
                }
            }

            if rr.count>0 {return ASTGenericWhereClause(requirementList:rr)}
            return nil
}

extension SwiftAST.TypealiasDeclaration : BinASTRepresentable {
  public func ast() throws -> AST { 
      var olddeclaredTypes:[String:ASTType]=[:]
      var generic: ASTGenericParameterClause?=nil
      if self.generic != nil {
          generic=try getGenericParameterClause(self.generic!, olddeclaredTypes:&olddeclaredTypes, location: self)
      }
      let assignment=try ASTType.get(type: self.assignment)
      //restore generic type names
      for (k,v) in olddeclaredTypes {ASTModule.current.currentScope.declaredTypes[k]=v}
      
      var modifiers:[Modifier]=[]
      switch self.accessLevelModifier {
            case .none: _=1
            case .`private`: modifiers.append(.`private`)
            case .privateSet: modifiers.append(.privateSet)
            case .`fileprivate`: modifiers.append(.`fileprivate`)
            case .fileprivateSet: modifiers.append(.fileprivateSet)
            case .`internal`: modifiers.append(.`internal`)
            case .internalSet: modifiers.append(.internalSet)
            case .`public`: modifiers.append(.`public`)
            case .publicSet: modifiers.append(.publicSet)
            case .`open`: modifiers.append(.`open`)
            case .openSet: modifiers.append(.openSet)
      }
      let ta = TypealiasDeclaration(name: self.name.textDescription,assignment: assignment, attributes: getAttributes(attributes:attributes), 
                                  modifiers: modifiers, generic:generic, location:self)
      try ASTModule.current.declareType(type: ta.alias)
      ta.needsDecl=false
      
      return ta
  }
}

func getTypeInheritanceClause(_ ti:SwiftAST.TypeInheritanceClause?) throws -> ASTTypeInheritanceClause? {
      var result:ASTTypeInheritanceClause?=nil
      if ti != nil {
            var til:[ASTTypeIdentifier]=[]
            for id in ti!.typeInheritanceList {
                var tin:[ASTTypeIdentifier.TypeName]=[]
                for n in id.names {
                    let name=n.name.textDescription
                    var ga:ASTGenericArgumentClause?=nil
                    if n.genericArgumentClause != nil {ga=try getGenericArgumentClause(n.genericArgumentClause!)}
                    tin.append(ASTTypeIdentifier.TypeName(name: name, genericArgumentClause: ga))
                }
                til.append(ASTTypeIdentifier(names:tin))
            }
            result=ASTTypeInheritanceClause(classRequirement: ti!.classRequirement, typeInheritanceList: til) 
      }
      return result
}

extension SwiftAST.StructDeclaration : BinASTRepresentable {
  public func ast() throws -> AST { 
      var olddeclaredTypes:[String:ASTType]=[:]

      var generic: ASTGenericParameterClause?=nil
      if self.genericParameterClause != nil {
          generic=try getGenericParameterClause(self.genericParameterClause!,olddeclaredTypes: &olddeclaredTypes, location: self)
      }

      var genericWhere: ASTGenericWhereClause?=nil
      if self.genericWhereClause != nil {
            genericWhere=try getGenericWhereClause(self.genericWhereClause!)
      }

      var accessLevelModifier:Modifier?=nil
      if self.accessLevelModifier != nil {
        switch self.accessLevelModifier {
            case .none: _=1
            case .`private`: accessLevelModifier = .`private`
            case .privateSet: accessLevelModifier = .privateSet
            case .`fileprivate`: accessLevelModifier = .`fileprivate`
            case .fileprivateSet: accessLevelModifier = .fileprivateSet
            case .`internal`: accessLevelModifier = .`internal`
            case .internalSet: accessLevelModifier = .internalSet
            case .`public`: accessLevelModifier = .`public`
            case .publicSet: accessLevelModifier = .publicSet
            case .`open`: accessLevelModifier = .`open`
            case .openSet: accessLevelModifier = .openSet
        }
      }

      let ti=try getTypeInheritanceClause(typeInheritanceClause)
      
      //append dummy scope
      ASTModule.current.pushScope(origin: self.name.textDescription)
      
      let members:[BinAST.Member]=[]
      for m in self.members {
          switch m {
              case .declaration(let decl):
                  let _=try decl.ast()
                  //print("got struct member:",mm)
              case .compilerControl(let cc):
                  throw ASTGenerationError("todo compilerControlStatement")
          }
      }
      
      //restore scope
      ASTModule.current.popScope()
      
      let s=StructDeclaration(name:self.name.textDescription, members: members, location: self, attributes: getAttributes(attributes:attributes), 
                              accessLevelModifier: accessLevelModifier, typeInheritanceClause: ti, generic:generic, genericWhere: genericWhere)
      s.context=ASTModule.current
      s.impl.context=s.context

      //restore generic type names
      for (k,v) in olddeclaredTypes {ASTModule.current.currentScope.declaredTypes[k]=v}

      for m in members {
           switch m {
            case .general(let ast):
                if let sc = ast as? BinAST.Scope {sc.context=s}
                if let pm=ast as? BinAST.PropertyMember {pm.context=s}
                if let sm=ast as? BinAST.SubscriptMember {sm.context=s}
                if let am=ast as? BinAST.AssociativityTypeMember {am.context=s}
                if let f=ast as? BinAST.FunctionDeclaration {f.context=s}
            case .property(let pm):
                pm.context=s
            case .method(let mm):
                mm.context=s
            case .initializer(let im):
                im.context=s
                im.type=s.impl
            case .`subscript`(let sm):
                sm.context=s
            case .associatedType(let am):
                am.context=s
         }
      }
      
      return s
  }
}

extension SwiftAST.ProtocolDeclaration : BinASTRepresentable {
  public func ast() throws -> AST { 
      var accessLevelModifier:Modifier?=nil
      if self.accessLevelModifier != nil {
        switch self.accessLevelModifier {
            case .none: _=1
            case .`private`: accessLevelModifier = .`private`
            case .privateSet: accessLevelModifier = .privateSet
            case .`fileprivate`: accessLevelModifier = .`fileprivate`
            case .fileprivateSet: accessLevelModifier = .fileprivateSet
            case .`internal`: accessLevelModifier = .`internal`
            case .internalSet: accessLevelModifier = .internalSet
            case .`public`: accessLevelModifier = .`public`
            case .publicSet: accessLevelModifier = .publicSet
            case .`open`: accessLevelModifier = .`open`
            case .openSet: accessLevelModifier = .openSet
        }
      }    

      let ti=try getTypeInheritanceClause(typeInheritanceClause)
      
      var members:[BinAST.Member]=[]
      for m in self.members {
          switch m {
              case .property(let pm):
                  let a=getAttributes(attributes: pm.attributes)
                  let m=getModifiers(modifiers: pm.modifiers)

                  let tat=try ASTType.get(type:pm.typeAnnotation.type)
                  let tattrs=getAttributes(attributes: pm.typeAnnotation.attributes) 
                  let ta=ASTTypeAnnotation(type: tat, attributes: tattrs, isInOutParameter: pm.typeAnnotation.isInOutParameter)
          
                  members.append(.property(BinAST.PropertyMember(name: pm.name.textDescription, typeAnnotation: ta, 
                                           isConstant: false, initializer: nil, location: self, 
                                           getterSetterKeywordBlock: getGetterSetterKeywordBlock(pm.getterSetterKeywordBlock), attributes: a, modifiers: m)))
              case .method(let mm):
                  let a=getAttributes(attributes: mm.attributes)
                  let m=getModifiers(modifiers: mm.modifiers)
                  
                  var olddeclaredTypes:[String:ASTType]=[:]
                  var genericParameter: ASTGenericParameterClause?=nil
                  if mm.genericParameter != nil {
                      genericParameter=try getGenericParameterClause(mm.genericParameter!, olddeclaredTypes:&olddeclaredTypes, location: self)
                  }
                  //restore generic type names
                  for (k,v) in olddeclaredTypes {ASTModule.current.currentScope.declaredTypes[k]=v}
                  
                  var genericWhere: ASTGenericWhereClause?=nil
                  if mm.genericWhere != nil {
                      genericWhere=try getGenericWhereClause(mm.genericWhere!)
                  }
                  
                  let parameterList=try getParameterList(mm.signature.parameterList)
                  var tk: ThrowsKind
                  switch mm.signature.throwsKind {
                      case .nothrowing: tk = .nothrowing
                      case .throwing: tk = .throwing
                      case .rethrowing: tk = .rethrowing
                  }
                  
                  var result:FunctionResult? = nil
                  if mm.signature.result != nil {
                      let ra=getAttributes(attributes: mm.signature.result!.attributes)
                      result=FunctionResult(attributes:ra, type: try ASTType.get(type: mm.signature.result!.type))
                  }
                  let signature=FunctionSignature(parameterList: parameterList, throwsKind: tk, result:result)
                  
                  members.append(.method(BinAST.MethodMember(name: mm.name.textDescription, body: nil, location: self, attributes: a, modifiers: m, 
                                         genericParameter: genericParameter, signature: signature, 
                                         genericWhere: genericWhere)))
              case .initializer(let im):
                  let a=getAttributes(attributes: im.attributes)
                  let m=getModifiers(modifiers: im.modifiers)
                  
                  let parameterList=try getParameterList(im.parameterList)
                  
                  var tk: ThrowsKind
                  switch im.throwsKind {
                      case .nothrowing: tk = .nothrowing
                      case .throwing: tk = .throwing
                      case .rethrowing: tk = .rethrowing
                  }
                  
                  var ik:InitializerDeclaration.InitKind
                  switch im.kind {
                      case .nonfailable: ik = .nonfailable
                      case .optionalFailable: ik = .optionalFailable
                      case .implicitlyUnwrappedFailable: ik = .implicitlyUnwrappedFailable
                  }
                  
                  var olddeclaredTypes:[String:ASTType]=[:]
                  var genericParameter: ASTGenericParameterClause?=nil
                  if im.genericParameter != nil {
                      genericParameter=try getGenericParameterClause(im.genericParameter!, olddeclaredTypes:&olddeclaredTypes, location: self)
                  }
                  //restore generic type names
                  for (k,v) in olddeclaredTypes {ASTModule.current.currentScope.declaredTypes[k]=v}
                  
                  var genericWhere: ASTGenericWhereClause?=nil
                  if im.genericWhere != nil {
                      genericWhere=try getGenericWhereClause(im.genericWhere!)
                  }
                  
                  members.append(.initializer(BinAST.InitializerMember(body:nil, location: self, attributes: a, modifiers: m,
                                              kind: ik, genericParameter: genericParameter,
                                              parameterList: parameterList, throwsKind: tk,
                                              genericWhere: genericWhere)))
              case .`subscript`(let sm):
                  let a=getAttributes(attributes: sm.attributes)
                  let m=getModifiers(modifiers: sm.modifiers)
                  
                  var olddeclaredTypes:[String:ASTType]=[:]
                  var genericParameter: ASTGenericParameterClause?=nil
                  if sm.genericParameter != nil {
                      genericParameter=try getGenericParameterClause(sm.genericParameter!, olddeclaredTypes:&olddeclaredTypes, location: self)
                  }
                  //restore generic type names
                  for (k,v) in olddeclaredTypes {ASTModule.current.currentScope.declaredTypes[k]=v}
                  
                  var genericWhere: ASTGenericWhereClause?=nil
                  if sm.genericWhere != nil {
                      genericWhere=try getGenericWhereClause(sm.genericWhere!)
                  }
                  
                  let parameterList=try getParameterList(sm.parameterList)
                  
                  let resultAttributes=getAttributes(attributes: sm.resultAttributes)
                  
                  members.append(.subscript(BinAST.SubscriptMember(resultType: try ASTType.get(type: sm.resultType), location: self, attributes: a, modifiers: m, 
                                            genericParameter: genericParameter, parameterList: parameterList,
                                            resultAttributes: resultAttributes, genericWhere: genericWhere,
                                            getterSetterKeywordBlock: getGetterSetterKeywordBlock(sm.getterSetterKeywordBlock))))
              case .associatedType(let am):
                  let a=getAttributes(attributes: am.attributes)
                  var accessLevelModifier:Modifier?=nil
                  if am.accessLevelModifier != nil {
                      switch am.accessLevelModifier! {
                        case .`private`: accessLevelModifier = .`private`
                        case .privateSet: accessLevelModifier = .privateSet
                        case .`fileprivate`: accessLevelModifier = .`fileprivate`
                        case .fileprivateSet: accessLevelModifier = .fileprivateSet
                        case .`internal`: accessLevelModifier = .`internal`
                        case .internalSet: accessLevelModifier = .internalSet
                        case .`public`: accessLevelModifier = .`public`
                        case .publicSet: accessLevelModifier = .publicSet
                        case .`open`: accessLevelModifier = .`open`
                        case .openSet: accessLevelModifier = .openSet
                      }
                  }
                  
                  var genericWhere: ASTGenericWhereClause?=nil
                  if am.genericWhere != nil {
                      genericWhere=try getGenericWhereClause(am.genericWhere!)
                  }
                  
                  let assignmentType:ASTType? = am.assignmentType != nil ? try ASTType.get(type: am.assignmentType!) : nil
                  
                  let ti=try getTypeInheritanceClause(am.typeInheritance)
                  
                  members.append(.associatedType(BinAST.AssociativityTypeMember(name: am.name.textDescription, location: self, 
                                                 attributes: a, accessLevelModifier: accessLevelModifier, typeInheritance: ti,
                                                 assignmentType: assignmentType, genericWhere: genericWhere)))
              case .compilerControl(let cc):
                  throw ASTGenerationError("todo compilerControlStatement")
          }
      }

      let p=ProtocolDeclaration(name:self.name.textDescription, members: members, location: self, attributes: getAttributes(attributes:attributes), 
                                 accessLevelModifier: accessLevelModifier, typeInheritanceClause: ti)
      p.context=ASTModule.current
      p.impl.context=p.context

      for m in members {
           switch m {
            case .general(let ast):
                if let sc = ast as? BinAST.Scope {sc.context=p}
                if let pm=ast as? BinAST.PropertyMember {pm.context=p}
                if let sm=ast as? BinAST.SubscriptMember {sm.context=p}
                if let am=ast as? BinAST.AssociativityTypeMember {am.context=p}
                if let f=ast as? BinAST.FunctionDeclaration {f.context=p}
            case .property(let pm):
                pm.context=p
            case .method(let mm):
                mm.context=p
            case .initializer(let im):
                im.context=p
                im.type=p.impl
            case .`subscript`(let sm):
                sm.context=p
            case .associatedType(let am):
                am.context=p
         }
      }

      return p
  }
}

extension SwiftAST.ClassDeclaration : BinASTRepresentable {
  public func ast() throws -> AST { 
      var olddeclaredTypes:[String:ASTType]=[:]

      var generic: ASTGenericParameterClause?=nil
      if self.genericParameterClause != nil {
          generic=try getGenericParameterClause(self.genericParameterClause!,olddeclaredTypes: &olddeclaredTypes, location: self)
      }

      var genericWhere: ASTGenericWhereClause?=nil
      if self.genericWhereClause != nil {
            genericWhere=try getGenericWhereClause(self.genericWhereClause!)
      }

      var accessLevelModifier:Modifier?=nil
      if self.accessLevelModifier != nil {
        switch self.accessLevelModifier {
            case .none: _=1
            case .`private`: accessLevelModifier = .`private`
            case .privateSet: accessLevelModifier = .privateSet
            case .`fileprivate`: accessLevelModifier = .`fileprivate`
            case .fileprivateSet: accessLevelModifier = .fileprivateSet
            case .`internal`: accessLevelModifier = .`internal`
            case .internalSet: accessLevelModifier = .internalSet
            case .`public`: accessLevelModifier = .`public`
            case .publicSet: accessLevelModifier = .publicSet
            case .`open`: accessLevelModifier = .`open`
            case .openSet: accessLevelModifier = .openSet
        }
      }

      let ti=try getTypeInheritanceClause(typeInheritanceClause)
      
      //append dummy scope
      ASTModule.current.pushScope(origin: self.name.textDescription)
      
      var members:[BinAST.Member]=[]
      for m in self.members {
          switch m {
              case .declaration(let decl):
                  let mm=try decl.ast()
                  //print("got class member:",mm)
                  if let f=mm as? InitializerDeclaration {
                      let initializer=BinAST.InitializerMember(body: f.body, 
                                                              location: f.location, attributes: f.attributes, 
                                                              modifiers: f.modifiers, genericParameter: f.genericParameterClause, 
                                                              parameterList:f.signature.parameterList, genericWhere: f.genericWhereClause)
                      members.append(.initializer(initializer))
                  }
                  else if let f=mm as? FunctionDeclaration {
                      let method=BinAST.MethodMember(name: f.name, body: f.body, 
                                                     location: f.location, attributes: f.attributes, 
                                                     modifiers: f.modifiers, genericParameter: f.genericParameterClause, signature: f.signature, 
                                                     genericWhere: f.genericWhereClause)
                      members.append(.method(method))
                  }
                  else if let v=mm as? VariableDeclaration {
                      let property=BinAST.PropertyMember(name: v.variable.name, typeAnnotation: v.typeAnnotation, 
                                                         isConstant: v.isConstant, initializer: v.initializer, location: v.location, 
                                                         getterSetterKeywordBlock: v.variable.getterSetterKeywordBlock, 
                                                         attributes: v.attributes, modifiers: v.modifiers)
                      members.append(.property(property))
                  }
                  else {
                      throw ASTGenerationError("Unhandled class declaration member \(mm) in \(sourceRange.ttyDescription)")
                  }
              case .compilerControl(let cc):
                  throw ASTGenerationError("todo compilerControlStatement")
          }
      }
      
      //restore scope
      ASTModule.current.popScope()
      
      let c=ClassDeclaration(name:self.name.textDescription, members: members, location: self, isFinal: isFinal, 
                             attributes: getAttributes(attributes:attributes), 
                             accessLevelModifier: accessLevelModifier, typeInheritanceClause: ti, generic:generic, genericWhere: genericWhere)
      c.context=ASTModule.current
      c.impl.context=c.context

      for m in members {
           switch m {
            case .general(let ast):
                if let sc = ast as? BinAST.Scope {sc.context=c}
                if let pm=ast as? BinAST.PropertyMember {pm.context=c}
                if let sm=ast as? BinAST.SubscriptMember {sm.context=c}
                if let am=ast as? BinAST.AssociativityTypeMember {am.context=c}
                if let f=ast as? BinAST.FunctionDeclaration {f.context=c}
            case .property(let pm):
                pm.context=c
            case .method(let mm):
                mm.context=c
            case .initializer(let im):
                im.context=c
                im.type=c.impl
            case .`subscript`(let sm):
                sm.context=c
            case .associatedType(let am):
                am.context=c
         }
      }
      
      //restore generic type names
      for (k,v) in olddeclaredTypes {ASTModule.current.currentScope.declaredTypes[k]=v}
      
      return c
  }
}

extension SwiftAST.ImportDeclaration : BinASTRepresentable {
  public func ast() throws -> AST {
      var a:[AST]=[]
      for i in path {
          var m:String=i.textDescription
          let n:String?=nil
          if let i=m.firstIndex(of:".") {
            //search with module prefix
            var n=m[i...]
            n.removeFirst()
            m=String(m[..<i])
          }
          let e=try ASTModule.current.addImport(module: m,location: self, kind: kind != nil ? "\(kind!)" : nil,name: n)
          a.append(e)
      }
      if a.count == 1 {return a[0]}
      return Compound(children:a, location: self, dummy:true)
  }
}


extension SwiftAST.FunctionDeclaration: BinASTRepresentable {
  public func ast() throws -> AST {
      let a=getAttributes(attributes: self.attributes)
      let m=getModifiers(modifiers: self.modifiers)
                  
      var olddeclaredTypes:[String:ASTType]=[:]
      var genericParameterClause: ASTGenericParameterClause?=nil
      if self.genericParameterClause != nil {
            genericParameterClause=try getGenericParameterClause(self.genericParameterClause!, olddeclaredTypes:&olddeclaredTypes, location: self)
      }
      
      var genericWhereClause: ASTGenericWhereClause?=nil
      if self.genericWhereClause != nil {
          genericWhereClause=try getGenericWhereClause(self.genericWhereClause!)
      }
                  
      let parameterList=try getParameterList(self.signature.parameterList)
      var tk: ThrowsKind
      switch self.signature.throwsKind {
        case .nothrowing: tk = .nothrowing
        case .throwing: tk = .throwing
        case .rethrowing: tk = .rethrowing
      }
                  
      var result:FunctionResult? = nil
      if self.signature.result != nil {
        let ra=getAttributes(attributes: self.signature.result!.attributes)
        result=FunctionResult(attributes:ra, type: try ASTType.get(type: self.signature.result!.type))
      }
      let signature=FunctionSignature(parameterList: parameterList, throwsKind: tk, result:result)
                  
      var body: CodeBlock?=nil
      if self.body != nil {
          body=try self.body!.ast() as! CodeBlock
      }
      
      //restore generic type names
      for (k,v) in olddeclaredTypes {ASTModule.current.currentScope.declaredTypes[k]=v}
    
                  
      let f = FunctionDeclaration(name: self.name.textDescription, body: body, location: self, attributes: a, modifiers: m, 
                                  genericParameterClause: genericParameterClause, signature: signature, 
                                  genericWhereClause: genericWhereClause)
      f.context=ASTModule.current
            
      try ASTModule.current.declareFunc(function: f)
      f.needsDecl=false
      
      return f
  }
}

var ignoreStatements=false
var ifcount=0
var oldignoreStatements=false

func defined(id:String) -> Bool {
    //todo check if symbol defined
    return false
}

extension CompilerControlStatement : BinASTRepresentable {
  public func ast() throws -> AST {
      switch kind {
        case .if(let id):
            if ignoreStatements {
                ifcount=ifcount+1
                return NoOp()
            }
            oldignoreStatements=ignoreStatements
            ignoreStatements = !defined(id:id)
            if ignoreStatements {ifcount=0}
            return NoOp()
        case .elseif(let id):
            if ignoreStatements && ifcount>0 {return NoOp()}
            ignoreStatements = !ignoreStatements && !defined(id:id)
            return NoOp()
        case .else:
            if ignoreStatements && ifcount>0 {return NoOp()}
            ignoreStatements = !ignoreStatements
            return NoOp()
        case .endif:
            if ignoreStatements {
                ifcount=ifcount-1
                if ifcount<=0 {ignoreStatements=oldignoreStatements}
                return NoOp()
            }
            ignoreStatements=oldignoreStatements
            return NoOp()
        case .sourceLocation(_, _):
            return NoOp()
      }
  }
}

extension AssignmentOperatorExpression : BinASTRepresentable {
  public func ast() throws -> AST {
    return Assignment(lhs: try leftExpression.ast(), rhs: try rightExpression.ast(), location: self)
  }
}

extension SwiftAST.IdentifierExpression : BinASTRepresentable {
  public func ast() throws -> AST {
    switch kind {
        case .identifier(let id, let gp):
            var agp:ASTGenericArgumentClause?=nil
            if gp != nil {
                agp=ASTGenericArgumentClause()
                for t in gp!.argumentList {
                    agp!.argumentList.append(try ASTType.get(type:t))
                }
            }
            //search this identifier in scope
            let name=id.textDescription
            
            return IdentifierExpression(kind: .identifier(name, agp), location: self)
        case .implicitParameterName(let i, let gp):
            var agp:ASTGenericArgumentClause?=nil
            if gp != nil {
                agp=ASTGenericArgumentClause()
                for t in gp!.argumentList {
                    agp!.argumentList.append(try ASTType.get(type:t))
                }
            }
            return IdentifierExpression(kind: .implicitParameterName(i, agp), location: self)
        case .bindingReference(let id):
            return IdentifierExpression(kind: .bindingReference(id), location: self)
    }
  }
}

extension SwiftAST.DictionaryEntry : BinASTRepresentable {
  public func ast() throws -> AST {
    return DictionaryEntry(key: try key.ast(), value: try value.ast(), location: ASTLocation())
  }
}

extension LiteralExpression : BinASTRepresentable {
  public func ast() throws -> AST {
    switch kind {
        case .nil: return Literal(kind: .nil,location: self)
        case .boolean(let b): return Literal(kind: .boolean(b),location: self)
        case .integer(let i, let s): return Literal(kind: .integer(i,s),location: self)
        case .floatingPoint(let d, let s): return Literal(kind: .floatingPoint(d, s),location: self)
        case .staticString(let s, let s1): return Literal(kind: .staticString(s, s1),location: self)
        case .interpolatedString(let e, let s): 
            var a:[AST]=[]
            for ee in e {
                a.append(try ee.ast())
            }
            return Literal(kind: .interpolatedString(a, s),location: self)
        case .array(let e):
            var a:[AST]=[]
            for ee in e {
                a.append(try ee.ast())
            }
            return Literal(kind: .array(a),location: self)
        case .dictionary(let d):
            var a:[DictionaryEntry]=[]
            for e in d {
                a.append(DictionaryEntry(key: try e.key.ast(), value: try e.value.ast(), location: self))
            }
            return Literal(kind: .dictionary(a),location: self)
        case .playground(let pl):
            switch pl {
                case .color(let e, let e1, let e2, let e3):return Literal(kind: .playground(.color(try e.ast(),try e1.ast(),try e2.ast(),try e3.ast())),location: self)
                case .file(let e): return Literal(kind: .playground(.file(try e.ast())),location: self)
                case .image(let e): return Literal(kind: .playground(.image(try e.ast())),location: self)
            }
    }
  }
}

func getParameterList(_ parameterList: [SwiftAST.FunctionSignature.Parameter]) throws -> [BinAST.FunctionSignature.Parameter] {
      var result: [FunctionSignature.Parameter]=[]
      for p in parameterList {
          let tat=try ASTType.get(type:p.typeAnnotation.type /*?? AnyType()*/)
          let tattrs=getAttributes(attributes: p.typeAnnotation.attributes)
          let ta=ASTTypeAnnotation(type: tat, attributes: tattrs, isInOutParameter: p.typeAnnotation.isInOutParameter)
          
          var pp=FunctionSignature.Parameter(externalName:p.externalName?.textDescription, localName:p.localName.textDescription, typeAnnotation: ta,
                                             defaultArgumentClause: try p.defaultArgumentClause?.ast())
          pp.isVarargs=p.isVarargs
          result.append(pp)
      }
      return result
}

extension SwiftAST.InitializerDeclaration: BinASTRepresentable {
  public func ast() throws -> AST {
      var k:InitializerDeclaration.InitKind 
      switch kind {
          case .nonfailable: k = .nonfailable
          case .optionalFailable: k = .optionalFailable
          case .implicitlyUnwrappedFailable: k = .implicitlyUnwrappedFailable
      }
      var olddeclaredTypes:[String:ASTType]=[:]
      var genericParameterClause: ASTGenericParameterClause?=nil
      if self.genericParameterClause != nil {
          genericParameterClause=try getGenericParameterClause(self.genericParameterClause!, olddeclaredTypes:&olddeclaredTypes, location: self)
      }
      var genericWhereClause: ASTGenericWhereClause?=nil
      if self.genericWhereClause != nil {
            genericWhereClause=try getGenericWhereClause(self.genericWhereClause!)
      }
      let parameterList=try getParameterList(self.parameterList)
      
      var tk: ThrowsKind
      switch self.throwsKind {
          case .nothrowing: tk = .nothrowing
          case .throwing: tk = .throwing
          case .rethrowing: tk = .rethrowing
      }
      
      //restore generic type names
      for (k,v) in olddeclaredTypes {ASTModule.current.currentScope.declaredTypes[k]=v}
      
      let i=InitializerDeclaration(body: try self.body.ast() as! CodeBlock, location: self,
                                    attributes: getAttributes(attributes: attributes), modifiers: getModifiers(modifiers: modifiers),
                                    kind: k, genericParameterClause: genericParameterClause,
                                    parameterList: parameterList, throwsKind: tk,
                                    genericWhereClause: genericWhereClause)
      i.context=ASTModule.current
      return i
  }
}



extension SwiftAST.CodeBlock: BinASTRepresentable {
  public func ast() throws -> AST {
      var statements:[AST]=[]
      for s in self.statements {statements.append(try s.ast())}
      return CodeBlock(statements: statements, location: self)
  }
}

extension SwiftAST.ReturnStatement: BinASTRepresentable {
  public func ast() throws -> AST {
      let expr=try expression?.ast() 
      return ReturnStatement(expression: expr, location: self)
  }
}

extension SwiftAST.ClosureExpression: BinASTRepresentable {
  public func ast() throws -> AST {
        var sig:BinAST.ClosureExpression.Signature?=nil
      if self.signature != nil {
        sig=BinAST.ClosureExpression.Signature(captureList: [])
        sig!.captureList=nil

        if self.signature!.captureList != nil {
            sig!.captureList=[]
            for ci in self.signature!.captureList! {
                var spec:BinAST.ClosureExpression.Signature.CaptureItem.Specifier?=nil
                if ci.specifier != nil {
                    switch ci.specifier! {
                        case .weak: spec = .weak
                        case .unowned : spec = .unowned
                        case .unownedSafe : spec = .unownedSafe
                        case .unownedUnsafe : spec = .unownedUnsafe
                    }
                }

                let expr=try ci.expression.ast()

                sig!.captureList!.append(BinAST.ClosureExpression.Signature.CaptureItem(specifier: spec, expression: expr))
            }
        }

        if self.signature!.parameterClause != nil {
            switch self.signature!.parameterClause! {
                case .parameterList(let pl):
                    var plist:[BinAST.ClosureExpression.Signature.ParameterClause.Parameter]=[]
                    for p in pl {
                        var ta:ASTTypeAnnotation?=nil
                        if p.typeAnnotation != nil {
                            let tat=try ASTType.get(type:p.typeAnnotation!.type)
                            let tattrs=getAttributes(attributes: p.typeAnnotation!.attributes) 
                            ta=ASTTypeAnnotation(type: tat, attributes: tattrs, isInOutParameter: p.typeAnnotation!.isInOutParameter)
                        }

                        plist.append(BinAST.ClosureExpression.Signature.ParameterClause.Parameter(name: p.name.textDescription, typeAnnotation: ta, 
                                                                                                  isVarargs: p.isVarargs))
                    }
                    sig!.parameterClause = .parameterList(plist)
                case .identifierList(let sl):
                    var slist:[String]=[]
                    for s in sl {slist.append(s.textDescription)}
                    sig!.parameterClause = .identifierList(slist)
            }
        }

        sig!.canThrow=self.signature!.canThrow

        if self.signature!.functionResult != nil {
            let ra=getAttributes(attributes: self.signature!.functionResult!.attributes)
            sig!.functionResult=FunctionResult(attributes:ra, type: try ASTType.get(type: self.signature!.functionResult!.type))
        }
      }
  
      var stmt:[AST]?=nil
      if self.statements != nil {
            stmt=[]
          for s in self.statements! {stmt!.append(try s.ast())}
      }

      return BinAST.ClosureExpression(signature: sig, statements: stmt, location: self)
  }
}

extension SwiftAST.FunctionCallExpression: BinASTRepresentable {
  public func ast() throws -> AST {
      let pf=try self.postfixExpression.ast()

      var ac:[BinAST.FunctionCallExpression.Argument]?=nil
      if self.argumentClause != nil {
            ac=[]
          for a in self.argumentClause! {
                switch a {
                    case .expression(let ast):
                    ac!.append(.expression(try ast.ast()))
                    case .namedExpression(let name, let ast):
                    ac!.append(.namedExpression(name.textDescription,try ast.ast()))
                  case .memoryReference(let ast):
                    ac!.append(.memoryReference(try ast.ast()))
                  case .namedMemoryReference(let name, let ast):
                    ac!.append(.namedMemoryReference(name.textDescription,try ast.ast()))
                  case .`operator`(let op):    
                    ac!.append(.`operator`(op))
                  case .namedOperator(let name, let op):
                    ac!.append(.namedOperator(name.textDescription, op))
              }
          }
      }

      var ce:BinAST.ClosureExpression?=nil
      if trailingClosure != nil {
            ce=try trailingClosure!.ast() as! BinAST.ClosureExpression
      }

      return BinAST.FunctionCallExpression(postfixExpression: pf, argumentClause: ac, trailingClosure: ce, location: self)
  }
}

extension SwiftAST.ExplicitMemberExpression: BinASTRepresentable {
  public func ast() throws -> AST { 
      switch kind {
            case .tuple(let ast, let index):
                return BinAST.ExplicitMemberExpression(kind: .tuple(try ast.ast(), index), location:self)
            case .namedType(let ast, let name):
                return BinAST.ExplicitMemberExpression(kind: .namedType(try ast.ast(), name.textDescription), location:self)
            case .generic(let ast, let name, let genericArgumentClause):
                let g=try getGenericArgumentClause(genericArgumentClause) ?? ASTGenericArgumentClause()
                return BinAST.ExplicitMemberExpression(kind: .generic(try ast.ast(), name.textDescription, g), location:self)
            case .argument(let ast, let name, let args):
                var a:[String]=[]
                for aa in args {a.append(aa.textDescription)}
                return BinAST.ExplicitMemberExpression(kind: .argument(try ast.ast(), name.textDescription, a), location:self)
        }
  }
}



extension SwiftAST.Statement {
  public func ast() throws -> AST { 
    switch self {
    case let ast as BinASTRepresentable:
      if ignoreStatements {
          if let cc=ast as? CompilerControlStatement {
              return try cc.ast()
          }
          return NoOp()
      }
    //print("do ast for ",ast)
    return try ast.ast()
    default:
      throw ASTGenerationError("Unknown AST statement type:\(type(of:self))->\(self.textDescription) in \(sourceRange.ttyDescription)")
    }
  }
}




















