// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title MedicalAccessNFT
/// @notice Credencial ERC721 intransferible usada solo para representar acceso temporal a un documento medico.
/// @dev El contrato no almacena contenido medico. Solo conserva metadatos tecnicos de la credencial.
/// @dev Su unica responsabilidad es reflejar en cadena una autorizacion ya decidida por MediRecordRegistry.
contract MedicalAccessNFT is ERC721, Ownable {
    /// @notice Datos tecnicos de una credencial almacenada en cadena.
    /// @dev La estructura no representa documentos ni pacientes; solo la autorizacion tecnica.
    /// @dev Mantiene el minimo estado necesario para que el NFT represente una credencial y no un activo transferible.
    struct CredencialAcceso {
        /// @notice Wallet que recibio la credencial.
        address beneficiario;
        /// @notice Referencia opaca del documento autorizado.
        bytes32 referenciaDocumento;
        /// @notice Timestamp en que se emitio la credencial.
        uint64 emitidoEn;
        /// @notice Timestamp en que expira la credencial.
        uint64 expiraEn;
        /// @notice Timestamp en que se revoco la credencial.
        uint64 revocadoEn;
        /// @notice Indica si la credencial sigue activa.
        bool activa;
        /// @notice Indica si la credencial fue revocada.
        bool revocada;
    }

    /// @notice Se revierte cuando el llamador no es el registry configurado.
    error NotRegistry();

    /// @notice Se revierte cuando se recibe una direccion cero donde no esta permitida.
    error ZeroAddressNotAllowed();

    /// @notice Se revierte cuando una credencial no existe.
    /// @param tokenId Token identifier that was not found.
    error CredentialDoesNotExist(uint256 tokenId);

    /// @notice Se revierte cuando una credencial ya fue revocada.
    /// @param tokenId Token identifier that was already revoked.
    error CredentialAlreadyRevoked(uint256 tokenId);

    /// @notice Se revierte cuando el tiempo de expiracion proporcionado es invalido.
    error InvalidExpiration();

    /// @notice Se revierte cuando un nuevo registry es igual al actual.
    error RegistryAlreadySet();

    /// @notice Se revierte cuando se usa cualquier ruta de transferencia.
    error TransfersDisabled();

    /// @notice Se revierte cuando se usa cualquier ruta de aprobacion.
    error ApprovalsDisabled();

    /// @notice Emitted when the registry address changes.
    /// @param previousRegistry Previous registry address.
    /// @param newRegistry New registry address.
    event RegistroActualizado(address indexed previousRegistry, address indexed newRegistry);

    /// @notice Emitted when a new credential is minted.
    /// @param tokenId Token identifier assigned to the credential.
    /// @param beneficiary Address that received the credential.
    /// @param documentRef Opaque document reference associated with the credential.
    /// @param expiresAt Credential expiration timestamp.
    event CredencialEmitida(uint256 indexed tokenId, address indexed beneficiary, bytes32 indexed documentRef, uint64 expiresAt);

    /// @notice Emitted when a credential is revoked.
    /// @param tokenId Token identifier that was revoked.
    /// @param revokedBy Address that executed the revocation.
    /// @param revokedAt Timestamp when the revocation happened.
    event CredencialRevocada(uint256 indexed tokenId, address indexed revokedBy, uint64 revokedAt);

    /// @dev Registry autorizado actualmente.
    /// @dev Debe permanecer como referencia unica para evitar que una credencial cambie de autoridad de emision.
    address private _registro;

    /// @dev Siguiente identificador de token a acuñar.
    /// @dev La numeracion vive aqui porque MedicalAccessNFT es el unico contrato que crea NFTs.
    uint256 private _siguienteTokenId = 1;

    /// @dev Almacenamiento en cadena de las credenciales.
    /// @dev Solo contiene el estado minimo para consultas de existencia y vigencia.
    mapping(uint256 => CredencialAcceso) private _credenciales;

    /// @notice Crea la coleccion de credenciales NFT.
    /// @dev El Registry se asigna despues del despliegue para evitar una dependencia circular al momento de publicar los contratos.
    constructor() ERC721("MedicalAccessNFT", "MANT") Ownable(msg.sender) {
    }

    /// @notice Restringe una funcion al registry actual.
    /// @dev Bloquea cualquier intento de emision o revocacion desde wallets no autorizadas.
    modifier soloRegistro() {
        if (msg.sender != _registro) {
            revert NotRegistry();
        }

        _;
    }

    /// @notice Acuna una nueva credencial de acceso.
    /// @param beneficiary Wallet que recibe la credencial.
    /// @param documentRef Referencia opaca del documento autorizado.
    /// @param expiresAt Timestamp de expiracion de la credencial.
    /// @return tokenId Identificador del token creado.
    /// @dev Solo puede ejecutarla el Registry. Valida beneficiario y expiracion para impedir credenciales inutiles o mal formadas.
    function mintCredential(address beneficiary, bytes32 documentRef, uint64 expiresAt) external soloRegistro returns (uint256 tokenId) {
        if (beneficiary == address(0)) {
            revert ZeroAddressNotAllowed();
        }

        if (expiresAt <= uint64(block.timestamp)) {
            revert InvalidExpiration();
        }

        tokenId = _siguienteTokenId;
        _siguienteTokenId = tokenId + 1;

        _credenciales[tokenId] = CredencialAcceso({
            beneficiario: beneficiary,
            referenciaDocumento: documentRef,
            emitidoEn: uint64(block.timestamp),
            expiraEn: expiresAt,
            revocadoEn: 0,
            activa: true,
            revocada: false
        });

        _safeMint(beneficiary, tokenId);

        emit CredencialEmitida(tokenId, beneficiary, documentRef, expiresAt);
    }

    /// @notice Revoca una credencial de acceso existente.
    /// @param tokenId Identificador del token a revocar.
    /// @dev Solo puede ejecutarla el Registry. Marca la credencial como inactiva sin transferirla ni borrarla.
    function revokeCredential(uint256 tokenId) external soloRegistro {
        CredencialAcceso storage credencial = _credencialORevertir(tokenId);

        if (credencial.revocada) {
            revert CredentialAlreadyRevoked(tokenId);
        }

        credencial.activa = false;
        credencial.revocada = true;
        credencial.revocadoEn = uint64(block.timestamp);

        emit CredencialRevocada(tokenId, msg.sender, credencial.revocadoEn);
    }

    /// @notice Verifica si una credencial existe.
    /// @param tokenId Identificador del token a inspeccionar.
    /// @return exists True cuando la credencial fue acuñada.
    /// @dev Permite al Registry validar que la credencial corresponde a un NFT real antes de autorizar acceso.
    function credentialExists(uint256 tokenId) public view returns (bool exists) {
        exists = _credenciales[tokenId].emitidoEn != 0;
    }

    /// @notice Devuelve una credencial por identificador de token.
    /// @param tokenId Identificador del token a inspeccionar.
    /// @return credential Datos tecnicos de la credencial.
    /// @dev Se usa para inspeccion y auditoria tecnica; no expone informacion medica.
    function getCredential(uint256 tokenId) external view returns (CredencialAcceso memory credential) {
        credential = _credencialORevertir(tokenId);
    }

    /// @notice Verifica si una credencial puede usarse en este momento.
    /// @param tokenId Identificador del token a inspeccionar.
    /// @return active True cuando la credencial existe, no fue revocada y no expiro.
    /// @dev El Registry la consulta para evitar confiar solo en su estado local y mantener consistencia con la credencial NFT.
    function isCredentialActive(uint256 tokenId) public view returns (bool active) {
        CredencialAcceso storage credencial = _credenciales[tokenId];

        if (credencial.emitidoEn == 0) {
            return false;
        }

        active = credencial.activa && !credencial.revocada && credencial.expiraEn >= uint64(block.timestamp);
    }

    /// @notice Devuelve el owner inmutable de la credencial.
    /// @param tokenId Identificador del token a inspeccionar.
    /// @return owner Address que posee la credencial.
    /// @dev Expone la propiedad ERC721, que en este proyecto representa una credencial y no un activo transferible.
    function ownerOfCredential(uint256 tokenId) external view returns (address owner) {
        owner = ownerOf(tokenId);
    }

    /// @notice Actualiza el registry autorizado para acuñar y revocar credenciales.
    /// @param newRegistry Address del nuevo registry.
    /// @dev Esta funcion existe en el codigo actual, pero su presencia debe revisarse frente al objetivo de dependencia immutable del proyecto.
    function updateRegistry(address newRegistry) external onlyOwner {
        if (newRegistry == address(0)) {
            revert ZeroAddressNotAllowed();
        }

        if (newRegistry == _registro) {
            revert RegistryAlreadySet();
        }

        address previousRegistry = _registro;
        _registro = newRegistry;

        emit RegistroActualizado(previousRegistry, newRegistry);
    }

    /// @notice Bloquea todas las transferencias directas.
    /// @dev El NFT es una credencial y no un activo comercial; cualquier transferencia alteraria el modelo de autorizacion.
    function transferFrom(address, address, uint256) public pure override {
        revert TransfersDisabled();
    }

    /// @notice Bloquea todas las transferencias seguras con datos adicionales.
    /// @dev Cubre la sobrecarga con datos extra para cerrar por completo la superficie de transferencia.
    function safeTransferFrom(address, address, uint256, bytes memory) public pure override {
        revert TransfersDisabled();
    }

    /// @notice Bloquea todas las operaciones de aprobacion.
    /// @dev Las aprobaciones no tienen sentido en una credencial intransferible y solo abririan una superficie innecesaria.
    function approve(address, uint256) public pure override {
        revert ApprovalsDisabled();
    }

    /// @notice Bloquea todas las aprobaciones de operador.
    /// @dev Impide delegar control sobre una credencial que, por diseño, no debe moverse ni compartirse por medio del estandar.
    function setApprovalForAll(address, bool) public pure override {
        revert ApprovalsDisabled();
    }

    /// @dev Resuelve una credencial o revierte si no existe.
    /// @param tokenId Identificador del token a inspeccionar.
    /// @return credential Datos almacenados de la credencial.
    /// @dev Centraliza la verificacion de existencia para no repetir la misma validacion en varias funciones publicas.
    function _credencialORevertir(uint256 tokenId) private view returns (CredencialAcceso storage credential) {
        credential = _credenciales[tokenId];

        if (credential.emitidoEn == 0) {
            revert CredentialDoesNotExist(tokenId);
        }
    }
}