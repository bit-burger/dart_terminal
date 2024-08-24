import 'package:advanced_terminal/src/canvas/widgets/canvas.dart';

abstract class Render {
  late bool transparent, onlyText;
  late int width, height;

  void render(
    Canvas c,
    int x1,
    int x2,
    int y1,
    int y2,
    int z,
  );

  // int hx1,
  //     int hx2,
  // int hy1,
  //     int hy2,
}
