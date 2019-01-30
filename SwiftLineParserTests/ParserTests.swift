//
//  ParserTests.swift
//  SwiftLineParserTests
//
//  Created by Zoe Smith on 4/21/18.
//  Copyright © 2018 Hot Beverage. All rights reserved.
//

import XCTest
@testable import SwiftLineParser

class ParserTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testStructure() {
        let lines = ["final class ViewController: NSViewController {",
                     " @IBOutlet var textView: NSTextView!",
                     "override func viewDidLoad() {",
                     "super.viewDidLoad()",
                     "let strings: [Highlight<NSAttributedString>] = markdown()",
                     "let result = strings.map { $0.rendered }.join(separator: \"/\n\n\")",
                     "textView.textStorage!.setAttributedString(result)",
                     "}",
                     "}"]
        
        let prefixable = [true, true, true, false, false, false, false, false, false]
        let parser = Parser(lines: lines)
        XCTAssertEqual(parser.isPrefixable, prefixable)
    }
    
    func testEnum() {
        let lines = ["enum Kind: Int {",
       " case keyword",
        "case string",
        "case other",
        
       " init?(sourceKitType type: String) {",
           " switch type {",
            "case \"source.lang.swift.syntaxtype.keyword\": self = .keyword",
           " case \"source.lang.swift.syntaxtype.string\": self = .string",
           " default: self = .other",
           " }",
       " }",
   " }"]
        let prefixable = [true, false, false, false, true, false, false, false, false, false, false, false]
        let parser = Parser(lines: lines)
        XCTAssertEqual(prefixable, parser.isPrefixable)
    }
    
    func testFunc() {
        let lines = ["func highlightSyntax(code: String) throws -> [(Range<String.Index>, Kind)] {",
        "let tempDir = NSURL(fileURLWithPath: NSTemporaryDirectory())",
        "let tmpFile = tempDir.appendingPathComponent(UUID().uuidString + \".swift\")!",
        "try! code.write(to: tmpFile, atomically: true, encoding: .utf8)]",
        "return (range, Kind(sourceKitType: dict[\"type\"] as! String)!)"]
        let prefixable = [true, false, false, false, false]
        let parser = Parser(lines: lines)
        XCTAssertEqual(prefixable, parser.isPrefixable)
    }

    
    func testPrePostSubstitutionFixing() {
        let lines = ["public let strings: [Highlight<NSAttributedString>] = markdown()",
                     "final class ViewController: NSViewController {",
                     "@IBOutlet var textView: NSTextView!",
                     "func highlightSyntax(code: String) throws -> [(Range<String.Index>, Kind)] {"]
        let prefixable = [true, true, true, true]
        let parser = Parser(lines: lines)
        let newLines = parser.newLines(at: [0, 1, 2, 3], level: .public)
        let expectedNewLines = ["public let strings: [Highlight<NSAttributedString>] = markdown()",
                                "public final class ViewController: NSViewController {",
                                "@IBOutlet public var textView: NSTextView!",
                                "public func highlightSyntax(code: String) throws -> [(Range<String.Index>, Kind)] {"]
        XCTAssertEqual(prefixable, parser.isPrefixable)
        for (lineNumber, expectedLine) in expectedNewLines.enumerated() {
            XCTAssertEqual(expectedLine, newLines[lineNumber])
        }
    }
    
    func testPrePostSubstitutionFixingVars() {
        let lines = ["public var strings: [Highlight<NSAttributedString>] = markdown()",
                     "final class ViewController: NSViewController {",
                     "@IBOutlet var textView: NSTextView!",
                     "func highlightSyntax(code: String) throws -> [(Range<String.Index>, Kind)] {"]
        let prefixable = [true, true, true, true]
        let parser = Parser(lines: lines)
        let newLines = parser.newLines(at: [0, 1, 2, 3], level: .public)
        let expectedNewLines = ["public var strings: [Highlight<NSAttributedString>] = markdown()",
                                "public final class ViewController: NSViewController {",
                                "@IBOutlet public var textView: NSTextView!",
                                "public func highlightSyntax(code: String) throws -> [(Range<String.Index>, Kind)] {"]
        XCTAssertEqual(prefixable, parser.isPrefixable)
        for (lineNumber, expectedLine) in expectedNewLines.enumerated() {
            XCTAssertEqual(expectedLine, newLines[lineNumber])
        }
    }
    
    func testPropertiesInsideStruct() {
        let lines = ["struct Highlight<Result> where Result: Block & HighlightedCode {",
            "let rendered: Result"]
        let prefixable = [true, true]
        let expectedNewLines = ["public struct Highlight<Result> where Result: Block & HighlightedCode {",
                                "public let rendered: Result"]

        let parser = Parser(lines: lines)
        let newLines = parser.newLines(at: [0, 1], level: .public)
        XCTAssertEqual(prefixable, parser.isPrefixable)
        for (lineNumber, expectedLine) in expectedNewLines.enumerated() {
            XCTAssertEqual(expectedLine, newLines[lineNumber])
        }
    }
    
    func testPropertiesMethodsInsideProtocol() {
        let lines = ["protocol HighlightedCode {",
            "static func highlight(text: String, tokens: [(Range<String.Index>, Kind)]) -> Self",
            "var whatever { get }",
        "var another { get set }"]
        let prefixable = [true, false, false, false]
        let parser = Parser(lines: lines)
        XCTAssertEqual(parser.isPrefixable, prefixable)
        XCTAssertEqual(parser.structure.declarations, [Declaration.init(keyword: .protocol, openBrace: true)])
    }
    
    func testPropertiesMethodsInsideProtocolWithClosingBrace() {
        let lines = ["protocol HighlightedCode {",
                     "static func highlight(text: String, tokens: [(Range<String.Index>, Kind)]) -> Self",
                     "var whatever { get }",
                     "var whatever { get }",
                     "var whatever { get }",
                     "var another { get set }",
                     "}"]
        let prefixable = [true, false, false, false, false, false, false]
        let parser = Parser(lines: lines)
        XCTAssertEqual(parser.isPrefixable, prefixable)
        XCTAssertEqual(parser.structure.declarations, [])
    }
    
    func testExtensionWithConformance() {
        let lines = ["extension NSAttributedString: Block {",
        "static func paragraph(text: String) -> Self {",
        "return .init(string: text)",
        "}"]
        let prefixable = [false, true, false, false]
        let parser = Parser(lines: lines)
        XCTAssertEqual(prefixable, parser.isPrefixable)
    }
    
    func testInitAsMethodNotRecognized() {
        let lines = [("extension NSAttributedString: HighlightedCode {", false),
                     ("static func highlight(text: String, tokens: [(Range<String.Index>, Kind)]) -> Self {", true),
                     (" let result = NSMutableAttributedString(string: text)", false),
                     (" for highlight in tokens {", false),
                     (" let range = NSRange(highlight.0, in: text)" , false),
                     (" let color = highlight.1.color" , false),
                     ("  result.addAttribute(.foregroundColor, value: color, range: range)", false),
                     (" }", false),
                     (" return .init(attributedString: result)", false),
                     ("  }", false),
                     (" }", false),
                     
                     (" extension NSAttributedString: Block {", false) ,
                     ("  static func paragraph(text: String) -> Self {", true),
                     ("  return .init(string: text)", false),
                     ("   }", false) ,
                     
                     (" static func codeBlock(text: String, language: String?) -> Self {", true),
                     ("  return .init(string: text)", false),
                     (" }", false),
                     ("  }", false)]
        let parser = Parser(lines: lines.map { $0.0 })
        for (index, line) in lines.enumerated() {
            XCTAssertEqual(parser.isPrefixable[index], line.1, "Line no.: \(index) \(line) was incorrectly parsed")
        }
    }
    
    func testDoubleAttributeMarking() {
        let lines = [("@IBOutlet private var Thing : UISwitch", true)]
        let parser = Parser(lines: lines.map { $0.0} )
        for (index, line) in lines.enumerated() {
            XCTAssertEqual(line.1, parser.isPrefixable[index], "Line no.: \(index) \(line) was incorrectly parsed")
        }
        let expectedNewLine = [0 : "@IBOutlet public var Thing : UISwitch"]
        let newLines = parser.newLines(at: [0], level: .public)
        XCTAssertEqual(newLines, expectedNewLine)
        
    }
    
    func testRemoval() {
        let lines = ["public let strings: [Highlight<NSAttributedString>] = markdown()",
                                "public final class ViewController: NSViewController {",
                                "@IBOutlet public var textView: NSTextView!",
                                "public func highlightSyntax(code: String) throws -> [(Range<String.Index>, Kind)] {"]
        let expectedNewLines = ["let strings: [Highlight<NSAttributedString>] = markdown()",
                                                               "final class ViewController: NSViewController {",
                                                               "@IBOutlet var textView: NSTextView!",
                                                               "func highlightSyntax(code: String) throws -> [(Range<String.Index>, Kind)] {"]
        let parser = Parser(lines: lines)
        let newLines = parser.newLines(at: [0, 1, 2, 3], level: .remove)
        for (index, expectedline) in expectedNewLines.enumerated() {
            XCTAssertEqual(newLines[index], expectedline, "Line no.: \(index) \(lines[index]) was incorrectly parsed")
        }
    }
    
    func testRequiredInitKeyword() {
        let lines = [
         "required init?(coder aDecoder: NSCoder) {",
         "super.init(style: .grouped)",
        " }"]
        let expectedNewLines = [
            "required public init?(coder aDecoder: NSCoder) {", nil, nil]
        let parser = Parser(lines: lines)
        let newLines = parser.newLines(at: [0, 1, 2], level: .public)
        for (index, expectedline) in expectedNewLines.enumerated() {
            XCTAssertEqual(newLines[index], expectedline, "Line no.: \(index) \(lines[index]) was incorrectly parsed")
        }
    }
    
    func testTypeAliasDecoration() {
        let lines = [
         "typealias WriteToState<State> = ((inout State) -> ()) -> ()"
         ]
        let expectedNewLines  = [
            "public typealias WriteToState<State> = ((inout State) -> ()) -> ()"
        ]
        let parser = Parser(lines: lines)
        let newLines = parser.newLines(at: [0], level: .public)
        for (index, expectedline) in expectedNewLines.enumerated() {
            XCTAssertEqual(newLines[index], expectedline, "Line no.: \(index) \(lines[index]) was incorrectly parsed")
        }
    }
    
    func testMutatingDecoration() {
    let lines = ["mutating func nest<X>(_ element: FormElement<X, State>) {",
                 "strongReferences.append(contentsOf: element.strongReferences)"]
    let expectedNewLines = ["public mutating func nest<X>(_ element: FormElement<X, State>) {", nil]
        let parser = Parser(lines: lines)
        let newLines = parser.newLines(at: [0], level: .public)
        for (index, expectedline) in expectedNewLines.enumerated() {
            XCTAssertEqual(newLines[index], expectedline, "Line no.: \(index) \(lines[index]) was incorrectly parsed")
        }
    }
    
    func testLastLineOfStructWithoutParens() {
        let lines = [
        "@testable import Parser",
        "",
        "struct CloudKitIdentifiers {",
        "let container: String",
        "let placesZone : String",
        "let databaseSubscriptionID: String",
        "let placesZoneSubscriptionID  : String",
        "}"]
        let expectedNewLines = [
            nil, "",
            "public struct CloudKitIdentifiers {",
            "public let container: String",
            "public let placesZone : String",
            "public let databaseSubscriptionID: String",
            "public let placesZoneSubscriptionID  : String"]
        let parser = Parser(lines: lines)
        let newLines = parser.newLines(at: [1 , 2, 3 ,4, 5, 6], level: .public)
        for (index, expectedline) in expectedNewLines.enumerated() {
            XCTAssertEqual(newLines[index], expectedline, "Line no.: \(index) \(lines[index]) was incorrectly parsed")
        }
        
    }
    
    func testEnumCases() {
        
        let test = """
                 enum Reps {
                    case count(Int)
                     case range(ClosedRange<Int>)
                     case amrap
                     case dropset(count: Int)
                     case rpe(Int)
                     case max(Int)
                     case time(Int)
                     case ladder([Int])
                }
                """
        let lines = test.components(separatedBy: .newlines)
        let prefixable: [Bool] = {
            var a = Array.init(repeating: false, count: lines.count)
            a[0] = true
            return a
        }()
        let parser = Parser(lines: lines)
        
        for (index, line) in lines.enumerated() {
            XCTAssertEqual(prefixable[index], parser.isPrefixable[index], "Line no.: \(index) \(line) was incorrectly parsed")
        }
    }
    
//    func testBlankLineReturnsNil() {
//        let lines = [""]
//        let expectedNewLines: [String?] = [nil]
//        let parser = Parser(lines: lines)
//        XCTAssertEqual(parser.newLines(at: [0], level: .public)[0], expectedNewLines[0])
//    }
    
    func testComputedVariables() {
        let test = """
var oneOrMore: Parser<[A]> {
// prepend the single result + remainder many result
let transform: (A, [A]) -> [A] = { single, array in return [single] + array }
let curried = curry(transform)
let intermediate = curried <^> self  // Parser<([A]) -> [A]>
let final = intermediate <*> self.many // Parser<[A]>
return final
}
"""
        let expected = """
public var oneOrMore: Parser<[A]> {
// prepend the single result + remainder many result
let transform: (A, [A]) -> [A] = { single, array in return [single] + array }
let curried = curry(transform)
let intermediate = curried <^> self  // Parser<([A]) -> [A]>
let final = intermediate <*> self.many // Parser<[A]>
return final
"""
        multilineTest(test: test, expected: expected)
    }
    
    func testComplexAssignmentsWithCurlyBraces() {
        let test = """
private let wales = countries[0].regions.first { $0.name == "Wales" }!
private let england = countries[0].regions.first { $0.name == "England" }!
private let english = england.languages.first { $0.name == "English" }!

"""
        let expected = """
public let wales = countries[0].regions.first { $0.name == "Wales" }!
public let england = countries[0].regions.first { $0.name == "England" }!
public let english = england.languages.first { $0.name == "English" }!

"""
    multilineTest(test: test, expected: expected)
    }
    
    func testComplexAssignmentListWithFancyOperators() {
        let test = """
let range = curry({ from, _, to in return RepStyle.range(from...to) }) <^> digits <*> hyphen <*> digits //8-12
let dropset = curry({ _, _, count in return RepStyle.dropset(count: count) }) <^> string("dropset") <*> hyphen <*> digits //dropset-4
let count = { RepStyle.count($0) } <^> digits <* character { $0 == "x" } //15
let amrap = { _ in RepStyle.amrap } <^> string("AMRAP")
let time = { RepStyle.time($0) } <^> digits <* character { $0 == "s" } //30s
let rpe = { RepStyle.rpe($0) } <^> (string("rpe") *> digits)  //rpe8
let ladder = { RepStyle.ladder($0) } <^> (digits <* character { $0 == "," }).oneOrMore // 12,10,8,6,8,10,12
let max = { RepStyle.max($0) } <^> digits <* character { $0 == "%" } //30%
let repStyle = ladder <|> dropset <|> range <|> time <|> rpe <|> amrap <|> max <|> count
"""
        let expected = """
public let range = curry({ from, _, to in return RepStyle.range(from...to) }) <^> digits <*> hyphen <*> digits //8-12
public let dropset = curry({ _, _, count in return RepStyle.dropset(count: count) }) <^> string("dropset") <*> hyphen <*> digits //dropset-4
public let count = { RepStyle.count($0) } <^> digits <* character { $0 == "x" } //15
public let amrap = { _ in RepStyle.amrap } <^> string("AMRAP")
public let time = { RepStyle.time($0) } <^> digits <* character { $0 == "s" } //30s
public let rpe = { RepStyle.rpe($0) } <^> (string("rpe") *> digits)  //rpe8
public let ladder = { RepStyle.ladder($0) } <^> (digits <* character { $0 == "," }).oneOrMore // 12,10,8,6,8,10,12
public let max = { RepStyle.max($0) } <^> digits <* character { $0 == "%" } //30%
public let repStyle = ladder <|> dropset <|> range <|> time <|> rpe <|> amrap <|> max <|> count
"""
        multilineTest(test: test, expected: expected)
    }
    
    func testIncompleteBraceSelection() {
        let test = """
struct CloudKitIdentifiers {
let container: String
let placesZone : String
let databaseSubscriptionID: String
let placesZoneSubscriptionID : String
"""
         let expected = """
public struct CloudKitIdentifiers {
public let container: String
public let placesZone : String
public let databaseSubscriptionID: String
public let placesZoneSubscriptionID : String
"""
        multilineTest(test: test, expected: expected)
    }
    
    func testVariablesDefinedWithLocalScopeInVarDontGetAccessNotation() {
        let test = """
var patchMark: String {
let fstMark = "yo"
let sndMark = "beef"
return "@@@@"
}
"""
        let expected = """
public var patchMark: String {
let fstMark = "yo"
let sndMark = "beef"
return "@@@@"
}
"""
        multilineTest(test: test, expected: expected)
    }
    
    func testComplexAssignmentsVarsWithCurlyBraces() {
        let test = """
private var wales = countries[0].regions.first { $0.name == "Wales" }!
private var england = countries[0].regions.first { $0.name == "England" }!
private var english = england.languages.first { $0.name == "English" }!

"""
        let expected = """
public var wales = countries[0].regions.first { $0.name == "Wales" }!
public var england = countries[0].regions.first { $0.name == "England" }!
public var english = england.languages.first { $0.name == "English" }!

"""
        multilineTest(test: test, expected: expected)
    }

    func testVariablesDefinedWithLocalScopeInLetDontGetAccessNotation() {
        let test = """
let patchMark: String {
let fstMark = "yo"
let sndMark = "beef"
return "@@@@"
}()
"""
        let expected = """
public let patchMark: String {
let fstMark = "yo"
let sndMark = "beef"
return "@@@@"
}()
"""
        multilineTest(test: test, expected: expected)
    }
    
    func testAccessModifierAfterStaticKeywordIsRecognized() {
        let test = """
static private func == (lhs: Index, rhs: Index) -> Bool {
switch (lhs, rhs) {
case (.array(let left), .array(let right)):
return left == right
case (.dictionary(let left), .dictionary(let right)):
return left == right
case (.null, .null): return true
default:
return false
}
}
"""
        
        let expected = """
static public func == (lhs: Index, rhs: Index) -> Bool {
switch (lhs, rhs) {
case (.array(let left), .array(let right)):
return left == right
case (.dictionary(let left), .dictionary(let right)):
return left == right
case (.null, .null): return true
default:
return false
}
}
"""
        multilineTest(test: test, expected: expected)
    }
    
    func testStaticKeywordRecognizedCorrectly() {
        let test = """
        static var playing: [PlayerCore] {
        return playerCores.filter { !$0.info.isIdle }
        }
        
        static var playerCores: [PlayerCore] = []
        static private var playerCoreCounter = 0
        
        static private func findIdlePlayerCore() -> PlayerCore? {
        return playerCores.first { $0.info.isIdle && !$0.info.fileLoading }
        }
        
        static private func createPlayerCore() -> PlayerCore {
        let pc = PlayerCore()
        playerCores.append(pc)
        pc.startMPV()
        playerCoreCounter += 1
        return pc
        }
        
        static func activeOrNewForMenuAction(isAlternative: Bool) -> PlayerCore {
        let useNew = Preference.bool(for: .alwaysOpenInNewWindow) != isAlternative
        return useNew ? newPlayerCore : active
        }
"""
        let expected = """
        static public var playing: [PlayerCore] {
        return playerCores.filter { !$0.info.isIdle }
        }
        
        static public var playerCores: [PlayerCore] = []
        static public var playerCoreCounter = 0
        
        static public func findIdlePlayerCore() -> PlayerCore? {
        return playerCores.first { $0.info.isIdle && !$0.info.fileLoading }
        }
        
        static public func createPlayerCore() -> PlayerCore {
        let pc = PlayerCore()
        playerCores.append(pc)
        pc.startMPV()
        playerCoreCounter += 1
        return pc
        }
        
        static public func activeOrNewForMenuAction(isAlternative: Bool) -> PlayerCore {
        let useNew = Preference.bool(for: .alwaysOpenInNewWindow) != isAlternative
        return useNew ? newPlayerCore : active
        }
"""
        multilineTest(test: test, expected: expected)
    }
    
    func testIgnoreAvailableModifier() {
        let test = """
/// The static null JSON
@available(*, unavailable, renamed:"null")
private static var nullJSON: JSON { return null }
private static var null: JSON { return JSON(NSNull()) }
"""
        let expected = """
/// The static null JSON
@available(*, unavailable, renamed:"null")
public static var nullJSON: JSON { return null }
public static var null: JSON { return JSON(NSNull()) }
"""
        multilineTest(test: test, expected: expected)
    }

    func testObjcModifierIgnored() {
        let test = """
  @objc
  private func droppedText(_ pboard: NSPasteboard, userData:String, error: NSErrorPointer) {
    if let url = pboard.string(forType: .string) {
      openFileCalled = true
      PlayerCore.active.openURLString(url)
    }
  }
"""
        let expected = """
  @objc
  public func droppedText(_ pboard: NSPasteboard, userData:String, error: NSErrorPointer) {
    if let url = pboard.string(forType: .string) {
      openFileCalled = true
      PlayerCore.active.openURLString(url)
    }
  }
"""
        multilineTest(test: test, expected: expected)
    }
    
    func testSomething() {
        let test = """

"""
        let expected = """

"""
        multilineTest(test: test, expected: expected)
    }
    
    func multilineTest(test: String, expected: String, file: StaticString = #file, line: UInt = #line) {
        let lines = test.components(separatedBy: .newlines)
        let expectedLines = expected.components(separatedBy: .newlines)
        let parser = Parser(lines: lines)
        let parsedLines = parser.newLines(at: 0..<lines.count, level: .public)
        for (index, expectedline) in expectedLines.enumerated() {
            if expectedline != lines[index] {
                // Parsed line should exist if the expected line is different
                XCTAssertNotNil(parsedLines[index])
            }
            if let parsedLine = parsedLines[index] {
                XCTAssertEqual(expectedline, parsedLine, "Line no.: \(index) \(lines[index]) was incorrectly parsed", file: file, line: line)
            }
        }
    }
}

extension Parser {
    func newLines(at lineNumbers: Range<Int>, level: Access) -> [Int : String] {
        return newLines(at: Array(lineNumbers), level: level)
    }
}
