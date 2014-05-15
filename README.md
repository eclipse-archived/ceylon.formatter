Ceylon Formatter
================

A source code formatter for the [Ceylon programming language](http://ceylon-lang.org/).

Current status
--------------

I consider the formatter itself ready for release;
a [public beta](https://groups.google.com/forum/#!topic/ceylon-users/UZDhaNcfxtc) was launched a few weeks ago.

However, the formatter is written for Ceylon 1.1;
the current release version of Ceylon is 1.0, so I have to wait until Ceylon 1.1 is released for releasing `ceylon.formatter 1.1.0`.

Building
--------

1. Install the Ceylon IDE, following [these instructions](http://ceylon-lang.org/documentation/1.0/ide/install/)
2. Clone the repository locally
3. In Eclipse, go to File -> Import... -> Existing Projects into Workspace, then choose the location of the `ceylon.formatter` repository and import the `ceylon.formatter` project
4. Run `source_gen.ceylon.formatter.run()` from the `source-gen` source folder  (ignore the warning that the project has build errors, that’s exactly what this is going to fix)
5. Right-click the `ceylon.formatter` module and choose Run As -> Ceylon Test to test if everything works

Usage
-----

If you have the formatter installed locally (from source):
```bash
ceylon run ceylon.formatter source # to format all Ceylon code in source
ceylon run ceylon.formatter source --to source-formatted # if you’re afraid I might break your code – directory structure is preserved
ceylon run ceylon.formatter source test-source # to format all Ceylon code in source and test-source
ceylon run ceylon.formatter source --and test-source --to formatted # to format all Ceylon code in source and test-source into formatted
```

If you don’t have the formatter installed, you can run the beta by adding a `--rep=https://lucaswerkmeister.github.io/ceylon.formatter/modules` option to the `ceylon run` command.

(Yes, at the moment you can only run the formatter from the command line.
IDE integration is planned, and a first version will hopefully be finished in time for the 1.1.0 release.)

Contact
-------

If you have found a bug or want to suggest a feature, [create an issue](https://github.com/lucaswerkmeister/ceylon.formatter/issues/new). You can also send me an e-mail (address is on my Github page), or join [![Gitter chat](https://badges.gitter.im/lucaswerkmeister/ceylon.formatter.png)](https://gitter.im/lucaswerkmeister/ceylon.formatter).

License
-------

The content of this repository is released under the ASL v2.0
as provided in the LICENSE file that accompanied this code.

By submitting a "pull request" or otherwise contributing to 
this repository, you agree to license your contribution under 
the license mentioned above.
