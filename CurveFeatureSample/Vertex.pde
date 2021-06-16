final float POINT_WIDTH = 10; // 画面描画時の頂点の幅（ピクセル）

class Vertex {
  String name;
  float x, y;

  Vertex() {}

  Vertex(float x, float y) {
    this.x = x;
    this.y = y;
  }

  Vertex(String n, float x, float y) {
    this.name = n;
    this.x = x;
    this.y = y;
  }

  void draw() {
    fill(0);
    noStroke();
    float pw = POINT_WIDTH;
    square(this.x - pw / 2, this.y - pw / 2, pw);
    text(this.name, this.x + pw, this.y + pw / 2);
  }
}