import java.lang {
    JString=String
}
import com.redhat.ceylon.common.config {
    ConfigFinder
}
import java.io {
    JFile=File
}

shared FormattingOptions configOptions() {
    value config = ConfigFinder("format.default", "ceylon.format").loadDefaultConfig(JFile("."));
    if (config.isSectionDefined("formatter")) {
        return parseFormattingOptions {
            for (JString key in assertNonnulls(config.getOptionNames("formatter").array))
                key.string->assertNonempty(config.getOptionValues("formatter.``key``").array.map((JString? s) {
                            assert (exists s);
                            return s.string;
                        }))
        };
    } else {
        return FormattingOptions();
    }
}

Iterable<T,Absent> assertNonnulls<T,Absent>(Iterable<T?,Absent> it)
        given Absent satisfies Null
        => { for (t in it) t else nothing };
{T+} assertNonempty<T>({T*} it) {
    assert (nonempty seq = it.sequence());
    return seq;
}
