import ceylon.file { parsePath, File, Reader }
import ceylon.language.meta.model { Attribute, VariableAttribute }
import ceylon.language.meta.declaration { FunctionDeclaration }
import ceylon.language.meta { type }
"Reads a file with formatting options.
 
 The file consists of lines of key=value pairs or comments, like this:
 
     # Boss Man says the One True Style is evil
     blockBraceOnNewLine=true
     # 80 characters is not enough
     maxLineWidth=120
     intentMode=4 spaces
 
 As you can see, comment lines begin with a `#` (`\\{0023}`), and the value
 doesn't need to be quoted to contain spaces. Blank lines are also allowed.
 
 The keys are attributes of [[FormattingOptions]].
 The format of the value depends on the type of the key; to parse it, the
 function `parse<KeyType>(String)` is used (e.g [[ceylon.language::parseInteger]]
 for `Integer` values, [[ceylon.language:parseBoolean]] for `Boolean` values, etc.).
 
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
    FormattingOptions baseOptions = FormattingOptions()) {
    
    return variableFormattingFile(filename, baseOptions);
}

"An internal version of [[formattingFile]] that specifies a return type of [[VariableOptions]],
 which is needed for the internally performed recursion."
VariableOptions variableFormattingFile(String filename, FormattingOptions baseOptions) {
    
    if (is File file = parsePath(filename).resource) {
    	// read the file
    	Reader reader = file.Reader();
    	variable String[] lines = [];
    	while (exists line = reader.readLine()) {
    		lines = [line, *lines];
    	}
    	lines = lines.reversed; // since we had to read the file in reverse order
    	
    	// read included files
    	variable VariableOptions options = VariableOptions(baseOptions);
    	for (String line in lines) {
    		if (line.startsWith("include=")) {
    			options = variableFormattingFile(line.terminal(line.size - "include=".size), options);
    		}
    	}
    	
    	// read other options
    	for (String line in lines) {
    		if (!line.startsWith("#") && !line.startsWith("include=")) {
    			Integer? indexOfEquals = line.indexes((Character c) => c == '=').first;
    			"Line does not contain an equality sign"
    			assert (exists indexOfEquals);
    			String optionName = line.segment(0, indexOfEquals);
    			String optionValue = line.segment(indexOfEquals + 1, line.size - indexOfEquals - 1);
    			
    			Attribute<VariableOptions>? attribute = `VariableOptions`.getAttribute<VariableOptions>(optionName);
    			assert (exists attribute);
    			
    			String fullTypeString = attribute.type.string;
        		Integer? endOfPackageIndex = fullTypeString.inclusions("::").first;
        		assert (exists endOfPackageIndex);
        		String parseFunctionName = "parse" + fullTypeString[endOfPackageIndex+2...];
    			FunctionDeclaration? parseFunction =
    					`package ceylon.language`.getFunction(parseFunctionName)
    					else `package ceylon.formatter.options`.getFunction(parseFunctionName);
    			"Internal error - type not parsable"
    			assert (exists parseFunction);
    			
    			// TODO in the code below, instead of Anything, we need the exact actual type of attribute.
    			"Internal error - attribute not assignable"
    			assert (is VariableAttribute<VariableOptions, Anything> attribute);
    			
    			Anything parsedOptionValue = (parseFunction.apply<Anything, [String]>())(optionValue);
    			"Internal error - parser function of wrong type"
    			assert (type(parsedOptionValue) == attribute.type);
    			
    			attribute(options).set(parsedOptionValue);
    		}
    	}
    	
    	return options;
    } else {
    	throw Exception("File '``filename``' not found!");
    }
}