//
//  Regex.swift
//  Temporary
//
//  Created by Zoe Smith on 4/20/18.
//  Copyright © 2018 Hot Beverage. All rights reserved.
//

import Foundation

public func match(_ string: String, pattern: String) -> Range<String.Index>? {
    let regex = try! NSRegularExpression(pattern: pattern, options: [])
    let firstMatch = match(string, with: regex)
    return firstMatch
}

public func match(_ string: String, with regex: NSRegularExpression) -> Range<String.Index>? {
    let firstMatch = regex.rangeOfFirstMatch(in: string, options: [], range: NSMakeRange(0, string.utf16.count))
    guard firstMatch.location != NSNotFound else { return nil }
    guard firstMatch.lowerBound != firstMatch.upperBound else {
        return nil
    }
    let range = Range(firstMatch, in: string)
    return range
}

public func matches(_ string: String, with regex: NSRegularExpression) -> [Range<String.Index>]? {
    let matches = regex.matches(in: string, options: [], range: NSMakeRange(0, string.utf16.count))
    let ranges = matches.map { Range($0.range, in: string) }.compactMap { $0 }
    guard ranges.count > 0 else { return nil }
    return ranges
}

func matches(_ slice: Substring, regex: NSRegularExpression) -> Bool {
    return match(String(slice), with: regex) != nil
}

typealias TokenGenerator = (String) -> Token?
let tokenList: [(String, TokenGenerator)] = [
    ("^[^a-zA-Z0-9]", { Token(SingleCharacter.matches[$0]) }),
    ("^@[a-zA-Z0-9]*", { .attribute($0) }),
    ("^[a-zA-Z0-9]*", { Token(Keyword.matches[$0]) ?? .identifier($0) }),
    ("[.]init", { Token.identifier($0) })
    ]







//    let regex = try! NSRegularExpression(pattern: "(protocol)", options: [])
//    if let range = match(string, with: regex) {
//        print(range)
//        let next = string[range.upperBound...]
//        print(next)
//    }
//    return []

//func leadingCharacter(in slice: Substring, from range: Range<Substring.Index>) -> Unicode.Scalar? {
//    return slice[range].first?.unicodeScalars.first
//}



