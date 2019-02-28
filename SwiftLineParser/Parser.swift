//
//  Parser.swift
//  SwiftLineParser
//
//  Created by Zoe Smith on 4/21/18.
//  Copyright © 2018-9 Zoë Smith. Distributed under the MIT License.
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
        
        var newLines: [Int : String] = [:]
        
        for (lineNumber, linetokens) in tokens.enumerated() {
            
            let (lineChange, isPrefixable, intermediateStructure) = parseLine(in: structure, lineNumber, linetokens)
            self.structure = intermediateStructure
            lineIsPrefixable[lineNumber] = isPrefixable
            
            guard lineIsPrefixable[lineNumber] else {
                continue
            }
            
            let unmodifiedLine = lines[lineNumber]
            
            let (newLineChange, substitution, target) = resolvedLineChange(previous: lineChange, accessChange, in: structure)
            let changedLine = unmodifiedLine.modifyingAccess(newLineChange, with: substitution)

            // Further alter the line for setter overrides
            let setterChangedLine = changedLine.modifyingSetter(newLineChange, accessChange, targetLevel: target)
            newLines[lineNumber] = setterChangedLine
        }
        return newLines
    }
    
    // Overrides type of line change according to the particular menu command
    // E.g. a fileprivate entity does not change when executing the Make API command
    private func resolvedLineChange(previous line: LineChange, _ accessChange: AccessChange, in structure: Structure) -> (LineChange, String, Access) {
        
        
        let currentLevel = structure.currentLevel
        let noSubstitution = (LineChange(type: .none, cursor: ""), "", currentLevel)
        let internalString = ""
        
        switch accessChange {
        case .singleLevel(let level): return (line, level.rawValue, level)
        
        case .makeAPI:
            switch currentLevel {
            case nil, .internal: return (line, line.substitution(target: .public), .public)
            default: return noSubstitution
            }
        
        case .removeAPI:
            switch currentLevel {
            case .public: return (line, line.substitution(target: .internal), .internal)
            default: return noSubstitution
            }
            
        case .increaseAccess:
            switch currentLevel {
            case .public: return noSubstitution
            case .internal, nil: return (line, line.substitution(target: .public), .public)
            case .fileprivate: return (line, line.substitution(target: .internal), .internal)
            case .private: return (line, line.substitution(target: .internal), .internal)
            default: fatalError()
            }
            
        case .decreaseAccess:
            switch currentLevel {
            case .public: return (line, internalString, .internal)
            case .internal, nil: return (line, line.substitution(target: .private), .private)
            case .fileprivate: return (line, line.substitution(target: .private), .private)
            case .private: return noSubstitution
            default: fatalError()
            }
        }
    }
    
    private var lines: [String]
    private var tokens: [[Token]]
  
    private var lineIsPrefixable: [Bool] // Overrides lineChangeType: if lineIsPrefixable == false, lineChangeType is ignored
//    private var lineChangeType: [Int : LineChange] = [:]
    
    var structure = Structure()
}


extension Parser {
    private func parseLine(in structure: Structure, _ line: Int, _ lineTokens: [Token]) -> (LineChange, Bool, Structure) {
        
        var structure = structure
        var lineIsPrefixable = false
        var lineChange: LineChange = LineChange(.none, at: "") // default if tokens are empty
        
        lineIsPrefixable = structure.allowsInternalAccessControlModifiers
        
        guard let firstToken = lineTokens.first else {
            return (lineChange, lineIsPrefixable, structure)
        }
        
        if !firstToken.isAccessControlModifiableInFirstPosition ||
            structure.tokens.containExtensionWithConformance {
            lineIsPrefixable = false
            structure.build(with: lineTokens)
            return  (lineChange, lineIsPrefixable, structure)
        }

        // If there is a setter access keyword, it's a setter subsitutiton, check it
        // before general line tokens because you need to check whether it's a
        // fileprivate(set) public var ... for example
        if let setterKeyword = lineTokens.containSetterAccessKeyword,
            let setter = Access(setterKeyword) {
            
            if let accessKeyword = lineTokens.containAccessKeyword {
                lineChange = LineChange(.setterSubstitute(setter), at: accessKeyword)
            } else {
                lineChange = LineChange(.setterPostfix(setter), at: setterKeyword)
            }
        }
        
        // If any token on the line contains an access keyword, it's a substution:
        else if let accessKeyword = lineTokens.containAccessKeyword {
            lineChange = LineChange(.substitute, at: accessKeyword)
        
        } else {
            
            switch firstToken {
            
            case .keyword(let keyword) where postfixableFunctionKeywords.contains(keyword):
                lineChange = LineChange(.postfix, at: keyword)
                
            case .attribute(let attribute) where Array(lineTokens.dropFirst()).containAnyKeyword == true:
                lineChange = LineChange(.postfix, at: attribute)
                
            case .attribute:
                lineChange = LineChange(.none, at: "")
                
            case .keyword(let keyword):
                lineChange = LineChange(.prefix, at: keyword)
            
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
