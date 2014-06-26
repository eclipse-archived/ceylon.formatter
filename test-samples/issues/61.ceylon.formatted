void testIssue61_fun(String arg(String a)) {}
void testIssue61_fun2(void arg(String a)) {}
void testIssue61() {
    testIssue61_fun { function arg(String a) => a; };
    testIssue61_fun { String arg(String a) => a; };
    testIssue61_fun2 { void arg(String a) => print(a); };
    testIssue61_fun { function arg(String a) { return a; } };
    testIssue61_fun { String arg(String a) { return a; } };
    testIssue61_fun2 { void arg(String a) { print(a); } };
    testIssue61_fun {
        function arg(String a) {
            return a;
        }
    };
    testIssue61_fun {
        String arg(String a) {
            return a;
        }
    };
    testIssue61_fun2 {
        void arg(String a) {
            print(a);
        }
    };
}
