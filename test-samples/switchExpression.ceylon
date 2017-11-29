void testSwitchExpression() {
    function isVocal(Character c) => switch (c.lowercased) case ('a' | 'e' | 'i' | 'o' | 'u') true else false;
    function invertComparison(Comparison c) => switch (c)
        case (smaller) larger
        case (equal) equal
        case (larger) smaller;
    function specialOp(Integer op, Integer a, Integer b, Integer c) => switch (op)
        case (0)
            a + (c - b) / 2
        case (1)
            (a + b + c) / (a * b * c)
        case (2)
            c - 1
        else nothing;
    print(switch (true) case (true) "true");
}
