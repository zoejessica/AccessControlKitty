//
//  Token.swift
//  Temporary
//
//  Created by Zoe Smith on 4/20/18.`while` 'repeat`
//  Copyright © 2018 Hot Beverage. All rights reserved.
//

import Foundation

enum Token: Equatable {
    case attribute(String)
    case keyword(Keyword)
    case singleCharacter(SingleCharacter)
    case identifier(String)
}

enum SingleCharacter: String, CaseIterable {
    case bracketOpen = "{", bracketClose = "}"
    case colon = ":"
    case equals = "="
}

enum Keyword: String, CaseIterable {
    case `protocol`, `extension`, `struct`, `class`, `let`, `var`,
    `public`, `private`, `open`, `fileprivate`, `internal`,
    `override`, `func`,
    `final`, `enum`, `case`,
    _init = "init",
    `static`, `typealias`, `required`,
    `mutating`, `nonmutating`,
    `for`, `while`, `repeat`,
    `unowned`, unownedsafe = "unowned(safe)", unownedunsafe = "unowned(unsafe)",
    `convenience`, `do`, `catch`, `defer`, `subscript`,
    `prefix`, `postfix`, `infix`,
    `lazy`, `weak`
}

let nonAccessModifiableKeywords: [Keyword] = [.case, .for, .while, .repeat, .do, .catch, .defer]
let localScopeKeywords: [Keyword] = [.func, ._init, .for, .while, .repeat, .protocol, .do, .catch, .defer, .subscript]
let structureKeywords: [Keyword] = [ .protocol, .class, .struct, .enum, .extension, .func, ._init, .var, .let, .for, .while, .repeat, .do, .catch, .defer, .subscript]
let accessKeywords: [Keyword] = [.public, .private, .fileprivate, .internal, .open]
let postfixableFunctionKeywords: [Keyword] = [.static, .unowned, .unownedsafe, .unownedunsafe, .required, .convenience]

extension Token {
    init?(_ singleCharacter: SingleCharacter?) {
        guard singleCharacter != nil else { return nil }
        self = .singleCharacter(singleCharacter!)
    }
    
    init?(_ keyword: Keyword?) {
        guard keyword != nil else { return nil }
        self = .keyword(keyword!)
    }
}

extension Token {
    var isAccessControlModifiableInFirstPosition: Bool {
        switch self {
        case .singleCharacter: return false
        case .identifier: return false
        case .keyword(let keyword) where nonAccessModifiableKeywords.contains(keyword): return false
        default: return true
        }
    }
}

extension Array where Element == Token {
    
    var containAccessKeyword: Keyword? {
        for token in self {
            if case let Token.keyword(keyword) = token, accessKeywords.contains(keyword) {
                return keyword
            }
        }
        return nil
    }
    
    var containAnyKeyword:  Bool {
        for token in self {
            if case Token.keyword(_) = token {
                return true
            }
        }
        return false
    }
    
    var containExtensionWithConformance: Bool {
        guard let startIndex = self.index(of: Token.keyword(.extension)) else { return false }
        var remainingTokens = self.dropFirst(startIndex + 1)
        guard self.count >= 3 else { return false }
        let first = remainingTokens.removeFirst()
        guard case Token.identifier = first else { return false }
        let second = remainingTokens.removeFirst()
        guard case Token.singleCharacter(.colon) = second else { return false }
        let third = remainingTokens.removeFirst()
        guard case Token.identifier = third else { return false }
        return true
    }
}




