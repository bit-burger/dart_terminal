import 'dart:io';

const ESC = '\u001B[';

void main() {
  man();
  man();
}

void man() {
  // final color = XTermTerminalColor(color: 100);
  // final code = ESC + color.termRep(background: true) + ";" + color.termRep(background: true) + "m";
  // stdout.write(code + "asdf");
  final IOSink n = stdout;

  final b = Stopwatch()..start();
  final builder = StringBuffer();
  for(int i = 0; i < 10000; i++) {
    builder.write(ESC + "40ma");
    // for(int i = 0; i < 100; i++) {
    // }
    n.write(builder.toString());
    builder.clear();
  }
  b.stop();


  StringBuffer l = StringBuffer() ;
  for(int i = 0; i < 10000; i++) {
    l.writeCharCode(27);
    l.writeCharCode(91);

    l.writeCharCode(52);
    l.writeCharCode(54);
    l.writeCharCode(109); // m

    l.writeCharCode(84);
  }
  n.write(l);
  l.clear();
  final a = Stopwatch()..start();
  for(int i = 0; i < 10000; i++) {
    l.writeCharCode(27);
    l.writeCharCode(91);

    l.writeCharCode(52);
    l.writeCharCode(54);
    l.writeCharCode(109); // m

    l.writeCharCode(84);
  }
  n.write(l);
  a.stop();
  //
  //
  stdout.write("\n");
  stdout.write(a.elapsedMilliseconds);
  stdout.write("\n");
  stdout.write(b.elapsedMilliseconds);
  stdout.write("\n");


  // final writer = TerminalEscapeCodeWriter.simple;
  // writer
  //   ..escCSIBegin(capability: "m")
  //   ..escParam("5")
  //   ..escParam("47")
  //   ..escParam("4")
  //   ..escParam("3")
  //   ..escParam("51")
  //   ..escEnd()
  //   ..write("aaaa\naaaa\naaaa\naaaa");
  // stdin.echoMode = false;
  // stdin.lineMode = false;
  // await for (final input in stdin) {
  //   print(input);
  // }
  // for(var i = 0; i < 256; i++) {
  //   AnsiStyles.bullet;
  //   final pen = AnsiPen()..xterm(i, bg: true)..xterm(0);
  //   stdout.write(ansiEscapes.clearTerminal);
  //   stdout.write(ansiEscapes.cursorMove(0, 0));
  //   stdout.write(pen("hallo"));
  //   await Future.delayed(Duration(milliseconds: 200));
  // }
}
