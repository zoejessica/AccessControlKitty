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
            lineIsPrefixable[lineNumber] = structure.allowsInternalAccessControlModifiers
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
    
    var structure: Structure = Structure(declarations: [])
    
    private func parseLine(_ line: Int, _ lineTokens: [Token]) {
        
        guard let firstToken = lineTokens.first else { return }
        
        defer {
            structure.build(with: lineTokens)
            
            if lineTokens.containExtensionWithConformance {
                lineIsPrefixable[line] = false
            }
        }
        
        if !firstToken.isAccessControlModifiableInFirstPosition {
            lineIsPrefixable[line] = false
            return
        }
        
        if structure.tokens.containExtensionWithConformance {
            lineIsPrefixable[line] = false
            return
        }
        
        // If any token on the line contains an access keyword, it's a substution:
        if let accessKeyword = lineTokens.containAccessKeyword {

            lineChangeType[line] = LineChange(.substitute, accessKeyword.rawValue, accessKeyword)
        
        } else {
        
            switch firstToken {
                
            case .keyword(let keyword) where accessKeywords.contains(keyword):

                lineChangeType[line] = LineChange(.substitute, keyword.rawValue, keyword)
                
            case .keyword(let keyword) where postfixableFunctionKeywords.contains(keyword):

                lineChangeType[line] = LineChange(.postfix, keyword.rawValue, nil)
                
            case .attribute(let attribute):
                
                if Array(lineTokens.dropFirst()).containAnyKeyword == false {
                    lineChangeType[line] = LineChange(.none, "", nil)
                } else {
                    lineChangeType[line] = LineChange(.postfix, attribute, nil)
                }
                
            case .keyword(let keyword): lineChangeType[line] = LineChange(.prefix, keyword.rawValue, nil)
            
            default: break
            
            }
        }        
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


















