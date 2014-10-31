void testSelf() {
    object printsSelf {
        shared void printIt() {
            print ( this ) ;
            print ( super . string);
        }
    }
    printsSelf.printIt();
}
