int coordinatesToPart(double x, double y) {
  if (x < 0.33) {
    if (y < 0.33) {
      return 0;
    } else if (y < 0.66) {
      return 3;
    } else {
      return 6;
    }
  } else if (x < 0.66) {
    if (y < 0.33) {
      return 1;
    } else if (y < 0.66) {
      return 4;
    } else {
      return 7;
    }
  } else {
    if (y < 0.33) {
      return 2;
    } else if (y < 0.66) {
      return 5;
    } else {
      return 8;
    }
  }
}
