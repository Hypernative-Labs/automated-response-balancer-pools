// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IPool} from "./interfaces/IPool.sol";
import {Enum} from "./GnosisSafeL2/common/Enum.sol";
import {GnosisSafe} from "./GnosisSafeL2/GnosisSafe.sol";
import {IVault} from "./interfaces/IVault.sol";

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

    modifier keeperOrSafe() {
        require(msg.sender == keeper || msg.sender == safe, ERROR_UNAUTHORIZED);
        _;
    }

    modifier onlySafe() {
        require(msg.sender == safe, ERROR_UNAUTHORIZED);
        _;
    }

    event PoolUpdated(uint256 index, address pool, string operation);
    event PauseFailed(address pool);
    event SafeUpdated(address newSafe);
    event KeeperUpdated(address newKeeper);
    event VaultUpdated(address newVault);

    constructor(address newVault, address newKeeper, address newSafe) {
        // Step 0: Verify input
        _expectNonZeroAddress(newKeeper, "newKeeper is address zero");
        _expectContract(newSafe, "newSafe is not a contract");
        // Step 1: Update storage
        vault = newVault;
        keeper = newKeeper;
        safe = newSafe;
    }

    //      P U B L I C   F U N C T I O N S

    /// @notice Saves a new pool
    /// @param newPoolId the added poolId
    function addPool(bytes32 newPoolId) public keeperOrSafe {
        _addPool(newPoolId);
    }

    /// @notice Saves a batch of pools
    /// @param _poolIds the added poolIds
    function addPools(bytes32[] memory _poolIds) external keeperOrSafe {
        uint length = _poolIds.length;

        for (uint256 index = 0; index < length; ++index) {
            _addPool(_poolIds[index]);
        }
    }

    /// @notice Delets a pool by index
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
    /// @param from the initial index
    /// @param to the final index
    function deletePools(
        uint256 from,
        uint256 to
    ) external keeperOrSafe {
        // Step 0: Verify input
        (from, to) = _rangeCheck(from, to);
        // Step 1: Deletion loop
        for (uint256 i = to; i > from; --i) {    
            _deletePool(i - 1);
        }
    }

    /// @notice Deletes all the pool addresses
    function deleteAllPools() external keeperOrSafe {
        uint256 length = pools.length;
        for (uint256 i = 0; i < length; ++i) {
            address deletedPool = pools[pools.length - 1];
            pools.pop();
            isPoolPresent[deletedPool] = false;
            emit PoolUpdated(pools.length, deletedPool, "Deleted");
        }
    }

    /// @notice Fetches a pool by its index
    /// @dev reverts if index >= pools.length
    /// @param index the requested pool index
    function getPool(uint256 index) public view returns (address pool) {
        if (index >= pools.length) revert("Out of index range");
        pool = pools[index];
    }

    /// @notice Fetches the number of pools
    function poolsLength() public view returns (uint256) {
        return pools.length;
    }

    /// @notice Fetches an array of pool addresses
    /// @dev Reverts if from is greater than to
    /// @param from the initial pool index (inclusive)
    /// @param to the final pool index (exclusive)
    function getPools(
        uint256 from,
        uint256 to
    ) public view returns (address[] memory _pools) {
        // Step 0: Verify input
        (from, to) = _rangeCheck(from, to);
        // Step 1: allocate memory
        _pools = new address[](to - from);
        uint256 counter = 0;
        // Step 2: Populate the array
        for (uint256 index = from; index < to; ++index) {
            _pools[counter] = pools[index];
            ++counter;
        }
    }

    /// @notice Pauses the range of pools
    /// @param from the initial pool index (inclusive)
    /// @param to the final pool index (exclusive)
    function pause(uint256 from, uint256 to) external keeperOrSafe {
        // Step 0: Verify input
        (from, to) = _rangeCheck(from, to);
        bytes memory callData = abi.encodeWithSelector(IPool.pause.selector);
        // Step 2: pause
        for (uint256 index = from; index < to; ++index) {
            bool success = GnosisSafe(payable(safe)).execTransactionFromModule(
                pools[index],
                0,
                callData,
                Enum.Operation.Call
            );
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
    /// @param newKeeper the address of the new keeper
    function updateKeeper(address newKeeper) external keeperOrSafe {
        _expectNonZeroAddress(newKeeper, "Zero address");
        keeper = newKeeper;
        emit KeeperUpdated(newKeeper);
    }

    /// @notice Replaces the multisig address
    /// @param newSafe the address of the new Gnosis Safe
    function updateSafe(address newSafe) external onlySafe {
        _expectContract(newSafe, "newSafe is not a contract");
        safe = newSafe;
        emit SafeUpdated(newSafe);
    }


    /// @notice Replaces the Balancer vault address
    /// @param newVault the address of the new Balancer Vault
    function updateVault(address newVault) external onlySafe {
        _expectContract(newVault, "newVault is not a contract");
        vault = newVault;
        emit VaultUpdated(newVault);
    }

    //      P R I V A T E   F U N C T I O N S

    /// @dev updates a pool address
    function _addPool(bytes32 poolId) private {
        // Step 0: Fetches the pool address
        (address newPool, ) = IVault(vault).getPool(poolId);
        // Step 1: Verify input
        _expectContract(newPool, "poolId doesn't exist");
        // Step 2: Update storage
        if (!isPoolPresent[newPool]) {
            pools.push(newPool);
            isPoolPresent[newPool] = true;
            emit PoolUpdated(pools.length - 1, newPool, "Added");
        }
    }

    /// @dev A single pool deletion logic
    function _deletePool(uint256 index) private {
        // Step 1: Verify input
        require(poolsLength() > 0, "No available pools");
        // Step 2: swap the last item with the removed one
        address deletedPool = pools[index];
        pools[index] = pools[pools.length - 1];
        // Step 3: Delete the last item
        pools.pop();
        isPoolPresent[deletedPool] = false;
        emit PoolUpdated(pools.length, deletedPool, "Deleted");
    }

    /// @dev Reverts if `a` is address zero
    function _expectNonZeroAddress(
        address a,
        string memory message
    ) private pure {
        if (a == address(0)) revert(message);
    }

    /// @dev Reverts if `a` has no attached code
    function _expectContract(address a, string memory message) private view {
        _expectNonZeroAddress(a, message);
        if (a.code.length == 0) revert(message);
    }

    /// @dev `from` & `to` params verification
    function _rangeCheck(
        uint256 from,
        uint256 to
    ) private view returns (uint256 _from, uint256 _to) {
        if (pools.length == 0) revert("No available pools");
        if (from >= to) revert("from is greater than to");
        _to = to > pools.length ? pools.length : to;
        _from = from;
    }
}
