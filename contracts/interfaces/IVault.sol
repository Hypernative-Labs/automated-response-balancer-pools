// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IVault {
    enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }
    
    /**
     * @dev Returns a Pool's contract address and specialization setting.
     * @param poolId a Balancer pool unique identifier
     * @return address of the pool
     * @return PoolSpecialization ∈ {GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN}
     */
    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);
}