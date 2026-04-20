## Problema

Una coordinación académica debe asignar bloques de tiempo (2 horas por bloque) a un conjunto de clases, evitando traslapes que violen las siguientes restricciones operativas:

- Un grupo no puede cursar dos clases en el mismo bloque de tiempo.
- Un docente no puede impartir dos clases en el mismo bloque de tiempo.

## Objetivo general

Optimizar la asignación de bloques de tiempo para clases académicas mediante el modelado del problema como un grafo de conflictos y la aplicación de algoritmos de coloreo.

## Tareas para realizar

- Modelar el conjunto de clases como un grafo de conflictos a partir de restricciones por grupo y por docente (como ejemplo considere los datos de la Tabla 1).
- Construir la representación gráfica del grafo para su procesamiento.
- Aplicar un algoritmo Greedy (paso a paso), dibujando el grafo de conflictos generado considerando el conjunto de datos de la Tabla 1 con el orden: B, A, H, F, I, E, D, C, G.
- Aplicar cualquier otro algoritmo de coloreo de grafos para compararlo con el algoritmo Greedy, considere los mismos datos de la Tabla 1 y coloree el grafo resultante.
- Argumentar un resultado teórico que le permita determinar: ¿cuándo se obtiene un número mínimo de bloques de tiempo?, o ¿cómo saber que ya no se puede reducir el número de bloques de tiempo.?
- Realizar el análisis de la complejidad de los algoritmos de coloreo utilizados.
- Proponer una implementación computacional para al menos uno de los algoritmos propuestos para el caso general de resolver conflictos mediante el coloreo grafos.

***Tabla 1***.  Regla de conflicto: dos clases están en conflicto si comparten el mismo Grupo o Docente.

| Id Clase | Materia    | Grupo | Docente |
| --- | --- | --- | --- |
| A | Mate I     | G1 | T1 |
| B | Mate II    | G1 | T2 |
| C | Mate III   | G1 | T3 |
| D | Física I   | G2 | T1 |
| E | Física II  | G2 | T2 |
| F | Física III | G2 | T3 |
| G | Prog I     | G3 | T1 |
| H | Prog II    | G3 | T2 |
| I | Prog III   | G3 | T3 |

### Preguntas guía

- ¿Cómo se construye el grafo de conflictos a partir de datos de clases?
- ¿Cuál es el número mínimo de bloques requerido para un conjunto de clases dado?
- ¿Qué algoritmo de coloreo produce soluciones de mejor calidad (menos bloques) bajo el mismo tiempo de cómputo?
- ¿Cómo se valida que el horario resultante no contiene conflictos?
- ¿En una implementación computacional que estructura de datos es adecuada para representar los datos del grafo de conflictos?
- Cómo se quiere obtener un óptimo minimal sobre el número de bloques de tiempo, ¿cómo saber si ya obtuvo tal valor óptimo?
- ¿Cómo cambia la solución al introducir el conflicto sobre la disponibilidad de los docentes por bloque?

#### Por ejemplo

Disponibilidad por docente:

- T1: **NO disponible** en B1 y B4 → **permitidos** {B2, B3}
- T2: **NO disponible** en B2 y B3 → **permitidos** {B1, B4}
- T3: **NO disponible** en B1 y B3 → **permitidos** {B2, B4}

---

## Solución

### Tarea 1

Modelar el conjunto de clases como un grafo de conflictos a partir de restricciones por grupo y por docente (como ejemplo considere los datos de la Tabla 1).

#### Ejecución

Al analizar el problema, podemos encontrar similitudes con **coloreo de grafos**. Dado que este último es un problema **NP-Completo**, es conveniente reducir nuestro problema a este. Esto nos permite obtener información relevante sobre su complejidad:

- El hecho de que sea **NP** indica que existe una forma de **verificar rápidamente una solución candidata** en tiempo polinomial.
- Al ser **NP-Hard**, no se conoce un algoritmo eficiente que garantice una solución exacta. Por ello, resulta recomendable usar **heurísticas** como **Greedy**, **DSATUR** o **Backtracking**, considerando su costo computacional.

#### Demostración

Comenzamos demostrando que el **coloreo de grafos** es en efecto **NP-Hard**:

#### Ejemplo visual

Consideremos la fórmula **3-SAT** pequeña:

`phi = (x_1 U - x_2 U x_2) ^ (- x_1 U x_2 U x_1)`

**Paso 1: Triángulo base**

```
B (BASE)
 /   \
T     F
```

- T = VERDADERO
- F = FALSO
- B = BASE

**Paso 2: Nodos de variables**

- Variable \(x_1\): nodos \(x_1\) y \(-x_1\) conectados entre sí y a B
- Variable \(x_2\): nodos \(x_2\) y \(-x_2\) conectados entre sí y a B

```
     x1 --- -x1
      \     /
       \   /
         B
     x2 --- -x2
      \     /
       \   /
         B
```

**Paso 3: Nodos de cláusulas**

- Cláusula \(C_1 = (x_1 U -x_2 U x_2)\)
- Cláusula \(C_2 = (-x_1 U x_2 U x_1)\)

- Cada nodo de cláusula está conectado a su literal correspondiente y al nodo BASE B

```
Nodos de C1: c11, c12, c13
c11 -- x1
c12 -- -x2
c13 -- x2
c11,c12,c13 -- B (triángulo)

Nodos de C2: c21, c22, c23
c21 -- -x1
c22 -- x2
c23 -- x1
c21,c22,c23 -- B (triángulo)
```

**Interpretación:**

- Para que los triángulos de cláusulas sean 3-coloreables, **al menos un literal debe ser VERDADERO**.
- Esto asegura que la asignación de colores corresponde a una **solución satisfacible** de la fórmula 3-SAT.

```
VERDADERO = T
FALSO      = F
BASE       = B
```

- Asignando colores a los nodos de variables según una solución válida, podemos colorear todos los triángulos de cláusulas, demostrando la correspondencia con **3-SAT**.

Por lo tanto, el **coloreo de grafos** con \(k >= 3\) colores es **NP-Hard**, y como verificar un coloreo dado se hace en tiempo polinomial, también es **NP-Completo**.

#### Reducción a coloreo de grafos

Luego de esta demostración, reducimos nuestro problema de asignación de bloques de clases a **coloreo de grafos** de la siguiente manera:

- Cada clase se representa como un nodo en el grafo.
- Se dibuja una arista de conflicto entre dos nodos si las clases comparten el **mismo grupo** o el **mismo docente**; así reflejamos que no pueden ocurrir en el **mismo bloque de tiempo**.
- Colorear el grafo con **k** colores equivale a asignar a **k** bloques de tiempo de manera que no existan conflictos, cumpliendo así todas las restricciones.

Esta reducción permite aplicar algoritmos de coloreo de grafos como **Greedy**, **DSATUR** y **Backtracking** para obtener horarios válidos.

De esta forma, se ha resuelto la primera tarea planteada en nuestro Objetivo.

### Tarea 2

Construir la representación gráfica del grafo para su procesamiento.

#### Ejecución

![Grafo](assets/graph_before_coloring.png)

### Tarea 3
Aplicar un algoritmo Greedy (paso a paso), dibujando el grafo de conflictos generado considerando el conjunto de datos de la Tabla 1 con el orden: B, A, H, F, I, E, D, C, G.

#### Ejecución

Orden de visita solicitado:

`B, A, H, F, I, E, D, C, G`

Grafo de conflicto por listas de adyacencia:

```
A -> B, C, D, G
B -> A, C, E, H
C -> A, B, F, I
D -> A, E, F, G
E -> B, D, F, H
F -> C, D, E, I
G -> A, D, H, I
H -> B, E, G, I
I -> C, F, G, H
```

Pasos del algoritmo de coloreo:

| Nodo | Colores de vecinos | Color asignado |
| --- | --- | --- |
| B | [] | 0 |
| A | [0] | 1 |
| H | [0] | 1 |
| F | [] | 0 |
| I | [0, 1] | 2 |
| E | [0, 1] | 2 |
| D | [0, 1, 2] | 3 |
| C | [0, 1, 2] | 3 |
| G | [1, 2, 3] | 0 |

Coloración final:

```
{
  B: 0,
  A: 1,
  H: 1,
  F: 0,
  I: 2,
  E: 2,
  D: 3,
  C: 3,
  G: 0
}
```

![Grafo](assets/graph_after_greedy_coloring_custom_order.png)

### Tarea 4

Aplicar cualquier otro algoritmo de coloreo de grafos para compararlo con el algoritmo Greedy, considere los mismos datos de la Tabla 1 y coloree el grafo resultante.

#### Ejecución

Orden de visita solicitado:

`B, A, H, F, I, E, D, C, G`

Grafo de conflicto por listas de adyacencia:

```
A -> B, C, D, G
B -> A, C, E, H
C -> A, B, F, I
D -> A, E, F, G
E -> B, D, F, H
F -> C, D, E, I
G -> A, D, H, I
H -> B, E, G, I
I -> C, F, G, H
```

Prioridad de nodos según entrada:

| Nodo | Prioridad |
| --- | --- |
| B | 0 |
| A | 1 |
| H | 2 |
| F | 3 |
| I | 4 |
| E | 5 |
| D | 6 |
| C | 7 |
| G | 8 |

Paso a Paso del Algoritmo DSATUR

1. Paso 1:
    - Nodos sin color: A, B, C, D, E, F, G, H, I
    - Nodo seleccionado: B (mayor saturación y prioridad)
    - Colores vecinos usados: []
    - Color asignado: 0
    - Saturación actualizada para vecinos (A, C, E, H): [0]
2. Paso 2:
    - Nodos sin color: A, C, D, E, F, G, H, I
    - Nodo seleccionado: A
    - Colores vecinos usados: [0]
    - Color asignado: 1
    - Saturación actualizada para vecinos (C, D, G): [1]
3. Paso 3:
    - Nodos sin color: C, D, E, F, G, H, I
    - Nodo seleccionado: C
    - Colores vecinos usados: [0, 1]
    - Color asignado: 2
    - Saturación actualizada para vecinos (F, I): [2]
4. Paso 4:
    - Nodos sin color: D, E, F, G, H, I
    - Nodo seleccionado: H
    - Colores vecinos usados: [0]
    - Color asignado: 1
    - Saturación actualizada para vecinos (E, G, I): [1,2]
5. Paso 5:
    - Nodos sin color: D, E, F, G, I
    - Nodo seleccionado: I
    - Colores vecinos usados: [1, 2]
    - Color asignado: 0
    - Saturación actualizada para vecinos (F, G): [0,2]
6. Paso 6:
    - Nodos sin color: D, E, F, G
    - Nodo seleccionado: F
    - Colores vecinos usados: [0, 2]
    - Color asignado: 1
    - Saturación actualizada para vecinos (D, E): [1,2]
7. Paso 7:
    - Nodos sin color: D, E, G
    - Nodo seleccionado: E
    - Colores vecinos usados: [0, 1]
    - Color asignado: 2
    - Saturación actualizada para vecinos (D): [1,2]
8. Paso 8:
    - Nodos sin color: D, G
    - Nodo seleccionado: D
    - Colores vecinos usados: [1, 2]
    - Color asignado: 0
    - Saturación actualizada para vecinos (G): [0,1]
9. Paso 9:
    - Nodo sin color: G
    - Colores vecinos usados: [0, 1]
    - Color asignado: 2

Coloración final:

```
{
  B: 0,
  A: 1,
  C: 2,
  H: 1,
  I: 0,
  F: 1,
  E: 2,
  D: 0,
  G: 2
}
```

### Tarea 4

Argumentar un resultado teórico que le permita determinar: ¿cuándo se obtiene un número mínimo de bloques de tiempo?, o ¿cómo saber que ya no se puede reducir el número de bloques de tiempo.?

#### Ejecución

El mínimo número de bloques de tiempo coincide con el **número cromático** chi(G) del grafo de conflictos.

##### Resultado teórico (criterio de optimalidad)
Una asignación con k bloques es óptima si se cumplen simultáneamente:

1. **Cota inferior:** existe un clique de tamaño k, por lo que chi(G) >= k.
2. **Cota superior:** existe una coloración válida con k colores, por lo que chi(G) <= k.

Si ambas se cumplen, entonces necesariamente chi(G) = k, y por tanto **ya no se puede reducir** el número de bloques.

##### Aplicación al caso de estudio
1. Existe un clique de tamaño 3, por ejemplo {A, B, C}, porque las tres clases comparten el mismo grupo (G1). Luego chi(G) >= 3.
2. En las ejecuciones de coloreo se obtuvo una coloración válida con 3 colores (3 bloques). Luego chi(G) <= 3.
3. Por lo tanto, chi(G) = 3. El número mínimo de bloques es 3; con 2 bloques se generan conflictos.

### Tarea 5

Realizar el análisis de la complejidad de los algoritmos de coloreo utilizados.

#### Ejecución

##### Greedy

El algoritmo greedy para el coloreo de grafos funciona de la siguiente manera:
1. Se fija un orden de visita de los nodos
2. Para cada nodo, se asigna el menor color disponible que no esté usado por sus vecinos
3. Se repite hasta colorear todos los nodos

***Análisis***:

Sea `n` el número de nodos y `m` el número de aristas.

En el algoritmo Greedy:

1. Se recorre cada nodo una vez para decidir su color.
2. Para cada nodo, se revisan los colores de sus vecinos para encontrar el menor color disponible.

En total, revisar vecinos en todos los pasos equivale a sumar los grados de todos los nodos.
Esa suma es `2m`, porque cada arista contribuye al grado de dos nodos.

Por ello, el costo por revisión de vecinos es `O(m)`, y el recorrido de nodos agrega `O(n)`.

La complejidad total es:

`O(n + m)`

##### DSATUR

El algoritmo **DSATUR** (Degree of Saturation) funciona de la siguiente manera:

1. Inicialmente, todos los nodos están sin colorear.
2. En cada paso, se selecciona el nodo con **mayor saturación** (es decir, el que tiene más colores diferentes ya asignados entre sus vecinos).  
   - Si hay empate, se selecciona el nodo con **mayor grado** o según prioridad definida.
3. Se asigna al nodo el **menor color disponible** que no esté usado por sus vecinos.
4. Se repite hasta que todos los nodos estén coloreados.

#### Análisis de complejidad

Sea `n` el número de nodos y `m` el número de aristas.

En cada iteración de DSATUR se realizan dos operaciones principales:

1. Seleccionar el nodo con mayor saturación.
   En la implementación actual, esta selección revisa y ordena candidatos, lo que en el peor caso es del orden de `O(n log n)` por iteración.
2. Revisar los colores de los vecinos del nodo seleccionado para elegir el menor color disponible.
   Esta parte cuesta `O(grado del nodo)`.

Como el proceso se repite para todos los nodos:

- El costo acumulado de selección es `O(n^2 log n)`.
- El costo acumulado de revisar vecinos es `O(m)`.

Por lo tanto, la complejidad total de esta implementación es:

`O(n^2 log n + m)`