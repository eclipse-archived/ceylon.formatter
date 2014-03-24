Ceylon Formatter
================

The goal of this project is to provide a formatter for Ceylon source code that can be embedded in the Eclipse and IntelliJ IDE, as well as directly called from the command line.

Current status
--------------

The formatter can format itself completely, and I’m currently working towards a first public beta before I can release a version 1.0.0.

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
