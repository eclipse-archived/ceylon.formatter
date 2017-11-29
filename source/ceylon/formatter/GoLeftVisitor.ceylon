/********************************************************************************
 * Copyright (c) 2011-2017 Red Hat Inc. and/or its affiliates and others
 *
 * This program and the accompanying materials are made available under the 
 * terms of the Apache License, Version 2.0 which is available at
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * SPDX-License-Identifier: Apache-2.0 
 ********************************************************************************/
import org.eclipse.ceylon.compiler.typechecker.tree {
    VisitorAdaptor,
    Tree {
        ...
    }
}

"A visitor that doesn’t descend into terms, but instead only moves left."
abstract class GoLeftVisitor() extends VisitorAdaptor() {
    
    shared actual void visitBaseMemberOrTypeExpression(BaseMemberOrTypeExpression that)
            => that.identifier.visit(this);
    
    shared actual void visitBinaryOperatorExpression(BinaryOperatorExpression that)
            => that.leftTerm.visit(this);
    
    shared actual void visitElementRange(ElementRange that)
            => that.lowerBound?.visit(this);
    
    shared actual void visitEntryOp(EntryOp that)
            => that.leftTerm.visit(this);
    
    shared actual void visitIndexExpression(IndexExpression that)
            => that.primary.visit(this);
    
    shared actual void visitInvocationExpression(InvocationExpression that)
            => that.primary.visit(this);
    
    shared actual void visitNotOp(NotOp that) {}
    
    shared actual void visitObjectDefinition(ObjectDefinition that) {}
    
    shared actual void visitRangeOp(RangeOp that)
            => that.leftTerm.visit(this);
    
    shared actual void visitSpreadOp(SpreadOp that) {}
}
