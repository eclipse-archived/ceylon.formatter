"A superclass of [[FormattingOptions]] where attributes are optional.
 
 The indented use is that users take a \"default\" `FormattingOptions` object and apply some
 `SparseFormattingOptions` on top of it using [[CombinedOptions]]; this way, they don't have
 to specify every option each time that they need to provide `FormattingOptions` somewhere."
shared class SparseFormattingOptions(
    	indentMode = null) {
    
    "The indentation mode of the formatter."
    shared default IndentMode? indentMode;
}

"A bundle of options for the formatter that control how the code should be formatted.
 
 The default arguments are modeled after the `ceylon.language` module and the Ceylon SDK.
 You can refine them using named arguments:
 
     FormattingOptions {
         indentMode = Tabs(4);
         // modify some others
         // keep the rest
     }"
shared class FormattingOptions(
    	indentMode = Spaces(4)) extends SparseFormattingOptions() {
    
    shared actual default IndentMode indentMode;
}

"A combination of several [[FormattingOptions]], of which some may be [[Sparse|SparseFormattingOptions]].
 
 Each attribute is first searched in each of the [[decoration]] options, in the order of their appearance,
 and, if it isn't present in any of them, the attribute of [[foundation]] is used.
 
 In the typical use case, `foundation` will be some default options (e.g. `FormattingOptions()`), and 
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

"A subclass of [[FormattingOptions]] that makes its attributes [[variable]].
 
 For internal use only."
class VariableOptions(FormattingOptions baseOptions) extends FormattingOptions() {
    
    shared actual variable IndentMode indentMode = baseOptions.indentMode;
}