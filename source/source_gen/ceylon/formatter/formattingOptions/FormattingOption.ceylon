/********************************************************************************
 * Copyright (c) 2011-2017 Red Hat Inc. and/or its affiliates and others
 *
 * This program and the accompanying materials are made available under the 
 * terms of the Apache License, Version 2.0 which is available at
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * SPDX-License-Identifier: Apache-2.0 
 ********************************************************************************/
"One formatting option."
class FormattingOption(documentation, type, name, defaultValue) {
    "The documentation string (excluding the surrounding quotes)."
    shared String documentation;
    "The type."
    shared String type;
    "The name."
    shared String name;
    "The default value."
    shared String defaultValue;
}
