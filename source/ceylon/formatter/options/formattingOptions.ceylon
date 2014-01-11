import ceylon.collection { HashMap }
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

shared [FormattingOptions, String[]] commandLineOptions() {
    Map<String, String> shortcuts = HashMap { "w"->"maxLineLength" };
    
    SequenceBuilder<String> lines = SequenceBuilder<String>();
    SequenceBuilder<String> otherLines = SequenceBuilder<String>();
    variable String? partialLine = null;
    for (String option in process.arguments) {
        if (option.startsWith("--")) {
            String o = option[2...];
            if (o.contains('=')) {
                lines.append(o);
            } else {
                partialLine = o;
            }
        } else if (option.startsWith("-")) {
            if (exists longOption = shortcuts[option[1..1]]) {
                String o = longOption+option[2...];
                if (o.contains('=')) {
                    lines.append(o);
                } else {
                    partialLine = o;
                }
            }
            else {
                // TODO report the error somewhere?
                process.writeError("Unrecognized short option '``option[0..1]``'!");
            }
        } else if(exists p = partialLine){
            // merge '--option value' into '--option=value'
            lines.append(p + "=" + option);
            partialLine = null;
        } else {
            otherLines.append(option);
        }
    }
    return [parseFormattingOptions(lines.sequence, FormattingOptions()), otherLines.sequence];
}

"An internal version of [[formattingFile]] that specifies a return type of [[VariableOptions]],
 which is needed for the internally performed recursion."
VariableOptions variableFormattingFile(String filename, FormattingOptions baseOptions) {
    
    if (is File file = parsePath(filename).resource) {
        // read the file
        Reader reader = file.Reader();
        SequenceBuilder<String> linesBuilder = SequenceBuilder<String>();
        while (exists line = reader.readLine()) {
            linesBuilder.append(line);
        }
        String[] lines = linesBuilder.sequence;
        return parseFormattingOptions(lines, baseOptions);
    } else {
        throw Exception("File '``filename``' not found!");
    }
}
