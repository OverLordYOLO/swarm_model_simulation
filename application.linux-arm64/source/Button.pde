class Button { //<>// //<>//

  int padding = 5;
  int posX, posY, wid, hei, textX, textY, textSize;
  color col, colHighlight, colText;
  String text;

  Button(int posX, int posY, int textSize, color col, color colHighlight, color colText, String text) {
    this.posX = posX;
    this.posY = posY;
    this.col = col;
    this.colHighlight = colHighlight;
    this.colText = colText;
    textSize(textSize);
    this.text = text;
    this.textSize = textSize;
    calculateParameters();
  }

  void calculateParameters() {
    this.textX = posX + padding;
    this.textY = posY + textSize + padding;
    textSize(textSize);
    this.wid = (ceil(textWidth(text)) + padding * 2);
    this.hei = textSize + 2 * padding;
  }

  Button SetPositionNextToOrUnder(Button button) {
    int x = button.posX + button.wid + 20;
    int y = button.posY;
    if ((x + wid) > width) {
      x = 10;
      y = button.posY + hei + 10;
    }
    posX = x;
    posY = y;
    calculateParameters();
    return this;
  }

  void Resize(int size) {
    this.textSize = size;
    calculateParameters();
  }

  void Show() {
    if (IsHoveringOver()) {
      fill(colHighlight);
    } else {
      fill(col);
    }
    rect(posX, posY, wid, hei);

    fill(colText);
    textSize(textSize);
    text(text, textX, textY);
  }

  boolean IsHoveringOver() {
    return mouseOverRectangle(posX, posY, wid, hei);
  }
  boolean mouseOverRectangle(int x, int y, int width, int height) {
    return mouseX <= x+width && mouseX >= x && 
      mouseY <= y+height && mouseY >= y;
  }
}
