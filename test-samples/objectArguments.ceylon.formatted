void testObjectArguments() {
    someFunction {
        object objectArgument
                satisfies Iterable<String,Nothing> {
            void printIt() {
                print(this);
            }
            
            void iterator()
                    => { "HelloWorld" }.iterator();
        }
    };
}
