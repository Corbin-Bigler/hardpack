//
//  Tests.swift
//  hardpack
//
//  Created by Corbin Bigler on 3/7/25.
//

import Foundation
import Testing
import Hardpack
import OSLog

func encodeDecode<T: Codable>(_ value: T) -> T? {
    do {
        let encoded = try HardpackEncoder().encode(value)
        return try HardpackDecoder().decode(T.self, from: encoded)
    } catch {
        print("\(error)")
        return nil
    }
}

@Test func testVarInt() {
    let value = VarInt(123456)
    #expect(encodeDecode(value) == value)
}

@Test func testUInt8() {
    let value: UInt8 = 255
    #expect(encodeDecode(value) == value)
}

@Test func testUInt16() {
    let value: UInt16 = 65535
    #expect(encodeDecode(value) == value)
}

@Test func testUInt32() {
    let value: UInt32 = 4294967295
    #expect(encodeDecode(value) == value)
}

@Test func testUInt64() {
    let value: UInt64 = 18446744073709551615
    #expect(encodeDecode(value) == value)
}

@Test func testInt8() {
    let value: Int8 = -128
    #expect(encodeDecode(value) == value)
}

@Test func testInt16() {
    let value: Int16 = -32768
    #expect(encodeDecode(value) == value)
}

@Test func testInt32() {
    let value: Int32 = -2147483648
    #expect(encodeDecode(value) == value)
}

@Test func testInt64() {
    let value: Int64 = -9223372036854775808
    #expect(encodeDecode(value) == value)
}

@Test func testString() {
    let value = "Hello, Hardpack!"
    #expect(encodeDecode(value) == value)
}

@Test func testFloat() {
    let value: Float = 3.1415926
    #expect(encodeDecode(value) == value)
}

@Test func testDouble() {
    let value: Double = 3.141592653589793
    #expect(encodeDecode(value) == value)
}

@Test func testBool() {
    let value: Bool = true
    #expect(encodeDecode(value) == value)
}

@Test func testUUID() {
    let value = UUID()
    #expect(encodeDecode(value) == value)
}

@Test func testDate() {
    let value = Date(timeIntervalSince1970: 1672531200)
    #expect(encodeDecode(value) == value)
}

@Test func testData() {
    let value = Data([0xDE, 0xAD, 0xBE, 0xEF])
    #expect(encodeDecode(value) == value)
}

@Test func testOptionalSome() {
    let value: Int64? = 42
    #expect(encodeDecode(value) == value)
}

@Test func testOptionalNone() {
    let value: Int64? = nil
    #expect(encodeDecode(value) == value)
}

@Test func testArrayOfInts() {
    let value: [Int16] = [1, 2, 3, 4, 5]
    #expect(encodeDecode(value) == value)
}

@Test func testArrayOfStrings() {
    let value = ["apple", "banana", "cherry"]
    #expect(encodeDecode(value) == value)
}

@Test func testDictionary() {
    let value: [String: Int8] = ["one": 1, "two": 2, "three": 3]
    #expect(encodeDecode(value) == value)
}

@Test func testNestedDictionary() {
    let value: [String: [String: Int8]] = ["numbers": ["one": 1, "two": 2]]
    #expect(encodeDecode(value) == value)
}

@Test func testComplexDictionary() {
    struct Complex: Codable, Equatable {
        let id: UUID
        let timestamp: Date
        let data: [String: Int8]
    }
    let value: [String: Complex] = [
        "entry1": Complex(id: UUID(), timestamp: Date(), data: ["key": 42])
    ]
    #expect(encodeDecode(value) == value)
}

class Node: Codable, Equatable {
    var value: Int8
    @Nullable var next: Node?

    init(value: Int8, next: Node? = nil) {
        self.value = value
        self.next = next
    }

    static func == (lhs: Node, rhs: Node) -> Bool {
        return lhs.value == rhs.value && lhs.next == rhs.next
    }
}

@Test func testSelfReferencingStructure() {
    let node3 = Node(value: 3)
    let node2 = Node(value: 2, next: node3)
    let node1 = Node(value: 1, next: node2)

    #expect(encodeDecode(node1) == node1)
}

extension Data {
    var hexString: String {
        return self.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}
