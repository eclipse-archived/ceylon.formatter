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

test
shared void test47() {
    testIssue(47);
}

test
shared void test49() {
    testIssue(49);
}

test
shared void test52() {
    testIssue(52);
}

test
shared void test54() {
    testIssue(54);
}

test
shared void test56() {
    testIssue(56);
}

test
shared void test59() {
    testIssue(59);
}

test
shared void test61() {
    testIssue(61);
}

test
shared void test66() {
    testIssue(66);
}

test
shared void test69() {
    testIssue(69);
}

test
shared void test77() {
    testIssue(77);
}

test
shared void test70() {
    testIssue(70);
}

test
shared void test81() {
    testIssue(81);
}

test
shared void test83() {
    testIssue(83);
}

test
shared void test86_fewLineBreaks() {
    testIssue(86, "fewLineBreaks");
}

test
shared void test86_manyLineBreaks() {
    testIssue(86, "manyLineBreaks");
}

test
shared void test90() {
    testIssue(90);
}

test
shared void test99() {
    testIssue(99);
}

test
shared void test102() {
    testIssue(102);
}
