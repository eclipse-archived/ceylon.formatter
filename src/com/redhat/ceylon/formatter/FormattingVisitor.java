package com.redhat.ceylon.formatter;

import java.io.IOException;
import java.io.Writer;
import java.util.List;

import org.antlr.runtime.Token;
import org.antlr.runtime.TokenStream;

import com.redhat.ceylon.compiler.typechecker.parser.CeylonLexer;
import com.redhat.ceylon.compiler.typechecker.tree.NaturalVisitor;
import com.redhat.ceylon.compiler.typechecker.tree.Node;
import com.redhat.ceylon.compiler.typechecker.tree.Tree.AnyMethod;
import com.redhat.ceylon.compiler.typechecker.tree.Tree.Block;
import com.redhat.ceylon.compiler.typechecker.tree.Tree.Identifier;
import com.redhat.ceylon.compiler.typechecker.tree.Tree.InvocationExpression;
import com.redhat.ceylon.compiler.typechecker.tree.Tree.Literal;
import com.redhat.ceylon.compiler.typechecker.tree.Tree.MethodDeclaration;
import com.redhat.ceylon.compiler.typechecker.tree.Tree.MethodDefinition;
import com.redhat.ceylon.compiler.typechecker.tree.Tree.Parameter;
import com.redhat.ceylon.compiler.typechecker.tree.Tree.ParameterList;
import com.redhat.ceylon.compiler.typechecker.tree.Tree.PositionalArgument;
import com.redhat.ceylon.compiler.typechecker.tree.Tree.PositionalArgumentList;
import com.redhat.ceylon.compiler.typechecker.tree.Tree.Statement;
import com.redhat.ceylon.compiler.typechecker.tree.Tree.TypedDeclaration;
import com.redhat.ceylon.compiler.typechecker.tree.Tree.VoidModifier;
import com.redhat.ceylon.compiler.typechecker.tree.Visitor;

public class FormattingVisitor extends Visitor implements NaturalVisitor {

	private final TokenStream	tokens;
	private final Writer		out;

	private boolean				needsWhitespace	= false;	// new tokens (especially identifiers) don't need to write a
															// leading space if the last token ends with a whitespace,
															// parenthesis, etc.
	private String				indent			= "";

	public FormattingVisitor(TokenStream tokens, Writer output) {
		this.tokens = tokens;
		this.out = output;

		// initialize TokenStream
		tokens.LA(1);
	}

	@Override
	public void visit(AnyMethod that) {
		// override the default Walker's order
		if (that.getAnnotationList() != null)
			that.getAnnotationList().visit(this);
		if (that.getType() != null)
			that.getType().visit(this);
		that.getIdentifier().visit(this);
		if (that.getTypeParameterList() != null)
			that.getTypeParameterList().visit(this);
		for (ParameterList list : that.getParameterLists()) {
			list.visit(this);
		}
		if (that.getTypeConstraintList() != null)
			that.getTypeConstraintList().visit(this);
	}

	@Override
	public void visit(MethodDeclaration that) {
		visit((AnyMethod) that);
		if (that.getSpecifierExpression() != null)
			that.getSpecifierExpression().visit(this);
	}

	@Override
	public void visit(MethodDefinition that) {
		visit((AnyMethod) that);
		that.getBlock().visit(this);
	}

	@Override
	public void visit(TypedDeclaration that) {
		that.getType().visit(this);
		that.getIdentifier().visit(this);
	}

	@Override
	public void visit(VoidModifier that) {
		try {
			if (needsWhitespace)
				out.write(" ");
			writeOut(that.getMainToken()); // "void"
			needsWhitespace = true;
		}
		catch (IOException e) {
			this.handleException(e, that);
		}
	}

	@Override
	public void visit(Identifier that) {
		try {
			if (needsWhitespace)
				out.write(" ");
			writeOut(that.getMainToken());
			needsWhitespace = true;
		}
		catch (IOException e) {
			this.handleException(e, that);
		}
	}

	@Override
	public void visit(ParameterList that) {
		try {
			writeOut(that.getMainToken()); // "("
			needsWhitespace = false;
			List<Parameter> parameters = that.getParameters();
			int i = 0;
			int size = parameters.size();
			if (size >= 1) {
				parameters.get(i).visit(this);
				while (++i < size) {
					out.write(", ");
					needsWhitespace = false;
					parameters.get(i).visit(this);
				}
			}
			writeOut(that.getMainEndToken()); // ")"
			needsWhitespace = true; // doesn't "need", but looks prettier - obviously, this model won't be kept
		}
		catch (IOException e) {
			this.handleException(e, that);
		}
	}

	@Override
	public void visit(Block that) {
		try {
			if (needsWhitespace)
				out.write(" "); // doesn't "need", but looks prettier
			writeOut(that.getMainToken()); // "{"
			nextLine();
			indent += "\t";
			for (Statement statement : that.getStatements()) {
				out.write(indent);
				needsWhitespace = false;
				statement.visit(this);
				nextLine();
			}
			indent = indent.substring(0, indent.length() - 1);
			out.write(indent);
			writeOut(that.getMainEndToken()); // "}"
			needsWhitespace = true; // again, doesn't strictly "need"
			nextLine();
		}
		catch (IOException e) {
			this.handleException(e, that);
		}
	}

	@Override
	public void visit(Statement that) {
		that.visitChildren(this);
		writeOut(that.getMainEndToken()); // ";"
	}

	@Override
	public void visit(InvocationExpression that) {
		that.getPrimary().visit(this);
		if (that.getPositionalArgumentList() != null)
			that.getPositionalArgumentList().visit(this);
		else if (that.getNamedArgumentList() != null)
			that.getNamedArgumentList().visit(this);
	}

	@Override
	public void visit(PositionalArgumentList that) {
		try {
			writeOut(that.getMainToken()); // "("
			needsWhitespace = false;
			List<PositionalArgument> arguments = that.getPositionalArguments();
			int i = 0;
			int size = arguments.size();
			if (size >= 1) {
				arguments.get(i).visit(this);
				while (++i < size) {
					out.write(", ");
					needsWhitespace = false;
					arguments.get(i).visit(this);
				}
			}
			writeOut(that.getMainEndToken()); // ")"
		}
		catch (IOException e) {
			this.handleException(e, that);
		}
	}

	@Override
	public void visit(Literal that) {
		try {
			if (needsWhitespace)
				out.write(" ");
			writeOut(that.getMainToken());
			needsWhitespace = true;
			if (that.getMainEndToken() != null)
				throw new Error("Literal has end token! Investigate"); // breakpoint here
		}
		catch (IOException e) {
			this.handleException(e, that);
		}
	}

	// TODO eventually, this will be unneeded, as each visit(? extends Node) should be overwritten here.
	@Override
	public void visitAny(Node that) {
		Token t = that.getMainToken();
		if (t != null) {
			System.err.print(t.getText());
			if (that.getMainEndToken() != null)
				System.err.print("\t" + that.getMainEndToken().getText());
			System.err.println();
		}
		super.visitAny(that);
	}

	/**
	 * Fast-forward the token stream until the specified token is reached, writing out any comment tokens, then write
	 * the specified token.
	 * <p>
	 * This method should always be used to write any tokens.
	 * 
	 * @param token
	 *            The next token to write.
	 */
	public void writeOut(Token token) {
		try {
			for (int i = tokens.index(); i < token.getTokenIndex(); i++) {
				Token current = tokens.get(i);
				switch (current.getType()) {
					case CeylonLexer.LINE_COMMENT:
					case CeylonLexer.MULTI_COMMENT: {
						if (needsWhitespace)
							out.write(" ");
						out.write(current.getText());
						break;
					}
					case CeylonLexer.WS:
						break;
					default: {
						throw new Error("Unexpected token \"" + current.getText());
					}
				}
				tokens.consume();
				if (current.getType() == CeylonLexer.MULTI_COMMENT)
					nextLine();
			}
			out.write(token.getText());
			tokens.consume();
		}
		catch (IOException e) {
			this.handleException(e, null); // TODO add argument "that" to signature to be able to pass here?
		}
	}

	/**
	 * Fast-forward the token stream until the next token contains a line break or isn't hidden, writing out any comment
	 * tokens, then write a line break.
	 * <p>
	 * This is needed to keep a line comment at the end of a line instead of putting it into the next line.
	 */
	public void nextLine() {
		try {
			Token current;
			boolean wroteLastToken;
			loop: for (int i = tokens.index(); true; i++) { // condition comes later
				wroteLastToken = false;
				current = tokens.get(i);
				switch (current.getType()) {
					case CeylonLexer.LINE_COMMENT:
					case CeylonLexer.MULTI_COMMENT: {
						if (needsWhitespace)
							out.write(" ");
						out.write(current.getText());
						tokens.consume();
						wroteLastToken = true;
					}
					//$FALL-THROUGH$ intentional - LINE_COMMENTs contain the terminating line break
					case CeylonLexer.WS: {
						if (current.getText().contains("\n"))
							break loop;
						break;
					}
					default: {
						// This happens if there's no newline where one should be (e.g., two statements in one line,
						// closing brace after statement, etc.)
						break loop;
					}
				}
				tokens.consume();
			}
			if (!current.getText().endsWith("\n") || !wroteLastToken) // LINE_COMMENTs contain the terminating line
																		// break
				out.write("\n");
			needsWhitespace = false;
		}
		catch (IOException e) {
			this.handleException(e, null); // TODO add argument "that" to signature to be able to pass here?
		}
	}
}
