import ceylon.test { createTestRunner, TestRunResult }
void run() {
	TestRunResult result = createTestRunner([`package test.ceylon.formatter`]).run();
	print(result.string);
}