import controlP5.*; // UIコンポーネント ControlP5をインポート
ControlP5 cp5;

boolean isDragged = false; // 頂点がドラッグされているか
Vertex draggedVertex = new Vertex(); // ドラッグされた頂点
String displayMode = "none"; // データの表示/非表示を制御する

// 頂点を初期化
Vertex [] vertices = new Vertex[] {
  new Vertex("mA", 239, 22), 
  new Vertex("hmAB", 303, 93), 
  new Vertex("hmBA", 294, 144), 
  new Vertex("mB", 261, 190), 

  new Vertex("hmBC", 205, 268), 
  new Vertex("hmCB", 83, 331), 
  new Vertex("mC", 147, 462), 

  new Vertex("gA", 589, 41), 
  new Vertex("hgAB", 559, 116), 
  new Vertex("hgBA", 505, 168), 
  new Vertex("gB", 467, 222), 

  new Vertex("hgBC", 420, 288), 
  new Vertex("hgCB", 398, 357), 
  new Vertex("gC", 475, 472), 
};

// カーブを初期化
Curve m = new Curve(
  new Bezier[] {
    new Bezier(new Vertex[] {vertices[0], vertices[1], vertices[2], vertices[3]}), 
    new Bezier(new Vertex[] {vertices[3], vertices[4], vertices[5], vertices[6]})
  }
);

Curve g = new Curve(
  new Bezier[] {
    new Bezier(new Vertex[] {vertices[7], vertices[8], vertices[9], vertices[10]}), 
    new Bezier(new Vertex[] {vertices[10], vertices[11], vertices[12], vertices[13]})
  }
);

// 描画領域を初期化
void setup() {
  size(1200, 700);
  cp5 = new ControlP5(this);

  // displayModeを切り替えるラジオボタンを表示
  cp5.addRadioButton("displayMode")
  .setPosition(10, 10)
  .setItemWidth(20)
  .setItemHeight(20)
  .addItem("None", 0)
  .addItem("Curvature", 1)
  .addItem("P-type fourier descriptor", 2)
  .addItem("G1 continuous constraint", 3)
  .addItem("G2 continuous constraint", 4)
  .setColorLabel(color(0))
  .activate(0);
}

void displayMode(int id) 
{
  switch(id) 
  {
  case(0):displayMode = "none";break;
  case(1):displayMode = "curvature";break;
  case(2):displayMode = "FD";break;
  case(3):displayMode = "G1";break;
  case(4):displayMode = "G2";break;
  }
}

// 描画用の本処理
// Processing実行中はdraw関数が呼び出され続ける
void draw() {
  background(255);

  // カーブと頂点の描画
  drawVertices(vertices);
  m.draw();
  g.draw();

  //  特徴量のプロット
  drawCurveFeatures(m, g);

  // 各displayModeに対応したデータをカーブ上に描画する
  if (displayMode == "curvature") {
    m.drawCurvatureVector();
    g.drawCurvatureVector();
  }
  if (displayMode == "FD") {
    FourierDescriptor mfd = m.getFourierDescriptor();
    FourierDescriptor gfd = g.getFourierDescriptor();
    mfd.drawInverse();
    gfd.drawInverse();
  }
  if (displayMode == "G1") {
    m.addG1Constraint();
    g.addG1Constraint();
  }
  if (displayMode == "G2") {
    m.addG2Constraint();
    g.addG2Constraint();
  }

}

// 頂点を描画
void drawVertices(Vertex[] vertices) {
  for (Vertex v: vertices) {
    v.draw();
  }
}

// マウスでドラッグした頂点を動かす
void mouseDragged() {
  for (Vertex v: vertices) {
    float pw = POINT_WIDTH;
    if (
      v.x - pw / 2 < mouseX &&
      v.x + pw / 2 > mouseX &&
      v.y - pw / 2 < mouseY &&
      v.y + pw / 2 > mouseY
    ) {
      isDragged = true;
      draggedVertex = v;
    }
    if (isDragged) {
      draggedVertex.x = mouseX;
      draggedVertex.y = mouseY;
    }
  }
}

void mouseReleased() {
  isDragged = false;
}

//  特徴量のプロット
void drawCurveFeatures(Curve m, Curve g) {

  int orgX = 750;
  int orgY = 20;

  // 相関係数の目盛り描画
  text("correlation coefficient ", orgX, orgY);
  text("-1", orgX + 190, orgY - 8);
  text("0", orgX + 295, orgY - 8);
  text("1", orgX + 395, orgY - 8);
  stroke(0);
  for (int i = 0; i < 21; i++) {
    line(orgX + 200 + i * 10, orgY - 5, orgX + 200 + i * 10, orgY);
  }

  // 相関係数の描画
  Correlation corrK = new Correlation("curvature", m.getCurvature(), g.getCurvature());
  corrK.draw(orgX, orgY + 20, 100);

  Correlation corrDKDT = new Correlation("curvature change ratio", m.getCurvatureChangeRate(), g.getCurvatureChangeRate());
  corrDKDT.draw(orgX, orgY + 40, 100);

  FourierDescriptor mfd = m.getFourierDescriptor();
  FourierDescriptor gfd = g.getFourierDescriptor();
  Correlation corrFD = new Correlation("fourier descriptor", mfd.spectrum, gfd.spectrum);
  corrFD.draw(orgX, orgY + 60, 100);

  // 各特徴量の描画
  m.drawCurvature("m curvature", orgX, 150);
  g.drawCurvature("g curvature", orgX, 250);
  m.drawCurvatureChangeRate("m curvature change ratio", orgX, 350);
  g.drawCurvatureChangeRate("g curvature change ratio", orgX, 450);
  mfd.drawSpectrum("m fourier descriptor", orgX, 550);
  gfd.drawSpectrum("g fourier descriptor", orgX, 650);
}