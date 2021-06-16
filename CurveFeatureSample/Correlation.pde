// 2つの配列の相関
class Correlation {
  String name;
  float coefficient;

  Correlation(String name, float[] a, float[] b) {
    this.name = name;
    float aSD = 0; // aの標準偏差
    float bSD = 0; // bの標準偏差
    float covariance = 0;
    int n = max(a.length, b.length);
    float aAve = average(a);
    float bAve = average(b);
    for (int i = 0; i < n; i++) {
      aSD += pow(a[i] - aAve, 2) / n;
      bSD += pow(b[i] - bAve, 2) / n;
      covariance += (a[i] - aAve) * (b[i] - bAve) / n;
    }
    float sd = sqrt(aSD) * sqrt(bSD);
    coefficient = covariance / sd;
  }

  void draw(float x, float y, float scale) {
    text(name + " " + String.format("%.7f", coefficient), x, y);
    fill(0);
    noStroke();
    rect(x + 300, y - 10, coefficient * scale, 10);
  }
}

float average(float[] values) {
  float sum = 0;
  for(float v: values) {
    sum += v;
  }
  return sum / values.length;
}