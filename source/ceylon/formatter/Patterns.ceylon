import org.antlr.runtime {
    Token
}
import com.redhat.ceylon.compiler.typechecker.tree {
    Tree {
        ...
    },
    Visitor
}
import ceylon.formatter.options {
    FormattingOptions,
    stack,
    addIndentBefore
}
import ceylon.interop.java {
    CeylonIterable
}


/*
 TODO
 remove assertions before release; they’re probably useful for finding bugs,
 but impact performance negatively
 */

FormattingWriter.FormattingContext writeBacktickOpening(FormattingWriter writer, Token backtick) {
    assert (backtick.text == "`");
    value context = writer.writeToken {
        backtick;
        lineBreaksAfter = noLineBreak;
        spaceAfter = false;
    };
    assert (exists context);
    return context;
}

void writeBacktickClosing(FormattingWriter writer, Token backtick, FormattingWriter.FormattingContext context) {
    assert (backtick.text == "`");
    writer.writeToken {
        backtick;
        lineBreaksBefore = noLineBreak;
        spaceBefore = false;
        context;
    };
}

FormattingWriter.FormattingContext writeSpecifierMainToken(FormattingWriter writer, Token|String token, FormattingOptions options) {
    FormattingWriter.FormattingContext? context;
    switch (options.indentationAfterSpecifierExpressionStart)
    case (stack) {
        context = writer.writeToken {
            token;
            indentBefore = 2; // TODO option
            indentAfter = 1; // see #37
            indentAfterOnlyWhenLineBreak = true; // see #37
            spaceBefore = true;
            spaceAfter = true;
        };
    }
    case (addIndentBefore) {
        context = writer.writeToken {
            token;
            indentBefore = 2; // TODO option
            nextIndentBefore = 2; // see #37
            spaceBefore = true;
            spaceAfter = true;
        };
    }
    assert (exists context);
    return context;
}

"""Writes a meta literal, for example `` `class Object` `` (where [[start]] would be `"class"`)
   or `` `process` `` (where [[start]] would be [[null]])."""
see (`function writeMetaLiteralStart`)
void writeMetaLiteral(FormattingWriter writer, FormattingVisitor visitor, MetaLiteral that, String? start) {
    value context = writeBacktickOpening(writer, that.mainToken);
    if (exists start) {
        writeMetaLiteralStart(writer, start);
    }
    if (is TypeLiteral that) {
        that.type?.visit(visitor);
        that.objectExpression?.visit(visitor);
    } else if (is MemberLiteral that) {
        if (that.type exists || that.objectExpression exists) {
            that.type?.visit(visitor);
            that.objectExpression?.visit(visitor);
            writer.writeToken {
                ".";
                spaceBefore = false;
                spaceAfter = false;
                lineBreaksBefore = noLineBreak;
                lineBreaksAfter = noLineBreak;
            };
        }
        that.identifier?.visit(visitor);
        that.typeArgumentList?.visit(visitor);
    } else if (is ModuleLiteral that) {
        that.importPath?.visit(visitor);
    } else {
        assert (is PackageLiteral that);
        that.importPath?.visit(visitor);
    }
    writeBacktickClosing(writer, that.mainEndToken, context);
}

"""Writes the start of a meta literal, for example the `class` or `module`
   of `` `class Object` `` or `` `module ceylon.language` ``."""
void writeMetaLiteralStart(FormattingWriter writer, String start) {
    writer.writeToken {
        start;
        lineBreaksBefore = noLineBreak;
        indentAfter = 1;
        spaceBefore = false;
        spaceAfter = maxDesire - 1;
    };
}

FormattingWriter.FormattingContext? writeModifier(FormattingWriter writer, Token modifier) {
    return writer.writeToken {
        modifier;
        lineBreaksBefore = 0..2;
        spaceBefore = maxDesire - 1;
        spaceAfter = maxDesire - 1;
    };
}

void writeSemicolon(FormattingWriter writer, Token semicolon, FormattingWriter.FormattingContext context) {
    assert (semicolon.text == ";");
    writer.writeToken {
        semicolon;
        lineBreaksBefore = noLineBreak;
        lineBreaksAfter = writer.tokens exists then 0..2 else 1..0;
        spaceBefore = false;
        spaceAfter = true;
        context;
    };
}

void writeSomeMemberOp(FormattingWriter writer, Token token) {
    assert (token.text in { ".", "?.", "*." });
    writer.writeToken {
        token;
        indentBefore = 1;
        lineBreaksAfter = noLineBreak;
        spaceBefore = false;
        spaceAfter = false;
    };
}

void writeTypeArgumentOrParameterList(FormattingWriter writer, Visitor visitor, TypeArgumentList|TypeParameterList list, FormattingOptions options) {
    value context = writer.openContext();
    writer.writeToken {
        list.mainToken; // "<"
        indentAfter = 1;
        lineBreaksAfter = noLineBreak;
        spaceBefore = false;
        spaceAfter = false;
    };
    [Type|TypeParameterDeclaration*] params;
    if (is TypeArgumentList list) {
        params = CeylonIterable(list.types).sequence();
    } else {
        assert (is TypeParameterList list); // TODO remove
        params = CeylonIterable(list.typeParameterDeclarations).sequence();
    }
    assert (nonempty params);
    params.first.visit(visitor);
    for (param in params.rest) {
        writer.writeToken {
            ",";
            spaceBefore = false;
            spaceAfter = options.spaceAfterTypeArgOrParamListComma;
            lineBreaksAfter = options.lineBreaksInTypeParameterList;
        };
        param.visit(visitor);
    }
    writer.writeToken {
        list.mainEndToken; // ">"
        context;
        lineBreaksBefore = noLineBreak;
        spaceBefore = false;
    };
    writer.closeContext(context);
}

alias ExpressionWithoutSpaces => BaseMemberExpression|Literal|QualifiedMemberExpression|StringTemplate;

Term unwrapExpression(Term term) {
    if (is Expression term, !term.mainToken exists) {
        return unwrapExpression(term.term);
    } else {
        return term;
    }
}

"Determines if two binary operators have the same precedence.
 
 Not all precedence levels are supported;
 this is just a helper function for [[useSpacesAroundBinaryOp]]."
Boolean samePrecedence(Term e1, Term e2)
        => e1 is SumOp|DifferenceOp && e2 is SumOp|DifferenceOp
        || e1 is ProductOp|QuotientOp|RemainderOp && e2 is ProductOp|QuotientOp|RemainderOp
        || e1 is PowerOp && e2 is PowerOp
        || e1 is ScaleOp && e2 is ScaleOp
        || e1 is IntersectionOp && e2 is IntersectionOp
        || e1 is UnionOp|ComplementOp && e2 is UnionOp|ComplementOp
        || e1 is AndOp && e2 is AndOp
        || e1 is OrOp && e2 is OrOp;

"Determines whether there should be spaces around a binary operator or not.
 
 The spaces are omitted if:
 - the expression is a child of another [[BinaryOperatorExpression]] –
   this can’t be checked by this function and must be tested externally –, and
 - the children are both either
   - [[ExpressionWithoutSpaces]] (i. e., [[Literal]], [[BaseMemberExpression]] or [[QualifiedMemberExpression]]), or
   - the same kind of [[BinaryOperatorExpression]] (same precedence),
     and also have their spaces omitted.
 
 (The last rule is necessary to avoid `1+2 + 3`.)
 
 For the first rule, range and entry operators (`..`, `:`, `->`)
 should always be treated as if they were children of another binary operator expression.
 
 This results in spacing like this:
 
     value sum = 1 + 2 + 3;
     value hollowCubeVolume = w*h*d - iW*iH*iD; // (inner) width/height/depth
     value allEqual = a==b && b==c && c==d;
     value regular = start..end;
     value shifted = start+offset .. end+offset;
 
 See [#99](https://github.com/ceylon/ceylon.formatter/issues/99)."
Boolean useSpacesAroundBinaryOp(BinaryOperatorExpression e)
        => !{ e.leftTerm, e.rightTerm }.map(unwrapExpression).every {
    function selecting(Term t) {
        if (t is ExpressionWithoutSpaces) {
            return true;
        } else if (is BinaryOperatorExpression t) {
            return samePrecedence(t, e) && !useSpacesAroundBinaryOp(t);
        } else {
            return false;
        }
    }
};

"Terms in string templates might sometimes require spacing to disambiguate the syntax.
 For more information, see
 [#47](https://github.com/ceylon/ceylon.formatter/issues/47),
 [ceylon-spec#959](https://github.com/ceylon/ceylon-spec/issues/959), and/or
 [ceylon-spec#686](https://github.com/ceylon/ceylon-spec/issues/686)."
Boolean wantsSpacesInStringTemplate(Term term) {
    variable Boolean startsWithBacktick = false;
    object startsWithBacktickVisitor extends GoLeftVisitor() {
        shared actual void visitAliasLiteral(AliasLiteral that) => startsWithBacktick = true;
        shared actual void visitClassLiteral(ClassLiteral that) => startsWithBacktick = true;
        shared actual void visitFunctionLiteral(FunctionLiteral that) => startsWithBacktick = true;
        shared actual void visitInterfaceLiteral(InterfaceLiteral that) => startsWithBacktick = true;
        shared actual void visitMetaLiteral(MetaLiteral that) => startsWithBacktick = true;
        shared actual void visitModuleLiteral(ModuleLiteral that) => startsWithBacktick = true;
        shared actual void visitPackageLiteral(PackageLiteral that) => startsWithBacktick = true;
        shared actual void visitTypeParameterLiteral(TypeParameterLiteral that) => startsWithBacktick = true;
        shared actual void visitValueLiteral(ValueLiteral that) => startsWithBacktick = true;
    }
    term.visit(startsWithBacktickVisitor);
    return startsWithBacktick || !term is Primary;
}
