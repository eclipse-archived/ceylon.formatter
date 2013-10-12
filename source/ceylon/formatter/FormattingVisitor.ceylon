import com.redhat.ceylon.compiler.typechecker.tree { Tree { ... }, Node, VisitorAdaptor }
import com.redhat.ceylon.compiler.typechecker.parser { CeylonLexer { lineComment=\iLINE_COMMENT, multiComment=\iMULTI_COMMENT, ws=\iWS } }
import org.antlr.runtime { TokenStream { la=\iLA }, Token }
import java.io { Writer }
import java.lang { Error, System { syserr=err }, Exception }
import ceylon.interop.java { CeylonIterable }

shared class FormattingVisitor(TokenStream tokens, Writer writer) extends VisitorAdaptor() {
    
    variable Boolean needsWhitespace = false;
    variable String indent = "";
    
    // initialize TokenStream
    tokens.la(1);
    
    shared actual void handleException(Exception? e, Node that) {
        // set breakpoint here
        if (exists e) {
            e.printStackTrace();
        }
    }
    
    shared actual void visitAnyMethod(AnyMethod that) {
        // override the default Walker's order
        that.annotationList.visit(this);
        that.type.visit(this);
        that.identifier.visit(this);
        if (exists TypeParameterList typeParams = that.typeParameterList) {
            typeParams.visit(this);
        }
        for (ParameterList list in CeylonIterable(that.parameterLists)) {
            list.visit(this);
        }
    }
    
    shared actual void visitMethodDeclaration(MethodDeclaration that) {
        visitAnyMethod(that);
        if (exists SpecifierExpression expr = that.specifierExpression) {
            expr.visit(this);
        }
    }
    
    shared actual void visitMethodDefinition(MethodDefinition that) {
        visitAnyMethod(that);
        that.block.visit(this);
    }
    
    shared actual void visitTypedDeclaration(TypedDeclaration that) {
        that.type.visit(this);
        that.identifier.visit(this);
    }
    
    shared actual void visitVoidModifier(VoidModifier that) {
        if (needsWhitespace) {
            writer.write(" ");
        }
        writeOut(that.mainToken);
        needsWhitespace = true;
    }
    
    shared actual void visitIdentifier(Identifier that) {
        if (needsWhitespace) {
            writer.write(" ");
        }
        writeOut(that.mainToken);
        needsWhitespace = true;
    }
    
    shared actual void visitParameterList(ParameterList that) {
        writeOut(that.mainToken); // "("
        needsWhitespace = false;
        variable Boolean hasFirst = false;
        for (Parameter parameter in CeylonIterable(that.parameters)) {
            if (hasFirst) {
                writer.write(", ");
                needsWhitespace = false;
            }
            parameter.visit(this);
            hasFirst = true;
        }
        writeOut(that.mainEndToken); // ")"
        needsWhitespace = true; // doesn't "need", but looks prettier - obviously, this model won't be kept
    }
    
    shared actual void visitBlock(Block that) {
        if (needsWhitespace) {
            writer.write(" "); // doesn't "need", but looks prettier
        }
        writeOut(that.mainToken); // "{"
        nextLine();
        indent += "\t";
        for (Statement statement in CeylonIterable(that.statements)) {
            writer.write(indent);
            needsWhitespace = false;
            statement.visit(this);
            nextLine();
        }
        // remove one character from indent
        variable Boolean b = true;
        indent = indent.trimTrailing(function(Character c) { if (b) { b = false; return true; } return false; });
        writer.write(indent);
        writeOut(that.mainEndToken); // "}"
        needsWhitespace = true; // again, doesn't strictly "need"
        nextLine();
    }
    
    shared actual void visitStatement(Statement that) {
        that.visitChildren(this);
        writeOut(that.mainEndToken); // ";"
    }
    
    shared actual void visitInvocationExpression(InvocationExpression that) {
        that.primary.visit(this);
        if (exists PositionalArgumentList list = that.positionalArgumentList) {
            list.visit(this);
        } else if (exists NamedArgumentList list = that.namedArgumentList) {
            list.visit(this);
        }
    }
    
    shared actual void visitPositionalArgumentList(PositionalArgumentList that) {
        writeOut(that.mainToken); // "("
        needsWhitespace = false;
        variable Boolean hasFirst = false;
        for (PositionalArgument argument in CeylonIterable(that.positionalArguments)) {
            if (hasFirst) {
                writer.write(", ");
                needsWhitespace = false;
            }
            argument.visit(this);
            hasFirst = true;
        }
        writeOut(that.mainEndToken); // ")"
    }
    
    shared actual void visitLiteral(Literal that) {
        if (needsWhitespace) {
            writer.write(" ");
        }
        writeOut(that.mainToken);
        needsWhitespace = true;
        if (exists Token endToken = that.mainEndToken) {
            throw Error("Literal has end token ('``endToken``')! Investigate"); // breakpoint here
        }
    }
    
    //TODO eventually, this will be unneeded, as each visitSomeSubclassOfNode should be overwritten here.
    shared actual void visitAny(Node that) {
        if (exists Token start = that.mainToken) {
            syserr.print(start.text);
            if (exists Token end = that.mainEndToken) {
                syserr.print("\t``end.text``");
            }
            syserr.println();
        }
        super.visitAny(that); // continue walking the tree
    }
    
    "Fast-forward the token stream until the specified token is reached, writing out any comment tokens,
     then write out the specified token.
     
     This method should always be used to write any tokens."
    void writeOut(Token token) {
        variable Integer i = tokens.index();
        while (i < token.tokenIndex) {
            Token current = tokens.get(i);
            if (current.type == lineComment || current.type == multiComment) {
                if (needsWhitespace) {
                    writer.write(" ");
                }
                writer.write(current.text);
            }
            else if (current.type != ws) {
                throw Error("Unexpected token '``current.text``'");
            }
            tokens.consume();
            if (current.type == multiComment) {
                nextLine();
            }
            i++;
        }
        writer.write(token.text);
        tokens.consume();
    }
    
    void nextLine() {
        variable Boolean wroteLastToken = false;
        variable Integer i = tokens.index();
        variable Token current = tokens.get(i); // definitely initialize
        while (i < tokens.size()) { // that's not the condition by which we normally exit the loop
            wroteLastToken = false;
            current = tokens.get(i);
            if (current.type == lineComment || current.type == multiComment || current.type == ws) {
                if (current.type != ws) {
                	if (needsWhitespace) {
                    	writer.write(" ");
                	}
                	writer.write(current.text);
                	tokens.consume();
                	wroteLastToken = true;
                }
                if (current.text.contains("\n")) {
                    break;
                }
            }
            else {
                // This happens when there's no newline where one should be (e.g., two statements in one line, closing brace after statement, etc.)
                break;
            }
            tokens.consume();
            i++;
        }
        if (!current.text.endsWith("\n") || !wroteLastToken) { // LINE_COMMENTs contain the terminating line break
            writer.write("\n");
        }
        needsWhitespace = false;
    }
}