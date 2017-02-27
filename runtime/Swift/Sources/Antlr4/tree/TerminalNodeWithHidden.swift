/// Copyright (c) 2012-2016 The ANTLR Project. All rights reserved.
/// Use of this file is governed by the BSD 3-clause license that
/// can be found in the LICENSE.txt file in the project root.
/// How to emit recognition errors.


/** Track text of hidden channel tokens to left and right of terminal node
 *  according to the rules borrowed from Roslyn on trivia:
 *
 *   "In general, a token owns any trivia after it on the same line up to
 *    the next token. Any trivia after that line is associated with the
 *    following token. The first token in the source file gets all the
 *    initial trivia, and the last sequence of trivia in the file is
 *    tacked onto the end-of-file token, which otherwise has zero width."
 *
 *  These rules are implemented by in {@link #collectHiddenTokens}. It
 *  deviates from Roslyn rules in that final whitespace is added to
 *  last real token not the EOF token.
 *
 *  An empty input is a special case. If the start rule has a reference to EOF,
 *  then the tree will also have a terminal node for that. If the input
 *  is empty except for whitespace or comments, then the EOF terminal node
 *  has these as hiddenLeft as a special case.
 *
 *  If there is no reference to EOF, then the parse tree is a single internal
 *  node for the start rule. Consequently there would be no place to stick the
 *  whitespace or comments; in effect, those will not get added to the tree.
 *
 *  To use this class, override these methods to create
 *  TerminalNodeWithHidden nodes:
 *  {@link org.antlr.v4.runtime.Parser#createErrorNode(ParserRuleContext, Token)} and
 *  {@link org.antlr.v4.runtime.Parser#createTerminalNode(ParserRuleContext, Token)}.
 *
 *  Example:
 *      class MySwiftTestParser : SwiftTestParser {
 *          init(tokens: TokenStream) {
 *              super(tokens)
 *          }
 *          override TerminalNode createTerminalNode(_ parent: ParserRuleContext, _ t: Token) {
 *              let node = TerminalNodeWithHidden(tokens, -1, t)
 *              node.parent = parent
 *              return node
 *          }
 *      }
 *
 *  @since 4.6.1
 */
public class TerminalNodeWithHidden : TerminalNodeImpl {
    
    /// Hidden tokens left of this node's token. hiddenLeft[0]
    /// is the furthest token from this node's token.
    var hiddenLeft: [Token]?
    
    /// Hidden tokens right of this node's token. hiddenRight[0]
    /// is the first token from this node's token.
    var hiddenRight: [Token]?

    /// Construct a node with left/right hidden tokens on a channel,
    /// or all hiden tokens if channel==-1.
    ///
    /// - Parameters:
    ///   - tokens: input token stream
    ///   - channel: channel indicator, -1 for all hidden channels
    ///   - symbol: the "surrounded" token
    public init(tokens: BufferedTokenStream, channel: Int, symbol: Token) {
      	super.init(symbol)
      	collectHiddenTokens(tokens, channel, symbol);
    }
   
    // TODO: how to collect hidden on error nodes (deleted, inserted, during recovery)
    public func collectHiddenTokens(_ tokens: BufferedTokenStream , _ channel: Int, _ symbol: Token) {
        let left = try! tokens.getHiddenTokensToLeft(symbol.getTokenIndex(), channel)
        _ = left.map {
            let firstHiddenLeft = $0[0]
            var prevReal: Token?
          	if firstHiddenLeft.getTokenIndex() > 0 {
                prevReal = try! tokens.get(firstHiddenLeft.getTokenIndex() - 1)
          	}
            if prevReal == nil { // this symbol is first real token (or EOF token) of file
                hiddenLeft = try! tokens.get(0, symbol.getTokenIndex() - 1)
          	}
          	else {
          		// collect all tokens on next line after prev real
                var nextTokens = [Token]()
          		for t in $0 {
          			if t.getLine() > prevReal!.getLine() {
                        nextTokens.append(t)
          			}
          		}
                hiddenLeft = nextTokens
          	}
        }
      
        let right = try! tokens.getHiddenTokensToRight(symbol.getTokenIndex(), channel)
        _ = right.map {
            let lastHiddenRight = $0[$0.count - 1]
            // FIXME: What if nextReal is not initialized?
            var nextReal: Token?
            if symbol.getType() != CommonToken.EOF {
                nextReal = try! tokens.get(lastHiddenRight.getTokenIndex() + 1)
            }
          	// If this is last real token, collect all hidden to right
            if nextReal!.getType() == CommonToken.EOF {
                hiddenRight = try! tokens.get($0[0].getTokenIndex(), nextReal!.getTokenIndex())
            }
            else {
                // collect all token text on same line to right
                let tokenLine = symbol.getLine()
                var nextTokens = [Token]()
                for t in $0 {
                    if t.getLine() == tokenLine {
                        nextTokens.append(t)
                    }
                }
                hiddenRight = nextTokens
            }
        }
    }
    
	public func getHiddenLeft() -> [Token]? {
        return hiddenLeft
    }
    
    public func getHiddenRight() -> [Token]? {
        return hiddenRight
    }
    
    public func setHiddenLeft(_ hiddenLeft: [Token]) {
        self.hiddenLeft = hiddenLeft
    }
   
    public func setHiddenRight(_ hiddenRight: [Token]) {
        self.hiddenRight = hiddenRight
    }
    
	override public func getText() -> String {
        let buf = StringBuilder()
        _ = hiddenLeft.map {
            _ = $0.map {
                t in buf.append(t.getText()!)
            }
        }
        buf.append(super.getText())
        _ = hiddenRight.map {
            _ = $0.map {
                t in buf.append(t.getText()!)
            }
        }
        return buf.toString();
    }
}
