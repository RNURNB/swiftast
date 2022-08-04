import Foundation
import SwiftAST


#if DLSYM
typealias Swift_Demangle = @convention(c) (_ mangledName: UnsafePointer<UInt8>?,
                                           _ mangledNameLength: Int,
                                           _ outputBuffer: UnsafeMutablePointer<UInt8>?,
                                           _ outputBufferSize: UnsafeMutablePointer<Int>?,
                                           _ flags: UInt32) -> UnsafeMutablePointer<Int8>?
#else
//we use SwiftDemangle here
#endif

/*func swift_demangle(_ mangled: String) -> SwiftDemangle.Node? {
    #if DLSYM
    let RTLD_DEFAULT = dlopen(nil, RTLD_NOW)
    if let sym = dlsym(RTLD_DEFAULT, "swift_demangle") {
        let f = unsafeBitCast(sym, to: Swift_Demangle.self)
        if let cString = f(mangled, mangled.count, nil, nil, 0) {
            defer { cString.deallocate() }
            return String(cString: cString)
        }
    }
    #else
    //we use SwiftDemangle here
    let d=Demangler(mangled)
    let node=d.demangleSymbol()
    //print(node)
    return node
    #endif
    return nil

}*/

// How to use
/*if let s = swift_demangle("$s20MyPlayground_Sources4TestC4testSSyF") {
    print(s) // MyPlayground_Sources.Test.test() -> Swift.String
}*/


