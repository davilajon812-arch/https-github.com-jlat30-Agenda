# Recursos para la ficha de Google Play

Todo lo necesario para publicar la ficha, con las medidas que exige Play Console.

| Archivo | Medida | Dónde se sube |
| ------- | ------ | ------------- |
| `icon-512.png` | 512×512, sin transparencia | Presencia en la tienda → Ícono de la app |
| `feature-graphic.png` | 1024×500 | Presencia en la tienda → Gráfico destacado |
| `screenshots/01-agenda-dia.png` | 1350×2700 | Capturas de teléfono (1 de 9) |
| `screenshots/02-nueva-cita.png` | 1350×2700 | Capturas de teléfono (2 de 9) |
| `screenshots/03-detalle-cita.png` | 1350×2700 | Capturas de teléfono (3 de 9) |
| `screenshots/04-clientes.png` | 1350×2700 | Capturas de teléfono (4 de 9) |
| `screenshots/05-detalle-cliente.png` | 1350×2700 | Capturas de teléfono (5 de 9) |
| `screenshots/06-servicios.png` | 1350×2700 | Capturas de teléfono (6 de 9) |
| `screenshots/07-horario-empleado.png` | 1350×2700 | Capturas de teléfono (7 de 9) |
| `screenshots/08-agenda-semana.png` | 1350×2700 | Capturas de teléfono (8 de 9) |
| `screenshots/09-ingresos.png` | 1350×2700 | Capturas de teléfono (9 de 9) |

## Requisitos de Play que se respetaron

- Capturas entre **2 y 8**, en PNG o JPEG.
- Lado menor **≥ 320 px** y mayor **≤ 3840 px**.
- Relación de aspecto **máximo 2:1**. El teléfono captura en 1224×2700 (2.20:1),
  así que cada imagen se rellenó a **1350×2700** con el color de fondo de la app
  para que el relleno no se note.

## Orden recomendado

El orden importa: la primera captura es la que más se ve en la tienda.

1. **Agenda del día** — el valor principal del producto.
2. **Nueva cita** — muestra el cálculo de huecos reales por empleado.
3. **Detalle de la cita** — estados, cobro y recordatorio por WhatsApp.
4. **Clientes** — buscador y datos de contacto.
5. **Historial del cliente** — visitas, servicios y precios.
6. **Servicios** — catálogo con duración y precio.
7. **Horario del empleado** — turnos por día.
8. **Agenda semanal** — vista de la semana completa.
9. **Ingresos** — lo cobrado en la semana con desglose por día, medio y
   servicio. Es la captura que explica el "para qué me sirve" del negocio.

## Cómo regenerarlas

Las capturas se tomaron desde el teléfono con la cuenta demo
(`docs/demo-account.md`) y luego se rellenaron al formato de Play.

```powershell
# 1. Con el teléfono conectado y sesión iniciada como demo:
adb shell screencap -p /sdcard/cap.png
adb pull /sdcard/cap.png store/screenshots/raw/01-agenda-dia.png

# 2. Rellenar a 2:1 (1350x2700) con el color de fondo
#    El relleno se calcula muestreando el borde izquierdo de cada captura.
```

Antes de capturar, comprueba que la app **no muestre el banner de DEBUG**
(`MaterialApp.router` ya tiene `debugShowCheckedModeBanner: false`).

## Pendiente

- Subir el AAB a pruebas internas.
- Crear la suscripción `agendapro_pro_mensual` (USD 5,00) **después** del primer
  AAB, y añadirse como *license tester*.

Los **textos de la ficha** (título, descripciones y novedades) ya están en
[`docs/play-listing.md`](../docs/play-listing.md).
