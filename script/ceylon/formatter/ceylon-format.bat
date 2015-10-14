@echo off
setlocal EnableDelayedExpansion

set "USAGE=[OPTION]... ( FILE [--and FILE]... [--to FILE] )..."
set "DESCRIPTION=format Ceylon source code"
set LONG_USAGE=    ceylon run ceylon.formatter source^

^

or, if you're worried about it breaking your source code (which shouldn't happen --^
if anything bad happens, error recovery kicks in and the original file is restored)^
or you just want to test it out:^

^

    ceylon run ceylon.formatter source --to source-formatted^

^

You can also format multiple folders at the same time:^

^

    ceylon run ceylon.formatter source --and test-source --to formatted^

^

which will recreate the 'source' and 'test-source' folders inside the new 'formatted' folder.^

^

OPTIONS^

^

--help^

    Print this help message.^

    (--help=options prints help for the various options.)^

^

--version^

    Print version information. The first line is always just the module name and version^
    in the format that 'ceylon run' understands ("ceylon.formatter/x.y.z"), which might be^
    useful for scripts.^

^

--${option name}=${option value}^

    Set a formatting option. The most useful ones are:^

    ^

    --maxLineLength^

        The maximum line length, or "unlimited".^

    ^

    --indentMode^

        The indentation mode. Syntax: "x spaces" or "y-wide tabs" or "mix x-wide tabs, y spaces".^

    ^

    --lineBreak^

        "lf", "crlf", or "os" for the operating system's native line breaks.^

    ^

    For a full list of options, see the output from '--help=options'^
    or the documentation of the FormattingOptions class.^


call %CEYLON_HOME%\bin\ceylon-sh-setup.bat %*

if "%errorlevel%" == "1" (
    exit /b 0
)
%CEYLON% run ceylon.formatter/1.2.0 "%*"
