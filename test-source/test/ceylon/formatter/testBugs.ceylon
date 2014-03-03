import ceylon.test { test }

void testBug(Integer number) => testFile("bugs/``number``");

test
shared void test27() {
    testBug(27);
}
