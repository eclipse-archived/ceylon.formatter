import java.lang {
    JString=String
}
import com.redhat.ceylon.common.config {
    CeylonConfig {
        getConfig=get
    }
}

shared FormattingOptions configOptions() {
    value config = getConfig();
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
