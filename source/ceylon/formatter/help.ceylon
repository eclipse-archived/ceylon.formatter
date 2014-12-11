import ceylon.formatter.options {
    SparseFormattingOptions,
    LineBreakStrategy,
    IndentMode
}
import ceylon.language.meta {
    annotations
}
import ceylon.language.meta.model {
    Attribute,
    Type,
    UnionType,
    ClassOrInterface
}

"Returns a help string for the given [[topic]],
 or [[null]] if no help is available for this topic."
shared String? help(topic) {
    "The requested help topic, or [[null]] for general help.
     
     Currently available:
     - `options`: A document list of all [[formatting options|ceylon.formatter.options::FormattingOptions]]."
    String? topic;
    
    switch (topic)
    case (null) {
        return
            "ceylon.formatter – a Ceylon module / program to format Ceylon source code.
             
             USAGE
             
                 ceylon run ceylon.formatter source
             
             or, if you’re worried about it breaking your source code (which shouldn’t happen –
             if anything bad happens, error recovery kicks in and the original file is restored)
             or you just want to test it out:
             
                 ceylon run ceylon.formatter source --to source-formatted
             
             You can also format multiple folders at the same time:
             
                 ceylon run ceylon.formatter source --and test-source --to formatted
             
             which will recreate the ‘source’ and ‘test-source’ folders inside the new ‘formatted’ folder.
             
             OPTIONS
             
             --help
                 Print this help message.
                 (--help=options prints help for the various options.)
             
             --version
                 Print version information. The first line is always just the module name and version
                 in the format that ‘ceylon run’ understands (“ceylon.formatter/x.y.z”), which might be
                 useful for scripts.
             
             --${option name}=${option value}
                 Set a formatting option. The most useful ones are:
                 
                 --maxLineLength
                     The maximum line length, or “unlimited”.
                 
                 --indentMode
                     The indentation mode. Syntax: “x spaces” or “y-wide tabs” or “mix x-wide tabs, y spaces”.
                 
                 --lineBreak
                     “lf”, “crlf”, or “os” for the operating system’s native line breaks.
                 
                 For a full list of options, see the output from ‘--help=options’
                 or the documentation of the FormattingOptions class.";
    }
    case ("options") {
        StringBuilder ret = StringBuilder();
        ret.append("The following options are available:");
        for (option in `SparseFormattingOptions`
            .getAttributes<SparseFormattingOptions,Anything,Nothing>()
            .filter((Attribute<SparseFormattingOptions,Anything,Nothing> element) {
                assert (exists c = element.container);
                return c == `SparseFormattingOptions`;
            })) {
            
            value optionDec = option.declaration;
            ret.append("\n\n");
            ret.append(optionDec.name);
            ret.append(": ");
            ret.append(formatType(option.type));
            `SparseFormattingOptions`.getDeclaredAttributes();
            for (line in annotations(`DocAnnotation`, optionDec)?.description?.lines else []) {
                ret.appendNewline();
                ret.append("    ");
                ret.append(line);
            }
        }
        return ret.string;
    }
    else {
        return null;
    }
}

String formatType(Type<Anything> type) {
    assert (nonempty partialTypes = collectPartialTypes(type));
    StringBuilder ret = StringBuilder();
    ret.append(partialTypes.first);
    for (partialType in partialTypes.rest) {
        if (partialType == partialTypes.last) {
            ret.append(" or ");
        } else {
            ret.append(", ");
        }
        ret.append(partialType);
    }
    return ret.string;
}

String[] collectPartialTypes(Type<Anything> type) {
    if (is UnionType<Anything> type) {
        return concatenate(*type.caseTypes.collect(collectPartialTypes));
    } else if (type.exactly(`Integer`)) {
        return ["Integer"];
    } else if (type.exactly(`Range<Integer>`)) {
        return ["Range<Integer> (‘x..y’)"];
    } else if (type.exactly(`IndentMode`)) {
        return ["IndentMode (‘x spaces’ or ‘y-wide tabs’ or ‘mix x-wide tabs, y spaces’)"];
    } else if (type.exactly(`LineBreakStrategy`)) {
        return ["LineBreakStrategy (‘default’)"];
    } else if (type.exactly(`{String*}`)) {
        return ["{String*} (‘abc def etc’)"];
    } else {
        assert (is ClassOrInterface<Anything> type);
        return type.caseValues.map((Anything element) {
                switch (element)
                case (null) { return null; }
                case (is Object) { return "‘``element.string``’"; }
            }).coalesced.sequence();
    }
}

shared void tmp() {
    print(help("options"));
}
