// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/// @title MockPool
/// @dev Imitates pool's pausing / unpausing logic
contract MockPool {
    /// @notice Storage switch flag
    bool public isPaused;

    /// @notice Switches the state to PAUSED
    function pause() external {
        if (isPaused) revert("Already paused");

        isPaused = true;
    }

    /// @notice Switches the state to UNPAUSED
    function unpause() external {
        isPaused = false;
    }
}