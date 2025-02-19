// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

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

    /// @notice the next pool index
    uint256 public poolCount;

    /// @dev pool addresses hashmap
    address[] public pools;

    modifier keeperOrSafe() {
        require(msg.sender == keeper || msg.sender == safe, ERROR_UNAUTHORIZED);
        _;
    }

    modifier onlySafe() {
        require(msg.sender == safe, ERROR_UNAUTHORIZED);
        _;
    }

    event PoolUpdated(uint256 index, address pool, string operation);

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

        for (uint256 index = 0; index < length; index++) {
            _addPool(_poolIds[index]);
        }
    }

    /// @notice Delets a pool by index
    /// @param index the position of the pool address in the list
    function deletePool(
        uint256 index
    ) external keeperOrSafe {
        // Step 0: Verify input
        if (index >= poolCount) revert("Out of index range");
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
            emit PoolUpdated(i, pools[i], "Deleted");
            pools.pop();
        }
        poolCount = 0;
    }

    /// @notice Fetches a pool by its index
    /// @dev reverts if index >= poolCount
    /// @param index the requested pool index
    function getPool(uint256 index) public view returns (address pool) {
        if (index >= poolCount) revert("Out of index range");
        pool = pools[index];
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
        for (uint256 index = from; index < to; index++) {
            _pools[counter] = pools[index];
            counter++;
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
        for (uint256 index = from; index < to; index++) {
            GnosisSafe(payable(safe)).execTransactionFromModule(
                pools[index],
                0,
                callData,
                Enum.Operation.Call
            );
        }
    }

    /// @notice Replaces the keeper address
    /// @param newKeeper the address of the new keeper
    function updateKeeper(address newKeeper) external keeperOrSafe {
        _expectNonZeroAddress(newKeeper, "Zero address");
        keeper = newKeeper;
    }

    /// @notice Replaces the multisig address
    /// @param newSafe the address of the new gnosis safe
    function updateSafe(address newSafe) external onlySafe {
        _expectNonZeroAddress(newSafe, "Zero address");
        safe = newSafe;
    }

    function updateVault(address newVault) external onlySafe {
        _expectNonZeroAddress(newVault, "Zero address");
        vault = newVault;
    }

    //      P R I V A T E   F U N C T I O N S

    /// @dev updates a pool address
    function _addPool(bytes32 poolId) private {
        // Step 0: Fetches the pool address
        (address newPool, ) = IVault(vault).getPool(poolId);
        // Step 1: Verify input
        _expectContract(newPool, "poolId doesn't exist");
        // Step 2: Update storage
        pools.push(newPool);
        emit PoolUpdated(poolCount, newPool, "Added");
        poolCount++;
    }

    /// @dev A single pool deletion logic
    function _deletePool(uint256 index) private {
        // Step 1: Decrement the counter
        poolCount--;
        // Step 2: swap the last item with the removed one
        address deletedPool = pools[index];
        pools[index] = pools[poolCount];
        
        // Step 3: Delete the last item
        pools.pop();
        emit PoolUpdated(poolCount, deletedPool, "Deleted");
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
        if (poolCount == 0) revert("No available pools");
        if (from >= to) revert("from is greater than to");
        _to = to > poolCount ? poolCount : to;
        _from = from;
    }
}
