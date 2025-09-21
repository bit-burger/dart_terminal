import 'dart:math' as math;

extension type const Size._(({int width, int height}) _) {
  const Size(int width, int height) : this._((width: width, height: height));
  int get width => _.width;
  int get height => _.height;
}

extension type const Offset._(({int dx, int dy}) _) {
  const Offset(int dx, int dy) : this._((dx: dx, dy: dy));

  static const Offset zero = Offset(0, 0);

  int get dx => _.dx;
  int get dy => _.dy;
}

extension type const Position._(({int x, int y}) _) {
  const Position(int x, int y) : this._((x: x, y: y));

  static const Position zero = Position(0, 0);

  Rect operator &(Size size) =>
      Rect(x, x + size.width - 1, y, y + size.height - 1);

  Position operator +(Offset v) => Position(x + v.dx, y + v.dy);

  int get x => _.x;
  int get y => _.y;
}

extension type const Rect._(({int x1, int x2, int y1, int y2}) _) {
  const Rect(int x1, int x2, int y1, int y2)
    : this._((x1: x1, x2: x2, y1: y1, y2: y2));

  int get width => _.x2 - _.x1 + 1;
  int get height => _.y2 - _.y1 + 1;
  Size get size => Size(width, height);
  int get x1 => _.x1;
  int get x2 => _.x2;
  int get y1 => _.y1;
  int get y2 => _.y2;

  Position get topLeft => Position(x1, y1);
  Position get topRight => Position(x2, y1);
  Position get bottomRight => Position(x2, y2);
  Position get bottomLeft => Position(x1, y2);

  Rect clip(Rect clip) => Rect(
    math.max(_.x1, clip.x1),
    math.min(_.x2, clip.x2),
    math.max(_.y1, clip.y1),
    math.min(_.y2, clip.y2),
  );

  bool contains(Position position) =>
      _.x1 <= position.x &&
      _.x2 >= position.x &&
      _.y1 <= position.y &&
      _.y2 >= position.y;
}
