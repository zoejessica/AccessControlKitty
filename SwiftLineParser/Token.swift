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

enum SingleCharacter: String, TokenType {
    case bracketOpen = "{", bracketClose = "}"
    case colon = ":"
    case equals = "="
    static let allCases = [SingleCharacter.bracketOpen, .bracketClose, .colon]
}

enum Keyword: String, TokenType, CaseIterable {
    case `protocol`, `extension`, `struct`, `class`, `let`, `var`,
    `public`, `private`, `open`, `fileprivate`, `internal`, `override`, `func`,
    `final`, `enum`, `case`, _init = "init", `static`, `typealias`, `required`, `mutating`, `nonmutating`, `for`, `while`, `repeat`
    static let allCases = [Keyword.protocol, .extension, .struct, .class, .let, .var, .public, .private, .open, .fileprivate, .internal, .override, .func, .final, .enum, .case, ._init, .static, .typealias, .required, .mutating, .nonmutating, .for, .while, .repeat]
}



protocol TokenType {
    associatedtype T: Equatable, RawRepresentable where T.RawValue == String
    static var allCases: [T] { get }
    static var matches: [String : T] { get }
}

extension TokenType {
    static var matches: [String : T] {
        let zipped = zip(allCases.map { $0.rawValue }, allCases )
        return Dictionary(uniqueKeysWithValues: zipped)
    }
}

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




