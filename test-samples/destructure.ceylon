void testDestructureStatementsValue() {
    value [a, b, c] = [1, 2.0, '3'];
    value [Integer x, Float y, Character z] = [a, b, c];
    value [init, *others] = [0, *(1..runtime.maxIntegerValue)];
    value [String first, String *rest] = ["executableName", *process.arguments];
    value m->n = true->"true";
    value Boolean o -> String p = m->n;
    value [e, [f, g], h->i, *j] = [0, [1, 2], 3->4];
    value [q, [Integer r, Integer s], Integer t -> Integer u, *v] = [0, [1, 2], 3->4];
}
void testDestructureStatementsLet() {
    let (var = 1);
    let (
        [a, b, c] = [1, 2.0, '3'],
        [Integer x, Float y, Character z] = [a, b, c],
        [init, *others] = [0, *(1..runtime.maxIntegerValue)],
        [String first, String *rest] = ["executableName", *process.arguments],
        m->n = true->"true",
        Boolean o -> String p = m->n,
        [e, [f, g], h->i, *j] = [0, [1, 2], 3->4],
        [q, [Integer r, Integer s], Integer t -> Integer u, *v] = [0, [1, 2], 3->4]
    );
}
void testDestructureFor() {
    for ([a, b, c] in [[1, 2.0, '3']]) {
        for ([Integer x, Float y, Character z] in [[a, b, c]]) {
            for ([init, *others] in [[0, *(1..runtime.maxIntegerValue)]]) {
                for ([String first, String *rest] in [["executableName", *process.arguments]]) {
                    for (m->n in [true->"true"]) {
                        for (Boolean o -> String p in [m->n]) {
                        }
                    }
                }
            }
        }
    }
}
void testDestructureExists() {
    if (exists [a, b, c] = { [1, 2.0, '3'] }.cycled.rest.first) {
        if (exists [Integer x, Float y, Character z] = { [a, b, c] }.cycled.rest.first) {
            if (exists [init, *others] = [0, *(1..runtime.maxIntegerValue)]) {
                if (exists [String first, String *rest] = ["executableName", *process.arguments]) {
                    if (exists m->n = { true->"true" }.cycled.rest.first) {
                        if (exists Boolean o -> String p = { m->n }.cycled.rest.first) {
                        }
                    }
                }
            }
        }
    }
}
void testDestructureNonempty() {
    if (nonempty [first, *rest] = process.arguments) {}
    if (nonempty [String first2, String *rest2] = process.arguments) {}
}
void testDestructureLet() {
    value v = let ([a, b, c] = [1, 2.0, '3'],
        [Integer x, Float y, Character z] = [a, b, c],
        [init, *others] = [0, *(1..runtime.maxIntegerValue)],
        [String first, String *rest] = ["executableName", *process.arguments],
        m->n = true->"true",
        Boolean o -> String p = m->n)
        nothing;
}
void testDestructureComprehensions() {
    value v = {
        for ([a, b, c] in [[1, 2.0, '3']])
            for ([Integer x, Float y, Character z] in [[a, b, c]])
                for ([init, *others] in [[0, *(1..runtime.maxIntegerValue)]])
                    for ([String first, String *rest] in [["executableName", *process.arguments]])
                        for (m->n in [true->"true"])
                            for (Boolean o -> String p in [m->n])
                                if (exists [ai, bi, ci] = { [1, 2.0, '3'] }.cycled.rest.first)
                                    if (exists [Integer xi, Float yi, Character zi] = { [ai, bi, ci] }.cycled.rest.first)
                                        if (exists [initi, *othersi] = [0, *(1..runtime.maxIntegerValue)])
                                            if (exists [String firsti, String *resti] = ["executableName", *process.arguments])
                                                if (exists mi->ni = { true->"true" }.cycled.rest.first)
                                                    if (exists Boolean oi -> String pi = { mi->ni }.cycled.rest.first)
                                                        nothing
    };
}
