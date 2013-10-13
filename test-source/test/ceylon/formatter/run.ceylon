import ceylon.test { TestRunner, PrintingTestListener }
import ceylon.formatter.options { ... }
void run() {
    TestRunner testRunner = TestRunner();
    testRunner.addTestListener(PrintingTestListener());
    testRunner.addTest("helloWorld", testHelloWorld);
    testRunner.addTest("helloWorldCommented", testHelloWorldCommented);
    testRunner.run();
}