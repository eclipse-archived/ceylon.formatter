import java.lang {
    JString=String
}
import com.redhat.ceylon.common.config {
    CeylonConfig,
    ConfigFinder,
    ConfigWriter
}
import java.io {
    JFile=File
}
import ceylon.language.meta.declaration {
    ValueDeclaration
}

CeylonConfig findConfig(String profile, Boolean inherit, String baseDir) {
    value configFinder = ConfigFinder("``profile``.format", "ceylon.format");
    CeylonConfig config;
    if (inherit) {
        config = configFinder.loadDefaultConfig(JFile(baseDir));
    } else {
        config = configFinder.loadFirstConfig(JFile(baseDir));
    }
    return config;
}

"""Loads formatting options from the given profile.
   
   A profile is a file with the name
   
       "``profile``.format"
   
   next to the regular Ceylon config file. It contains
   formatting options in a `formatter` section, like this:
   
       [formatter]
       indentMode = 4 spaces
       braceOnOwnLine = false
   
   If [[inherit]] is [[true]], options from the profile file
   in the current directory take precedence over options
   from the profile file in the user and system-wide configuration
   directories (as per the default Ceylon configuration mechanism);
   otherwise, only the options from the profile file itself are used."""
shared FormattingOptions loadProfile(profile = "default", inherit = true, baseDir = ".") {
    """The profile name.
       
       The options are loaded from a configuration file with the name
       
           "``profile``.format"
       
       using the normal configuration file lookup mechanism
       (that is, options are inherited from the user and system-wide
       configuration in a file with the same name)."""
    see (`function configProfileName`)
    String profile;
    """Whether to inherit options from the user and system-wide configuration
       or not.
       
       By default, options are inherited; however, certain users (for example,
       an IDE) might want to disable this."""
    Boolean inherit;
    "The base directory (e. g., the project directory.)
     
     (The parent of the `.ceylon` directory, *not* that
     directory itself!)"
    String baseDir;
    
    value config = findConfig(profile, inherit, baseDir);
    if (config.isSectionDefined("formatter")) {
        return combinedOptions(FormattingOptions(), parseFormattingOptions {
                for (JString key in assertNonnulls(config.getOptionNames("formatter").array))
                    key.string -> assertNonempty(config.getOptionValues("formatter.``key``").array.map((JString? s) {
                                assert (exists s);
                                return s.string;
                            }))
            });
    } else {
        return FormattingOptions();
    }
}

"Saves formatting options to the given profile.
 
 For more informations on profiles, see the
 [[loadProfile]] documentation."
see (`function loadProfile`)
shared void saveProfile(profile, name = "default", baseDir = ".", relativePath = ".ceylon/``name``.format") {
    "The formatting options to save.
     
     (Only non-[[null]] options will be saved.)"
    SparseFormattingOptions profile;
    "The profile name."
    String name;
    "The base directory (e. g., the project directory.)
     
     (The parent of the `.ceylon` directory, *not* that
     directory itself!)"
    String baseDir;
    "The relative path of the file name.
     
     (The relative path from `baseDir`, defaults
     to `.ceylon/{profile}.format`)"
    String relativePath;
    
    value config = findConfig(name, false, baseDir);
    for (declaration in `class SparseFormattingOptions`.declaredMemberDeclarations<ValueDeclaration>()) {
        String optionName = declaration.name;
        value optionValue = declaration.memberGet(profile);
        if (exists optionValue) {
            String string;
            if (is {Object*} optionValue, !optionValue is Range<Integer>) {
                string = " ".join(optionValue.map(Object.string));
            } else {
                string = optionValue.string;
            }
            config.setOption("formatter.``optionName``", string);
        }
    }
    ConfigWriter.instance().write(config, JFile(baseDir, relativePath));
}

"Loads the profile name from the Ceylon configuration
 (key `formattool.profile`)."
see (`function loadProfile`)
shared String? configProfileName()
        => CeylonConfig.get("formattool.profile");

Iterable<T,Absent> assertNonnulls<T, Absent>(Iterable<T?,Absent> it)
        given Absent satisfies Null
        => { for (t in it) assertNonnull(t) };
T assertNonnull<T>(T? t) {
    assert (exists t);
    return t;
}
{T+} assertNonempty<T>({T*} it) {
    assert (nonempty seq = it.sequence());
    return seq;
}
