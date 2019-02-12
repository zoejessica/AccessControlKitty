//
//  Structure.swift
//  SwiftLineParser
//
//  Created by Zoe Smith on 2/2/19.
//  Copyright © 2019 Hot Beverage. All rights reserved.
//

import Foundation


struct Declaration: Equatable {
    let access: Access?
    let keyword: Keyword?
    var openBrace: Bool
}

extension Declaration {
    var isVariableWithoutClosure: Bool {
        if openBrace == false && (keyword == .var || keyword == .let) {
            return true
        } else {
            return false
        }
    }
    
    var isVariableWithClosure: Bool {
        if openBrace == true && (keyword == .var || keyword == .let) {
            return true
        } else {
            return false
        }
    }
}

struct Structure: Equatable {
    
    init() {
        self.declarations = []
    }
    
    var currentLevel: Access {
        get {
            if let explicitAccess = declarations.last?.access {
                return explicitAccess
            } else if let implicitAccess = declarations.last(where: { $0.access != nil })?.access {
                return min(implicitAccess, Access.internal) // implict access levels even in public entity is always internal
            }
            return .internal // default
        }
    }
    
    private(set) var declarations: [Declaration]
    
    mutating func build(with lineTokens: [Token]) {
        
        var lineaccess: Access?
        
        for token in lineTokens {

            switch token {

            case .keyword(let keyword) where accessKeywords.contains(keyword):

                    lineaccess = Access(keyword)
                
            case .keyword(let keyword) where structureKeywords.contains(keyword) && !starts(with: Keyword.protocol):

                if let last = declarations.last, last.isVariableWithoutClosure {
                    _ = declarations.popLast()
                }
                
                declarations.append(.init(access: lineaccess, keyword: keyword, openBrace: false))
                
            case .singleCharacter(let char) where char == .bracketOpen:
                openBrace(level: lineaccess)
            case .singleCharacter(let char) where char == .bracketClose:
                closeBrace()
                
            default: break
                
            }
            
            
            
            print(debugDescription)
        }
    }
    
    private mutating func openBrace(level: Access?) {
        guard var last = declarations.last, last.openBrace == false else {
            declarations.append(.init(access: level, keyword: nil, openBrace: true))
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
    }
}

extension Structure {
    
    var allowsInternalAccessControlModifiers: Bool {
        if contains(any: localScopeKeywords) { return false }
//        if contains(Keyword.protocol) { return false }
        if declarations.contains(where: { $0.isVariableWithClosure }) { return false }
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
