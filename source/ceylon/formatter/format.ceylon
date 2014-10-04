import ceylon.formatter.options {
    FormattingOptions
}
import com.redhat.ceylon.compiler.typechecker.tree {
    Node
}
import org.antlr.runtime {
    TokenStream
}
import ceylon.file {
    Writer
}

object stdoutWriter satisfies Writer {
    shared actual void close() => flush();
    shared actual void flush() {}
    shared actual void write(String string) {
        process.write(string);
    }
    shared actual void writeLine(String line) {
        process.writeLine(line);
    }
    shared actual void writeBytes({Byte*} bytes) {
        throw AssertionError("Can’t write bytes");
    }
}

"Format the given [[CompilationUnit|com.redhat.ceylon.compiler.typechecker.tree::Tree.CompilationUnit]]
 and write it to the given [[Writer]]."
shared void format(
    "A node that you want to format,
     e. g. a [[CompilationUnit|com.redhat.ceylon.compiler.typechecker.tree::Tree.CompilationUnit]]
     from the Ceylon compiler."
    Node node,
    "The options for the formatter. These dictate the line breaking strategy,
     the bracing style, the maximum line length, and much more.
     
     The default options are modeled after the `ceylon.language` module and the Ceylon SDK.
     You can adapt them through the named arguments syntax, keeping the default values of
     the options that you don’t want to change.
     
     You can also adapt any other `FormattingOptions` by using
     [[ceylon.formatter.options::SparseFormattingOptions]] and
     [[ceylon.formatter.options::combinedOptions]], like this:
     ~~~
     value myOptions = combinedOptions(bossOptions,
         SparseFormattingOptions {
             indentMode = Spaces(4); // I don’t care what the boss says, spaces rule
         });
     ~~~"
    FormattingOptions options = FormattingOptions(),
    "The [[Writer]] to which the formatted [[node]] is written.
     
     Defaults to standard output."
    Writer output = stdoutWriter,
    "An ANTLR Token Stream from which the `CompilationUnit` was parsed.
     This only makes sense if you got [[node]] from the Ceylon compiler,
     otherwise you should keep the default value `null`.
     
     Note that you probably do *not* want a [[org.antlr.runtime::CommonTokenStream]]
     (which is what you normally give to the compiler), because that skips comments.
     Use [[org.antlr.runtime::BufferedTokenStream]] instead."
    TokenStream? tokens = null,
    "The initial indentation to use.
     
     You probably shouldn’t use this when [[node]] is a `CompilationUnit`,
     but it’s useful when formatting other nodes."
    Integer initialIndentation = 0) {
    
    variable Throwable? error = null;
    try (formattingVisitor = FormattingVisitor(tokens, output, options, initialIndentation)) {
        node.visit(formattingVisitor);
    } catch (Throwable t) {
        error = t;
        throw t;
    } finally {
        output.destroy(error);
    }
}
