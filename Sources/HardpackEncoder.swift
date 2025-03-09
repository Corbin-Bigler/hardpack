//
//  HardpackEncoder.swift
//  hardpack
//
//  Created by Corbin Bigler on 3/8/25.
//

import Foundation

public class HardpackEncoder {

    public init() {}

    public func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = _HardpackEncoder()
        try encoder.encode(value)
        return encoder.data
    }

    fileprivate class _HardpackEncoder: Encoder {
        private(set) var data = Data()

        var codingPath: [any CodingKey] = []
        var userInfo: [CodingUserInfoKey: Any] = [:]

        init() {}

        func encode(_ value: Encodable) throws {
            var unwrappedValue: Encodable = value
            if value is any EncodableOptional {
                guard let unwrapped = (value as! any EncodableOptional).unwrapped else {
                    encodeNil()
                    return
                }
                try encode(UInt8(0x01))
                unwrappedValue = unwrapped
            }
            
            switch unwrappedValue {
            case let array as [Encodable]: try encodeArray(array)
            case let dictionary as EncodableDictionary: try encodeDictionary(dictionary)
            case let data as Data: try encodeArray(Array(data))
            default: try unwrappedValue.encode(to: self)
            }
        }
        
        func encodeNil() {
            data.append(0x00)
        }
        func encodeOptional<T: Encodable>(_ value: T?) throws {
            if let value = value {
                data.append(0x01)
                try encode(value)
            } else {
                encodeNil()
            }
        }
        func encodeDictionary(_ value: EncodableDictionary) throws {
            let keys = value.keysArray
            let values = value.valuesArray
            let count = keys.count
            
            try encode(VarInt(count))
            for index in 0..<count {
                try encode(keys[index])
                try encode(values[index])
            }
        }
        func encodeArray(_ value: [Encodable]) throws {
            try encode(VarInt(value.count))
            for element in value {
                try encode(element)
            }
        }

        func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
            KeyedEncodingContainer(KeyedContainer(encoder: self))
        }

        func unkeyedContainer() -> any UnkeyedEncodingContainer {
            fatalError()
        }

        func singleValueContainer() -> any SingleValueEncodingContainer {
            SingleValueContainer(encoder: self)
        }

        struct SingleValueContainer: SingleValueEncodingContainer {
            let encoder: _HardpackEncoder
            var codingPath: [any CodingKey] { encoder.codingPath }

            func encodeNil() throws { encoder.encodeNil() }
            
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
                switch value {
                case let varInt as VarInt: encodeVarInt(varInt)
                case let uInt8 as UInt8: encodeInteger(uInt8)
                case let uInt16 as UInt16: encodeInteger(uInt16)
                case let uInt32 as UInt32: encodeInteger(uInt32)
                case let uInt64 as UInt64: encodeInteger(uInt64)
                case let int8 as Int8: encodeInteger(int8)
                case let int16 as Int16: encodeInteger(int16)
                case let int32 as Int32: encodeInteger(int32)
                case let int64 as Int64: encodeInteger(int64)
                case let string as String: encodeString(string)
                case let float as Float: encodeFloat(float)
                case let double as Double: encodeDouble(double)
                case let bool as Bool: encodeBool(bool)
                case let uuid as UUID: encodeUUID(uuid)
                case let date as Date: encodeDate(date)
                default:
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

            func encodeNil(forKey key: Key) throws { encoder.encodeNil() }
            func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
                try encoder.encode(value)
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
    }
}

protocol EncodableDictionary {
    var keysArray: [Encodable] { get }
    var valuesArray: [Encodable] { get }
}

extension Dictionary: EncodableDictionary where Key: Encodable, Value: Encodable {
    var keysArray: [Encodable] {
        return Array(self.keys)
    }
    var valuesArray: [Encodable] {
        return Array(self.values)
    }
}

protocol EncodableOptional {
    associatedtype Wrapped: Encodable
    var unwrapped: Wrapped? { get }
}

extension Optional: EncodableOptional where Wrapped: Encodable {
    var unwrapped: Wrapped? {
        return self
    }
}
extension Nullable: EncodableOptional where Wrapped: Encodable {
    var unwrapped: Wrapped? {
        return wrappedValue
    }
}
