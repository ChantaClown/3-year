Aquí tienes una explicación detallada de los códigos presentados:

---

### **Elias-γ Code**

El **Elias-γ Code** es un método de codificación que representa números enteros de forma eficiente utilizando un formato basado en la longitud del número en binario.

1. **Desglose del proceso**:
   - Dado un número $ k $:
     - $ k_d = \lfloor \log_2(k) \rfloor $ es el número de bits necesarios para representar $ k $ en binario menos 1.
     - $ k_r = k - 2^{\lfloor \log_2(k) \rfloor} $ es el "resto", o lo que queda después de quitar el bit más significativo.
   - $ k_d $ se codifica en **unario**: una secuencia de $ k_d $ unos, seguida por un 0.
   - $ k_r $ se codifica en **binario**, usando $ k_d $ bits.

2. **Ejemplo**:
   - Para $ k = 15 $:
     - $ k_d = 3 $ (porque $ \lfloor \log_2(15) \rfloor = 3 $).
     - $ k_r = 15 - 2^3 = 7 $.
     - Código en Elias-γ:
       - $ k_d $: $ 1110 $ (unario).
       - $ k_r $: $ 111 $ (binario).
       - Resultado: $ 1110 111 $.

---

### **Elias-δ Code**

El **Elias-δ Code** mejora al Elias-γ al codificar también la longitud de $ k_d $, haciendo el formato más eficiente para números grandes.

1. **Desglose del proceso**:
   - Dado un número $ k $:
     - $ k_d = \lfloor \log_2(k) \rfloor $.
     - Dividimos $ k_d $ en dos componentes:
       - $ k_{dd} = \lfloor \log_2(k_d + 1) \rfloor $ (el número de bits en $ k_d $).
       - $ k_{dr} = k_d - 2^{\lfloor \log_2(k_d + 1) \rfloor} $.
   - Codificación:
     - $ k_{dd} $: codificado en unario.
     - $ k_{dr} $: codificado en binario, usando $ k_{dd} $ bits.
     - $ k_r $: codificado en binario, usando $ k_d $ bits.

2. **Ejemplo**:
   - Para $ k = 255 $:
     - $ k_d = 7 $.
     - $ k_{dd} = 3 $, $ k_{dr} = 3 $.
     - Código en Elias-δ:
       - $ k_{dd} $: $ 1110 $ (unario).
       - $ k_{dr} $: $ 011 $ (binario).
       - $ k_r $: $ 1111111 $ (binario).
       - Resultado: $ 1110 011 1111111 $.

---

### **Variable Byte (V-Byte) Encoding**

Este método codifica números enteros utilizando bytes, marcando el último byte de un número con un bit más significativo (MSB) igual a 1, mientras que los bytes intermedios tienen MSB igual a 0.

1. **Desglose del proceso**:
   - Dividir $ k $ en bloques de 7 bits.
   - Los primeros 7 bits se almacenan en un byte. Si el número excede los 7 bits, se añade otro byte y se repite el proceso.
   - El último byte tiene su MSB configurado a 1 para indicar el final del número.

2. **Ejemplo**:
   - Para $ k = 20000 $:
     - Binario: $ 100111000100000 $.
     - División en bloques de 7 bits: $ 0000010 $, $ 0111000 $, $ 0100000 $.
     - Bytes:
       - $ 0000001 $: MSB $ 0 $, se convierte en $ 01 $.
       - $ 0111000 $: MSB $ 0 $, se convierte en $ 70 $.
       - $ 0100000 $: MSB $ 1 $, se convierte en $ C0 $.
     - Resultado: $ 01 70 C0 $.

---

### **Compression Example**

1. **Lista invertida**:
   - Se tienen documentos con posiciones (e.g., $ (docid, count, [positions]) $).

2. **Delta Encoding**:
   - Codifica diferencias en lugar de valores absolutos para reducir la redundancia.

3. **Compresión con V-Byte**:
   - La lista resultante tras el delta encoding es codificada utilizando el método de V-Byte.

4. **Ejemplo**:
   - Lista: $ 1,2,1,6,1,2,6,11,180,1,1,1 $.
   - V-Byte: $ 81,82,81,86,83,86,8B,01,B4,81,81,81 $.

---

¿Quieres ayuda implementando alguno de estos métodos en código?
