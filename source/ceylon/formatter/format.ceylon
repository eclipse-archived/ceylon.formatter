import ceylon.formatter.options {
    FormattingOptions
}
import com.redhat.ceylon.compiler.typechecker.tree {
    Tree {
        CompilationUnit
    }
}
import org.antlr.runtime {
    TokenStream
}
import ceylon.file {
    Writer
}

object stdoutWriter satisfies Writer {
    shared actual void destroy() => flush();
    shared actual void flush() {}
    shared actual void write(String string) {
        process.write(string);
    }
    shared actual void writeLine(String line) {
        process.writeLine(line);
    }
}

"Format the given [[CompilationUnit]] and write it to the given [[Writer]]."
shared void format(
    "A [[CompilationUnit]], e. g. from the Ceylon compiler."
    CompilationUnit compilationUnit,
    "The options for the formatter. These dictate the line breaking strategy,
     the bracing style, the maximum line length, and much more.
     
     The default options are modeled after the `ceylon.language` module and the Ceylon SDK.
     You can adapt them through the named arguments syntax, keeping the default values of
     the options that you don’t want to change.
     
     You can also adapt any other `FormattingOptions` by using
     [[ceylon.formatter.options::SparseFormattingOptions]] and
     [[ceylon.formatter.options::CombinedOptions]], like this:
     ~~~
     value myOptions = CombinedOptions(bossOptions,
         SparseFormattingOptions {
             indentMode = Spaces(4); // I don’t care what the boss says, spaces rule
         });
     ~~~"
    FormattingOptions options = FormattingOptions(),
    "The [[Writer]] to which the formatted [[compilationUnit]] is written.
     
     Defaults to standard output."
    Writer output = stdoutWriter,
    "An ANTLR Token Stream from which the `CompilationUnit` was parsed.
     This only makes sense if you got [[compilationUnit]] from the Ceylon compiler,
     otherwise you should keep the default value `null`.
     
     Note that you probably do *not* want a [[org.antlr.runtime::CommonTokenStream]]
     (which is what you normally give to the compiler), because that skips comments.
     Use [[org.antlr.runtime::BufferedTokenStream]] instead."
    TokenStream? tokens = null)
        => compilationUnit.visit(FormattingVisitor(tokens, output, options));
