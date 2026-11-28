# Conectividad móvil

Implementación local del 26/11/2026. No representa un release de tienda.

`InternetBanner` envuelve el navegador desde `Application.builder`: muestra una franja ámbar
con icono y texto **Sin conexión a Internet**. Reserva su espacio, respeta el área segura y
anuncia el estado a lectores de pantalla. Al recuperar conexión desaparece sin reconstruir
el navegador ni borrar el formulario o su foco.

Corrección del 26/11/2026 tras captura de iPhone con isla dinámica: la franja declara su propio
`AnnotatedRegion<SystemUiOverlayStyle>`, con iconos oscuros para el fondo claro de la barra de
estado (`statusBarBrightness: light` en iOS, `statusBarIconBrightness: dark` en Android). La región
incluye el área segura superior; la leyenda queda debajo de reloj/isla/batería. Al desaparecer
la franja se retira esta región y vuelve el estilo de la pantalla. No cambia globalmente el
estilo de navegación inferior. Una región exterior de reserva recupera los iconos claros del
encabezado azul cuando la pantalla no declara estilo; las anotaciones propias de otras pantallas
conservan prioridad. La QA anterior con capturas de Flutter no incluía los iconos
nativos del sistema y no detectó la falta de contraste que mostró el usuario.

`InternetMonitor` comprueba acceso HTTPS al iniciar, cada 10 segundos en primer plano y al
regresar a la app. Cancela los sondeos en segundo plano y al desmontarse. No se muestra una
desconexión mientras el estado inicial sea desconocido. Las comprobaciones simultáneas se
comparten y un resultado anterior no sustituye una respuesta HTTP más reciente.

Usa `internet_connection_checker_plus` 3.1.2, con las comprobaciones HEAD independientes de
la API que provee el paquete (Cloudflare, icanhazip, Google y Apple). Basta una respuesta
correcta; cada comprobación tiene un límite de 3 segundos. No usa el cliente autenticado,
ni envía tokens, credenciales o datos de negocio. El monitor limita su espera a 6 segundos.
En condiciones normales la detección tarda hasta unos 13 segundos (intervalo más sondeo).
Una red que bloquee todos esos destinos puede producir un falso aviso: no se bloquean
peticiones a la API basándose en ese resultado.

## Mensajes de las peticiones

El interceptor compartido normaliza el mensaje de Dio conservando tipo, respuesta y causa
para diagnóstico. No modifica el cuerpo de respuesta ni las validaciones del negocio.

| Evidencia | Mensaje |
| --- | --- |
| Error de transporte y comprobación independiente sin acceso | Sin conexión a Internet. Revisa tu Wi-Fi o tus datos móviles. |
| HTTP 500–599 | El servicio no está disponible en este momento. Inténtalo más tarde. |
| Timeout con acceso a Internet o causa no confirmada | El servicio está tardando en responder. Inténtalo de nuevo. |
| Reset/DNS/conexión fallida sin confirmar desconexión | No pudimos conectar con el servicio. Inténtalo de nuevo. |

Una respuesta HTTP confirma conexión y retira la franja. Un timeout o reset por sí solo
no demuestra que el celular esté desconectado ni que todo el servicio haya caído.
El inicio de sesión conserva mensajes de credenciales (401) y permisos (403); el interceptor
no trata el 401 de `/auth/login` como una sesión expirada. Las peticiones autenticadas
conservan su cierre de sesión existente.

Los consumidores que antes deducían «sin Internet» de `response == null` usan ahora el
mensaje clasificado. Las notificaciones eliminan texto técnico en inglés y evitan apilar
un toast de desconexión sobre la franja. No se reenvían operaciones automáticamente al
recuperar conexión, para evitar duplicar escrituras o emisiones.

## Comprobación

Pruebas focalizadas: `flutter test test/shared/internet_monitor_test.dart
test/widgets/internet_banner_test.dart test/utils/network_error_test.dart
test/utils/api_network_interceptor_test.dart test/utils/notifications_test.dart`.

Cubren desconexión/recuperación, estado desconocido, concurrencia, sondeos detenidos,
formulario/foco conservados, texto al 200% en 320 px, 5xx frente a transporte/timeout,
401 del login y ausencia de reintento de una escritura fallida.

La evidencia de esta tarea está en `../output/conectividad-movil-2026-11-26/` respecto al
repositorio. La QA con conectividad y respuestas simuladas comprueba interfaz y clasificación;
no acredita una interrupción real del operador ni una caída de producción.
