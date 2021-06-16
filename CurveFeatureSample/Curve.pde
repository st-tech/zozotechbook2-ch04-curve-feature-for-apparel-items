// 複数のベジェ曲線で構成されるカーブ
class Curve {
  Bezier[] segments;

  Curve(Bezier[] segments) {
    this.segments = segments;
  }

  // カーブを構成する頂点のリストを返す
  Vertex[] getVertices() {
    Vertex[] result = new Vertex[(V_SIZE - 1) * segments.length + 1];
    for (int i = 0; i < segments.length; i++) {
      Vertex[] vertices = segments[i].getVertices();
      for (int j = 0; j < vertices.length; j++) {
        result[(V_SIZE - 1) * i + j] = vertices[j];
      }
    }
    return result;
  }
  // サンプリングされたカーブの各点の符号付き曲率を返す
  float[] getCurvature() {
    float[] result = new float[V_SIZE * segments.length]; // カーブの結合点は曲率を2つもつ
    for (int i = 0; i < segments.length; i++) {
      float[] k = segments[i].getCurvature();
      for (int j = 0; j < k.length; j++) {
        result[V_SIZE * i + j] = k[j];
      }
    }
    return result;
  }

  // 符号付き曲率の変化率を返す
  float[] getCurvatureChangeRate() {
    float[] result = new float[V_SIZE * segments.length]; // カーブの結合点は曲率を2つもつ
    for (int i = 0; i < segments.length; i++) {
      float[] k = segments[i].getCurvatureChangeRate();
      for (int j = 0; j < k.length; j++) {
        result[V_SIZE * i + j] = k[j];
      }
    }
    return result;
  }

  // 等間隔に分割された頂点リストを返す
  // Ref: https://stackoverflow.com/questions/43726836/resample-curve-into-even-length-segments-using-c
  Vertex[] getEquallyDevidedVertices() {
    int n = V_SIZE * 5; // 分割の準備として出力の想定より高密度にサンプリングする
    float curveLength = 0;
    Vertex[] vertices = new Vertex[(n - 1) * segments.length + 1];
    for (int i = 0; i < segments.length; i++) {
      curveLength += segments[i].getLength();
      Vertex[] bezierVertices = segments[i].getVertices(n);
      for (int j = 0; j < bezierVertices.length; j++) {
        vertices[(n - 1) * i + j] = bezierVertices[j];
      }
    }
    
    // 頂点数が m 個になるよう等分する
    int m = V_SIZE * segments.length;
    Vertex[] result = new Vertex[m];
    float segmentLength = curveLength / (m - 1);
    float srcSegmentOffset = 0;
    float srcSegmentLength = sqrt(pow(vertices[1].x - vertices[0].x, 2) + pow(vertices[1].y - vertices[0].y, 2));
    int j = 1;
    result[0] = vertices[0];
    for (int i = 1; i < m - 1; i++) {
      float nextOffset = segmentLength * i;
      while(srcSegmentOffset + srcSegmentLength < nextOffset) {
        srcSegmentOffset += srcSegmentLength;
        j++;
        srcSegmentLength = sqrt(pow(vertices[j].x - vertices[j - 1].x, 2) + pow(vertices[j].y - vertices[j - 1].y, 2));
      }
      float partOffset = nextOffset - srcSegmentOffset;
      float partRatio = partOffset / srcSegmentLength;
      float x = vertices[j - 1].x + partRatio * (vertices[j].x - vertices[j - 1].x);
      float y = vertices[j - 1].y + partRatio * (vertices[j].y - vertices[j - 1].y);
      result[i] = new Vertex(x, y);
    }
    result[m - 1] = vertices[vertices.length - 1];
    return result;
  }

  // カーブのフーリエ記述子を返す
  FourierDescriptor getFourierDescriptor() {
    Vertex[] vertices = getEquallyDevidedVertices();
    FourierDescriptor fd = new FourierDescriptor(vertices);
    return fd;
  }

  void draw() {
    for (Bezier b: segments) {
      b.draw();
    }
  }

  void drawCurvature(String name, float x, float y) {
    final float scale = -5000; // 描画時の倍率
    float[] k = getCurvature();
    text(name, x, y - 50);
    fill(0);
    noStroke();
    for (int i = 0; i < k.length; i++) {
      rect(x + 2 * i, y, 1, k[i] * scale);
    }
  }

  void drawCurvatureChangeRate(String name, float x, float y) {
    final float scale = -500; // 描画時の倍率
    float[] dkdt = getCurvatureChangeRate();
    text(name, x, y - 50);
    fill(0);
    noStroke();
    for (int i = 0; i < dkdt.length; i++) {

      rect(x + 2 * i, y, 1, dkdt[i] * scale);
    }
  }

  void drawCurvatureVector() {
    for (Bezier b: segments) {
      b.drawCurvatureVector();
    }
  }

  void addG1Constraint() {
    Vertex connectingP = segments[0].cps[3]; // 2つのカーブの接続点
    Vertex handle1 = segments[0].cps[2]; // 接続点から生えているBezierハンドル
    Vertex handle2 = segments[1].cps[1]; // 接続点から生えているBezierハンドル

    float handleLength1 = sqrt(pow(handle1.x - connectingP.x, 2) + pow(handle1.y - connectingP.y, 2));
    float handleLength2 = sqrt(pow(handle2.x - connectingP.x, 2) + pow(handle2.y - connectingP.y, 2));
    float k = handleLength1 / handleLength2;

    // 接続点から生えているハンドルがドラッグされている場合、もう一方のハンドルをG1連続で縛る
    if (draggedVertex.x == handle1.x && draggedVertex.y == handle1.y) {
      segments[1].cps[1].x = -1.0 / k * handle1.x + (1.0 + k) / k * connectingP.x;
      segments[1].cps[1].y = -1.0 / k * handle1.y + (1.0 + k) / k * connectingP.y;
    } else if (draggedVertex.x == handle2.x && draggedVertex.y == handle2.y) {
      segments[0].cps[2].x = (1.0 + k) * connectingP.x - k * handle2.x;
      segments[0].cps[2].y = (1.0 + k) * connectingP.y - k * handle2.y;
    }

    // 制約つきのハンドルを描画
    stroke(255, 0, 0);
    strokeWeight(10);
    point(handle1.x, handle1.y);
    point(handle2.x, handle2.y);
    strokeWeight(1);
    line(handle1.x, handle1.y, handle2.x, handle2.y);
  }

  // Ref: https://www.unisys.co.jp/tec_info/tr114/11403.pdf
  void addG2Constraint() {

    // 2つのカーブの長さ比sを算出
    float totalCurveLength = 0;
    for(Bezier b: segments) {
      totalCurveLength += b.getLength();
    }
    float s = segments[0].getLength() / totalCurveLength;

    // 2つのベジェのcpを計算する
    // 2つの3次ベジェはそれぞれcpを4つもち、p3が両カーブで共有されている

    // 2つのベジェのエッジ（p0, p3, p6）はG2連続の影響を受けないものとする
    Vertex p0 = segments[0].cps[0];
    Vertex p3 = segments[0].cps[3];
    Vertex p6 = segments[1].cps[3];

    // 2つのカーブを構成するベジェハンドル（p1, p2, p4, p5）をG2連続で縛る
    Vertex p1;
    Vertex p2;
    Vertex p4;
    Vertex p5;

    
    if (draggedVertex.x == segments[0].cps[1].x && draggedVertex.y == segments[0].cps[1].y) { // p1がドラッグされている場合
      p1 = segments[0].cps[1];
      p2 = new Vertex(
        -pow(1.0 - s, 2) / 3.0 * p0.x + (1.0 - s) * p1.x + 1.0 / 3.0 / (1.0 - s) * p3.x - pow(s, 3) / 3.0 / (1.0 - s) * p6.x, 
        -pow(1.0 - s, 2) / 3.0 * p0.y + (1.0 - s) * p1.y + 1.0 / 3.0 / (1.0 - s) * p3.y - pow(s, 3) / 3.0 / (1.0 - s) * p6.y
        );
      p4 = new Vertex(
        pow(1.0 - s, 3) / s * p0.x - 3 * pow(1.0 - s, 2) / s * p1.x + 2 * (1.0 - s) / s * p2.x + pow(s, 2) * p6.x, 
        pow(1.0 - s, 3) / s * p0.y - 3 * pow(1.0 - s, 2) / s * p1.y + 2 * (1.0 - s) / s * p2.y + pow(s, 2) * p6.y
        );
      p5 = new Vertex(
        pow(1.0 - s, 3) / 3.0 / pow(s, 2) * p0.x - (1.0 - s) / 3.0 / pow(s, 2) * p2.x + 2.0 / 3.0 / s * p4.x + s / 3.0 * p6.x, 
        pow(1.0 - s, 3) / 3.0 / pow(s, 2) * p0.y - (1.0 - s) / 3.0 / pow(s, 2) * p2.y + 2.0 / 3.0 / s * p4.y + s / 3.0 * p6.y
        );
    } else if (draggedVertex.x == segments[1].cps[1].x && draggedVertex.y == segments[1].cps[1].y) { // p4がドラッグされている場合
      p4 = segments[1].cps[1];
      p2 = new Vertex(1.0 / (1.0 - s) * p3.x - s / (1.0 - s) * p4.x, 1.0 / (1.0 - s) * p3.y - s / (1.0 - s) * p4.y);
      p1 = new Vertex(
        (1.0 - s) / 3.0 * p0.x + 2.0 / 3.0 / (1.0 - s) * p2.x - s / 3.0 / pow(1.0 - s, 2) * p4.x + pow(s, 3) / 3.0 / pow(1.0 - s, 2) * p6.x, 
        (1.0 - s) / 3.0 * p0.y + 2.0 / 3.0 / (1.0 - s) * p2.y - s / 3.0 / pow(1.0 - s, 2) * p4.y + pow(s, 3) / 3.0 / pow(1.0 - s, 2) * p6.y
        );
      p5 = new Vertex(
        pow(1.0 - s, 3) / 3.0 / pow(s, 2) * p0.x - (1.0 - s) / 3.0 / pow(s, 2) * p2.x + 2.0 / 3.0 / s * p4.x + s / 3.0 * p6.x, 
        pow(1.0 - s, 3) / 3.0 / pow(s, 2) * p0.y - (1.0 - s) / 3.0 / pow(s, 2) * p2.y + 2.0 / 3.0 / s * p4.y + s / 3.0 * p6.y
        );
    } else if (draggedVertex.x == segments[1].cps[2].x && draggedVertex.y == segments[1].cps[2].y) { // p5がドラッグされている場合
      p5 = segments[1].cps[2];
      p4 = new Vertex(
        -pow(1.0 - s, 3) / 3.0 / s * p0.x + 1.0 / 3.0 / s * p3.x + s * p5.x - pow(s, 2) / 3.0 * p6.x, 
        -pow(1.0 - s, 3) / 3.0 / s * p0.y + 1.0 / 3.0 / s * p3.y + s * p5.y - pow(s, 2) / 3.0 * p6.y
        );
      p2 = new Vertex(1.0 / (1.0 - s) * p3.x - s / (1.0 - s) * p4.x, 1.0 / (1.0 - s) * p3.y - s / (1.0 - s) * p4.y);
      p1 = new Vertex(
        (1.0 - s) / 3.0 * p0.x + 2.0 / 3.0 / (1.0 - s) * p2.x - s / 3.0 / pow(1.0 - s, 2) * p4.x + pow(s, 3) / 3.0 / pow(1.0 - s, 2) * p6.x, 
        (1.0 - s) / 3.0 * p0.y + 2.0 / 3.0 / (1.0 - s) * p2.y - s / 3.0 / pow(1.0 - s, 2) * p4.y + pow(s, 3) / 3.0 / pow(1.0 - s, 2) * p6.y
        );
    } else { // p2またはエッジがドラッグされている場合
      p2 = segments[0].cps[2];
      p4 = new Vertex(1.0 / s * p3.x - (1.0 - s) / s * p2.x, 1.0 / s * p3.y - (1.0 - s) / s * p2.y);
      p1 = new Vertex(
        (1.0 - s) / 3.0 * p0.x + 2.0 / 3.0 / (1.0 - s) * p2.x - s / 3.0 / pow(1.0 - s, 2) * p4.x + pow(s, 3) / 3.0 / pow(1.0 - s, 2) * p6.x, 
        (1.0 - s) / 3.0 * p0.y + 2.0 / 3.0 / (1.0 - s) * p2.y - s / 3.0 / pow(1.0 - s, 2) * p4.y + pow(s, 3) / 3.0 / pow(1.0 - s, 2) * p6.y
        );
      p5 = new Vertex(
        pow(1.0 - s, 3) / 3.0 / pow(s, 2) * p0.x - (1.0 - s) / 3.0 / pow(s, 2) * p2.x + 2.0 / 3.0 / s * p4.x + s / 3.0 * p6.x, 
        pow(1.0 - s, 3) / 3.0 / pow(s, 2) * p0.y - (1.0 - s) / 3.0 / pow(s, 2) * p2.y + 2.0 / 3.0 / s * p4.y + s / 3.0 * p6.y
        );
    }

    // 計算結果をカーブに適用
    segments[0].cps[1].x = p1.x;
    segments[0].cps[1].y = p1.y;
    segments[0].cps[2].x = p2.x;
    segments[0].cps[2].y = p2.y;
    segments[1].cps[1].x = p4.x;
    segments[1].cps[1].y = p4.y;
    segments[1].cps[2].x = p5.x;
    segments[1].cps[2].y = p5.y;

    // 仮想のcpであるp2-とp2+を描画
    // G2連続を満たす時、p2-とp2+は一致する
    Vertex p2Minus = new Vertex(p1.x + 1 / s * (p2.x - p1.x), p1.y + 1 / s * (p2.y - p1.y));
    Vertex p2Plus = new Vertex(p5.x + 1 / (1 - s) * (p4.x - p5.x), p5.y + 1 / (1 - s) * (p4.y - p5.y));
    stroke(255, 0, 0);
    strokeWeight(10);
    point(p2Minus.x, p2Minus.y);
    point(p2Plus.x, p2Plus.y);
    strokeWeight(1);
    line(p2Minus.x, p2Minus.y, p1.x, p1.y);
    line(p2Plus.x, p2Plus.y, p5.x, p5.y);
  }
}