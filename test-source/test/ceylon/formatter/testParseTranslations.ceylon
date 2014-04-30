import ceylon.test {
    test
}
import ceylon.formatter {
    parseTranslations
}

test
void testParseTranslations() {
    value testCases = {
        "source" -> { ["source"] -> "source" },
        "source --to source-formatted" -> { ["source"] -> "source-formatted" },
        "source --to source-formatted otherSource" -> { ["source"] -> "source-formatted", ["otherSource"] -> "otherSource" },
        "source --and test-source --to formatted" -> { ["source", "test-source"] -> "formatted" },
        "source --to source-formatted test-source --to test-source-formatted" -> { ["source"] -> "source-formatted", ["test-source"] -> "test-source-formatted" }
    };
    for (testCase in testCases) {
        value actual = parseTranslations(testCase.key.split().sequence);
        value expected = testCase.item.sequence;
        assert (actual == expected);
    }
}
