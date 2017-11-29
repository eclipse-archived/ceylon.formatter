import ceylon.test {
    assertEquals,
    test
}
import ceylon.formatter {
    parseTranslations
}

test
shared void testParseTranslations() {
    {<String->{<String[]->String>+}>+} testCases = {
        "source" -> { ["source"] -> "source" },
        "source --to source-formatted" -> { ["source"] -> "source-formatted" },
        "source --to source-formatted otherSource" -> { ["source"] -> "source-formatted", ["otherSource"] -> "otherSource" },
        "source --and test-source --to formatted" -> { ["source", "test-source"] -> "formatted" },
        "source --to source-formatted test-source --to test-source-formatted" -> { ["source"] -> "source-formatted", ["test-source"] -> "test-source-formatted" }
    };
    for (testCase in testCases) {
        assertEquals {
            expected = testCase.item.sequence();
            actual = parseTranslations(testCase.key.split().sequence());
        };
    }
}
