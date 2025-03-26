//
//  VarInt.swift
//  SwiftNIOTutorial
//
//  Created by Corbin Bigler on 3/2/25.
//

import Foundation

public struct VarInt: Equatable, Sendable {
    public let bytes: Data
    private(set) public var value: UInt64

    public init?(bytes: Data) {
        guard let (value, bytesRead) = VarInt.decode(bytes) else { return nil }
        self.bytes = bytes.subdata(in: 0..<bytesRead)
        self.value = value
    }
    
    public init<T: FixedWidthInteger>(_ value: T) {
        var v = UInt64(value)
        var bytes = Data()
        
        while v >= 0x80 {
            bytes.append(UInt8(v & 0x7F) | 0x80)
            v >>= 7
        }
        bytes.append(UInt8(v & 0x7F))

        self.bytes = bytes
        self.value = UInt64(value)
    }

    private static func decode(_ bytes: Data) -> (value: UInt64, bytesRead: Int)? {
        var result: UInt64 = 0
        var shift: UInt64 = 0
        var bytesRead = 0
        
        for byte in bytes {
            let value = UInt64(byte & 0x7F)
            result |= value << shift
            shift += 7
            bytesRead += 1
            
            if byte & 0x80 == 0 { return (result, bytesRead) }
            if bytesRead >= 10 { return nil }
        }
        
        return nil
    }
}

extension VarInt: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self = try container.decode(Self.self)
    }
}

extension VarInt: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: UInt64) {
        self.init(value)
    }
}

extension Int {
    public init(_ varInt: VarInt) {
        self.init(varInt.value)
    }
}
