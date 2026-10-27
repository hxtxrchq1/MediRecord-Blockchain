# Guía paso a paso para desplegar MediRecord en Sepolia

## 1. Objetivo de esta guía

Esta guía explica cómo subir los contratos de MediRecord a Ethereum Sepolia usando Remix, qué papel cumple MetaMask, qué significa tener Sepolia ETH y qué información debes guardar para poder conectar después el backend y el frontend.

La idea es que el contrato quede desplegado una sola vez y que luego React y Node.js trabajen directamente con la dirección y el ABI del contrato.

## 2. Qué papel cumple MetaMask

MetaMask no forma parte de la lógica del sistema médico.

Su función es:

- conectar tu wallet con Remix o con el frontend,
- firmar transacciones,
- autorizar despliegues,
- autorizar llamadas que cambian estado en blockchain.

En MediRecord, MetaMask solo aparece cuando el usuario o el administrador necesita firmar algo en Sepolia.

Después del despliegue, el frontend y el backend ya no dependen de Remix. Se conectan directamente al contrato mediante ethers.js.

## 3. Qué es Sepolia ETH

Sepolia ETH es ETH de prueba.

Sirve para pagar gas en la red Sepolia, pero no tiene valor real.

No se usa dinero real para desplegar contratos allí.

En un entorno de pruebas, a veces la gente dice "minar" Sepolia ETH, pero en la práctica normalmente se obtiene de un faucet o de herramientas de prueba. Lo importante es que tengas saldo suficiente para pagar:

- despliegue de contratos,
- llamadas de escritura,
- pruebas de transacciones.

## 4. Qué debes tener antes de desplegar

Antes de ir a Remix, verifica esto:

- Tener instalado MetaMask.
- Tener una cuenta configurada en MetaMask.
- Estar en la red Sepolia.
- Tener saldo de Sepolia ETH.
- Tener el contrato final listo.
- Tener claro qué versión del contrato se va a desplegar.

## 4.1 Antes de abrir Remix: configurar MetaMask

Antes de desplegar, MetaMask debe quedar preparado en el navegador.

### Qué debes verificar

- Que la extensión de MetaMask esté instalada.
- Que la wallet ya tenga una cuenta creada o importada.
- Que la cuenta tenga acceso a Sepolia.
- Que exista saldo de Sepolia ETH.
- Que el navegador tenga permiso para usar la extensión.

### Para qué sirve esto

MetaMask es la herramienta que firma la transacción de despliegue.

Sin MetaMask, Remix no puede enviar el contrato a Sepolia porque necesita una wallet que autorice y pague el gas de prueba.

## 5. Flujo general del despliegue

El flujo correcto es este:

1. Abrir Remix.
2. Cargar o pegar los contratos.
3. Compilar.
4. Conectar MetaMask.
5. Seleccionar la red Sepolia.
6. Desplegar `MedicalAccessNFT`.
7. Copiar la dirección del contrato NFT.
8. Desplegar `MediRecordRegistry` usando la dirección del NFT.
9. Copiar la dirección del Registry.
10. Guardar los ABI.
11. Documentar el despliegue.
12. Reutilizar esas direcciones en backend y frontend.

## 5.1 Qué significa la conexión "Browser Connection" en Remix

Cuando en Remix ves una opción parecida a:

```text
Sepolia Testnet - MetaMask
```

eso significa que Remix está detectando a MetaMask como proveedor de firma en el navegador.

No es una conexión a Remix como tal.

Es una conexión entre:

- el navegador,
- MetaMask,
- y Remix.

Remix usará MetaMask para firmar el despliegue y enviar la transacción a Sepolia.

### Qué debes hacer ahí

1. Abrir MetaMask en el navegador.
2. Seleccionar la cuenta que tiene Sepolia ETH.
3. Confirmar que MetaMask esté en la red Sepolia.
4. Volver a Remix y elegir el entorno inyectado por MetaMask si aparece.
5. Aceptar la conexión cuando MetaMask la solicite.

### Qué hace ese paso en realidad

Ese paso permite que Remix actúe como interfaz de despliegue, pero la firma real la hace MetaMask.

Sin ese permiso, Remix no puede enviar la transacción.

## 6. Paso a paso en Remix

### Paso 1. Abrir Remix

Entra a Remix desde el navegador.

Ahí vas a trabajar con los contratos Solidity.

### Paso 2. Cargar los archivos

Debes tener visibles al menos:

- `MedicalAccessNFT.sol`
- `MediRecordRegistry.sol`
- `IMedicalAccessNFT.sol`

### Paso 3. Compilar

Compila con Solidity 0.8.20 o superior.

Debes verificar que no haya errores de compilación.

Si existe un error, no despliegues todavía.

### Paso 4. Conectar MetaMask

Remix necesita MetaMask para firmar el despliegue.

Cuando conectas MetaMask, Remix ya puede enviar la transacción a Sepolia.

### Cómo se hace exactamente

1. Abre la extensión de MetaMask en el navegador.
2. Selecciona la cuenta que usarás para desplegar.
3. Verifica que la red sea Sepolia.
4. Si Remix muestra un botón de conexión, autorízalo.
5. Si MetaMask pide permiso, acepta la conexión.
6. Confirma que Remix ya muestra la cuenta conectada.

### Qué debes ver cuando quedó bien

- La cuenta aparece visible en Remix.
- La red indica Sepolia.
- El contrato ya puede compilarse y desplegarse desde esa cuenta.

### Por qué este paso es importante

Remix por sí solo no firma transacciones.
MetaMask es quien firma y paga el gas de prueba con Sepolia ETH.

### Paso 5. Confirmar la red

Asegúrate de que MetaMask esté en Sepolia.

Si la red está incorrecta, el despliegue ocurrirá en otra red o fallará.

### Qué pasa si MetaMask está en otra red

Si MetaMask está, por ejemplo, en una red distinta a Sepolia, el deploy puede fallar o terminar en una red equivocada.

Por eso siempre debes revisar dos cosas:

- la red seleccionada en MetaMask,
- la red visible en Remix.

Ambas deben coincidir con Sepolia.

### Paso 6. Desplegar `MedicalAccessNFT`

Primero despliega el contrato NFT.

Esto es importante porque el Registry necesita conocer la dirección de este contrato.

Cuando se despliega, Remix ya no te pedirá una dirección de constructor para este contrato.

Eso permite publicar primero el NFT y luego enlazarlo con el Registry sin dependencia circular.

### Qué hace el despliegue del NFT

Este despliegue crea el contrato que representará las credenciales de acceso.

Aquí todavía no estás dando permisos a usuarios finales.

Solo estás publicando el contrato en Sepolia para que luego el Registry pueda usarlo.

### Paso 7. Guardar la dirección del NFT

Después del deploy, copia la dirección del contrato.

Ejemplo:

```text
0xA54f...12B
```

Esa dirección debe quedar guardada porque luego la usarán:

- el Registry,
- el backend,
- y eventualmente el frontend.

### Paso 8. Desplegar `MediRecordRegistry`

Despliega el Registry después.

Cuando el constructor lo solicite, pásale la dirección del contrato NFT.

Ese paso fija la relación entre ambos contratos.

### Paso 8.1 Vincular el NFT con el Registry

Después de desplegar el Registry, vuelve al contrato `MedicalAccessNFT` ya desplegado.

Luego llama a `updateRegistry(address newRegistry)` y pásale la dirección del `MediRecordRegistry` recién desplegado.

Ese paso deja al NFT apuntando al Registry correcto y permite que solo ese contrato pueda acuñar o revocar credenciales.

### Qué hace el despliegue del Registry

El Registry es el contrato principal.

Cuando lo despliegas, dejas publicada la lógica que manejará:

- usuarios,
- documentos,
- permisos,
- validación,
- y auditoría.

Por eso este contrato depende de la dirección del NFT que ya desplegaste antes.

### Paso 9. Guardar la dirección del Registry

Copia la dirección desplegada del Registry.

Esa será la dirección principal que usará el frontend y el backend para consultar permisos y validar accesos.

## 7. Qué debes guardar después del despliegue

Después de desplegar necesitas guardar dos cosas por cada contrato:

### 7.1 Dirección del contrato

Ejemplo:

```text
MedicalAccessNFT: 0x...
MediRecordRegistry: 0x...
```

### 7.2 ABI del contrato

El ABI es la interfaz que permite a ethers.js saber cómo llamar al contrato.

Debes guardarlo en el frontend y también en el backend.

## 8. Dónde guardar esa información

Una estructura simple y práctica sería esta:

```text
frontend/
  src/
    contracts/
      MedicalAccessNFTABI.json
      MediRecordRegistryABI.json
      addresses.js

backend/
  src/
    contracts/
      MedicalAccessNFTABI.json
      MediRecordRegistryABI.json
      addresses.js
```

## 9. Para qué sirve guardar la dirección y el ABI

Sin la dirección, ethers.js no sabe a qué contrato conectarse.

Sin el ABI, ethers.js no sabe qué funciones existen ni cómo llamar a cada una.

Por eso ambas cosas son obligatorias para el frontend y el backend.

## 10. Para qué sirve MetaMask en el proyecto

MetaMask sirve para firmar transacciones desde el lado del usuario.

Se usa principalmente cuando:

- el paciente registra un documento,
- el paciente emite un permiso,
- el paciente revoca un permiso,
- o el administrador ejecuta una función que cambia estado.

MetaMask no se usa para leer datos únicamente.

Para leer, el frontend o el backend pueden usar ethers.js con provider.

## 11. Qué hace el frontend después del despliegue

El frontend ya no habla con Remix.

Habla directamente con Sepolia usando ethers.js.

Su tarea será:

- conectar MetaMask,
- verificar la red,
- consultar el rol,
- mostrar el dashboard correcto,
- llamar al contrato cuando haya una acción de escritura,
- y consultar datos del contrato cuando solo necesite lectura.

## 12. Qué hace el backend después del despliegue

El backend tendrá dos tareas principales:

- guardar PDFs y metadata real,
- consultar el contrato antes de entregar un documento.

Por ejemplo:

- si el paciente sube un PDF, el backend lo guarda,
- si alguien intenta acceder, el backend vuelve a verificar el permiso en el Registry,
- si el permiso es válido, entrega el archivo,
- si no es válido, niega el acceso.

## 13. Flujo de despliegue para MediRecord

### Flujo resumido

1. Compilas en Remix.
2. Conectas MetaMask.
3. Tienes Sepolia ETH de prueba.
4. Despliegas `MedicalAccessNFT`.
5. Copias la dirección.
6. Despliegas `MediRecordRegistry` usando la dirección del NFT.
7. Copias la dirección del Registry.
8. Guardas ambos ABI.
9. Documentas el deploy.
10. Conectas frontend y backend con ethers.js.

### Flujo explicado sin saltos

1. **Preparar MetaMask**: instalas la extensión, eliges cuenta y verificas Sepolia.
2. **Abrir Remix**: usas Remix solo como entorno de desarrollo y despliegue.
3. **Compilar**: aseguras que los contratos no tengan errores.
4. **Conectar Remix con MetaMask**: autorizas al navegador para usar tu wallet.
5. **Desplegar MedicalAccessNFT**: publicas primero el contrato de credenciales.
6. **Guardar la dirección del NFT**: esa dirección se usará después como referencia.
7. **Desplegar MediRecordRegistry**: publicas el contrato principal pasando la dirección del NFT.
8. **Guardar la dirección del Registry**: esa será la dirección que consuman frontend y backend.
9. **Guardar ABI y documentar**: exportas la interfaz de ambos contratos.
10. **Integrar frontend/backend**: React y Node.js se conectan por ethers.js a Sepolia.

## 14. Qué revisar antes de considerar listo el deploy

Antes de dar por cerrado el despliegue revisa:

- que la red sea Sepolia,
- que la dirección del NFT esté correcta,
- que el Registry apunte al NFT correcto,
- que el ABI exportado corresponda a la versión final del contrato,
- que MetaMask tenga saldo de prueba,
- y que no existan errores de compilación.

## 15. Cómo se relaciona esto con las vistas del frontend

Las vistas que definiste dependen de este deploy.

El frontend usará la dirección y el ABI del Registry para:

- consultar roles,
- mostrar dashboards,
- emitir permisos,
- revocar permisos,
- y validar accesos.

Sin el contrato desplegado no hay conexión real con Sepolia.

## 16. Recomendación importante

No cambies el contrato después de empezar a desarrollar frontend y backend, salvo que realmente encuentres un error de diseño.

Si cambias la lógica del contrato luego, tendrás que volver a revisar:

- ABI,
- direcciones,
- funciones disponibles,
- y posiblemente la UI.

Por eso conviene desplegar solo cuando ya estés seguro de la versión final.

## 17. Resumen final

Remix se usa solo para compilar y desplegar.

MetaMask se usa para firmar despliegues y transacciones.

Sepolia ETH se usa para pagar gas de prueba.

El frontend y el backend usan ethers.js para hablar con los contratos ya desplegados.

Lo que debes guardar siempre es:

- la dirección de cada contrato,
- el ABI de cada contrato,
- y una nota de qué versión quedó desplegada.

Con eso ya puedes continuar con backend y frontend sin depender de Remix otra vez.

## 18. Respuesta corta a tu duda sobre MetaMask

MetaMask se usa porque necesitas una wallet que firme la transacción de despliegue y después las transacciones de escritura.

En MediRecord, MetaMask no sirve para guardar documentos ni para hablar con el backend.

Sirve para esto:

- desplegar contratos en Sepolia,
- emitir permisos,
- revocar permisos,
- y ejecutar acciones que cambian el estado en blockchain.

Si no conectas MetaMask en Remix, no podrás desplegar correctamente los contratos en la red de prueba.
