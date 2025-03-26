//
//  SimpleBufferDeserializer.swift
//  SwiftNIOTutorial
//
//  Created by Corbin Bigler on 3/3/25.
//

import Foundation

struct Test: Codable {
    let string: String
    let int8: Int8
    let int16: Int16
    let int32: Int32
    let int64: Int64
    let uInt8: UInt8
    let uInt16: UInt16
    let uInt32: UInt32
    let uInt64: UInt64
    let float: Float
    let double: Double
    let bool: Bool
    let date: Date
    let data: Data
    let uuid: UUID
    
    let arrayString: [String]
    let arrayInt8: [Int8]
    let arrayInt16: [Int16]
    let arrayInt32: [Int32]
    let arrayInt64: [Int64]
    let arrayUInt8: [UInt8]
    let arrayUInt16: [UInt16]
    let arrayUInt32: [UInt32]
    let arrayUInt64: [UInt64]
    let arrayFloat: [Float]
    let arrayDouble: [Double]
    let arrayBool: [Bool]
    let arrayDate: [Date]
    let arrayData: [Data]
    let arrayUuid: [UUID]
    let arrayNested: [Test]

    let dictionaryString: [String : String]
    let dictionaryInt8: [Int8 : Int8]
    let dictionaryInt16: [Int16 : Int16]
    let dictionaryInt32: [Int32 : Int32]
    let dictionaryInt64: [Int64 : Int64]
    let dictionaryUInt8: [UInt8 : UInt8]
    let dictionaryUInt16: [UInt16 : UInt16]
    let dictionaryUInt32: [UInt32 : UInt32]
    let dictionaryUInt64: [UInt64 : UInt64]
    let dictionaryFloat: [Float : Float]
    let dictionaryDouble: [Double : Double]
    let dictionaryBool: [Bool : Bool]
    let dictionaryDate: [Date : Date]
    let dictionaryData: [Data : Data]
    let dictionaryUuid: [UUID : UUID]
    let dictionaryNested: [Int8 : Test]

    let optionalString: String?
    let optionalInt8: Int8?
    let optionalInt16: Int16?
    let optionalInt32: Int32?
    let optionalInt64: Int64?
    let optionalUInt8: UInt8?
    let optionalUInt16: UInt16?
    let optionalUInt32: UInt32?
    let optionalUInt64: UInt64?
    let optionalFloat: Float?
    let optionalDouble: Double?
    let optionalBool: Bool?
    let optionalDate: Date?
    let optionalData: Data?
    let optionalUuid: UUID?
    
    let dictionaryDictionary: [Int8 : [Int8 : Int8]]
    let dictionaryArray: [Int8 : [Int8]]
    let dictionaryOptional: [Int8 : Int8?]
    
    let arrayArray: [[Int8]]
    let arrayDictionary: [[Int8 : Int8]]
    let arrayOptional: [Int8?]
    
    let optionalArray: [Int8]?
    let optionalDictionary: [Int8 : Int8]?
    let optionalOptional: Int8??
}


public class HardpackDecoder {
    
    public init() {}
    
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = _HardpackDecoder(data: data)
        return try decoder.decode(type)
    }

    fileprivate class _HardpackDecoder: Decoder {
        let data: Data
        var offset = 0
        
        var codingPath: [any CodingKey] = []
        var userInfo: [CodingUserInfoKey : Any] = [:]
        var unexpectedEndOfData: DecodingError { DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Unexpected end of data")) }

        init(data: Data) {
            self.data = data
        }
        
        func decodeNil() throws -> Bool {
            let currentByte = data[offset]
            if currentByte > 1 {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Currupted optional data"))
            }
            offset += 1
            return currentByte == 0
        }

        public func decode<T: Decodable>(_ type: T.Type) throws -> T {
            if let decodableType = type as? any DecodableDictionary.Type {
                return try decodableType.init(custom: self) as! T
            }
            return try T.init(from: self)
        }
        
        func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
            return .init(KeyedContainer(decoder: self))
        }
        func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
            return UnkeyedContainer(decoder: self)
        }
        func singleValueContainer() throws -> any SingleValueDecodingContainer {
            return SingleValueContainer(decoder: self)
        }

        struct SingleValueContainer: SingleValueDecodingContainer {
            private let decoder: _HardpackDecoder
            
            var data: Data { decoder.data }
            var offset: Int { decoder.offset }

            var codingPath: [CodingKey] { return decoder.codingPath }
            var unexpectedEndOfData: DecodingError { DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Unexpected end of data")) }
            
            init(decoder: _HardpackDecoder) {
                self.decoder = decoder
            }
            
            func decodeNil() -> Bool {
                guard let decode = try? decoder.decodeNil() else { return true }
                return decode
            }
            func decodeInteger<T: FixedWidthInteger>(_ type: T.Type) throws -> T {
                let size = MemoryLayout<T>.size
                guard offset + size <= data.count else { throw unexpectedEndOfData }
                let value = data.subdata(in: offset..<(offset + size)).withUnsafeBytes { $0.loadUnaligned(as: T.self) }
                decoder.offset += size
                return T(littleEndian: value)
            }
            func decodeFloat() throws -> Float {
                return Float(bitPattern: try decodeInteger(UInt32.self))
            }
            
            func decodeDouble() throws -> Double {
                return Double(bitPattern: try decodeInteger(UInt64.self))
            }
            func decodeString() throws -> String {
                let varLength = try decodeVarInt()
                let length = Int(varLength.value)
                guard offset + length <= data.count else { throw unexpectedEndOfData }
                let stringData = data.subdata(in: offset..<offset + length)
                decoder.offset += length
                guard let string = String(data: stringData, encoding: .utf8) else {
                    throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Invalid UTF-8 string"))
                }
                return string
            }
            func decodeVarInt() throws -> VarInt {
                var result: UInt64 = 0
                var shift: UInt64 = 0
                var bytesRead = 0
                while offset < data.count {
                    let byte = data[offset]
                    decoder.offset += 1
                    bytesRead += 1
                    
                    let value = UInt64(byte & 0x7F)
                    result |= value << shift
                    shift += 7
                    
                    if byte & 0x80 == 0 { return VarInt(result) }
                    
                    if bytesRead >= 10 {
                        throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "VarInt too long"))
                    }
                }
                
                throw unexpectedEndOfData
            }
            func decodeUUID() throws -> UUID {
                guard offset + 16 <= data.count else {
                    throw DecodingError.dataCorrupted(.init(codingPath: codingPath, debugDescription: "Unexpected end of data for UUID"))
                }
                let bytes = Array(data[offset..<offset+16])
                decoder.offset += 16
                return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7], bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
            }
            func decodeDate() throws -> Date {
                let timeInterval = try decodeInteger(UInt64.self)
                return Date(timeIntervalSince1970: TimeInterval(timeInterval) / 1000)
            }
            func decodeBool() throws -> Bool {
                return try decodeInteger(UInt8.self) != 0
            }

            func decode<T: Decodable>(_ type: T.Type) throws -> T {
                switch type {
                case is Float.Type: return try decodeFloat() as! T
                case is Double.Type: return try decodeDouble() as! T
                case is String.Type: return try decodeString() as! T
                case is Date.Type: return try decodeDate() as! T
                case is Bool.Type: return try decodeBool() as! T
                case is UUID.Type: return try decodeUUID() as! T
                case is VarInt.Type: return try decodeVarInt() as! T
                case is Int8.Type: return try decodeInteger(Int8.self) as! T
                case is Int16.Type: return try decodeInteger(Int16.self) as! T
                case is Int32.Type: return try decodeInteger(Int32.self) as! T
                case is Int64.Type: return try decodeInteger(Int64.self) as! T
                case is UInt8.Type: return try decodeInteger(UInt8.self) as! T
                case is UInt16.Type: return try decodeInteger(UInt16.self) as! T
                case is UInt32.Type: return try decodeInteger(UInt32.self) as! T
                case is UInt64.Type: return try decodeInteger(UInt64.self) as! T
                default: throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Unsupported value of type \(type)"))
                }
            }
        }
        
        struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
            private let decoder: _HardpackDecoder
            var codingPath: [CodingKey] { return decoder.codingPath }
            var allKeys: [Key] = []

            init(decoder: _HardpackDecoder) {
                self.decoder = decoder
            }

            private func decoder(with key: CodingKey) -> _HardpackDecoder {
                decoder.codingPath += [key]
                return decoder
            }

            func contains(_ key: Key) -> Bool {
                return true
            }
            func decodeNil(forKey key: Key) throws -> Bool {
                let currentByte = decoder.data[decoder.offset]
                if currentByte > 1 {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Currupted optional data"))
                }
                decoder.offset += 1
                return currentByte == 0
            }
            
            func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
                try decoder(with: key).container(keyedBy: type)
            }
            func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer { try decoder(with: key).unkeyedContainer() }
            func superDecoder() throws -> any Decoder { decoder }
            func superDecoder(forKey key: Key) throws -> any Decoder { decoder(with: key) }

            func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
                return try decoder(with: key).decode(type)//try T.init(from: decoder(with: key))
            }
        }
        
        struct UnkeyedContainer: UnkeyedDecodingContainer {
            private let decoder: _HardpackDecoder
            var codingPath: [CodingKey] { return decoder.codingPath }
            var count: Int?
            var isAtEnd: Bool = false
            var currentIndex: Int = 0
            
            init(decoder: _HardpackDecoder) {
                let varCount = try! (try! decoder.singleValueContainer() as! SingleValueContainer).decodeVarInt()
                count = Int(varCount.value)
                self.decoder = decoder
            }
            
            mutating func decode<T: Decodable>(_ type: T.Type) throws -> T {
                currentIndex += 1
                isAtEnd = currentIndex == count!
//                return try T.init(from: decoder)
                return try decoder.decode(type)
            }
            func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
                try decoder.container(keyedBy: type)
            }
            func nestedUnkeyedContainer() throws -> any UnkeyedDecodingContainer {
                try decoder.unkeyedContainer()
            }
            func superDecoder() throws -> any Decoder { decoder }
            func decodeNil() -> Bool {
                guard let decode = try? decoder.decodeNil() else { return true }
                return decode
            }
        }
    }
}

private struct Pair<Key: Decodable & Hashable, Value: Decodable>: Decodable {
    let key: Key
    let value: Value
}

private protocol DecodableDictionary: Decodable {
    associatedtype Key: Decodable & Hashable
    associatedtype Value: Decodable

    init<Key: Decodable & Hashable, Value: Decodable>(pairs: [Pair<Key, Value>])
    init(custom decoder: Decoder) throws
}

extension Dictionary: DecodableDictionary where Key: Decodable, Value: Decodable {
    fileprivate init<K, V>(pairs: [Pair<K, V>]) where K: Decodable & Hashable, V: Decodable {
        self.init(uniqueKeysWithValues: pairs.map { (key: $0.key as! Key, value: $0.value as! Value) })
    }
    init(custom decoder: Decoder) throws {
        let pairs = try [Pair<Key, Value>].init(from: decoder)
        self.init(pairs: pairs)
    }
}
