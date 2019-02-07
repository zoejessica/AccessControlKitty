//
//  Access.swift
//  SwiftLineParser
//
//  Created by Zoe Smith on 6/2/19.
//  Copyright © 2019 Hot Beverage. All rights reserved.
//

import Foundation

public enum AccessChange {
    case singleLevel(Access)
    case increaseAccess
    case decreaseAccess
    case makeAPI
    case removeAPI
}

public enum Access: String {
    case `public` = "public"
    case `private` = "private"
    case `internal` = "internal"
    case `fileprivate` = "fileprivate"
    case remove = ""
    case `open` = "open"
}

extension Access: Comparable {
    
    public static func <(_ lhs: Access, _ rhs: Access) -> Bool {
        return lhs.order < rhs.order
    }
    
    var order: Int {
        switch self {
        case .private: return -2
        case .fileprivate: return -1
        case .internal: return 0
        case .remove: return 0
        case .public: return 1
        case .open: return 2
        }
    }
}

extension Access {
    init?(_ keyword: Keyword?) {
        guard let keyword = keyword, let a = Access.init(rawValue: keyword.rawValue) else {
            return nil
        }
        self = a        
    }
}
