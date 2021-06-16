// P形フーリエ既述子
// Ref: https://www.jstage.jst.go.jp/article/jsbbr/7/3/7_3_133/_pdf

class FourierDescriptor {
  float[] spectrum; // 記述子の複素平面上のノルム
  float[] re; // 記述子の実部
  float[] im; // 記述子の虚部
  int orgSize; // インプット（元のカーブ）の頂点数
  final int d = 10; // 記述子の次数
  float segLen; // カーブを構成する頂点の間隔
  Vertex offset; // 原点からのオフセット

  FourierDescriptor(Vertex[] in) {
    // 初期化
    orgSize = in.length;
    int l = orgSize - 1; 
    spectrum = new float[2 * d];
    re = new float[2 * d];
    im = new float[2 * d];
    segLen = sqrt(pow((in[1].x - in[0].x), 2) + pow((in[1].y - in[0].y), 2));  
    offset = in[0];
    
    for (int k = 0 ;k < l; k++) {
      // 変数変換
      int i = 0;
      if (k < d) {
        i = k + d;
      } else if (l - k <= d) {
        i = k + d - l;
      } else {
        continue;
      }

      // 記述子とスペクトルを算出
      for (int n = 0; n < l; n++) {   
        re[i] += ((in[n + 1].x - in[n].x) * cos(2.0 * PI * n * k / l) + (in[n + 1].y - in[n].y) * sin(2.0 * PI * n * k / l)) / segLen;
        im[i] += ((in[n + 1].y - in[n].y) * cos(2.0 * PI * n * k / l) - (in[n + 1].x - in[n].x) * sin(2.0 * PI * n * k / l)) / segLen;
      }
      re[i] /= l;
      im[i] /= l;
      spectrum[i] = sqrt(pow(re[i], 2) + pow(im[i], 2));   
    }
  }

  // 逆変換で構成したカーブを元のカーブに重ねて表示
  void drawInverse() {
    noFill();
    stroke(255, 0, 0);
    strokeWeight(2);

    int l = orgSize - 1;
    Vertex v = new Vertex();
    Vertex prev = new Vertex();
    float x = 0;
    float y = 0;
    for (int n = 0; n < l; n++) {
      // 頂点をプロット
      if (n == 0) {
        v = new Vertex(offset.x, offset.y);
      } else {
        v = new Vertex(x + prev.x, y + prev.y);
      }
      point(v.x, v.y);
      
      // 変数を初期化
      prev = v;
      x = 0;
      y = 0;

      // 逆変換
      for (int k = 0; k < re.length; k++) {
        // 変数変換
        int i = 0;
        if (k < d) {
          i = k - d + l; 
        } else if (d <= k) {
          i = k - d;
        } else {
          continue;
        }

        // 座標の算出
        x += segLen * (re[k] * cos(2.0 * PI * n * i / l) - im[k] * sin(2.0 * PI * n * i / l));
        y += segLen * (re[k] * sin(2.0 * PI * n * i / l) + im[k] * cos(2.0 * PI * n * i / l));
      }
    }
  }

  // スペクトルをプロット
  void drawSpectrum(String title, int x, int y) {
    final float scale = -50; // 描画用の倍率
    final int width = 200 / d; // 棒グラフの幅
    text(title, x, y - 50);
    for (int i = 0; i < spectrum.length; i++) {
      fill(0);
      noStroke();
      rect(x + width * i, y, width, spectrum[i] * scale);
      stroke(0);
    }
  }
}