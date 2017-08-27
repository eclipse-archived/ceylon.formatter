import com.redhat.ceylon.common.tool {
    Tool,
    description,
    description__SETTER,
    option__SETTER,
    optionArgument__SETTER,
    rest__SETTER,
    remainingSections,
    summary
}
import com.redhat.ceylon.common.tools {
    CeylonTool
}

import java.lang {
    JString=String
}
import java.util {
    List,
    Collections
}

summary ("Formats Ceylon source code")
description ("    ceylon format source
              
              or, if you're worried about it breaking your source code (which shouldn't happen - if anything bad happens, error recovery kicks in and the original file is restored) or you just want to test it out:
              
                  ceylon format source --to source-formatted
              
              You can also format multiple folders at the same time:
              
                  ceylon format source --and test-source --to formatted
              
              which will recreate the `source` and `test-source` folders inside the new `formatted` folder.")
remainingSections ("## Other options
                    
                    --${option name}=${option value}
                    
                        Set a formatting option. The most useful ones are:
                        
                        --maxLineLength
                            The maximum line length, or `unlimited`.
                        
                        --indentMode
                            The indentation mode. Syntax: `x spaces` or `y-wide tabs` or `mix x-wide tabs, y spaces`.
                        
                        --lineBreak
                            `lf`, `crlf`, or `os` for the operating system's native line breaks.
                        
                        For a full list of options, see the output from `--help=options` or the documentation of the FormattingOptions class.")
shared class CeylonFormatTool() satisfies Tool {
    
    rest__SETTER
    shared variable List<JString> args = Collections.emptyList<JString>();
    
    option__SETTER { longName = "help"; }
    optionArgument__SETTER { longName = "help"; }
    description__SETTER ("Print this help message.
                          (--help=options prints help for the various options.)")
    shared variable JString? help = null;
    
    option__SETTER { longName = "version"; }
    description__SETTER ("Print version information.
                          The first line is always just the module name and version in the format that `ceylon run` understands (`ceylon.formatter/x.y.z`), which might be useful for scripts.")
    shared variable Boolean version = false;
    
    shared actual void run() => package.run(concatenate(
            { *args }.collect(JString.string),
            emptyOrSingleton(
                switch (help?.string)
                    case (null) null
                    case ("") "--help"
                    else "--help=`` help?.string else "options" ``"
            ),
            emptyOrSingleton(version then "--version")
        ));
    
    shared actual void initialize(CeylonTool? ceylonTool) {}
}
