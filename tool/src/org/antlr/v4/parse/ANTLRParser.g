/*
 [The "BSD license"]
 Copyright (c) 2010 Jim Idle, Terence Parr
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.
 3. The name of the author may not be used to endorse or promote products
    derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/** The definitive ANTLR v3 grammar to parse ANTLR v4 grammars.
 *  The grammar builds ASTs that are sniffed by subsequent stages.
 */
parser grammar ANTLRParser;

options {
	// Target language is Java, which is the default but being specific
	// here as this grammar is also meant as a good example grammar for
	// for users.
	language      = Java;
	
	// The output of this grammar is going to be an AST upon which
	// we run a semantic checking phase, then the rest of the analysis
	// including final code generation.
	output        = AST;
	
	// The vocabulary (tokens and their int token types) we are using 
	// for the parser. This is generated by the lexer. The vocab will be extended
	// to include the imaginary tokens below.
	tokenVocab    = ANTLRLexer;

	ASTLabelType  = GrammarAST;
}

// Imaginary Tokens
//
// Imaginary tokens do not exist as far as the lexer is concerned, and it cannot
// generate them. However we sometimes need additional 'tokens' to use as root
// nodes for the AST we are generating. The tokens section is where we
// specify any such tokens 
tokens {		
    LEXER;
    RULE;
    RULES;
    RULEMODIFIERS;
    RULEACTIONS;
    BLOCK;
    REWRITE_BLOCK;
    OPTIONAL;
    CLOSURE;
    POSITIVE_CLOSURE;
    SYNPRED;
    RANGE;
    CHAR_RANGE;
    EPSILON;
    ALT;
    ALTLIST;
    RESULT;  
    ID;
    ARG;
    ARGLIST;
    RET;
    //LEXER_GRAMMAR;
 //   PARSER_GRAMMAR;
//    TREE_GRAMMAR;
//    COMBINED_GRAMMAR;
    INITACTION;
    LABEL;                // $x used in rewrite rules
    TEMPLATE;
    GATED_SEMPRED;        // {p}? =>
    SYN_SEMPRED;          // (...) =>   it's a manually-specified synpred converted to sempred
    BACKTRACK_SEMPRED;    // auto backtracking mode syn pred converted to sempred
    DOT;
    // A generic node indicating a list of something when we don't
    // really need to distinguish what we have a list of as the AST
    // will 'kinow' by context.
    //
    LIST;
    ELEMENT_OPTIONS;      // TOKEN<options>
    ST_RESULT;			  // distinguish between ST and tree rewrites
    RESULT;
    ALT_REWRITE;		  // indicate ALT is rewritten
}

// Include the copyright in this source and also the generated source
//
@header {
/*
 [The "BSD licence"]
 Copyright (c) 2005-2009 Terence Parr
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.
 3. The name of the author may not be used to endorse or promote products
    derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
package org.antlr.v4.parse;

import org.antlr.v4.tool.*;
}

// The main entry point for parsing a V3 grammar from top to toe. This is
// the method call from whence to obtain the AST for the parse.
//
grammarSpec
    : 
      // The grammar itself can have a documenation comment, which is the
      // first terminal in the file.
      //
      DOC_COMMENT?
      
      // Next we should see the type and name of the grammar file that
      // we are about to parse.
      //
      grammarType id SEMI
      
      // There now follows zero or more declaration sections that should
      // be given to us before the rules are declared
      //
// A number of things can be declared/stated before the grammar rules
// 'proper' are parsed. These include grammar imports (delegate), grammar
// options, imaginary token declarations, global scope declarations,
// and actions such as @header. In this rule we allow any number of
// these constructs in any order so that the grammar author is not
// constrained by some arbitrary order of declarations that nobody
// can remember. In the next phase of the parse, we verify that these
// constructs are valid, not repeated and so on.
      prequelConstruct*
	    
	  // We should now see at least one ANTLR EBNF style rule
	  // declaration. If the rules are missing we will let the
	  // semantic verification phase tell the user about it.
	  //  
	  rules
      
      // And we force ANTLR to process everything it finds in the input
      // stream by specifying hte need to match End Of File before the
      // parse is complete.
      //
      EOF

      // Having parsed everything in the file and accumulated the relevant
      // subtrees, we can now rewrite everything into the main AST form
      // that our tree walkers are expecting.
      //
      
      -> ^(grammarType       // The grammar type is our root AST node
             id              // We need to identify the grammar of course  
             DOC_COMMENT?    // We may or may not have a global documentation comment for the file
             prequelConstruct* // The set of declarations we accumulated
             rules           // And of course, we need the set of rules we discovered
         )
	;
	

// ------------
// Grammar Type
//
// ANTLR will process a combined lexer/grammar, a stand alone parser,
// a stand alone lexer, and tree grammars. This rule determines which of
// these the gramamr author is asking us to deal with. This choice will
// later allow us to throw out valid syntactical constructs that are
// not valid for certain grammar types, such as rule parameters and
// returns specified for lexer rules.
//
/*
grammarType
    : (	  // A standalone lexer specification
          LEXER GRAMMAR  -> LEXER_GRAMMAR<GrammarRootAST>[$LEXER, "LEXER_GRAMMAR"]
          
        | // A standalone parser specification
          PARSER GRAMMAR -> PARSER_GRAMMAR<GrammarRootAST>[$PARSER, "PARSER_GRAMMAR"]
          
        | // A standalone tree parser specification
          TREE GRAMMAR   -> TREE_GRAMMAR<GrammarRootAST>[$TREE, "TREE_GRAMMAR"]
          
        // A combined lexer and parser specification
        | g=GRAMMAR        -> COMBINED_GRAMMAR<GrammarRootAST>[$g, "COMBINED_GRAMMAR"]
                  
       )
    ;
    */
grammarType
@after {
	if ( $t!=null ) ((GrammarRootAST)$tree).grammarType = $t.type;
	else ((GrammarRootAST)$tree).grammarType=GRAMMAR;
}
    :	(	t=LEXER g=GRAMMAR  -> GRAMMAR<GrammarRootAST>[$g, "LEXER_GRAMMAR"]          
		| // A standalone parser specification
		  	t=PARSER g=GRAMMAR -> GRAMMAR<GrammarRootAST>[$g, "PARSER_GRAMMAR"]
		  
		| // A standalone tree parser specification
		  	t=TREE g=GRAMMAR   -> GRAMMAR<GrammarRootAST>[$g, "TREE_GRAMMAR"]
		  
		// A combined lexer and parser specification
		| 	g=GRAMMAR          -> GRAMMAR<GrammarRootAST>[$g, "COMBINED_GRAMMAR"]                  
		)
    ;
    
// This is the list of all constructs that can be declared before
// the set of rules that compose the grammar, and is invoked 0..n
// times by the grammarPrequel rule.
prequelConstruct
	: // A list of options that affect analysis and/or code generation
	  optionsSpec
	  
    | // A list of grammars to which this grammar will delegate certain
      // parts of the parsing sequence - a set of imported grammars
      delegateGrammars
      
    | // The declaration of any token types we need that are not already
      // specified by a preceeding grammar, such as when a parser declares
      // imaginary tokens with which to construct the AST, or a rewriting
      // tree parser adds further imaginary tokens to ones defined in a prior
      // {tree} parser.
      tokensSpec
      
    | // A declaration of a scope that may be used in multiple rules within
      // the grammar spec, rather than being delcared and therefore associated
      // with, a specific rule.
      attrScope
      
    | // A declaration of language target implemented constructs. All such
      // action sections start with '@' and are given to the language target's
      // StringTemplate group. For instance @parser::header and @lexer::header
      // are gathered here.
      action  
    ;

// A list of options that affect analysis and/or code generation
optionsSpec
	:	OPTIONS (option SEMI)* RBRACE -> ^(OPTIONS[$OPTIONS, "OPTIONS"] option+)
    ;
        
option
    :   id ASSIGN^ optionValue
    ;

// ------------
// Option Value
//
// The actual value of an option - Doh!
//
optionValue
    : // If the option value is a single word that conforms to the
      // lexical rules of token or rule names, then the user may skip quotes
      // and so on. Many option values meet this description
      //
      qid
 
    | // The value is a long string
      //
      STRING_LITERAL<TerminalAST>

    | // The value was an integer number
      //
      INT
      
    | // Asterisk, used for things like k=*
      //
      STAR
    ;

// A list of grammars to which this grammar will delegate certain
// parts of the parsing sequence - a set of imported grammars
delegateGrammars
	: IMPORT delegateGrammar (COMMA delegateGrammar)* SEMI -> ^(IMPORT delegateGrammar+)
	;

// A possibly named grammar file that should be imported to this gramamr
// and delgated to for the rules it specifies
delegateGrammar
    :   id ASSIGN^ id
    |   id
    ;

/** The declaration of any token types we need that are not already
 *  specified by a preceeding grammar, such as when a parser declares
 *  imaginary tokens with which to construct the AST, or a rewriting
 *  tree parser adds further imaginary tokens to ones defined in a prior
 *  {tree} parser.
 */
tokensSpec
	: TOKENS tokenSpec+ RBRACE -> ^(TOKENS tokenSpec+)
	;

tokenSpec
	:	id
		(	ASSIGN STRING_LITERAL	-> ^(ASSIGN id STRING_LITERAL<TerminalAST>)
		|							-> id
		)
		SEMI
	|	RULE_REF // INVALID! (an error alt)
	;

// A declaration of a scope that may be used in multiple rules within
// the grammar spec, rather than being declared within and therefore associated
// with, a specific rule.
attrScope
	:	SCOPE id ACTION -> ^(SCOPE id ACTION)
	;

// A declaration of a language target specifc section,
// such as @header, @includes and so on. We do not verify these
// sections, they are just passed on to the language target.
/** Match stuff like @parser::members {int i;} */
action
	:	AT (actionScopeName COLONCOLON)? id ACTION -> ^(AT actionScopeName? id ACTION)
	;
  
/** Sometimes the scope names will collide with keywords; allow them as
 *  ids for action scopes.
 */
actionScopeName
	:	id
	|	LEXER	-> ID[$LEXER]
    |   PARSER	-> ID[$PARSER]
	;

rules
    : rule*      
      // Rewrite with an enclosing node as this is good for counting
      // the number of rules and an easy marker for the walker to detect
      // that there are no rules.
      ->^(RULES rule*)
    ;    

// The specification of an EBNF rule in ANTLR style, with all the
// rule level parameters, declarations, actions, rewrite specs and so
// on.
//
// Note that here we allow any number of rule declaration sections (such
// as scope, returns, etc) in any order and we let the upcoming semantic
// verification of the AST determine if things are repeated or if a 
// particular functional element is not valid in the context of the
// grammar type, such as using returns in lexer rules and so on.
rule
    : // A rule may start with an optional documentation comment
      DOC_COMMENT?
      
      // Following the documentation, we can declare a rule to be
      // public, private and so on. This is only valid for some
      // language targets of course but the target will ignore these
      // modifiers if they make no sense in that language.
      ruleModifiers?

	  // Next comes the rule name. Here we do not distinguish between
	  // parser or lexer rules, the semantic verification phase will
	  // reject any rules that make no sense, such as lexer rules in
	  // a pure parser or tree parser.
	  id
	  
	  // Immediately following the rulename, there may be a specification
	  // of input parameters for the rule. We do not do anything with the
	  // parameters here except gather them for future phases such as
	  // semantic verifcation, type assignment etc. We require that
	  // the input parameters are the next syntactically significant element
	  // following the rule id.
	  ARG_ACTION?
	  
	  ruleReturns?

	  // Now, before the rule specification itself, which is introduced
	  // with a COLON, we may have zero or more configuration sections.
	  // As usual we just accept anything that is syntactically valid for
	  // one form of the rule or another and let the semantic verification
	  // phase throw out anything that is invalid.
// At the rule level, a programmer may specify a number of sections, such
// as scope declarations, rule return elements, @ sections (which may be
// language target specific) and so on. We allow any number of these in any
// order here and as usual rely onthe semantic verification phase to reject
// anything invalid using its addinotal context information. Here we are 
// context free and just accept anything that is a syntactically correct
// construct.
//
      rulePrequel*
      
      COLON
      
      // The rule is, at the top level, just a list of alts, with
      // finer grained structure defined within the alts.
      altListAsBlock
      
      SEMI

      exceptionGroup
            
      -> ^( RULE<RuleAST> id DOC_COMMENT? ruleModifiers? ARG_ACTION?
      		ruleReturns? rulePrequel* altListAsBlock exceptionGroup*
      	  )
    ;

// Many language targets support exceptions and the rule will
// generally be able to throw the language target equivalent 
// of a recognition exception. The grammar programmar can 
// specify a list of exceptions to catch or a generic catch all
// and the target language code generation template is
// responsible for generating code that makes sense.
exceptionGroup
    : exceptionHandler* finallyClause?
    ;

// Specifies a handler for a particular type of exception
// thrown by a rule
exceptionHandler
	: CATCH ARG_ACTION ACTION -> ^(CATCH ARG_ACTION ACTION)
	;

// Specifies a block of code to run after the rule and any
// expcetion blocks have exceuted.
finallyClause
	: FINALLY ACTION -> ^(FINALLY ACTION)
	;
  
// An individual rule level configuration as referenced by the ruleActions
// rule above.
//
rulePrequel
    : throwsSpec
    | ruleScopeSpec
    | optionsSpec
    | ruleAction
    ;

// A rule can return elements that it constructs as it executes.
// The return values are specified in a 'returns' prequel element,
// which contains COMMA separated declarations, where the declaration
// is target language specific. Here we see the returns declaration
// as a single lexical action element, to be processed later.
//
ruleReturns
	: RETURNS^ ARG_ACTION
	;

// --------------
// Exception spec
//
// Some target languages, such as Java and C# support exceptions
// and they are specified as a prequel element for each rule that
// wishes to throw its own exception type. Note that the name of the
// exception is just a single word, so the header section of the grammar
// must specify the correct import statements (or language equivalent).
// Target languages that do not support exceptions just safely ignore
// them.
//
throwsSpec
    : THROWS qid (COMMA qid)* -> ^(THROWS qid+)
    ;
  
// As well as supporting globally specifed scopes, ANTLR supports rule
// level scopes, which are tracked in a rule specific stack. Rule specific 
// scopes are specified at this level, and globally specified scopes 
// are merely referenced here.
ruleScopeSpec
	:	SCOPE ACTION -> ^(SCOPE ACTION)
	|	SCOPE id (COMMA id)* SEMI -> ^(SCOPE id+)
	;

// @ Sections are generally target language specific things
// such as local variable declarations, code to run before the
// rule starts and so on. Fir instance most targets support the
// @init {} section where declarations and code can be placed
// to run before the rule is entered. The C target also has
// an @declarations {} section, where local variables are declared
// in order that the generated code is C89 copmliant.
//
/** Match stuff like @init {int i;} */
ruleAction
	:	AT id ACTION -> ^(AT id ACTION)
	;
         
// A set of access modifiers that may be applied to rule declarations
// and which may or may not mean something to the target language.
// Note that the parser allows any number of these in any order and the
// semantic pass will throw out invalid combinations.
//
ruleModifiers
    : ruleModifier+ -> ^(RULEMODIFIERS ruleModifier+)
    ;
  
// An individual access modifier for a rule. The 'fragment' modifier
// is an internal indication for lexer rules that they do not match
// from the input but are like subroutines for other lexer rules to
// reuse for certain lexical patterns. The other modifiers are passed
// to the code generation templates and may be ignored by the template
// if they are of no use in that language.
ruleModifier
    : PUBLIC
    | PRIVATE
    | PROTECTED
    | FRAGMENT
    ;

altList
    : alternative (OR alternative)* -> alternative+
    ;

// A set of alts, rewritten as a BLOCK for generic processing
// in tree walkers. Used by the rule 'rule' so that the list of
// alts for a rule appears as a BLOCK containing the alts and
// can be processed by the generic BLOCK rule. Note that we
// use a separate rule so that the BLOCK node has start and stop
// boundaries set correctly by rule post processing of rewrites.
altListAsBlock
    : altList -> ^(BLOCK<BlockAST> altList)
    ;

// An individual alt with an optional rewrite clause for the
// elements of the alt.
alternative
    :	elements
    	(	rewrite -> ^(ALT_REWRITE elements rewrite)
    	|			-> elements
    	)
    |	rewrite		-> ^(ALT_REWRITE ^(ALT EPSILON) rewrite) // empty alt with rewrite
    |				-> ^(ALT EPSILON) // empty alt
    ;

elements
    : e+=element+ -> ^(ALT $e+)
    ;
  
element
	:	labeledElement
		(	ebnfSuffix	-> ^( ebnfSuffix ^(BLOCK<BlockAST> ^(ALT labeledElement ) ))
		|				-> labeledElement
		)
	|	atom
		(	ebnfSuffix	-> ^( ebnfSuffix ^(BLOCK<BlockAST> ^(ALT atom ) ) )
		|				-> atom
		)
	|	ebnf
	|   ACTION
	|   SEMPRED
		(	IMPLIES		-> GATED_SEMPRED[$IMPLIES]
		|				-> SEMPRED
		)
	|   treeSpec
		(	ebnfSuffix	-> ^( ebnfSuffix ^(BLOCK<BlockAST> ^(ALT treeSpec ) ) )
		|				-> treeSpec
		)
	;
	
labeledElement : id (ASSIGN^|PLUS_ASSIGN^) (atom|block) ;
    
// Tree specifying alt
// Tree grammars need to have alts that describe a tree structure they
// will walk of course. Alts for trees therefore start with ^( XXX, which 
// says we will see a root node of XXX then DOWN etc
treeSpec
    : TREE_BEGIN
         // Only a subset of elements are allowed to be a root node. However
         // we allow any element to appear here and reject silly ones later
         // when we walk the AST.
         element
         // After the tree root we get the usual suspects, 
         // all members of the element set
         element+
      RPAREN
      -> ^(TREE_BEGIN element+)
    ;

// A block of gramamr structure optionally followed by standard EBNF
// notation, or ANTLR specific notation. I.E. ? + ^ and so on
ebnf
    : block    
      // And now we see if we have any of the optional suffixs and rewrite
      // the AST for this rule accordingly
      //
      (	blockSuffixe	-> ^(blockSuffixe block)
      |					-> block
      )
    ;

// The standard EBNF suffixes with additional components that make
// sense only to ANTLR, in the context of a grammar block.
blockSuffixe
    : ebnfSuffix // Standard EBNF

	  // ANTLR Specific Suffixes      
    | ROOT
    | IMPLIES   // We will change this to syn/sem pred in the next phase
    | BANG
    ;

ebnfSuffix
@init {
	Token op = input.LT(1);
}
	:	QUESTION	-> OPTIONAL[op]
  	|	STAR 		-> CLOSURE[op]
   	|	PLUS	 	-> POSITIVE_CLOSURE[op]
	;
	
atom:	range (ROOT^ | BANG^)? // Range x..y - only valid in lexers
      
	|	// Qualified reference delegate.rule. This must be
	    // lexically contiguous (no spaces either side of the DOT)
	    // otherwise it is two references with a wildcard in between
	    // and not a qualified reference.
	    {
	    	input.LT(1).getCharPositionInLine()+input.LT(1).getText().length()==
	        input.LT(2).getCharPositionInLine() &&
	        input.LT(2).getCharPositionInLine()+1==input.LT(3).getCharPositionInLine()
	    }?
	    id WILDCARD ruleref 
	    -> ^(DOT[$WILDCARD] id ruleref)
	|	// Qualified reference delegate.token.
	    {
	    	input.LT(1).getCharPositionInLine()+input.LT(1).getText().length()==
	        input.LT(2).getCharPositionInLine() &&
	        input.LT(2).getCharPositionInLine()+1==input.LT(3).getCharPositionInLine()
	    }?
	    id WILDCARD terminal
	    -> ^(DOT[$WILDCARD] id terminal)
    |   terminal
    |   ruleref
    |	notSet (ROOT^|BANG^)?
    ;
  

   
// --------------------  
// Inverted element set
//
// A set of characters (in a lexer) or terminal tokens, if a parser
// that are then used to create the inverse set of them.
//
notSet
    : NOT notTerminal	-> ^(NOT notTerminal)
    | NOT block			-> ^(NOT block)
    ;
   
// ------------------- 
// Valid set terminals
//
// The terminal tokens that can be members of an inverse set (for
// matching anything BUT these)
//
notTerminal
    : TOKEN_REF<TerminalAST>
    | STRING_LITERAL<TerminalAST>
    ;

// -------------
// Grammar Block
//
// Anywhere where an element is valid, the grammar may start a new block
// of alts by surrounding that block with ( ). A new block may also have a set
// of options, which apply only to that block.
//
block
    : LPAREN
    
         // A new blocked altlist may have a set of options set sepcifically
         // for it.
         //
         optionsSpec?
         
         (
             // Optional @ sections OR an action, however we allow both
             // to be present and will let the semantic checking phase determine
             // what is allowable.
             //
             ra+=ruleAction*
             ACTION?
         
            // COLON is optional with a block
            //
            COLON
         )?
         
         // List of alts for this Paren block
         //
         altList
         
      RPAREN
      
      // Rewrite as a block
      //
      -> ^(BLOCK<BlockAST> optionsSpec? $ra* ACTION? altList )
    ; 

// ----------------    
// Parser rule ref
//
// Reference to a parser rule with optional arguments and optional
// directive to become the root node or ignore the tree produced
//
ruleref
    :	RULE_REF ARG_ACTION?
		(	(op=ROOT|op=BANG)	-> ^($op RULE_REF ARG_ACTION?)
		|						-> ^(RULE_REF ARG_ACTION?)
		)
    ;
  
// ---------------  
// Character Range
//
// Specifies a range of characters. Valid for lexer rules only, but
// we do not check that here, the tree walkers shoudl do that.
// Note also that the parser also allows through more than just
// character literals so that we can produce a much nicer semantic
// error about any abuse of the .. operator.
//
range
    : rangeElement RANGE^ rangeElement
    ;

// -----------------
// Atoms for a range
//  
// All the things that we are going to allow syntactically as the subject of a range
// operator. We do not want to restrict this just to STRING_LITERAL as then
// we will issue a syntax error that is perhaps none too obvious, even though we
// say 'expecting STRING_LITERAL'. Instead we will check these semantically
//
rangeElement
    : STRING_LITERAL<TerminalAST>
    | RULE_REF        // Invalid
    | TOKEN_REF<TerminalAST>       // Invalid
    ;
    
terminal
    :   (	// Args are only valid for lexer rules
		    TOKEN_REF ARG_ACTION? elementOptions? -> ^(TOKEN_REF<TerminalAST> ARG_ACTION? elementOptions?)
		|   STRING_LITERAL elementOptions?		  -> ^(STRING_LITERAL<TerminalAST> elementOptions?)
		|   // Wildcard '.' means any character in a lexer, any
			// token in parser and any token or node in a tree parser
			// Because the terminal rule is allowed to be the node
			// specification for the start of a tree rule, we must
			// later check that wildcard was not used for that.
		    DOT elementOptions?		 			  -> ^(WILDCARD<TerminalAST>[$DOT] elementOptions?)
		)
		(	ROOT								  -> ^(ROOT $terminal)
		|	BANG								  -> ^(BANG $terminal)
		)?
	;

 // --------------- 
 // Generic options
 //
 // Terminals may be adorned with certain options when
 // reference in the grammar: TOK<,,,>
 //
 elementOptions
    : // Options begin with < and end with >
      //
      LT elementOption (COMMA elementOption)* GT -> ^(ELEMENT_OPTIONS elementOption+)
    ;

// WHen used with elements we can specify what the tree node type can
// be and also assign settings of various options  (which we do not check here)
elementOption
    : // This format indicates the default node option
      qid
      
    | // This format indicates option assignment
      id ASSIGN^ (qid | STRING_LITERAL<TerminalAST>)
    ;

rewrite
	:	predicatedRewrite* nakedRewrite -> predicatedRewrite* nakedRewrite
	;

predicatedRewrite
	:	RARROW SEMPRED rewriteAlt
		-> {$rewriteAlt.isTemplate}? ^(ST_RESULT[$RARROW] SEMPRED rewriteAlt)
		-> ^(RESULT[$RARROW] SEMPRED rewriteAlt)
	;
	
nakedRewrite
	:	RARROW rewriteAlt -> {$rewriteAlt.isTemplate}? ^(ST_RESULT[$RARROW] rewriteAlt)
	 					  -> ^(RESULT[$RARROW] rewriteAlt)
	;
	
// distinguish between ST and tree rewrites; for ETC/EPSILON and trees,
// rule altAndRewrite makes REWRITE root. for ST, we use ST_REWRITE
rewriteAlt returns [boolean isTemplate]
options {backtrack=true;}
    : // try to parse a template rewrite
      rewriteTemplate {$isTemplate=true;}

    | // If we are not building templates, then we must be 
      // building ASTs or have rewrites in a grammar that does not
      // have output=AST; options. If that is the case, we will issue
      // errors/warnings in the next phase, so we just eat them here
      rewriteTreeAlt
      
    | ETC

    | /* empty rewrite */ -> EPSILON
    ;
	
rewriteTreeAlt
    :	rewriteTreeElement+ -> ^(ALT rewriteTreeElement+)
    ;

rewriteTreeElement
	:	rewriteTreeAtom
	|	rewriteTreeAtom ebnfSuffix
		-> ^( ebnfSuffix ^(REWRITE_BLOCK ^(ALT rewriteTreeAtom)) )
	|   rewriteTree
		(	ebnfSuffix
			-> ^(ebnfSuffix ^(REWRITE_BLOCK ^(ALT rewriteTree)) )
		|	-> rewriteTree
		)
	|   rewriteTreeEbnf
	;

rewriteTreeAtom
    :   TOKEN_REF ARG_ACTION? -> ^(TOKEN_REF<TerminalAST> ARG_ACTION?) // for imaginary nodes
    |   RULE_REF
	|   STRING_LITERAL<TerminalAST>
	|   DOLLAR id -> LABEL[$DOLLAR,$id.text] // reference to a label in a rewrite rule
	|	ACTION
	;

rewriteTreeEbnf
@init {
    Token firstToken = input.LT(1);
}
@after {
	$rewriteTreeEbnf.tree.getToken().setLine(firstToken.getLine());
	$rewriteTreeEbnf.tree.getToken().setCharPositionInLine(firstToken.getCharPositionInLine());
}
	:	lp=LPAREN rewriteTreeAlt RPAREN ebnfSuffix -> ^(ebnfSuffix ^(REWRITE_BLOCK[$lp] rewriteTreeAlt))
	;

rewriteTree
	:	TREE_BEGIN rewriteTreeAtom rewriteTreeElement* RPAREN
		-> ^(TREE_BEGIN rewriteTreeAtom rewriteTreeElement* )
	;

/** Build a tree for a template rewrite:
      ^(TEMPLATE (ID|ACTION) ^(ARGLIST ^(ARG ID ACTION) ...) )
    ID can be "template" keyword.  If first child is ACTION then it's
    an indirect template ref

    -> foo(a={...}, b={...})
    -> ({string-e})(a={...}, b={...})  // e evaluates to template name
    -> {%{$ID.text}} // create literal template from string (done in ActionTranslator)
	-> {st-expr} // st-expr evaluates to ST
 */
rewriteTemplate
	:   // -> template(a={...},...) "..."    inline template
		TEMPLATE LPAREN rewriteTemplateArgs RPAREN
		( str=DOUBLE_QUOTE_STRING_LITERAL | str=DOUBLE_ANGLE_STRING_LITERAL )
		-> ^(TEMPLATE[$TEMPLATE,"TEMPLATE"] rewriteTemplateArgs? $str)

	|	// -> foo(a={...}, ...)
		rewriteTemplateRef

	|	// -> ({expr})(a={...}, ...)
		rewriteIndirectTemplateHead

	|	// -> {...}
		ACTION
	;

/** -> foo(a={...}, ...) */
rewriteTemplateRef
	:	id LPAREN rewriteTemplateArgs RPAREN
		-> ^(TEMPLATE[$LPAREN,"TEMPLATE"] id rewriteTemplateArgs?)
	;

/** -> ({expr})(a={...}, ...) */
rewriteIndirectTemplateHead
	:	lp=LPAREN ACTION RPAREN LPAREN rewriteTemplateArgs RPAREN
		-> ^(TEMPLATE[$lp,"TEMPLATE"] ACTION rewriteTemplateArgs?)
	;

rewriteTemplateArgs
	:	rewriteTemplateArg (COMMA rewriteTemplateArg)*
		-> ^(ARGLIST rewriteTemplateArg+)
	|
	;

rewriteTemplateArg
	:   id ASSIGN ACTION -> ^(ARG[$ASSIGN] id ACTION)
	;

// The name of the grammar, and indeed some other grammar elements may
// come through to the parser looking like a rule reference or a token
// reference, hence this rule is used to pick up whichever it is and rewrite
// it as a generic ID token.
id
    : RULE_REF  ->ID[$RULE_REF]
    | TOKEN_REF ->ID[$TOKEN_REF]
    | TEMPLATE  ->ID[$TEMPLATE] // keyword
    ;
    
qid :	id (WILDCARD id)* -> ID[$qid.start, $text] ;

alternativeEntry : alternative EOF ; // allow gunit to call alternative and see EOF afterwards
elementEntry : element EOF ;
ruleEntry : rule EOF ;
blockEntry : block EOF ;
