//
//  String alterations.swift
//  SwiftLineParser
//
//  Created by Zoe Smith on 13/2/19.
//  Copyright © 2018-9 Zoë Smith. Distributed under the MIT License.
//

import Foundation

extension String {
    
    func modifyingAccess(_ change: LineChange, with substitution: String) -> String {
        
        var line = self
        
        var searchWord = change.cursor
        
        // These two cases might be fixed by using remove function on String
        if substitution == "" {
            switch change.type {
            case .substitute, .setterSubstitute:
                searchWord = searchWord + " "
            default: break
            }
        }
        
        guard let range = line.range(of: searchWord) else {
            return self
        }
        
        switch change.type {
        case .none: return self
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
    
    func modifyingSetter(_ line: LineChange, _ accessChange: AccessChange, targetLevel: Access) -> String {
        switch line.type {
        case .setterPostfix(setterAccess: let currentSetterAccess):
            return self.modifyingSetterForTarget(current: currentSetterAccess, access: accessChange, targetLevel: targetLevel)
        case .setterSubstitute(setterAccess: let currentSetterAccess):
            return self.modifyingSetterForTarget(current: currentSetterAccess, access: accessChange, targetLevel: targetLevel)
        default: return self
        }
    }
    
    private func modifyingSetterForTarget(current setter: Access, access: AccessChange, targetLevel: Access) -> String {
        
        guard setter != targetLevel else {
            return self.removingSetter(setter)
        }
        
        switch access {
            
        case .increaseAccess:
            return self 
            
        case .decreaseAccess:
            
            switch setter {
            case .fileprivate where targetLevel == .private: return self.removingSetter(setter)
            case .fileprivate, .internal: return self
            default: return self
            }
            
        case .makeAPI:
            return self
            
        case .removeAPI:
            switch setter {
            case .internal: return self.alteringSetter(setter, target: .internal)
            default: return self
            }
            
        case .singleLevel:
            return self.removingSetter(setter)
            
        }
    }
    
    private func alteringSetter(_ setter: Access, target: Access) -> String {
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
}
