// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IPool} from "./interfaces/IPool.sol";
import {Enum} from "./GnosisSafeL2/common/Enum.sol";
import {GnosisSafe} from "./GnosisSafeL2/GnosisSafe.sol";
import {IVault} from "./interfaces/IVault.sol";

/// @title BalancerHelper
/// @dev On-chain logic for PAUSING one or multiple Balancer pools in one transaction
///
/// PUBLIC ENTITIES:
///
///         `keeper`            A trusted EOA managed by a trusted WEB3 cyber security entity
///         `vault`             The address of the Balancer vault on the current chain
///         `pools`             An array of Balancer pool addresses where `safe` has the role required for pausing
///         `safe`              A GnosisSafe multisig contract address managed by the Balancer team
///                             `Safe` holds the roles in the pool contracts required for pausing / unpausing
///
/// BUSINESS LOGIC:
///
///         The contract is deployed on every chain where Balancer plans to pause the pools.
///
///         Set at deployment:
///                             - `vault`   Relevant for the current chain
///                             - `keeper`  Relevant for the current chain or the same for all EVMs
///                             - `safe`    Relevant for the current chain or the same for all EVMs
///
///
///         The `keeper` intended behavior:
///
///                 1. It pauses a range or all the `pools` in case of a detected security event.
///                 2. Pools are added or deleted by the `keeper` only upon Balancer team requests.
///                 3. The `keeper` can update the `keeper` but cannot replace the `vault` or the `safe` contract
///
///         The `safe` intended behavior:
///
///                 1. `Safe` can add or delete liquidity pools once there is a need
///                 2. `Safe` can update the `safe`, the `keeper`, and the `vault`
///                 3. `Safe` can pause one or multiple pools for security or business reasons
///
///
/// PUBLIC FUNCTIONS:
///
///         `addPool`           Appends a single pool to the `pools` array
///         `addPools`          Adds an array of pool address
///         `deletePool`        Deletes a single pool address from the `pools` array
///         `deletePools`       Removes an array of pool addresses
///         `deleteAllPools`    Empties the pools array of all the addresses in one transaction
///         `getPool`           Fetches a pool address from the array by its index
///         `getPools`          Fetches an array of pool addresses by the `from` & `to` indices
///         `poolsLength`       Fetches the number of items in the `pools` array
///         `pause`             Pauses a range of pools from the stored array by the `from` & `to` indices
///         `pauseAll`          Pauses all the pools in the `pools` array
///         `updateKeeper`      Replaces the keeper address
///         `updateSafe`        Replaces the GnosisSafe address
///         `updateVault`       Replaces the vault address
///
/// MODIFIERS:
///
///         `keeperOrSafe`      Limits the function callers to `safe` or `keeper`
///         `onlySafe`          Limits the function caller to `safe` only
///
contract BalancerHelper {
    string private constant ERROR_UNAUTHORIZED = "Unauthorised call";

    /// @notice the role bearer
    address public keeper;

    /// @notice Multisig contract
    address public safe;

    /// @notice Balancer Vault address
    address public vault;

    /// @dev pool addresses hashmap
    address[] public pools;

    /// @dev pool addresses hashmap
    mapping (address pool => bool) isPoolPresent;

    /// @dev limits the function callers to `safe` or `keeper`
    modifier keeperOrSafe() {
        require(msg.sender == keeper || msg.sender == safe, ERROR_UNAUTHORIZED);
        _;
    }

    /// @dev limits the function caller to `safe` only
    modifier onlySafe() {
        require(msg.sender == safe, ERROR_UNAUTHORIZED);
        _;
    }

    /// @dev Emitted when a pool address is altered
    /// @param index the position of the address on the list
    /// @param pool the address of the deleted pool
    /// @param operation the kind of change
    event PoolUpdated(uint256 index, address pool, string operation);

    /// @dev Emitted when a pool pausing failed
    /// @param pool the address whose pausing failed
    event PauseFailed(address pool);

    /// @dev Emitted when a safe address is updated
    /// @param newSafe the new safe address
    event SafeUpdated(address newSafe);

    /// @dev Emitted whe3n the keeper address is updated
    /// @param newKeeper the replacing keeper address
    event KeeperUpdated(address newKeeper);

    /// @dev Emitted when the vault address is updated
    /// @param newVault the replacing vault address
    event VaultUpdated(address newVault);

    constructor(address newVault, address newKeeper, address newSafe) {
        // Step 1: Verify input
        // Step 1.1: Revert early if the `newKeeper` is address zero
        _expectNonZeroAddress(newKeeper, "newKeeper is address zero");
        // Step 1.2: Revert early if the `newSafe` is not a contract
        _expectContract(newSafe, "newSafe is not a contract");
        // Step 2: Update storage
        vault = newVault;
        keeper = newKeeper;
        safe = newSafe;
    }

    //      P U B L I C   F U N C T I O N S

    /// @notice Saves a new pool
    /// @dev REVERTS IF: caller is not `safe` or `keeper`
    /// @param newPoolId the added poolId
    function addPool(bytes32 newPoolId) public keeperOrSafe {
        _addPool(newPoolId);
    }

    /// @notice Saves a batch of pools
    /// @dev REVERTS IF: caller is not `safe` or `keeper`
    /// @param _poolIds the added poolIds
    function addPools(bytes32[] memory _poolIds) external keeperOrSafe {
        // Step 1: Compute the length once
        uint length = _poolIds.length;

        // Step 2: loop over the pool addresses in the `_poolIds`
        for (uint256 index = 0; index < length; ++index) {
            // Add the pool address to the `pools` array
            _addPool(_poolIds[index]);
        }
    }

    /// @notice Delets a pool by index
    /// @dev REVERTS IF: caller is not `safe` or `keeper`
    /// @param index the position of the pool address in the list
    function deletePool(
        uint256 index
    ) external keeperOrSafe {
        // Step 0: Verify input
        if (index >= pools.length) revert("Out of index range");
        // Step 1: Trigger the deletion logic
        _deletePool(index);
    }

    /// @notice  Delets a range of pools
    /// @dev REVERTS IF: caller is not `safe` or `keeper`
    /// @param from the initial index
    /// @param to the final index
    function deletePools(
        uint256 from,
        uint256 to
    ) external keeperOrSafe {
        // Step 0: Verify input
        (from, to) = _rangeCheck(from, to);
        // Step 1: Loop over the index range
        for (uint256 i = to; i > from; --i) {  
            // Delete the pool at the index  
            _deletePool(i - 1);
        }
    }

    /// @notice Deletes all the pool addresses
    /// @dev REVERTS IF: caller is not `safe` or `keeper`
    function deleteAllPools() external keeperOrSafe {
        // Step 1: Compute the length once
        uint256 length = pools.length;
        // Step 2: Loop over the indices
        for (uint256 i = 0; i < length; ++i) {
            // Step 2.1: store the last pool address
            address deletedPool = pools[pools.length - 1];
            // Step 2.2: delete the last array item
            pools.pop();
            // Step 2.3: Remove the pool address from known
            isPoolPresent[deletedPool] = false;
            // Step 2.4 Notify the external observers
            emit PoolUpdated(pools.length, deletedPool, "Deleted");
        }
    }

    /// @notice Fetches a pool by its index
    /// @dev reverts if index >= pools.length
    /// @param index the requested pool index
    /// @return pool a pool address found at `index`
    function getPool(uint256 index) public view returns (address pool) {
        // Step 1: revert early if the `index` is out of range
        if (index >= pools.length) revert("Out of index range");
        // Step 2: return the pool address at `index`
        pool = pools[index];
    }

    /// @notice Fetches the number of pools
    /// @return - the number of items in the `pools` array
    function poolsLength() public view returns (uint256) {
        return pools.length;
    }

    /// @notice Fetches an array of pool addresses
    /// @dev Reverts if from is greater than to
    /// @param from the initial pool index (inclusive)
    /// @param to the final pool index (exclusive)
    /// @return _pools an array of the pool addresses within the `from` - `to` index range
    function getPools(
        uint256 from,
        uint256 to
    ) public view returns (address[] memory _pools) {
        // Step 0: Verify input
        (from, to) = _rangeCheck(from, to);
        // Step 1: allocate memory
        _pools = new address[](to - from);
        // Step 2: allocate memory for the counter
        uint256 counter = 0;
        // Step 3: Loop over the index range
        for (uint256 index = from; index < to; ++index) {
            // Step 3.1: Populate the returned array with a pool address from the storage at the index
            _pools[counter] = pools[index];
            // Step 3.2: increment the counter
            ++counter;
        }
    }

    /// @notice Pauses the range of pools
    /// @dev REVERTS IF: caller is not `safe` or `keeper`
    /// @param from the initial pool index (inclusive)
    /// @param to the final pool index (exclusive)
    function pause(uint256 from, uint256 to) external keeperOrSafe {
        // Step 1: Verify input
        // Step 1.1: Ensure the `from` & `to` make sense for the `pools` array
        (from, to) = _rangeCheck(from, to);
        // Step 1.1: Encode the low level call data for calling the `pause()` function
        bytes memory callData = abi.encodeWithSelector(IPool.pause.selector);
        // Step 2: loop over the indices
        for (uint256 index = from; index < to; ++index) {
            // Step 2.1: Trigger the execute from module of the gnosis safe
            bool success = GnosisSafe(payable(safe)).execTransactionFromModule(
                pools[index],
                0,
                callData,
                Enum.Operation.Call
            );
            // Step 2.2: Notify the external entities which pool's pausing failed
            if (!success) emit PauseFailed(pools[index]);
        }
    }

    /// @notice Pauses all the pools
    function pauseAll() external keeperOrSafe {
        uint256 length = pools.length;
        bytes memory callData = abi.encodeWithSelector(IPool.pause.selector);
        for (uint256 index; index < length; ++index) {
            bool success = GnosisSafe(payable(safe)).execTransactionFromModule(
                pools[index],
                0,
                callData,
                Enum.Operation.Call
            );
            if (!success) emit PauseFailed(pools[index]);
        }
    }

    /// @notice Replaces the keeper address
    /// @dev REVERTS IF: caller is not `safe` or `keeper`
    /// @param newKeeper the address of the new keeper
    function updateKeeper(address newKeeper) external keeperOrSafe {
        // Step 1: Ensure the new `keeper` is not address zero
        _expectNonZeroAddress(newKeeper, "Zero address");
        // Step 2: Update the storage variable
        keeper = newKeeper;
        // Step 3: Notify the external entities of the `keeper` change
        emit KeeperUpdated(newKeeper);
    }

    /// @notice Replaces the multisig address
    /// @dev REVERTS IF: caller is not `safe`
    /// @param newSafe the address of the new Gnosis Safe
    function updateSafe(address newSafe) external onlySafe {
        // Step 1: Ensure the `newSafe` is a contract
        _expectContract(newSafe, "newSafe is not a contract");
        // Step 2: Update the storage
        safe = newSafe;
        // Step 3: Notify the external entities of the `safe` change
        emit SafeUpdated(newSafe);
    }


    /// @notice Replaces the Balancer vault address
    /// @param newVault the address of the new Balancer Vault
    function updateVault(address newVault) external onlySafe {
        // Step 1: Ensure the `newVault` is a contract
        _expectContract(newVault, "newVault is not a contract");
        // Step 2: Update the storage
        vault = newVault;
        // Step 3: Notify the external entities of the `vault` change
        emit VaultUpdated(newVault);
    }

    //      P R I V A T E   F U N C T I O N S

    /// @dev updates a pool address
    /// @param poolId a unique pool identifier
    function _addPool(bytes32 poolId) private {
        // Step 0: Fetch the pool address
        (address newPool, ) = IVault(vault).getPool(poolId);
        // Step 1: Verify input
        _expectContract(newPool, "poolId doesn't exist");
        // Step 2: Update the storage
        if (!isPoolPresent[newPool]) {
            // Step 2.1: append the new item
            pools.push(newPool);
            // Step 2.2: Mark the pool present
            isPoolPresent[newPool] = true;
            // Step 2.3: Notify the external entities
            emit PoolUpdated(pools.length - 1, newPool, "Added");
        }
    }

    /// @dev A single pool deletion logic
    /// @param index the index of the deleted pool
    function _deletePool(uint256 index) private {
        // Step 1: Verify input
        require(poolsLength() > 0, "No available pools");
        // Step 2: swap the last item with the removed one
        // Step 2.1: save the deleted pool address locally
        address deletedPool = pools[index];
        // Step 2.2: Replace the item at index with the last item
        pools[index] = pools[pools.length - 1];
        // Step 3: Delete the item
        // Step 3.1: Remove the array's last item
        pools.pop();
        // Step 3.2: mark the pool address absent
        isPoolPresent[deletedPool] = false;
        // Step 4: Notify the external observers
        emit PoolUpdated(pools.length, deletedPool, "Deleted");
    }

    /// @dev Verifies whether `a` is address zero
    /// @dev REVERTS IF: `a` equals address zero
    /// @param a a verified address
    /// @param message an injected revert reason
    function _expectNonZeroAddress(
        address a,
        string memory message
    ) private pure {
        if (a == address(0)) revert(message);
    }

    /// @dev Verifies whether `a` is a contract
    /// @dev REVERTS IF: `a` has no code attached
    /// @param a a verified address
    /// @param message an injected revert reason
    function _expectContract(address a, string memory message) private view {
        // Step 1: Ensure non-zero address
        _expectNonZeroAddress(a, message);
        // Step 2: Revert if there's no code
        if (a.code.length == 0) revert(message);
    }

    /// @dev `from` & `to` params verification
    /// @dev REVERTS IF:
    ///      1. The pools array is empty
    ///      2. the initial index `from` is greater than the final index `to`
    /// @param from the initial index
    /// @param to the final index
    function _rangeCheck(
        uint256 from,
        uint256 to
    ) private view returns (uint256 _from, uint256 _to) {
        // Step 1: Revert early if the pools array is empty
        if (pools.length == 0) revert("No available pools");
        // Step 2: Revert if the initial index is greater than the final one
        if (from >= to) revert("from is greater than to");
        // Step 3: Fix the final index if it was out of the range
        _to = to > pools.length ? pools.length : to;
        // Step 4: Populate the returned `_from`
        _from = from;
    }
}
