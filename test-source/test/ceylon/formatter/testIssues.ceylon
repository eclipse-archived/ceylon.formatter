import ceylon.test {
    test
}

void testIssue(Integer number, String? variant = null) {
    if (exists variant) {
        testFile("issues/``number``_``variant``");
    } else {
        testFile("issues/``number``");
    }
}

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

test
shared void test37Stack() {
    testIssue(37, "stack");
}

test
shared void test37AddIndentBefore() {
    testIssue(37, "addIndentBefore");
}

test
shared void test39() {
    testIssue(39);
}

test
shared void test41() {
    testIssue(41);
}

test
shared void test40() {
    testIssue(40);
}
