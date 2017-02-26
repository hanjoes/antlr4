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
 *  @since 4.6.1
 */
public class TerminalNodeWithHidden : TerminalNodeImpl {
    
    var hiddenLeft: String?
    var hiddenRight: String?

    public init(tokens: BufferedTokenStream, channel: Int, symbol: Token) {
      	super.init(symbol)
      	collectHiddenTokens(tokens, channel, symbol);
    }
   
    // TODO: how to collect hidden on error nodes (deleted, inserted, during recovery)
    public func collectHiddenTokens(_ tokens: BufferedTokenStream , _ channel: Int, _ symbol: Token) {
        let left = try! tokens.getHiddenTokensToLeft(symbol.getTokenIndex(), channel)
        if left != nil {
            let firstHiddenLeft = left![0]
            var prevReal: Token?
          	if firstHiddenLeft.getTokenIndex() > 0 {
                prevReal = try! tokens.get(firstHiddenLeft.getTokenIndex() - 1)
          	}
            if prevReal == nil { // this symbol is first real token (or EOF token) of file
                hiddenLeft = try? tokens.getText(Interval.of(0, symbol.getTokenIndex()-1))
          	}
          	else {
          		// collect all token text on next line after prev real
          		let buf = StringBuilder()
          		for t in left! {
          			if t.getLine() > prevReal!.getLine() {
          				buf.append(t.getText()!)
          			}
          		}
          		hiddenLeft = buf.toString()
          	}
        }
      
        let right = try! tokens.getHiddenTokensToRight(symbol.getTokenIndex(), channel)
        if right != nil {
            let lastHiddenRight = right![right!.count - 1]
            var nextReal: Token?
            if symbol.getType() != CommonToken.EOF {
                nextReal = try! tokens.get(lastHiddenRight.getTokenIndex() + 1)
            }
          	// If this is last real token, collect all hidden to right
            let buf = StringBuilder()
            if nextReal!.getType() == CommonToken.EOF {
                hiddenRight = try? tokens.getText(right![0], nextReal)
            }
            else {
                // collect all token text on same line to right
                let tokenLine = symbol.getLine()
                for t in right! {
                    if t.getLine() == tokenLine {
                        buf.append(t.getText()!)
                    }
                }
                hiddenRight = buf.toString()
            }
        }
    }
    
	public func getHiddenLeft() -> String? {
        return hiddenLeft
    }
    
    public func getHiddenRight() -> String? {
        return hiddenRight
    }
    
    public func setHiddenLeft(_ hiddenLeft: String) {
        self.hiddenLeft = hiddenLeft
    }
   
    public func setHiddenRight(_ hiddenRight: String) {
        self.hiddenRight = hiddenRight
    }
    
	override public func getText() -> String {
        let buf = StringBuilder()
        if hiddenLeft != nil {
            buf.append(hiddenLeft!)
        }
        buf.append(super.getText())
        if hiddenRight != nil {
            buf.append(hiddenRight!)
        }
        return buf.toString();
    }
}
