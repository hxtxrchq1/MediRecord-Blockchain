# Guía de Frontend para MediRecord

## 1. Objetivo

Esta guia define como debe construirse el frontend de MediRecord para que tu companero tenga una referencia clara de vistas, roles, flujo de usuario e integracion con blockchain.

La regla principal es esta: el frontend presenta la experiencia, pero no guarda informacion medica sensible ni toma decisiones de confianza por si solo.

## 2. Responsabilidad del frontend

El frontend debe encargarse de:

- mostrar la experiencia visual del sistema,
- conectar la wallet con MetaMask,
- detectar red y cuenta activa,
- consultar el rol del usuario,
- mostrar las vistas segun rol,
- firmar transacciones cuando sea necesario,
- llamar al backend para subir o descargar documentos,
- y mostrar errores claros al usuario.

El frontend no debe:

- guardar PDFs,
- decidir por si solo si un acceso es valido,
- ni sustituir la validacion del Registry o del backend.

## 3. Tecnologias recomendadas

- React
- ethers.js
- MetaMask
- React Router
- fetch o axios para backend

## 4. Datos que necesita consumir

El frontend debe leer dos fuentes principales:

### Desde blockchain

- direccion del `MediRecordRegistry`,
- direccion del `MedicalAccessNFT`,
- ABI de ambos contratos,
- rol del usuario,
- documentos tecnicos,
- permisos,
- tokenId,
- estado de la credencial,
- eventos de auditoria.

### Desde backend

- PDF real,
- nombre del documento,
- descripcion,
- categoria,
- fecha de carga,
- owner tecnico,
- historial de archivos,
- respuesta de acceso.

## 5. Estructura de vistas

La interfaz no debe verse como un panel cripto. Debe verse como una aplicacion medica moderna.

### 5.1 Landing page

Pantalla publica con:

- nombre del sistema,
- propuesta de valor,
- resumen del flujo,
- roles soportados,
- ventajas del sistema,
- boton de conectar wallet.

### 5.2 Pantalla de conexion

Debe mostrar:

- wallet conectada,
- red actual,
- estado de MetaMask,
- rol detectado,
- y acceso al dashboard correspondiente.

Tambien debe cubrir errores como:

- MetaMask no instalada,
- red incorrecta,
- cuenta no autorizada,
- usuario no registrado,
- usuario cancelo la firma.

### 5.3 Dashboard del Administrador

Debe permitir:

- registrar usuarios,
- cambiar roles,
- ver wallets registradas,
- revisar documentos tecnicos,
- revisar permisos emitidos,
- consultar auditoria,
- acceder al perfil de administracion.

### 5.4 Dashboard del Paciente

Debe permitir:

- subir documentos al backend,
- ver mis documentos,
- compartir un documento,
- revisar permisos activos,
- revocar permisos si el flujo lo permite,
- revisar historial de consultas,
- ver perfil personal.

### 5.5 Dashboard del Medico

Debe permitir:

- ver documentos compartidos con su wallet,
- ver permisos vigentes,
- abrir detalle del documento autorizado,
- revisar historial de acceso,
- ver perfil profesional.

### 5.6 Dashboard de la Clinica

Debe tener la misma logica general que el medico, pero con etiqueta institucional.

Debe mostrar:

- documentos autorizados,
- permisos vigentes,
- historial,
- perfil institucional.

### 5.7 Dashboard de la Aseguradora

Debe mostrar:

- documentos autorizados,
- permisos vigentes,
- historial de validaciones,
- perfil institucional.

### 5.8 Vistas complementarias

Ademas de los dashboards, conviene tener estas pantallas:

- Mis Documentos,
- Subir Documento,
- Compartir Documento,
- Detalle del Documento,
- Detalle del Permiso,
- Historial Blockchain,
- Perfil,
- Configuracion,
- Estado de transaccion,
- Pantallas de error.

## 6. Roles y comportamiento esperado

### Admin

Puede administrar la base tecnica del sistema.

### Paciente

Es el propietario de la informacion y quien autoriza el acceso.

### Medico

Consulta informacion cuando tiene permiso vigente.

### Clinica

Consulta informacion con un perfil institucional.

### Aseguradora

Verifica permisos para evaluaciones o autorizaciones.

## 6.1 Roles y control de acceso detallado

MediRecord debe respetar estas reglas de acceso en la interfaz:

### Administrador

- Es la cuenta que despliega el contrato.
- Puede registrar nuevas direcciones y asignarles un rol.
- Puede consultar los participantes registrados.
- No puede otorgar ni revocar permisos medicos en nombre de los pacientes.
- Si una persona necesita actuar como administrador y paciente, debe usar dos cuentas distintas de MetaMask.

### Paciente

- Es el titular de los permisos medicos.
- Puede otorgar permisos a medicos, clinicas y aseguradoras previamente registradas.
- Puede consultar los permisos emitidos.
- Puede revocar permisos que sigan activos.
- Ninguna otra cuenta puede revocar un permiso emitido por el paciente.

### Medico

- Puede consultar los permisos otorgados por los pacientes.
- Puede verificar si un permiso esta activo, expirado o revocado.
- No puede emitir permisos, cambiar su vigencia ni transferir el token recibido.

### Clinica

- Puede recibir y consultar permisos institucionales otorgados por pacientes.
- No puede modificar ni transferir los permisos recibidos.

### Aseguradora

- Puede consultar permisos relacionados con coberturas, auditorias o autorizaciones administrativas.
- No puede modificar, revocar ni transferir permisos.

## 6.2 Distribucion de cuentas para pruebas

Para la demostracion del sistema se deben usar seis cuentas independientes de MetaMask:

- Cuenta 1: administrador y desplegador del contrato.
- Cuenta 2: paciente 1.
- Cuenta 3: paciente 2.
- Cuenta 4: medico.
- Cuenta 5: clinica.
- Cuenta 6: aseguradora.

Cada integrante debe usar su propia cuenta.
No es necesario compartir contraseñas, claves privadas ni frases de recuperacion.

## 7. Reglas de experiencia por rol

El frontend debe cambiar dos cosas segun el rol:

- los modulos visibles,
- y las acciones disponibles.

No es necesario construir cinco aplicaciones distintas. Es mejor usar un dashboard base y mostrar o esconder bloques segun el rol.

Tambien debe reflejar el estado de cada permiso con estas categorias:

- Activo.
- Expirado.
- Revocado.

## 8. Flujo de pantalla

1. El usuario entra al sitio.
2. Ve la landing page.
3. Conecta MetaMask.
4. El frontend detecta red y cuenta.
5. Consulta el rol en el Registry.
6. Redirige al dashboard correcto.
7. Muestra acciones permitidas segun rol.
8. Si el usuario firma una transaccion, el frontend muestra progreso y resultado.

## 8.1 Requisitos funcionales que el frontend debe soportar

### RF01. Conexion con MetaMask

El frontend debe permitir conectar una cuenta de MetaMask y mostrar la direccion publica activa.

### RF02. Validacion de la red

El frontend debe verificar que la red sea Ethereum Sepolia antes de permitir operaciones.

### RF03. Actualizacion de cuenta

Si el usuario cambia de cuenta en MetaMask, el frontend debe actualizar automaticamente la direccion, el rol y la informacion mostrada.

### RF04. Consulta del rol

El frontend debe consultar el rol asignado a la direccion conectada y mostrar solo las funciones correspondientes.

### RF05. Registro de participantes

El frontend debe exponer al administrador la opcion de registrar una direccion y asignarle un rol permitido.

### RF06. Consulta de participantes

El frontend debe permitir al administrador consultar las direcciones registradas y su rol.

### RF07. Otorgamiento de permisos

El frontend debe permitir que el paciente cree un permiso indicando:

- direccion autorizada,
- tipo de acceso,
- referencia externa del documento,
- fecha de expiracion.

### RF08. Emision del token

El frontend debe mostrar que el permiso genera un token unico asociado a la autorizacion.

### RF09. Consulta de permisos emitidos

El paciente debe poder ver los permisos que emitio con sus datos principales.

### RF10. Consulta de permisos recibidos

Medicos, clinicas y aseguradoras deben poder ver los permisos que recibieron.

### RF11. Validacion del permiso

El frontend debe mostrar el resultado de una validacion de solo lectura que indique si el permiso existe, no fue revocado y no expiro.

### RF12. Registro de consulta

El frontend debe permitir ejecutar la transaccion de registro de consulta y mostrar el resultado on-chain.

### RF13. Revocacion de permisos

El paciente debe poder revocar un permiso que haya emitido.

### RF14. Visualizacion de transacciones

Despues de cada operacion, el frontend debe mostrar el hash de la transaccion y un enlace a Sepolia Etherscan.

### RF15. Gestion de estados

El frontend debe representar cada permiso como Activo, Expirado o Revocado.

### RF16. Manejo de errores

El frontend debe informar claramente cuando ocurra alguno de estos casos:

- MetaMask no esta instalado.
- La wallet no esta conectada.
- La red seleccionada no es Sepolia.
- El usuario rechaza una transaccion.
- La cuenta no tiene un rol registrado.
- La direccion autorizada no es valida.
- La cuenta no tiene permisos para ejecutar la operacion.
- El saldo de Sepolia ETH es insuficiente.
- El permiso esta expirado o revocado.

## 8.2 Reglas de negocio que el frontend debe respetar

El frontend no debe decidir por si solo la seguridad, pero si debe reflejar estas reglas en la interfaz:

- Una cuenta solo puede tener un rol.
- Solo el administrador puede registrar participantes.
- Solo pacientes pueden emitir permisos.
- Solo se pueden autorizar medico, clinica o aseguradora.
- No se permite autoautorizacion.
- La expiracion debe ser futura.
- El token de permiso no debe verse como transferible.
- El contenido de un permiso no debe editarse despues de emitido.
- Solo el paciente emisor puede revocar.
- La expiracion es automatica por fecha.
- Las consultas de lectura no consumen gas.
- Las operaciones de escritura consumen Sepolia ETH.
- El frontend no reemplaza las validaciones del contrato.

## 9. Integracion con contratos

### Registry

Es el contrato principal que el frontend consulta para roles, documentos y permisos.

### NFT

Se usa como credencial tecnica asociada al permiso.

### ABI y direcciones

El frontend debe consumir los archivos que estan en la raiz del proyecto:

- `MedicalAccessNFTABI.json`
- `MediRecordRegistryABI.json`
- `contract-addresses.js`

## 9.1 Vistas que deben quedar cubiertas por el frontend

El compañero de frontend deberia tener en cuenta estas pantallas como minimo:

- Landing Page.
- Conexion de wallet.
- Dashboard de administrador.
- Dashboard de paciente.
- Dashboard de medico.
- Dashboard de clinica.
- Dashboard de aseguradora.
- Mis Documentos.
- Subir Documento.
- Compartir Documento.
- Detalle del Documento.
- Detalle del Permiso.
- Historial Blockchain.
- Perfil.
- Configuracion.
- Transacciones.
- Errores y estados vacios.

## 9.2 Flujo visual esperado para permisos

La interfaz debe permitir distinguir claramente estos estados:

- Activo: puede utilizarse.
- Expirado: ya no permite acceso.
- Revocado: fue cancelado por el paciente.

Cuando se ejecute una operacion, el frontend debe mostrar:

- estado de carga,
- confirmacion de firma,
- hash de transaccion,
- enlace a Etherscan,
- y mensaje final de exito o error.

## 10. Estructura recomendada

Una estructura simple y clara podria ser:

- `src/contracts/`
- `src/pages/`
- `src/components/`
- `src/hooks/`
- `src/services/`
- `src/routes/`
- `src/utils/`

## 11. Piezas clave que debe implementar el companero

- un proveedor de MetaMask,
- un contexto de wallet,
- deteccion de rol,
- proteccion de rutas por rol,
- componente de carga de transaccion,
- componente de errores,
- componente para listar documentos,
- componente para compartir documentos,
- componente para ver permisos.

## 12. Buenas practicas de frontend

- No confiar en el navegador como unica fuente de verdad.
- No mostrar acciones que el rol no puede ejecutar.
- Siempre reflejar el estado real de la wallet y la red.
- Mostrar mensajes legibles, no errores tecnicos crudos.
- Reutilizar el mismo layout base para todos los dashboards.

## 13. Relacion con el backend

El frontend no entrega el PDF por si mismo.

Siempre debe pedir al backend el archivo o el acceso al archivo, despues de que el backend y el Registry validen el permiso.

Eso evita que una manipulacion del navegador rompa la seguridad.

## 14. Resumen final

El frontend de MediRecord debe ser una capa de experiencia y control visual.

Su trabajo es guiar al usuario, mostrar vistas por rol y firmar acciones en blockchain cuando sea necesario.

La logica de confianza vive en el Registry y la custodia real del PDF vive en el backend.
