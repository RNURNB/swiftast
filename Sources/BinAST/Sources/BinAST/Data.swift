import Foundation

public extension Data {
    
    /*
    /// Returns a Data object initialized by decompressing the data from the file specified by `path` using the given `compression` algorithm.
    /// 
    ///     let data = Data(contentsOfArchive: absolutePathToFile, usedCompression: Compression.lzfse)
    ///
    /// - Parameter contentsOfArchive: The absolute path of the file from which to read data
    /// - Parameter usedCompression: Algorithm to use during decompression. If compression is nil, attempts to determine the appropriate decompression algorithm using the path's extension
    /// - Returns: A Data object initialized by decompressing the data from the file specified by `path` using the given `compression` algorithm. Returns `nil` if decompression fails.
    static public func dataWithContentsOfArchive( path: String, usedCompression: Compression?) -> Data? {
        let pathURL = URL(fileURLWithPath: path)
        
        // read in the compressed data from disk
        guard let compressedData = try? Data(contentsOf: pathURL)  else {
            return nil
        }
        
        // if compression is set use it
        let compression: Compression
        if usedCompression != nil {
            compression = usedCompression!
        }
        else {
            // otherwise, attempt to use the file extension to determine the compression algorithm
            switch pathURL.pathExtension.lowercased() {
            case "lz4"  :    compression = Compression.lz4
            case "zlib" :    compression = Compression.zlib
            case "lzma" :    compression = Compression.lzma
            case "lzfse":    compression = Compression.lzfse
            default:        return nil
            }
        }
        
        // finally, attempt to uncompress the data and initalize self
        if let uncompressedData = compressedData.uncompressed(using: compression) {
            return uncompressedData
        }
        else {
            return nil
        }
    }
    
    
    /// Returns a Data object created by compressing the receiver using the given compression algorithm.
    ///
    ///     let compressedData = someData.compressed(using: Compression.lzfse)
    ///
    /// - Parameter using: Algorithm to use during compression
    /// - Returns: A Data object created by encoding the receiver's contents using the provided compression algorithm. Returns nil if compression fails or if the receiver's length is 0.
    public func compressed(using compression: Compression) -> Data? {
        return self.data(using: compression, operation: .encode)
    }
    
    /// Returns a Data object by uncompressing the receiver using the given compression algorithm.
    ///
    ///     let uncompressedData = someCompressedData.uncompressed(using: Compression.lzfse)
    ///
    /// - Parameter using: Algorithm to use during decompression
    /// - Returns: A Data object created by decoding the receiver's contents using the provided compression algorithm. Returns nil if decompression fails or if the receiver's length is 0.
    public func uncompressed(using compression: Compression) -> Data? {
        return self.data(using: compression, operation: .decode)
    }
    
    
    private enum CompressionOperation {
        case encode
        case decode
    }
    
    private func data(using compression: Compression, operation: CompressionOperation) -> Data? {
        
        guard self.count > 0 else {
            return nil
        }
        
        let streamPtr = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
        var stream = streamPtr.pointee
        var status : compression_status
        var op : compression_stream_operation
        var flags : Int32
        var algorithm : compression_algorithm
        
        switch compression {
        case .lz4:
            algorithm = COMPRESSION_LZ4
        case .lzfse:
            algorithm = COMPRESSION_LZFSE
        case .lzma:
            algorithm = COMPRESSION_LZMA
        case .zlib:
            algorithm = COMPRESSION_ZLIB
        }
        
        switch operation {
        case .encode:
            op = COMPRESSION_STREAM_ENCODE
            flags = Int32(COMPRESSION_STREAM_FINALIZE.rawValue)
        case .decode:
            op = COMPRESSION_STREAM_DECODE
            flags = 0
        }
        
        status = compression_stream_init(&stream, op, algorithm)
        guard status != COMPRESSION_STATUS_ERROR else {
            // an error occurred
            return nil
        }
        
        let outputData = withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Data? in
            // setup the stream's source
            stream.src_ptr = bytes
            stream.src_size = count
            
            // setup the stream's output buffer
            // we use a temporary buffer to store the data as it's compressed
            let dstBufferSize : size_t = 4096
            let dstBufferPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: dstBufferSize)
            stream.dst_ptr = dstBufferPtr
            stream.dst_size = dstBufferSize
            // and we store the output in a mutable data object
            var outputData = Data()
            
            
            repeat {
                status = compression_stream_process(&stream, flags)
                
                switch status {
                case COMPRESSION_STATUS_OK:
                    // Going to call _process at least once more, so prepare for that
                    if stream.dst_size == 0 {
                        // Output buffer full...
                        
                        // Write out to outputData
                        outputData.append(dstBufferPtr, count: dstBufferSize)
                        
                        // Re-use dstBuffer
                        stream.dst_ptr = dstBufferPtr
                        stream.dst_size = dstBufferSize
                    }
                    
                case COMPRESSION_STATUS_END:
                    // We are done, just write out the output buffer if there's anything in it
                    if stream.dst_ptr > dstBufferPtr {
                        outputData.append(dstBufferPtr, count: stream.dst_ptr - dstBufferPtr)
                    }
            
                case COMPRESSION_STATUS_ERROR:
                    return nil
                    
                default:
                    break
                }
                
            } while status == COMPRESSION_STATUS_OK
            
            return outputData
        }
        
        compression_stream_destroy(&stream)
        
        return outputData
    }
    */
    
    
    func copyBytes<T>(ofs:Int,as _: T.Type,elemcount:Int) -> [T] {
        return withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in
           //Array(UnsafeBufferPointer(start: UnsafeRawPointer(bytes+ofs), count: count / MemoryLayout<T>.stride))
           let ptr=bytes+ofs
           let buffer = ptr.withMemoryRebound(to: T.self, capacity: elemcount ) {
              UnsafeBufferPointer(start: $0, count: elemcount )
           }
           return Array<T>(buffer)
        }
    }
}

public struct DataExt : Hashable {
     var pair : (p: Int, q: Int, r:Int, s:Int)

     public func hash(into hasher: inout Hasher) {
         hasher.combine(pair.p)
         hasher.combine(pair.q)
         hasher.combine(pair.r)
         hasher.combine(pair.s)
     }
}

public func ==(left: DataExt, right: DataExt) -> Bool {          // Needed to be Equatable
     return left.pair == right.pair
}

public class SCLData:NSObject{
    var data:Data
    var ofs:Int=0
    public var isRoot=true
    public var version=0
    public var extratuples:[DataExt:Int]=[:]
    public var extratuplesmap:[Int:DataExt]=[:]
    public var importmapping:[Int:ASTModule]=[:]
    public var typeIndex:Int=0 //current type index
    public var types:[Int:ASTType]=[:]
    
    public override required init() {
        data=Data()
        super.init()
    }
    
    public init(contentsOfFile: String) throws {
        data=try Data(contentsOf:URL(fileURLWithPath: contentsOfFile),options:.mappedIfSafe)
    }
    
    public init?(contentsOfFile: String, options: NSData.ReadingOptions) throws {
        data=try Data(contentsOf:URL(fileURLWithPath: contentsOfFile),options:options)
    }
    
    public init(contentsOf: URL) throws {
        data=try Data(contentsOf:contentsOf,options:.mappedIfSafe)
    }
    
    public init?(contentsOf: URL, options: NSData.ReadingOptions) throws {
        data=try Data(contentsOf:contentsOf,options:options)
    }
    
    public init(data:Data) {
        self.data=Data(data)
    }
    
    public func rawData() -> Data {
        return data
    }
    
    public func save(toFile: String) throws {
        try save(toFile:toFile,options:.atomic)
    }
    
    public func save(toFile: String, options: Data.WritingOptions) throws {
        try data.write(to:URL(fileURLWithPath: toFile),options:options)
    }
    
    func save(to: URL) throws {
        try save(to:to,options:.atomic)
    }
    
    public func save(to: URL, options: Data.WritingOptions) throws {
        try data.write(to:to,options:options)
    }
   
    /*public func compress() throws {
        data = try data.compressed(using: .lzfse)!
        ofs=0
    }
    
    public func uncompress() throws {
        data = try data.uncompressed(using: .lzfse)!
        ofs=0

    }
    
    public func compressed() -> SCLData? {
        do {
           let compressedData = try data.compressed(using: .lzfse)
           if (compressedData==nil) {return nil}
           return SCLData(data:compressedData!)
        } catch {
           return nil
        }
    }
    
    public func uncompressed() -> SCLData? {
        do {
           let uncompressedData = try data.uncompressed(using: .lzfse)
           if (uncompressedData==nil) {return nil}
           return SCLData(data:uncompressedData!)
        } catch {
           return nil
        }
    }*/
   
    
    public func readByte(ofs:UInt?=nil) -> UInt8 {
        if ofs != nil {self.ofs=Int(ofs!)}
        //let R:[UInt8]=data.copyBytes(ofs:self.ofs,as:UInt8.self,elemcount:1)
        return data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in
           let ptr=bytes+self.ofs
           self.ofs += 1
           return ptr[0]
        }
        //self.ofs += 1
        //return R[0]
    }
    
    public func writeByte(_ b:UInt8) {
        var bb=b
        data.append(&bb,count:1)
        self.ofs += 1
    }
    
    public func readWord(ofs:UInt?=nil) -> UInt16 {
        let R:UInt16=read(ofs:ofs)
        return R
    }
    
    public func writeWord(_ i:UInt16) {
        var ii=i
        write(&ii)
    }
    
    public func readCardinal(ofs:UInt?=nil) -> UInt32 {
        let R:UInt32=read(ofs:ofs)
        return R
    }
    
    public func writeCardinal(_ i:UInt32) {
        var ii=i
        write(&ii)
    }
    
    public func readLongWord(ofs:UInt?=nil) -> UInt64 {
        let R:UInt64=read(ofs:ofs)
        return R
    }
    
    public func writeLongWord(_ i:UInt64) {
        var ii=i
        write(&ii)
    }
    
    public func readInt(ofs:UInt?=nil) -> Int {
        let R:Int=read(ofs:ofs)
        return R
    }
    
    public func writeInt(_ i:Int) {
        var ii=i
        write(&ii)
    }
    
    public func readInt8(ofs:UInt?=nil) -> Int8 {
        let R:Int8=read(ofs:ofs)
        return R
    }
    
    public func writeInt8(_ i:Int8) {
        var ii=i
        write(&ii)
    }
    
    public func readInt16(ofs:UInt?=nil) -> Int16 {
        let R:Int16=read(ofs:ofs)
        return R
    }
    
    public func writeInt16(_ i:Int16) {
        var ii=i
        write(&ii)
    }
    
    public func readInt32(ofs:UInt?=nil) -> Int32 {
        let R:Int32=read(ofs:ofs)
        return R
    }
    
    public func writeInt32(_ i:Int32) {
        var ii=i
        write(&ii)
    }
    
    public func readInt64(ofs:UInt?=nil) -> Int64 {
        let R:Int64=read(ofs:ofs)
        return R
    }
    
    public func writeInt64(_ i:Int64) {
        var ii=i
        write(&ii)
    }
    
    public func readFloat(ofs:UInt?=nil) -> Float {
        let R:Float=read(ofs:ofs)
        return R
    }
    
    public func writeFloat(_ f:Float) {
        var ff=f
        write(&ff)
    }
    
    public func readDouble(ofs:UInt?=nil) -> Double {
        let R:Double=read(ofs:ofs)
        return R
    }
    
    public func writeDouble(_ d:Double) {
        var dd=d
        write(&dd)
    }
    
    public func readCharacter(ofs:UInt?=nil) -> Character {
        let C:Character=read(ofs:ofs)
        return C
    }
    
    public func writeCharacter(_ c:Character) {
        var cc=c
        write(&cc)
    }
    
    public func readBool(ofs:UInt?=nil) -> Bool {
        return readByte(ofs:ofs) != 0
    }
    
    public func writeBool(_ b:Bool) {
        writeByte(b ? 1 : 0)
    }
    
    public func read<T>(ofs:UInt?=nil) -> T {
        if ofs != nil {self.ofs=Int(ofs!)}
        let R:[T]=data.copyBytes(ofs:self.ofs,as:T.self,elemcount:1)
        self.ofs += MemoryLayout.size(ofValue:R[0])
        return R[0]
    }
    
    public func write<T>(_ b:inout T) {
        let c=MemoryLayout.size(ofValue: b)
        var cc=0
        withUnsafeBytes(of: &b) { bytes in
           /*for byte in bytes {
              //print(byte)
              var bb=byte
              data.append(&bb,count:1)
              cc += 1
           }*/
           data.append(contentsOf:bytes)
           cc += bytes.count
        }
        //data.append(&b,count:c)
        while cc<c {
            var bb:UInt8=0
            data.append(&bb,count:1)
            cc += 1
        }
        self.ofs += c
    }
    
    public func readArray<T>(elementCount:UInt,ofs:UInt?=nil) -> [T] {
        if ofs != nil {self.ofs=Int(ofs!)}
        let c=Int(elementCount)*MemoryLayout<T>.stride
        let R:[T]=data.copyBytes(ofs:self.ofs,as:T.self,elemcount:Int(elementCount))
        self.ofs += c
        return R
    }
    
    public func writeArray<T>(_ a:[T]) {
        //let data = Data(buffer: UnsafeBufferPointer(start: a, count: a.count))
        //self.append(data)
        //let ptr=UnsafeBufferPointer(start: a, count: a.count)
        //let c=a.count*MemoryLayout<T>.stride
        //data.append(ptr.baseAddress!,count:c)
        //self.ofs += c
        let c=MemoryLayout<T>.stride
        for elem in a {
            var cc=0
            var e=elem
            withUnsafeBytes(of: &e) { bytes in
               /*for byte in bytes {
                 //print(byte)
                 var bb=byte
                 data.append(&bb,count:1)
                 cc += 1
               }*/
               data.append(contentsOf:bytes)
               cc += bytes.count
            }
            while cc<c {
               var bb:UInt8=0
               data.append(&bb,count:1)
               cc += 1
            }
        }
        self.ofs += a.count * c
    }
    
    public func readByteArray(elementCount:UInt,ofs:UInt?=nil) -> [UInt8]
    {
        let R:[UInt8]=readArray(elementCount:elementCount,ofs:ofs)
        return R
    }
    
    public func writeByteArray(_ a:[UInt8]) {
        writeArray(a)
    }
    
    //returns nil on error
    public func readString(ofs:UInt?=nil) -> String? {
        let c=readInt(ofs:ofs)
        if c==0 {return ""}
        let byteArray:[UInt8]=readArray(elementCount:UInt(c),ofs:UInt(self.ofs))
        let R = String(data: Data(byteArray), encoding: .utf8)
        return R
    }
    
    //returns nil on error
    public func getString(len:UInt,ofs:UInt?=nil) -> String? {
        if ofs != nil {self.ofs=Int(ofs!)}
        if len==0 {return ""}
        let byteArray:[UInt8]=readArray(elementCount:UInt(len),ofs:UInt(self.ofs))
        let R = String(data: Data(byteArray), encoding: .utf8)
        return R
    }
    
    public func writeString(_ s:String) {
        let byteArray: [UInt8] = s.utf8.map{UInt8($0)}
        writeInt(byteArray.count)
        if byteArray.count==0 {return}
        writeArray(byteArray)
    }
    
    public func readShortString(ofs:UInt?=nil) -> String? {
        let c=readByte(ofs:ofs)
        if c==0 {return ""}
        let byteArray:[UInt8]=readArray(elementCount:UInt(c),ofs:UInt(self.ofs))
        let R = String(data: Data(byteArray), encoding: .utf8)
        return R
    }
    
    public func writeShortString(_ s:String) {
        let byteArray: [UInt8] = s.utf8.map{UInt8($0)}
        writeByte(UInt8(byteArray.count))
        if byteArray.count==0 {return}
        writeArray(byteArray)
    }
    
    //returns nil on error
    public func readAsciiString(ofs:UInt?=nil) -> String? {
        let c=readInt(ofs:ofs)
        if c==0 {return ""}
        let byteArray:[UInt8]=readArray(elementCount:UInt(c),ofs:UInt(self.ofs))
        let R = String(data: Data(byteArray), encoding: .ascii)
        return R
    }
    
    //returns nil on error
    public func getAsciiString(len:UInt,ofs:UInt?=nil) -> String? {
        if ofs != nil {self.ofs=Int(ofs!)}
        if len==0 {return ""}
        let byteArray:[UInt8]=readArray(elementCount:UInt(len),ofs:UInt(self.ofs))
        let R = String(data: Data(byteArray), encoding: .ascii)
        return R
    }
    
    public func writeAsciiString(_ s:String) {
        let byteArray: [UInt8] = s.utf8.map{UInt8($0)}
        writeInt(byteArray.count)
        if byteArray.count==0 {return}
        writeArray(byteArray)
    }
    
    public func readData(count:Int,ofs:UInt?=nil) -> Data {
        if ofs != nil {self.ofs=Int(ofs!)}
        let byteArray:[UInt8]=readArray(elementCount:UInt(count),ofs:UInt(self.ofs))
        return Data(byteArray)
    }
    
    public func writeData(data:Data) {
        self.data.append(data)
        ofs += data.count
    }
}




















