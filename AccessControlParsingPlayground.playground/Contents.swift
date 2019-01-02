//: Playground - noun: a place where people can play

import Cocoa
import SwiftLineParser

let testString = """
public let range = curry({ from, _, to in return RepStyle.range(from...to) }) <^> digits <*> hyphen <*> digits //8-12
public let dropset = curry({ _, _, count in return RepStyle.dropset(count: count) }) <^> string("dropset") <*> hyphen <*> digits //dropset-4
public let count = { RepStyle.count($0) } <^> digits <* character { $0 == "x" } //15
public let amrap = { _ in RepStyle.amrap } <^> string("AMRAP")
public let time = { RepStyle.time($0) } <^> digits <* character { $0 == "s" } //30s
public let rpe = { RepStyle.rpe($0) } <^> (string("rpe") *> digits)  //rpe8
public let ladder = { RepStyle.ladder($0) } <^> (digits <* character { $0 == "," }).oneOrMore // 12,10,8,6,8,10,12
public let max = { RepStyle.max($0) } <^> digits <* character { $0 == "%" } //30%
let repStyle = ladder <|> dropset <|> range <|> time <|> rpe <|> amrap <|> max <|> count\n
"""

print(testString.last!)


let lines = testString.components(separatedBy: .newlines)

let allLineNumbers = (0..<lines.count).map { $0 }

let p = Parser(lines: lines)
dump(p.newLines(at: allLineNumbers, level: .public)[8])



