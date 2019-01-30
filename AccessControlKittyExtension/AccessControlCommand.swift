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
        let selectedLineNumbers = selections
            .map(lines)
            .flatMap { $0 }
            |> Set.init
        return Array.init(selectedLineNumbers).sorted()
    }
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        // Implement your command here, invoking the completion handler when done. Pass it nil on success, and an NSError on failure.
        guard (invocation.buffer.contentUTI == "com.apple.dt.playground") || (invocation.buffer.contentUTI == "public.swift-source") else {
            completionHandler(nil)
            return
        }
        
        guard let accessLevel = Parser.Access.init(commandIdentifier: invocation.commandIdentifier) else {
            completionHandler(nil)
            return
            
        }
        
        changeAccessLevel(accessLevel, invocation.buffer)
        completionHandler(nil)
    }
    
    func changeAccessLevel(_ access: Parser.Access, _ buffer: XCSourceTextBuffer) {
        guard let lines = buffer.lines as? [String] else { return }
        
        let selectedLineNumbers = selectedLines(in: buffer)
        let parser = Parser(lines: lines)
        let changedSelections = parser.newLines(at: Array(selectedLineNumbers), level: access)
        for lineNumber in selectedLineNumbers {
            if let line = changedSelections[lineNumber] {
                buffer.lines[lineNumber] = line
            }
        }
    }
}

func lines(_ range: XCSourceTextRange) -> [Int] {
    // Always include the whole line UNLESS the start and end positions are exactly the same, in which return an empty array
    if range.start.line == range.end.line && range.start.column == range.end.column {
        return []
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

extension Parser.Access {
    init?(commandIdentifier: String) {
        guard let plist = try? PListFile<SourceKitExtensionPlist>() else {
            return nil
        }
        let bundleName = plist.data.CFBundleIdentifier
        switch commandIdentifier {
        case bundleName + ".MakePublic": self = .public
        case bundleName + ".MakeInternal": self = .internal
        case bundleName + ".MakePrivate": self = .private
        case bundleName + ".MakeFileprivate": self = .fileprivate
        case bundleName + ".Remove": self = .remove
        default: return nil
        }
    }
}
