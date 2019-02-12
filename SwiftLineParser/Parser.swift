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
        
        var newLines: [Int : String] = [:]
        
        for (lineNumber, linetokens) in tokens.enumerated() {
            
            let (lineChange, isPrefixable, intermediateStructure) = parseLine(in: structure, lineNumber, linetokens)
            self.structure = intermediateStructure
            lineIsPrefixable[lineNumber] = isPrefixable
            lineChangeType[lineNumber] = lineChange
            
            if lineIsPrefixable[lineNumber] {
                
                let unmodifiedLine = lines[lineNumber]
                
                if let lineChange = lineChangeType[lineNumber],
                    case let (newLineChange, substitution) = lineAlteration(for: lineChange, accessChange, in: structure),

                    let changedLine = unmodifiedLine.modifyLine(newLineChange, with: substitution) {
                    
                    // Further alter the line for the setter: must include the actual changedLine here
                    let setterChangedLine = changedLine.setterAlteration(for: newLineChange, accessChange, in: structure)
                    
                    newLines[lineNumber] = setterChangedLine
                } else {
                    newLines[lineNumber] = unmodifiedLine
                }
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
    private func lineAlteration(for line: LineChange, _ accessChange: AccessChange, in structure: Structure) -> (LineChange, String) {
        
        
        let currentLevel = structure.currentLevel
        let noSubstitution = (LineChange(type: .none, cursor: ""), "")
        let internalString = ""
        
        switch accessChange {
        case .singleLevel(let level): return (line, level.rawValue)
        
        case .makeAPI:
            switch currentLevel {
            case nil, .internal: return (line, line.substitution(target: .public))
            default: return noSubstitution
            }
        
        case .removeAPI:
            switch currentLevel {
            case .public: return (line, line.substitution(target: .internal))
            default: return noSubstitution
            }
            
        case .increaseAccess:
            switch currentLevel {
            case .public: return noSubstitution
            case .internal, nil: return (line, line.substitution(target: .public))
            case .fileprivate: return (line, line.substitution(target: .internal))
            case .private: return (line, line.substitution(target: .internal))
            default: fatalError()
            }
            
        case .decreaseAccess:
            switch currentLevel {
            case .public: return (line, internalString)
            case .internal, nil: return (line, line.substitution(target: .private))
            case .fileprivate: return (line, line.substitution(target: .private))
            case .private: return noSubstitution
            default: fatalError()
            }
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
    
    enum LineChangeType: Equatable {
        case substitute
        case setterSubstitute(setterAccess: Access)
        case setterPostfix(setterAccess: Access)
        case prefix
        case postfix
        case none
    }
}

extension LineChange {
    init(_ type: LineChangeType, at cursor: String) {
        self = LineChange.init(type: type, cursor: cursor)
    }
    
    init(_ type: LineChangeType, at keyword: Keyword) {
        self = LineChange.init(type: type, cursor: keyword.rawValue)
    }
    
    func substitution(target access: Access) -> String {
        switch access {
        case (.internal): return ""
        default: return access.rawValue
        }
    }
    
    /*
 //        case (.setterSubstitute, .public): return ""
 //        case (.setterSubstitute, .internal): return Keyword.internalset.rawValue
 //        case (.setterSubstitute, .fileprivate): return Keyword.fileprivateset.rawValue
 //        case (.setterSubstitute, .private): return Keyword.privateset.rawValue*/

}


extension Parser {
    private func parseLine(in structure: Structure, _ line: Int, _ lineTokens: [Token]) -> (LineChange, Bool, Structure) {
        
        var structure = structure
        var lineIsPrefixable = false
        var lineChange: LineChange = LineChange(.none, at: "")
        
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
        
        
        // If there is a setter access keyword, it's a setter subsitutiton, check it
        // before general line tokens because you need to check whether it's a
        // fileprivate(set) public var ... for example
        if let setterKeyword = lineTokens.containSetterAccessKeyword, let setter = Access(setterKeyword) {
            if let accessKeyword = lineTokens.containAccessKeyword {
                lineChange = LineChange(.setterSubstitute(setterAccess: setter), at: accessKeyword)
            } else {
                lineChange = LineChange(.setterPostfix(setterAccess: setter), at: setterKeyword)
            }
        }
        
        // If any token on the line contains an access keyword, it's a substution:
        else if let accessKeyword = lineTokens.containAccessKeyword {
            
            lineChange = LineChange(.substitute, at: accessKeyword)
        
        } else {
            
            switch firstToken {
                
            case .keyword(let keyword) where accessKeywords.contains(keyword):
                
                lineChange = LineChange(.substitute, at: keyword)
                
            case .keyword(let keyword) where postfixableFunctionKeywords.contains(keyword):
                
                lineChange = LineChange(.postfix, at: keyword)
                
            case .attribute(let attribute):
                
                if Array(lineTokens.dropFirst()).containAnyKeyword == false {
                    lineChange = LineChange(.none, at: "")
                } else {
                    lineChange = LineChange(.postfix, at: attribute)
                }
                
            case .keyword(let keyword): lineChange = LineChange(.prefix, at: keyword)
                
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

extension String {

    fileprivate func modifyLine(_ change: LineChange, with substitution: String) -> String? {
        
        var line = self
        
        var searchWord = change.cursor
        
        // These two cases might be fixed by using remove function on String
        if case .substitute = change.type, substitution == "" {
            searchWord = searchWord + " "
        }
        
        if case .setterSubstitute = change.type, substitution == "" {
            searchWord = searchWord + " "
        }
        
        guard let range = line.range(of: searchWord) else {
            return nil
        }
        
        switch change.type {
        case .none: return nil
        case .substitute, .setterSubstitute:
            return line.replacingCharacters(in: range, with: substitution)
        case .postfix where substitution != "", .setterPostfix where substitution != "":
            line.insert(contentsOf: " \(substitution)", at: range.upperBound)
            return line
        case .prefix where substitution != "":
            line.insert(contentsOf: "\(substitution) ", at: range.lowerBound)
            return line
        default:
            return line
        }
    }
    
    fileprivate func setterAlteration(for line: LineChange, _ accessChange: AccessChange, in structure: Structure) -> String {
        switch line.type {
        case .setterPostfix(setterAccess: let currentSetterAccess):
            return self.alteration(setter: currentSetterAccess, access: accessChange, currentStructureLevel: structure.currentLevel)
        case .setterSubstitute(setterAccess: let currentSetterAccess):
            return self.alteration(setter: currentSetterAccess, access: accessChange, currentStructureLevel: structure.currentLevel)
        default: return self
        }
    }
    
    private func alteredSetter(_ setter: Access, target: Access) -> String {
        guard let setterString = setter.setterString, target <= .internal, let targetString = target.setterString else {
            return self
        }
        
        guard setter != target else {
            return removingSetter(setter)
        }
        
        guard let range = range(of: setterString) else {
            return self
        }
        
        return replacingCharacters(in: range, with: targetString)
    }
    
    private func removingSetter(_ setter: Access) -> String {
        guard let setterString = setter.setterString else { return self }
        guard let range = range(of: setterString) else { return self }
        let rangeWithFollowingSpace = self.range(of: (setterString + " ")) ?? range
        var copy = self
        copy.removeSubrange(rangeWithFollowingSpace)
        return copy
    }
    
    private func alteration(setter: Access, access: AccessChange, currentStructureLevel: Access) -> String {
    
        switch access {
            
        case .increaseAccess:
            switch setter {
            case .private, .fileprivate: return self.alteredSetter(setter, target: .internal)
            default: return self
            }

        case .decreaseAccess:
            switch setter {
            case .fileprivate, .internal: return self.alteredSetter(setter, target: .private)
            default: return self
            }
            
        case .makeAPI:
            return self
            
        case .removeAPI:
            switch setter {
            case .internal: return self.alteredSetter(setter, target: .internal)
            default: return self
            }
            
        case .singleLevel:
            return self.removingSetter(setter)
            
        }
        
        
}
}



















