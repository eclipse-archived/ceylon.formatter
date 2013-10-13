"Options for the Ceylon formatter.
 
 The formatter requires an object satisfying [[FormattingOptions]].
 There are several ways in which you can obtain such an object:
 
 * Manually create one, defining each attribute yourself:
 
         object options extends FormattingOptions {
             indentMode = Spaces(4);
             // ...
         })
         FormattingVisitor(tokens, writer, options);
 
 * Read one from a file using [[FormattingFile]]:
 
         FormattingVisitor(tokens, writer, FormattingFile(filename));
 
 * Use the [[default options|defaultOptions]]:
 
         FormattingVisitor(tokens, writer, defaultOptions);
 
 * [[Combine|CombinedOptions]] existing `FormattingOptions` with manually created [[SparseFormattingOptions]]:
 
         object myOptions extends SparseFormattingOptions {
             indentMode = Mixed(Tabs(8), Spaces(4));
             // ...
         }
         FormattingVisitor(tokens, writer, CombinedOptions(defaultOptions, myOptions));"
// TODO implement FormattingFile
shared package ceylon.formatter.options;
