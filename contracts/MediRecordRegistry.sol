// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IMedicalAccessNFT} from "./interfaces/IMedicalAccessNFT.sol";

/// @title MediRecordRegistry
/// @notice Registry principal de MediRecord. Guarda usuarios, documentos tecnicos, permisos y auditoria mediante eventos.
/// @dev Este contrato concentra la logica de negocio. MedicalAccessNFT solo conserva la credencial ERC721 intransferible.
/// @dev En el flujo del sistema, este contrato decide quien puede compartir un documento, quien puede recibir acceso y durante cuanto tiempo.
contract MediRecordRegistry is Ownable {
    /// @notice Roles tecnicos soportados por el sistema.
    /// @dev Se usan para representar actores del dominio sin introducir reglas clinicas complejas ni estados extra.
    enum Rol {
        NONE,
        ADMIN,
        PATIENT,
        DOCTOR,
        CLINIC,
        INSURANCE
    }

    /// @notice Registro minimo de un usuario.
    /// @dev Solo guarda el rol tecnico y si la wallet esta registrada.
    /// @dev Evita almacenar datos personales y mantiene la identidad del sistema en el plano estrictamente tecnico.
    struct Usuario {
        /// @notice Rol asignado a la wallet.
        Rol rol;
        /// @notice Indica si la wallet esta registrada.
        bool registrado;
    }

    /// @notice Registro tecnico de un documento.
    /// @dev No almacena PDFs, nombres ni datos medicos; solo metadatos tecnicos.
    /// @dev El backend conserva el archivo real y este contrato solo conserva la referencia de integridad y propiedad.
    struct Documento {
        /// @notice Identificador tecnico del documento.
        bytes32 idDocumento;
        /// @notice Hash del documento almacenado en el backend.
        bytes32 hashDocumento;
        /// @notice Wallet que posee el documento.
        address owner;
    }

    /// @notice Permiso tecnico para una wallet sobre un documento especifico.
    /// @dev El permiso solo modela autorizacion; la credencial visual es el NFT.
    /// @dev Este registro es la fuente de verdad del acceso logico, mientras que el NFT materializa esa autorizacion en cadena.
    struct Permiso {
        /// @notice Identificador unico del permiso.
        bytes32 idPermiso;
        /// @notice Token NFT emitido por MedicalAccessNFT.
        uint256 tokenId;
        /// @notice Identificador tecnico del documento.
        bytes32 idDocumento;
        /// @notice Hash tecnico del documento.
        bytes32 hashDocumento;
        /// @notice Wallet del paciente propietario del documento.
        address patient;
        /// @notice Wallet autorizada para acceder al documento.
        address autorizado;
        /// @notice Timestamp de emision del permiso.
        uint64 issuedAt;
        /// @notice Timestamp de expiracion del permiso.
        uint64 expiresAt;
        /// @notice Indica si el permiso fue revocado.
        bool revoked;
    }

    /// @notice Se revierte cuando se recibe una direccion cero donde no esta permitida.
    error ZeroAddressNotAllowed();

    /// @notice Se revierte cuando el rol solicitado no es valido para la operacion.
    error InvalidRole();

    /// @notice Se revierte cuando una wallet no esta registrada.
    error UserNotRegistered();

    /// @notice Se revierte cuando una wallet ya estaba registrada.
    error UserAlreadyRegistered();

    /// @notice Se revierte cuando el llamador no es el owner.
    error NotOwner();

    /// @notice Se revierte cuando el llamador no es un paciente.
    error NotPatient();

    /// @notice Se revierte cuando el identificador tecnico del documento es invalido.
    error InvalidDocumentId();

    /// @notice Se revierte cuando el hash tecnico del documento es invalido.
    error InvalidDocumentHash();

    /// @notice Se revierte cuando un documento ya existe.
    error DocumentAlreadyRegistered();

    /// @notice Se revierte cuando un documento no existe.
    error DocumentNotRegistered();

    /// @notice Thrown when a permission already exists for the same document and wallet.
    error PermissionAlreadyExists();

    /// @notice Thrown when a permission does not exist.
    error PermissionNotFound();

    /// @notice Thrown when a permission was already revoked.
    error PermissionAlreadyRevoked();

    /// @notice Thrown when the requested expiration time is invalid.
    error InvalidExpiration();

    /// @notice Thrown when a wallet is not eligible to receive a permission.
    error InvalidAuthorizationTarget();

    /// @notice Thrown when the NFT call cannot be completed.
    error NFTCallFailed();

    /// @notice Se emite cuando una wallet queda registrada.
    event UsuarioRegistrado(address indexed usuario, Rol rol);

    /// @notice Se emite cuando cambia el rol de una wallet.
    event RolUsuarioActualizado(address indexed usuario, Rol rolAnterior, Rol rolNuevo);

    /// @notice Se emite cuando se registra un documento tecnico.
    event DocumentoRegistrado(bytes32 indexed idDocumento, bytes32 indexed hashDocumento, address indexed owner);

    /// @notice Se emite cuando se emite un permiso.
    event PermisoEmitido(bytes32 indexed idPermiso, uint256 indexed tokenId, bytes32 indexed idDocumento, address autorizado, uint64 expiresAt);

    /// @notice Se emite cuando se revoca un permiso.
    event PermisoRevocado(bytes32 indexed idPermiso, uint256 indexed tokenId, address indexed revocadoPor);

    /// @notice Se emite cuando se intenta validar un acceso.
    event IntentoValidacionAcceso(bytes32 indexed idDocumento, address indexed solicitante, uint256 timestamp, bool concedido);

    /// @dev Dependencia fija de MedicalAccessNFT.
    /// @dev El Registry no conoce la implementacion concreta, solo el contrato necesario para acuñar y revocar credenciales.
    IMedicalAccessNFT private immutable nftAccesoMedico;

    /// @dev Usuarios registrados.
    /// @dev Mantiene el estado de identidad tecnica del sistema sin almacenar informacion personal.
    mapping(address => Usuario) private usuarios;

    /// @dev Documentos tecnicos.
    /// @dev Relaciona la huella tecnica del documento con su propietario en cadena.
    mapping(bytes32 => Documento) private documentos;

    /// @dev Permisos indexados por identificador tecnico.
    /// @dev Es la fuente de verdad del acceso logico antes de consultar la credencial NFT.
    mapping(bytes32 => Permiso) private permisos;

    /// @dev Relacion permiso por documento y wallet autorizada.
    /// @dev Evita duplicar permisos activos para la misma combinacion de documento y wallet.
    mapping(bytes32 => mapping(address => bytes32)) private permisoPorDocumentoYAutorizado;

    /// @dev Relacion permiso por token NFT.
    /// @dev Permite reconstruir la trazabilidad entre la credencial ERC721 y la autorizacion de negocio.
    mapping(uint256 => bytes32) private permisoPorTokenId;

    /// @dev Crea el registry y fija la dependencia NFT de forma permanente.
    /// @param medicalAccessNFTAddress Address del contrato MedicalAccessNFT ya desplegado.
    constructor(address medicalAccessNFTAddress) Ownable(msg.sender) {
        if (medicalAccessNFTAddress == address(0)) {
            revert ZeroAddressNotAllowed();
        }

        nftAccesoMedico = IMedicalAccessNFT(medicalAccessNFTAddress);
        usuarios[msg.sender] = Usuario({rol: Rol.ADMIN, registrado: true});

        emit UsuarioRegistrado(msg.sender, Rol.ADMIN);
    }

    /// @notice Restringe una funcion al owner del contrato.
    /// @dev Se usa para operaciones de administracion tecnica del sistema y no para logica clinica.
    modifier soloOwner() {
        if (msg.sender != owner()) {
            revert NotOwner();
        }

        _;
    }

    /// @notice Restringe una funcion a un paciente registrado.
    /// @dev Evita que wallets sin rol de paciente registren documentos propios y rompan el modelo de propiedad.
    modifier soloPaciente() {
        if (!_esPaciente(msg.sender)) {
            revert NotPatient();
        }

        _;
    }

    /// @notice Restringe una funcion a un documento existente.
    /// @dev Protege rutas que dependen de un documento previamente registrado para evitar permisos colgados.
    modifier documentoExiste(bytes32 idDocumento) {
        if (!_existeDocumento(idDocumento)) {
            revert DocumentNotRegistered();
        }

        _;
    }

    /// @notice Restringe una funcion a un permiso existente.
    /// @dev Asegura que la revocacion o consulta solo opere sobre registros validos.
    modifier permisoExiste(bytes32 idPermiso) {
        if (!_existePermiso(idPermiso)) {
            revert PermissionNotFound();
        }

        _;
    }

    /// @notice Restringe una funcion al propietario del documento registrado.
    /// @dev Evita que un tercero emita permisos sobre documentos ajenos.
    modifier documentoPropioDelLlamador(bytes32 idDocumento) {
        if (!_existeDocumento(idDocumento) || documentos[idDocumento].owner != msg.sender) {
            revert InvalidAuthorizationTarget();
        }

        _;
    }

    /// @notice Restringe una funcion al paciente que posee el permiso registrado.
    /// @dev Evita revocaciones por cuentas que no son el dueño logico del documento.
    modifier permisoPropioDelLlamador(bytes32 idPermiso) {
        if (!_existePermiso(idPermiso) || permisos[idPermiso].patient != msg.sender) {
            revert InvalidAuthorizationTarget();
        }

        _;
    }

    /// @notice Registra una wallet con un rol tecnico.
    /// @param user Wallet que se registra.
    /// @param role Rol tecnico a asignar.
    /// @dev Solo puede ejecutarla el owner. Modifica el mapeo de usuarios y establece la identidad tecnica de la wallet.
    function registerUser(address user, Rol role) external soloOwner {
        _registrarUsuario(user, role);
    }

    /// @notice Actualiza el rol de una wallet ya registrada.
    /// @param user Wallet a actualizar.
    /// @param role Nuevo rol tecnico.
    /// @dev Solo puede ejecutarla el owner. Modifica el registro de usuarios sin introducir estados intermedios ni historiales adicionales.
    function updateUserRole(address user, Rol role) external soloOwner {
        _actualizarRolUsuario(user, role);
    }

    /// @notice Registra un documento tecnico del sistema.
    /// @param documentId Identificador tecnico del documento.
    /// @param documentHash Hash del documento almacenado en el backend.
    /// @dev Solo puede ejecutarla un paciente registrado. Solo almacena la relacion tecnica documento-propietario, sin tocar PDFs ni datos clinicos.
    function registerDocument(bytes32 documentId, bytes32 documentHash) external soloPaciente {
        _registrarDocumentoTecnico(documentId, documentHash);
    }

    /// @notice Emite un permiso sobre un documento tecnico para una wallet autorizada.
    /// @param documentId Identificador tecnico del documento.
    /// @param authorized Wallet autorizada para acceder al documento.
    /// @param expiresAt Timestamp de expiracion del permiso.
    /// @return permissionId Identificador tecnico del permiso creado.
    /// @return tokenId Token NFT emitido por MedicalAccessNFT.
    /// @dev Solo puede ejecutarla el paciente propietario del documento. Valida registro, propiedad, expiracion y duplicidad antes de crear la credencial.
    function issuePermission(bytes32 documentId, address authorized, uint64 expiresAt)
        external
        soloPaciente
        documentoExiste(documentId)
        documentoPropioDelLlamador(documentId)
        returns (bytes32 permissionId, uint256 tokenId)
    {
        permissionId = _emitirPermiso(documentId, authorized, expiresAt);
        tokenId = permisos[permissionId].tokenId;
    }

    /// @notice Revoca un permiso ya emitido.
    /// @param permissionId Identificador tecnico del permiso.
    /// @dev Solo puede ejecutarla el paciente propietario del documento asociado. Retira el acceso logico y sincroniza la credencial NFT.
    function revokePermission(bytes32 permissionId) external permisoExiste(permissionId) permisoPropioDelLlamador(permissionId) {
        _revocarPermiso(permissionId);
    }

    /// @notice Valida si una wallet puede acceder a un documento y registra el intento por evento.
    /// @param requester Wallet que solicita acceso.
    /// @param documentId Identificador tecnico del documento.
    /// @return granted True cuando el acceso es concedido.
    /// @dev Puede ejecutarla el backend o el frontend. No modifica storage; solo consulta estado y emite auditoria para trazabilidad.
    function validateAccess(address requester, bytes32 documentId) external returns (bool granted) {
        granted = _tieneAcceso(requester, documentId);
        emit IntentoValidacionAcceso(documentId, requester, block.timestamp, granted);
    }

    /// @notice Consulta si una wallet puede acceder a un documento sin emitir eventos.
    /// @param requester Wallet que solicita acceso.
    /// @param documentId Identificador tecnico del documento.
    /// @return granted True cuando el acceso es concedido.
    /// @dev Se usa para lecturas puras desde el frontend o el backend cuando no se desea auditoria en logs.
    function hasAccess(address requester, bytes32 documentId) external view returns (bool granted) {
        granted = _tieneAcceso(requester, documentId);
    }

    /// @notice Obtiene el registro tecnico de una wallet.
    /// @param user Wallet a inspeccionar.
    /// @return record Registro de usuario almacenado.
    /// @dev Solo consulta el mapping de usuarios. No expone datos personales porque el sistema no los almacena.
    function getUser(address user) external view returns (Usuario memory record) {
        record = usuarios[user];
    }

    /// @notice Obtiene el documento tecnico registrado.
    /// @param documentId Identificador tecnico del documento.
    /// @return record Registro tecnico del documento.
    /// @dev Solo consulta el mapping de documentos. La integridad real del archivo permanece en el backend.
    function getDocument(bytes32 documentId) external view returns (Documento memory record) {
        record = documentos[documentId];
    }

    /// @notice Obtiene un permiso tecnico por su identificador.
    /// @param permissionId Identificador tecnico del permiso.
    /// @return record Registro tecnico del permiso.
    /// @dev Solo consulta el mapping de permisos. Es el puente entre la autorizacion de negocio y la credencial NFT.
    function getPermission(bytes32 permissionId) external view returns (Permiso memory record) {
        record = permisos[permissionId];
    }

    /// @notice Obtiene el identificador de permiso para un documento y una wallet autorizada.
    /// @param documentId Identificador tecnico del documento.
    /// @param authorized Wallet autorizada.
    /// @return permissionId Identificador tecnico almacenado, o cero si no existe.
    /// @dev Facilita la integracion del backend y del frontend con la credencial NFT asociada.
    function getPermissionByDocumentAndAuthorized(bytes32 documentId, address authorized) external view returns (bytes32 permissionId) {
        permissionId = permisoPorDocumentoYAutorizado[documentId][authorized];
    }

    /// @notice Obtiene el identificador de permiso asociado a un token NFT.
    /// @param tokenId Token NFT emitido por MedicalAccessNFT.
    /// @return permissionId Identificador tecnico almacenado, o cero si no existe.
    /// @dev Se usa para correlacionar el permiso de negocio con la credencial ERC721.
    function getPermissionByTokenId(uint256 tokenId) external view returns (bytes32 permissionId) {
        permissionId = permisoPorTokenId[tokenId];
    }

    /// @notice Verifica si existe un permiso tecnico.
    /// @param permissionId Identificador tecnico del permiso.
    /// @return exists True cuando el permiso esta almacenado.
    /// @dev Solo consulta el estado del mapping de permisos.
    function permissionExists(bytes32 permissionId) external view returns (bool exists) {
        exists = _existePermiso(permissionId);
    }

    /// @notice Verifica si existe un documento tecnico.
    /// @param documentId Identificador tecnico del documento.
    /// @return exists True cuando el documento esta almacenado.
    /// @dev Solo consulta el estado del mapping de documentos.
    function documentExists(bytes32 documentId) external view returns (bool exists) {
        exists = _existeDocumento(documentId);
    }

    /// @notice Registra una wallet internamente.
    /// @param user Wallet a registrar.
    /// @param role Rol tecnico a asignar.
    /// @dev Evita duplicados y mantiene el estado minimo del usuario. La separacion en funcion interna evita repetir la validacion desde varias rutas.
    function _registrarUsuario(address user, Rol role) private {
        if (user == address(0)) {
            revert ZeroAddressNotAllowed();
        }

        if (role == Rol.NONE) {
            revert InvalidRole();
        }

        if (usuarios[user].registrado) {
            revert UserAlreadyRegistered();
        }

        usuarios[user] = Usuario({rol: role, registrado: true});
        emit UsuarioRegistrado(user, role);
    }

    /// @notice Actualiza el rol tecnico de una wallet.
    /// @param user Wallet a actualizar.
    /// @param role Nuevo rol tecnico.
    /// @dev Se usa para corregir o modificar el perfil tecnico sin guardar estados adicionales.
    function _actualizarRolUsuario(address user, Rol role) private {
        if (user == address(0)) {
            revert ZeroAddressNotAllowed();
        }

        if (!_estaRegistrado(user)) {
            revert UserNotRegistered();
        }

        Rol rolAnterior = usuarios[user].rol;
        usuarios[user].rol = role;
        usuarios[user].registrado = role != Rol.NONE;

        emit RolUsuarioActualizado(user, rolAnterior, role);
    }

    /// @notice Registra tecnicamente un documento.
    /// @param documentId Identificador tecnico del documento.
    /// @param documentHash Hash del documento almacenado en el backend.
    /// @dev No crea permisos ni NFT; solo guarda la referencia tecnica del documento. La separacion evita mezclar almacenamiento documental con autorizacion.
    function _registrarDocumentoTecnico(bytes32 documentId, bytes32 documentHash) private {
        if (documentId == bytes32(0)) {
            revert InvalidDocumentId();
        }

        if (documentHash == bytes32(0)) {
            revert InvalidDocumentHash();
        }

        if (_existeDocumento(documentId)) {
            revert DocumentAlreadyRegistered();
        }

        documentos[documentId] = Documento({idDocumento: documentId, hashDocumento: documentHash, owner: msg.sender});
        emit DocumentoRegistrado(documentId, documentHash, msg.sender);
    }

    /// @notice Emite un permiso tecnico y lo sincroniza con el NFT.
    /// @param documentId Identificador tecnico del documento.
    /// @param authorized Wallet autorizada para acceder.
    /// @param expiresAt Timestamp de expiracion del permiso.
    /// @return permissionId Identificador tecnico del permiso creado.
    /// @dev Esta logica pertenece al Registry porque orquesta reglas de negocio, evita duplicados y mantiene la correlacion con la credencial ERC721.
    function _emitirPermiso(bytes32 documentId, address authorized, uint64 expiresAt)
        private
        returns (bytes32 permissionId)
    {
        Documento memory documento = documentos[documentId];

        if (authorized == address(0)) {
            revert ZeroAddressNotAllowed();
        }

        if (authorized == documento.owner) {
            revert InvalidAuthorizationTarget();
        }

        if (!_estaRegistrado(authorized)) {
            revert UserNotRegistered();
        }

        _validarExpiracion(expiresAt);
        _validarDestinoAutorizacion(documentId, authorized);

        permissionId = _construirIdPermiso(documentId, authorized);
        uint256 tokenId = _emitirCredencialNFT(authorized, documentId, expiresAt);

        permisos[permissionId] = Permiso({
            idPermiso: permissionId,
            tokenId: tokenId,
            idDocumento: documentId,
            hashDocumento: documento.hashDocumento,
            patient: documento.owner,
            autorizado: authorized,
            issuedAt: uint64(block.timestamp),
            expiresAt: expiresAt,
            revoked: false
        });

        permisoPorDocumentoYAutorizado[documentId][authorized] = permissionId;
        permisoPorTokenId[tokenId] = permissionId;

        emit PermisoEmitido(permissionId, tokenId, documentId, authorized, expiresAt);
    }

    /// @notice Revoca un permiso tecnico y sincroniza la credencial NFT.
    /// @param permissionId Identificador tecnico del permiso.
    /// @dev La revocacion vive en el Registry porque es una regla de negocio; el NFT solo refleja el estado final. Esto evita dividir la autoridad sobre el acceso entre dos contratos.
    function _revocarPermiso(bytes32 permissionId) private {
        Permiso storage permiso = permisos[permissionId];

        if (permiso.revoked) {
            revert PermissionAlreadyRevoked();
        }

        if (permiso.patient != msg.sender) {
            revert InvalidAuthorizationTarget();
        }

        permiso.revoked = true;
        _revocarCredencialNFT(permiso.tokenId);

        emit PermisoRevocado(permissionId, permiso.tokenId, msg.sender);
    }

    /// @notice Acuña la credencial NFT asociada a un permiso.
    /// @param beneficiary Wallet que recibe la credencial.
    /// @param documentId Identificador tecnico del documento.
    /// @param expiresAt Timestamp de expiracion del permiso.
    /// @return tokenId Token NFT creado por MedicalAccessNFT.
    /// @dev El Registry no genera tokenIds; solo solicita la acuñacion y guarda la relacion. Asi se evita duplicar la responsabilidad de numeracion.
    function _emitirCredencialNFT(address beneficiary, bytes32 documentId, uint64 expiresAt)
        private
        returns (uint256 tokenId)
    {
        tokenId = nftAccesoMedico.mintCredential(beneficiary, documentId, expiresAt);

        if (tokenId == 0) {
            revert NFTCallFailed();
        }
    }

    /// @notice Revoca la credencial NFT asociada a un permiso.
    /// @param tokenId Token NFT a revocar.
    /// @dev La logica real de credencial pertenece a MedicalAccessNFT; aqui solo se orquesta su estado para no duplicar reglas de revocacion.
    function _revocarCredencialNFT(uint256 tokenId) private {
        nftAccesoMedico.revokeCredential(tokenId);
    }

    /// @notice Construye un identificador tecnico de permiso.
    /// @param documentId Identificador tecnico del documento.
    /// @param authorized Wallet autorizada.
    /// @return permissionId Identificador tecnico del permiso.
    /// @dev Se usa para evitar ambiguedades en la correlacion documento-wallet y mantener trazabilidad estable en los eventos.
    function _construirIdPermiso(bytes32 documentId, address authorized) private view returns (bytes32 permissionId) {
        permissionId = keccak256(abi.encode(documentId, authorized, msg.sender, block.timestamp, block.prevrandao, address(this)));
    }

    /// @notice Valida si el destino de autorizacion puede reutilizarse.
    /// @param documentId Identificador tecnico del documento.
    /// @param authorized Wallet autorizada.
    /// @dev Evita duplicar permisos activos para la misma combinacion documento-wallet, lo que impediria saber cual credencial gobierna el acceso.
    function _validarDestinoAutorizacion(bytes32 documentId, address authorized) private view {
        bytes32 existingPermissionId = permisoPorDocumentoYAutorizado[documentId][authorized];

        if (existingPermissionId == bytes32(0)) {
            return;
        }

        Permiso storage existingPermission = permisos[existingPermissionId];

        if (!existingPermission.revoked && !_estaExpirado(existingPermission)) {
            revert PermissionAlreadyExists();
        }
    }

    /// @notice Valida la expiracion de un permiso.
    /// @param expiresAt Timestamp de expiracion.
    /// @dev Evita emitir permisos ya vencidos, lo que romperia la semantica de acceso temporal.
    function _validarExpiracion(uint64 expiresAt) private view {
        if (expiresAt <= uint64(block.timestamp)) {
            revert InvalidExpiration();
        }
    }

    /// @notice Evalua si una wallet tiene acceso a un documento.
    /// @param requester Wallet solicitante.
    /// @param documentId Identificador tecnico del documento.
    /// @return granted True cuando el acceso es permitido.
    /// @dev La comprobacion pertenece al Registry porque combina documento, usuario, permiso y credencial NFT. El NFT solo sabe si la credencial existe y sigue activa.
    function _tieneAcceso(address requester, bytes32 documentId) private view returns (bool granted) {
        if (!_existeDocumento(documentId) || !_estaRegistrado(requester)) {
            return false;
        }

        Documento storage documento = documentos[documentId];

        if (requester == documento.owner) {
            return true;
        }

        bytes32 permissionId = permisoPorDocumentoYAutorizado[documentId][requester];
        if (permissionId == bytes32(0)) {
            return false;
        }

        Permiso storage permiso = permisos[permissionId];
        if (permiso.revoked || _estaExpirado(permiso)) {
            return false;
        }

        if (permiso.autorizado != requester || permiso.patient != documento.owner) {
            return false;
        }

        if (documento.hashDocumento != permiso.hashDocumento) {
            return false;
        }

        granted = nftAccesoMedico.isCredentialActive(permiso.tokenId);
    }

    /// @notice Verifica si una wallet esta registrada.
    /// @param user Wallet a inspeccionar.
    /// @return registered True cuando la wallet esta registrada.
    function _estaRegistrado(address user) private view returns (bool registered) {
        registered = usuarios[user].registrado;
    }

    /// @notice Verifica si una wallet es un paciente registrado.
    /// @param user Wallet a inspeccionar.
    /// @return isPatient True cuando la wallet es paciente.
    function _esPaciente(address user) private view returns (bool isPatient) {
        Usuario storage record = usuarios[user];
        isPatient = record.registrado && record.rol == Rol.PATIENT;
    }

    /// @notice Verifica si un documento tecnico existe.
    /// @param documentId Identificador tecnico del documento.
    /// @return exists True cuando el documento esta almacenado.
    function _existeDocumento(bytes32 documentId) private view returns (bool exists) {
        exists = documentos[documentId].owner != address(0);
    }

    /// @notice Verifica si un permiso tecnico existe.
    /// @param permissionId Identificador tecnico del permiso.
    /// @return exists True cuando el permiso esta almacenado.
    function _existePermiso(bytes32 permissionId) private view returns (bool exists) {
        exists = permisos[permissionId].idPermiso != bytes32(0);
    }

    /// @notice Verifica si un permiso tecnico expiro.
    /// @param permission Permiso a inspeccionar.
    /// @return expired True cuando el permiso ya vencio.
    function _estaExpirado(Permiso storage permission) private view returns (bool expired) {
        expired = permission.expiresAt < uint64(block.timestamp);
    }
}