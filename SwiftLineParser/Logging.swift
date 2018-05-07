//
//  Logging.swift
//  Temporary
//
//  Created by Zoe Smith on 4/21/18.
//  Copyright © 2018 Hot Beverage. All rights reserved.
//

import Foundation

extension Token: CustomDebugStringConvertible {    
    var debugDescription: String {
        switch self {
        case .keyword(let k): return k.rawValue
        case .singleCharacter(let s): return s.rawValue
        case .identifier(let i): return i
        case .attribute: return "attribute"
        }
    }
}

extension SingleCharacter: CustomDebugStringConvertible {
    var debugDescription: String { return rawValue }
}

extension Keyword: CustomDebugStringConvertible {
    var debugDescription: String { return rawValue }
}
