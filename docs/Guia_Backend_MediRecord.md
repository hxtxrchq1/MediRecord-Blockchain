# Guia de Backend para MediRecord

> Para una version mas completa de arquitectura, estructura de carpetas, modelo de datos y flujo end-to-end, revisa tambien [Guia_Backend_MediRecord_Arquitectura_y_Flujo.md](Guia_Backend_MediRecord_Arquitectura_y_Flujo.md).

## 1. Objetivo

Esta guia define como debe construirse el backend de MediRecord para que tu companero tenga claro que debe almacenar, validar y exponer.

La regla central es esta: el backend guarda el PDF real y vuelve a validar el acceso antes de entregar cualquier documento.

## 2. Responsabilidad del backend

El backend debe encargarse de:

- recibir y guardar PDFs,
- generar o registrar el identificador tecnico del documento,
- guardar el hash del archivo,
- asociar metadatos del documento,
- consultar el Registry,
- volver a validar permisos antes de entregar un archivo,
- exponer APIs para el frontend,
- y registrar o servir informacion de auditoria si el proyecto lo requiere.

El backend no debe:

- guardar permisos como unica fuente de verdad,
- ni confiar solo en lo que diga el navegador.

## 3. Tecnologias recomendadas

- Node.js
- Express o Fastify
- ethers.js
- multer o una libreria equivalente para subida de archivos
- provider RPC de Sepolia
- almacenamiento local o en nube, segun el alcance del proyecto

## 4. Datos que maneja el backend

### Documentos

- documentId,
- documentHash,
- filePath o URL interna,
- nombre del archivo,
- tamano,
- categoria,
- descripcion,
- fecha de carga,
- owner tecnico.

### Seguridad

- direccion de la wallet solicitante,
- rol tecnico,
- id del documento,
- permiso activo,
- expiracion,
- estado de revocacion.

## 5. Relacion con la blockchain

El backend usa blockchain para verificar, no para guardar PDFs.

Debe consultar:

- `MediRecordRegistry`
- `MedicalAccessNFT`

Con eso puede saber:

- si la wallet esta registrada,
- si el documento existe,
- si el permiso sigue vigente,
- si la credencial sigue activa,
- y si el acceso puede concederse.

## 6. Flujo principal del backend

1. El paciente sube un PDF desde el frontend.
2. El backend valida el archivo.
3. El backend guarda el archivo.
4. El backend genera o recibe `documentId` y `documentHash`.
5. El frontend registra el documento tecnico en el Registry.
6. Si se solicita acceso, el backend consulta al Registry.
7. El backend verifica wallet, documento, permiso, expiracion y revocacion.
8. Si todo es valido, entrega el archivo.
9. Si algo falla, niega el acceso y deja trazabilidad.

## 7. Endpoints sugeridos

No es obligatorio usar exactamente estos nombres, pero esta estructura ayuda a ordenar el backend.

### Subida y gestion de documentos

- `POST /documents/upload`
- `GET /documents`
- `GET /documents/:id`
- `DELETE /documents/:id`

### Permisos y acceso

- `POST /access/validate`
- `GET /access/:documentId/:wallet`
- `POST /access/log`

### Usuarios tecnicos

- `GET /users/:wallet`
- `GET /roles/:wallet`

### Auditoria

- `GET /audit/documents/:id`
- `GET /audit/access/:documentId`

## 8. Validaciones que debe hacer el backend

El backend no debe entregar un PDF solo porque el frontend lo pidio.

Debe validar como minimo:

- que exista el archivo,
- que el documento exista tecnicamente,
- que la wallet solicitante este registrada,
- que el permiso exista,
- que el permiso no este revocado,
- que no haya expirado,
- que la credencial NFT siga activa,
- y que el Registry confirme el acceso.

## 9. Piezas internas recomendadas

### 9.1 Capa de rutas

Recibe peticiones HTTP y las dirige al controlador correcto.

### 9.2 Capa de controladores

Recibe la solicitud, valida lo basico y coordina el flujo.

### 9.3 Capa de servicios

Contiene la logica de negocio.

### 9.4 Capa de contratos

Contiene el ABI y las direcciones del Registry y del NFT.

### 9.5 Capa de almacenamiento

Guarda PDFs, metadatos y referencias del archivo.

## 10. Integracion con ethers.js

El backend debe crear un provider para Sepolia y luego una instancia del contrato.

Debe usar los archivos de la raiz del proyecto:

- `MedicalAccessNFTABI.json`
- `MediRecordRegistryABI.json`
- `contract-addresses.js`

Eso evita duplicar direcciones en codigo.

### 10.1 Secuencia real de despliegue

El flujo de despliegue se rompe a proposito para evitar una dependencia circular entre ambos contratos.

Primero se despliega `MedicalAccessNFT` sin pasarle una direccion de Registry en el constructor. Luego se despliega `MediRecordRegistry` apuntando a la direccion ya publicada del NFT. Por ultimo, se llama a `updateRegistry(address newRegistry)` en `MedicalAccessNFT` para enlazarlo con el Registry correcto.

Ese bootstrap es el que deja estables las direcciones finales que consumen el backend y el frontend desde `contract-addresses.js`.

## 11. Responsabilidad de seguridad

El backend es la ultima barrera antes de entregar el documento.

Aunque el frontend ya haya mostrado que el usuario puede entrar, el backend debe repetir la validacion.

Esto protege contra:

- peticiones manipuladas,
- navegadores alterados,
- y acceso directo no autorizado.

## 12. Roles y reglas de backend

### Admin

Puede registrar usuarios y administrar roles si el flujo del proyecto lo contempla.

### Paciente

Puede subir documentos y compartirlos.

### Medico

Solo puede consultar documentos compartidos con su wallet.

### Clinica

Puede acceder a documentos autorizados segun permisos vigentes.

### Aseguradora

Puede consultar documentos solo si existe autorizacion.

## 12.1 Roles y control de acceso detallado

El backend debe aplicar estas reglas al validar cada operacion:

### Administrador

- Es la cuenta que despliega el contrato.
- Puede registrar direcciones y asignar roles.
- Puede consultar los participantes registrados.
- No puede otorgar ni revocar permisos medicos por los pacientes.

### Paciente

- Es el titular de los permisos medicos.
- Puede emitir permisos a medico, clinica o aseguradora previamente registrados.
- Puede consultar permisos emitidos.
- Puede revocar solo los permisos que el mismo creo.

### Medico

- Puede consultar permisos que hayan sido emitidos a su favor.
- Puede verificar si estan activos, expirados o revocados.
- No puede emitir, modificar ni transferir permisos.

### Clinica

- Puede consultar permisos institucionales otorgados por pacientes.
- No puede modificar ni transferir permisos.

### Aseguradora

- Puede consultar permisos para cobertura, auditoria o autorizaciones administrativas.
- No puede modificar, revocar ni transferir permisos.

## 12.2 Distribucion de cuentas para pruebas

El backend debe asumir que en pruebas se usaran seis cuentas de MetaMask:

- Cuenta 1: administrador y desplegador del contrato.
- Cuenta 2: paciente 1.
- Cuenta 3: paciente 2.
- Cuenta 4: medico.
- Cuenta 5: clinica.
- Cuenta 6: aseguradora.

No se deben compartir credenciales entre integrantes.

## 13. Vistas o pantallas que el backend soporta indirectamente

Aunque el backend no dibuja pantallas, debe alimentar estas vistas del frontend:

- login o conexion,
- dashboard por rol,
- mis documentos,
- compartir documento,
- detalle del documento,
- detalle del permiso,
- historial de accesos,
- perfil,
- configuracion,
- pantallas de error.

## 13.1 Requisitos funcionales que el backend debe soportar

### RF01. Conexion con MetaMask

Aunque la conexion se inicia en el frontend, el backend debe aceptar solicitudes solo cuando la wallet y la sesion correspondan a una cuenta valida.

### RF02. Validacion de la red

El backend debe asumir que todas las interacciones on-chain se hacen contra Ethereum Sepolia.

### RF03. Actualizacion de cuenta

Si la cuenta conectada cambia, el backend debe evaluar la nueva identidad y aplicar el rol correcto.

### RF04. Consulta del rol

El backend debe consultar el rol de la direccion activa cuando necesite decidir una operacion o devolver informacion.

### RF05. Registro de participantes

El backend debe permitir que el administrador registre participantes solo si la operacion proviene de la cuenta autorizada.

### RF06. Consulta de participantes

El backend debe poder devolver el listado de participantes registrados para el frontend.

### RF07. Otorgamiento de permisos

El backend debe aceptar solicitudes de pacientes para crear permisos solo si la direccion destino pertenece a medico, clinica o aseguradora registrada.

### RF08. Emision del token

Cuando se emite un permiso, el backend debe guardar la referencia tecnica del token si la respuesta del contrato la devuelve.

### RF09. Consulta de permisos emitidos

El backend debe poder listar los permisos emitidos por un paciente.

### RF10. Consulta de permisos recibidos

El backend debe poder listar los permisos recibidos por medico, clinica o aseguradora.

### RF11. Validacion del permiso

El backend debe consultar si un permiso existe, no fue revocado y no ha expirado antes de entregar informacion.

### RF12. Registro de consulta

El backend debe registrar la consulta de uso del permiso y conservar el hash de la transaccion y el resultado.

### RF13. Revocacion de permisos

El backend debe aceptar la revocacion solo desde la misma cuenta que emitio el permiso.

### RF14. Visualizacion de transacciones

El backend debe guardar o devolver el hash de cada operacion y permitir el enlace a Sepolia Etherscan.

### RF15. Gestion de estados

El backend debe exponer el estado del permiso como Activo, Expirado o Revocado.

### RF16. Manejo de errores

El backend debe responder correctamente ante:

- MetaMask no instalada en el cliente.
- wallet no conectada.
- red que no sea Sepolia.
- transaccion rechazada.
- cuenta sin rol registrado.
- direccion autorizada invalida.
- cuenta sin permisos.
- saldo insuficiente para gas.
- permiso expirado o revocado.

## 14. Respuesta esperada por tipo de rol

El backend debe responder con datos suficientes para que el frontend sepa que mostrar.

Por ejemplo:

- si el usuario es paciente, el frontend muestra subida y comparticion,
- si es medico, muestra documentos autorizados,
- si es admin, muestra gestion tecnica,
- si es clinica o aseguradora, muestra solo consulta y auditoria permitida.

## 14.1 Reglas de negocio que el backend debe hacer cumplir

El backend debe rechazar cualquier operacion que contradiga estas reglas:

- Una cuenta solo puede tener un rol.
- El administrador inicial es el desplegador del contrato.
- Solo el administrador puede registrar participantes y asignar roles.
- Solo pacientes pueden emitir permisos medicos.
- Solo se puede autorizar a medico, clinica o aseguradora.
- No se permite autoautorizacion.
- La expiracion debe ser futura.
- Cada permiso debe tener un identificador unico.
- El token de permiso no debe transferirse.
- El permiso emitido es inmutable.
- Solo el paciente emisor puede revocar.
- La revocacion es irreversible.
- La expiracion debe evaluarse automaticamente contra el tiempo de blockchain.
- La revocacion no debe borrar la trazabilidad historica.
- Las consultas de lectura no deben consumir gas.
- Las operaciones de escritura si consumen Sepolia ETH.
- El frontend nunca reemplaza la validacion del contrato.

## 14.2 Validacion que debe realizar el backend al registrar una consulta

Cuando una entidad autorizada intente usar un permiso, el backend debe registrar:

- el identificador del permiso,
- la direccion consultante,
- la fecha o timestamp,
- y el resultado de la validacion.

Eso permite conservar evidencia tanto de accesos permitidos como de intentos fallidos sobre permisos expirados o revocados.

## 15. Auditoria

El backend puede guardar trazas tecnicas propias, pero la auditoria oficial del acceso debe seguir apoyandose en eventos de blockchain.

Eso deja una historia verificable y coherente con el modelo del proyecto.

## 15.1 Estado esperado de permisos desde backend

El backend debe devolver el estado de cada permiso en estas categorias:

- Activo.
- Expirado.
- Revocado.

La logica debe permitir que el frontend muestre esa misma informacion sin tener que reinterpretarla.

## 16. Estructura recomendada

Una estructura ordenada podria ser:

- `src/routes/`
- `src/controllers/`
- `src/services/`
- `src/contracts/`
- `src/middlewares/`
- `src/storage/`
- `src/utils/`
- `src/config/`

## 17. Buenas practicas de backend

- Validar todo en servidor.
- No confiar en el frontend para autorizacion final.
- No guardar datos medicos sensibles en blockchain.
- Separar almacenamiento de archivos y logica de permisos.
- Reutilizar un solo modulo para hablar con el Registry.
- Registrar errores y decisiones de acceso.

## 18. Relacion con el frontend

El frontend pide al backend:

- subir archivos,
- listar documentos,
- validar accesos,
- y descargar archivos permitidos.

El backend responde con datos y archivos, pero siempre pasando por la validacion del Registry.

## 19. Resumen final

El backend de MediRecord es el custodio del PDF y el verificador final del permiso.

La blockchain decide si existe autorizacion, pero el backend decide si entrega el archivo real.

Ese esquema mantiene el proyecto claro, seguro y facil de explicar.
