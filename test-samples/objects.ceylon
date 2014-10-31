import ceylon.math.float { random }

void testObjects() {
    object o1 {
    }
    object o2 satisfies {String*} {
        shared actual Iterator<String> iterator() {
            object it satisfies Iterator<String> {
                shared actual String|Finished next() => random() > 0.99 then "-" else finished;
            }
            return it;
        }
    }
}
