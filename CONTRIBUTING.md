Contributing to `ceylon.formatter`
==================================

So you want to contribute? Awesome! Here’s how you can do that:

1. Participate in “Request for comment” issues
2. Contribute code
3. Test the formatter, report bugs, provide sample code
4. Some other way that I didn’t think of

Let’s look at them in closer detail.

Participate in “Request for comment” issues
-------------------------------------------

This is the most lightweight way to contribute to this project. You don’t need to fork, you don’t need to clone, you don’t need to change any files on your computer. All you need to do is to **head over [here](https://github.com/ceylon/ceylon.formatter/issues?labels=request+for+comments&page=1&state=open "issues tagged with \"request for comment\"")**, pick an issue, **read** through the issue text and existing comments, **think** about it, then **add your opinion** to the discussion. (I’d like to point out that while comments like “You forgot corner case X”, “@bob is currently working on this in ####” and “I like the name A better, B could be misinterpreted as β” are in a way more constructive, a simple “sounds good to me”, “good idea” or just “+1” can be really motivating as well, so please don’t hesitate sending your comment, no matter how short it is!)

Contribute code
---------------

Standard GitHub workflow: [Create a fork](https://github.com/ceylon/ceylon.formatter/fork), edit files, submit a pull request. If you’re unsure where to start, have a look at the [issues tagged “easy”](https://github.com/ceylon/ceylon.formatter/issues?labels=easy). Building instructions are available in the README. Creating a branch for the feature is recommended for major contributions, but not required. If you’re fixing an issue, use GitHub’s feature to [close issues via commit messages](https://help.github.com/articles/closing-issues-via-commit-messages). Write tests if you can be bothered. Coding style follows the ceylon.language and ceylon-sdk modules; indent by four spaces (there’s a [git hook](https://github.com/ceylon/ceylon.formatter/wiki/Utilities#git-pre-commit-hook) for that). **TL;DR: Don’t worry, I’ll probably accept it anyways.**

Test the formatter, report bugs, provide sample code
----------------------------------------------------

See the README on how to run the formatter. Give it some code. Unsupported language features are just dumped to stderr; please don’t file bugs for them yet. If the formatted code looks wrong, file an issue.

Some other way that I didn’t think of
-------------------------------------

Of course, you’re free to contribute in any way you want. It will still be appreciated :)

The boring stuff
================

The content of this repository is released under the ASL v2.0 as provided in the LICENSE file that accompanied this code.

By submitting a "pull request" or otherwise contributing to this repository, you agree to license your contribution under the license mentioned above.
