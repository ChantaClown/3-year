# Leer y Visualizar

Pixel -> Menor representacion de una imagen
RGB -> Matriz de 3 dimensiones, con pixeles de valores entre ${0 - 250}$
- $P(0,0) = (255,0,0)$ Rojo
- $P(0,1) = (0,255,0)$ Verde
- $P(0,2) = (0,0,255)$ Azul
- $P(0,0) = (255,255,255)$ Blanco
- $P(0,0) = (0,0,0)$ Negro

256 = 2⁸ -> uint8 = sizenet(+ o -) int 8bit || 0..256

Escala gris: Paso de "Tridimensional" a "Bidimesional"
    3 canales ->  1 canal

Al realizar operaciones se pasade $uint8$ a $float$, pasamos de usar $(255,255,255)$ a usar $(1,1,1)$. 