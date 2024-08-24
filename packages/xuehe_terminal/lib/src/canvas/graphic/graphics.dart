part "shape.dart";
part 'pattern.dart';

abstract class Graphics {
  TerminalStyle? drawStyle(double x, double y);

  const Graphics();
}

class Filled extends Graphics {
  final TerminalStyle style;

  const Filled({required this.style});

  @override
  TerminalStyle? drawStyle(double x, double y) {
    return style;
  }
}



class Stack implements Graphics {
  final List<Graphics> children;

  const Stack({required this.children});

  @override
  TerminalStyle? drawStyle(double x, double y) {
    for (var i = children.length - 1; i >= 0; i--) {
      final style = children[i].drawStyle(x, y);
      if (style != null) return style;
    }
    return null;
  }
}

class EdgeInsets {
  final double left, right, top, bottom;

  double get contentWidth => 1 - left - right;
  double get contentHeight => 1 - top - bottom;

  double get horizontal => left + right;
  double get vertical => top + bottom;

  const EdgeInsets.lrtb(this.left, this.right, this.top, this.bottom)
      : assert(left >= 0),
        assert(right >= 0),
        assert(top >= 0),
        assert(bottom >= 0),
        assert(left + right < 1),
        assert(top + bottom < 1);

  const EdgeInsets.only({
    this.left = 0,
    this.right = 0,
    this.top = 0,
    this.bottom = 0,
  })  : assert(left >= 0),
        assert(right >= 0),
        assert(top >= 0),
        assert(bottom >= 0),
        assert(left + right < 1),
        assert(top + bottom < 1);

  const EdgeInsets.all(double all)
      : assert(all >= 0 && all < 1),
        left = all,
        right = all,
        top = all,
        bottom = all;

  const EdgeInsets.symmetric({double horizontal = 0, double vertical = 0})
      : assert(horizontal >= 0 && horizontal < 1),
        assert(vertical >= 0 && vertical < 1),
        left = horizontal,
        right = horizontal,
        top = vertical,
        bottom = vertical;
}

class Padding extends Graphics {
  final Graphics child;
  final EdgeInsets edgeInsets;

  const Padding({required this.edgeInsets, required this.child});

  @override
  TerminalStyle? drawStyle(double x, double y) {
    if ((x <= edgeInsets.left || 1 - x <= edgeInsets.right) ||
        (y <= edgeInsets.top || 1 - y <= edgeInsets.bottom)) return null;
    return child.drawStyle(
      (x - edgeInsets.left) / edgeInsets.contentWidth,
      (y - edgeInsets.top) / edgeInsets.contentHeight,
    );
  }
}

class Zoom extends Graphics {
  final Graphics child;
  final EdgeInsets edgeInsets;

  Zoom({required this.edgeInsets, required this.child});

  @override
  TerminalStyle? drawStyle(double x, double y) => child.drawStyle(
    (x + edgeInsets.left) * edgeInsets.contentWidth,
    (y + edgeInsets.top) * edgeInsets.contentHeight,
  );
}

class Clip extends Graphics {
  final Shape shape;
  final Graphics child;
  final bool _shouldBeInShape;

  const Clip({
    required this.shape,
    required this.child,
  }) : _shouldBeInShape = true;

  const Clip.reverse({
    required this.shape,
    required this.child,
  }) : _shouldBeInShape = false;

  @override
  TerminalStyle? drawStyle(double x, double y) {
    if (_shouldBeInShape == shape.inShape(x, y)) {
      return child.drawStyle(x, y);
    }
    return null;
  }
}
