"A formatter for the Ceylon programming language.
 
 The main class of this package is [[FormattingVisitor]], which visits an
 AST [[com.redhat.ceylon.compiler.typechecker.tree::Node]] (typically
 a [[CompilationUnit|com.redhat.ceylon.compiler.typechecker.tree::Tree.CompilationUnit]])
 and writes it out to a [[java.io::Writer]]. See the `ceylon.formatter.options` package on how
 to influence the format of the written code."
shared package ceylon.formatter;
