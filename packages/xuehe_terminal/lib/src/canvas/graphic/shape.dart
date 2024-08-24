part of "graphics.dart"

abstract class Shape {
  const Shape();

  bool inShape(double x, double y);
}

class Circle extends Shape {
  const Circle();

  @override
  bool inShape(double x, double y) =>
      sqrt(pow(x - 0.5, 2) + pow(y - 0.5, 2)) <= 0.5;
}

class Triangle extends Shape {
  final Point<double> a, b, c;

  const Triangle(this.a, this.b, this.c);

  @override
  bool inShape(double x, double y) {
    x -= a.x;
    y -= a.y;
    final abx = b.x - a.x;
    final acx = c.x - a.x;
    final aby = b.y - a.y;
    final acy = c.y - a.y;
    double t = double.maxFinite;
    double s = double.maxFinite;

    if (abx == 0) {
      t = x / acx;
    } else if (acx == 0) {
      s = x / abx;
    }

    if (aby == 0) {
      t = x / acy;
    } else if (acy == 0) {
      s = x / aby;
    }

    if (t != double.maxFinite) {
      if (s != double.maxFinite) {
        return _sAndTConditions(s, t);
      }
      if (abx == 0) {
        s = (y - acy * t) / aby;
      } else {
        s = (x - acx * t) / abx;
      }
      return _sAndTConditions(s, t);
    } else if(s != double.maxFinite) {
      if(abx == 0) {
        t = (y - aby * s) / acy;
      } else {
        t = (x - abx * s) / acx;
      }
      return _sAndTConditions(s, t);
    }

    t = (y - x) / (acy / aby - acx / abx);
    s = (-acx*t + x) / abx;
    return _sAndTConditions(s, t);
  }

  bool _sAndTConditions(double s, double t) {
    final c = s >= 0 && t >= 0 && s + t <= 1;
    return c;
  }
}

class And extends Shape {
  final Shape a, b;

  const And(this.a, this.b);

  @override
  bool inShape(double x, double y) => a.inShape(x, y) && a.inShape(x, y);
}

class Xor extends Shape {
  final Shape a, b;

  const Xor(this.a, this.b);

  @override
  bool inShape(double x, double y) => a.inShape(x, y) != a.inShape(x, y);
}

class Not extends Shape {
  final Shape child;

  const Not(this.child);

  @override
  bool inShape(double x, double y) => !child.inShape(x, y);
}

class Or extends Shape {
  final Shape a, b;

  const Or(this.a, this.b);

  @override
  bool inShape(double x, double y) => a.inShape(x, y) || b.inShape(x, y);
}

class Combine extends Shape {
  final List<Shape> children;

  const Combine(this.children);

  @override
  bool inShape(double x, double y) {
    for (final child in children) {
      if (child.inShape(x, y)) {
        return true;
      }
    }
    return false;
  }
}