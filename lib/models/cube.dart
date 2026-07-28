enum CubeType { normal, joker, hint }

class Cube {
  final List<String> faces;
  int topFaceIndex;
  int rotationLimit;
  final CubeType type;

  Cube({
    required this.faces,
    required this.topFaceIndex,
    required this.rotationLimit,
    this.type = CubeType.normal,
  });

  String get currentLetter => faces[topFaceIndex];
  bool get canRotate => rotationLimit > 0;

  void rotate() {
    if (rotationLimit > 0) {
      topFaceIndex = (topFaceIndex + 1) % faces.length;
      rotationLimit--;
    }
  }
}
