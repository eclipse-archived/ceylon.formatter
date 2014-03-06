Ceylon Formatter
================

The goal of this project is to provide a formatter for Ceylon source code that can be embedded in the Eclipse and IntelliJ IDE, as well as directly called from the command line.

Current status
--------------

The architecture of the formatter ([`FormattingVisitor`](source/ceylon/formatter/FormattingVisitor.ceylon) and [`FormattingWriter`](source/ceylon/formatter/FormattingWriter.ceylon)) is mostly finished. Now I’m adding more and more language features to the Formatter. The target of this phase is “dogfooding”: when the formatter can format itself (and the formatted formatter formatting itself again doesn’t change anything), then this phase is done.

This phase is probably the easiest if you want to help out: you only have to find out how your language feature looks in the Abstract Syntax Tree (for example by setting a breakpoint in `FormattingVisitor.visitAny`) and then override the necessary `visitX` method(s). For usage examples, you can look at the existing `visitX` methods. If you have any questions, don’t hesitate to ask!

Building
--------------------

1. Install the Ceylon IDE, following [these instructions](http://ceylon-lang.org/documentation/1.0/ide/install/)
2. Clone the repository locally
3. In Eclipse, go to File -> Import... -> Existing Projects into Workspace, then choose the location of the `ceylon.formatter` repository and import the `ceylon.formatter` project
4. Run `source_gen.ceylon.formatter.run()` (ignore the warning that the project has build errors, that’s exactly what this is going to fix)
5. Right-click the `test.ceylon.formatter` module and choose Run As -> Ceylon Test to test if everything works

Due to some quirks in the Ceylon IDE, compilation might fail because the compiler can’t find the ANTLR runtime (which comes with the ceylon compiler).
I don’t have a reliable way to fix this, but cleaning the project and/or restarting the IDE has always worked for me after a few times.

Contact
-------

If you have found a bug or want to suggest a feature, file an issue. You can also send me an e-mail (address is on my Github page), or join [![Gitter chat](https://badges.gitter.im/lucaswerkmeister/ceylon.formatter.png)](https://gitter.im/lucaswerkmeister/ceylon.formatter).

License
-------

The content of this repository is released under the ASL v2.0
as provided in the LICENSE file that accompanied this code.

By submitting a "pull request" or otherwise contributing to 
this repository, you agree to license your contribution under 
the license mentioned above.
