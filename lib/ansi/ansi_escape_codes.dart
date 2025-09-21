/// https://gist.github.com/ConnerWill/d4b6c776b509add763e17f9f113fd25b
/// General ASCII Codes
const String bell = '\x07';
const String backspace = '\x08';
const String tab = '\x09';
const String lineFeed = '\x0A';
const String verticalTab = '\x0B';
const String formFeed = '\x0C';
const String carriageReturn = '\x0D';
const String escape = '\x1B';
const String delete = '\x7F';

/// Sequence Introducers
const String ESC = '\x1B';
const String CSI = '\x1B[';
const String DCS = '\x1BP';
const String OSC = '\x1B]';

/// Cursor Position
const String cursorPositionQuery = '\x1B[6n';
const String cursorHome = '\x1B[H';
String cursorTo(int line, int column) => '\x1B[$line;${column}H';
String cursorUp(int lines) => '\x1B[${lines}A';
String cursorDown(int lines) => '\x1B[${lines}B';
String cursorForward(int columns) => '\x1B[${columns}C';
String cursorBackward(int columns) => '\x1B[${columns}D';
const String cursorNextLine = '\x1B[E';
const String cursorPrevLine = '\x1B[F';
String cursorColumn(int column) => '\x1B[${column}G';
const String requestCursorPosition = '\x1B[6n';
const String cursorUpScroll = '\x1BM';
// DEC is recommended
const String saveCursorPositionDEC = '\x1B7';
const String restoreCursorPositionDEC = '\x1B8';
const String saveCursorPositionSCO = '\x1B[s';
const String restoreCursorPositionSCO = '\x1B[u';

/// Cursor Visibility
const String hideCursor = '\x1B[?25l';
const String showCursor = '\x1B[?25h';
const String enableCursorBlink = '\x1B[?12l';
const String disableCursorBlink = '\x1B[?12h';

/// Change Window
String changeWindowDimension(int width, int height) =>
    '\x1b[8;$height;${width}t';
String changeTerminalTitle(String title) => '\x1b]0;$title\x07';

/// Erase Functions
const String eraseScreenFromCursor = '\x1B[J';
const String eraseScreenToCursor = '\x1B[1J';
const String eraseEntireScreen = '\x1B[2J';
const String eraseLineFromCursor = '\x1B[K';
const String eraseLineToCursor = '\x1B[1K';
const String eraseEntireLine = '\x1B[2K';

/// Text Formatting
const String resetAllFormats = '\x1B[0m';
const String boldText = '\x1B[1m';
const String dimText = '\x1B[2m';
const String italicText = '\x1B[3m';
const String underlineText = '\x1B[4m';
const String blinkingText = '\x1B[5m';
const String inverseText = '\x1B[7m';
const String hiddenText = '\x1B[8m';
const String strikethroughText = '\x1B[9m';

/// Reset Text Formatting
const String resetBoldDim = '\x1B[22m';
const String resetItalic = '\x1B[23m';
const String resetUnderline = '\x1B[24m';
const String resetBlink = '\x1B[25m';
const String resetInverse = '\x1B[27m';
const String resetHidden = '\x1B[28m';
const String resetStrikethrough = '\x1B[29m';

/// Colors
const String defaultColor = '\x1B[39m';
String foregroundColor(int colorCode) => '\x1B[${colorCode}m';
String backgroundColor(int colorCode) => '\x1B[${colorCode + 10}m';
String ansi16Color(int colorCode, {bool isForeground = true}) =>
    '\x1B[${isForeground ? 3 : 4}${colorCode}m';
String ansiBrightColor(int colorCode, {bool isForeground = true}) =>
    '\x1B[${isForeground ? 9 : 10}${colorCode}m';

/// 256 Colors
String fg256Color(int colorId) => '\x1B[38;5;${colorId}m';
String bg256Color(int colorId) => '\x1B[48;5;${colorId}m';

/// RGB Colors
String fgRGBColor(int r, int g, int b) => '\x1B[38;2;$r;$g;${b}m';
String bgRGBColor(int r, int g, int b) => '\x1B[48;2;$r;$g;${b}m';

/// Screen Modes
String setScreenMode(int mode) => '\x1B[=${mode}h';
String resetScreenMode(int mode) => '\x1B[=${mode}l';
const String enableLineWrapping = '\x1B[?7h';
const String disableLineWrapping = '\x1B[?7l';

/// Common Private Modes
const String enableAlternativeBuffer = '\x1B[?1049h';
const String disableAlternativeBuffer = '\x1B[?1049l';
const String saveScreen = '\x1B[?47h';
const String restoreScreen = '\x1B[?47l';

// TODO: scrolling + delete scrollback buffers

/// Done based on xterm functionality: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html
/// Focus tracking
const String enableFocusTracking = "\u001B[?1004h";
const String disableFocusTracking = "\u001B[?1004l";

/// Mouse functionality
const String enableMouseEvents = "\u001B[?1003;1006h";
const String disableMouseEvents = "\u001B[?1003;1006l";

/// Keyboard Strings
String keyboardString(String code) => '\x1B[${code}~';

/// Common function keys
String fKey(int n) => keyboardString('1${n - 1}');
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
