import ceylon.collection {
    MutableMap,
    HashMap,
    MutableList,
    LinkedList
}
import ceylon.file {
    Reader,
    File,
    parsePath
}
import ceylon.formatter {
    help
}

"Reads a file with formatting options.
 
 The file consists of lines of key=value pairs or comments, like this:
 ~~~~plain
 # Boss Man says the One True Style is evil
 blockBraceOnNewLine=true
 # 80 characters is not enough
 maxLineWidth=120
 indentMode=4 spaces
 ~~~~
 As you can see, comment lines begin with a `#` (`\\{0023}`), and the value
 doesn't need to be quoted to contain spaces. Blank lines are also allowed.
 
 The keys are attributes of [[FormattingOptions]].
 The format of the value depends on the type of the key; to parse it, the
 function `parse<KeyType>(String)` is used (e.g [[ceylon.language::parseInteger]]
 for `Integer` values, [[ceylon.language::parseBoolean]] for `Boolean` values, etc.).
 
 A special option in this regard is `include`: It is not an attribute of
 `FormattingOptions`, but instead specifies another file to be loaded.
 
 The file is processed in the following order:
 
 1. First, load [[baseOptions]].
 2. Then, scan the file for any `include` options, and process any included files.
 3. Lastly, parse all other lines.
 
 Thus, options in the top-level file override options in included files."
shared FormattingOptions formattingFile(
    "The file to read"
    String filename,
    "The options that will be used if the file and its included files
     don't specify an option"
    FormattingOptions baseOptions = FormattingOptions())
        => combinedOptions(baseOptions, variableFormattingFile(filename, baseOptions));

Map<String,String> sugarOptions = HashMap { "-w"->"--maxLineLength", "--maxLineWidth"->"--maxLineLength" };
Map<String,Anything(VariableOptions)> presets = HashMap {
    "--allmanStyle" -> (void(VariableOptions options) => options.braceOnOwnLine = true)
};

shared [FormattingOptions, String[]] commandLineOptions(String[] arguments = process.arguments) {
    // first of all, the special cases --help and --version, which both cause exiting
    if (nonempty helpArguments = arguments.select((String argument) => argument.startsWith("--help"))) {
        for (helpArgument in helpArguments) {
            if (helpArgument.startsWith("--help=")) {
                value helpTopic = helpArgument["--help=".size...];
                if (exists topicHelp = help(helpTopic)) {
                    print(topicHelp);
                } else {
                    print("No help available for topic ‘``helpTopic``’.");
                }
            } else {
                print(help(null));
            }
        }
        process.exit(0);
    } else if (arguments.contains("--version")) {
        print(
            "`` `module`.name ``/`` `module`.version ``
             Copyright 2014-2017 Lucas Werkmeister and ceylon.formatter contributors
             Licensed under the Apache License, Version 2.0."
        );
        process.exit(0);
    }
    
    String[] splitArguments = expand(arguments.map((String s) {
                if (exists index = s.firstIndexWhere('='.equals)) {
                    return [s[... index-1], s[index+1 ...]];
                }
                return [s];
            }))
            .sequence();
    
    String? profileName;
    if (exists profileArgumentIndex = splitArguments.firstIndexWhere("--profile".equals)) {
        profileName = splitArguments[profileArgumentIndex + 1];
    } else {
        profileName = null;
    }
    
    variable FormattingOptions baseOptions = loadProfile(profileName else configProfileName() else "default");
    
    value options = VariableOptions(baseOptions);
    value remaining = LinkedList<String>();
    
    if (nonempty splitArguments) {
        variable Integer i = 0;
        while (i < splitArguments.size) {
            assert (exists option = splitArguments[i]);
            String optionName = (sugarOptions[option] else option)["--".size...];
            if (option == "--") {
                remaining.addAll(splitArguments[(i + 1) ...]);
                break;
            } else if (optionName == "profile") {
                i++; // skip profile name
            } else if (optionName.startsWith("no-")) {
                try {
                    parseFormattingOption(optionName["no-".size...], "false", options);
                } catch (ParseOptionException e) {
                    process.writeErrorLine("Option '``optionName["no-".size...]``' is not a boolean option and can’t be used as '``option``'!");
                } catch (UnknownOptionException e) {
                    remaining.add(option);
                }
            } else if (exists preset = presets[option]) {
                preset(options);
            } else if (exists optionValue = splitArguments[i + 1]) {
                try {
                    parseFormattingOption(optionName, optionValue, options);
                    i++;
                } catch (ParseOptionException e) {
                    // maybe it’s a boolean option
                    try {
                        parseFormattingOption(optionName, "true", options);
                    } catch (ParseOptionException f) {
                        if (optionValue.startsWith("-")) {
                            process.writeErrorLine("Missing value for option '``optionName``'!");
                        } else {
                            process.writeErrorLine(e.message);
                            i++;
                        }
                    }
                } catch (UnknownOptionException e) {
                    remaining.add(option);
                }
            } else {
                try {
                    // maybe it’s a boolean option…
                    parseFormattingOption(optionName, "true", options);
                } catch (ParseOptionException e) {
                    // …nope.
                    process.writeErrorLine("Missing value for option '``optionName``'!");
                } catch (UnknownOptionException e) {
                    remaining.add(option);
                }
            }
            i++;
        }
    }
    return [combinedOptions(FormattingOptions(), options), remaining.sequence()];
}

"An internal version of [[formattingFile]] that specifies a return type of [[VariableOptions]],
 which is needed for the internally performed recursion."
VariableOptions variableFormattingFile(String filename, SparseFormattingOptions baseOptions) {
    
    if (is File file = parsePath(filename).resource) {
        // read the file
        Reader reader = file.Reader();
        MutableMap<String,MutableList<String>> lines = HashMap<String,MutableList<String>>();
        while (exists line = reader.readLine()) {
            if (line.startsWith("#")) {
                continue;
            }
            if (exists i = line.firstIndexWhere('='.equals)) {
                String key = line[... i-1];
                String item = line[i+1 ...];
                if (exists appender = lines[key]) {
                    appender.add(item);
                } else {
                    lines[key] = LinkedList { item };
                }
            } else {
                // TODO report the error somewhere?
                process.writeError("Missing value for option '``line``'!");
            }
        }
        return parseFormattingOptions(lines.map((String->MutableList<String> option) => option.key -> option.item.sequence()), baseOptions);
    } else {
        throw Exception("File '``filename``' not found!");
    }
}

VariableOptions parseFormattingOptions({<String->{String*}>*} entries, SparseFormattingOptions baseOptions = FormattingOptions()) {
    // read included files
    variable VariableOptions options = VariableOptions(baseOptions);
    if (exists includes = entries.find((String->{String*} entry) => entry.key == "include")?.item) {
        for (include in includes) {
            options = variableFormattingFile(include, options);
        }
    }
    
    // read other options
    for (String->{String*} entry in entries.filter((String->{String*} entry) => entry.key != "include")) {
        String optionName = entry.key;
        assert (exists optionValue = entry.item.last);
        try {
            parseFormattingOption(optionName, optionValue, options);
        } catch (ParseOptionException e) {
            process.writeErrorLine(e.message);
        } catch (UnknownOptionException e) {
            try {
                parseLegacyFormattingOption(optionName, optionValue, options);
            } catch (ParseOptionException|UnknownOptionException e2) {
                process.writeErrorLine(e2.message);
            }
        }
    }
    
    return options;
}

throws (`class ParseOptionException`, "If the option can’t be parsed")
throws (`class UnknownOptionException`, "If the option is unknown")
void parseLegacyFormattingOption(String optionName, String optionValue, VariableOptions options) {
    switch (optionName)
    case ("spaceAfterTypeArgOrParamListComma") {
        if (exists option = parseBoolean(optionValue)) {
            options.spaceAfterTypeParamListComma = option;
            options.spaceAfterTypeArgListComma = option;
        } else {
            throw ParseOptionException("spaceAfterTypeArgOrParamListComma", optionValue);
        }
    }
    case ("forceSpaceAroundBinaryOp") {
        if (exists option = parseBoolean(optionValue)) {
            options.spaceOptionalAroundOperatorLevel = option then 0 else 3;
        } else {
            throw ParseOptionException("forceSpaceAroundBinaryOp", optionValue);
        }
    }
    case ("indentationAfterSpecifierExpressionStart") {
        // introduced by #37, obsoleted by #105
        switch (optionValue)
        case ("stack") {
            // current behavior, do nothing
        }
        case ("addIndentBefore") {
            // no longer supported; TODO: warning?
        }
        else {
            throw ParseOptionException("indentationAfterSpecifierExpressionStart", optionValue);
        }
    }
    else {
        throw UnknownOptionException(optionName);
    }
}

shared Range<Integer>? parseIntegerRange(String string) {
    value parts = string.split('.'.equals).sequence();
    if (parts.size == 2,
        exists first = parseInteger(parts[0]),
        exists last = parseInteger(parts[1] else "invalid")) {
        return first..last;
    }
    return null;
}
