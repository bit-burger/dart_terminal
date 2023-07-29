import 'dart:io';

const ESC = '\u001B';
const CSI = '$ESC[';
const OSC = '$ESC]';
const BEL = '\u0007';

const clearScreen = '${ESC}c';
const clearTerminalWindows = '$clearScreen${ESC}0f';
const clearTerminalUnix = '$clearScreen${ESC}3J${ESC}H';
final clearTerminal =
    Platform.isWindows ? clearTerminalWindows : clearTerminalUnix;
const cursorHide = '$ESC?25l';
const cursorShow = '$ESC?25h';
