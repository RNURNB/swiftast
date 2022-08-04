
import Foundation
import Swift

//hack to be able to handle nil as Any
let NilAny: Any = Optional<Any>.none as Any

//so we can detect if Any contains a nil with type(of:var) is OptionalProtocol.Type
public protocol OptionalProtocol {}
extension Optional : OptionalProtocol {}

public func unwrap<T>(_ x: Any) -> T {
  return x as! T
}

//public typealias Pffi_cif = UnsafeMutablePointer<ffi_cif>?
//public typealias Pffi_type = UnsafeMutablePointer<ffi_type>?

public enum TRuntimeSwiftType {
    case int8
    case int16
    case int32
    case int

    case uint8
    case uint16
    case uint32
    case uint

    case float
    case double

    case character
    case string

    case bool

    case `nil`

    case `void`

    case any
    case pointer
    case `class`
    case `struct`
    case `enum`
    case `protocol`
    case dictionary

    case variable
    case variableList

    case function
    case functionList

    case type
    case typeList
    
        case cell
}

public let RuntimeSwiftType_None:UInt8 = 0
public let RuntimeSwiftType_Optional:UInt8 = 1
public let RuntimeSwiftType_Literal:UInt8  = 2

public typealias RuntimeSwiftType=(TRuntimeSwiftType, UInt8/*IsOptional, isLiteral*/)

//Integer Types
public var int8_rt_type:RuntimeSwiftType=(.int8,RuntimeSwiftType_None)
public var uint8_rt_type:RuntimeSwiftType=(.uint8,RuntimeSwiftType_None)
public var int16_rt_type:RuntimeSwiftType=(.int16,RuntimeSwiftType_None)
public var uint16_rt_type:RuntimeSwiftType=(.uint16,RuntimeSwiftType_None)
public var int32_rt_type:RuntimeSwiftType=(.int32,RuntimeSwiftType_None)
public var uint32_rt_type:RuntimeSwiftType=(.uint32,RuntimeSwiftType_None)
public var int_rt_type:RuntimeSwiftType=(.int,RuntimeSwiftType_None)
public var uint_rt_type:RuntimeSwiftType=(.uint,RuntimeSwiftType_None)

//Optional Integer Types
public var oint8_rt_type:RuntimeSwiftType=(.int8,RuntimeSwiftType_Optional)
public var ouint8_rt_type:RuntimeSwiftType=(.uint8,RuntimeSwiftType_Optional)
public var oint16_rt_type:RuntimeSwiftType=(.int16,RuntimeSwiftType_Optional)
public var ouint16_rt_type:RuntimeSwiftType=(.uint16,RuntimeSwiftType_Optional)
public var oint32_rt_type:RuntimeSwiftType=(.int32,RuntimeSwiftType_Optional)
public var ouint32_rt_type:RuntimeSwiftType=(.uint32,RuntimeSwiftType_Optional)
public var oint_rt_type:RuntimeSwiftType=(.int,RuntimeSwiftType_Optional)
public var ouint_rt_type:RuntimeSwiftType=(.uint,RuntimeSwiftType_Optional)

//Floating Point Types
public var float_rt_type:RuntimeSwiftType=(.float,RuntimeSwiftType_None)
public var double_rt_type:RuntimeSwiftType=(.double,RuntimeSwiftType_None)

//Optional Floating Point Types
public var ofloat_rt_type:RuntimeSwiftType=(.float,RuntimeSwiftType_Optional)
public var odouble_rt_type:RuntimeSwiftType=(.double,RuntimeSwiftType_Optional)

public var bool_rt_type:RuntimeSwiftType=(.bool,RuntimeSwiftType_None)
public var obool_rt_type:RuntimeSwiftType=(.bool,RuntimeSwiftType_Optional)

public var character_rt_type:RuntimeSwiftType=(.character,RuntimeSwiftType_None)
public var ocharacter_rt_type:RuntimeSwiftType=(.character,RuntimeSwiftType_Optional)

public var void_rt_type:RuntimeSwiftType=(.nil,RuntimeSwiftType_None)

public var any_rt_type:RuntimeSwiftType=(.any,RuntimeSwiftType_None)

public var nil_rt_type:RuntimeSwiftType=(.nil,RuntimeSwiftType_None)
public var literalNil_rt_type:RuntimeSwiftType=(.nil,RuntimeSwiftType_Literal)

//String Types
public var string_rt_type:RuntimeSwiftType=(.string,RuntimeSwiftType_None)
public var ostring_rt_type:RuntimeSwiftType=(.string,RuntimeSwiftType_Optional)

//variables / functions / types / classes
public var variable_rt_type:RuntimeSwiftType=(.variable,RuntimeSwiftType_None)
public var variablelist_rt_type:RuntimeSwiftType=(.variableList,RuntimeSwiftType_None)

public var type_rt_type:RuntimeSwiftType=(.type,RuntimeSwiftType_None)
public var typelist_rt_type:RuntimeSwiftType=(.typeList,RuntimeSwiftType_None)

public var function_rt_type:RuntimeSwiftType=(.function,RuntimeSwiftType_None)
public var functionlist_rt_type:RuntimeSwiftType=(.functionList,RuntimeSwiftType_None)

public var class_rt_type:RuntimeSwiftType=(.class,RuntimeSwiftType_None)
public var oclass_rt_type:RuntimeSwiftType=(.class,RuntimeSwiftType_Optional)

public var struct_rt_type:RuntimeSwiftType=(.struct,RuntimeSwiftType_None)
public var ostruct_rt_type:RuntimeSwiftType=(.struct,RuntimeSwiftType_Optional)

public var enum_rt_type:RuntimeSwiftType=(.enum,RuntimeSwiftType_None)
public var oenum_rt_type:RuntimeSwiftType=(.enum,RuntimeSwiftType_Optional)

public var pointer_rt_type:RuntimeSwiftType=(.pointer,RuntimeSwiftType_None)
public var opointer_rt_type:RuntimeSwiftType=(.pointer,RuntimeSwiftType_Optional)

public var dictionary_rt_type:RuntimeSwiftType=(.dictionary,RuntimeSwiftType_None)
public var odictionary_rt_type:RuntimeSwiftType=(.dictionary,RuntimeSwiftType_Optional)

public var oany_rt_type:RuntimeSwiftType=(.any,RuntimeSwiftType_Optional)

public var runtimeNilValue=RuntimeValue(literalNil:nil)

public protocol RuntimeVariable {
    var name: String {get}
    var isConstant: Bool {get}
    var value:RuntimeValue? {get}

    mutating func setValue(value:RuntimeValue?)
}

public protocol RuntimeFunctionDeclaration {
    var name: String {get}
}

public protocol RuntimeType {

}

public struct RuntimeValue {
    public var value:Any
    public var type:RuntimeSwiftType

    public var isOptional:Bool {
        if type.0 == .nil {return false} //nil itself is not optional
        if type.0 == .void {return false} //void is just void
        if type.0 == .variable || type.0 == .variableList {
            if let v=value as? RuntimeVariable {
                return v.value?.isOptional ?? false
            }
            else {return false}
        }
        if type.0 == .function || type.0 == .functionList {
            return false //??
        }
        if type.0 == .type || type.0 == .typeList {
            return false //??
        }
        return value is OptionalProtocol
    }

    public var isNil:Bool {
        if value is OptionalProtocol {
            switch type.0 {
                case .int8:
                    let z:Int8?=unwrap(value)
                    return z==nil
                case .int16:
                    let z:Int16?=unwrap(value)
                    return z==nil
                case .int32:
                    let z:Int32?=unwrap(value)
                    return z==nil
                case .int:
                    let z:Int?=unwrap(value)
                    return z==nil

                case .uint8:
                    let z:UInt8?=unwrap(value)
                    return z==nil
                case .uint16:
                    let z:UInt16?=unwrap(value)
                    return z==nil
                case .uint32:
                    let z:UInt32?=unwrap(value)
                    return z==nil
                case .uint:
                    let z:UInt?=unwrap(value)
                    return z==nil

                case .float:
                    let z:Float?=unwrap(value)
                    return z==nil
                case .double:
                    let z:Double?=unwrap(value)
                    return z==nil

                case .character:
                    let z:Character?=unwrap(value)
                    return z==nil
                case .string:
                    let z:String?=unwrap(value)
                    return z==nil

                case .bool:
                    let z:Bool?=unwrap(value)
                    return z==nil

                case .`nil`:
                    return true

                case .`void`:
                    return false

                case .pointer:
                    let z:Any?=unwrap(value)
                    return z==nil
                case .any:
                    let z:Any?=unwrap(value)
                    return z==nil

                case .`class`:
                    let z:AnyObject?=unwrap(value)
                    return z==nil
                case .`struct`:
                    let z:Any?=unwrap(value)
                    return z==nil
                case .`enum`:
                    let z:Any?=unwrap(value)
                    return z==nil
                case .`protocol`:
                    return false
                case .dictionary:
                    let z:Any=unwrap(value)
                    return z==nil

                case .variable:
                    if let v=value as? RuntimeVariable {
                        return v.value?.isNil ?? false
                    }
                    else {return false}
                case .variableList:
                    return false //??

                case .function:
                    return false //??
                case .functionList:
                    return false //??

                case .type:
                    return false //??
                case .typeList:
                    return false //??
                    
                case .cell:
                    return false //??
            }
        }
        return false
    }

    public init(`nil`:Int?) {type=nil_rt_type; value=NilAny}

    public init(literalNil:Int?) {type=literalNil_rt_type; value=NilAny}

    public init() {type=void_rt_type; value=NilAny}

    public init(int8: Int8) {type=int8_rt_type; value=int8}
    public init(uint8: UInt8) {type=uint8_rt_type; value=uint8}
    public init(int16: Int16) {type=int16_rt_type; value=int16}
    public init(uint16: UInt16) {type=uint8_rt_type; value=uint16}
    public init(int32: Int32) {type=int32_rt_type; value=int32}
    public init(uint32: UInt32) {type=uint32_rt_type; value=uint32}
    public init(int: Int) {type=int_rt_type; value=int}
    public init(uint: UInt) {type=uint_rt_type; value=uint}

    public init(float: Float) {type=float_rt_type; value=float}
    public init(double: Double) {type=double_rt_type; value=double}

    public init(bool: Bool) {type=bool_rt_type; value=bool}

    public init(character: Character) {type=character_rt_type; value=character}

    public init(string: String) {type=string_rt_type; value=string}

    public init(object: AnyObject) {type=class_rt_type; value=object}
    
    public init(`struct` s: Any) {type=struct_rt_type; value=s}
    
    public init(`enum` e: Any) {type=enum_rt_type; value=e}

    public init(variable: RuntimeVariable) {type=variable_rt_type; value=variable}
    public init(variableList: [RuntimeVariable]) {type=variablelist_rt_type; value=variableList}

    public init(function: RuntimeFunctionDeclaration) {type=function_rt_type; value=function}
    public init(functionList: [RuntimeFunctionDeclaration]) {type=functionlist_rt_type; value=functionList}

    public init(type: RuntimeType) {self.type=type_rt_type; value=type}
    public init(typeList: [RuntimeType]) {self.type=typelist_rt_type; value=typeList}

    public init(anyvalue: Any) {
        self.value=anyvalue
        if anyvalue is OptionalProtocol {
            if isBinaryInteger(anyvalue) {
                if anyvalue is Int8 {type=oint8_rt_type}
                else if anyvalue is Int16 {type=oint16_rt_type}
                else if anyvalue is Int32 {type=oint32_rt_type}
                else if anyvalue is Int {type=oint_rt_type}
                else if anyvalue is Int64 {type=oint_rt_type}
                else if anyvalue is UInt8 {type=ouint8_rt_type}
                else if anyvalue is UInt16 {type=ouint16_rt_type}
                else if anyvalue is UInt32 {type=ouint32_rt_type}
                else if anyvalue is UInt {type=ouint_rt_type}
                else if anyvalue is UInt64 {type=oint_rt_type}
                else {type=oany_rt_type}
            }
            else if anyvalue is String {type=ostring_rt_type}
            else if anyvalue is Float {type=ofloat_rt_type}
            else if anyvalue is Double {type=ofloat_rt_type}
            else if anyvalue is Bool {type=obool_rt_type}
            else if anyvalue is AnyObject {type=oclass_rt_type}
            else if anyvalue is Character {type=ocharacter_rt_type}
            else {type=oany_rt_type}
        }
        else {
            if isBinaryInteger(anyvalue) {
                if anyvalue is Int8 {type=int8_rt_type}
                else if anyvalue is Int16 {type=int16_rt_type}
                else if anyvalue is Int32 {type=int32_rt_type}
                else if anyvalue is Int {type=int_rt_type}
                else if anyvalue is Int64 {type=int_rt_type}
                else if anyvalue is UInt8 {type=uint8_rt_type}
                else if anyvalue is UInt16 {type=uint16_rt_type}
                else if anyvalue is UInt32 {type=uint32_rt_type}
                else if anyvalue is UInt {type=uint_rt_type}
                else if anyvalue is UInt64 {type=int_rt_type}
                else {type=any_rt_type}
            }
            else if anyvalue is String {type=string_rt_type}
            else if anyvalue is Float {type=float_rt_type}
            else if anyvalue is Double {type=float_rt_type}
            else if anyvalue is Bool {type=bool_rt_type}
            else if anyvalue is AnyObject {type=class_rt_type}
            else if anyvalue is Character {type=character_rt_type}
            else {type=any_rt_type}
        }
    }

    //Optional values
    public init(int8: Int8?) {type=oint8_rt_type; value=int8}
    public init(uint8: UInt8?) {type=ouint8_rt_type; value=uint8}
    public init(int16: Int16?) {type=oint16_rt_type; value=int16}
    public init(uint16: UInt16?) {type=ouint8_rt_type; value=uint16}
    public init(int32: Int32?) {type=oint32_rt_type; value=int32}
    public init(uint32: UInt32?) {type=ouint32_rt_type; value=uint32}
    public init(int: Int?) {type=oint_rt_type; value=int}
    public init(uint: UInt?) {type=ouint_rt_type; value=uint}

    public init(float: Float?) {type=ofloat_rt_type; value=float}
    public init(double: Double?) {type=odouble_rt_type; value=double}

    public init(bool: Bool?) {type=obool_rt_type; value=bool}

    public init(character: Character?) {type=ocharacter_rt_type; value=character}

    public init(string: String?) {type=ostring_rt_type; value=string}

    public init(object: AnyObject?) {type=oclass_rt_type; value=object}
    
    public init(`struct` s: Any?) {type=ostruct_rt_type; value=s}
    
    public init(`enum` e: Any?) {type=oenum_rt_type; value=e}
}

public struct MemoryAddress<T>: CustomStringConvertible {

    public var intValue: UInt64

    public var description: String {
        let length = 2 + 2 * MemoryLayout<UnsafeRawPointer>.size
        return String(format: "%0\(length)p", intValue)
    }

    // for structures 
    public init(of structPointer: UnsafePointer<T>) {
        intValue = unsafeBitCast(structPointer, to: UInt64.self) //UInt64(bitPattern: structPointer)
    }
}

public extension MemoryAddress where T: AnyObject {

    // for classes
    public init(of classInstance: T) {
        intValue = unsafeBitCast(classInstance, to: UInt64.self)
        // or      Int(bitPattern: Unmanaged<T>.passUnretained(classInstance).toOpaque())
    }
}

var globalProcessHandle:UnsafeMutableRawPointer?=nil

public func symbolAdressOf(name: String) -> UInt64 {
    #if WINDOWS
    #else
    if globalProcessHandle==nil {globalProcessHandle = dlopen(nil, RTLD_NOW)}
    if globalProcessHandle != nil {
        //print("global process got")
        //delete prefix _ from name
        if name.first=="_" {
            var pname=String(name.dropFirst())
            let sym = dlsym(globalProcessHandle, pname)
            if sym != nil {
                print("resolved ",name," to ",sym)
                return unsafeBitCast(sym, to: UInt64.self)
            }
                    
            //needed for objc_empty_cache
            let sym1 = dlsym(globalProcessHandle, name)
            if sym1 != nil {
                print("resolved ",name," to ",sym1)
                return unsafeBitCast(sym1, to: UInt64.self)
            }
        }
        else {
            let sym = dlsym(globalProcessHandle, name)
            if sym != nil {
                print("resolved ",name," to ",sym)
                return unsafeBitCast(sym, to: UInt64.self)
            }
        }
        //print("symbol ",pname,"not found")
        
        /*if name=="$sSSN" {
            return unsafeBitCast(Int.self, to: UInt64.self)
        }*/
    }
    #endif 

    print("resolver symbol ",name,"not found")
    
    //if name=="_hostCall" {return unsafeBitCast(hostCallp, to: UInt64.self)}
            
    //if name=="_objc_empty_cache" {return MemoryAddress(of: &objc_empty_cache).intValue}

    return 0
}

func sizeof <T> (_ : T.Type) -> Int
{
    return (MemoryLayout<T>.size)
}

func sizeof <T> (_ : T) -> Int
{
    return (MemoryLayout<T>.size)
}

func sizeof <T> (_ value : [T]) -> Int
{
    return (MemoryLayout<T>.size * value.count)
}

func sizeof<T:FixedWidthInteger>(_ int:T) -> Int {
    return int.bitWidth/UInt8.bitWidth
}

func sizeof<T:FixedWidthInteger>(_ intType:T.Type) -> Int {
    return intType.bitWidth/UInt8.bitWidth
}

extension FixedWidthInteger {
    var byteWidth:Int {
        return self.bitWidth/UInt8.bitWidth
    }
    static var byteWidth:Int {
        return Self.bitWidth/UInt8.bitWidth
    }
}

protocol ConformanceMarker {}
enum BinaryIntegerMarker<T> {}
extension BinaryIntegerMarker: ConformanceMarker where T: BinaryInteger {}
enum OptionalMarker<T> {}
extension OptionalMarker: ConformanceMarker where T: OptionalProtocol {}

func isBinaryIntegerType<T>(_ t: T.Type) -> Bool {
  return BinaryIntegerMarker<T>.self is ConformanceMarker.Type
}

func isBinaryInteger<T>(_ t: T) -> Bool {
  return isBinaryIntegerType(T.self)
}

func isOptionalType<T>(_ t: T.Type) -> Bool {
  return OptionalMarker<T>.self is ConformanceMarker.Type
}

func isOptional<T>(_ t: T) -> Bool {
  return isOptionalType(T.self)
}

/*public func typeToFFIType<T>(type: T.Type) -> Pffi_type {
    if isBinaryIntegerType(type) {
        let sz=sizeof(type)
        let bitWidth=sz / 8
            
        if bitWidth==8 {
            if type is UInt8 {return pffi_type_uint8}
            return pffi_type_sint8
        }
        else if bitWidth==16 {
            if type is UInt16 {return pffi_type_uint16}
            return pffi_type_sint16
        }
        else if bitWidth==32 {
            if type is UInt32 {return pffi_type_uint32}
            return pffi_type_sint32
        }
        else if bitWidth==64 {
            if type is UInt64 {return pffi_type_uint64}
            return pffi_type_sint64
        }
    }
    
    if type is OptionalProtocol/*isOptional(type)*/ {
        return pffi_type_pointer
    }
    
    if type is Float {return pffi_type_float}
    if type is Double {return pffi_type_double}
    
    //everything else is a pointer, note that structs are handled separately
    return pffi_type_pointer
}*/

public func directAllocation<T>(t: T) -> UnsafeMutablePointer<T>? {
    let tPtr = UnsafeMutablePointer<T>.allocate(capacity: 1)
    tPtr.initialize(repeating: t, count: 1)
    tPtr.assign(repeating: t, count: 1)
    return tPtr
}

public func directAllocation<T>(t: [T]) -> UnsafeMutablePointer< UnsafeMutablePointer<T>? >? {
    let count=t.count
    let tPtr = UnsafeMutablePointer< UnsafeMutablePointer <T>? >.allocate(capacity: count)
    //tPtr.initialize(repeating: t, count: count)
    //tPtr.assign(repeating: t, count: count)
    var index=0
    for e in t {
        tPtr.advanced(by: index).pointee = directAllocation(t: e)
        index = index + 1
    }
    return tPtr
}

/*public func alloc_ffi() -> Pffi_cif {
    //return get_ffi_cif()
    return UnsafeMutablePointer<ffi_cif>.allocate(capacity: 1)
}

public func dealloc_type(type: Pffi_type) {
    if type == nil {return}
    
    //dealloc structs
    if type!.pointee.type == FFI_TYPE_STRUCT {
        if type!.pointee.elements != nil {
            //deallocate struct members
            //elements is null terminated
            var index=0
            while true {
                if let t=type!.pointee.elements.advanced(by: index).pointee {
                    dealloc_type(type: t)
                    index=index+1
                }
                else {break}
            }
        }
        
        type!.deallocate()
    }
    
    //types except structs are just static fixed pointers
}

public func dealloc_ffi(cif: Pffi_cif) {
    if cif == nil {return}
    
    dealloc_type(type: cif!.pointee.rtype)
    cif!.pointee.rtype=nil
    cif!.pointee.rtype=nil
    if cif!.pointee.arg_types != nil {
        for index in 0..<cif!.pointee.nargs {
            if let t=cif!.pointee.arg_types.advanced(by: Int(index)).pointee {
                dealloc_type(type: t)
                
            }
        }
        cif!.pointee.arg_types=nil
    }
    
    cif!.deallocate()
    
    //free_ffi_cif(cif)
    

}

public func dump_ffi_type(type: Pffi_type) {
    //type!.withMemoryRebound(to: ffi_type.self, capacity: 1) { t in
    if let t=type?.pointee {
        print("type size:", t.size)
        print("type alignment:", t.alignment)
        print("type type:", t.type)
        print("type elements:", t.elements)
    }
    else {print("type: nil")}
}

public func prep_ffi(cif: Pffi_cif, returnType: Pffi_type, argTypes: [Pffi_type]) -> ffi_status {
    let acount=argTypes.count
    //let rPtr = directAllocation(t: returnType)
    //let argPtr = directAllocation(t: argTypes)
    
    //print("prep ffi start")
    
    let argPtr = UnsafeMutablePointer< UnsafeMutablePointer <ffi_type>? >.allocate(capacity: acount)
    var index=0
    for e in argTypes {
        argPtr.advanced(by: index).pointee = e
        index = index + 1
    }
    
    //print("prepping ffi with ", acount, "args")

    return ffi_prep_cif(cif, FFI_DEFAULT_ABI, UInt32(argTypes.count), returnType/*rPtr*/, argPtr);

    //print("prepped ffi")
}

public func call_ffi_method (cif: Pffi_cif, addr:UInt64, this: Any?, args:inout [RuntimeValue], returnType: RuntimeSwiftType ) -> RuntimeValue {
    var s=this
    let pu:UnsafeMutableRawPointer=UnsafeMutableRawPointer(&s)
    
    //reserve 128 bytes for result, not that structs from 8..16 bytes are also returned here
    let result:UnsafeMutableRawPointer=getResultPtr()
    
    //var aargs:UnsafeMutablePointer< UnsafeMutableRawPointer? >? = nil
    let aargs=UnsafeMutablePointer< UnsafeMutablePointer<Any>? >.allocate(capacity: args.count)
    //let aargsptr=UnsafeMutableRawPointer(&args)
    var index=0
    var a1=args
    let argsp=UnsafeMutablePointer<RuntimeValue>(&a1)
    for a in args {
        //aargs.advanced(by: index).pointee = UnsafeMutableRawPointer(directAllocation(t: a)) //aargsptr+index
        aargs.advanced(by: index).pointee=UnsafeMutablePointer(&(argsp.advanced(by: index).pointee.value))
        //print("got arg#",index,":",argsp.advanced(by: index).pointee.value,"->",aargs.advanced(by: index).pointee)
        index=index+1 
    }
    //aargs.advanced(by: index).pointee=nil //terminator

    let a=unsafeBitCast(aargs, to:UnsafeMutablePointer< UnsafeMutableRawPointer? >.self)
    
    #if WINDOWS
    print("Windows calling addr ",addr)
    print("Windows args(\(cif!.pointee.nargs)):")
    for i in 0..<args.count {
        let a:UnsafeMutablePointer<Any>?=aargs.advanced(by: i).pointee
        print(a!.pointee)
    }
    if returnType.0 == .int {result.storeBytes(of: 0x0000_0009 , as: Int.self)}
    #else
    
    swift_ffi_call_int (cif, addr, pu, result , a, nil)
    #endif
    
    
    aargs.deallocate()
    
    //print("returning type=",returnType)
    
    switch returnType.0/*Int32(cif!.pointee.rtype?.pointee.type ?? 0)*/ {
        case .void/*FFI_TYPE_VOID*/:
            //print("got void result")
            releaseResultPtr(result)
            //return NilAny
            return RuntimeValue()

        case .nil/*FFI_TYPE_VOID*/:
            //print("got nil result")
            releaseResultPtr(result)
            //return NilAny
            return RuntimeValue()
        
        case .int8/*FFI_TYPE_SINT8*/:
            if (returnType.2 & RuntimeSwiftType_Optional) != 0/*optional*/ {
                let i = result.load(as: Int8?.self) 
                releaseResultPtr(result)
                //return i
                return RuntimeValue(int8:i)
            }
            let i = result.load(as: Int8.self) 
            releaseResultPtr(result)
            //return i
            return RuntimeValue(int8:i)
        case .int16/*FFI_TYPE_SINT16*/:
            if (returnType.2 & RuntimeSwiftType_Optional) != 0/*optional*/ {
                let i = result.load(as: Int16?.self) 
                releaseResultPtr(result)
                //return i
                return RuntimeValue(int16:i)
            }
            let i = result.load(as: Int16.self) 
            releaseResultPtr(result)
            //return i
            return RuntimeValue(int16:i)
        case .int32/*FFI_TYPE_SINT32*/:
            if (returnType.2 & RuntimeSwiftType_Optional) != 0/*optional*/ {
                let i = result.load(as: Int32?.self) 
                releaseResultPtr(result)
                //return i
                return RuntimeValue(int32:i)
            }
            let i = result.load(as: Int32.self) 
            releaseResultPtr(result)
            //return i
            return RuntimeValue(int32:i)
        case .int/*FFI_TYPE_SINT64*/:
            if (returnType.2 & RuntimeSwiftType_Optional) != 0/*optional*/ {
                let i = result.load(as: Int?.self) 
                releaseResultPtr(result)
                //return i
                return RuntimeValue(int:i)
            }
            let i = result.load(as: Int.self) 
            releaseResultPtr(result)
            //return i
            return RuntimeValue(int:i)
            
        case .uint8/*FFI_TYPE_UINT8*/:
            if (returnType.2 & RuntimeSwiftType_Optional) != 0/*optional*/ {
                let u = result.load(as: UInt8?.self) 
                releaseResultPtr(result)
                //return u
                return RuntimeValue(uint8:u)
            }
            let u = result.load(as: UInt8.self) 
            releaseResultPtr(result)
            //return u
            return RuntimeValue(uint8:u)
        case .uint16/*FFI_TYPE_UINT16*/:
            if (returnType.2 & RuntimeSwiftType_Optional) != 0/*optional*/ {
                let u = result.load(as: UInt16?.self) 
                releaseResultPtr(result)
                //return u
                return RuntimeValue(uint16:u)
            }
            let u = result.load(as: UInt16.self) 
            releaseResultPtr(result)
            //return u
            return RuntimeValue(uint16:u)
        case .uint32/*FFI_TYPE_UINT32*/:
            if (returnType.2 & RuntimeSwiftType_Optional) != 0/*optional*/ {
                let u = result.load(as: UInt32?.self) 
                releaseResultPtr(result)
                //return u
                return RuntimeValue(uint32:u)
            }
            let u = result.load(as: UInt32.self) 
            releaseResultPtr(result)
            //return u
            return RuntimeValue(uint32:u)
        case .uint/*FFI_TYPE_UINT64*/:
            if (returnType.2 & RuntimeSwiftType_Optional) != 0/*optional*/ {
                let u = result.load(as: UInt?.self) 
                releaseResultPtr(result)
                //return u
                return RuntimeValue(uint:u)
            }
            let u = result.load(as: UInt.self) 
            releaseResultPtr(result)
            //return u
            return RuntimeValue(uint:u)
            
        case .float/*FFI_TYPE_FLOAT*/:
            if (returnType.2 & RuntimeSwiftType_Optional) != 0/*optional*/ {
                let f = result.load(as: Float?.self) 
                releaseResultPtr(result)
                //return f
                return RuntimeValue(float:f)
            }
            let f = result.load(as: Float.self) 
            releaseResultPtr(result)
            //return f
            return RuntimeValue(float:f)
        case .double/*FFI_TYPE_DOUBLE*/:
            if (returnType.2 & RuntimeSwiftType_Optional) != 0/*optional*/ {
                let d = result.load(as: Double?.self) 
                releaseResultPtr(result)
                //return d
                return RuntimeValue(double:d)
            }
            let d = result.load(as: Double.self) 
            releaseResultPtr(result)
            //return d
            return RuntimeValue(double:d)
            
        //todo check structs with size <=16 bytes
            
        default:
            //everything else is a pointer
            //todo structs?
            if (returnType.2 & RuntimeSwiftType_Optional) != 0/*optional*/ {
                let o = result.load(as: AnyObject?.self) 
                releaseResultPtr(result)
                //return i
                return RuntimeValue(object:o)
            }
            let o = result.load(as: AnyObject.self) 
            releaseResultPtr(result)
            //return o
            return RuntimeValue(object:o)
    }
    
    //print("call ret=",r)
    
    //r.deallocate()
    
    return RuntimeValue() //void
}*/


/*

withUnsafePointer(&i, { (ptr: UnsafePointer<Int>) -> Void in
    var vptr= UnsafeRawPointer(ptr)
    functionThatNeedsAVoidPointer(vptr)
})

let r = withUnsafePointer(&i, { (ptr: UnsafePointer<Int>) -> Int in
    var vptr= UnsafeRawPointer(ptr)
    return functionThatNeedsAVoidPointerAndReturnsInt(vptr)
})

func directAllocation<T>(t: T, count: Int) {
    let tPtr = UnsafeMutablePointer<T>.allocate(capacity: count)
    tPtr.initialize(repeating: t, count: count)
    tPtr.assign(repeating: t, count: count)
    tPtr.deinitialize(count: count)
    tPtr.deallocate()
}

func rawAllocate<T>(t: T, numValues: Int) -> UnsafeMutablePointer<T> {
    let rawPtr = UnsafeMutableRawPointer.allocate(
            byteCount: MemoryLayout<T>.stride * numValues,
            alignment: MemoryLayout<T>.alignment)
    let tPtr = rawPtr.initializeMemory(as: T.self, repeating: t, count: numValues)
    // Must use the typed pointer ‘tPtr’ to deinitialize.
    return tPtr
}


let pointer = UnsafeMutablePointer<Int>.allocate(capacity: count)
  pointer.initialize(repeating: 0, count: count)
  defer {
    pointer.deinitialize(count: count)
    pointer.deallocate()
  }
  
  pointer.pointee = 42
  pointer.advanced(by: 1).pointee = 6
  pointer.pointee
  pointer.advanced(by: 1).pointee
  
  let bufferPointer = UnsafeBufferPointer(start: pointer, count: count)
  for (index, value) in bufferPointer.enumerated() {
    print("value \(index): \(value)")
  }
  
  
  print("Converting raw pointers to typed pointers")
  
  let rawPointer = UnsafeMutableRawPointer.allocate(
    byteCount: byteCount,
    alignment: alignment)
  defer {
    rawPointer.deallocate()
  }
  
  let typedPointer = rawPointer.bindMemory(to: Int.self, capacity: count)
  typedPointer.initialize(repeating: 0, count: count)
  defer {
    typedPointer.deinitialize(count: count)
  }

  typedPointer.pointee = 42
  typedPointer.advanced(by: 1).pointee = 6
  typedPointer.pointee
  typedPointer.advanced(by: 1).pointee
  
  let bufferPointer = UnsafeBufferPointer(start: typedPointer, count: count)
  for (index, value) in bufferPointer.enumerated() {
    print("value \(index): \(value)")
  }
  
  print("Getting the bytes of an instance")
  
  var sampleStruct = SampleStruct(number: 25, flag: true)

  withUnsafeBytes(of: &sampleStruct) { bytes in
    for byte in bytes {
      print(byte)
    }
  }
  
  // Rule #1
do {
  print("1. Don't return the pointer from withUnsafeBytes!")
  
  var sampleStruct = SampleStruct(number: 25, flag: true)
  
  let bytes = withUnsafeBytes(of: &sampleStruct) { bytes in
    return bytes // strange bugs here we come ☠️☠️☠️
  }
  
  print("Horse is out of the barn!", bytes) // undefined!!!
}


*/















