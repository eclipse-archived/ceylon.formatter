abstract class TestCaseTypes()
        of T1 | t2 | T3 | t4 | T5 {}
class T1() extends TestCaseTypes() {}
class T3() extends TestCaseTypes() {}
class T5() extends TestCaseTypes() {}
object t2 extends TestCaseTypes() {}
object t4 extends TestCaseTypes() {}
