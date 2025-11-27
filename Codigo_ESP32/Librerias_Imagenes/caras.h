#ifndef CARAS_H
#define CARAS_H

#include <Arduino.h>
#include <SPI.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ILI9341.h>
#include <math.h>

// Referencia externa al objeto 'tft' que creaste en tu main.cpp
extern Adafruit_ILI9341 tft;

// ==========================================
//             FUNCIONES DE CARAS
// ==========================================

// Dibuja ojos azules simples + sonrisa suave (fondo blanco).
void caraFelizBasica() {
  // --- Fondo y centro de pantalla ---
  tft.fillScreen(ILI9341_WHITE);
  const int CX = tft.width() / 2;
  const int CY = tft.height() / 2;

  // --- Geometría de la cara ---
  const int SEP_X   = 70;   // separación horizontal de los ojos
  const int EYE_Y   = CY - 40;
  const int R_IRIS1 = 22;   // anillo exterior (azul claro)
  const int R_IRIS2 = 16;   // anillo interior (azul más oscuro)
  const int R_PUP   = 10;   // pupila

  // --- Colores (RGB565) ---
  uint16_t AZUL_EXT = tft.color565(0, 180, 255);
  uint16_t AZUL_INT = tft.color565(0, 140, 255);
  uint16_t NEGRO    = ILI9341_BLACK;
  uint16_t BLANCO   = ILI9341_WHITE;

  // === OJO IZQUIERDO ===
  int ex = CX - SEP_X, ey = EYE_Y;
  // Iris doble (dos círculos para dar aspecto de anillo)
  tft.fillCircle(ex, ey, R_IRIS1, AZUL_EXT);
  tft.fillCircle(ex, ey, R_IRIS2, AZUL_INT);
  // Pupila
  tft.fillCircle(ex, ey, R_PUP, NEGRO);
  // Reflejo
  tft.fillCircle(ex - 5, ey - 7, 3, BLANCO);

  // === OJO DERECHO ===
  ex = CX + SEP_X; ey = EYE_Y;
  tft.fillCircle(ex, ey, R_IRIS1, AZUL_EXT);
  tft.fillCircle(ex, ey, R_IRIS2, AZUL_INT);
  tft.fillCircle(ex, ey, R_PUP, NEGRO);
  tft.fillCircle(ex - 5, ey - 7, 3, BLANCO);

  // === Boca (arco de círculo) ===
  // Centro de la boca y radio
  const int BX = CX, BY = CY + 45, R = 38;
  // Dibuja puntos del arco desde 20° a 160° para que sea una sonrisa
  for (int a = 20; a <= 160; a++) {
    float rad = a * 0.0174533f; // grados -> radianes
    int x = BX + R * cos(rad);
    int y = BY + R * sin(rad);
    tft.drawPixel(x, y, NEGRO);
    tft.drawPixel(x, y + 1, NEGRO); // pequeño grosor
  }
}

// Dibuja ojos azules simples + boca triste (arco invertido), fondo blanco.
void caraTristeBasica() {
  tft.fillScreen(ILI9341_WHITE);
  const int CX = tft.width() / 2;
  const int CY = tft.height() / 2;

  // Geometría
  const int SEP_X   = 70;
  const int EYE_Y   = CY - 40;
  const int R_IRIS1 = 22;
  const int R_IRIS2 = 16;
  const int R_PUP   = 10;

  // Colores
  uint16_t AZUL_EXT = tft.color565(0, 180, 255);
  uint16_t AZUL_INT = tft.color565(0, 140, 255);
  uint16_t NEGRO    = ILI9341_BLACK;
  uint16_t BLANCO   = ILI9341_WHITE;

  // Ojo izquierdo
  int ex = CX - SEP_X, ey = EYE_Y;
  tft.fillCircle(ex, ey, R_IRIS1, AZUL_EXT);
  tft.fillCircle(ex, ey, R_IRIS2, AZUL_INT);
  tft.fillCircle(ex, ey, R_PUP, NEGRO);
  tft.fillCircle(ex - 5, ey - 7, 3, BLANCO);

  // Ojo derecho
  ex = CX + SEP_X; ey = EYE_Y;
  tft.fillCircle(ex, ey, R_IRIS1, AZUL_EXT);
  tft.fillCircle(ex, ey, R_IRIS2, AZUL_INT);
  tft.fillCircle(ex, ey, R_PUP, NEGRO);
  tft.fillCircle(ex - 5, ey - 7, 3, BLANCO);

  // Boca triste (arco invertido): 200° a 340°
  const int BX = CX, BY = CY + 45, R = 34;
  for (int a = 200; a <= 340; a++) {
    float rad = a * 0.0174533f;
    int x = BX + R * cos(rad);
    int y = BY + R * sin(rad);
    tft.drawPixel(x, y, NEGRO);
    tft.drawPixel(x, y + 1, NEGRO);
  }
}

// Ojos azules + boquita “O” (sorpresa), fondo blanco.
void caraSorpresaBasica() {
  tft.fillScreen(ILI9341_WHITE);
  const int CX = tft.width() / 2;
  const int CY = tft.height() / 2;

  // Geometría
  const int SEP_X   = 70;
  const int EYE_Y   = CY - 40;
  const int R_IRIS1 = 22;   // anillo exterior
  const int R_IRIS2 = 16;   // anillo interior
  const int R_PUP   = 10;   // pupila

  // Colores
  uint16_t AZUL_EXT = tft.color565(0, 180, 255);
  uint16_t AZUL_INT = tft.color565(0, 140, 255);
  uint16_t NEGRO    = ILI9341_BLACK;
  uint16_t BLANCO   = ILI9341_WHITE;

  // Ojo izquierdo
  int ex = CX - SEP_X, ey = EYE_Y;
  tft.fillCircle(ex, ey, R_IRIS1, AZUL_EXT);
  tft.fillCircle(ex, ey, R_IRIS2, AZUL_INT);
  tft.fillCircle(ex, ey, R_PUP, NEGRO);
  tft.fillCircle(ex - 5, ey - 7, 3, BLANCO);

  // Ojo derecho
  ex = CX + SEP_X; ey = EYE_Y;
  tft.fillCircle(ex, ey, R_IRIS1, AZUL_EXT);
  tft.fillCircle(ex, ey, R_IRIS2, AZUL_INT);
  tft.fillCircle(ex, ey, R_PUP, NEGRO);
  tft.fillCircle(ex - 5, ey - 7, 3, BLANCO);

  // Boca “O” (círculo relleno)
  tft.fillCircle(CX, CY + 45, 10, NEGRO);
}

// Ojo izquierdo “guiño” (línea) + ojo derecho normal + sonrisa.
void caraGuinoBasica() {
  tft.fillScreen(ILI9341_WHITE);
  const int CX = tft.width() / 2;
  const int CY = tft.height() / 2;

  // Geometría
  const int SEP_X   = 70;
  const int EYE_Y   = CY - 40;
  const int R_IRIS1 = 22;   // anillo exterior (azul claro)
  const int R_IRIS2 = 16;   // anillo interior (azul más oscuro)
  const int R_PUP   = 10;   // pupila

  // Colores
  uint16_t AZUL_EXT = tft.color565(0, 180, 255);
  uint16_t AZUL_INT = tft.color565(0, 140, 255);
  uint16_t NEGRO    = ILI9341_BLACK;
  uint16_t BLANCO   = ILI9341_WHITE;

  // === OJO IZQUIERDO (guiño) ===
  int ex = CX - SEP_X, ey = EYE_Y;
  tft.fillCircle(ex, ey, R_IRIS1, AZUL_EXT);
  tft.fillCircle(ex, ey, R_IRIS2, AZUL_INT);
  // “párpado” como línea horizontal centrada (no dibujamos pupila)
  tft.drawFastHLine(ex - 12, ey, 24, NEGRO);
  tft.drawFastHLine(ex - 12, ey + 1, 24, NEGRO); // pequeño grosor

  // === OJO DERECHO (normal) ===
  ex = CX + SEP_X; ey = EYE_Y;
  tft.fillCircle(ex, ey, R_IRIS1, AZUL_EXT);
  tft.fillCircle(ex, ey, R_IRIS2, AZUL_INT);
  tft.fillCircle(ex, ey, R_PUP, NEGRO);
  tft.fillCircle(ex - 5, ey - 7, 3, BLANCO); // brillo

  // === Boca (sonrisa corta) ===
  const int BX = CX, BY = CY + 45, R = 34;
  for (int a = 25; a <= 155; a++) {
    float rad = a * 0.0174533f;
    int x = BX + R * cos(rad);
    int y = BY + R * sin(rad);
    tft.drawPixel(x, y, NEGRO);
    tft.drawPixel(x, y + 1, NEGRO);
  }
}

// Ojos verdosos (enfermo) + boca en zigzag (náusea), fondo blanco.
void caraEnfermoBasica() {
  tft.fillScreen(ILI9341_WHITE);
  const int CX = tft.width() / 2;
  const int CY = tft.height() / 2;

  // Geometría
  const int SEP_X   = 70;
  const int EYE_Y   = CY - 40;
  const int R_IRIS1 = 22;   // anillo exterior (verde-azulado)
  const int R_IRIS2 = 16;   // anillo interior (verde)
  const int R_PUP   = 10;   // pupila

  // Colores (RGB565)
  uint16_t VERDE_EXT = tft.color565(0, 180, 0);   // turquesa/teal
  uint16_t VERDE_INT = tft.color565(0, 255, 0);  // verde claro
  uint16_t NEGRO     = ILI9341_BLACK;
  uint16_t BLANCO    = ILI9341_WHITE;

  // === OJO IZQUIERDO ===
  int ex = CX - SEP_X, ey = EYE_Y;
  tft.fillCircle(ex, ey, R_IRIS1, VERDE_EXT);
  tft.fillCircle(ex, ey, R_IRIS2, VERDE_INT);
  tft.fillCircle(ex, ey, R_PUP, NEGRO);
  tft.fillCircle(ex - 5, ey - 7, 3, BLANCO); // brillo

  // === OJO DERECHO ===
  ex = CX + SEP_X; ey = EYE_Y;
  tft.fillCircle(ex, ey, R_IRIS1, VERDE_EXT);
  tft.fillCircle(ex, ey, R_IRIS2, VERDE_INT);
  tft.fillCircle(ex, ey, R_PUP, NEGRO);
  tft.fillCircle(ex - 5, ey - 7, 3, BLANCO);

  // === Boca en zigzag (malestar) ===
  int y = CY + 45;
  int x0 = CX - 28;             // anchura total ~56 px
  int step = 10;                // longitud de cada tramo
  // dibuja segmentos alternando arriba/abajo
  int x = x0;
  bool arriba = false;
  for (int i = 0; i < 6; i++) { // 6 segmentos
    int x1 = x + step;
    int y1 = y + (arriba ? -5 : +5);
    tft.drawLine(x, y, x1, y1, NEGRO);
    tft.drawLine(x, y+1, x1, y1+1, NEGRO); // grosor
    x = x1; y = y1; arriba = !arriba;
  }
}

// Ojos con pupilas ligeramente hacia arriba-izquierda + boca pequeña de preocupación.
void caraPreocupadoBasica() {
  tft.fillScreen(ILI9341_WHITE);
  const int CX = tft.width() / 2;
  const int CY = tft.height() / 2;

  // Geometría
  const int SEP_X   = 70;    // separación entre ojos
  const int EYE_Y   = CY - 40;
  const int R_IRIS1 = 22;    // anillo exterior (azul claro)
  const int R_IRIS2 = 16;    // anillo interior (azul más oscuro)
  const int R_PUP   = 10;    // pupila

  // Colores
  uint16_t AZUL_EXT = tft.color565(0, 180, 255);
  uint16_t AZUL_INT = tft.color565(0, 140, 255);
  uint16_t NEGRO    = ILI9341_BLACK;
  uint16_t BLANCO   = ILI9341_WHITE;

  // Desplazamiento de pupila (mirada “preocupada” hacia arriba-izq)
  const int DX = -4;
  const int DY = -6;

  // --- OJO IZQUIERDO ---
  int ex = CX - SEP_X, ey = EYE_Y;
  tft.fillCircle(ex, ey, R_IRIS1, AZUL_EXT);
  tft.fillCircle(ex, ey, R_IRIS2, AZUL_INT);
  tft.fillCircle(ex + DX, ey + DY, R_PUP, NEGRO);
  tft.fillCircle(ex + DX - 5, ey + DY - 7, 3, BLANCO); // brillo

  // --- OJO DERECHO ---
  ex = CX + SEP_X; ey = EYE_Y;
  tft.fillCircle(ex, ey, R_IRIS1, AZUL_EXT);
  tft.fillCircle(ex, ey, R_IRIS2, AZUL_INT);
  tft.fillCircle(ex + DX, ey + DY, R_PUP, NEGRO);
  tft.fillCircle(ex + DX - 5, ey + DY - 7, 3, BLANCO);

  // --- Boca pequeña de preocupación (∩) ---
  const int BX = CX, BY = CY + 45, R = 14;
  for (int a = 220; a <= 320; a++) {
    float rad = a * 0.0174533f;
    int x = BX + R * cos(rad);
    int y = BY + R * sin(rad);
    tft.drawPixel(x, y, NEGRO);
    tft.drawPixel(x, y + 1, NEGRO); // leve grosor
  }
}

// Ojos azules simples + boca recta (neutral), fondo blanco.
void caraNeutraBasica() {
  tft.fillScreen(ILI9341_WHITE);
  const int CX = tft.width() / 2;
  const int CY = tft.height() / 2;

  // Geometría
  const int SEP_X   = 70;   // separación horizontal entre ojos
  const int EYE_Y   = CY - 40;
  const int R_IRIS1 = 22;   // anillo exterior (azul claro)
  const int R_IRIS2 = 16;   // anillo interior (azul más oscuro)
  const int R_PUP   = 10;   // pupila

  // Colores
  uint16_t AZUL_EXT = tft.color565(0, 180, 255);
  uint16_t AZUL_INT = tft.color565(0, 140, 255);
  uint16_t NEGRO    = ILI9341_BLACK;
  uint16_t BLANCO   = ILI9341_WHITE;

  // Ojo izquierdo
  int ex = CX - SEP_X, ey = EYE_Y;
  tft.fillCircle(ex, ey, R_IRIS1, AZUL_EXT);
  tft.fillCircle(ex, ey, R_IRIS2, AZUL_INT);
  tft.fillCircle(ex, ey, R_PUP, NEGRO);
  tft.fillCircle(ex - 5, ey - 7, 3, BLANCO);

  // Ojo derecho
  ex = CX + SEP_X; ey = EYE_Y;
  tft.fillCircle(ex, ey, R_IRIS1, AZUL_EXT);
  tft.fillCircle(ex, ey, R_IRIS2, AZUL_INT);
  tft.fillCircle(ex, ey, R_PUP, NEGRO);
  tft.fillCircle(ex - 5, ey - 7, 3, BLANCO);

  // Boca recta (neutral)
  const int BX0 = CX - 35;
  const int BY  = CY + 45;
  const int BW  = 70;
  tft.drawFastHLine(BX0,     BY, BW, NEGRO);
  tft.drawFastHLine(BX0, BY+1, BW, NEGRO); // leve grosor
}

// Ojos con corazones ROJOS en las pupilas + sonrisa.
void caraEnamoradoCorazonesRojos() {
  tft.fillScreen(ILI9341_WHITE);
  const int CX = tft.width() / 2;
  const int CY = tft.height() / 2;

  // Geometría
  const int SEP_X   = 70;
  const int EYE_Y   = CY - 40;
  const int R_IRIS1 = 22;   // anillo exterior
  const int R_IRIS2 = 16;   // anillo interior

  // Colores
  uint16_t AZUL_EXT = tft.color565(0, 180, 255);
  uint16_t AZUL_INT = tft.color565(0, 140, 255);
  uint16_t ROJO     = tft.color565(230, 40, 40);
  uint16_t NEGRO    = ILI9341_BLACK;

  // Función local para dibujar un corazón centrado en (x,y), tamaño s (≈ ancho)
  auto corazon = [&](int x, int y, int s){
    int r = s/2;
    // dos semicírculos (lóbulos)
    tft.fillCircle(x - r/2, y - r/3, r/2, ROJO);
    tft.fillCircle(x + r/2, y - r/3, r/2, ROJO);
    // triángulo inferior
    tft.fillTriangle(x - s/2, y - r/6, x + s/2, y - r/6, x, y + s/2, ROJO);
  };

  // === OJO IZQUIERDO ===
  int ex = CX - SEP_X, ey = EYE_Y;
  tft.fillCircle(ex, ey, R_IRIS1, AZUL_EXT);
  tft.fillCircle(ex, ey, R_IRIS2, AZUL_INT);
  corazon(ex, ey, 12);  // corazón rojo dentro del iris

  // === OJO DERECHO ===
  ex = CX + SEP_X; ey = EYE_Y;
  tft.fillCircle(ex, ey, R_IRIS1, AZUL_EXT);
  tft.fillCircle(ex, ey, R_IRIS2, AZUL_INT);
  corazon(ex, ey, 12);

  // === Boca (sonrisa suave) ===
  const int BX = CX, BY = CY + 45, R = 34;
  for (int a = 25; a <= 155; a++) {
    float rad = a * 0.0174533f;
    int x = BX + R * cos(rad);
    int y = BY + R * sin(rad);
    tft.drawPixel(x, y, NEGRO);
    tft.drawPixel(x, y + 1, NEGRO);
  }
}

void caraDormidoBasica() {
  tft.fillScreen(ILI9341_WHITE);
  const int CX = tft.width() / 2;
  const int CY = tft.height() / 2;

  // Geometría
  const int SEP_X = 70;        // separación entre ojos
  const int EYE_Y = CY - 40;   // altura de los ojos
  const int BX    = CX;        // centro boca
  const int BY    = CY + 45;

  // Colores
  uint16_t NEGRO   = ILI9341_BLACK;
  uint16_t AZUL_Z  = tft.color565(0, 120, 255);

  // ---- util: arco para los párpados "~" ----
  auto arco = [&](int cx, int cy, int r, int a0, int a1) {
    for (int a = a0; a <= a1; a++) {
      float rad = a * 0.0174533f;
      int x = cx + r * cos(rad);
      int y = cy + r * sin(rad);
      tft.drawPixel(x, y, NEGRO);
      tft.drawPixel(x, y + 1, NEGRO);
    }
  };

  // === OJOS cerrados tipo "~ ~" ===
  int ex = CX - SEP_X;
  arco(ex - 8, EYE_Y + 2, 16, 200, 260);
  arco(ex + 8, EYE_Y + 2, 16, 280, 340);
  ex = CX + SEP_X;
  arco(ex - 8, EYE_Y + 2, 16, 200, 260);
  arco(ex + 8, EYE_Y + 2, 16, 280, 340);

  // === Boca ovalada (abierta) ===
  int w = 22, h = 14, r = 5;
  tft.fillRoundRect(BX - w/2, BY - h/2, w, h, r, NEGRO);

  // === “Z” de ronquido (alineadas a la derecha SIN salirse) ===
  // Fuente 5x7: ancho ≈ 6*size, alto ≈ 8*size
  tft.setTextWrap(false);
  const int MARGEN = 6;
  // Z grande (size 4)
  int sz4 = 4, w4 = 6*sz4, h4 = 8*sz4;
  int x4 = tft.width()  - w4 - MARGEN;
  int y4 = MARGEN;                      // arriba, dentro del área visible
  // Z media (size 3)
  int sz3 = 3, w3 = 6*sz3, h3 = 8*sz3;
  int x3 = x4 - w3 - 4;                 // escalonadas hacia la izquierda
  int y3 = y4 + h4 - 6;                 // un poco más abajo
  // Z chica (size 2)
  int sz2 = 2, w2 = 6*sz2, h2 = 8*sz2;
  int x2 = x3 - w2 - 4;
  int y2 = y3 + h3 - 6;

  // Clamp por si cambia la rotación o tamaño de pantalla
  x4 = max(0, x4); y4 = max(0, y4);
  x3 = max(0, x3); y3 = max(0, y3);
  x2 = max(0, x2); y2 = max(0, y2);

  tft.setTextColor(AZUL_Z);
  tft.setTextSize(sz2); tft.setCursor(x2, y2); tft.print("Z");
  tft.setTextSize(sz3); tft.setCursor(x3, y3); tft.print("Z");
  tft.setTextSize(sz4); tft.setCursor(x4, y4); tft.print("Z");
}

#endif