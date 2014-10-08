"Options for the Ceylon formatter.
 
 The formatter requires an object satisfying [[FormattingOptions]].
 There are several ways in which you can obtain such an object:
 
 * Manually create one, defining each attribute yourself:
 
         FormattingVisitor(tokens, writer, FormattingOptions {
             indentMode = Spaces(4);
             // ...
         });
 
 * Read one from a file using [[formattingFile]]:
 
         FormattingVisitor(tokens, writer, formattingFile(filename));
 
 * Use the default options:
 
         FormattingVisitor(tokens, writer, FormattingOptions());
 
 * [[Combine|combinedOptions]] existing `FormattingOptions` with manually created [[SparseFormattingOptions]]:
 
         FormattingVisitor(tokens, writer, combinedOptions(defaultOptions, SparseFormattingOptions {
             indentMode = Mixed(Tabs(8), Spaces(4));
             // ...
         }));"
shared package ceylon.formatter.options;
