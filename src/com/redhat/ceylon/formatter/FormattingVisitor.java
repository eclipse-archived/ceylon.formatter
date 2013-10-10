package com.redhat.ceylon.formatter;

import java.io.IOException;
import java.io.Writer;
import java.util.List;

import org.antlr.runtime.Token;
import org.antlr.runtime.TokenStream;

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
			out.write(that.getMainToken().getText()); // "void"
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
			out.write(that.getMainToken().getText());
			needsWhitespace = true;
		}
		catch (IOException e) {
			this.handleException(e, that);
		}
	}

	@Override
	public void visit(ParameterList that) {
		try {
			out.write(that.getMainToken().getText()); // "("
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
			out.write(that.getMainEndToken().getText()); // ")"
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
			out.write(that.getMainToken().getText()); // "{"
			out.write("\n");
			indent += "\t";
			for (Statement statement : that.getStatements()) {
				out.write(indent);
				needsWhitespace = false;
				statement.visit(this);
				out.write("\n");
			}
			indent = indent.substring(0, indent.length() - 1);
			out.write(indent);
			out.write(that.getMainEndToken().getText()); // "}"
			out.write("\n");
			needsWhitespace = false;
		}
		catch (IOException e) {
			this.handleException(e, that);
		}
	}

	@Override
	public void visit(Statement that) {
		try {
			that.visitChildren(this);
			out.write(that.getMainEndToken().getText()); // ";"
		}
		catch (IOException e) {
			this.handleException(e, that);
		}
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
			out.write(that.getMainToken().getText()); // "("
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
			out.write(that.getMainEndToken().getText()); // ")"
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
			out.write(that.getText()); // "literal"
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
}
