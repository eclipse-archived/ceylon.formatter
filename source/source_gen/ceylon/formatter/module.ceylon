/********************************************************************************
 * Copyright (c) {date} Red Hat Inc. and/or its affiliates and others
 *
 * This program and the accompanying materials are made available under the 
 * terms of the Apache License, Version 2.0 which is available at
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * SPDX-License-Identifier: Apache-2.0 
 ********************************************************************************/
"Auto-generate sources for ceylon.formatter."
by ("Lucas Werkmeister <mail@lucaswerkmeister.de>")
license ("https://www.apache.org/licenses/LICENSE-2.0.html")
native ("jvm") module source_gen.ceylon.formatter "1.3.4-SNAPSHOT" {
    import ceylon.file "1.3.4-SNAPSHOT";
    import java.base "7";
}
