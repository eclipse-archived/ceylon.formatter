import ceylon.test {
    test
}
import ceylon.formatter.options {
    commandLineOptions
}

test
shared void testCommandLineOptions() {
    value result = commandLineOptions(["-w=80", "--allmanStyle", "--spaceBeforeParamListOpeningParen", "source/myFile.ceylon"]);
    value options = result[0];
    value remaining = result[1];
    assert (options.maxLineLength == 80);
    assert (options.braceOnOwnLine);
    assert (options.spaceBeforeParamListOpeningParen);
    assert (remaining == ["source/myFile.ceylon"]);
}
