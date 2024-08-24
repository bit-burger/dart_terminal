import 'dart:io';

import 'package:ansicolor/ansicolor.dart';

const ESC = '\u001B';
const CSI = '$ESC[';
const OSC = '$ESC]';
const BEL = '\u0007';

const clearScreen = '${ESC}c';
const clearTerminalWindows = '$clearScreen${CSI}0f';
const clearTerminalUnix = '$clearScreen${CSI}3J${CSI}H';
final clearTerminal =
    Platform.isWindows ? clearTerminalWindows : clearTerminalUnix;
const cursorHide = '$ESC?25l';
const cursorShow = '$ESC?25h';

const a = ansiEscape
