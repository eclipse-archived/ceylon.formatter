import source_gen.ceylon.formatter.formattingOptions { generateFormattingOptions = generate }
"Generate sources."
shared void run() {
    generateFormattingOptions();
}