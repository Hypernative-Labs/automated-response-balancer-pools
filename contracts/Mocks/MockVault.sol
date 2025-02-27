// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "hardhat/console.sol";

/// @title MockVault
/// @dev A mock vault logic immitation
contract MockVault {
    enum PoolSpecialization {
        GENERAL,
        MINIMAL_SWAP_INFO,
        TWO_TOKEN
    }

    /// @notice Pool registry hashmap
    mapping(bytes32 => bool) public _isPoolRegistered;
    /// @dev Nonces counter
    uint256 private _nextPoolNonce;

    /**
     * @dev Reverts unless `poolId` corresponds to a registered Pool.
     * @param poolId a unique Balancer pool identifier
     */
    modifier withRegisteredPool(bytes32 poolId) {
        _ensureRegisteredPool(poolId);
        _;
    }

    /**
     * @dev Reverts unless `poolId` corresponds to a registered Pool.
     * @param poolId a unique Balancer pool identifier
     */
    function _ensureRegisteredPool(bytes32 poolId) internal view {
        require(_isPoolRegistered[poolId], "INVALID_POOL_ID");
    }

    /**
     * @notice Fetches a pool address by ID
     * @param poolId a unique Balancer pool identifier
     */
    function getPool(
        bytes32 poolId
    )
        external
        view
        withRegisteredPool(poolId)
        returns (address, PoolSpecialization)
    {
        return (_getPoolAddress(poolId), _getPoolSpecialization(poolId));
    }

    function registerPool(
        address pool,
        PoolSpecialization specialization
    ) external returns (bytes32) {
        bytes32 poolId = _toPoolId(
            pool,
            specialization,
            uint80(_nextPoolNonce)
        );
        console.log("ONCHAIN registrating poolId", uint256(poolId));
        _nextPoolNonce += 1;
        console.log("ONCHAIN: registrating poolAddress", pool);
        _isPoolRegistered[poolId] = true;
        return poolId;
    }

    /**
     * @dev Returns the address of a Pool's contract.
     * @param poolId a unique Balancer pool identifier
     *
     * Due to how Pool IDs are created, this is done with no storage accesses and costs little gas.
     */
    function _getPoolAddress(bytes32 poolId) internal pure returns (address) {
        // 12 byte logical shift left to remove the nonce and specialization setting. We don't need to mask,
        // since the logical shift already sets the upper bits to zero.
        //console.log("poolId", address(uint160(uint256(poolId)) >> (12 * 8)));
        return address(uint160(uint256(poolId) >> (12 * 8)));
    }

    /**
     * @dev Returns the specialization setting of a Pool.
     * @param poolId a unique Balancer pool identifier
     *
     * Due to how Pool IDs are created, this is done with no storage accesses and costs little gas.
     */
    function _getPoolSpecialization(
        bytes32 poolId
    ) internal pure returns (PoolSpecialization specialization) {
        // 10 byte logical shift left to remove the nonce, followed by a 2 byte mask to remove the address.
        uint256 value = uint256(poolId >> (10 * 8)) & (2 ** (2 * 8) - 1);

        // Casting a value into an enum results in a runtime check that reverts unless the value is within the enum's
        // range. Passing an invalid Pool ID to this function would then result in an obscure revert with no reason
        // string: we instead perform the check ourselves to help in error diagnosis.

        // There are three Pool specialization settings: general, minimal swap info and two tokens, which correspond to
        // values 0, 1 and 2.
        require(value < 3, "INVALID_SPECIALIZATION");

        // Because we have checked that `value` is within the enum range, we can use assembly to skip the runtime check.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            specialization := value
        }
    }

    /**
     * @notice Converts a pool address to a pool identifier
     * @param pool the address of the pool
     * @param specialization a pool speciality
     * @param nonce a number used once as salt
     */
    function _toPoolId(
        address pool,
        PoolSpecialization specialization,
        uint80 nonce
    ) public pure returns (bytes32) {
        bytes32 serialized;

        serialized |= bytes32(uint256(nonce));
        serialized |= bytes32(uint256(specialization)) << (10 * 8);
        serialized |= bytes32(uint256(uint160(pool))) << (12 * 8);

        return serialized;
    }
}
