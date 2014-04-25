import ceylon.test {
    test
}
import ceylon.formatter.options {
    Spaces,
    Tabs,
    Mixed,
    parseIndentMode
}

test
void testIndentMode() {
    value spaces = Spaces(5);
    value tabs = Tabs(7);
    value mixed = Mixed(Tabs(9), Spaces(3));
    
    assert (exists parsedSpaces = parseIndentMode(spaces.string));
    assert (parsedSpaces == spaces);
    assert (exists parsedTabs = parseIndentMode(tabs.string));
    assert (parsedTabs == tabs);
    assert (exists parsedMixed = parseIndentMode(mixed.string));
    assert (parsedMixed == mixed);
}
