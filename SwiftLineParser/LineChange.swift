//
//  LineChange.swift
//  SwiftLineParser
//
//  Created by Zoe Smith on 13/2/19.
//  Copyright © 2018-9 Zoë Smith. Distributed under the MIT License.
//

import Foundation

struct LineChange {
    let type: LineChangeType
    let cursor: String
    
    enum LineChangeType: Equatable {
        case substitute
        case setterSubstitute(Access) // records the access level of the setter
        case setterPostfix(Access) // records the access level of the setter
        case prefix
        case postfix
        case none
    }
}

extension LineChange {
    init(_ type: LineChangeType, at cursor: String) {
        self = LineChange.init(type: type, cursor: cursor)
    }
    
    init(_ type: LineChangeType, at keyword: Keyword) {
        self = LineChange.init(type: type, cursor: keyword.rawValue)
    }
    
    func substitution(target access: Access) -> String {
        switch access {
        case (.internal): return ""
        default: return access.rawValue
        }
    }
}
