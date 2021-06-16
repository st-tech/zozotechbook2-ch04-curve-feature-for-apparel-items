final int V_SIZE = 100; // ベジェ曲線のデフォルトのサンプリング数

// ベジェ曲線。3次ベジェのみを想定。
class Bezier {
  Vertex[] cps; // 4つのcontrol pointでカーブを定義する
  
  Bezier(Vertex[] cps) {
    this.cps = cps;
  }

  // ベジェ曲線を構成する頂点のリストを返す
  Vertex[] getVertices() {
    return getVertices(V_SIZE);
  }

  Vertex[] getVertices(int n) {
    Vertex[] vertices = new Vertex[n];
    for (int i = 0; i < n; i++) {
      float t = 1.0 / (n - 1) * i;
      float xt = 
        pow((1 - t), 3) * cps[0].x + 
        3 * pow((1 - t), 2) * t * cps[1].x + 
        3 * (1 - t) * pow(t, 2) * cps[2].x + 
        pow(t, 3) * cps[3].x;
      float yt = 
        pow((1 - t), 3) * cps[0].y + 
        3 * pow((1 - t), 2) * t * cps[1].y + 
        3 * (1 - t) * pow(t, 2) * cps[2].y + 
        pow(t, 3) * cps[3].y;
      vertices[i] = new Vertex(xt, yt);
    }
    return vertices;
  }

  // ベジェ曲線の長さを返す
  float getLength() {
    float l = 0;
    Vertex prev = new Vertex(0, 0);
    for (int i = 0; i < V_SIZE; i++) {
      float t = 1.0 / (V_SIZE - 1) * i;
      float xt = 
        pow((1 - t), 3) * cps[0].x + 
        3 * pow((1 - t), 2) * t * cps[1].x + 
        3 * (1 - t) * pow(t, 2) * cps[2].x + 
        pow(t, 3) * cps[3].x;
      float yt = 
        pow((1 - t), 3) * cps[0].y + 
        3 * pow((1 - t), 2) * t * cps[1].y + 
        3 * (1 - t) * pow(t, 2) * cps[2].y + 
        pow(t, 3) * cps[3].y;
      Vertex current = new Vertex(xt, yt);
      if (i != 0) {
        l += sqrt(pow(current.x - prev.x, 2) + pow(current.y - prev.y, 2));
      }
      prev = current;
    }
    return l;
  }

  // サンプリングされたベジェ曲線の各点の符号付き曲率を返す
  // Ref: https://qiita.com/Ken227/items/99a7f3ce649299aa1967
  float[] getCurvature() {
    float[] k = new float[V_SIZE];
    for (int i = 0; i < V_SIZE; i++) {
      float t = 1.0 / (V_SIZE - 1) * i;
      Vertex fd = getFirstDerivative(t); // 点tでベジェ曲線を微分
      Vertex sd = getSecondDerivative(t); // 2階微分
      k[i] = (fd.x * sd.y - sd.x * fd.y) / pow(pow(fd.x, 2) + pow(fd.y, 2), 1.5);     
    }
    return k;
  }

  // サンプリングされたベジェ曲線の各点の曲率ベクトルを返す
  Vertex[] getCurvatureVector() {
    Vertex[] k = new Vertex[V_SIZE];
    for (int i = 0; i < V_SIZE; i++) {
      float t = 1.0 / (V_SIZE - 1) * i;
      Vertex fd = getFirstDerivative(t);
      Vertex sd = getSecondDerivative(t);
      float norm = sqrt(pow(fd.x, 2) + pow(fd.y, 2));
      float kX = (sd.x - fd.x / norm * (sd.x * fd.x / norm + sd.y * fd.y / norm)) / (pow(fd.x, 2) + pow(fd.y, 2));
      float kY = (sd.y - fd.y / norm * (sd.x * fd.x / norm + sd.y * fd.y / norm)) / (pow(fd.x, 2) + pow(fd.y, 2));
      k[i] = new Vertex(kX, kY);
    }
    return k;
  }

  // 曲率kをtで微分
  float[] getCurvatureChangeRate() {
    float[] dkdt = new float[V_SIZE];
    for (int i = 0; i < V_SIZE; i++) {
      float t = 1.0 / (V_SIZE - 1) * i;
      Vertex fd = getFirstDerivative(t); 
      Vertex sd = getSecondDerivative(t);
      Vertex td = getThirdDerivative(t);
      float f = pow(fd.x, 2) + pow(fd.y, 2);
      float g = fd.x * sd.y - sd.x * fd.y;
      float dfdt = 2 * fd.x * sd.x + 2 * fd.y * sd.y;
      float dgdt = sd.x * sd.y + fd.x * td.y - td.x * fd.y - sd.x * sd.y;
      dkdt[i] = (dgdt * pow(f, 1.5) - 1.5 * sqrt(f) * dfdt * g) / pow(f, 3);
    }
    return dkdt;
  }

  // ベジェ曲線を描画
  void draw() {
    noFill();
    stroke(0);
    strokeWeight(1);

    // ベジェハンドルを描画
    line(cps[0].x, cps[0].y, cps[1].x, cps[1].y);
    line(cps[2].x, cps[2].y, cps[3].x, cps[3].y);

    // ベジェ曲線を描画
    bezier(cps[0].x, cps[0].y, cps[1].x, cps[1].y, cps[2].x, cps[2].y, cps[3].x, cps[3].y);
  }

  // 曲率ベクトルを描画
  void drawCurvatureVector() {
    noFill();
    stroke(255, 0, 0);
    strokeWeight(1);
    
    final float scale = -3000; // 描画用の倍率設定
    Vertex[] vertices = getVertices();
    Vertex[] k = getCurvatureVector();
    for (int i = 0; i < k.length; i++) {
      k[i].x *= scale;
      k[i].y *= scale;
      k[i].x += vertices[i].x;
      k[i].y += vertices[i].y;
      line(vertices[i].x, vertices[i].y, k[i].x, k[i].y);
    }
  }

  // 点tでベジェ曲線を微分
  Vertex getFirstDerivative(float t) {
    float x = -3 * pow((1 - t), 2) * cps[0].x + 3 * (-3 * t + 1) * (-t + 1) * cps[1].x + 3 * t * (2 - 3 * t) * cps[2].x + 3 * pow(t, 2) * cps[3].x;
    float y = -3 * pow((1 - t), 2) * cps[0].y + 3 * (-3 * t + 1) * (-t + 1) * cps[1].y + 3 * t * (2 - 3 * t) * cps[2].y + 3 * pow(t, 2) * cps[3].y;
    return new Vertex(x, y); 
  }

  // 2階微分
  Vertex getSecondDerivative(float t) {
    float x = 6 * (1 - t) * cps[0].x + 6 * (3 * t - 2) * cps[1].x + 6 * (1 - 3 * t) * cps[2].x + 6 * t * cps[3].x;
    float y = 6 * (1 - t) * cps[0].y + 6 * (3 * t - 2) * cps[1].y + 6 * (1 - 3 * t) * cps[2].y + 6 * t * cps[3].y;
    return new Vertex(x, y);
  }

  // 3階微分
  Vertex getThirdDerivative(float t) {
    float x = -6 * cps[0].x + 18 * cps[1].x - 18 * cps[2].x + 6 * cps[3].x;
    float y = -6 * cps[0].y + 18 * cps[1].y - 18 * cps[2].y + 6 * cps[3].y;
    return new Vertex(x, y);
  }
}