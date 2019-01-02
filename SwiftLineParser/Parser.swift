//
//  Parser.swift
//  SwiftLineParser
//
//  Created by Zoe Smith on 4/21/18.
//  Copyright © 2018 Hot Beverage. All rights reserved.
//

import Foundation

public class Parser {
    
    public enum Access: String {
        case `public` = "public"
        case `private` = "private"
        case `internal` = "internal"
        case `fileprivate` = "fileprivate"
        case remove = ""
    }
    
    public init(lines: [String]) {
        self.lines = lines
        let lexer = Lexer()
        tokens = lines.map { lexer.analyse($0) }
        isPrefixable = Array<Bool>.init(repeating: true, count: lines.count)
        for (lineNumber, linetokens) in tokens.enumerated() {
            isPrefixable[lineNumber] = currentStructurePermitsPrefix(lineNumber)
            parseLine(lineNumber, linetokens)
        }
    }
    
    public func newLines(at lineNumbers: [Int], level: Access) -> [Int : String] {
        
        var newLines: [Int : String] = [:]
        for i in lineNumbers where isPrefixable[i] == true {
            let currentLine = lines[i]
            if let change = lineChangeType[i],
                let changedLine = changeAccessLevel(change, in: currentLine, with: level.rawValue) {
                newLines[i] = changedLine
            } else {
                newLines[i] = currentLine
            }
        }
        return newLines
    }
    
    private var lines: [String]
    private var tokens: [[Token]]
    var isPrefixable: [Bool]
    private var lineChangeType: [Int : (LineChangeType, String)] = [:]
    
    private let structureKeywords: [Keyword] = [ .protocol, .class, .struct, .enum, .extension, .func, ._init, .var, .let, .for, .while, .repeat]
    private let accessKeywords: [Keyword] = [.public, .private, .fileprivate, .internal, .open]
    private let postfixableFunctionKeywords: [Keyword] = [.required]
    var structure: Structure = Structure(declarations: [])
    
    private func parseLine(_ line: Int, _ lineTokens: [Token]) {
        
        guard let firstToken = lineTokens.first else { return }
        
        if !prefixableInFirstPosition(firstToken) {
            isPrefixable[line] = false
        }
        
        if tokenSequenceIsExtensionWithConformance(structure.tokens) {
            isPrefixable[line] = false
        }
        
        switch firstToken {
            
        case .keyword(let keyword) where accessKeywords.contains(keyword):
            lineChangeType[line] = (.substitute, keyword.rawValue)
            
        case .keyword(let keyword) where postfixableFunctionKeywords.contains(keyword):
            lineChangeType[line] = (.postfix, keyword.rawValue)
            
        case .attribute(let attribute):
            if let secondToken = lineTokens.dropFirst().first,
                case let .keyword(keyword) = secondToken,
                accessKeywords.contains(keyword) {
                lineChangeType[line] = (.substitute, keyword.rawValue)
            } else {
                lineChangeType[line] = (.postfix, attribute)
            }
        case .keyword(let keyword): lineChangeType[line] = (.prefix, keyword.rawValue)
        default: break
        }
        
        for (index, token) in lineTokens.enumerated() {
            switch token {
            
            
                
            case .keyword(let keyword) where structureKeywords.contains(keyword) && !structure.starts(with: Keyword.protocol):
                structure.append(.init(keyword: keyword, openBrace: false))
            case .singleCharacter(let char) where char == .bracketOpen:
                structure.openBrace()
            case .singleCharacter(let char) where char == .bracketClose:
                structure.closeBrace()
            default: break
            }
        }
        
        if tokenSequenceIsExtensionWithConformance(lineTokens) {
            isPrefixable[line] = false
        }
    }

    private func currentStructurePermitsPrefix(_ lineNumber: Int) -> Bool {
        if structure.starts(with: Keyword.func) { return false }
        if structure.starts(with: Keyword.protocol) { return false }
        if structure.starts(with: Declaration.init(keyword: .var, openBrace: true)) { return false }
        if structure.starts(with: Declaration.init(keyword: .let, openBrace: true)) { return false }

        return structure.openStructures < 2 ?  true : false
    }
    
    private func prefixableInFirstPosition(_ token: Token) -> Bool {
        switch token {
        case .singleCharacter: return false
        case .identifier: return false
        case .keyword(let keyword) where keyword == .case: return false 
        default: return true
        }
    }
    
    private enum LineChangeType {
        case substitute
        case prefix
        case postfix
        case none
    }
    
    private func changeAccessLevel(_ change: (LineChangeType, String), in line: String, with substitution: String) -> String? {
        var line = line
        let (changeType, word) = change
        
        var searchWord = word
        if case .substitute = changeType, substitution == "" {
            searchWord = searchWord + " "
        }
        
        guard let range = line.range(of: searchWord) else { return nil }
        
        switch changeType {
        case .none: return nil
        case .substitute:
            return line.replacingCharacters(in: range, with: substitution)
        case .postfix where substitution != "":
            line.insert(contentsOf: " \(substitution)", at: range.upperBound)
            return line
        case .prefix where substitution != "":
            line.insert(contentsOf: "\(substitution) ", at: range.lowerBound)
            return line
        default:
            return line
        }
    }
    
    func tokenSequenceIsExtensionWithConformance(_ tokens: [Token]) -> Bool {
        guard let startIndex = tokens.index(of: Token.keyword(.extension)) else { return false }
        var remainingTokens = tokens.dropFirst(startIndex + 1)
        guard tokens.count >= 3 else { return false }
        let first = remainingTokens.removeFirst()
        guard case Token.identifier = first else { return false }
        let second = remainingTokens.removeFirst()
        guard case Token.singleCharacter(.colon) = second else { return false }
        let third = remainingTokens.removeFirst()
        guard case Token.identifier = third else { return false }
        return true
    }
}

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


















