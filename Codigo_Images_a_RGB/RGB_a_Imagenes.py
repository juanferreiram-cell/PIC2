# Instalar e importar
try:
    from PIL import Image
except:
    !pip install Pillow
    from PIL import Image

import io
import os
import zipfile
from google.colab import files
from IPython.display import display

print("✅ Librerías cargadas\n")


# FUNCIÓN DE CONVERSIÓN

def rgb888_to_rgb565(r, g, b):
    """Convierte RGB888 a RGB565"""
    return ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | (b >> 3)


def convertir_imagen(img, ancho, alto, nombre, mostrar=True):
    """Convierte imagen PIL a archivo .h"""

    if mostrar:
        print(f"\n{'='*60}")
        print(f"🔄 Convirtiendo: {nombre} a {ancho}x{alto}")
        print(f"{'='*60}\n")

    # Redimensionar
    img = img.resize((ancho, alto), Image.Resampling.LANCZOS)
    img = img.convert('RGB')

    if mostrar:
        display(img)

    # Convertir a RGB565
    rgb565 = []
    for y in range(alto):
        for x in range(ancho):
            r, g, b = img.getpixel((x, y))
            rgb565.append(rgb888_to_rgb565(r, g, b))

    # Generar .h
    var = nombre.lower().replace('-', '_').replace(' ', '_').replace('.', '_')
    total = len(rgb565)
    kb = (total * 2) / 1024

    lineas = [
        f"// {nombre} - {ancho}x{alto} - RGB565 - {kb:.1f} KB",
        f"#ifndef {var.upper()}_H",
        f"#define {var.upper()}_H",
        "#include <Arduino.h>",
        f"const uint16_t {var}[{total}] PROGMEM = {{"
    ]

    for i in range(0, total, 12):
        chunk = rgb565[i:min(i+12, total)]
        line = "  " + ", ".join([f"0x{v:04X}" for v in chunk])
        lineas.append(line + ("," if i + 12 < total else ""))

    lineas.extend(["};", f"#endif"])

    if mostrar:
        print(f"✅ {nombre}: {total:,} píxeles, {kb:.1f} KB")

    return '\n'.join(lineas), var, ancho, alto



# EJECUCIÓN PRINCIPAL


print("="*60)
print("  CONVERSOR RGB565 - MÚLTIPLES IMÁGENES")
print("="*60)

# 1. MODO DE ENTRADA
print("\n📁 ¿Qué quieres subir?")
print("  1. Una imagen")
print("  2. Múltiples imágenes (selección múltiple)")
print("  3. Carpeta comprimida (.zip)")

modo = input("\nElige (1-3): ").strip()

# 2. RESOLUCIÓN (preguntar antes de subir)
print("\n" + "="*60)
print("📐 RESOLUCIONES DISPONIBLES")
print("="*60)
print("  1. 240x320 (TFT 2.4\" vertical)")
print("  2. 320x240 (TFT 2.4\" horizontal)")
print("  3. 128x160 (TFT 1.8\")")
print("  4. 60x80   (pequeña, para probar)")
print("  5. Personalizada")

opcion = input("\nElige (1-5): ").strip()

resoluciones = {
    '1': (240, 320),
    '2': (320, 240),
    '3': (128, 160),
    '4': (60, 80)
}

if opcion in resoluciones:
    ancho, alto = resoluciones[opcion]
elif opcion == '5':
    ancho = int(input("  Ancho: "))
    alto = int(input("  Alto: "))
else:
    print("⚠️ Usando 60x80 por defecto")
    ancho, alto = 60, 80

# 3. SUBIR ARCHIVOS
print(f"\n📁 Sube tu{'s archivos' if modo != '1' else ' imagen'}:")
uploaded = files.upload()

if not uploaded:
    print("❌ No se subió nada")
else:
    imagenes = {}
    extensiones_validas = ('.png', '.jpg', '.jpeg', '.bmp', '.gif', '.webp')

    # Procesar según el modo
    if modo == '3':
        # ZIP: extraer imágenes
        zip_name = list(uploaded.keys())[0]
        with zipfile.ZipFile(io.BytesIO(uploaded[zip_name]), 'r') as z:
            for name in z.namelist():
                if name.lower().endswith(extensiones_validas) and not name.startswith('__'):
                    try:
                        img_data = z.read(name)
                        img = Image.open(io.BytesIO(img_data))
                        # Usar solo el nombre del archivo, sin la ruta
                        nombre_limpio = os.path.basename(name)
                        imagenes[nombre_limpio] = img
                    except:
                        print(f"⚠️ No se pudo leer: {name}")
    else:
        # Imágenes directas
        for filename, data in uploaded.items():
            if filename.lower().endswith(extensiones_validas):
                try:
                    img = Image.open(io.BytesIO(data))
                    imagenes[filename] = img
                except:
                    print(f"⚠️ No se pudo leer: {filename}")

    if not imagenes:
        print("❌ No se encontraron imágenes válidas")
    else:
        print(f"\n✅ {len(imagenes)} imagen(es) encontrada(s):")
        for name in imagenes:
            print(f"   • {name}")

        # 4. CONVERTIR TODAS
        archivos_generados = []
        variables = []

        # Crear directorio temporal
        os.makedirs("output", exist_ok=True)

        for filename, img in imagenes.items():
            nombre_base = os.path.splitext(filename)[0]
            contenido, var, w, h = convertir_imagen(img, ancho, alto, nombre_base, mostrar=True)

            archivo_h = f"output/{nombre_base}.h"
            with open(archivo_h, 'w') as f:
                f.write(contenido)

            archivos_generados.append(archivo_h)
            variables.append((var, nombre_base))

        # 5. GENERAR CÓDIGO DE EJEMPLO CON TODAS LAS IMÁGENES
        includes = '\n'.join([f'#include "{os.path.basename(f)}"' for f in archivos_generados])

        codigo = f'''#include <SPI.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ILI9341.h>

// Incluir todas las imágenes
{includes}

#define TFT_CS   5
#define TFT_DC   21
#define TFT_RST  4

Adafruit_ILI9341 tft(TFT_CS, TFT_DC, TFT_RST);

// Array de punteros a las imágenes
const uint16_t* imagenes[] = {{
  {', '.join([v[0] for v in variables])}
}};
const int NUM_IMAGENES = {len(variables)};

void setup() {{
  tft.begin();
  tft.setRotation(1);
  tft.fillScreen(ILI9341_BLACK);

  // Mostrar primera imagen
  tft.drawRGBBitmap(0, 0, imagenes[0], {ancho}, {alto});
}}

int indice = 0;

void loop() {{
  delay(2000);
  indice = (indice + 1) % NUM_IMAGENES;
  tft.drawRGBBitmap(0, 0, imagenes[indice], {ancho}, {alto});
}}
'''

        archivo_ino = "output/slideshow_ejemplo.ino"
        with open(archivo_ino, 'w') as f:
            f.write(codigo)
        archivos_generados.append(archivo_ino)

        # 6. CREAR ZIP CON TODO
        zip_salida = "imagenes_rgb565.zip"
        with zipfile.ZipFile(zip_salida, 'w') as z:
            for archivo in archivos_generados:
                z.write(archivo, os.path.basename(archivo))

        # 7. DESCARGAR
        print(f"\n{'='*60}")
        print("✅ ¡CONVERSIÓN COMPLETA!")
        print(f"{'='*60}")
        print(f"\n📦 Archivos generados: {len(archivos_generados)}")
        for f in archivos_generados:
            print(f"   • {os.path.basename(f)}")

        print(f"\n⬇️ Descargando ZIP con todos los archivos...")
        files.download(zip_salida)

        print(f"\n📝 El ZIP incluye un ejemplo de slideshow que rota entre todas las imágenes")
        print(f"\n💡 Instrucciones:")
        print(f"   • Arduino IDE: extrae todo en la misma carpeta que tu .ino")
        print(f"   • PlatformIO: .h en include/, .ino renómbralo a main.cpp en src/")