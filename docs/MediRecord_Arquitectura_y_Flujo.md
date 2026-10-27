# MediRecord: arquitectura, motivo y flujo del sistema

## 1. Propósito del proyecto

MediRecord es un sistema universitario para controlar autorizaciones de acceso a documentos médicos usando blockchain como capa de verificación de permisos, no como repositorio de información clínica.

El objetivo principal no es almacenar historiales médicos en cadena, sino registrar de forma confiable quién puede acceder a un documento específico, durante cuánto tiempo y bajo qué condiciones.

La información médica real permanece fuera de la blockchain, en un backend Node.js que almacena los PDF, la ruta del archivo, el identificador técnico del documento y su hash.

## 2. Motivo del diseño

El diseño del proyecto sigue una separación estricta de responsabilidades:

- La blockchain administra permisos.
- El backend administra documentos.
- El frontend administra la interacción con el usuario.
- MetaMask autentica la identidad de la wallet.

Esta división evita varios problemas:

- No se exponen datos médicos sensibles en cadena.
- No se duplican responsabilidades entre contratos.
- La validación de acceso puede auditarse con eventos.
- El sistema queda más simple para un proyecto universitario.
- La arquitectura es más fácil de probar y explicar.

## 3. Visión general de la arquitectura

La arquitectura se organiza así:

- Frontend React
- MetaMask
- Ethereum Sepolia
- Smart Contracts
- Backend Node.js
- Base de datos
- Repositorio de PDFs

La blockchain no entrega el PDF directamente. Solo decide si el acceso está permitido.

## 4. Responsabilidad de cada contrato

### 4.1 MediRecordRegistry.sol

Este es el contrato principal del sistema.

Su función es concentrar toda la lógica de negocio:

- Registro técnico de usuarios.
- Gestión de roles.
- Registro técnico de documentos.
- Emisión de permisos.
- Revocación de permisos.
- Validación de acceso.
- Emisión de eventos de auditoría.
- Sincronización con MedicalAccessNFT.

Este contrato es el punto de entrada que consume el frontend y también el punto que consulta el backend antes de entregar un documento.

### 4.2 MedicalAccessNFT.sol

Este contrato representa la credencial on-chain del acceso.

No representa:

- Un documento médico.
- Un paciente.
- Un historial clínico.
- Un PDF.

Solo representa una autorización temporal mediante un NFT ERC721 intransferible.

Su responsabilidad es mínima:

- Crear la credencial.
- Bloquear transferencias.
- Bloquear aprobaciones.
- Marcar la credencial como revocada.
- Permitir consultas de estado.

### 4.3 IMedicalAccessNFT.sol

Es la interfaz mínima que usa el Registry para comunicarse con el contrato NFT.

Su propósito es desacoplar el Registry de la implementación concreta del NFT y dejar clara la superficie necesaria para:

- Acuñar credenciales.
- Revocarlas.
- Consultar si una credencial está activa.

## 5. Flujo funcional completo

### 5.1 Usuario

El usuario interactúa con el frontend usando MetaMask.

MetaMask sirve como mecanismo de autenticación de la wallet. La identidad del usuario en el sistema está asociada a su dirección pública, no a un nombre o correo almacenado en blockchain.

### 5.2 Registro

El owner administrativo del sistema registra direcciones dentro del Registry con un rol técnico.

Los roles actuales representan actores funcionales del sistema:

- ADMIN
- PATIENT
- DOCTOR
- CLINIC
- INSURANCE

El registro no guarda datos personales.

### 5.3 Documento

El paciente sube el PDF al backend.

El backend genera:

- documentId
- documentHash

El Registry solo almacena la relación técnica del documento con su propietario.

Esto permite verificar integridad del archivo sin guardar el archivo en la blockchain.

### 5.4 Permiso

Cuando el paciente decide compartir el documento:

- El Registry registra el documento técnico.
- El Registry crea el permiso asociado a ese documento y a una wallet autorizada.
- El Registry llama a MedicalAccessNFT para materializar la credencial.
- El Registry guarda la relación entre permissionId y tokenId.

El permiso es temporal y está atado a una wallet específica.

### 5.5 NFT

MedicalAccessNFT crea la credencial ERC721.

Ese NFT no se transfiere y no se aprueba para otros usuarios.

La credencial sirve como prueba técnica de que el acceso fue emitido por el Registry.

### 5.6 Validación de acceso

Antes de entregar un PDF, el backend consulta al Registry.

La validación se hace con:

- requester
- documentId

El Registry verifica:

- Que el documento exista.
- Que la wallet esté registrada.
- Que exista un permiso activo.
- Que el permiso no esté revocado.
- Que el permiso no esté expirado.
- Que la credencial NFT siga activa.

Si todo coincide, el acceso se concede.

### 5.7 Auditoría

Cada intento de acceso queda registrado mediante un evento.

Esto permite trazabilidad sin almacenar auditoría en storage.

La auditoría registra:

- documentId
- requester
- timestamp
- resultado de la validación

## 6. Estructuras de datos principales

### 6.1 Usuario

Representa una wallet registrada con un rol técnico y un estado mínimo de registro.

No contiene nombres, correos ni datos clínicos.

### 6.2 Documento

Relaciona tres elementos técnicos:

- documentId
- documentHash
- owner

Esto es suficiente para identificar un documento sin almacenar información médica.

### 6.3 Permiso

El permiso modela la autorización de acceso.

Contiene:

- permissionId
- tokenId
- documentId
- documentHash
- patient
- authorized
- issuedAt
- expiresAt
- revoked

Este diseño permite correlacionar el negocio del Registry con la credencial NFT.

## 7. Razón de usar eventos para auditoría

La auditoría no se guarda en storage porque eso aumentaría complejidad y costo de gas sin aportar valor real al dominio.

Ethereum ya ofrece trazabilidad mediante logs.

Por eso el sistema registra eventos para:

- Emisión de usuarios.
- Registro de documentos.
- Emisión de permisos.
- Revocación de permisos.
- Validaciones de acceso.

## 8. Seguridad y buenas prácticas

El diseño sigue varias buenas prácticas:

- Separación estricta de responsabilidades.
- Uso de errors personalizados.
- Bloqueo total de transferencias en el NFT.
- Dependencia fija entre Registry y NFT.
- No almacenar datos médicos sensibles en cadena.
- Validación fail-closed.
- Auditoría mediante eventos.

Esto evita que un contrato termine haciendo el trabajo del otro.

## 9. Qué problema resuelve cada contrato

### MediRecordRegistry.sol

Resuelve la lógica de negocio: quién puede registrar, quién puede compartir, quién puede acceder y bajo qué condiciones.

### MedicalAccessNFT.sol

Resuelve la representación técnica de la credencial de acceso.

### IMedicalAccessNFT.sol

Resuelve el desacoplamiento entre el Registry y el NFT.

## 10. Estado actual del proyecto

El código actual ya está orientado a este flujo general.

A nivel conceptual, la arquitectura está lista para pruebas del flujo completo:

- Registro de usuario.
- Registro de documento.
- Emisión de permiso.
- Creación de credencial NFT.
- Validación de acceso.
- Revocación del permiso.
- Auditoría por eventos.

## 11. Observación importante

La documentación del código y esta guía describen el flujo previsto del proyecto. Si en etapas posteriores se decide simplificar o eliminar alguna función administrativa, la documentación deberá actualizarse para mantener coherencia con la implementación final.

## 12. Resumen ejecutivo

MediRecord usa blockchain como capa de autorización y auditoría, no como almacén de documentos médicos.

El backend conserva los PDFs.

El Registry controla la lógica del acceso.

MedicalAccessNFT representa la credencial intransferible.

El frontend solo consume la capa de negocio y el backend valida permisos antes de entregar información.

Ese enfoque mantiene el sistema simple, seguro y entendible para una entrega académica.
