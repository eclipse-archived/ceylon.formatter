/********************************************************************************
 * Copyright (c) 2011-2017 Red Hat Inc. and/or its affiliates and others
 *
 * This program and the accompanying materials are made available under the 
 * terms of the Apache License, Version 2.0 which is available at
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * SPDX-License-Identifier: Apache-2.0 
 ********************************************************************************/
"A formatter for the Ceylon programming language.
 
 The main class of this package is [[FormattingVisitor]], which visits an
 AST [[org.eclipse.ceylon.compiler.typechecker.tree::Node]] (typically
 a [[CompilationUnit|org.eclipse.ceylon.compiler.typechecker.tree::Tree.CompilationUnit]])
 and writes it out to a [[java.io::Writer]]. See the `ceylon.formatter.options` package on how
 to influence the format of the written code."
shared package ceylon.formatter;
