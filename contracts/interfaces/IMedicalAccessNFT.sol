// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IMedicalAccessNFT
/// @notice Interfaz minima del NFT de credencial intransferible usado por MediRecordRegistry.
/// @dev Esta interfaz existe para desacoplar el Registry del contrato concreto del NFT y facilitar la validacion de accesos sin duplicar logica.
interface IMedicalAccessNFT {
    /// @notice Acuna una nueva credencial NFT.
    /// @param beneficiary Wallet que recibe la credencial.
    /// @param documentRef Referencia opaca asociada a la credencial.
    /// @param expiresAt Timestamp de expiracion de la credencial.
    /// @return tokenId Identificador del token creado.
    /// @dev El Registry invoca esta funcion para materializar la autorizacion de negocio como credencial ERC721.
    function mintCredential(address beneficiary, bytes32 documentRef, uint64 expiresAt) external returns (uint256 tokenId);

    /// @notice Revoca una credencial NFT existente.
    /// @param tokenId Identificador del token a revocar.
    /// @dev El Registry la usa cuando el permiso de negocio deja de ser valido.
    function revokeCredential(uint256 tokenId) external;

    /// @notice Verifica si una credencial sigue activa.
    /// @param tokenId Identificador del token a inspeccionar.
    /// @return active True cuando la credencial permanece activa.
    /// @dev El Registry la consulta para evitar inconsistencias entre el permiso tecnico y la credencial on-chain.
    function isCredentialActive(uint256 tokenId) external view returns (bool active);
}