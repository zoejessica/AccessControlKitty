//
//  AccessControlCommand.swift
//  Change Access Level
//
//  Created by Zoe Smith on 4/25/18.
//  Copyright © 2018-9 Zoë Smith. Distributed under the MIT License.
//

import Foundation
import XcodeKit
import SwiftLineParser

class AccessControlCommand: NSObject, XCSourceEditorCommand {

    func selectedLines(in buffer: XCSourceTextBuffer) -> [Int] {
        guard let selections = buffer.selections as? [XCSourceTextRange] else { return [] }
        let selectedLines = selections.flatMap { lines($0, totalLinesInBuffer: buffer.lines.count) }
        let set = Set.init(selectedLines)
        return Array(set).sorted()
    }
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        // Implement your command here, invoking the completion handler when done. Pass it nil on success, and an NSError on failure.
        guard (invocation.buffer.contentUTI == "com.apple.dt.playground") || (invocation.buffer.contentUTI == "public.swift-source") else {
            completionHandler(nil)
            return
        }
        
        guard let accessLevel = AccessChange.init(commandIdentifier: invocation.commandIdentifier) else {
            completionHandler(nil)
            return
            
        }
        
        changeAccessLevel(accessLevel, invocation.buffer)
        completionHandler(nil)
    }
    
    func changeAccessLevel(_ access: AccessChange, _ buffer: XCSourceTextBuffer) {
        guard let lines = buffer.lines as? [String] else { return }
        
        let selectedLineNumbers = selectedLines(in: buffer)
        let parser = Parser(lines: lines)
        let changedSelections = parser.newLines(at: Array(selectedLineNumbers), accessChange: access)
        for lineNumber in selectedLineNumbers {
            if let line = changedSelections[lineNumber] {
                buffer.lines[lineNumber] = line
            }
        }
    }
}

func lines(_ range: XCSourceTextRange, totalLinesInBuffer: Int) -> [Int] {
    // Always include the whole line UNLESS the start and end positions are exactly the same, in which return an empty array
    if range.start.line == range.end.line && range.start.column == range.end.column {
        return []
    } else if totalLinesInBuffer == range.end.line {
        return Array(range.start.line..<range.end.line)
    } else if range.end.column == 0 {
        return Array(range.start.line..<range.end.line)
    } else {
        return Array(range.start.line...range.end.line)
    }
}

extension AccessChange {
    init?(commandIdentifier: String) {
        guard let id = commandIdentifier.split(separator: ".").last,
            case let idString = String(id),
            let accessChange = AccessChange.commandIdentifiers[idString] else {
            return nil
        }
        self = accessChange
    }
    
    static var commandIdentifiers: [String : AccessChange] {
        return [ "DecreaseAccess" : .decreaseAccess ,
                 "IncreaseAccess" : .increaseAccess,
                 "MakeAPI" : .makeAPI,
                 "RemoveAPI" : .removeAPI,
                 "MakePublic": .singleLevel(.public),
                 "MakeInternal": .singleLevel(.internal),
                 "MakePrivate": .singleLevel(.private),
                 "MakeFileprivate": .singleLevel(.fileprivate),
                 "Remove": .singleLevel(.remove)]
    }
}
