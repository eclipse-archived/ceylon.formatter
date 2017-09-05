Ceylon Formatter
================

[![Build Status](https://ci-ceylon.rhcloud.com/buildStatus/icon?job=ceylon.formatter)](https://ci-ceylon.rhcloud.com/job/ceylon.formatter)

A source code formatter for the [Ceylon programming language](https://ceylon-lang.org/).

Current status
--------------

Version 1.3.3 has been [released][release-1.3.3] and is available on [Herd][herd-1.3.3].
There are no immediate plans for changes;
the next release will probably be for bugfixes, or to support new language features, or for a new binary version of Ceylon.

[release-1.3.3]: https://github.com/ceylon/ceylon.formatter/releases/1.3.3
[herd-1.3.3]: https://modules.ceylon-lang.org/modules/ceylon.formatter/1.3.3

Building
--------

### With `ant`

```bash
git clone https://github.com/ceylon/ceylon.formatter
cd ceylon.formatter
ant install
```

The buildfile assumes that `ceylon-dist` (including the Ceylon ant files) is a sibling folder; otherwise, you might have to adjust the paths in `build.properties`.

### With the IDE

1. Install the Ceylon IDE, following [these instructions](https://ceylon-lang.org/documentation/current/ide/eclipse/install/)
2. Clone the repository locally
3. In Eclipse, go to File -> Import... -> Existing Projects into Workspace, then choose the location of the `ceylon.formatter` repository and import the `ceylon.formatter` project
4. Run `source_gen.ceylon.formatter.run()` from the `source-gen` source folder  (ignore the warning that the project has build errors, that’s exactly what this is going to fix)
5. Right-click the `test.ceylon.formatter` module and choose Run As -> Ceylon Test to test if everything works

Usage
-----

The formatter is part of the [Ceylon IDE](https://ceylon-lang.org/documentation/current/ide/eclipse/). You can format any source file by hitting Ctrl+Shift+F, or selecting Source > Format from the menu.

You can also run the formatter from the command line:

```bash
ceylon format source # to format all Ceylon code in source
ceylon format source --to source-formatted # if you’re afraid I might break your code – directory structure is preserved
ceylon format source test-source # to format all Ceylon code in source and test-source
ceylon format source --and test-source --to formatted # to format all Ceylon code in source and test-source into formatted
```

(Replace `ceylon format` with `ceylon run ceylon.formatter` if you don’t have the plugin installed.)

Contact
-------

If you have found a bug or want to suggest a feature, [create an issue](https://github.com/ceylon/ceylon.formatter/issues/new). You can also send me an e-mail (address is on my Github page).

License
-------

The content of this repository is released under the ASL v2.0
as provided in the LICENSE file that accompanied this code.

By submitting a "pull request" or otherwise contributing to 
this repository, you agree to license your contribution under 
the license mentioned above.
