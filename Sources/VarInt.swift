//
//  VarInt.swift
//  SwiftNIOTutorial
//
//  Created by Corbin Bigler on 3/2/25.
//

import Foundation

public struct VarInt: Codable, Equatable {
    public let bytes: Data
    private(set) public var value: UInt64
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self)
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self = try container.decode(Self.self)
    }

    private static func decode(_ bytes: Data) -> UInt64? {
        var result: UInt64 = 0
        var shift: UInt64 = 0
        var bytesRead = 0
        
        for byte in bytes {
            let value = UInt64(byte & 0x7F)
            result |= value << shift
            shift += 7
            bytesRead += 1
            
            if byte & 0x80 == 0 { return result }
            if bytesRead >= 10 { return nil }
        }
        
        return nil
    }
    
    public init<T: FixedWidthInteger>(_ value: T) {
        var v = UInt64(value) // Ensure the value fits in UInt64
        var bytes = Data()
        
        while v >= 0x80 {
            bytes.append(UInt8(v & 0x7F) | 0x80)
            v >>= 7
        }
        bytes.append(UInt8(v & 0x7F))

        self.bytes = bytes
        self.value = UInt64(value)
    }

    public init?(bytes: Data) {
        guard let decodedValue = VarInt.decode(bytes) else { return nil }
        self.init(decodedValue)
    }
}
