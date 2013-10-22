Ceylon Formatter
================

The goal of this project is to provide a formatter for Ceylon source code that can be embedded in the Eclipse and IntelliJ IDE, as well as directly called from the command line.

Current status
--------------

I'm currently working out the architecture: How the formatting works in general, how formatting options are kept and passed, etc.
At the end of this phase, I should have a formatter with support for only a few language features and formatting options, but with that support being very generic and easily expandable.
When I'm comfortable with the architecture, all there's left to do is implementing more language features and formatting options.

Building and running
--------------------

### Environment

You'll need a *very* recent version of Ceylon and the compiler (unless 1.0.0 is already out when you're reading this).
For this, you need to build both your Ceylon and your Ceylon IDE from source.

    mkdir ceylon && cd ceylon
    git clone https://github.com/ceylon/ceylon-dist
    cd ceylon-dist
    ant setup publish-all
    cd ..
    git clone https://github.com/ceylon/ceylon-sdk
    cd ceylon-sdk
    ant publish
    cd ..
    git clone https://github.com/ceylon/ceylon-ide-eclipse
    cd ceylon-ide-eclipse
    mvn clean install -Dmaven.test.skip
    # now install it into your Eclipse from the update site ceylon/ceylon-ide-eclipse/site/target/site
    cd ..

### The formatter

    git clone https://github.com/lucaswerkmeister/ceylon.formatter.git

Open Eclipse and choose Import -> Existing projects into workspaces, select the `ceylon.formatter` repository and import the project

You need to tell Eclipse to use your system repo for building instead of the `defaultRepository`:
Right click on the `ceylon.formatter` project, open Properties -> Ceylon Compiler -> Module Repositories and change the System repository from `${ceylon.repo}` to your `.ceylon/repo` in your home folder.
(This step will be obsolete as soon as the `ceylon-ide-eclipse` developers update their `defaultRepository` binaries again, which will hopefully be soon.)

Then compile and run the `source_gen.ceylon.formatter` module (in folder `source-gen`), which generates a few sources for the formatter;
then you can finally compile `ceylon.formatter`.
To check if everything went well, you can run the tests in `test.ceylon.formatter` (in folder `source-test`).

### Too complicated?

One of my goals ([issue #3](https://github.com/lucaswerkmeister/ceylon.formatter/issues/3)) is to automate the build process.
If these instructions were too much for you, poke that issue, say that I should make that a priority, and then watch and wait.

License
-------

The content of this repository is released under the ASL v2.0
as provided in the LICENSE file that accompanied this code.

By submitting a "pull request" or otherwise contributing to 
this repository, you agree to license your contribution under 
the license mentioned above.
