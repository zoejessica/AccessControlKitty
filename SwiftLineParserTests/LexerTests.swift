//
//  TemporaryTests.swift
//  TemporaryTests
//
//  Created by Zoe Smith on 4/20/18.
//  Copyright © 2018-9 Zoë Smith. Distributed under the MIT License.
//

import XCTest
@testable import SwiftLineParser

class LexerTests: XCTestCase {
    
    var lexer: Lexer!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        lexer = Lexer()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testOutput() {
        let line = "public protocol foo {"
        let expectedOutput: [Token] = [.keyword(.public), .keyword(.protocol), .identifier("foo"), .singleCharacter(.bracketOpen)]
        XCTAssertEqual(lexer.analyse(line), expectedOutput)
    }
    
    func testOutputBracketSpacingA() {
        let line = "public protocol foo{"
        let expectedOutput: [Token] = [.keyword(.public), .keyword(.protocol), .identifier("foo"), .singleCharacter(.bracketOpen)]
        XCTAssertEqual(lexer.analyse(line), expectedOutput)
    }
    
    func testOutputBracketSpacingB() {
        let line = "{protocol}. ."
        let expectedOutput: [Token] = [.singleCharacter(.bracketOpen),
                                       .keyword(.protocol),
                                       .singleCharacter(.bracketClose)]
        XCTAssertEqual(lexer.analyse(line), expectedOutput)
    }
    
    func testOutputA() {
        let line = "override func setUp() {"
        let expectedOutput: [Token] = [.keyword(.override),
                                       .keyword(.func),
                                       .identifier("setUp"),
                                       .singleCharacter(.bracketOpen)]
        XCTAssertEqual(lexer.analyse(line), expectedOutput)
    }
    
    func testNumber() {
        let line = "override func setUp() 23456 {"
        let expectedOutput: [Token] = [.keyword(.override),
                                       .keyword(.func),
                                       .identifier("setUp"),
                                       .identifier("23456"),
                                       .singleCharacter(.bracketOpen)]
        XCTAssertEqual(lexer.analyse(line), expectedOutput)
    }
    
    func testSingleLineComment() {
        let line = "override //func setUp() 23456 {"
        let expectedOutput: [Token] = [.keyword(.override)]
        XCTAssertEqual(lexer.analyse(line), expectedOutput)

        let lineA = "override//func setUp() 23456 {"
        XCTAssertEqual(lexer.analyse(lineA), expectedOutput)
        
        let lineB = "override//*()(sdfgsdfrsdvfunc setUp() 23456 {"
        XCTAssertEqual(lexer.analyse(lineB), expectedOutput)
    }
    
    func testMultiLineCommentStart() {
        let line = "override /* func setUp() 23456 {"
        let expectedOutput: [Token] = [.keyword(.override)]
        XCTAssertEqual(lexer.analyse(line), expectedOutput)

        lexer.insideMultilineComment = false
        let lineA = "override/*///func setUp() 23456 {"
        XCTAssertEqual(lexer.analyse(lineA), expectedOutput)

        lexer.insideMultilineComment = false
        let lineB = "override/*/*/*override/*()(sdfgsdfrsdvfunc setUp() 23456 {"
        XCTAssertEqual(lexer.analyse(lineB), expectedOutput)
    }
    
    func testEndMultiLineComment() {
        let line = "*/override /* func setUp() 23456 {"
        let expectedOutput: [Token] = [.keyword(.override)]
        XCTAssertEqual(lexer.analyse(line), expectedOutput)
        XCTAssertTrue(lexer.insideMultilineComment)
        
        lexer.insideMultilineComment = false
        let lineA = "override/*///func setUp() 23456*/override {"
        let expectedOutputA: [Token] = [.keyword(.override), .keyword(.override), .singleCharacter(.bracketOpen)]
        XCTAssertEqual(lexer.analyse(lineA), expectedOutputA)
        XCTAssertFalse(lexer.insideMultilineComment)
        
        let lineB = "override/*///func setUp() 23456*/override {"
        let expectedOutputB: [Token] = [.keyword(.override), .keyword(.override), .singleCharacter(.bracketOpen)]
        XCTAssertEqual(lexer.analyse(lineB), expectedOutputB)
        XCTAssertFalse(lexer.insideMultilineComment)
    }
    
    func testString() {
        let line = "\"/*\" override"
        let expectedOutput: [Token] = [.keyword(.override)]
        XCTAssertEqual(lexer.analyse(line), expectedOutput)
        XCTAssertFalse(lexer.insideMultilineComment)
        
        let lineA = "\" override"
        XCTAssertEqual(lexer.analyse(lineA), expectedOutput)
        XCTAssertFalse(lexer.insideMultilineComment)
    }
    
    func testMultipleStrings() {
        let line = "\"override\" func struct \"23456\" thing \"other\" thing"
        let expectedOutput: [Token] = [.keyword(.func), .keyword(.struct), .identifier("thing"), .identifier("thing")]
        XCTAssertEqual(lexer.analyse(line), expectedOutput)
        XCTAssertFalse(lexer.insideMultilineComment)
    }
    
    func testMultilineString() {
        let line = "override \"\"\" func"
        let expectedOutput: [Token] = [.keyword(.override), .keyword(.func)]
        XCTAssertEqual(lexer.analyse(line), expectedOutput)
        XCTAssertFalse(lexer.insideMultilineString)
        
        let lineA = "override \"\"\"\n"
        let expectedOutputA: [Token] = [.keyword(.override)]
        XCTAssertEqual(lexer.analyse(lineA), expectedOutputA)
        XCTAssertTrue(lexer.insideMultilineString)
    }
    
    func testAttribute() {
        let line = "public protocol @IBOutlet foo {"
        let expectedOutput: [Token] = [.keyword(.public), .keyword(.protocol), .attribute("@IBOutlet"), .identifier("foo"), .singleCharacter(.bracketOpen)]
        XCTAssertEqual(lexer.analyse(line), expectedOutput)
    }
}

//func struct "23456" thing 
