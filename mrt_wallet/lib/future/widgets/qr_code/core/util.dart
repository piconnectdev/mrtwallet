const List<List<int>> _patternPositionTable = [
  [],
  [6, 18],
  [6, 22],
  [6, 26],
  [6, 30],
  [6, 34],
  [6, 22, 38],
  [6, 24, 42],
  [6, 26, 46],
  [6, 28, 50],
  [6, 30, 54],
  [6, 32, 58],
  [6, 34, 62],
  [6, 26, 46, 66],
  [6, 26, 48, 70],
  [6, 26, 50, 74],
  [6, 30, 54, 78],
  [6, 30, 56, 82],
  [6, 30, 58, 86],
  [6, 34, 62, 90],
  [6, 28, 50, 72, 94],
  [6, 26, 50, 74, 98],
  [6, 30, 54, 78, 102],
  [6, 28, 54, 80, 106],
  [6, 32, 58, 84, 110],
  [6, 30, 58, 86, 114],
  [6, 34, 62, 90, 118],
  [6, 26, 50, 74, 98, 122],
  [6, 30, 54, 78, 102, 126],
  [6, 26, 52, 78, 104, 130],
  [6, 30, 56, 82, 108, 134],
  [6, 34, 60, 86, 112, 138],
  [6, 30, 58, 86, 114, 142],
  [6, 34, 62, 90, 118, 146],
  [6, 30, 54, 78, 102, 126, 150],
  [6, 24, 50, 76, 102, 128, 154],
  [6, 28, 54, 80, 106, 132, 158],
  [6, 32, 58, 84, 110, 136, 162],
  [6, 26, 54, 82, 110, 138, 166],
  [6, 30, 58, 86, 114, 142, 170]
];

const int _g15 =
    (1 << 10) | (1 << 8) | (1 << 5) | (1 << 4) | (1 << 2) | (1 << 1) | (1 << 0);
const int _g18 = (1 << 12) |
    (1 << 11) |
    (1 << 10) |
    (1 << 9) |
    (1 << 8) |
    (1 << 5) |
    (1 << 2) |
    (1 << 0);
const _g15Mask = (1 << 14) | (1 << 12) | (1 << 10) | (1 << 4) | (1 << 1);

int bchTypeInfo(int data) {
  var d = data << 10;
  while (_bchDigit(d) - _bchDigit(_g15) >= 0) {
    d ^= _g15 << (_bchDigit(d) - _bchDigit(_g15));
  }
  return ((data << 10) | d) ^ _g15Mask;
}

int bchTypeNumber(int data) {
  var d = data << 12;
  while (_bchDigit(d) - _bchDigit(_g18) >= 0) {
    d ^= _g18 << (_bchDigit(d) - _bchDigit(_g18));
  }
  return (data << 12) | d;
}

int _bchDigit(int data) {
  var digit = 0;

  while (data != 0) {
    digit++;
    data >>= 1;
  }

  return digit;
}

List<int> patternPosition(int typeNumber) =>
    _patternPositionTable[typeNumber - 1];

const int modeNumber = 1 << 0;
const int modeAlphaNum = 1 << 1;
const int mode8bitByte = 1 << 2;
const int modeKanji = 1 << 3;
