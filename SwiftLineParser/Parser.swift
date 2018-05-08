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
            isPrefixable[lineNumber] = structurePermitsPrefix(lineNumber)
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
    
    private let functionKeywords: [Keyword] = [ .protocol, .class, .struct, .enum, .extension, .func, ._init]
    private let accessKeywords: [Keyword] = [.public, .private, .fileprivate, .internal, .open]
    var structure: [Token] = []
    
    private func parseLine(_ line: Int, _ lineTokens: [Token]) {
        
        guard let firstToken = lineTokens.first else { return }
        
        if !prefixableInFirstPosition(firstToken) {
            isPrefixable[line] = isPrefixable[line] && false
        }
        
        if tokenSequenceIsExtensionWithConformance(structure) {
            isPrefixable[line] = false
        }
        
        switch firstToken {
        case .keyword(let keyword) where accessKeywords.contains(keyword): lineChangeType[line] = (.substitute, keyword.rawValue)
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
        
        for token in lineTokens {
            switch token {
            case .keyword(let keyword) where functionKeywords.contains(keyword) && structure.starts(with: [Token(Keyword.protocol)!]) == false:
                structure.append(token)
            case .singleCharacter(let char) where char == .bracketOpen:
                structure.append(token)
            case .singleCharacter(let char) where char == .bracketClose:
                structure = Array(structure.dropLast())
                if let lastStructureToken = structure.last {
                    if case let Token.keyword(keyword) = lastStructureToken, functionKeywords.contains(keyword) {
                        structure = Array(structure.dropLast())
                    }
                }
            default: break
            }
        }
        
        if tokenSequenceIsExtensionWithConformance(lineTokens) {
            isPrefixable[line] = false
        }
    }

    private func structurePermitsPrefix(_ lineNumber: Int) -> Bool {
        if structure.starts(with: [Token.keyword(.func)]) { return false }
        if structure.starts(with: [Token.keyword(.protocol)]) { return false }
        
        return structure.count < 4 ?  true : false
    }
    
    private func prefixableInFirstPosition(_ token: Token) -> Bool {
        switch token {
        case .singleCharacter: return false
        case .identifier: return false
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
        guard let range = line.range(of: word) else { return nil }
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



























