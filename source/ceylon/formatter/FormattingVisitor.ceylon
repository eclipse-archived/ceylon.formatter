import com.redhat.ceylon.compiler.typechecker.tree {
    Tree { ... },
    Node,
    VisitorAdaptor,
    NaturalVisitor
}
import com.redhat.ceylon.compiler.typechecker.parser {
    CeylonLexer {
        uidentifier=\iUIDENTIFIER,
        lidentifier=\iLIDENTIFIER
    }
}
import org.antlr.runtime {
    TokenStream {
        la=\iLA
    },
    Token,
    CommonToken
}
import ceylon.file {
    Writer
}
import ceylon.interop.java {
    CeylonIterable
}
import ceylon.formatter.options {
    FormattingOptions,
    multiLine
}
import ceylon.collection {
    MutableList,
    ArrayList
}

"A [[com.redhat.ceylon.compiler.typechecker.tree::Visitor]] that writes a formatted version of the
 element (typically a [[com.redhat.ceylon.compiler.typechecker.tree::Tree.CompilationUnit]]) to a
 [[java.io::Writer]]."
shared class FormattingVisitor(
    "The [[TokenStream]] from which the element was parsed;
     this is mainly needed to preserve comments, as they're not present in the AST."
    TokenStream? tokens,
    "The writer to which the subject is written."
    Writer writer,
    "The options for the formatter that control the format of the written code."
    FormattingOptions options) extends VisitorAdaptor() satisfies NaturalVisitor&Destroyable {
    
    FormattingWriter fWriter = FormattingWriter(tokens, writer, options);
    
    """When visiting an annotation, some elements are formatted differently.
       For example:
       
           doc ("<-- space")
           print("<-- no space");"""
    variable Boolean visitingAnnotation = false;
    
    // initialize TokenStream
    if (exists tokens) { tokens.la(1); }
    
    shared actual void handleException(Exception? e, Node that) {
        // set breakpoint here
        if (exists e) {
            if (options.failFast) {
                throw e;
            } else {
                e.printStackTrace();
            }
        }
    }
    
    shared actual void visitAbstractedType(AbstractedType that) {
        fWriter.writeToken {
            that.mainToken; // "abstracts"
            indentBefore = options.indentBeforeTypeInfo;
            linebreaksAfter = noLineBreak;
            spaceBefore = true;
            spaceAfter = true;
        };
        that.type.visit(this);
    }
    
    shared actual void visitAlias(Alias that) {
        that.identifier.visit(this);
        fWriter.writeToken {
            that.mainToken; // "="
            linebreaksBefore = noLineBreak;
            linebreaksAfter = noLineBreak;
            spaceBefore = options.spaceAroundImportAliasEqualsSign;
            spaceAfter = options.spaceAroundImportAliasEqualsSign;
        };
    }
    
    shared actual void visitAliasLiteral(AliasLiteral that)
            => writeMetaLiteral(fWriter, this, that, "alias");
    
    shared actual void visitAnnotation(Annotation that) {
        "Annotations can’t be nested"
        assert (!visitingAnnotation);
        visitingAnnotation = true;
        that.visitChildren(this);
        visitingAnnotation = false;
        if (is {String*} inlineAnnotations = options.inlineAnnotations) {
            if (exists text = that.primary?.children?.get(0)?.mainToken?.text,
                text in inlineAnnotations) {
                // no line break for these annotations
            } else {
                fWriter.requireAtLeastLineBreaks(1);
            }
        } else {
            // no line breaks for any annotations
        }
    }
    
    shared actual void visitAnonymousAnnotation(AnonymousAnnotation that) {
        "Annotations can’t be nested"
        assert (!visitingAnnotation);
        visitingAnnotation = true;
        that.visitChildren(this);
        visitingAnnotation = false;
        fWriter.requireAtLeastLineBreaks(1);
    }
    
    shared actual void visitAnyClass(AnyClass that) {
        value context = fWriter.openContext();
        that.annotationList.visit(this);
        fWriter.writeToken {
            that.mainToken; // "class"
            linebreaksAfter = noLineBreak;
            spaceBefore = true;
            spaceAfter = true;
        };
        that.identifier.visit(this);
        that.typeParameterList?.visit(this);
        that.parameterList?.visit(this);
        that.caseTypes?.visit(this);
        that.extendedType?.visit(this);
        that.satisfiedTypes?.visit(this);
        that.typeConstraintList?.visit(this);
        if (is ClassDefinition that) {
            that.classBody.visit(this);
        } else if (is ClassDeclaration that) {
            that.classSpecifier?.visit(this);
            writeSemicolon(fWriter, that.mainEndToken, context);
        }
    }
    
    shared actual void visitAnyInterface(AnyInterface that) {
        value context = fWriter.openContext();
        that.annotationList.visit(this);
        fWriter.writeToken {
            that.mainToken; // "interface"
            linebreaksAfter = noLineBreak;
            spaceBefore = true;
            spaceAfter = true;
        };
        that.identifier.visit(this);
        that.typeParameterList?.visit(this);
        that.caseTypes?.visit(this);
        that.satisfiedTypes?.visit(this);
        that.typeConstraintList?.visit(this);
        if (is InterfaceDefinition that) {
            that.interfaceBody.visit(this);
        } else if (is InterfaceDeclaration that) {
            that.typeSpecifier?.visit(this);
            writeSemicolon(fWriter, that.mainEndToken, context);
        }
    }
    
    shared actual void visitAnyMethod(AnyMethod that) {
        // override the default Walker's order
        that.annotationList.visit(this);
        that.type.visit(this);
        that.identifier.visit(this);
        that.typeParameterList?.visit(this);
        for (ParameterList list in CeylonIterable(that.parameterLists)) {
            list.visit(this);
        }
        that.typeConstraintList?.visit(this);
    }
    
    shared actual void visitAssertion(Assertion that) {
        value context = fWriter.openContext();
        that.annotationList.visit(this);
        fWriter.writeToken {
            that.mainToken; // "assert"
            linebreaksAfter = noLineBreak;
            spaceBefore = true; // TODO option
            spaceAfter = true;
        };
        that.conditionList.visit(this);
        writeSemicolon(fWriter, that.mainEndToken, context);
    }
    
    shared actual void visitAttributeDeclaration(AttributeDeclaration that) {
        value context = fWriter.openContext();
        visitAnyAttribute(that);
        if (exists expression = that.specifierOrInitializerExpression) {
            expression.visit(this);
        }
        if (exists endToken = that.mainEndToken) {
            writeSemicolon(fWriter, that.mainEndToken, context);
        } else {
            fWriter.closeContext(context);
        }
    }
    
    shared actual void visitAttributeGetterDefinition(AttributeGetterDefinition that) {
        visitAnyAttribute(that);
        that.block.visit(this);
    }
    
    shared actual void visitBaseMemberExpression(BaseMemberExpression that)
            => that.identifier.visit(this);
    
    shared actual void visitBaseType(BaseType that) {
        writeOptionallyGrouped(fWriter, void() {
                that.identifier.visit(this);
                that.typeArgumentList?.visit(this);
            });
    }
    
    shared actual void visitBaseTypeExpression(BaseTypeExpression that) {
        writeOptionallyGrouped(fWriter, void() {
                that.identifier.visit(this);
                that.typeArguments.visit(this);
            });
    }
    
    shared actual void visitBinaryOperatorExpression(BinaryOperatorExpression that) {
        that.leftTerm.visit(this);
        fWriter.writeToken {
            that.mainToken;
            spaceBefore = true;
            spaceAfter = true;
        };
        that.rightTerm.visit(this);
    }
    
    shared actual void visitBody(Body that) {
        value statements = CeylonIterable(that.statements).sequence;
        FormattingWriter.FormattingContext? context;
        if (exists token = that.mainToken) {
            context = fWriter.writeToken {
                token; // "{"
                indentAfter = 1;
                linebreaksBefore = options.braceOnOwnLine then 1..1 else noLineBreak;
                linebreaksAfter = 0..2;
                spaceBefore = 10;
                spaceAfter = statements nonempty;
            };
        } else {
            context = null;
        }
        for (Statement statement in statements) {
            if (statements.longerThan(1)) {
                fWriter.requireAtLeastLineBreaks(1);
            }
            statement.visit(this);
            if (statements.longerThan(1)) {
                fWriter.requireAtLeastLineBreaks(1);
            }
        }
        if (exists token = that.mainEndToken) {
            fWriter.writeToken {
                token; // "}"
                linebreaksBefore = 0..1;
                linebreaksAfter = 0..3;
                spaceBefore = statements nonempty;
                spaceAfter = 5;
                context;
            };
        }
    }
    
    shared actual void visitBreak(Break that) {
        value context = fWriter.writeToken {
            that.mainToken; // "break"
            spaceAfter = false;
            linebreaksAfter = noLineBreak;
        };
        assert (exists context);
        writeSemicolon(fWriter, that.mainEndToken, context);
    }
    
    shared actual void visitCaseClause(CaseClause that) {
        fWriter.writeToken {
            that.mainToken; // "case"
            spaceBefore = true;
            spaceAfter = true; // TODO option
            linebreaksBefore = 1..1;
            linebreaksAfter = noLineBreak;
        };
        value context = fWriter.writeToken {
            "(";
            /* not in the AST – there’s a TODO in Ceylon.g that “we really should not throw away this token”;
               for now, we produce it out of thin air :) */
            spaceAfter = false; // TODO option
            indentAfter = 1;
            linebreaksAfter = noLineBreak;
        };
        that.caseItem?.visit(this); // nullsafe because the grammar allows case () { ... } – wtf?
        fWriter.writeToken {
            that.caseItem?.mainEndToken else ")";
            context;
            spaceBefore = false; // TODO option
            linebreaksBefore = noLineBreak;
        };
        that.block.visit(this);
    }
    
    shared actual void visitCaseTypes(CaseTypes that) {
        value context = fWriter.writeToken {
            that.mainToken; // "of"
            spaceBefore = true;
            spaceAfter = true;
            indentBefore = options.indentBeforeTypeInfo;
            indentAfter = 1;
        };
        assert (exists context);
        // TODO replace casesList with ceylon-spec#947’s solution
        // TODO should be MutableList<StaticType|BaseMemberExpression>, ceylon-compiler#1572
        MutableList<Node> casesList = ArrayList<Node>();
        casesList.addAll(CeylonIterable(that.types));
        casesList.addAll(CeylonIterable(that.baseMemberExpressions));
        assert (nonempty cases = casesList.sort(byIncreasing(compose(Token.tokenIndex, Node.token))));
        cases.first.visit(this);
        for (item in cases.rest) {
            fWriter.writeToken {
                "|";
                spaceBefore = false; // TODO option
                spaceAfter = false;
                linebreaksBefore = noLineBreak;
                linebreaksAfter = noLineBreak;
            };
            item.visit(this);
        }
        fWriter.closeContext(context);
    }
    
    shared actual void visitCatchClause(CatchClause that) {
        fWriter.writeToken {
            that.mainToken; // "catch"
            spaceBefore = true;
        };
        that.catchVariable.visit(this);
        that.block.visit(this);
    }
    
    shared actual void visitCatchVariable(CatchVariable that) {
        value context = fWriter.writeToken {
            that.mainToken; // "("
            spaceBefore = options.spaceBeforeCatchVariable;
            spaceAfter = false;
            linebreaksBefore = noLineBreak;
            indentAfter = 1;
        };
        that.variable?.visit(this); // nullsafe because the grammar allows catch ()
        fWriter.writeToken {
            that.mainEndToken; // ")"
            context;
            spaceBefore = false;
        };
    }
    
    shared actual void visitClassLiteral(ClassLiteral that)
            => writeMetaLiteral(fWriter, this, that, "class");
    
    shared actual void visitConditionList(ConditionList that) {
        value context = fWriter.writeToken {
            that.mainToken; // "("
            linebreaksBefore = noLineBreak;
            indentAfter = 1;
            spaceAfter = false;
        };
        value conditions = CeylonIterable(that.conditions).sequence;
        "Empty condition list not allowed"
        assert (exists first = conditions.first);
        variable value innerContext = fWriter.openContext();
        first.visit(this);
        for (element in conditions.rest) {
            fWriter.writeToken {
                ",";
                linebreaksBefore = noLineBreak;
                spaceBefore = false;
                spaceAfter = true;
                innerContext;
            };
            innerContext = fWriter.openContext();
            element.visit(this);
        }
        fWriter.writeToken {
            that.mainEndToken; // ")"
            linebreaksBefore = noLineBreak;
            spaceBefore = false;
            spaceAfter = 0;
            context;
        };
    }
    
    shared actual void visitContinue(Continue that) {
        value context = fWriter.writeToken {
            that.mainToken; // "continue"
            spaceAfter = false;
            linebreaksAfter = noLineBreak;
        };
        assert (exists context);
        writeSemicolon(fWriter, that.mainEndToken, context);
    }
    
    shared actual void visitDefaultOp(DefaultOp that) {
        that.leftTerm.visit(this);
        fWriter.writeToken {
            that.mainToken; // "else"
            indentBefore = 2;
            spaceBefore = true;
            spaceAfter = true;
        };
        that.rightTerm.visit(this);
    }
    
    shared actual void visitElementRange(ElementRange that) {
        /* 
         An ElementRange can be anything that goes into an index expression (except a single element),
         that is, ...upper, lower..., lower..upper, and lower:length.
         The ..., .. and : tokens are all lost because the grammar for this part kinda sucks
         (TODO go bug someone about that),
         so we just have to infer them from which fields are null and which aren’t
         (for example, use : if there’s a length).
         */
        Expression? lower = that.lowerBound;
        Expression? upper = that.upperBound;
        Expression? length = that.length;
        
        variable Boolean wantsSpaces = wantsSpecialSpaces({ lower?.term, upper?.term, length?.term }.coalesced);
        
        if (exists lower) {
            if (exists length) {
                "Range can’t have an upper bound when it has a length"
                assert (is Null upper);
                lower.visit(this);
                fWriter.writeToken {
                    ":";
                    spaceBefore = wantsSpaces;
                    spaceAfter = wantsSpaces;
                    linebreaksBefore = noLineBreak;
                    linebreaksAfter = noLineBreak;
                };
                length.visit(this);
            } else if (exists upper) {
                "Range can’t have a length when it has an upper bound"
                assert (is Null length);
                lower.visit(this);
                fWriter.writeToken {
                    "..";
                    spaceBefore = wantsSpaces;
                    spaceAfter = wantsSpaces;
                    linebreaksBefore = noLineBreak;
                    linebreaksAfter = noLineBreak;
                };
                upper.visit(this);
            } else {
                lower.visit(this);
                fWriter.writeToken {
                    "...";
                    spaceBefore = wantsSpaces;
                    linebreaksBefore = noLineBreak;
                };
            }
        } else {
            "Range can’t have a length without a lower bound"
            assert (is Null length);
            "Range can’t be unbounded"
            assert (exists upper);
            fWriter.writeToken {
                "...";
                spaceAfter = wantsSpaces;
                linebreaksAfter = noLineBreak;
            };
            upper.visit(this);
        }
    }
    
    "Do not use this for `switch` `else` clauses – use [[visitSwitchElseClause]] for that instead.
     
     (Reason: [[FormattingOptions.elseOnOwnLine]] shouldn’t be used for these else clauses.)"
    shared actual void visitElseClause(ElseClause that) {
        fWriter.writeToken {
            that.mainToken; // "else"
            linebreaksBefore = options.elseOnOwnLine then 1..1 else 0..0;
            linebreaksAfter = noLineBreak;
        };
        that.visitChildren(this);
    }
    
    shared actual void visitEntryOp(EntryOp that)
            => writeBinaryOpWithSpecialSpaces(fWriter, this, that);
    
    shared actual void visitEntryType(EntryType that) {
        writeOptionallyGrouped(fWriter, () {
                that.keyType.visit(this);
                fWriter.writeToken {
                    "->";
                    linebreaksBefore = noLineBreak;
                    linebreaksAfter = noLineBreak;
                    spaceBefore = false;
                    spaceAfter = false;
                };
                that.valueType.visit(this);
                return null;
            });
    }
    
    shared actual void visitExists(Exists that) {
        value context = fWriter.openContext();
        that.term.visit(this);
        fWriter.writeToken {
            that.mainToken; // "exists"
            context;
            spaceBefore = true;
            linebreaksBefore = noLineBreak;
        };
    }
    
    shared actual void visitExistsOrNonemptyCondition(ExistsOrNonemptyCondition that) {
        fWriter.writeToken {
            that.mainToken; // "exists" or "nonempty"
            spaceAfter = true;
            linebreaksAfter = noLineBreak;
        };
        that.visitChildren(this);
    }
    
    shared actual void visitExpression(Expression that) {
        if (exists token = that.mainToken) {
            assert (exists endToken = that.mainEndToken);
            value context = fWriter.writeToken {
                token; // "("
                indentAfter = 1;
                spaceAfter = false;
            };
            that.term.visit(this);
            fWriter.writeToken {
                endToken; // ")"
                context;
                spaceBefore = false;
            };
        } else {
            that.term.visit(this);
        }
    }
    
    shared actual void visitExtendedType(ExtendedType that) {
        fWriter.writeToken {
            that.mainToken; // "extends"
            indentBefore = options.indentBeforeTypeInfo;
            linebreaksAfter = noLineBreak;
            spaceBefore = true;
            spaceAfter = true;
        };
        that.type.visit(this);
        that.invocationExpression.visit(this);
    }
    
    shared actual void visitFinallyClause(FinallyClause that) {
        fWriter.writeToken {
            that.mainToken;
            spaceBefore = true;
            spaceAfter = true;
        };
        that.block.visit(this);
    }
    
    shared actual void visitForClause(ForClause that) {
        fWriter.writeToken {
            that.mainToken; // "for"
            linebreaksAfter = noLineBreak;
            spaceAfter = options.spaceBeforeForOpeningParenthesis;
        };
        that.visitChildren(this);
    }
    
    shared actual void visitForComprehensionClause(ForComprehensionClause that) {
        fWriter.writeToken {
            that.mainToken; // "for"
            linebreaksAfter = noLineBreak;
            spaceAfter = options.spaceBeforeForOpeningParenthesis;
        };
        that.forIterator.visit(this);
        value context = fWriter.openContext(1);
        that.comprehensionClause.visit(this);
        fWriter.closeContext(context);
    }
    
    shared actual void visitFunctionArgument(FunctionArgument that) {
        that.type?.visit(this);
        for (list in CeylonIterable(that.parameterLists)) {
            list.visit(this);
        }
        if (exists expr = that.expression) {
            fWriter.writeToken {
                "=>";
                spaceBefore = true;
                spaceAfter = true;
                linebreaksBefore = noLineBreak;
                indentAfter = 1;
            };
            expr.visit(this);
        } else {
            "Function argument must have either a specifier expression or a block"
            assert (exists block = that.block);
            block.visit(this);
        }
    }
    
    shared actual void visitFunctionLiteral(FunctionLiteral that)
            => writeMetaLiteral(fWriter, this, that, "function");
    
    shared actual void visitFunctionModifier(FunctionModifier that) {
        if (exists token = that.mainToken) {
            writeModifier(fWriter, token);
        }
    }
    
    shared actual void visitFunctionType(FunctionType that) {
        that.returnType.visit(this);
        value context = fWriter.writeToken {
            "(";
            spaceBefore = false;
            spaceAfter = false;
            linebreaksBefore = noLineBreak;
            indentAfter = 1;
        };
        value argumentTypes = CeylonIterable(that.argumentTypes).sequence;
        if (nonempty argumentTypes) {
            argumentTypes.first.visit(this);
            for (argumentType in argumentTypes.rest) {
                fWriter.writeToken {
                    ",";
                    spaceBefore = false;
                    spaceAfter = true;
                    linebreaksBefore = noLineBreak;
                };
                argumentType.visit(this);
            }
        }
        fWriter.writeToken {
            that.mainEndToken; // ")"
            context;
            spaceBefore = false;
        };
    }
    
    shared actual void visitIdentifier(Identifier that) {
        String tokenText;
        assert (is CommonToken token = that.mainToken); // need CommonToken’s start and stop fields
        value diff = token.stopIndex - token.startIndex - token.text.size + 1;
        if (diff == 0) {
            // normal identifier
            tokenText = token.text;
        } else {
            // \iidentifier or \Iidentifier
            assert (diff == 2);
            if (token.type == uidentifier) {
                tokenText = "\\I" + token.text;
            } else if (token.type == lidentifier) {
                tokenText = "\\i" + token.text;
            } else {
                throw Exception("Unexpected token type on identifier token!");
            }
        }
        fWriter.writeToken {
            tokenText;
            tokenInStream = that.mainToken;
            linebreaksBefore = 0..2;
        };
    }
    
    shared actual void visitIfClause(IfClause that) {
        fWriter.writeToken {
            that.mainToken; // "if"
            linebreaksAfter = noLineBreak;
            spaceAfter = options.spaceBeforeIfOpeningParenthesis;
        };
        that.visitChildren(this);
    }
    
    shared actual void visitIfComprehensionClause(IfComprehensionClause that) {
        fWriter.writeToken {
            that.mainToken; // "if"
            linebreaksAfter = noLineBreak;
            spaceAfter = options.spaceBeforeIfOpeningParenthesis;
        };
        that.conditionList.visit(this);
        value context = fWriter.openContext(1);
        that.comprehensionClause.visit(this);
        fWriter.closeContext(context);
    }
    
    shared actual void visitImport(Import that) {
        fWriter.writeToken {
            that.mainToken;
            linebreaksBefore = 1..0;
            linebreaksAfter = noLineBreak;
            spaceBefore = false;
            spaceAfter = true;
        };
        that.visitChildren(this);
        fWriter.requireAtLeastLineBreaks(1);
    }
    
    shared actual void visitImportMemberOrTypeList(ImportMemberOrTypeList that) {
        value context = fWriter.writeToken {
            that.mainToken; // "{"
            linebreaksBefore = noLineBreak;
            indentAfter = 1;
            spaceBefore = true;
            spaceAfter = true;
        };
        if (exists wildcard = that.importWildcard) {
            wildcard.visit(this);
        } else {
            if (options.importStyle == multiLine) {
                fWriter.requireAtLeastLineBreaks(1);
            }
            assert (exists membersOrTypes = that.importMemberOrTypes);
            value elements = CeylonIterable(membersOrTypes).sequence;
            "Empty import list not allowed"
            assert (exists first = elements.first);
            variable value innerContext = fWriter.openContext();
            first.visit(this);
            for (value element in elements.rest) {
                fWriter.writeToken {
                    ",";
                    linebreaksBefore = noLineBreak;
                    linebreaksAfter = (options.importStyle == multiLine then 1 else 0)..1;
                    spaceBefore = false;
                    spaceAfter = true;
                    innerContext;
                };
                innerContext = fWriter.openContext();
                element.visit(this);
            }
            if (options.importStyle == multiLine) {
                fWriter.requireAtLeastLineBreaks(1);
            }
            fWriter.closeContext(innerContext);
        }
        fWriter.writeToken {
            that.mainEndToken; // "}"
            linebreaksAfter = 0..3;
            spaceBefore = true;
            spaceAfter = 1000;
            context;
        };
    }
    
    shared actual void visitImportModule(ImportModule that) {
        value context = fWriter.openContext();
        that.annotationList.visit(this);
        fWriter.writeToken {
            that.mainToken; // "import"
            spaceBefore = true;
            spaceAfter = true;
            linebreaksAfter = noLineBreak;
        };
        that.importPath?.visit(this); // nullsafe because might be quoted…
        that.quotedLiteral?.visit(this); // …like this
        that.version?.visit(this); // version not mandatory in the grammar
        writeSemicolon(fWriter, that.mainEndToken, context);
    }
    
    shared actual void visitImportModuleList(ImportModuleList that) {
        value context = fWriter.writeToken {
            that.mainToken; // "{"
            spaceBefore = true;
            spaceAfter = true;
            linebreaksBefore = options.braceOnOwnLine then 1..1 else noLineBreak;
            linebreaksAfter = 1..2;
            indentAfter = 1;
        };
        for (importModule in CeylonIterable(that.importModules)) {
            importModule.visit(this);
        }
        fWriter.writeToken {
            that.mainEndToken; // "}"
            context;
            linebreaksBefore = 1..1;
        };
    }
    
    shared actual void visitImportPath(ImportPath that) {
        value identifiers = CeylonIterable(that.identifiers).sequence;
        "Import can’t have empty import path"
        assert (nonempty identifiers);
        identifiers.first.visit(this);
        for (value identifier in identifiers.rest) {
            fWriter.writeToken {
                ".";
                indentBefore = 1;
                linebreaksAfter = noLineBreak;
                spaceBefore = false;
                spaceAfter = false;
            };
            identifier.visit(this);
        }
    }
    
    shared actual void visitImportWildcard(ImportWildcard that) {
        fWriter.writeToken {
            that.mainToken; // "..."
            linebreaksBefore = noLineBreak;
            linebreaksAfter = noLineBreak;
            spaceBefore = true;
            spaceAfter = true;
        };
    }
    
    shared actual void visitIndexExpression(IndexExpression that) {
        that.primary.visit(this);
        value context = fWriter.writeToken {
            that.mainToken; // "["
            spaceBefore = false;
            spaceAfter = false;
            linebreaksBefore = noLineBreak;
            linebreaksAfter = noLineBreak;
        };
        that.elementOrRange.visit(this);
        fWriter.writeToken {
            that.mainEndToken; // "]"
            context;
            spaceBefore = false;
            linebreaksBefore = noLineBreak;
        };
    }
    
    shared actual void visitInterfaceLiteral(InterfaceLiteral that)
            => writeMetaLiteral(fWriter, this, that, "interface");
    
    shared actual void visitIntersectionType(IntersectionType that) {
        writeOptionallyGrouped(fWriter, () {
                value types = CeylonIterable(that.staticTypes).sequence;
                "Empty union type not allowed"
                assert (nonempty types);
                types.first.visit(this);
                for (type in types.rest) {
                    fWriter.writeToken {
                        "&";
                        linebreaksBefore = noLineBreak;
                        linebreaksAfter = noLineBreak;
                        spaceBefore = false;
                        spaceAfter = false;
                    };
                    type.visit(this);
                }
                return null;
            });
    }
    
    shared actual void visitInvocationExpression(InvocationExpression that) {
        that.primary.visit(this);
        if (exists PositionalArgumentList list = that.positionalArgumentList) {
            list.visit(this);
        } else if (exists NamedArgumentList list = that.namedArgumentList) {
            list.visit(this);
        }
    }
    
    shared actual void visitIsCase(IsCase that) {
        fWriter.writeToken {
            that.mainToken; // "is"
            spaceAfter = true;
            linebreaksAfter = noLineBreak;
        };
        that.type.visit(this);
        // Note: Do not visitChildren! compiler adds Variable to node (the variable whose type is tested), but that’s not in the code.
    }
    
    shared actual void visitIsCondition(IsCondition that) {
        if (that.not) {
            fWriter.writeToken {
                that.mainToken; // "!"
                spaceAfter = false;
                linebreaksAfter = noLineBreak;
            };
        }
        fWriter.writeToken {
            "is";
            spaceAfter = true;
            linebreaksAfter = noLineBreak;
        };
        that.type.visit(this);
        that.variable.visit(this);
    }
    
    shared actual void visitIterableType(IterableType that) {
        writeOptionallyGrouped(fWriter, () {
                value context = fWriter.writeToken {
                    that.mainToken; // "{"
                    linebreaksAfter = noLineBreak;
                    spaceAfter = false;
                };
                that.elementType.visit(this);
                fWriter.writeToken {
                    that.mainEndToken; // "}"
                    linebreaksBefore = noLineBreak;
                    spaceBefore = false;
                    context = context;
                };
                return null;
            });
    }
    
    shared actual void visitLiteral(Literal that) {
        fWriter.writeToken {
            that.mainToken;
            spaceBefore = 1;
            spaceAfter = 1;
            linebreaksBefore = visitingAnnotation then 0..3 else 0..1;
        };
        if (exists Token endToken = that.mainEndToken) {
            throw Error("Literal has end token ('``endToken``')! Investigate"); // breakpoint here
        }
    }
    
    shared actual void visitMatchCase(MatchCase that)
            => that.visitChildren(this);
    
    shared actual void visitMemberOp(MemberOp that)
            => writeSomeMemberOp(fWriter, that.mainToken);
    
    shared actual void visitMetaLiteral(MetaLiteral that)
            => writeMetaLiteral(fWriter, this, that, null);
    
    shared actual void visitMethodDeclaration(MethodDeclaration that) {
        value context = fWriter.openContext();
        visitAnyMethod(that);
        if (exists SpecifierExpression expr = that.specifierExpression) {
            expr.visit(this);
        }
        if (exists semicolon = that.mainEndToken) {
            writeSemicolon(fWriter, semicolon, context);
        } else {
            fWriter.closeContext(context);
        }
    }
    
    shared actual void visitMethodDefinition(MethodDefinition that) {
        value context = fWriter.openContext();
        visitAnyMethod(that);
        fWriter.closeContext(context);
        that.block.visit(this);
    }
    
    shared actual void visitModuleDescriptor(ModuleDescriptor that) {
        that.annotationList.visit(this);
        fWriter.writeToken {
            that.mainToken; // "module"
            spaceBefore = true;
            spaceAfter = true;
            linebreaksAfter = noLineBreak;
        };
        that.importPath.visit(this);
        that.version.visit(this);
        that.importModuleList.visit(this);
    }
    
    shared actual void visitModuleLiteral(ModuleLiteral that)
            => writeMetaLiteral(fWriter, this, that, "module");
    
    shared actual void visitNamedArgumentList(NamedArgumentList that) {
        value context = fWriter.writeToken {
            that.mainToken; // "{"
            spaceAfter = true;
            linebreaksAfter = 1..0;
            indentBefore = 1;
            indentAfter = 1;
        };
        for (arg in CeylonIterable(that.namedArguments)) {
            arg.visit(this);
        }
        that.sequencedArgument?.visit(this);
        fWriter.writeToken {
            that.mainEndToken; // "}"
            context;
            spaceBefore = true;
            linebreaksBefore = 1..0;
        };
    }
    
    shared actual void visitNegativeOp(NegativeOp that) {
        fWriter.writeToken {
            that.mainToken; // "-"
            spaceAfter = false;
            linebreaksAfter = noLineBreak;
        };
        that.term.visit(this);
    }
    
    shared actual void visitNonempty(Nonempty that) {
        value context = fWriter.openContext();
        that.term.visit(this);
        fWriter.writeToken {
            that.mainToken; // "nonempty"
            context;
            spaceBefore = true;
            linebreaksBefore = noLineBreak;
        };
    }
    
    shared actual void visitNotOp(NotOp that) {
        fWriter.writeToken {
            that.mainToken; // "!"
            spaceAfter = false;
            linebreaksAfter = noLineBreak;
        };
        that.term.visit(this);
    }
    
    shared actual void visitObjectArgument(ObjectArgument that) {
        value context = fWriter.writeToken {
            that.mainToken; // "object"
            spaceAfter = true;
            linebreaksAfter = noLineBreak;
        };
        assert (exists context);
        that.identifier.visit(this);
        that.extendedType?.visit(this);
        that.satisfiedTypes?.visit(this);
        if (exists body = that.classBody) {
            body.visit(this);
            fWriter.closeContext(context);
        } else {
            /*
             If I understand the grammar correctly, it’s possible to replace the body with a semicolon.
             In that case, the parser will add a recognition error, but then continue parsing.
             I guess that qualifies as syntactically valid-ish code, so we support it here.
             */
            writeSemicolon(fWriter, that.mainEndToken, context);
        }
    }
    
    shared actual void visitObjectDefinition(ObjectDefinition that) {
        that.annotationList?.visit(this);
        fWriter.writeToken {
            that.mainToken; // "object"
            spaceAfter = true;
        };
        that.identifier.visit(this);
        that.extendedType?.visit(this);
        that.satisfiedTypes?.visit(this);
        that.classBody.visit(this);
    }
    
    shared actual void visitOptionalType(OptionalType that) {
        writeOptionallyGrouped(fWriter, () {
                that.definiteType.visit(this);
                fWriter.writeToken {
                    that.mainEndToken; // "?"
                    linebreaksBefore = noLineBreak;
                    spaceBefore = false;
                };
                return null;
            });
    }
    
    shared actual void visitOuter(Outer that) {
        fWriter.writeToken {
            that.mainToken;
        };
    }
    
    shared actual void visitPackageDescriptor(PackageDescriptor that) {
        value context = fWriter.openContext();
        that.annotationList.visit(this);
        fWriter.writeToken {
            that.mainToken; // "import"
            spaceBefore = true;
            spaceAfter = true;
            linebreaksAfter = noLineBreak;
        };
        that.importPath.visit(this);
        writeSemicolon(fWriter, that.mainEndToken, context);
    }
    
    shared actual void visitPackageLiteral(PackageLiteral that)
            => writeMetaLiteral(fWriter, this, that, "package");
    
    shared actual void visitParameterList(ParameterList that) {
        variable Boolean multiLine = false;
        object multiLineVisitor extends VisitorAdaptor() {
            shared actual void visitAnnotation(Annotation annotation) {
                if (is {String*} inlineAnnotations = options.inlineAnnotations) {
                    if (exists text = annotation.primary?.children?.get(0)?.mainToken?.text,
                        text in inlineAnnotations) {
                        // not multiLine
                    } else {
                        multiLine = true;
                    }
                } else {
                    // not multiLine
                }
            }
            shared actual void visitAnonymousAnnotation(AnonymousAnnotation? anonymousAnnotation) {
                multiLine = true;
            }
        }
        that.visitChildren(multiLineVisitor);
        
        value context = fWriter.writeToken {
            that.mainToken; // "("
            indentAfter = 1;
            linebreaksAfter = multiLine then 1..1 else 0..1;
            spaceBefore = options.spaceAfterParamListOpeningParen;
            spaceAfter = options.spaceAfterParamListOpeningParen;
        };
        
        variable FormattingWriter.FormattingContext? previousContext = null;
        for (Parameter parameter in CeylonIterable(that.parameters)) {
            if (exists c = previousContext) {
                fWriter.writeToken {
                    ",";
                    linebreaksBefore = noLineBreak;
                    linebreaksAfter = multiLine then 1..1 else 0..1;
                    spaceBefore = false;
                    spaceAfter = true;
                    context = c;
                };
            }
            previousContext = fWriter.openContext();
            parameter.visit(this);
        }
        fWriter.writeToken {
            that.mainEndToken; // ")"
            linebreaksBefore = noLineBreak;
            spaceBefore = options.spaceBeforeParamListClosingParen;
            spaceAfter = options.spaceAfterParamListClosingParen;
            context = context;
        };
    }
    
    shared actual void visitPositionalArgumentList(PositionalArgumentList that) {
        Token? openingParen = that.mainToken;
        Token? closingParen = that.mainEndToken;
        if (exists openingParen, exists closingParen) {
            value context = fWriter.writeToken {
                that.mainToken; // "("
                linebreaksBefore = noLineBreak;
                indentAfter = 1;
                spaceBefore = visitingAnnotation
                        then options.spaceBeforeAnnotationPositionalArgumentList
                        else options.spaceBeforeMethodOrClassPositionalArgumentList;
                spaceAfter = false;
            };
            variable FormattingWriter.FormattingContext? previousContext = null;
            for (PositionalArgument argument in CeylonIterable(that.positionalArguments)) {
                if (exists c = previousContext) {
                    fWriter.writeToken {
                        ",";
                        c;
                        linebreaksBefore = noLineBreak;
                        spaceBefore = false;
                        spaceAfter = true;
                    };
                }
                previousContext = fWriter.openContext();
                argument.visit(this);
            }
            fWriter.writeToken {
                that.mainEndToken; // ")"
                spaceBefore = false;
                spaceAfter = 5;
                context;
            };
        } else {
            // this happens for annotations with no arguments
            assert (that.positionalArguments.empty);
            return;
        }
    }
    
    shared actual void visitPositiveOp(PositiveOp that) {
        fWriter.writeToken {
            that.mainToken; // "-"
            spaceAfter = false;
            linebreaksAfter = noLineBreak;
        };
        that.term.visit(this);
    }
    
    shared actual void visitPostfixOperatorExpression(PostfixOperatorExpression that) {
        that.term.visit(this);
        fWriter.writeToken {
            that.mainToken; // "++" or "--"
            spaceBefore = false;
            linebreaksBefore = noLineBreak;
        };
    }
    
    shared actual void visitPrefixOperatorExpression(PrefixOperatorExpression that) {
        fWriter.writeToken {
            that.mainToken; // "++" or "--"
            spaceAfter = false;
            linebreaksAfter = noLineBreak;
        };
        that.term.visit(this);
    }
    
    shared actual void visitQualifiedMemberOrTypeExpression(QualifiedMemberOrTypeExpression that) {
        that.primary.visit(this);
        that.memberOperator.visit(this);
        that.identifier.visit(this);
        that.typeArguments.visit(this);
    }
    
    shared actual void visitQualifiedType(QualifiedType that) {
        writeOptionallyGrouped(fWriter, void() {
                that.outerType.visit(this);
                fWriter.writeToken {
                    that.mainToken; // "."
                    spaceBefore = false;
                    spaceAfter = false;
                    linebreaksBefore = noLineBreak;
                    linebreaksAfter = noLineBreak;
                };
                that.identifier.visit(this);
            });
    }
    
    shared actual void visitRangeOp(RangeOp that)
            => writeBinaryOpWithSpecialSpaces(fWriter, this, that);
    
    shared actual void visitResourceList(ResourceList that) {
        value context = fWriter.writeToken {
            that.mainToken; // "("
            spaceBefore = options.spaceBeforeResourceList;
            spaceAfter = false;
        };
        value resources = CeylonIterable(that.resources).sequence;
        if (nonempty resources) { // grammar allows empty resource list
            variable Resource lastResource = resources.first;
            lastResource.visit(this);
            for (resource in resources.rest) {
                fWriter.writeToken {
                    lastResource.mainEndToken; // ","
                    spaceBefore = false;
                    spaceAfter = true;
                    linebreaksBefore = noLineBreak;
                };
                lastResource = resource;
                lastResource.visit(this);
            }
        }
        fWriter.writeToken {
            that.mainEndToken; // ")"
            context;
            spaceBefore = false;
        };
    }
    
    shared actual void visitReturn(Return that) {
        value context = fWriter.writeToken {
            that.mainToken; // "return"
            indentAfter = 1;
            indentAfterOnlyWhenLineBreak = true;
            spaceAfter = that.expression exists;
            linebreaksAfter = that.expression exists then 0..1 else 0..0;
        };
        assert (exists context);
        that.expression?.visit(this);
        writeSemicolon(fWriter, that.mainEndToken, context);
    }
    
    shared actual void visitSafeMemberOp(SafeMemberOp that)
            => writeSomeMemberOp(fWriter, that.mainToken);
    
    shared actual void visitSatisfiedTypes(SatisfiedTypes that) {
        value context = fWriter.writeToken {
            that.mainToken; // "satisfies"
            indentBefore = options.indentBeforeTypeInfo;
            linebreaksAfter = noLineBreak;
            spaceBefore = true;
            spaceAfter = true;
        };
        assert (exists context);
        value types = CeylonIterable(that.types).sequence;
        "Must satisfy at least one type"
        assert (nonempty types);
        types.first.visit(this);
        for (type in types.rest) {
            fWriter.writeToken {
                "&";
                linebreaksBefore = noLineBreak;
                linebreaksAfter = noLineBreak;
                spaceBefore = false;
                spaceAfter = false;
            };
            type.visit(this);
        }
        fWriter.closeContext(context);
    }
    
    shared actual void visitSatisfiesCase(SatisfiesCase that) {
        fWriter.writeToken {
            that.mainToken; // "satisfies"
            spaceAfter = true;
            linebreaksAfter = noLineBreak;
        };
        that.visitChildren(this);
    }
    
    shared actual void visitSegmentOp(SegmentOp that)
            => writeBinaryOpWithSpecialSpaces(fWriter, this, that);
    
    shared actual void visitSelfExpression(SelfExpression that) {
        fWriter.writeToken {
            that.mainToken; // "this" or "super"
        };
    }
    
    shared actual void visitSequencedArgument(SequencedArgument that) {
        value elements = CeylonIterable(that.positionalArguments).sequence;
        "Empty sequenced argument not allowed"
        assert (nonempty elements);
        elements.first.visit(this);
        for (element in elements.rest) {
            fWriter.writeToken {
                ",";
                spaceBefore = false;
                spaceAfter = true;
                linebreaksBefore = noLineBreak;
            };
            element.visit(this);
        }
    }
    
    shared actual void visitSequencedType(SequencedType that) {
        // String* is a SequencedType
        writeOptionallyGrouped(fWriter, () {
                that.type.visit(this);
                fWriter.writeToken {
                    that.mainEndToken; // "*" or "+"
                    linebreaksBefore = noLineBreak;
                    linebreaksAfter = noLineBreak;
                    spaceBefore = false;
                    spaceAfter = 10;
                };
                return null;
            });
    }
    
    shared actual void visitSequenceEnumeration(SequenceEnumeration that) {
        value context = fWriter.writeToken {
            that.mainToken; // "{"
            spaceAfter = options.spaceAfterSequenceEnumerationOpeningBrace;
            indentAfter = 1;
        };
        that.sequencedArgument.visit(this);
        fWriter.writeToken {
            that.mainEndToken; // "}"
            context;
            spaceBefore = options.spaceBeforeSequenceEnumerationClosingBrace;
        };
    }
    
    shared actual void visitSequenceType(SequenceType that) {
        // String[] is a SequenceType
        writeOptionallyGrouped(fWriter, () {
                that.elementType.visit(this);
                fWriter.writeToken {
                    "["; // doesn’t seem like that token is in the AST anywhere
                    linebreaksBefore = noLineBreak;
                    linebreaksAfter = noLineBreak;
                    spaceBefore = false;
                    spaceAfter = false;
                };
                fWriter.writeToken {
                    that.mainEndToken; // "]"
                    linebreaksBefore = noLineBreak;
                    spaceBefore = false;
                };
                return null;
            });
    }
    
    shared actual void visitSimpleType(SimpleType that) {
        writeOptionallyGrouped(fWriter, () {
                that.visitChildren(this);
                return null;
            });
    }
    
    shared actual void visitSpecifiedArgument(SpecifiedArgument that) {
        value context = fWriter.openContext();
        if (exists identifier = that.identifier) {
            that.identifier.visit(this);
        }
        that.specifierExpression.visit(this);
        writeSemicolon(fWriter, that.mainEndToken, context);
    }
    
    shared actual void visitSpecifierExpression(SpecifierExpression that) {
        FormattingWriter.FormattingContext? context;
        if (exists mainToken = that.mainToken) {
            context = writeSpecifierMainToken(fWriter, mainToken, options);
        } else {
            context = null;
        }
        that.expression.visit(this);
        if (exists context) {
            fWriter.closeContext(context);
        }
    }
    
    shared actual void visitSpecifierStatement(SpecifierStatement that) {
        value context = fWriter.openContext();
        that.baseMemberExpression.visit(this);
        writeSpecifierMainToken(fWriter, "=", options); // I can’t find the "=" in the AST anywhere
        that.specifierExpression.visit(this);
        writeSemicolon(fWriter, that.mainEndToken, context);
    }
    
    shared actual void visitSpreadArgument(SpreadArgument that) {
        value context = fWriter.writeToken {
            that.mainToken; // "*"
            spaceAfter = false; // TODO option?
            linebreaksAfter = noLineBreak;
        };
        assert (exists context);
        that.expression.visit(this);
        fWriter.closeContext(context);
    }
    
    shared actual void visitSpreadOp(SpreadOp that)
            => writeSomeMemberOp(fWriter, that.mainToken);
    
    shared actual void visitStatement(Statement that) {
        value context = fWriter.openContext();
        that.visitChildren(this);
        if (exists mainEndToken = that.mainEndToken) {
            writeSemicolon(fWriter, mainEndToken, context);
        } else {
            // complex statements like loops, ifs, etc. don’t end in a semicolon
            fWriter.closeContext(context);
        }
    }
    
    shared actual void visitStringTemplate(StringTemplate that) {
        value literals = CeylonIterable(that.stringLiterals).sequence;
        value expressions = CeylonIterable(that.expressions).sequence;
        "String template must have at least one string literal"
        assert (nonempty literals);
        "String template must have exactly one more string literal than expressions"
        assert (literals.size == expressions.size + 1);
        variable Boolean? wantsSpace;
        if (exists expression = expressions.first) {
            wantsSpace = wantsSpecialSpaces { expression.term };
        } else {
            wantsSpace = null;
        }
        fWriter.writeToken {
            literals.first.mainToken;
            spaceBefore = 0;
            spaceAfter = wantsSpace else 0;
        };
        variable value i = 0;
        for (literal in literals.rest) {
            assert (exists expression = expressions[i++]);
            assert (exists previousWantsSpace = wantsSpace);
            Boolean? nextWantsSpace;
            if (exists nextExpression = expressions[i]) {
                nextWantsSpace = wantsSpecialSpaces { nextExpression.term };
            } else {
                nextWantsSpace = null;
            }
            expression.visit(this);
            fWriter.writeToken {
                literal.mainToken;
                spaceBefore = previousWantsSpace;
                spaceAfter = nextWantsSpace else 0;
            };
            wantsSpace = nextWantsSpace;
        }
    }
    
    shared actual void visitSwitchCaseList(SwitchCaseList that) {
        for (caseClause in CeylonIterable(that.caseClauses)) {
            visitCaseClause(caseClause);
        }
        if (exists elseClause = that.elseClause) {
            visitSwitchElseClause(elseClause);
        }
    }
    
    shared actual void visitSwitchClause(SwitchClause that) {
        fWriter.writeToken {
            that.mainToken; // "switch"
            spaceBefore = true;
            spaceAfter = true; // TODO option
            linebreaksAfter = noLineBreak;
        };
        value context = fWriter.writeToken {
            "("; // nowhere in the AST
            spaceAfter = false; // TODO option
            indentAfter = 1;
            linebreaksAfter = noLineBreak;
        };
        that.expression.visit(this);
        fWriter.writeToken {
            ")"; // not in the AST as well
            context;
            spaceBefore = false; // TODO option
            linebreaksBefore = noLineBreak;
            linebreaksAfter = 1..2;
        };
    }
    
    shared void visitSwitchElseClause(ElseClause that) {
        fWriter.writeToken {
            that.mainToken; // "else"
            linebreaksBefore = 1..1;
            linebreaksAfter = noLineBreak;
        };
        that.visitChildren(this);
    }
    
    shared actual void visitThenOp(ThenOp that) {
        that.leftTerm.visit(this);
        fWriter.writeToken {
            that.mainToken; // "then"
            indentBefore = 2;
            spaceBefore = true;
            spaceAfter = true;
        };
        that.rightTerm.visit(this);
    }
    
    shared actual void visitThrow(Throw that) {
        value context = fWriter.writeToken {
            that.mainToken; // "throw"
            spaceAfter = true;
            linebreaksAfter = noLineBreak;
        };
        assert (exists context);
        that.expression.visit(this);
        writeSemicolon(fWriter, that.mainEndToken, context);
    }
    
    shared actual void visitTryClause(TryClause that) {
        fWriter.writeToken {
            that.mainToken; // "try"
            spaceBefore = true;
            spaceAfter = true;
        };
        if (exists resources = that.resourceList) {
            resources.visit(this);
        }
        that.block.visit(this);
    }
    
    shared actual void visitTuple(Tuple that) {
        value context = fWriter.writeToken {
            that.mainToken; // "["
            spaceAfter = -1000;
            indentAfter = 1;
        };
        that.sequencedArgument?.visit(this); // warning: can be null for the empty tuple []
        fWriter.writeToken {
            that.mainEndToken; // "]"
            context;
            spaceBefore = -1000;
        };
    }
    
    shared actual void visitTupleType(TupleType that) {
        writeOptionallyGrouped(fWriter, () {
                value context = fWriter.writeToken {
                    that.mainToken; // "["
                    linebreaksAfter = noLineBreak;
                    spaceAfter = false;
                };
                value elements = CeylonIterable(that.elementTypes).sequence;
                if (exists first = elements.first) {
                    variable value innerContext = fWriter.openContext();
                    first.visit(this);
                    for (element in elements.rest) {
                        fWriter.writeToken {
                            ",";
                            linebreaksBefore = noLineBreak;
                            indentAfter = 1;
                            spaceBefore = false;
                            spaceAfter = true;
                            innerContext;
                        };
                        innerContext = fWriter.openContext();
                        element.visit(this);
                    }
                }
                fWriter.writeToken {
                    that.mainEndToken; // "]"
                    linebreaksBefore = noLineBreak;
                    spaceBefore = false;
                    context = context;
                };
                return null;
            });
    }
    
    shared actual void visitTypeAliasDeclaration(TypeAliasDeclaration that) {
        that.annotationList.visit(this);
        value context = fWriter.writeToken {
            that.mainToken; // "alias"
            spaceBefore = true;
            spaceAfter = true;
            linebreaksAfter = noLineBreak;
        };
        assert (exists context);
        that.identifier.visit(this);
        that.typeParameterList?.visit(this);
        that.typeConstraintList?.visit(this);
        that.typeSpecifier?.visit(this);
        writeSemicolon(fWriter, that.mainEndToken, context);
    }
    
    shared actual void visitTypeArgumentList(TypeArgumentList that) {
        writeTypeArgumentOrParameterList(fWriter, this, that, options);
    }
    
    shared actual void visitTypeConstraint(TypeConstraint that) {
        value context = fWriter.writeToken {
            that.mainToken; // "given"
            spaceAfter = true;
            indentBefore = options.indentBeforeTypeInfo;
            indentAfter = options.indentBeforeTypeInfo;
        };
        assert (exists context);
        that.identifier.visit(this);
        that.parameterList?.visit(this);
        that.caseTypes?.visit(this);
        that.satisfiedTypes?.visit(this);
        that.abstractedType?.visit(this);
        fWriter.closeContext(context);
    }
    
    shared actual void visitTypeConstraintList(TypeConstraintList that) {
        for (constraint in CeylonIterable(that.typeConstraints)) {
            fWriter.requireAtLeastLineBreaks(1);
            constraint.visit(this);
        }
    }
    
    shared actual void visitTypedDeclaration(TypedDeclaration that) {
        that.annotationList?.visit(this);
        that.type.visit(this);
        that.identifier.visit(this);
    }
    
    shared actual void visitTypeOperatorExpression(TypeOperatorExpression that) {
        that.term.visit(this);
        fWriter.writeToken {
            that.mainToken; // "is", "extends", "satisfies" or "of"
            spaceBefore = true;
            spaceAfter = true;
            linebreaksBefore = noLineBreak;
            linebreaksAfter = noLineBreak;
        };
        that.type.visit(this);
    }
    
    shared actual void visitTypeParameterList(TypeParameterList that) {
        writeTypeArgumentOrParameterList(fWriter, this, that, options);
    }
    
    shared actual void visitTypeParameterLiteral(TypeParameterLiteral that)
            => writeMetaLiteral(fWriter, this, that, "given");
    
    shared actual void visitTypeSpecifier(TypeSpecifier that) {
        fWriter.writeToken {
            that.mainToken; // "=>"
            spaceBefore = true;
            spaceAfter = true;
            linebreaksBefore = noLineBreak;
            indentAfter = 1;
        };
        that.type.visit(this);
    }
    
    shared actual void visitUnionType(UnionType that) {
        writeOptionallyGrouped(fWriter, () {
                value types = CeylonIterable(that.staticTypes).sequence;
                "Empty union type not allowed"
                assert (nonempty types);
                types.first.visit(this);
                for (type in types.rest) {
                    fWriter.writeToken {
                        "|";
                        linebreaksBefore = noLineBreak;
                        linebreaksAfter = noLineBreak;
                        spaceBefore = false;
                        spaceAfter = false;
                    };
                    type.visit(this);
                }
                return null;
            });
    }
    
    shared actual void visitValueIterator(ValueIterator that) {
        value context = fWriter.writeToken {
            that.mainToken; // "("
            spaceAfter = options.spaceAfterValueIteratorOpeningParenthesis;
            linebreaksAfter = noLineBreak;
        };
        that.variable.visit(this);
        that.specifierExpression.visit(this);
        fWriter.writeToken {
            that.mainEndToken; // ")"
            context;
            spaceBefore = options.spaceBeforeValueIteratorClosingParenthesis;
            linebreaksBefore = noLineBreak;
        };
    }
    
    shared actual void visitValueLiteral(ValueLiteral that)
            => writeMetaLiteral(fWriter, this, that, "value");
    
    shared actual void visitValueModifier(ValueModifier that) {
        if (exists mainToken = that.mainToken) {
            writeModifier(fWriter, mainToken);
        } else {
            // the variables in a for (x in xs, y in ys) apparently have a ValueModifier without token
        }
    }
    
    shared actual void visitVariable(Variable that) {
        that.annotationList?.visit(this);
        that.type.visit(this);
        that.identifier.visit(this);
        for (list in CeylonIterable(that.parameterLists)) {
            list.visit(this);
        }
        if (exists t = that.specifierExpression?.mainToken) {
            that.specifierExpression.visit(this);
        } else {
            /*
             ignore; for a condition like
                 if (exists something)
             (without a specifier expression), the compiler just adds the identifier as expression
             in which case we shouldn’t visit this “virtual” expression
             (see #27)
             */
        }
    }
    
    shared actual void visitVoidModifier(VoidModifier that) {
        if (exists token = that.mainToken) {
            writeModifier(fWriter, token);
        }
    }
    
    shared actual void visitWhileClause(WhileClause that) {
        fWriter.writeToken {
            that.mainToken; // "while"
            spaceAfter = options.spaceBeforeWhileOpeningParenthesis;
            linebreaksAfter = noLineBreak;
        };
        that.conditionList.visit(this);
        that.block.visit(this);
    }
    
    shared actual void visitWithinOp(WithinOp that) {
        that.lowerBound.visit(this);
        fWriter.writeToken {
            that.lowerBound is OpenBound then "<" else "<="; // no, there is no better way to get this information
            spaceBefore = true;
            spaceAfter = true;
        };
        that.term.visit(this);
        fWriter.writeToken {
            that.upperBound is OpenBound then "<" else "<=";
            spaceBefore = true;
            spaceAfter = true;
        };
        that.upperBound.visit(this);
    }
    
    //TODO eventually, this will be unneeded, as each visitSomeSubclassOfNode should be overwritten here.
    shared actual void visitAny(Node that) {
        if (that.mainToken exists || that.mainEndToken exists) {
            process.writeErrorLine("`` that.mainToken?.text else "" ``\t`` that.mainEndToken?.text else "" ``"); // breakpoint here
        }
        super.visitAny(that); // continue walking the tree
    }
    
    shared actual void destroy(Throwable? error) {
        fWriter.destroy(error);
        writer.destroy(error);
    }
}
