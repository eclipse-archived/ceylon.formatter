import ceylon.test { test }

void testIssue(Integer number) => testFile("issues/``number``");

test
shared void test27() {
    testIssue(27);
}

test
shared void test30() {
    testIssue(30);
}

test
shared void test38() {
    testIssue(38);
}

test
shared void test36() {
    testIssue(36);
}
