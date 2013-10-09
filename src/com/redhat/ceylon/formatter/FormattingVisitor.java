package com.redhat.ceylon.formatter;

import java.io.Writer;

import org.antlr.runtime.TokenStream;

import com.redhat.ceylon.compiler.typechecker.tree.NaturalVisitor;
import com.redhat.ceylon.compiler.typechecker.tree.Visitor;

public class FormattingVisitor extends Visitor implements NaturalVisitor {

	private final TokenStream	tokens;
	private final Writer		out;

	public FormattingVisitor(TokenStream tokens, Writer output) {
		this.tokens = tokens;
		this.out = output;
	}
}
