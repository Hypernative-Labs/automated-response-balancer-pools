// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract MockPool {
    bool public isPaused;

    function pause() external {
        isPaused = true;
    }

    function unpause() external {
        isPaused = false;
    }
}