//
//  String alterations.swift
//  SwiftLineParser
//
//  Created by Zoe Smith on 13/2/19.
//  Copyright © 2019 Hot Beverage. All rights reserved.
//

import Foundation

extension String {
    
    func modifyLine(_ change: LineChange, with substitution: String) -> String? {
        
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
    
    func setterAlteration(for line: LineChange, _ accessChange: AccessChange, in structure: Structure) -> String {
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
