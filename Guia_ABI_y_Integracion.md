# Guía de ABIs y direcciones para MediRecord

## 1. Objetivo

Este archivo explica cómo guardar y usar los ABI y las direcciones de los contratos desplegados en Sepolia.

La idea es que tanto el frontend como el backend consuman exactamente los mismos datos, sin depender de Remix otra vez.

## 2. Archivos creados en la raíz del proyecto

En la raíz del proyecto se guardaron estos archivos:

- `MedicalAccessNFTABI.json`
- `MediRecordRegistryABI.json`
- `contract-addresses.js`

Estos archivos funcionan como la base de integración para backend y frontend.

## 3. Qué contiene cada archivo

### 3.1 MedicalAccessNFTABI.json

Contiene la interfaz JSON del contrato `MedicalAccessNFT`.

Sirve para que ethers.js sepa:

- qué funciones existen,
- qué eventos emite,
- qué errores puede devolver,
- y cómo llamar al contrato.

### 3.2 MediRecordRegistryABI.json

Contiene la interfaz JSON del contrato `MediRecordRegistry`.

Sirve para que ethers.js pueda interactuar con:

- registro de usuarios,
- documentos,
- permisos,
- validación de acceso,
- y eventos de auditoría.

### 3.3 contract-addresses.js

Contiene las direcciones desplegadas en Sepolia.

Sirve para no escribir la misma dirección en varios archivos y evitar errores manuales.

## 4. Direcciones actuales

### MedicalAccessNFT

- `0x5905C1ce26A000E0d5fAb425aCBfDDc1628eF89f`

### MediRecordRegistry

- `0x6c4BdF463CC6fA7b895002eb400fD7Eb0f8cdba7`

## 5. Cómo usar estos archivos en el frontend

En el frontend React puedes copiar estos archivos dentro de una carpeta como:

```text
frontend/
  src/
    contracts/
```

O importarlos directamente desde una estructura de configuración si decides centralizarlos.

### Recomendación práctica

En el frontend deberías tener algo así:

```text
frontend/
  src/
    contracts/
      MedicalAccessNFTABI.json
      MediRecordRegistryABI.json
      contract-addresses.js
```

Luego, con ethers.js:

- importas el ABI,
- tomas la dirección desde `contract-addresses.js`,
- y creas la instancia del contrato.

## 6. Cómo usar estos archivos en el backend

En el backend Node.js puedes crear una carpeta equivalente:

```text
backend/
  src/
    contracts/
      MedicalAccessNFTABI.json
      MediRecordRegistryABI.json
      contract-addresses.js
```

Con eso el backend puede:

- consultar `hasAccess()`,
- registrar validaciones con `validateAccess()` si hace falta,
- y leer eventos para auditoría.

## 7. Para qué sirve guardar ABI y dirección juntos

Los dos elementos son necesarios:

- la **dirección** dice dónde está desplegado el contrato,
- el **ABI** dice cómo hablar con él.

Si falta uno de los dos, ethers.js no puede trabajar correctamente.

## 8. Flujo de integración

### Frontend

1. El usuario abre la app.
2. Conecta MetaMask.
3. React carga la dirección del contrato.
4. React carga el ABI.
5. React crea una instancia de ethers.js.
6. El frontend consulta o envía transacciones al Registry.

### Backend

1. El backend arranca.
2. Carga la dirección y el ABI.
3. Crea un provider de Sepolia.
4. Lee permisos y estados desde el Registry.
5. Verifica el acceso antes de entregar un PDF.

## 9. Qué debes guardar como práctica

Además de estos archivos, conviene anotar:

- red usada: Sepolia,
- fecha del deploy,
- cuenta usada para desplegar,
- versión del contrato,
- y si la dirección corresponde a una prueba o a la versión final.

## 10. Paso a paso resumido para preparar frontend y backend

1. Copia los archivos ABI a la carpeta de contratos del frontend.
2. Copia los archivos ABI a la carpeta de contratos del backend.
3. Copia `contract-addresses.js` a ambos lados.
4. En frontend, usa MetaMask para firmar transacciones.
5. En backend, usa un provider RPC para lectura y validación.
6. Usa `MediRecordRegistry` como contrato principal.
7. Usa `MedicalAccessNFT` solo como credencial asociada.

## 11. Guías separadas por capa

Para no mezclar responsabilidades, la documentación se divide en dos archivos:

- [Guía de frontend](docs/Guia_Frontend_MediRecord.md)
- [Guía de backend](docs/Guia_Backend_MediRecord.md)

## 12. Qué hace cada contrato en integración

### MedicalAccessNFT

Representa la credencial digital intransferible.

### MediRecordRegistry

Controla usuarios, documentos, permisos y auditoría.

## 13. Recomendación final

No cambies estos archivos a mano en varios lugares.

Usa una sola fuente de verdad para:

- ABI,
- direcciones,
- y nombres de contrato.

Eso evita errores cuando empieces a construir frontend y backend.
