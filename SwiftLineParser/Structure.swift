//
//  Structure.swift
//  SwiftLineParser
//
//  Created by Zoe Smith on 2/2/19.
//  Copyright © 2019 Hot Beverage. All rights reserved.
//

import Foundation

struct Structure: Equatable {
    var declarations: [Declaration]
    
    var openStructures: Int {
        return declarations.filter { $0.openBrace == true }.count
    }
    
    var tokens: [Token] {
        return declarations.compactMap {
            if let keyword = $0.keyword {
                return Token.keyword(keyword)
            } else {
                return nil
            }
        }
    }
    
    func contains(_ element: Keyword) -> Bool {
        return declarations.contains(where: { $0.keyword == element })
    }
    
    func contains(any elements: [Keyword]) -> Bool {
        for keyword in elements {
            if contains(keyword) {
                return true
            }
        }
        return false
    }
    
    func contains(_ declaration: Declaration) -> Bool {
        return declarations.contains(declaration)
    }
    
    func starts(with keyword: Keyword) -> Bool {
        if let first = declarations.first, first.keyword == keyword  {
            return true
        } else {
            return false
        }
    }
    
    func starts(with declaration: Declaration) -> Bool {
        if let first = declarations.first, first == declaration  {
            return true
        } else {
            return false
        }
    }
    
    mutating func append(_ declaration: Declaration) {
        if let last = declarations.last,
            last == .init(keyword: .var, openBrace: false) || last == .init(keyword: .let, openBrace: false) {
            _ = declarations.popLast()
        }
        declarations.append(declaration)
    }
    
    mutating func openBrace() {
        guard var last = declarations.last, last.openBrace == false else {
            declarations.append(.init(keyword: nil, openBrace: true))
            return
        }
        last.openBrace = true
        _ = declarations.popLast()
        declarations.append(last)
    }
    
    mutating func closeBrace() {
        if let last = declarations.last {
            if last.openBrace == true  {
                _ = declarations.popLast()
            } else {
                _ = declarations.popLast()
                closeBrace()
            }
        }
    }
}

struct Declaration: Equatable {
    let keyword: Keyword?
    var openBrace: Bool
}
