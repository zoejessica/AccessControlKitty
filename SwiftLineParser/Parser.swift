//
//  Parser.swift
//  SwiftLineParser
//
//  Created by Zoe Smith on 4/21/18.
//  Copyright © 2018 Hot Beverage. All rights reserved.
//

import Foundation

public class Parser {
    
    public init(lines: [String]) {
        self.lines = lines
        let lexer = Lexer()
        tokens = lines.map { lexer.analyse($0) }
        lineIsPrefixable = Array<Bool>.init(repeating: true, count: lines.count)
 


    }
    
    public func newLines(at lineNumbers: [Int], accessChange: AccessChange) -> [Int : String] {
        
        for (lineNumber, linetokens) in tokens.enumerated() {
            
            let (lineChange, isPrefixable, intermediateStructure) = parseLine(in: structure, lineNumber, linetokens)
            self.structure = intermediateStructure
            lineIsPrefixable[lineNumber] = isPrefixable
            lineChangeType[lineNumber] = lineChange
            
        }
        
        
        
        
        
        
        var newLines: [Int : String] = [:]
        for i in lineNumbers where lineIsPrefixable[i] == true {
            let currentLine = lines[i]
            if let lineChange = lineChangeType[i],
                case let (newLineChange, substitution) = lineAlteration(for: lineChange, accessChange),
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
    
    // Overrides type of line change according to the particular menu command
    // E.g. a fileprivate entity does not change when executing the Make API command
    private func lineAlteration(for line: LineChange, _ accessChange: AccessChange) -> (LineChange, String) {
        
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
    
    private var lines: [String]
    private var tokens: [[Token]]
  
    private var lineIsPrefixable: [Bool] // Overrides lineChangeType: if lineIsPrefixable == false, lineChangeType is ignored
    private var lineChangeType: [Int : LineChange] = [:]
    
    var structure = Structure()
    
    
}

private struct LineChange {
    let type: LineChangeType
    let cursor: String
    let current: Access?
    
    enum LineChangeType {
        case substitute
        case prefix
        case postfix
        case none
    }
}

extension LineChange {
    init(_ type: LineChangeType, at cursor: String, current: Keyword?) {
        self = LineChange.init(type: type, cursor: cursor, current: Access.init(current))
    }
    
    init(_ type: LineChangeType, at keyword: Keyword, current: Keyword?) {
        self = LineChange.init(type: type, cursor: keyword.rawValue, current: Access.init(current))
    }
}


extension Parser {
    private func parseLine(in structure: Structure, _ line: Int, _ lineTokens: [Token]) -> (LineChange, Bool, Structure) {
        
        var structure = structure
        var lineIsPrefixable = false
        var lineChange: LineChange = LineChange(.none, at: "", current: nil)
        
        lineIsPrefixable = structure.allowsInternalAccessControlModifiers
        
        guard let firstToken = lineTokens.first else { return (lineChange, lineIsPrefixable, structure) }
        
        
        if !firstToken.isAccessControlModifiableInFirstPosition {
            lineIsPrefixable = false
            
            structure.build(with: lineTokens)
            
            if lineTokens.containExtensionWithConformance {
                lineIsPrefixable = false
            }
            return  (lineChange, lineIsPrefixable, structure)
        }
        
        if structure.tokens.containExtensionWithConformance {
            lineIsPrefixable = false
            
            structure.build(with: lineTokens)
            
            if lineTokens.containExtensionWithConformance {
                lineIsPrefixable = false
            }
            return (lineChange, lineIsPrefixable, structure)
        }
        
        // If any token on the line contains an access keyword, it's a substution:
        if let accessKeyword = lineTokens.containAccessKeyword {
            
            lineChange = LineChange(.substitute, at: accessKeyword, current: .init(accessKeyword))
            
        } else {
            
            switch firstToken {
                
            case .keyword(let keyword) where accessKeywords.contains(keyword):
                
                lineChange = LineChange(.substitute, at: keyword, current: keyword)
                
            case .keyword(let keyword) where postfixableFunctionKeywords.contains(keyword):
                
                lineChange = LineChange(.postfix, at: keyword, current: nil)
                
            case .attribute(let attribute):
                
                if Array(lineTokens.dropFirst()).containAnyKeyword == false {
                    lineChange = LineChange(.none, at: "", current: nil)
                } else {
                    lineChange = LineChange(.postfix, at: attribute, current: nil)
                }
                
            case .keyword(let keyword): lineChange = LineChange(.prefix, at: keyword, current: nil)
                
            default: break
                
            }
        }
        
        structure.build(with: lineTokens)
        
        if lineTokens.containExtensionWithConformance {
            lineIsPrefixable = false
        }
        return (lineChange, lineIsPrefixable, structure)
    }
}

















