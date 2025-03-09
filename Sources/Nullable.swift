//
//  NullEncodable.swift
//  hardpack
//
//  Created by Corbin Bigler on 3/5/25.
//

@propertyWrapper
public struct Nullable<Wrapped>: Codable where Wrapped: Codable {
    
    public var wrappedValue: Wrapped?

    public init(wrappedValue: Wrapped?) {
        self.wrappedValue = wrappedValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            wrappedValue = nil
        } else {
            wrappedValue = try Wrapped.init(from: decoder)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch wrappedValue {
        case .some(_): try container.encode(wrappedValue)
        case .none: try container.encodeNil()
        }
    }
}
