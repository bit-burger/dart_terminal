// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>
#include <stdlib.h>
#include "ffi_system_access.h"

#define bool int
#define true 1
#define false 0

int main()
{
    system_access("tput civis");
    system_access("stty -echo");
    return 0;
}

// Note:
// ---only on Windows---
// Every function needs to be exported to be able to access the functions by dart.
// Refer: https://stackoverflow.com/q/225432/8608146

void system_access(char* command)
{
    //system("tput civis");
    //system("stty -echo");
    system(command);
}
