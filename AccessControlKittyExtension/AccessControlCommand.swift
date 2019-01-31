//
//  AccessControlCommand.swift
//  Change Access Level
//
//  Created by Zoe Smith on 4/25/18.
//  Copyright © 2018 Hot Beverage. All rights reserved.
//

import Foundation
import XcodeKit
import SwiftLineParser

class AccessControlCommand: NSObject, XCSourceEditorCommand {

    func selectedLines(in buffer: XCSourceTextBuffer) -> [Int] {
        guard let selections = buffer.selections as? [XCSourceTextRange] else { return [] }
        let selectedLines = selections.flatMap { lines($0, totalLines: buffer.lines.count) }
        let set = Set.init(selectedLines)
        return Array(set).sorted()
    }
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        // Implement your command here, invoking the completion handler when done. Pass it nil on success, and an NSError on failure.
        guard (invocation.buffer.contentUTI == "com.apple.dt.playground") || (invocation.buffer.contentUTI == "public.swift-source") else {
            completionHandler(nil)
            return
        }
        
        guard let accessLevel = Parser.AccessChange.init(commandIdentifier: invocation.commandIdentifier) else {
            completionHandler(nil)
            return
            
        }
        
        changeAccessLevel(accessLevel, invocation.buffer)
        completionHandler(nil)
    }
    
    func changeAccessLevel(_ access: Parser.AccessChange, _ buffer: XCSourceTextBuffer) {
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

func lines(_ range: XCSourceTextRange, totalLines: Int) -> [Int] {
    // Always include the whole line UNLESS the start and end positions are exactly the same, in which return an empty array
    if range.start.line == range.end.line && range.start.column == range.end.column {
        return []
    } else if totalLines == range.end.line {
        return Array(range.start.line..<range.end.line)
    } else {
        return Array(range.start.line...range.end.line)
    }
}

precedencegroup PipeForward { associativity: left }
infix operator |> : PipeForward
public func |> <A, B>(_ a: A, _ f: (A) -> B) -> B {
    return f(a)
}

struct SourceKitExtensionPlist : Codable {
    let CFBundleIdentifier: String
}

extension Parser.AccessChange {
    init?(commandIdentifier: String) {
//        guard let plist = try? PListFile<SourceKitExtensionPlist>() else {
//            return nil
//        }
        // let bundleName = plist.data.CFBundleIdentifier
        guard let id = commandIdentifier.split(separator: ".").last,
            case let idString = String(id),
            let accessChange = Parser.AccessChange.commandIdentifiers[idString] else {
            return nil
        }
        self = accessChange
    }
    
    static var commandIdentifiers: [String : Parser.AccessChange] {
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
