/********************************************************************************
 * Copyright (c) 2011-2017 Red Hat Inc. and/or its affiliates and others
 *
 * This program and the accompanying materials are made available under the 
 * terms of the Apache License, Version 2.0 which is available at
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * SPDX-License-Identifier: Apache-2.0 
 ********************************************************************************/
shared abstract class LineBreak(text, string) of os | lf | crlf {
    "The actual text of the line break, i. e.,
     what should be written to the file."
    shared String text;
    "The name of the object, i. e., one of
     `os`, `lf`, `crlf`."
    shared actual String string;
}

shared object os extends LineBreak(operatingSystem.newline, "os") {}
shared object lf extends LineBreak("\n", "lf") {}
shared object crlf extends LineBreak("\r\n", "crlf") {}
