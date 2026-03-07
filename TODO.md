# TODO

## MVP Cafe Veloz

- [x] Crear app menubar nativa macOS 14+ con SwiftUI.
- [x] Implementar controlador de proceso para `caffeinate -di`.
- [x] Implementar UI taza flotante (sin recuadro), arrastrable, con toggle Prender/Apagar en click.
- [x] Cambiar icono de barra según estado prendido/apagado.
- [x] Forzar apagado de `caffeinate` al salir (`Quit`).
- [x] Agregar tests unitarios para flujo start/stop/toggle/fallo/salida inesperada.
- [x] Actualizar documentación de uso en `README.md`.
- [x] Agregar pipeline local de trabajo (`scripts/pipeline.sh`) con test + build + empaquetado en `dist/CafeVeloz.app`.
- [x] Agregar acción Mostrar/Ocultar para la taza flotante y mejorar su silueta visual.
- [x] Ajustar taza flotante a estilo icono (sin texto en el widget, solo estado visual on/off).

## Fuera de alcance MVP

- [x] Autoarranque al iniciar sesión.
- [ ] Configuración de flags de `caffeinate`.
- [ ] Empaquetado y firma para distribución.
