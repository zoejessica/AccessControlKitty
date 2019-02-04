//
//  Parser.swift
//  SwiftLineParser
//
//  Created by Zoe Smith on 4/21/18.
//  Copyright © 2018 Hot Beverage. All rights reserved.
//

import Foundation

public class Parser {
    
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
    }
    
    public init(lines: [String]) {
        self.lines = lines
        let lexer = Lexer()
        tokens = lines.map { lexer.analyse($0) }
        lineIsPrefixable = Array<Bool>.init(repeating: true, count: lines.count)
        for (lineNumber, linetokens) in tokens.enumerated() {
            lineIsPrefixable[lineNumber] = currentStructureAllowsInternalAccessControlModifiers(lineNumber)
            parseLine(lineNumber, linetokens)
        }
    }
    
    public func newLines(at lineNumbers: [Int], accessChange: AccessChange) -> [Int : String] {
        var newLines: [Int : String] = [:]
        for i in lineNumbers where lineIsPrefixable[i] == true {
            let currentLine = lines[i]
            if let lineChange = lineChangeType[i],
                case let (newLineChange, substitution) = substitution(for: lineChange, accessChange),
                let changedLine = changeAccessLevel(newLineChange, in: currentLine, with: substitution) {
                newLines[i] = changedLine
            } else {
                newLines[i] = currentLine
            }
        }
        return newLines
    }
    
    // Left here for existing tests
    func newLines(at lineNumbers: [Int], level: Access) -> [Int : String] {
        return newLines(at: lineNumbers, accessChange: .singleLevel(level))
    }
    
    private func substitution(for line: LineChange, _ accessChange: AccessChange) -> (LineChange, String) {
        
        let noSubstitution = (LineChange(type: .none, cursor: "", current: nil), "")
        let internalString = ""
        
        switch accessChange {
        case .singleLevel(let level): return (line, level.rawValue)
        
        case .makeAPI:
            switch line.current {
            case nil, .internal?: return (line, Keyword.public.rawValue)
            default: return noSubstitution
            }
        
        case .removeAPI:
            switch line.current {
            case .public?: return (line, internalString)
            default: return noSubstitution
            }
            
        case .increaseAccess:
            switch line.current {
            case .public?: return noSubstitution
            case .internal?, nil: return (line, Keyword.public.rawValue)
            case .fileprivate?: return (line, internalString)
            case .private?: return (line, internalString)
            default: fatalError()
            }
            
        case .decreaseAccess:
            switch line.current {
            case .public?: return (line, internalString)
            case .internal?, nil: return (line, Keyword.private.rawValue)
            case .fileprivate?: return (line, Keyword.private.rawValue)
            case .private?: return noSubstitution
            default: fatalError()
            }
        }
    }
    
    private var lines: [String]
    private var tokens: [[Token]]
  
    var lineIsPrefixable: [Bool] // Overrides lineChangeType: if lineIsPrefixable == false, lineChangeType is ignored
    private var lineChangeType: [Int : LineChange] = [:]
    
    private let nonAccessModifiableKeywords: [Keyword] = [.case, .for, .while, .repeat, .do, .catch, .defer]
    private let localScopeKeywords: [Keyword] = [.func, ._init, .for, .while, .repeat, .protocol, .do, .catch, .defer, .subscript]
    private let structureKeywords: [Keyword] = [ .protocol, .class, .struct, .enum, .extension, .func, ._init, .var, .let, .for, .while, .repeat, .do, .catch, .defer, .subscript]
    private let accessKeywords: [Keyword] = [.public, .private, .fileprivate, .internal, .open]
    private let postfixableFunctionKeywords: [Keyword] = [.static, .unowned, .unownedsafe, .unownedunsafe, .required, .convenience]
    
    var structure: Structure = Structure(declarations: [])
    
    fileprivate func buildStructure(_ lineTokens: [Token]) {
        for token in lineTokens {
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
    }
    
    private func parseLine(_ line: Int, _ lineTokens: [Token]) {
        
        guard let firstToken = lineTokens.first else { return }
        
        defer {
            buildStructure(lineTokens)
            
            if tokenSequenceIsExtensionWithConformance(lineTokens) {
                lineIsPrefixable[line] = false
            }
        }
        
        if !tokenIsAccessControlModifiableInFirstPosition(firstToken) {
            lineIsPrefixable[line] = false
            return
        }
        
        if tokenSequenceIsExtensionWithConformance(structure.tokens) {
            lineIsPrefixable[line] = false
            return
        }
        
        // If any token on the line contains an access keyword, it's a substution:
        if let accessKeyword = tokensContainsAccessKeyword(lineTokens) {

            lineChangeType[line] = LineChange(.substitute, accessKeyword.rawValue, accessKeyword)
        
        } else {
        
            switch firstToken {
                
            case .keyword(let keyword) where accessKeywords.contains(keyword):

                lineChangeType[line] = LineChange(.substitute, keyword.rawValue, keyword)
                
            case .keyword(let keyword) where postfixableFunctionKeywords.contains(keyword):

                lineChangeType[line] = LineChange(.postfix, keyword.rawValue, nil)
                
            case .attribute(let attribute):
                
                if tokensContainAnyKeyword(lineTokens.dropFirst()) == false {
                    lineChangeType[line] = LineChange(.none, "", nil)
                } else {
                    lineChangeType[line] = LineChange(.postfix, attribute, nil)
                }
                
            case .keyword(let keyword): lineChangeType[line] = LineChange(.prefix, keyword.rawValue, nil)
            
            default: break
            
            }
        }        
    }
    
    private func tokensContainAnyKeyword(_ tokens: ArraySlice<Token>) -> Bool {
        for token in tokens {
            if case Token.keyword(_) = token {
                return true
            }
        }
        return false
    }
    
    private func tokensContainsAccessKeyword(_ tokens: [Token]) -> Keyword? {
        for token in tokens {
            if case let Token.keyword(keyword) = token, accessKeywords.contains(keyword) {
                return keyword
            }
        }
        return nil
    }
    
    private func changeAccessLevel(_ change: LineChange, in line: String, with substitution: String) -> String? {

        var line = line
        
        var searchWord = change.cursor
        
        if case .substitute = change.type, substitution == "" {
            searchWord = searchWord + " "
        }
        
        guard let range = line.range(of: searchWord) else {
            return nil            
        }
        
        switch change.type {
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
    
    private func currentStructureAllowsInternalAccessControlModifiers(_ lineNumber: Int) -> Bool {
        if structure.contains(oneOf: localScopeKeywords) { return false }
        if structure.contains(Declaration(keyword: .var, openBrace: true)) { return false }
        if structure.contains(Declaration(keyword: .let, openBrace: true)) { return false }
        return true
    }
    
    private func tokenIsAccessControlModifiableInFirstPosition(_ token: Token) -> Bool {
        switch token {
        case .singleCharacter: return false
        case .identifier: return false
        case .keyword(let keyword) where nonAccessModifiableKeywords.contains(keyword): return false
        default: return true
        }
    }
    
    private func tokenSequenceIsExtensionWithConformance(_ tokens: [Token]) -> Bool {
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

private struct LineChange {
    let type: LineChangeType
    let cursor: String
    let current: Keyword?
    
    enum LineChangeType {
        case substitute
        case prefix
        case postfix
        case none
    }
}

extension LineChange {
    init(_ type: LineChangeType, _ cursor: String, _ current: Keyword?) {
        self = LineChange.init(type: type, cursor: cursor, current: current)
    }
}


















