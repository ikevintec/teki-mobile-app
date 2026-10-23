# Navegación móvil agrupada

Inicio muestra accesos rápidos y secciones abiertas, sin el modal «Más opciones».

- Accesos rápidos: Nueva venta, Comprobantes, Cuentas por cobrar, Envases pendientes, Fidelización y Cotizaciones, solo si están autorizados.
- Ventas: venta, comprobantes y cotizaciones. Crear cotización está dentro de Cotizaciones; un creador sin permiso de consulta conserva un acceso específico para crearla.
- Clientes y fidelización: clientes, tarjetas y envases pendientes.
- Inventario y abastecimiento: productos, inventario, traslados rápidos y compras.
- Cobros y pagos: cuentas por cobrar, por pagar y Yape.
- Restaurante: mesas, pedidos, cocina y cobrador, solo con rubro y permisos correspondientes.
- Administración: estadísticas y ajustes.

La barra inferior conserva el orden Inicio, Clientes, Inventario, Caja. Cada destino se muestra solo con su permiso de lectura; Inicio siempre está disponible. Los índices internos son estables: quitar un destino no cambia a qué pantalla lleva otro. Revocar el destino activo vuelve a Inicio y desmonta su pantalla.

Las reglas compartidas viven en `dashboard_navigation.dart`. Los grupos vacíos desaparecen y la grilla de accesos se compacta. No se crean permisos ni se conceden desde la app. La autorización del servidor sigue siendo necesaria para cada operación.

Fidelización requiere su flag y permiso propios, sin depender de envases. Envases requiere `permitirRetornoEnvase`, `inventario` y lectura de inventario. Yape usa su flag de empresa; Replicador se encuentra en la barra de Yape y conserva sus requisitos de Android y permiso específico.

Clientes se integra como pestaña reutilizando el listado existente. Crear y editar se muestran con sus permisos respectivos. El listado respeta el final de página y descarta respuestas anteriores después de limpiar/recargar el estado. Al volver desde una subpantalla se actualiza el tab activo.

El resumen de Inicio es compacto y se desplaza junto al menú. Solo consulta ventas con `VENTAS_VER`, caja con `CAJA_VER` y ofrece estadísticas con `REPORTE_VENTAS`. Conserva monedas y el aviso de una caja anterior abierta; no convierte un error de consulta en un saldo cero.

## Verificación

```sh
flutter test test/navigation/dashboard_navigation_test.dart test/widgets/dashboard_navigation_test.dart test/providers/customer_pagination_test.dart
flutter run -t test/previews/dashboard_preview.dart -d <simulador>
LOYALTY_QA_OUTPUT=/tmp/teki-menu-qa flutter drive --no-dds --driver=test_driver/loyalty_p1_driver.dart --target=integration_test/dashboard_menu_test.dart -d <simulador>
```

La vista de prueba sustituye todas las solicitudes por un adaptador sin acceso externo, usa datos sintéticos rotulados y rechaza release. El recorrido nativo verifica accesos completos, consulta de clientes, modo lectura, revocación y creación de ventas sin permiso de listados. No realiza ventas, cobros ni modificaciones de producción.
