//
//  Tagged.swift
//  Temporary
//
//  Created by Zoe Smith on 4/19/18.
//  Copyright © 2018-9 Zoë Smith. Distributed under the MIT License.
//

import Foundation


public struct Tagged<Tag, RawValue> {
    public let rawValue: RawValue
}

extension Tagged: Equatable where RawValue: Equatable {
    public static func ==(lhs: Tagged, rhs: Tagged) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

extension Tagged: ExpressibleByUnicodeScalarLiteral where RawValue: ExpressibleByUnicodeScalarLiteral {
    public typealias UnicodeScalarLiteralType = RawValue.UnicodeScalarLiteralType
    public init(unicodeScalarLiteral value: RawValue.UnicodeScalarLiteralType) {
        self.init(rawValue: RawValue(unicodeScalarLiteral: value))
    }
}

extension Tagged: ExpressibleByExtendedGraphemeClusterLiteral where RawValue: ExpressibleByExtendedGraphemeClusterLiteral {
    public typealias ExtendedGraphemeClusterLiteralType = RawValue.ExtendedGraphemeClusterLiteralType
    public init(extendedGraphemeClusterLiteral value: RawValue.ExtendedGraphemeClusterLiteralType) {
        self.init(rawValue: RawValue(extendedGraphemeClusterLiteral: value))
    }
}

extension Tagged: ExpressibleByStringLiteral where RawValue: ExpressibleByStringLiteral {
    public typealias StringLiteralType = RawValue.StringLiteralType
    public init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: RawValue(stringLiteral: value))
    }
}

