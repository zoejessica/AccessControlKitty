//
//  Structure.swift
//  SwiftLineParser
//
//  Created by Zoe Smith on 2/2/19.
//  Copyright © 2019 Hot Beverage. All rights reserved.
//

import Foundation


struct Declaration: Equatable {
    let keyword: Keyword?
    var openBrace: Bool
}

struct Structure: Equatable {
    
    init() {
        self.declarations = []
        self.currentLevel = .internal
    }
    
    private(set) var currentLevel: Parser.Access
    
    private(set) var declarations: [Declaration]
    
    mutating func build(with lineTokens: [Token]) {
        for token in lineTokens {
            switch token {
            case .keyword(let keyword) where accessKeywords.contains(keyword):
                if let level = Parser.Access.init(rawValue: keyword.rawValue) {
                    currentLevel = level
                } else {
                    fatalError("\(keyword.rawValue) not recognized by Parser.Access") // could be open
                }
            case .keyword(let keyword) where structureKeywords.contains(keyword) && !starts(with: Keyword.protocol):
                append(.init(keyword: keyword, openBrace: false))
            case .singleCharacter(let char) where char == .bracketOpen:
                openBrace()
            case .singleCharacter(let char) where char == .bracketClose:
                closeBrace()
            default: break
            }
            print(debugDescription)
        }
    }
    
    private mutating func append(_ declaration: Declaration) {
        if let last = declarations.last,
            last == .init(keyword: .var, openBrace: false) || last == .init(keyword: .let, openBrace: false) {
            _ = declarations.popLast()
        }
        declarations.append(declaration)
    }
    
    private mutating func openBrace() {
        guard var last = declarations.last, last.openBrace == false else {
            declarations.append(.init(keyword: nil, openBrace: true))
            return
        }
        last.openBrace = true
        _ = declarations.popLast()
        declarations.append(last)
    }
    
    private mutating func closeBrace() {
        if let last = declarations.last {
            if last.openBrace == true  {
                _ = declarations.popLast()
            } else {
                _ = declarations.popLast()
                closeBrace()
            }
        }
        if declarations.count == 0 {
            currentLevel = .internal
        }
    }
}

extension Structure {
    
    var allowsInternalAccessControlModifiers: Bool {
        if contains(any: localScopeKeywords) { return false }
        if contains(Declaration(keyword: .var, openBrace: true)) { return false }
        if contains(Declaration(keyword: .let, openBrace: true)) { return false }
        return true
    }
    
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
}
