//
//  main.swift
//  hardpack
//
//  Created by Corbin Bigler on 3/8/25.
//

import Foundation

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
let node3 = Node(value: 3)
let node2 = Node(value: 2, next: node3)
let node1 = Node(value: 1, next: node2)

let encoded = try HardpackEncoder().encode(node1)
print(encoded.hexString)
let decoded = try HardpackDecoder().decode(Node.self, from: encoded)
print(decoded)
print(node1 == decoded)

//struct Complex: Codable {
//    @Nullable var none: UInt8?
//    var other: String
//    @Nullable var some: [UInt8?]?
//}
//
//let complex = Complex(none: nil, other: "asdf", some: [255, nil, 1, 2, nil])
//let some: String? = nil
////let a: [String : [UInt8]] = ["a": [1], "b": [1, 2]]
//let encoded = try HardpackEncoder().encode(complex)
//print(encoded.hexString)
//let decoded = try HDecoder().decode(Complex.self, from: encoded)
//print(decoded)
//
extension Data {
    var hexString: String {
        return self.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}
