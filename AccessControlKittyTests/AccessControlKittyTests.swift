//
//  AccessControlKittyTests.swift
//  AccessControlKittyTests
//
//  Created by Zoe Smith on 16/2/19.
//  Copyright © 2019 Hot Beverage. All rights reserved.
//

import XCTest
import XcodeKit

class AccessControlKittyTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testEntireLineSelected() {
        // - <XCSourceTextRange: 0x7fb173e151a0 {{line: 49, column: 0}, {line: 50, column: 0}}> #0
        let range = XCSourceTextRange(start: XCSourceTextPosition(line: 49, column: 0), end: XCSourceTextPosition(line: 50, column: 0))
        let expected = [49]
        XCTAssertEqual(lines(range, totalLinesInBuffer: 50), expected)
    }
    
    func testPartialSingleLineSelected() {
        //  <XCSourceTextRange: 0x7fd437c143a0 {{line: 49, column: 0}, {line: 49, column: 33}}>
        let range = XCSourceTextRange(start: XCSourceTextPosition(line: 49, column: 0), end: XCSourceTextPosition(line: 49, column: 33))
        let expected = [49]
        XCTAssertEqual(lines(range, totalLinesInBuffer: 50), expected)
    }
    
    func testEntireSourceFileSelected() {
        //  <XCSourceTextRange: 0x7fd437c189d0 {{line: 0, column: 0}, {line: 82, column: 0}}
        // 82 line count
        let range = XCSourceTextRange(start: XCSourceTextPosition(line: 0, column: 0), end: XCSourceTextPosition(line: 82, column: 0))
        let expected =  Array(0...81)
        XCTAssertEqual(lines(range, totalLinesInBuffer: 82), expected)
    }
    
    func testEntireSourceFileSelectedWithoutLastReturn() {
        //  <XCSourceTextRange: 0x7fd437c189d0 {{line: 0, column: 0}, {line: 82, column: 0}}
        // 82 line count
        let range = XCSourceTextRange(start: XCSourceTextPosition(line: 0, column: 0), end: XCSourceTextPosition(line: 82, column: 0))
        let expected =  Array(0...81)
        XCTAssertEqual(lines(range, totalLinesInBuffer: 82), expected)
    }
    
    func testMultiplePartialLinesSelected() {
        // - <XCSourceTextRange: 0x7fd437d05c20 {{line: 49, column: 0}, {line: 52, column: 34}}> #0
        let range = XCSourceTextRange(start: XCSourceTextPosition(line: 49, column: 0), end: XCSourceTextPosition(line: 52, column: 34))
        let expected = [49, 50, 51, 52]
        XCTAssertEqual(lines(range, totalLinesInBuffer: 50), expected)
    }
    
    func testColumnarSelections() {
        /* ▿ 3 elements
        - <XCSourceTextRange: 0x7fddf1c068d0 {{line: 71, column: 15}, {line: 71, column: 23}}> #0
        - super: NSObject
        - <XCSourceTextRange: 0x7fddf1c06900 {{line: 72, column: 15}, {line: 72, column: 23}}> #1
        - super: NSObject
        - <XCSourceTextRange: 0x7fddf1c06930 {{line: 73, column: 15}, {line: 73, column: 23}}> #2
        - super: NSObject
        Line count: 82
 */
        let ranges = [XCSourceTextRange(start: XCSourceTextPosition(line: 71, column: 15), end: XCSourceTextPosition(line: 71, column: 23)),
                     XCSourceTextRange(start: XCSourceTextPosition(line: 72, column: 15), end: XCSourceTextPosition(line: 72, column: 23)),
                     XCSourceTextRange(start: XCSourceTextPosition(line: 73, column: 15), end: XCSourceTextPosition(line: 73, column: 23))]
        let expected = [71, 72, 73]
        XCTAssertEqual(ranges.flatMap { lines($0, totalLinesInBuffer: 82) }, expected)
    }
}
