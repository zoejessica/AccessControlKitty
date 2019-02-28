//
//  Lexer.swift
//  Temporary
//
//  Created by Zoe Smith on 4/20/18.
//  Copyright © 2018-9 Zoë Smith. Distributed under the MIT License.
//


// Helped a lot by a series of blog posts by Harlan Haskins on lexing and parsing in Swift: 
// https://harlanhaskins.com/2017/01/08/building-a-compiler-with-swift-in-llvm-part-1-introduction-and-the-lexer.html

import Foundation

protocol WordTag {}
typealias Word = Tagged<WordTag, String>

public class Lexer {
    
    var insideMultilineComment: Bool = false
    var insideMultilineString: Bool = false
    
    func analyse(_ line: String) -> [Token] {
        

        var line = line

        // Check to see if the line does include an end of multiline comment
        // If so trim the line of its comment prefix and continue
        // Otherwise the line can be ignored, return an empty token array for this line
        if insideMultilineComment {
            if let newLine = trimLineAfterEndMultilineComment(line: line) {
                line = newLine
                insideMultilineComment = false
            } else {
                return []
            }
        }
        
        // Check for multiline string:
        if !insideMultilineString, let range = match(line, with: multiLineRegex) {
            if insideMultilineString {
                insideMultilineString = false
                return []
            } else {
                line = String(line.prefix(upTo: range.lowerBound))
                insideMultilineString = true
            }
        }
        
        // Remove single line strings:
        while let match = match(line, with: stringRegex) {
            line.removeSubrange(match)
        }
        
        let trimmedAndSeparatedWords = line.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .whitespacesAndNewlines).map { Word(rawValue: $0) }
        var lineTokens: [Token] = []
        tokenisingLine: for word in trimmedAndSeparatedWords {
            
            do {
                lineTokens += try tokenise(word)
            } catch LexerError.singleLineComment(let tokens) {
                lineTokens += tokens
                break tokenisingLine
            } catch {
                fatalError("unhandled error")
            }
        }
        return lineTokens
    }

    func tokenise(_ word: Word) throws -> [Token] {
        let s = word.rawValue
        if !insideMultilineComment, let token = Token(SingleCharacter.init(rawValue: s)) ?? Token(Keyword.init(rawValue: s)) {
            return [token]
        } else {
            return try readByCharacters(word)
        }
    }

    func readByCharacters(_ word: Word) throws -> [Token] {
        var tokens: [Token] = []
        let string = word.rawValue
        var startIndex: String.Index = string.startIndex
        
        while startIndex < string.endIndex {
            do {
                let result = try read(slice: string[startIndex..<string.endIndex])
                if let token = result.token { tokens.append(token) }
                startIndex = result.newStartIndex
            } catch LexerError.singleLineComment { throw LexerError.singleLineComment(tokens)
            } catch  { throw error }
        }
        return tokens
    }

    enum LexerError : Error {
        case singleLineComment([Token])
        case startMultiLineComment
    }

    func read(slice: Substring) throws -> (token: Token?, newStartIndex: Substring.Index) {
        var startIndex = slice.startIndex
        
        // Ignore rest of slice if it starts with a multiline comment
        if let indexAfterComment = hasMultilineCommentPrefix(slice: slice) {
            insideMultilineComment = true
            return (nil, indexAfterComment)
        }
        
        if insideMultilineComment {
            // If we are in a multiline comment, but it's terminated within this slice
            // ignore the characters before the termination and then continue to read by character:
            if let termination = slice.range(of: "*/") {
                startIndex = termination.upperBound
                insideMultilineComment = false
                return (nil, startIndex)
            
            // If however the multiline comment does not terminate
            // the whole word should be ignored:
            } else {
                return (nil, slice.endIndex)
            }
        }

        // Check to see if the next characters are a comment:
        if !insideMultilineComment { try isComment(slice: slice) }
        
        // Return a token if found
        if let result = readIdentifier(slice: slice) {
            return (result.token, result.newStartIndex)
        }
        
        // Unknown first character - advance the index and return a nil token
        slice.formIndex(after: &startIndex)
        return (nil, startIndex)
    }

    func readIdentifier(slice: Substring) -> (token: Token, newStartIndex: Substring.Index)? {
        let string = String(slice)
        for (pattern, generator) in tokenList {
            if let matchRange = match(string, pattern: pattern) {
                let match = string[matchRange]
                if  let token = generator(String(match)),
                    let newStartIndex = slice.range(of: match)?.upperBound {
                    return (token, newStartIndex)
                }
            }    
        }
        return nil
    }
}
