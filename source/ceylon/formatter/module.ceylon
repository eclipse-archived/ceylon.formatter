"""A formatter for the Ceylon programming language.
   
   # Command line usage
   
   Note: if the `ceylon format` plugin wasn’t installed by default
   in your distribution, you can add it by running:
   ~~~sh
   ceylon plugin install ceylon.formatter/1.3.0
   ~~~
   
   To format all Ceylon code in the `source` and `test-source` directories:
   ~~~sh
   ceylon format source test-source
   ~~~
   To format all Ceylon code in the `source` directory into the
   `source-formatted` directory:
   ~~~sh
   ceylon format source --to source-formatted
   ~~~
   To format all Ceylon code in the `source` and `test-source` directories
   into the `source-formatted` directory:
   ~~~sh
   ceylon format source --and test-source --to source-formatted
   ~~~
   (This results in two subdirectories `source` and `test-source`
   of `source-formatted`.)
   
   You can specify an arbitrary amount of these formatting commands:
   ~~~sh
   ceylon format \
           source --to source-formatted \
           test-source --to test-source-formatted
   ~~~
   (The line breaks are only included for clarity and not a part of
   the command line syntax.)
   
   If no formatting commands are present, the formatter operates in
   “pipe mode”, reading code from standard input and writing to
   standard output.
   
   ## Options
   
   You can specify formatting options using the following syntax:
   ~~~sh
   --optionName=optionValue
   # or
   --optionName optionValue
   ~~~
   
   For available option names, see [[ceylon.formatter.options::FormattingOptions]].
   The syntax of `optionValue` is:
   
   - for [[Boolean]] or [[Integer]] values, use a Ceylon-style literal (`1`, `true`)
   - for [[Range]] values, use a Ceylon-style range operator `x..y`
   - for [[IndentMode|ceylon.formatter.options::IndentMode]] values, see
     the documentation of [[parseIndentMode|ceylon.formatter.options::parseIndentMode]]
   - for [[Iterable]] values, list the individual elements, separated by spaces
   - for [[LineBreakStrategy|ceylon.formatter.options::LineBreakStrategy]],
     the only valid value is `default`
   - for enumerated types, use the name of one of the object cases (`lf`, `all`)
   
   # Library usage
   
   Use the [[format]] function to format any AST node.
   This can be a compilation unit (simply speaking, a complete file)
   or any other node.
   
   If the node was parsed from an existing file, don’t forget
   to pass the token stream to [[format]] –
   without the token stream, the formatter can’t obtain the comments,
   so they won’t be present in the formatted file.
   
   To construct [[FormattingOptions|ceylon.formatter.options::FormattingOptions]],
   usage of named arguments is highly recommended:
   ~~~ceylon
   FormattingOptions {
       indentMode = Spaces(8);
       maxLineLength = 80;
   }
   ~~~
   You can also use [[SparseFormattingOptions|ceylon.formatter.options::SparseFormattingOptions]]
   and [[combinedOptions|ceylon.formatter.options::combinedOptions]] to compose several sets
   of options, like this:
   ~~~ceylon
   combinedOptions {
       baseOptions = companyWideOptions;
       SparseFormattingOptions {
           indentMode = Spaces(1); // our department has very small screens :-(
       }
   }
   ~~~"""
by ("Lucas Werkmeister <mail@lucaswerkmeister.de>")
license ("https://www.apache.org/licenses/LICENSE-2.0.html")
native ("jvm")
module ceylon.formatter "1.3.0" {
    shared import java.base "7";
    shared import com.redhat.ceylon.typechecker "1.3.0";
    shared import com.redhat.ceylon.common "1.3.0";
    shared import com.redhat.ceylon.cli "1.3.0";
    shared import ceylon.file "1.3.0";
    import ceylon.interop.java "1.3.0";
    import ceylon.collection "1.3.0";
}
