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

extension Access {
    init?(_ keyword: Keyword?) {
        guard let keyword = keyword, let a = Access.init(rawValue: keyword.rawValue) else {
            return nil
        }
        self = a        
    }
}
