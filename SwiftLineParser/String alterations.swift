//
//  String alterations.swift
//  SwiftLineParser
//
//  Created by Zoe Smith on 13/2/19.
//  Copyright © 2019 Hot Beverage. All rights reserved.
//

import Foundation

extension String {
    
    func modifyingAccess(_ change: LineChange, with substitution: String) -> String? {
        
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
    
    func modifyingSetter(_ line: LineChange, _ accessChange: AccessChange) -> String {
        switch line.type {
        case .setterPostfix(setterAccess: let currentSetterAccess):
            return self.modifyingSetter(current: currentSetterAccess, access: accessChange)
        case .setterSubstitute(setterAccess: let currentSetterAccess):
            return self.modifyingSetter(current: currentSetterAccess, access: accessChange)
        default: return self
        }
    }
    
    private func modifyingSetter(current setter: Access, access: AccessChange) -> String {
        
        switch access {
            
        case .increaseAccess:
            switch setter {
            case .private, .fileprivate: return self.alteringSetter(setter, target: .internal)
            default: return self
            }
            
        case .decreaseAccess:
            switch setter {
            case .fileprivate, .internal: return self.alteringSetter(setter, target: .private)
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
