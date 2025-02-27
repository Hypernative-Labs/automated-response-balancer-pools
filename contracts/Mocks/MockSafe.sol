// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IBalancerHelper {
    function addPool(bytes32 newPoolId) external;
    function addPools(bytes32[] memory _poolIds) external;

    function updateSafe(address newSafe) external;
    function updateVault(address newVault) external;
    function pause(uint256 from, uint256 to) external;
    function pauseAll() external;
}

/// @title MockSafe
/// @dev immitates some Safe functionality
contract MockSafe {
    address public owner;
    address public module;

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorised call");
        _;
    }

    constructor(address newOwner) {
        owner = newOwner;
    }

    function addPool(bytes32 newPoolId) external onlyOwner {
        IBalancerHelper(module).addPool(newPoolId);
    }

    function addPools(bytes32[] memory _poolIds) external onlyOwner {
        IBalancerHelper(module).addPools(_poolIds);
    }

    function updateSafe(address newSafe) external onlyOwner {
        IBalancerHelper(module).updateSafe(newSafe);
    }

    function updateVault(address newVault) external onlyOwner {
        IBalancerHelper(module).updateVault(newVault);
    }

    function setModule(address newModule) external onlyOwner {
        module = newModule;
    }

    function pause(uint256 from, uint256 to) external onlyOwner {
        IBalancerHelper(module).pause(from, to);
    }

    function pauseAll() external onlyOwner {
        IBalancerHelper(module).pauseAll();
    }

    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        uint8 operation
    ) external returns (bool success) {
        if (operation == 0) {
            (success, ) = to.call{value: value}(data);
            return success;
        }
        return false;
    }
}
