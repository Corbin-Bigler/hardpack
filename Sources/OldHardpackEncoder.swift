//
//  HardpackEncoder.swift
//  SwiftNIOTutorial
//
//  Created by Corbin Bigler on 3/3/25.
//

import Foundation


public class OldHardpackEncoder {
    
    public func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = _HardpackEncoder()
        return try encoder.encode(value)
    }

    public init() {}

    private class _HardpackEncoder: Encoder {
        private var data = Data()
        private var array: [Data] = []

        var codingPath: [any CodingKey] = []
        var userInfo: [CodingUserInfoKey: Any] = [:]
        
        init() {}

        func encode<T: Encodable>(_ value: T) throws -> Data {
            data = Data()
            array = []
            if value is Dictionary<AnyHashable, Any> {
                    
            } else {
                try value.encode(to: self)
            }
            encodeArray()
            return data
        }

        func encodeArray() {
            if !array.isEmpty {
                let container = SingleValueContainer(encoder: self)
                container.encodeVarInt(VarInt(UInt(array.count)))
                for element in array {
                    data.append(contentsOf: element)
                }
                array = []
            }
        }

        func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
            encodeArray()
            return .init(KeyedContainer(encoder: self))
        }
        func unkeyedContainer() -> any UnkeyedEncodingContainer {
            encodeArray()
            return UnkeyedContainer(encoder: self)
        }
        func singleValueContainer() -> any SingleValueEncodingContainer {
            encodeArray()
            return SingleValueContainer(encoder: self)
        }

        fileprivate struct SingleValueContainer: SingleValueEncodingContainer {
            let encoder: _HardpackEncoder
            var codingPath: [any CodingKey] { encoder.codingPath }

            func encodeNil() throws { encoder.data.append(0x00) }

            func encodeBool(_ value: Bool) {
                encoder.data.append(value ? 0x01 : 0x00)
            }
            func encodeInteger<T: FixedWidthInteger>(_ value: T) {
                var littleEndianValue = value.littleEndian
                withUnsafeBytes(of: &littleEndianValue) { encoder.data.append(contentsOf: $0) }
            }
            func encodeFloat(_ value: Float) {
                var littleEndianValue = value.bitPattern.littleEndian
                withUnsafeBytes(of: &littleEndianValue) { encoder.data.append(contentsOf: $0) }
            }
            func encodeDouble(_ value: Double) {
                var littleEndianValue = value.bitPattern.littleEndian
                withUnsafeBytes(of: &littleEndianValue) { encoder.data.append(contentsOf: $0) }
            }
            func encodeString(_ string: String) {
                let utf8Data = Data(string.utf8)
                encodeVarInt(VarInt(UInt(utf8Data.count)))
                encoder.data.append(utf8Data)
            }
            func encodeUUID(_ uuid: UUID) {
                let uuid = uuid.uuid
                let bytes = [uuid.0, uuid.1, uuid.2, uuid.3, uuid.4, uuid.5, uuid.6, uuid.7, uuid.8, uuid.9, uuid.10, uuid.11, uuid.12, uuid.13, uuid.14, uuid.15]
                encoder.data.append(contentsOf: bytes)
            }
            func encodeVarInt(_ value: VarInt) {
                encoder.data.append(value.bytes)
            }
            func encodeDate(_ value: Date) {
                let timeInterval = UInt64(value.timeIntervalSince1970 * 1000)
                encodeInteger(timeInterval)
            }

            func encode<T: Encodable>(_ value: T) throws {
                print(value)
                if let bool = value as? Bool { encodeBool(bool) }
                else if let integer = value as? any FixedWidthInteger { encodeInteger(integer) }
                else if let varInt = value as? VarInt { encodeVarInt(varInt) }
                else if let float = value as? Float { encodeFloat(float) }
                else if let double = value as? Double { encodeDouble(double) }
                else if let string = value as? String { encodeString(string) }
                else if let uuid = value as? UUID { encodeUUID(uuid) }
                else if let date = value as? Date { encodeDate(date) }
                else if let data = value as? Data { try data.encode(to: encoder) }
                else {
                    throw EncodingError.invalidValue(
                        value,
                        EncodingError.Context(
                            codingPath: codingPath,
                            debugDescription: "Unsupported value of type \(type(of: value))"
                        )
                    )
                }
            }
        }
        
        struct KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
            let encoder: _HardpackEncoder
            var codingPath: [CodingKey] { return encoder.codingPath }

            private func encoder(with key: CodingKey) -> _HardpackEncoder {
                encoder.codingPath += [key]
                return encoder
            }
            
            func encodeNil(forKey key: Key) throws { fatalError("Optional types not supported") }
            func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
                print(value)
                print(key)
                try value.encode(to: encoder(with: key))
            }
            func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
                encoder(with: key).container(keyedBy: type)
            }
            func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
                encoder(with: key).unkeyedContainer()
            }
            func superEncoder() -> Encoder { return encoder }
            func superEncoder(forKey key: Key) -> Encoder { encoder(with: key) }
        }
        
        struct UnkeyedContainer: UnkeyedEncodingContainer {
            let encoder: _HardpackEncoder
            var codingPath: [CodingKey] { return encoder.codingPath }
            var count: Int = 0
            
            func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
                encoder.container(keyedBy: keyType)
            }
            func nestedUnkeyedContainer() -> any UnkeyedEncodingContainer { encoder.unkeyedContainer() }
            func superEncoder() -> any Encoder { encoder }
            func encodeNil() throws { fatalError("Optional types in unkeyed containers not supported") }
            func encode<T: Encodable>(_ value: T) throws {
                let encoder = _HardpackEncoder()
                self.encoder.array.append(try encoder.encode(value))
            }
        }
    }
}

//private protocol OptionalProtocol {
//    static var wrappedType: Any.Type { get }
//}
//extension Optional: OptionalProtocol {
//    static var wrappedType: Any.Type { return Wrapped.self }
//}
