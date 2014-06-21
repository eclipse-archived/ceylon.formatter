import ceylon.test {
    test,
    assertEquals
}
import ceylon.file {
    parsePath
}
import ceylon.formatter {
    commonRoot
}

test
void testCommandLineFiles() {
    value testCases = {
        [{ "a/b/c", "a/c" }, "a"],
        [{ "a/b/c" }, "a/b/c"],
        [{ "/a/b/c", "/a/b/c/d" }, "/a/b/c"],
        [{ "/a/b/c", "/x/y/z" }, "/"],
        [{ "a/b/c/d/e", "a/b/c/d/f", "a/b/x/d/e" }, "a/b"]
    };
    for (testCase in testCases) {
        assert (nonempty paths = testCase[0].collect(parsePath));
        value actual = commonRoot(paths);
        value expected = parsePath(testCase[1]);
        assertEquals(actual, expected, testCase.string);
    }
}
