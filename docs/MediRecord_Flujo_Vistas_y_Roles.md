# MediRecord: flujo, roles, vistas y arquitectura de uso

## 1. Objetivo del documento

Este documento resume, de forma práctica y técnica, cómo se utilizará MediRecord en el proyecto.

La intención es dejar claro:

- para qué sirve cada contrato,
- cómo se conectan frontend, backend y blockchain,
- qué rol cumple cada participante,
- qué pantallas debe tener el sistema,
- y cuál es el flujo completo desde que el usuario entra hasta que un PDF es entregado.

La idea es que este texto funcione como base de documentación del proyecto antes de comenzar el desarrollo del frontend y del backend.

## 2. Idea central del sistema

MediRecord no usa blockchain para guardar documentos médicos.

La blockchain solo se usa para:

- registrar identidades técnicas,
- registrar documentos de forma técnica,
- emitir permisos de acceso,
- revocar permisos,
- validar autorizaciones,
- y dejar auditoría mediante eventos.

El PDF real vive en el backend Node.js.

Eso significa que el contrato no almacena:

- nombres,
- correos,
- diagnósticos,
- recetas,
- PDFs,
- rutas de archivo,
- ni información médica sensible.

## 3. Contratos del sistema

### 3.1 MediRecordRegistry.sol

Es el contrato principal.

Su función es concentrar la lógica del negocio:

- registro técnico de usuarios,
- administración de roles,
- registro técnico de documentos,
- emisión de permisos,
- revocación de permisos,
- validación de acceso,
- y auditoría por eventos.

Este contrato es el que utilizarán el frontend y el backend.

### 3.2 MedicalAccessNFT.sol

Este contrato representa una credencial digital de acceso.

No representa el documento médico.
No representa al paciente.
No representa el contenido clínico.

Solo representa que una wallet tiene autorización temporal sobre un documento específico.

Además, esa credencial es:

- única,
- verificable,
- intransferible,
- y controlada por el Registry.

### 3.3 IMedicalAccessNFT.sol

Es la interfaz mínima que usa el Registry para comunicarse con el NFT.

Sirve para desacoplar los dos contratos y hacer más clara la relación entre negocio y credencial.

## 4. Roles del sistema

Los roles definidos en MediRecord sirven para controlar quién puede hacer qué dentro de la plataforma.

### 4.1 Administrador

Cuenta responsable de registrar participantes y asignar roles dentro del sistema.

Puede administrar la base técnica del sistema, revisar documentos, permisos y actividad.

### 4.2 Paciente

Titular de la información médica.

Es quien sube sus documentos al backend y quien otorga o revoca permisos de acceso.

### 4.3 Médico

Profesional que consulta información autorizada para atención o diagnóstico.

Solo puede ver documentos que hayan sido compartidos con su wallet.

### 4.4 Clínica

Entidad institucional que consulta información médica externa cuando cuenta con un permiso vigente.

### 4.5 Aseguradora

Entidad que verifica permisos para evaluaciones de cobertura, auditorías o autorizaciones.

## 5. Relación entre contratos y aplicación

### Frontend

React será la interfaz principal para el usuario.

Se conectará con Ethereum Sepolia mediante ethers.js.

El frontend solo necesita:

- la dirección del Registry,
- la dirección del NFT,
- y los ABI de ambos contratos.

### Backend

Node.js almacenará los archivos y actuará como guardián del contenido real.

Su trabajo será:

- guardar PDFs,
- guardar metadata técnica,
- calcular o conservar el hash del documento,
- y validar el acceso antes de entregar un archivo.

### Blockchain

Ethereum Sepolia será el entorno donde se despliegan los contratos.

Remix solo se usa para desarrollo y despliegue inicial.

Después del deploy, el frontend y el backend se conectan directamente con ethers.js.

## 6. Flujo general del sistema

El flujo completo es el siguiente:

1. El usuario entra al frontend.
2. Conecta su wallet con MetaMask.
3. El sistema detecta la red Sepolia.
4. El frontend consulta el rol registrado en el Registry.
5. Se muestra el dashboard correspondiente.
6. El paciente sube un PDF al backend.
7. El backend guarda el archivo y genera la referencia técnica.
8. El paciente registra el documento técnico en el Registry.
9. El paciente comparte el documento con una wallet autorizada.
10. El Registry emite el permiso.
11. MedicalAccessNFT crea la credencial NFT.
12. El usuario autorizado solicita acceso al documento.
13. El Registry valida el permiso.
14. El backend verifica nuevamente antes de entregar el PDF.
15. La auditoría queda registrada por evento.

## 7. Flujo detallado por etapa

### 7.1 Usuario

El usuario no debe sentir que está usando una interfaz de blockchain.

Debe percibir el sistema como un software médico moderno.

MetaMask solo aparece cuando es necesario firmar una transacción.

### 7.2 Registro

El administrador registra wallets y asigna roles.

Eso le permite al sistema saber si una cuenta corresponde a un paciente, médico, clínica, aseguradora o administrador.

Este registro es técnico, no clínico.

### 7.3 Documento

El paciente sube el PDF al backend.

El backend conserva el archivo real y genera o guarda:

- documentId,
- documentHash.

Ese documento luego se registra en el Registry.

### 7.4 Permiso

Cuando el paciente decide compartir el documento:

- el Registry valida que el documento exista,
- valida que la wallet sea la propietaria,
- valida que el destinatario esté registrado,
- valida la expiración,
- y evita permisos duplicados activos.

Después emite el permiso y llama al NFT para crear la credencial.

### 7.5 NFT

MedicalAccessNFT crea la credencial ERC721.

La credencial no puede transferirse.
No puede aprobarse.
No puede usarse como activo comercial.

Solo existe para representar acceso temporal y verificable.

### 7.6 Validación de acceso

Cuando una wallet intenta acceder a un documento:

- el Registry revisa si hay un permiso vigente,
- revisa si el permiso no está revocado,
- revisa si no venció,
- revisa si la credencial NFT sigue activa,
- y decide si el acceso se permite.

### 7.7 Auditoría

Cada validación puede dejar un evento en blockchain.

Eso permite tener trazabilidad sin guardar una bitácora adicional en storage.

## 8. Vistas del sistema

El sistema debe verse como una aplicación médica moderna, no como una aplicación cripto.

### 8.1 Landing Page

Es la pantalla pública.

Debe incluir:

- nombre del proyecto,
- descripción del sistema,
- explicación breve del flujo,
- beneficios,
- tecnologías utilizadas,
- y botón para conectar MetaMask.

### 8.2 Pantalla de conexión

Se muestra al conectar la wallet.

Debe indicar:

- wallet conectada,
- estado de MetaMask,
- estado de la red,
- rol detectado,
- y si el usuario puede continuar.

También debe manejar errores como:

- MetaMask no instalada,
- red incorrecta,
- usuario canceló conexión,
- usuario no registrado.

### 8.3 Dashboard Administrador

Debe permitir:

- registrar usuarios,
- consultar usuarios,
- ver documentos registrados,
- ver permisos emitidos,
- revisar actividad blockchain,
- y consultar el perfil del administrador.

### 8.4 Dashboard Paciente

Debe permitir:

- subir documentos,
- ver mis documentos,
- compartir un documento,
- ver mis permisos emitidos,
- revisar historial de consultas,
- y consultar el perfil.

### 8.5 Dashboard Médico

Debe permitir:

- ver documentos compartidos con su wallet,
- ver sus autorizaciones,
- registrar consulta si el sistema lo utiliza,
- revisar historial,
- y consultar su perfil.

### 8.6 Dashboard Clínica

Debe permitir una experiencia muy parecida a la del médico.

La diferencia está en el tipo de actor y en el texto de las secciones.

### 8.7 Dashboard Aseguradora

Debe mostrar:

- documentos autorizados,
- permisos vigentes,
- historial,
- y perfil institucional.

### 8.8 Vistas complementarias

Además de los dashboards, conviene tener vistas específicas para:

- Mis Documentos,
- Compartir Documento,
- Vista Documento,
- Detalle del Permiso,
- Historial Blockchain,
- Perfil,
- Configuración,
- Transacciones,
- y pantallas de error.

## 9. Recomendación de interfaz

Lo más recomendable es no construir cinco dashboards totalmente distintos.

Lo ideal es usar un dashboard base común y cambiar solo:

- los módulos visibles,
- las acciones permitidas,
- y el título del rol.

Eso reduce trabajo, hace la interfaz más consistente y mantiene el sistema más fácil de mantener.

## 10. Qué datos vienen de cada capa

### Desde blockchain

- rol registrado,
- documentos técnicos,
- permisos,
- tokenId,
- estado de la credencial,
- eventos de auditoría.

### Desde backend

- PDF,
- nombre del documento,
- categoría,
- descripción,
- fecha de carga,
- nombre del paciente,
- metadata adicional,
- historial de almacenamiento.

### Desde frontend

- navegación,
- formularios,
- tablas,
- mensajes de error,
- estados visuales,
- y llamadas a backend o contratos.

## 11. Qué función tiene cada capa

### Frontend

Presenta la información y permite la interacción con el usuario.

### MetaMask

Firma las transacciones necesarias.

### Backend

Guarda documentos y vuelve a validar el acceso antes de entregar el archivo.

### Registry

Gobierna permisos, documentos y validaciones.

### NFT

Representa la credencial intransferible.

## 12. Sobre la auditoría

La auditoría debe quedar en eventos, no en storage.

Esto es suficiente porque Ethereum ya conserva trazabilidad histórica.

Además, evita duplicar lógica innecesaria.

## 13. Sobre la seguridad del backend

El backend nunca debe confiar solo en el navegador.

Aunque el frontend ya haya validado algo, el backend debe volver a consultar el Registry antes de entregar un PDF.

Eso evita que el navegador sea manipulado.

## 14. Conclusión

MediRecord debe funcionar como un sistema médico con soporte blockchain, no como un explorador de blockchain con pantallas médicas.

El backend conserva el archivo.
El Registry conserva la lógica.
El NFT conserva la credencial.
El frontend organiza la experiencia.

Ese enfoque permite construir una solución clara, profesional y adecuada para una entrega universitaria.
