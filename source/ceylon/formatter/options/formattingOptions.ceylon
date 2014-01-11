import ceylon.collection { MutableMap, HashMap }
import ceylon.file { Reader, File, parsePath }
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
 
 Thus, options in the top-level file override options in included files.
 
 For another function which does exactly the same thing in a different way,
 see [[formattingFile_meta]]."
shared FormattingOptions formattingFile(
    "The file to read"
    String filename,
    "The options that will be used if the file and its included files
     don't specify an option"
    FormattingOptions baseOptions = FormattingOptions())
        => variableFormattingFile(filename, baseOptions);


Map<Character, String> shortcuts = HashMap { 'w'->"maxLineLength" };
Map<String, String> aliases = HashMap { "maxLineWidth"->"maxLineLength" };
Map<String, SparseFormattingOptions> presets = HashMap {
    "allmanStyle"->SparseFormattingOptions {
        braceOnOwnLine = true;
    }
};

shared [FormattingOptions, String[]] commandLineOptions() {
    variable FormattingOptions baseOptions = FormattingOptions();
    MutableMap<String, SequenceAppender<String>> lines = HashMap<String, SequenceAppender<String>>();
    SequenceBuilder<String> otherLines = SequenceBuilder<String>();
    SequenceBuilder<SparseFormattingOptions> usedPresets = SequenceBuilder<SparseFormattingOptions>();
    variable String? partialLine = null;
    for (String option in process.arguments) {
        String key;
        String item;
        if (option.startsWith("-"), exists char1 = option[1]) {
            if(exists p = partialLine) {
                // TODO report the error somewhere?
                process.writeError("Missing value for option '``p``'!");
            }
            String expanded;
            if (char1 == '-') { // option.startsWith("--")
                expanded = option[2...];
                if (exists preset = presets[expanded]) {
                    usedPresets.append(preset);
                    continue;
                }
            } else if (exists longOption = shortcuts[char1]) {
                expanded = longOption + option[2...];
            }
            else {
                // TODO report the error somewhere?
                process.writeError("Unrecognized short option '``option[0..1]``'!");
                continue;
            }
            if (exists i = expanded.indexes('='.equals).first) {
                key = expanded[...i-1];
                item = expanded[i+1...];
            } else {
                partialLine = expanded;
                continue;
            }
        } else if(exists p = partialLine){
            key = p;
            item = option;
            partialLine = null;
        } else {
            otherLines.append(option);
            continue;
        }
        if(exists appender = lines[(aliases[key] else key)]) {
            appender.append(item);
        } else {
            lines.put(aliases[key] else key, SequenceAppender([item]));
        }
    }
    if (nonempty seq = usedPresets.sequence) {
        baseOptions = CombinedOptions(baseOptions, *seq.reversed);
    }
    return [
    parseFormattingOptions(
        lines.map((String->SequenceAppender<String> option) => option.key->option.item.sequence), baseOptions),
    otherLines.sequence
    ];
}

"An internal version of [[formattingFile]] that specifies a return type of [[VariableOptions]],
 which is needed for the internally performed recursion."
VariableOptions variableFormattingFile(String filename, FormattingOptions baseOptions) {
    
    if (is File file = parsePath(filename).resource) {
        // read the file
        Reader reader = file.Reader();
        MutableMap<String, SequenceAppender<String>> lines = HashMap<String, SequenceAppender<String>>();
        while (exists line = reader.readLine()) {
            if(line.startsWith("#")) {
                continue;
            }
            if (exists i = line.indexes('='.equals).first) {
                String key = line[...i-1];
                String item = line[i+1...];
                if(exists appender = lines[key]) {
                    appender.append(item);
                } else {
                    lines.put(key, SequenceAppender([item]));
                }
            } else {
                // TODO report the error somewhere?
                process.writeError("Missing value for option '``line``'!");
            }
        }
        return parseFormattingOptions(lines.map((String->SequenceAppender<String> option) => option.key->option.item.sequence), baseOptions);
    } else {
        throw Exception("File '``filename``' not found!");
    }
}
