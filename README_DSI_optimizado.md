# DSI optimizado en Dart

## Descripción general

Esta implementación resuelve el problema de coloreo de grafos usando una variante optimizada de **DSI** (*DSATUR with interchanges*). El algoritmo combina dos ideas:

1. **DSATUR** para decidir cuál vértice colorear a continuación.
2. **Kempe interchanges** para intentar evitar la creación de un color nuevo cuando todos los colores actuales están bloqueados.

La meta es obtener coloraciones de alta calidad, es decir, usar pocos colores, sin pagar el costo de un método exacto como backtracking o branch and bound.

---

## Idea matemática

### Saturación

Para un vértice no coloreado `v`, su grado de saturación es la cantidad de colores distintos presentes en sus vecinos ya coloreados:

\[
sat(v)=\left|\{\,c(u):u\in N(v)\text{ y }u\text{ ya está coloreado}\,\}\right|
\]

donde:

- `N(v)` es el conjunto de vecinos de `v`,
- `c(u)` es el color del vecino `u`.

El algoritmo **DSATUR** selecciona en cada paso un vértice con saturación máxima. Si hay empate, se rompe por mayor grado y luego por prioridad.

### Interchange de Kempe

Cuando un vértice no puede recibir ninguno de los colores ya usados, en lugar de introducir inmediatamente un color nuevo, se intenta un **interchange** entre dos colores `a` y `b`.

La idea es considerar una componente conexa del subgrafo inducido por los vértices coloreados con `a` o `b`, y luego intercambiar los colores en esa componente:

- los vértices con color `a` pasan a `b`,
- los vértices con color `b` pasan a `a`.

Si este intercambio libera el color `a` en la vecindad del vértice actual, entonces ese color puede reutilizarse y se evita crear un color nuevo.

---

## Objetivo de la optimización

Una implementación ingenua de DSATUR o DSI puede ser costosa por varias razones:

- ordenar todos los vértices no coloreados en cada iteración,
- recalcular saturaciones desde cero,
- volver a calcular el color máximo usado,
- explorar demasiados swaps inútiles.

Esta arquitectura optimizada mejora eso mediante:

- **max-heap con invalidación perezosa (lazy invalidation)**,
- **actualización incremental de saturación**,
- **mantenimiento de `currentMaxColor`**,
- **búsqueda temprana de componentes bicolores**,
- **recomputación local solo en vértices afectados por un swap**.

---

## Estructuras de datos utilizadas

### 1. `Map<T, Set<T>> adjacency`

Representa la lista de adyacencia del grafo.

Ejemplo:

```dart
{
  'A': {'B', 'C'},
  'B': {'A', 'D'},
  'C': {'A'},
  'D': {'B'}
}
```

Cada clave es un vértice y su valor es el conjunto de sus vecinos.

### 2. `Map<T, int> colorByNode`

Guarda el color asignado a cada vértice ya coloreado.

Ejemplo:

```dart
{
  'A': 0,
  'B': 1,
  'C': 0
}
```

### 3. `Set<T> uncolored`

Contiene los vértices que todavía no han sido coloreados.

### 4. `Map<T, Set<int>> seenColorsByNode`

Para cada vértice no coloreado, almacena los colores distintos presentes en sus vecinos ya coloreados.

Esto permite mantener la saturación de forma incremental, sin recalcular todo desde cero.

### 5. `Map<T, int> saturationCountByNode`

Guarda la saturación actual de cada vértice.

En vez de recalcular:

```dart
sat(v) = número de colores distintos en vecinos coloreados
```

se mantiene actualizada cada vez que se colorea un vecino o se hace un swap.

### 6. `Map<T, int> degreeByNode`

Guarda el grado de cada vértice. Es estático y se calcula una sola vez.

### 7. `Map<T, int> priorityByNode`

Se usa para romper empates cuando dos vértices tienen igual saturación e igual grado. Si el usuario entrega un orden inicial, este mapa conserva esa prioridad.

### 8. `Map<T, int> versionByNode`

Se usa para el esquema de **lazy invalidation** del heap.

Cada vez que cambia la saturación de un vértice, se incrementa su versión y se vuelve a insertar una entrada actualizada en el heap. Si más adelante sale una entrada vieja, se descarta.

### 9. `HeapPriorityQueue<_NodeEntry<T>> heap`

Es la cola de prioridad principal. Siempre se extrae el mejor candidato según:

1. mayor saturación,
2. mayor grado,
3. menor prioridad,
4. orden lexicográfico final.

---

## Cómo funciona el algoritmo

## Paso 1. Normalización del grafo

Antes de comenzar, la lista de adyacencia se normaliza para asegurar que:

- el grafo sea tratado como no dirigido,
- si `u` es vecino de `v`, entonces `v` también sea vecino de `u`,
- no existan lazos (`u -> u`).

---

## Paso 2. Inicialización

Se crean:

- el mapa de grados,
- la prioridad por nodo,
- el conjunto de no coloreados,
- la saturación inicial en cero,
- el heap con una entrada inicial por vértice.

Al inicio ningún vértice tiene vecinos coloreados, así que todas las saturaciones son cero.

---

## Paso 3. Selección del siguiente vértice

En cada iteración se extrae del heap el mejor vértice disponible.

El heap usa invalidación perezosa:

- si la entrada extraída corresponde a una versión vieja, se ignora,
- si el vértice ya fue coloreado, también se ignora,
- solo se acepta la entrada que coincide con el estado actual.

Esto evita tener que reordenar todos los vértices en cada paso.

---

## Paso 4. Búsqueda del menor color disponible

Se calculan los colores usados por los vecinos ya coloreados del vértice actual.

Luego se revisan los colores desde `0` hasta `currentMaxColor`:

- si alguno no está usado por los vecinos, se asigna,
- si todos están bloqueados, se intenta un interchange.

---

## Paso 5. Interchange de Kempe

Cuando no hay color libre, el algoritmo intenta liberar uno.

### Idea

Sea `v` el vértice actual.

Si todos los colores `0,1,...,k` aparecen en su vecindad, entonces normalmente habría que crear el color `k+1`.

Antes de eso, el algoritmo intenta:

- elegir un color bloqueado `a`,
- elegir otro color `b`,
- explorar componentes del subgrafo inducido por colores `a` y `b`,
- intercambiar `a <-> b` en componentes donde el swap sea seguro.

### Cuándo es seguro

Para liberar el color `a` en la vecindad de `v`, cada vecino de color `a` debe pertenecer a una componente `(a,b)` que **no contenga** un vecino de color `b` adyacente a `v`.

Si eso se cumple, al intercambiar los colores en esas componentes:

- los vecinos de `v` que tenían `a` pasan a `b`,
- no aparece ningún nuevo vecino de `v` con color `a`,
- el color `a` queda libre para `v`.

### Optimización importante

La búsqueda en la componente bicolor se hace con **parada temprana**:

- si durante el DFS/BFS aparece un vecino prohibido de color `b`,
- se aborta inmediatamente ese intento de swap.

Eso evita recorrer componentes completas cuando ya se sabe que no sirven.

---

## Paso 6. Aplicar el color

Si el interchange funcionó, el vértice usa un color ya existente.

Si no funcionó, se crea un color nuevo:

```dart
selectedColor = currentMaxColor + 1;
```

y luego se actualiza:

```dart
currentMaxColor = selectedColor;
```

---

## Paso 7. Actualizar saturaciones

Cuando un vértice se colorea, solo sus vecinos no coloreados pueden cambiar de saturación.

Para cada vecino no coloreado:

- si el nuevo color no estaba en su conjunto de colores vistos,
- se agrega,
- se actualiza la saturación,
- se incrementa la versión,
- se inserta una nueva entrada en el heap.

---

## Paso 8. Recomputación local tras un swap

Cuando se realiza un interchange, cambian colores en una componente del grafo.

Eso puede afectar la saturación de algunos vértices no coloreados vecinos de esa componente.

En vez de recalcular la saturación de todo el grafo, la implementación solo hace esto:

1. recoge los vértices no coloreados adyacentes a nodos intercambiados,
2. recomputa sus colores vistos desde cero,
3. actualiza saturación, versión y heap.

Esta decisión hace el algoritmo mucho más eficiente en la práctica.

---

## Clases auxiliares

### `_NodeEntry<T>`

Representa una entrada en el heap.

Contiene:

- `node`: el vértice,
- `saturation`: saturación snapshot,
- `degree`: grado,
- `priority`: prioridad de desempate,
- `version`: versión snapshot.

### `_TwoColorSearchResult<T>`

Representa el resultado de explorar una componente bicolor.

Contiene:

- `component`: conjunto de nodos encontrados,
- `hitForbidden`: indica si apareció un vecino prohibido, lo que invalida el swap.

---

## Correctitud básica

La implementación mantiene una coloración propia porque:

1. un vértice solo recibe un color que no aparece en sus vecinos, o
2. un interchange solo se realiza sobre una componente bicolor, lo que preserva la propiedad de coloreo propio.

Por tanto, dos vértices adyacentes nunca terminan con el mismo color.

---

## Complejidad

Sea:

- `n` = número de vértices,
- `m` = número de aristas,
- `k` = número de colores usados en una etapa del proceso.

### 1. Normalización

Normalizar la lista de adyacencia cuesta:

\[
O(n + m)
\]

### 2. Selección del siguiente vértice

Cada inserción o extracción en el heap cuesta:

\[
O(\log n)
\]

En la parte base estilo DSATUR, el número total de actualizaciones del heap es cercano a `O(n + m)` en la práctica, ya que cada coloreo solo afecta a vecinos inmediatos.

Por ello, el costo base de selección queda aproximadamente en:

\[
O((n + m)\log n)
\]

### 3. Búsqueda del menor color disponible

Buscar el menor color libre cuesta:

\[
O(k)
\]

por iteración. En el peor caso, como `k <= n`, esto puede sumar:

\[
O(n^2)
\]

aunque en grafos reales suele ser bastante menor.

### 4. Interchange

En el peor caso, un intento de interchange puede:

- probar varios pares de colores,
- explorar componentes bicolores,
- refrescar saturaciones locales.

Una cota conservadora por intento es:

\[
O(k^2 (n + m))
\]

y si eso ocurre muchas veces, el peor caso global sigue siendo alto, como en otras variantes de DSI.

### Conclusión de complejidad

La parte **DSATUR base** de esta implementación mejora claramente frente a una versión que ordena todos los vértices en cada iteración:

- implementación ingenua típica:
  \[
  O(n^2 \log n + m)
  \]

- implementación optimizada con heap:
  \[
  O((n+m)\log n + n^2)
  \]

La parte de **DSI** añade el costo de los interchanges, cuyo peor caso sigue siendo elevado, pero en la práctica se reduce bastante gracias a:

- selección incremental,
- poda temprana,
- recomputación local tras swap.

---

## Ventajas de esta arquitectura

- Evita ordenar todos los vértices en cada iteración.
- No recalcula saturaciones globalmente.
- No recalcula el color máximo usado.
- Reduce el trabajo del interchange con parada temprana.
- Solo refresca vértices realmente afectados por un swap.
- Permite romper empates con prioridad personalizada.

---

## Limitaciones

- El peor caso teórico del interchange sigue siendo costoso.
- La implementación está optimizada para buen rendimiento práctico, no para minimalismo de código.
- Si se quisiera exprimir todavía más, podría sustituirse `Set<int>` por bitsets o estructuras compactas de colores.

---

## Ejemplo de uso

```dart
final adjacency = <String, Set<String>>{
  'A': {'B', 'C', 'D', 'G'},
  'B': {'A', 'C', 'E', 'H'},
  'C': {'A', 'B', 'F', 'I'},
  'D': {'A', 'E', 'F', 'G'},
  'E': {'B', 'D', 'F', 'H'},
  'F': {'C', 'D', 'E', 'I'},
  'G': {'A', 'D', 'H', 'I'},
  'H': {'B', 'E', 'G', 'I'},
  'I': {'C', 'F', 'G', 'H'},
};

final visitOrder = ['B', 'A', 'H', 'F', 'I', 'E', 'D', 'C', 'G'];

final algorithm = OptimizedDsiColoring<String>();
final coloring = algorithm.call(adjacency, visitOrder: visitOrder);

print(coloring);
```

---

## Resumen final

Esta implementación combina:

- el criterio inteligente de selección de **DSATUR**,
- la capacidad de mejora local de **DSI** mediante interchanges,
- y una arquitectura optimizada para evitar trabajo innecesario.

En resumen, es una versión seria y eficiente para experimentar con coloreo heurístico de grafos en Dart sin caer en la versión lenta que ordena medio universo en cada vuelta.
