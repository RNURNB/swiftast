import Foundation
import SwiftAST
import BinAST



#if WINDOWS
#else
//NSSetUncaughtExeceptionHandler {exception in print("Uncaught exception \(exception) called");print(Thread.callStackSymbols)}
#endif
signal(SIGABRT) {_  in print("SIGABRT called");print(Thread.callStackSymbols)}
signal(SIGILL) {_  in print("SIGILL called");print(Thread.callStackSymbols)}
signal(SIGSEGV) {_  in print("SIGSEGV called");print(Thread.callStackSymbols)}
signal(SIGFPE) {_  in print("SIGFPE called");print(Thread.callStackSymbols)}
#if WINDOWS
#else
signal(SIGBUS) {_  in print("SIGBUS called");print(Thread.callStackSymbols)}
signal(SIGPIPE) {_  in print("SIGPIPE called");print(Thread.callStackSymbols)}
#endif 

//registeredClasses["USER.User"]=User.self

/*var v1=RuntimeValue(int:66)
print("value:",v1.value)
print("isNil:",v1.isNil)
print("isOptional:",v1.isOptional)
var ii:Int?=88
var v2=RuntimeValue(int:ii)
print("value:",v2.value)
print("isNil:",v2.isNil)
print("isOptional:",v2.isOptional)
var v3=RuntimeValue(nil:nil)
print("value:",v3.value)
print("isNil:",v3.isNil)
print("isOptional:",v3.isOptional)
*/

/*
let cif=alloc_ffi()
print("cif allocated")

var argTypes: [Pffi_type] = []
let status=prep_ffi(cif: cif, returnType: pffi_type_void , argTypes: argTypes) 
print("prep_ffi =", status, " FFI_OK=", FFI_OK)
 
let addr=symbolAdressOf(name:"$s4USER4UserCACycfc")

//var u=try createInstance(of: User.self , constructor: nil) as! User
var md = ClassMetadata(type: User.self)
let info = md.toTypeInfo()
let metadata = unsafeBitCast(User.self, to: UnsafeRawPointer.self)
let instanceSize = Int32(md.pointer.pointee.instanceSize)
print("instanceSize=",instanceSize)
let alignmentMask = Int32(md.pointer.pointee.instanceAlignmentMask)
guard var u:UnsafeRawPointer = swift_allocObject(metadata, instanceSize, alignmentMask) else {
    throw RuntimeError.unableToBuildType(type: User.self)
}
//try setProperties(typeInfo: info, pointer: UnsafeMutableRawPointer(mutating: u))
print("raw allocated:",u)
var args:[RuntimeValue]=[]
call_ffi_method (cif: cif, addr:addr, this: unsafeBitCast(u, to: AnyObject.self), args:&args, returnType: void_rt_type )

print("init called")

//print("u after init=",u," email=",(u as! User).email)
//print("pu=",pu)
//print("memory u=",uSelf)
#if WINDOWS
let uu=User()
#else
let uu=unsafeBitCast(u, to: User.self)
print("uu=",uu," email=",uu.email)
#endif

//test2(arg1: Int, arg2:Int)->Int
let cif1=alloc_ffi()
let addr1=symbolAdressOf(name:"$s4USER4UserC5test24arg14arg2S2i_SitF")
let status1=prep_ffi(cif: cif1, returnType: pffi_type_sint64, argTypes: [pffi_type_sint64, pffi_type_sint64])
print("prep_ffi1 =", status1, " FFI_OK=", FFI_OK)
var args1:[RuntimeValue]=[RuntimeValue(int:7),RuntimeValue(int:3)]
let r=call_ffi_method (cif: cif1, addr:addr1, this: uu, args: &args1, returnType:  int_rt_type)
print("test 2 call result:",r)


dealloc_ffi(cif: cif)
print("cif deallocated")

#if WINDOWS
#else
for i in 0..<80 {print("error                                                             ")}
#endif
fatalError()
*/

/*
#if WINDOWS
let stdlibpath="C:\\Users\\A336380\\Desktop\\SwiftAST\\USER.swiftdecl"
let stdliboutpath="C:\\Users\\A336380\\Desktop\\SwiftAST\\USER.bc"
#else
let stdlibpath="./../USER.swiftdecl"
let stdliboutpath="./../USER.bc"
#endif

do {
    try processSTDLib(path:stdlibpath, out:stdliboutpath)
} catch {
    for d in DiagnosticPool.shared.diagnostics {
        print(d.level,":",d.kind.diagnosticMessage," at ",d.location)
    }
    if let d=error as? DiagnosticStopper {
    }
    else {print("Exception got: \(error)")}
}
*/



/*
let info = try typeInfo(of: User.self)
print("runtime info got:",info)
print("mangled name:",info.mangledName)
var user = User(/*id:66, username:"RN"*/)
print("instance created:",user)
let property = try info.property(named: "username")
try property.set(value: "newUsername", on: &user)
let username = try property.get(from: user)
print("username=",username)
func doSomething(a: Int, b: Bool) throws -> String { 
  return "" 
}
let finfo = try functionInfo(of: doSomething)
print("runtime function info got:",finfo)

/*print("allocating object")
doAllocObject()
print("allocated object")*/

print("Type from name:")
// ex. So8UIButtonCSg -> UIButton?
/*
$s12SwiftASTTest4UserCACycfC 
$s12SwiftASTTest4UserCACycfCTq 
$s12SwiftASTTest4UserCACycfc 
$s12SwiftASTTest4UserCMa 
$s12SwiftASTTest4UserCMn 
$s12SwiftASTTest4UserCN 
$s12SwiftASTTest4UserCfD 
$s12SwiftASTTest4UserCfd
*/
print( getTypeFromMangledName("User"))

let u=try createInstance(of: User.self , constructor: nil/*((PropertyInfo) throws -> Any)? = nil*/) 
/*
$s12SwiftASTTest4UserC2id8username5emailACSi_S2StcfC
SwiftASTTest.User.__allocating_init(id: Swift.Int, username: Swift.String, email: Swift.String) -> SwiftASTTest.User
*/

print("manual u:",u)

fatalError()
*/

print("Start Swift AST test")

#if WINDOWS
let path="C:\\Users\\A336380\\Desktop\\SwiftAST\\test.xswift"
let path1="C:\\Users\\A336380\\Desktop\\SwiftAST\\test1.xswift"
#else
let path="./../test.xswift"
let path1="./../test1.xswift"
#endif
let source=SourceFile(path:path, content:try! String(contentsOfFile:path));
let source1=SourceFile(path:path1, content:try! String(contentsOfFile:path1));

do {
    let parser1=Parser(source:source1)
    let decls1=try parser1.parse()
    for d in DiagnosticPool.shared.diagnostics {
        print(d.level,":",d.kind.diagnosticMessage," at ",d.location)
    }
    if DiagnosticPool.shared.hasErrors {
        for i in 0..<80 {print("error                                                             ")}
        fatalError()
    }
    
    print("Dump1:")
    print(decls1.ttyDump)
    try InitBinASTGenerator()
    let binAST1=try generateBinAST(module:"test1", file:decls1)
    try ASTModule.current.archive(path:"test1.bc")
    //double check unit for correctness (e.g. statements at top level
    try binAST1.runDeclarations(isTopLevel:true)

    print("ast1=",binAST1)
    print(try binAST1.printTree(execMode:true))
    
    
    print("unit test1 generated")

    let parser=Parser(source:source)
    let decls=try parser.parse()
    for d in DiagnosticPool.shared.diagnostics {
        print(d.level,":",d.kind.diagnosticMessage," at ",d.location)
    }
    if DiagnosticPool.shared.hasErrors {
        for i in 0..<50 {print("error                                                             ")}
        fatalError()
    }
    //print("decls=",decls)

    print("Dump:")
    print(decls.ttyDump)
    
    print("Parsing test")

    //let binAST=try decls.ast()
    try InitBinASTGenerator()
    setOption(option:"primary-file", value:"test.xswift")
    setOption(option:"-I", value:"./..")
    let binAST=try generateBinAST(module:"<main>", file:decls)
    print("bin ast generated")
    try ASTModule.current.archive(path:"main.bc")
    
    print("Parsed test")
    
    try binAST.runDeclarations(isTopLevel:true)
    
    print("test decls ok")

    print("ast=",binAST)
    print(try binAST.printTree(execMode:true))

    print("**********************Starting Execution*********************************")
    try binAST.exec()

    //let seqExprFolding = SequenceExpressionFolding()
    //seqExprFolding.fold([topLevelDecl])
} catch {
    for d in DiagnosticPool.shared.diagnostics {
        print(d.level,":",d.kind.diagnosticMessage," at ",d.location)
    }
    if let d=error as? DiagnosticStopper {
    }
    else {print("Exception got: \(error)")}
}

print("End Swift AST test")

