import ceylon.test {
    test
}
import ceylon.formatter.options {
    commandLineOptions,
    singleLine
}

test
shared void testCommandLineOptions() {
    value result = commandLineOptions(["-w=80", "--allmanStyle", "--spaceBeforeParamListOpeningParen", "source/myFile.ceylon", "--importStyle", "singleLine"]);
    value options = result[0];
    value remaining = result[1];
    assert (options.maxLineLength == 80);
    assert (options.braceOnOwnLine);
    assert (options.spaceBeforeParamListOpeningParen);
    assert (remaining == ["source/myFile.ceylon"]);
    assert (options.importStyle == singleLine);
}
