//
//  TerminalNodeWithHiddenTests.swift
//  Antlr4
//
//  Created by Hanzhou Shi on 2/26/17.
//  Copyright © 2017 jlabs. All rights reserved.
//

import XCTest
import Antlr4

class SwiftTestParserOverriden : SwiftTestParser {
    override func createTerminalNode(parent: ParserRuleContext, t: Token) -> TerminalNode {
        let node = TerminalNodeWithHidden(tokens: tokens, channel: -1, symbol: t)
    }
}

class TerminalNodeWithHiddenTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testEmptyInputWithCommentNoEOFRefInGrammar() {
    }

    func testEmptyInputWithCommentEOFRefInGrammar() {
    }

    func testWSBeforeFirstToken() {
    }

    func testWSAfterLastToken() {
    }

    func testWSBeforeAfterSingleToken() {
    }
    
    func testMultilineWSAfterLastTokenGetsAll() {
        
    }
    
    func testMultilineWSAfterTokenGetsOnLineOnly() {
        
    }
    
    func testWSAroundSingleOp() {
    }
    
    func parse_calc(input: String) {
        let lexer = SwiftTestLexer(ANTLRInputStream(input))
        let tokens = CommonTokenStream(lexer)
        let parser = SwiftTestParser(tokens)
    }
}
