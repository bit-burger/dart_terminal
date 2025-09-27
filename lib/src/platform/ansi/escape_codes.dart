/// ANSI escape sequences and control codes for terminal manipulation.
///
/// This module provides constants and functions for generating ANSI escape sequences
/// that control terminal behavior, cursor movement, text formatting, and colors.
/// Based on documentation from:
/// - https://gist.github.com/ConnerWill/d4b6c776b509add763e17f9f113fd25b
/// - https://invisible-island.net/xterm/ctlseqs/ctlseqs.html

//==============================================================================
// BASIC ASCII CONTROL CODES
//==============================================================================

/// Ring the terminal bell (audio or visual alert)
const String bell = '\x07';

/// Move cursor one position left
const String backspace = '\x08';

/// Move cursor to next tab stop
const String tab = '\x09';

/// Move cursor to beginning of next line
const String lineFeed = '\x0A';

/// Move cursor down one line maintaining column position
const String verticalTab = '\x0B';

/// Move cursor to next page
const String formFeed = '\x0C';

/// Move cursor to beginning of current line
const String carriageReturn = '\x0D';

/// Start of escape sequence
const String escape = '\x1B';

/// Delete character at cursor
const String delete = '\x7F';

//==============================================================================
// ANSI SEQUENCE INTRODUCERS
//==============================================================================

/// Escape sequence initiator
const String ESC = '\x1B';

/// Control Sequence Introducer (CSI)
const String CSI = '\x1B[';

/// Device Control String
const String DCS = '\x1BP';

/// Operating System Command
const String OSC = '\x1B]';

//==============================================================================
// CURSOR CONTROL SEQUENCES
//==============================================================================

/// Request cursor position report
const String cursorPositionQuery = '\x1B[6n';

/// Move cursor to home position (1,1)
const String cursorHome = '\x1B[H';

/// Move cursor to specific position
String cursorTo(int line, int column) => '\x1B[$line;${column}H';

/// Move cursor up by specified number of lines
String cursorUp(int lines) => '\x1B[${lines}A';

/// Move cursor down by specified number of lines
String cursorDown(int lines) => '\x1B[${lines}B';

/// Move cursor forward by specified number of columns
String cursorForward(int columns) => '\x1B[${columns}C';

/// Move cursor backward by specified number of columns
String cursorBackward(int columns) => '\x1B[${columns}D';

/// Move cursor to beginning of next line
const String cursorNextLine = '\x1B[E';

/// Move cursor to beginning of previous line
const String cursorPrevLine = '\x1B[F';

/// Move cursor to specified column in current line
String cursorColumn(int column) => '\x1B[${column}G';

/// Alternative cursor position query (same as cursorPositionQuery)
const String requestCursorPosition = '\x1B[6n';

/// Scroll screen up one line
const String cursorUpScroll = '\x1BM';

//==============================================================================
// CURSOR STATE MANAGEMENT
//==============================================================================

/// Save cursor position (DEC sequence - recommended)
const String saveCursorPositionDEC = '\x1B7';

/// Restore cursor position (DEC sequence - recommended)
const String restoreCursorPositionDEC = '\x1B8';

/// Save cursor position (SCO sequence)
const String saveCursorPositionSCO = '\x1B[s';

/// Restore cursor position (SCO sequence)
const String restoreCursorPositionSCO = '\x1B[u';

//==============================================================================
// CURSOR VISIBILITY CONTROL
//==============================================================================

/// Hide the cursor
const String hideCursor = '\x1B[?25l';

/// Show the cursor
const String showCursor = '\x1B[?25h';

/// Enable cursor blinking
const String enableCursorBlink = '\x1B[?12l';

/// Disable cursor blinking
const String disableCursorBlink = '\x1B[?12h';

//==============================================================================
// WINDOW MANIPULATION
//==============================================================================

/// Change terminal window dimensions
String changeWindowDimension(int width, int height) =>
    '\x1b[8;$height;${width}t';

/// Set terminal window title
String changeTerminalTitle(String title) => '\x1b]0;$title\x07';

//==============================================================================
// SCREEN CLEARING AND ERASING
//==============================================================================

/// Erase from cursor to end of screen
const String eraseScreenFromCursor = '\x1B[J';

/// Erase from start of screen to cursor
const String eraseScreenToCursor = '\x1B[1J';

/// Erase entire screen
const String eraseEntireScreen = '\x1B[2J';

/// Erase from cursor to end of line
const String eraseLineFromCursor = '\x1B[K';

/// Erase from start of line to cursor
const String eraseLineToCursor = '\x1B[1K';

/// Erase entire line
const String eraseEntireLine = '\x1B[2K';

//==============================================================================
// TEXT FORMATTING
//==============================================================================

/// Reset all text formatting
const String resetAllFormats = '\x1B[0m';

/// Enable bold text
const String boldText = '\x1B[1m';

/// Enable dim/faint text
const String dimText = '\x1B[2m';

/// Enable italic text
const String italicText = '\x1B[3m';

/// Enable underlined text
const String underlineText = '\x1B[4m';

/// Enable blinking text
const String blinkingText = '\x1B[5m';

/// Enable inverse/reversed colors
const String inverseText = '\x1B[7m';

/// Enable hidden/invisible text
const String hiddenText = '\x1B[8m';

/// Enable strikethrough text
const String strikethroughText = '\x1B[9m';

//==============================================================================
// TEXT FORMAT RESET
//==============================================================================

/// Reset bold and dim attributes
const String resetBoldDim = '\x1B[22m';

/// Reset italic attribute
const String resetItalic = '\x1B[23m';

/// Reset underline attribute
const String resetUnderline = '\x1B[24m';

/// Reset blink attribute
const String resetBlink = '\x1B[25m';

/// Reset inverse/reversed colors
const String resetInverse = '\x1B[27m';

/// Reset hidden/invisible attribute
const String resetHidden = '\x1B[28m';

/// Reset strikethrough attribute
const String resetStrikethrough = '\x1B[29m';

//==============================================================================
// COLOR CONTROL
//==============================================================================

/// Reset to default color
const String defaultColor = '\x1B[39m';

/// Set foreground color using color code
String foregroundColor(int colorCode) => '\x1B[${colorCode}m';

/// Set background color using color code
String backgroundColor(int colorCode) => '\x1B[${colorCode + 10}m';

/// Set 16-color ANSI color
String ansi16Color(int colorCode, {bool isForeground = true}) =>
    '\x1B[${isForeground ? 3 : 4}${colorCode}m';

/// Set bright ANSI color
String ansiBrightColor(int colorCode, {bool isForeground = true}) =>
    '\x1B[${isForeground ? 9 : 10}${colorCode}m';

//==============================================================================
// EXTENDED COLOR SUPPORT
//==============================================================================

/// Set foreground color using 256-color palette
String fg256Color(int colorId) => '\x1B[38;5;${colorId}m';

/// Set background color using 256-color palette
String bg256Color(int colorId) => '\x1B[48;5;${colorId}m';

/// Set foreground color using RGB values
String fgRGBColor(int r, int g, int b) => '\x1B[38;2;$r;$g;${b}m';

/// Set background color using RGB values
String bgRGBColor(int r, int g, int b) => '\x1B[48;2;$r;$g;${b}m';

//==============================================================================
// SCREEN MODE CONTROL
//==============================================================================

/// Set screen mode
String setScreenMode(int mode) => '\x1B[=${mode}h';

/// Reset screen mode
String resetScreenMode(int mode) => '\x1B[=${mode}l';

/// Enable line wrapping
const String enableLineWrapping = '\x1B[?7h';

/// Disable line wrapping
const String disableLineWrapping = '\x1B[?7l';

//==============================================================================
// TERMINAL BUFFER CONTROL
//==============================================================================

/// Switch to alternate screen buffer
const String enableAlternativeBuffer = '\x1B[?1049h';

/// Switch back to main screen buffer
const String disableAlternativeBuffer = '\x1B[?1049l';

/// Save current screen
const String saveScreen = '\x1B[?47h';

/// Restore saved screen
const String restoreScreen = '\x1B[?47l';

//==============================================================================
// FOCUS AND MOUSE TRACKING
//==============================================================================

/// Enable terminal focus events
const String enableFocusTracking = "\u001B[?1004h";

/// Disable terminal focus events
const String disableFocusTracking = "\u001B[?1004l";

/// Enable mouse tracking (motion, button, and SGR encoding)
const String enableMouseEvents = "\u001B[?1003;1006h";

/// Disable mouse tracking
const String disableMouseEvents = "\u001B[?1003;1006l";

//==============================================================================
// KEYBOARD AND FUNCTION KEYS
//==============================================================================

/// Generate keyboard escape sequence
String keyboardString(String code) => '\x1B[${code}~';

/// Generate function key escape sequence
String fKey(int n) => keyboardString('1${n - 1}');

/// Common keyboard code mappings for function and special keys
final Map<String, String> keyboardCodes = {
  'F1': '0;59',
  'F2': '0;60',
  'F3': '0;61',
  'F4': '0;62',
  'F5': '0;63',
  'F6': '0;64',
  'F7': '0;65',
  'F8': '0;66',
  'F9': '0;67',
  'F10': '0;68',
  'F11': '0;133',
  'F12': '0;134',
  'HOME': '0;71',
  'UP': '0;72',
  'PGUP': '0;73',
  'LEFT': '0;75',
  'RIGHT': '0;77',
  'END': '0;79',
  'DOWN': '0;80',
  'PGDN': '0;81',
  'INS': '0;82',
  'DEL': '0;83',
  'ENTER': '13',
  'BACKSPACE': '8',
  'TAB': '9',
};

/// Generate keyboard escape sequence with modifiers
String keyCode(
  String key, {
  bool shift = false,
  bool ctrl = false,
  bool alt = false,
}) {
  if (!keyboardCodes.containsKey(key)) return '';
  String baseCode = keyboardCodes[key]!;
  if (shift) baseCode = '0;${int.parse(baseCode.split(';')[1]) + 25}';
  if (ctrl) baseCode = '0;${int.parse(baseCode.split(';')[1]) + 35}';
  if (alt) baseCode = '0;${int.parse(baseCode.split(';')[1]) + 45}';
  return '\x1B[${baseCode}~';
}
