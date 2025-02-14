import Foundation
import Compression

/// Service for managing compression operations
public final class CompressionManager: @unchecked Sendable {
    /// Shared instance
    public static let shared = CompressionManager()
    
    /// Whether LZMA compression is available
    private let isLZMAAvailable: Bool
    
    /// Initialize compression manager
    private init() {
        // Check LZMA availability
        var stream = compression_stream()
        isLZMAAvailable = (compression_stream_init(
            &stream,
            COMPRESSION_STREAM_ENCODE,
            COMPRESSION_LZMA
        ) == COMPRESSION_STATUS_OK)
        
        if isLZMAAvailable {
            compression_stream_destroy(&stream)
        }
    }
    
    /// Compress data using LZMA
    /// - Parameter data: Data to compress
    /// - Returns: Compressed data
    /// - Throws: CompressionError if compression fails
    public func compress(_ data: Data) throws -> Data {
        guard isLZMAAvailable else {
            throw CompressionError.lzmaUnavailable
        }
        
        var stream = compression_stream()
        let initResult = compression_stream_init(
            &stream,
            COMPRESSION_STREAM_ENCODE,
            COMPRESSION_LZMA
        )
        guard initResult == COMPRESSION_STATUS_OK else {
            throw CompressionError.initializationFailed
        }
        defer { compression_stream_destroy(&stream) }
        
        let bufferSize = 32768
        var compressedData = Data()
        var sourceBuffer = Array(data)
        var destinationBuffer = [UInt8](repeating: 0, count: bufferSize)
        
        stream.src_ptr = sourceBuffer
        stream.src_size = sourceBuffer.count
        stream.dst_ptr = &destinationBuffer
        stream.dst_size = bufferSize
        
        repeat {
            let status = compression_stream_process(&stream, 0)
            
            switch status {
            case COMPRESSION_STATUS_OK, COMPRESSION_STATUS_END:
                let count = bufferSize - stream.dst_size
                compressedData.append(destinationBuffer[0..<count])
                stream.dst_ptr = &destinationBuffer
                stream.dst_size = bufferSize
                
            case COMPRESSION_STATUS_ERROR:
                throw CompressionError.compressionFailed
                
            default:
                throw CompressionError.unknownError
            }
            
        } while stream.src_size > 0
        return compressedData
    }
    
    /// Decompress LZMA compressed data
    /// - Parameter data: Compressed data
    /// - Returns: Decompressed data
    /// - Throws: CompressionError if decompression fails
    public func decompress(_ data: Data) throws -> Data {
        guard isLZMAAvailable else {
            throw CompressionError.lzmaUnavailable
        }
        
        var stream = compression_stream()
        let initResult = compression_stream_init(
            &stream,
            COMPRESSION_STREAM_DECODE,
            COMPRESSION_LZMA
        )
        guard initResult == COMPRESSION_STATUS_OK else {
            throw CompressionError.initializationFailed
        }
        defer { compression_stream_destroy(&stream) }
        
        let bufferSize = 32768
        var decompressedData = Data()
        var sourceBuffer = Array(data)
        var destinationBuffer = [UInt8](repeating: 0, count: bufferSize)
        
        stream.src_ptr = sourceBuffer
        stream.src_size = sourceBuffer.count
        stream.dst_ptr = &destinationBuffer
        stream.dst_size = bufferSize
        
        repeat {
            let status = compression_stream_process(&stream, 0)
            
            switch status {
            case COMPRESSION_STATUS_OK, COMPRESSION_STATUS_END:
                let count = bufferSize - stream.dst_size
                decompressedData.append(destinationBuffer[0..<count])
                stream.dst_ptr = &destinationBuffer
                stream.dst_size = bufferSize
                
            case COMPRESSION_STATUS_ERROR:
                throw CompressionError.decompressionFailed
                
            default:
                throw CompressionError.unknownError
            }
            
        } while stream.src_size > 0 || status == COMPRESSION_STATUS_OK
        return decompressedData
    }
}

/// Compression related errors
public enum CompressionError: LocalizedError {
    /// LZMA compression is not available
    case lzmaUnavailable
    /// Failed to initialize compression stream
    case initializationFailed
    /// Compression operation failed
    case compressionFailed
    /// Decompression operation failed
    case decompressionFailed
    /// Unknown error occurred
    case unknownError
    
    public var errorDescription: String? {
        switch self {
        case .lzmaUnavailable:
            return "LZMA compression is not available on this system"
        case .initializationFailed:
            return "Failed to initialize compression stream"
        case .compressionFailed:
            return "Failed to compress data"
        case .decompressionFailed:
            return "Failed to decompress data"
        case .unknownError:
            return "An unknown compression error occurred"
        }
    }
}
