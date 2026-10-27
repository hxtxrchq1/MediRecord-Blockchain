# MediRecord: guia de backend, arquitectura y flujo completo

## 1. Proposito

Este documento organiza el backend de MediRecord como una guia tecnica completa para entender que hace cada parte, como se conecta con la blockchain, como se guarda la informacion en base de datos y cual es el flujo real desde que un paciente sube un PDF hasta que otro usuario obtiene acceso.

La idea es que esta guia sirva como referencia de arquitectura antes de escribir el backend final.

## 2. Contexto del proyecto

MediRecord usa blockchain para administrar permisos de acceso, no para almacenar informacion medica.

Reglas centrales:

- El smart contract no almacena PDFs.
- El smart contract no almacena nombres de pacientes.
- El smart contract no almacena diagnosticos.
- El smart contract no almacena rutas de archivos.
- La informacion medica real vive en el backend.
- La blockchain conserva permisos, roles, credenciales y auditoria.

## 3. Arquitectura general

La arquitectura del proyecto queda asi:

- Frontend React
- MetaMask
- Ethereum Sepolia
- Smart Contracts
- Backend Node.js
- Base de datos
- Repositorio de PDFs

El frontend consulta el Registry.
El backend guarda archivos y valida acceso.
La blockchain define permisos y credenciales.

## 4. Contratos y responsabilidad

### 4.1 MediRecordRegistry

Es el contrato principal.

Responsabilidades:

- registrar usuarios tecnicos,
- administrar roles,
- registrar documentos tecnicos,
- emitir permisos,
- revocar permisos,
- validar acceso,
- emitir eventos de auditoria,
- coordinar la credencial NFT.

### 4.2 MedicalAccessNFT

Representa la credencial de acceso.

Responsabilidades:

- crear la credencial ERC721,
- impedir transferencias,
- impedir aprobaciones,
- marcar revocacion,
- exponer consultas de estado.

### 4.3 Relacion entre ambos

El Registry es quien usa el NFT.
El NFT no debe ser consumido directamente por el frontend.

La secuencia de despliegue se hace en dos pasos para evitar dependencia circular:

1. Desplegar `MedicalAccessNFT`.
2. Desplegar `MediRecordRegistry` usando la direccion del NFT.
3. Llamar a `updateRegistry(address newRegistry)` en `MedicalAccessNFT`.

Con eso quedan fijas las direcciones que luego se guardan en `contract-addresses.js`.

## 5. Responsabilidad del backend

El backend es la capa que conserva el contenido real y hace la ultima verificacion antes de entregar un archivo.

Debe encargarse de:

- recibir y validar PDFs,
- guardarlos en disco o almacenamiento externo,
- calcular o registrar el hash del archivo,
- guardar metadata tecnica del documento,
- autenticar la wallet de la sesion,
- consultar al Registry,
- volver a validar permisos antes de entregar un PDF,
- registrar trazabilidad y auditoria tecnica,
- exponer endpoints para el frontend.

El backend no debe:

- asumir que el frontend ya valido acceso,
- confiar solo en la wallet declarada por el navegador,
- usar la base de datos como fuente de verdad para permisos,
- guardar datos medicos en blockchain.

## 6. Stack recomendado

### 6.1 Servidor

- Node.js
- Express o Fastify

### 6.2 Integracion blockchain

- ethers.js
- RPC de Sepolia

### 6.3 Archivos

- multer o equivalente para carga de archivos
- almacenamiento local durante desarrollo
- almacenamiento externo si el proyecto lo requiere

### 6.4 Base de datos

Se recomienda una base relacional para modelar bien usuarios, documentos, permisos y auditoria.

Opciones validas:

- PostgreSQL
- MySQL
- SQLite para entorno de pruebas

## 7. Estructura del backend

Una estructura limpia podria ser:

```text
backend-medirecord/
  src/
    app.js
    server.js
    config/
    contracts/
    controllers/
    middlewares/
    routes/
    services/
    storage/
    models/
    repositories/
    utils/
    validators/
  uploads/
  logs/
  tests/
```

### 7.1 config

Variables de entorno, conexion a base de datos, provider de Sepolia y configuracion general.

### 7.2 contracts

ABIs, direcciones y wrappers de ethers.js.

### 7.3 controllers

Reciben requests HTTP y coordinan la respuesta.

### 7.4 services

Contienen la logica principal del negocio.

### 7.5 repositories

Acceso a base de datos.

### 7.6 storage

Gestor de PDFs y archivos asociados.

### 7.7 middlewares

Autenticacion, validacion, manejo de errores y control de acceso.

### 7.8 validators

Esquemas de validacion para body, params y query.

## 8. Modelo de datos sugerido

### 8.1 Users

Guarda las wallets registradas y su rol tecnico.

Campos sugeridos:

- id
- wallet
- role
- registeredAt
- status

### 8.2 Documents

Guarda la metadata tecnica del archivo.

Campos sugeridos:

- id
- documentId
- documentHash
- fileName
- filePath
- fileSize
- category
- description
- ownerWallet
- uploadedAt
- status

### 8.3 Permissions

Guarda la referencia de negocio del permiso emitido on-chain.

Campos sugeridos:

- id
- permissionId
- tokenId
- documentId
- patientWallet
- authorizedWallet
- issuedAt
- expiresAt
- revoked
- revokedAt
- txHash
- status

### 8.4 AccessLogs

Guarda trazabilidad tecnica de accesos y validaciones.

Campos sugeridos:

- id
- permissionId
- documentId
- requesterWallet
- result
- reason
- txHash
- createdAt

### 8.5 AuditEvents

Guarda referencias de eventos escuchados desde blockchain si el proyecto decide indexarlos.

## 9. Flujo completo del backend

### 9.1 Subida de PDF

1. El paciente se conecta con MetaMask en el frontend.
2. El frontend obtiene el rol desde el Registry.
3. El paciente selecciona un PDF.
4. El frontend envia el archivo al backend.
5. El backend valida formato, tamano y presencia del archivo.
6. El backend genera o recibe `documentId`.
7. El backend calcula o registra `documentHash`.
8. El backend almacena el PDF.
9. El backend guarda la metadata en base de datos.
10. El paciente registra el documento tecnico en el Registry.

### 9.2 Emision de permiso

1. El paciente selecciona el documento.
2. El frontend pide destino y expiracion.
3. La transaccion se firma con MetaMask.
4. El Registry valida propietario, destino y expiracion.
5. El Registry emite el permiso y llama al NFT.
6. El backend puede guardar el `permissionId`, `tokenId` y `txHash` si recibe la informacion.

### 9.3 Consulta de acceso

1. El medico, clinica o aseguradora solicita el documento.
2. El frontend envia la solicitud al backend.
3. El backend identifica la wallet solicitante.
4. El backend consulta al Registry.
5. El backend verifica que el permiso exista, no este revocado, no haya expirado y que la credencial siga activa.
6. Si todo es valido, el backend entrega el PDF.
7. Si falla algo, el backend niega el acceso y registra la trazabilidad.

### 9.4 Revocacion

1. El paciente solicita revocar un permiso.
2. El frontend firma la operacion.
3. El Registry marca el permiso como revocado.
4. El NFT se marca como revocado.
5. El backend actualiza el estado local si conserva espejo de datos.

## 10. Endpoints recomendados

### 10.1 Documentos

- `POST /documents/upload`
- `GET /documents`
- `GET /documents/:id`
- `GET /documents/:id/file`
- `DELETE /documents/:id`

### 10.2 Permisos

- `POST /permissions/validate`
- `GET /permissions/:documentId/:wallet`
- `GET /permissions/issued/:wallet`
- `GET /permissions/received/:wallet`
- `POST /permissions/log`

### 10.3 Usuarios

- `GET /users/:wallet`
- `GET /roles/:wallet`
- `GET /users`

### 10.4 Auditoria

- `GET /audit/documents/:id`
- `GET /audit/access/:documentId`
- `GET /audit/permissions/:permissionId`

### 10.5 Salud y soporte

- `GET /health`
- `GET /config/status`

## 11. Validaciones obligatorias

El backend debe rechazar cualquier operacion que no cumpla estas reglas:

- el archivo debe existir,
- el documento debe estar registrado tecnicamente,
- la wallet solicitante debe estar registrada,
- el rol debe ser valido,
- el permiso debe existir,
- el permiso no debe estar revocado,
- la expiracion debe ser futura o vigente,
- la credencial NFT debe seguir activa,
- el Registry debe confirmar el acceso,
- el backend no debe entregar el PDF sin validacion final.

## 12. Seguridad

### 12.1 Autenticacion por wallet

El backend debe vincular la sesion a una wallet y no aceptar identidad por query string o body sin verificarla.

### 12.2 Validacion doble

La validacion debe hacerse dos veces:

- en el frontend para experiencia de usuario,
- en el backend para entrega real del archivo.

### 12.3 Control de errores

El backend debe manejar:

- wallet no conectada,
- red incorrecta,
- cuenta no registrada,
- permiso expirado,
- permiso revocado,
- archivo no encontrado,
- firma rechazada,
- gas insuficiente para una transaccion.

### 12.4 Auditoria

La auditoria oficial debe apoyarse en eventos on-chain.

La base de datos puede guardar una copia tecnica de respaldo.

## 13. Integracion con ethers.js

El backend debe cargar:

- `MedicalAccessNFTABI.json`
- `MediRecordRegistryABI.json`
- `contract-addresses.js`

Y construir instancias para:

- leer roles,
- validar documentos,
- consultar permisos,
- revisar estado de credenciales,
- registrar validaciones si el flujo lo requiere.

## 14. Reglas por rol

### 14.1 Administrador

- registra participantes,
- asigna roles,
- revisa actividad,
- no emite permisos medicos por los pacientes.

### 14.2 Paciente

- sube documentos,
- consulta sus documentos,
- emite permisos,
- revoca sus permisos,
- consulta historial.

### 14.3 Medico

- consulta documentos autorizados,
- consulta permisos vigentes,
- no modifica permisos.

### 14.4 Clinica

- consulta documentos autorizados,
- consulta permisos vigentes,
- no modifica permisos.

### 14.5 Aseguradora

- consulta autorizaciones permitidas,
- consulta historial,
- no modifica permisos.

## 15. Mapa de vistas que alimenta el backend

El backend debe soportar datos para:

- login o conexion,
- dashboard por rol,
- mis documentos,
- compartir documento,
- detalle del documento,
- detalle del permiso,
- historial de accesos,
- perfil,
- configuracion,
- estado de transaccion,
- pantallas de error.

## 16. Flujo tecnico resumido

1. Wallet conectada en frontend.
2. Rol consultado en Registry.
3. PDF subido al backend.
4. Documento guardado con metadata y hash.
5. Documento registrado en blockchain.
6. Permiso emitido por el Registry.
7. NFT creado como credencial.
8. Solicitud de acceso recibida por el backend.
9. Validacion contra blockchain y base de datos.
10. Entrega segura del PDF.
11. Registro de trazabilidad.

## 17. Entregable esperado del backend

El backend debe terminar funcionando como una capa segura y coherente con MediRecord:

- guarda documentos reales,
- conserva metadata tecnica,
- valida acceso antes de servir archivos,
- respeta roles,
- se integra con Sepolia,
- usa los ABIs y direcciones compartidas,
- y mantiene la arquitectura limpia para el frontend.
