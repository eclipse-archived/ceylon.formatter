package com.redhat.ceylon.formatter;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.Writer;

import org.antlr.runtime.ANTLRFileStream;
import org.antlr.runtime.BufferedTokenStream;
import org.antlr.runtime.CommonTokenStream;
import org.antlr.runtime.RecognitionException;

import com.redhat.ceylon.compiler.typechecker.parser.CeylonLexer;
import com.redhat.ceylon.compiler.typechecker.parser.CeylonParser;
import com.redhat.ceylon.compiler.typechecker.tree.Tree.CompilationUnit;

public class Main {
	public static void main(String[] args) {
		String fileName = "../ceylon-walkthrough/source/en/01basics.ceylon";
		Writer output = new OutputStreamWriter(System.out);
		if (args.length >= 1) {
			fileName = args[0];
			if (args.length >= 2)
				try {
					output = new FileWriter(new File(args[1]));
				}
				catch (IOException e) {
					System.err.println("Couldn't open output file \"" + args[1] + "\", using stdout instead");
					e.printStackTrace();
				}
		}
		try {
			CeylonLexer lexer = new CeylonLexer(new ANTLRFileStream(fileName));
			CompilationUnit cu = new CeylonParser(new CommonTokenStream(lexer)).compilationUnit();
			lexer.reset(); // FormattingVisitor needs to read the tokens again
			cu.visit(new FormattingVisitor(new BufferedTokenStream(lexer), // can't use CommonTokenStream, we don't want
																			// to skip comments
					output));
		}
		catch (IOException | RecognitionException e) {
			System.err.println("FATAL: Couldn't process file!");
			e.printStackTrace();
			System.exit(1);
		}
		finally {
			try {
				output.close();
			}
			catch (IOException e) {
				// oh come on
				e.printStackTrace();
			}
		}
	}
}
