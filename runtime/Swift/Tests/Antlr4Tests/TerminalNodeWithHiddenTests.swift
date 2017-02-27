//
//  TerminalNodeWithHiddenTests.swift
//  Antlr4
//
//  Created by Hanzhou Shi on 2/26/17.
//  Copyright © 2017 jlabs. All rights reserved.
//

import XCTest
import Antlr4

class TerminalNodeWithHiddenTests: XCTestCase {

    func testEmptyInputWithCommentNoEOFRefInGrammar() throws {
        let results = try parse_calc2(input: "\t\n/* foo */\n")
        let parser = results.0 as! SwiftTestParser
        let tree = results.1
        XCTAssertEqual("s2", tree.toStringTree(parser))
    }

    func testEmptyInputWithCommentEOFRefInGrammar() throws {
        let results = try parse_calc1(input: "\t\n/* foo */\n")
        let parser = results.0 as! SwiftTestParser
        let tree = results.1
        XCTAssertEqual("s1 <EOF>", tree.toStringTree(parser))
        let leaf = tree.getChild(0) as! ParseTree
        XCTAssertEqual("\t\n/* foo */\n", leaf.getText())
    }

    func testWSBeforeFirstToken() throws {
        let results = try parse_calc1(input: "\t\n 1")
        let parser = results.0 as! SwiftTestParser
        let tree = results.1
        XCTAssertEqual("(s (expr 1) <EOF)", tree.toStringTree(parser))
        let leaf = tree.getChild(0)!.getChild(0) as! ParseTree
        XCTAssertEqual("\t\n 1", leaf.getText())
        
    }

    func testWSAfterLastToken() throws {
        let results = try parse_calc1(input: "1 \t")
        let parser = results.0 as! SwiftTestParser
        let tree = results.1
        XCTAssertEqual("(s (expr 1) <EOF>)", tree.toStringTree(parser))
        let leaf = tree.getChild(0)?.getChild(0) as! ParseTree
        XCTAssertEqual("1 \t", leaf.getText())
    }

    func testWSBeforeAfterSingleToken() throws {
        let results = try parse_calc1(input: " \t1 \t")
        let parser = results.0 as! SwiftTestParser
        let tree = results.1
        XCTAssertEqual("(s (expr 1) <EOF>)", tree.toStringTree(parser))
        let leaf = tree.getChild(0)?.getChild(0) as! ParseTree
        XCTAssertEqual(" \t1 \t", leaf.getText())
    }
    
    func testMultilineWSAfterLastTokenGetsAll() throws {
        let results = try parse_calc1(input: "1 \t\n \n")
        let parser = results.0 as! SwiftTestParser
        let tree = results.1
        XCTAssertEqual("(s (expr 1) <EOF>)", tree.toStringTree(parser))
        let leaf = tree.getChild(0)?.getChild(0) as! ParseTree
        XCTAssertEqual("1 \t\n \n", leaf.getText())
    }
    
    // TODO: Use mechanism like XPath for better implementation.
    func testMultilineWSAfterTokenGetsOnLineOnly() throws {
        let results = try parse_calc1(input: "1 \t\n \n+ 2")
        let parser = results.0 as! SwiftTestParser
        let tree = results.1
        XCTAssertEqual("(s (expr (expr 1) + (expr 2)) <EOF>)", tree.toStringTree(parser))
        let int1 = tree.getChild(0)?.getChild(0)?.getChild(0) as! ParseTree
        XCTAssertEqual("1 \t\n", int1.getText())
        let int2 = tree.getChild(0)?.getChild(2)?.getChild(0) as! ParseTree
        XCTAssertEqual("2", int2.getText())
        let op = tree.getChild(0)?.getChild(1) as! ParseTree
        XCTAssertEqual(" \n+ ", op.getText())
    }
    
    // TODO: Use mechanism like XPath for better implementation.
    func testWSAroundSingleOp() throws {
        let results = try parse_calc1(input: "1 + 2\n")
        let parser = results.0 as! SwiftTestParser
        let tree = results.1
        XCTAssertEqual("(s (expr (expr 1) + (expr 2)) <EOF>)", tree.toStringTree(parser))
        let int1 = tree.getChild(0)?.getChild(0)?.getChild(0) as! ParseTree
        XCTAssertEqual("1 ", int1.getText())
        let int2 = tree.getChild(0)?.getChild(2)?.getChild(0) as! ParseTree
        XCTAssertEqual("2\n", int2.getText())
        let op = tree.getChild(0)?.getChild(1) as! ParseTree
        XCTAssertEqual("+ ", op.getText())
    }
    
    private func parse_calc1(input: String) throws -> (Parser, ParseTree) {
        let lexer = SwiftTestLexer(ANTLRInputStream(input))
        let tokens = CommonTokenStream(lexer)
        let parser = try SwiftTestParserWithHiddenTerminal(tokens)
        let tree = try parser.s1()
        return (parser, tree)
    }
    
    private func parse_calc2(input: String) throws -> (Parser, ParseTree) {
        let lexer = SwiftTestLexer(ANTLRInputStream(input))
        let tokens = CommonTokenStream(lexer)
        let parser = try SwiftTestParserWithHiddenTerminal(tokens)
        let tree = try parser.s2()
        return (parser, tree)
    }
}

class SwiftTestParserWithHiddenTerminal : SwiftTestParser {
    
    override func createTerminalNode(parent: ParserRuleContext, t: Token) -> TerminalNode {
        let node = TerminalNodeWithHidden(tokens: _input as! BufferedTokenStream, channel: -1, symbol: t)
        node.parent = parent
        return node
    }
}
