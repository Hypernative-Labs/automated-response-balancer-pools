// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IPool} from "./interfaces/IPool.sol";
import {Enum} from "./GnosisSafeL2/common/Enum.sol";
import {GnosisSafe} from "./GnosisSafeL2/GnosisSafe.sol";

contract BalancerHelper {
    string private constant ERROR_UNAUTHORIZED = "Unauthorised call";

    /// @notice the role bearer
    address public keeper;

    /// @notice Multisig contract
    address public safe;

    /// @notice the next pool index
    uint256 public poolCount;

    /// @dev pool addresses hashmap
    mapping(uint256 index => address) private _pools;

    modifier keeperOrSafe() {
        require(msg.sender == keeper || msg.sender == safe, ERROR_UNAUTHORIZED);
        _;
    }

    event PoolUpdated(uint256 index, address pool, string operation);

    constructor(address newKeeper, address newSafe) {
        // Step 0: Verify input
        _expectNonZeroAddress(newKeeper, "newKeeper is address zero");
        _expectContract(newSafe, "newSafe is not a contract");
        // Step 1: Update storage
        keeper = newKeeper;
        safe = newSafe;
    }

    //      P U B L I C   F U N C T I O N S

    /// @notice Saves a new pool
    /// @param newPool the added address
    function addPool(address newPool) public keeperOrSafe {
        _addPool(newPool);
    }

    /// @notice Saves a batch of pools
    /// @param pools the added addresses
    function addPools(address[] memory pools) external keeperOrSafe {
        uint length = pools.length;

        for (uint256 index = 0; index < length; index++) {
            _addPool(pools[index]);
        }
    }

    /// @notice Delets a pool by index
    /// @param index the position of the pool address in the list
    function deletePool(uint256 index) external keeperOrSafe {
        // Step 0: Verify input
        if (index >= poolCount) revert("Out of index range");
        // Step 1: Notify the observers
        emit PoolUpdated(index, _pools[index], "Deleted");
        // Step 2: Decrement the counter
        poolCount--;
        // Step 3: swap the last item with the removed one
        _pools[index] = _pools[poolCount];
        // Step 4: Delete the last item
        delete _pools[poolCount];
    }

    /// @notice Fetches a pool by its index
    /// @dev reverts if index >= poolCount
    /// @param index the requested pool index
    function getPool(uint256 index) public view returns (address pool) {
        if (index >= poolCount) revert("Out of index range");
        pool = _pools[index];
    }

    /// @notice Fetches an array of pool addresses
    /// @dev Reverts if from is greater than to
    /// @param from the initial pool index (inclusive)
    /// @param to the final pool index (exclusive)
    function getPools(
        uint256 from,
        uint256 to
    ) public view returns (address[] memory pools) {
        // Step 0: Verify input
        (from, to) = _rangeCheck(from, to);
        // Step 1: allocate memory
        pools = new address[](to - from);
        uint256 counter = 0;
        // Step 2: Populate the array
        for (uint256 index = from; index < to; index++) {
            pools[counter] = _pools[index];
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
                _pools[index],
                0,
                callData,
                Enum.Operation.Call
            );
        }
    }

    //      P R I V A T E   F U N C T I O N S

    function _addPool(address newPool) private {
        // Step 0: Verify input
        _expectContract(newPool, "newPool is not a contract");
        // Step 1: Update storage
        _pools[poolCount] = newPool;
        // Step 2: Notify the observers
        emit PoolUpdated(poolCount, newPool, "Added");
        // Step 3: increment the counter
        poolCount++;
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
