"A superclass of [[FormattingOptions]] where attributes are optional.
 
 The indented use is that users take a \"default\" `FormattingOptions` object and apply some
 `SparseFormattingOptions` on top of it using [[CombinedOptions]]; this way, they don't have
 to specify every option each time that they need to provide `FormattingOptions` somewhere."
shared abstract class SparseFormattingOptions() {
    
    "The indentation mode of the formatter."
    shared formal IndentMode? indentMode;
}

"A bundle of options for the formatter that control how the code should be formatted.
 
 See [[SparseFormattingOptions]] for a convenient way to refine FormattingOptions without
 having to specify each option explicitly."
// This class should do nothing more than narrow down all the parameters of
// SparseFormattingOptions to non-optional types. 
shared abstract class FormattingOptions() extends SparseFormattingOptions() {
    
    shared actual formal IndentMode indentMode;
}

"A combination of several [[FormattingOptions]], of which some may be [[Sparse|SparseFormattingOptions]].
 
 Each attribute is first searched in each of the [[decoration]] options, in the order of their appearance,
 and, if it isn't present in any of them, the attribute of [[foundation]] is used.
 
 In the typical use case, `foundation` will be some default options (e.g. [[defaultOptions]]), and 
 `decoration` will be one `SparseFormattingOptions` object created on the fly:
 
     FormattingVisitor(tokens, writer, CombinedOptions(defaultOptions,
         SparseFormattingOptions {
             indentMode = Mixed(Tabs(8), Spaces(4));
             // ....
         }));"
shared class CombinedOptions(FormattingOptions foundation, SparseFormattingOptions+ decoration) extends FormattingOptions() {
    
    shared actual IndentMode indentMode {
        for (options in decoration) {
            if (exists indentMode = options.indentMode) {
                return indentMode;
            }
        }
        return foundation.indentMode;
    }
}

"The default formatting options, as used in the `ceylon.language` module and the Ceylon SDK."
shared object defaultOptions extends FormattingOptions() {
    
    indentMode = Spaces(4);
}