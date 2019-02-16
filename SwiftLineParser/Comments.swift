//
//  Comments.swift
//  SwiftLineParser
//
//  Created by Zoe Smith on 4/23/18.
//  Copyright © 2018-9 Zoë Smith. Distributed under the MIT License.
//

import Foundation

private let singleLineComment = try! NSRegularExpression(pattern: "^//", options: [])
private let multiLineCommentStart = try! NSRegularExpression(pattern: "", options: [])

extension Lexer {
    
    func hasMultilineCommentPrefix(slice: Substring) -> Substring.Index? {
        if slice.hasPrefix("/*") {
            var newStartRange = slice.startIndex
            slice.formIndex(&newStartRange, offsetBy: 2)
            return newStartRange
        } else {
            return nil
        }
    }

    func isComment(slice: Substring) throws -> () {
        if matches(slice, regex: singleLineComment) {
            throw LexerError.singleLineComment([])
      }
    }

    func trimLineAfterEndMultilineComment(line: String) -> String? {
        if let firstOccurence = line.range(of: "*/") {
            return String(line.suffix(from: firstOccurence.upperBound))
        } else {
            return nil
        }
    }
}


