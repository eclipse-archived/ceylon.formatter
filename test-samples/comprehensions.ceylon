void testComprehensions() {
    print(" ".join({for(s in{ "Hello,", "sodding", "World!"})if(s.first?.uppercase else false)s}));
}
