import com.redhat.ceylon.compiler.typechecker.tree { Tree { ... }, Node, VisitorAdaptor, NaturalVisitor }
import org.antlr.runtime { TokenStream { la=\iLA }, Token }
import java.lang { Error, Exception }
import ceylon.file { Writer }
import ceylon.interop.java { CeylonIterable }
import ceylon.formatter.options { FormattingOptions, multiLine }

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
    FormattingOptions options) extends VisitorAdaptor() satisfies NaturalVisitor {
    
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
            fWriter.writeToken {
                that.mainEndToken; // ";"
                linebreaksBefore = noLineBreak;
                spaceBefore = false;
            };
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
        fWriter.writeToken {
            that.mainEndToken; // ";"
            linebreaksBefore = noLineBreak;
            spaceBefore = false;
            spaceAfter = true;
            context;
        };
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
        FormattingWriter.FormattingContext? context;
        if (exists token = that.mainToken) {
            context = fWriter.writeToken {
                token; // "{"
                indentAfter = Indent(1);
                linebreaksBefore = options.braceOnOwnLine then 1..1 else noLineBreak;
                linebreaksAfter = 1..2;
                spaceBefore = 10;
                spaceAfter = false;
            };
        } else {
            context = null;
        }
        for (Statement statement in CeylonIterable(that.statements)) {
            statement.visit(this);
            if (that.statements.size() > 1) {
                fWriter.requireAtLeastLineBreaks(1);
            }
        }
        if (exists token = that.mainEndToken) {
            fWriter.writeToken {
                token; // "}"
                linebreaksAfter = 0..3;
                spaceBefore = false;
                spaceAfter = 5;
                context;
            };
        }
    }
    
    shared actual void visitCaseClause(CaseClause that) {
        fWriter.writeToken {
            that.mainToken; // "case"
            spaceBefore = true;
            spaceAfter = true; // TODO option
            linebreaksAfter = noLineBreak;
        };
        value context = fWriter.writeToken {
            "("; // not in the AST – there’s a TODO in Ceylon.g that “we really should not throw away this token”;
                 // for now, we produce it out of thin air :)
            spaceAfter = false; // TODO option
            indentAfter = Indent(1);
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
    
    shared actual void visitClassLiteral(ClassLiteral that)
            => writeMetaLiteral(fWriter, this, that, "class");
    
    shared actual void visitConditionList(ConditionList that) {
        value context = fWriter.writeToken {
            that.mainToken; // "("
            linebreaksBefore = noLineBreak;
            indentAfter = Indent(1);
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
    
    shared actual void visitElementRange(ElementRange that) {
        // An ElementRange can be anything that goes into an index expression (except a single element),
        // that is, ...upper, lower..., lower..upper, and lower:length.
        // The ..., .. and : tokens are all lost because the grammar for this part kinda sucks
        // (TODO go bug someone about that),
        // so we just have to infer them from which fields are null and which aren’t
        // (for example, use : if there’s a length).
        Expression? lower = that.lowerBound;
        Expression? upper = that.upperBound;
        Expression? length = that.length;
        if (exists lower) {
            if (exists length) {
                "Range can’t have an upper bound when it has a length"
                assert (is Null upper);
                lower.visit(this);
                fWriter.writeToken {
                    ":";
                    spaceBefore = false;
                    spaceAfter = false;
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
                    spaceBefore = false;
                    spaceAfter = false;
                    linebreaksBefore = noLineBreak;
                    linebreaksAfter = noLineBreak;
                };
                upper.visit(this);
            } else {
                lower.visit(this);
                fWriter.writeToken {
                    "...";
                    spaceBefore = false;
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
                spaceAfter = false;
                linebreaksAfter = noLineBreak;
            };
            upper.visit(this);
        }
    }
    
    shared actual void visitElseClause(ElseClause that) {
        fWriter.writeToken {
            that.mainToken; // "else"
            linebreaksAfter = noLineBreak;
        };
        that.visitChildren(this);
    }
    
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
    
    shared actual void visitExistsOrNonemptyCondition(ExistsOrNonemptyCondition that) {
        fWriter.writeToken {
            that.mainToken; // "exists" or "nonempty"
            spaceAfter = true;
            linebreaksAfter = noLineBreak;
        };
        that.visitChildren(this);
    }
    
    shared actual void visitExtendedType(ExtendedType that) {
        fWriter.writeToken {
            that.mainToken; // "extends"
            indentBefore = Indent(1);
            linebreaksAfter = noLineBreak;
            spaceBefore = true;
            spaceAfter = true;
        };
        that.type.visit(this);
        that.invocationExpression.visit(this);
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
        that.comprehensionClause.visit(this);
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
                indentAfter = Indent(1);
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
    
    shared actual void visitIdentifier(Identifier that) {
        fWriter.writeToken {
            that.mainToken;
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
        that.comprehensionClause.visit(this);
    }
    
    shared actual void visitImport(Import that) {
        fWriter.writeToken {
            that.mainToken;
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
            indentAfter = Indent(1);
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
            spaceAfter = true;
            context;
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
                indentBefore = Indent(1);
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
    
    shared actual void visitModuleLiteral(ModuleLiteral that)
            => writeMetaLiteral(fWriter, this, that, "module");
    
    shared actual void visitNamedArgumentList(NamedArgumentList that) {
        value context = fWriter.writeToken {
            that.mainToken; // "{"
            spaceAfter = true;
            linebreaksAfter = 1..0;
            indentAfter = Indent(1);
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
    
    shared actual void visitNotOp(NotOp that) {
        fWriter.writeToken {
            that.mainToken; // "!"
            spaceAfter = false;
            linebreaksAfter = noLineBreak;
        };
        that.term.visit(this);
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
            indentAfter = Indent(1);
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
        if(exists openingParen, exists closingParen) {
            value context = fWriter.writeToken {
                that.mainToken; // "("
                linebreaksBefore = noLineBreak;
                indentAfter = Indent(1);
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
                linebreaksBefore = noLineBreak;
                linebreaksAfter = noLineBreak;
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
    
    shared actual void visitQualifiedMemberExpression(QualifiedMemberExpression that) {
        that.primary.visit(this);
        that.memberOperator.visit(this);
        that.identifier.visit(this);
    }
    
    shared actual void visitQualifiedType(QualifiedType that) {
        writeOptionallyGrouped(fWriter, void () {
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
    
    shared actual void visitRangeOp(RangeOp that) {
        that.leftTerm.visit(this);
        fWriter.writeToken {
            that.mainToken; // ".."
            linebreaksBefore = noLineBreak;
            linebreaksAfter = noLineBreak;
            spaceBefore = false;
            spaceAfter = false;
        };
        that.rightTerm.visit(this);
    }
    
    shared actual void visitReturn(Return that) {
        value context = fWriter.writeToken {
            that.mainToken; // "return"
            indentAfter = Indent(1);
            spaceAfter = true;
        };
        assert (exists context);
        that.expression.visit(this);
        writeSemicolon(fWriter, that.mainEndToken, context);
    }
    
    shared actual void visitSafeMemberOp(SafeMemberOp that)
            => writeSomeMemberOp(fWriter, that.mainToken);
    
    shared actual void visitSatisfiedTypes(SatisfiedTypes that) {
        value context = fWriter.writeToken {
            that.mainToken; // "satisfies"
            indentBefore = Indent(1);
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
            indentAfter = Indent(1);
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
        that.identifier?.visit(this);
        that.specifierExpression.visit(this);
        writeSemicolon(fWriter, that.mainEndToken, context);
    }
    
    shared actual void visitSpecifierExpression(SpecifierExpression that) {
        if (exists mainToken = that.mainToken) {
            writeSpecifierMainToken(fWriter, mainToken);
        }
        that.expression.visit(this);
    }
    
    shared actual void visitSpecifierStatement(SpecifierStatement that) {
        value context = fWriter.openContext();
        that.baseMemberExpression.visit(this);
        writeSpecifierMainToken(fWriter, "="); // I can’t find the "=" in the AST anywhere
        that.specifierExpression.visit(this);
        writeSemicolon(fWriter, that.mainEndToken, context);
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
        assert  (nonempty literals);
        "String template must have exactly more string literal than expressions"
        assert (literals.size == expressions.size + 1);
        literals.first.visit(this);
        variable value i = 0;
        for (literal in literals.rest) {
            assert (exists expression = expressions[i++]);
            expression.visit(this);
            literal.visit(this);
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
            indentAfter = Indent(1);
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
                        indentAfter = Indent(1);
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
    
    shared actual void visitTypeArgumentList(TypeArgumentList that) {
        value context = fWriter.openContext();
        fWriter.writeToken {
            that.mainToken; // "<"
            indentAfter = Indent(1);
            linebreaksAfter = noLineBreak;
            spaceBefore = false;
            spaceAfter = false;
        };
        value params = CeylonIterable(that.types).sequence;
        assert (nonempty params);
        params.first.visit(this);
        for (param in params.rest) {
            fWriter.writeToken {
                ",";
                spaceAfter = true;
                linebreaksAfter = options.typeParameterListLineBreaks;
            };
            param.visit(this);
        }
        fWriter.writeToken {
            that.mainEndToken; // ">"
            context;
            linebreaksBefore = noLineBreak;
            spaceBefore = false;
            optional = true; // an optionally grouped type might already have eaten the closing angle bracket
        };
        fWriter.closeContext(context);
    }
    
    shared actual void visitTypedDeclaration(TypedDeclaration that) {
        that.annotationList?.visit(this);
        that.type.visit(this);
        that.identifier.visit(this);
    }
    
    shared actual void visitTypeParameterLiteral(TypeParameterLiteral that)
            => writeMetaLiteral(fWriter, this, that, "given");
    
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
            // ignore; for a condition like
            //     if (exists something)
            // (without a specifier expression), the compiler just adds the identifier as expression
            // in which case we shouldn’t visit this “virtual” expression
            // (see #27)
        }
    }
    
    shared actual void visitVoidModifier(VoidModifier that) {
        writeModifier(fWriter, that.mainToken);
    }
    
    //TODO eventually, this will be unneeded, as each visitSomeSubclassOfNode should be overwritten here.
    shared actual void visitAny(Node that) {
        if (that.mainToken exists || that.mainEndToken exists) {
            process.writeErrorLine("``that.mainToken?.text else ""``\t``that.mainEndToken?.text else ""``"); // breakpoint here
        }
        super.visitAny(that); // continue walking the tree
    }
    
    shared void close() {
        fWriter.close();
        writer.close(null);
    }
}