// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IPool {
    /**
     * @notice Pause the pool: an emergency action which disables all pool functions.
     * @dev This is a permissioned function that will only work during the Pause Window set during pool factory
     * deployment (see `TemporarilyPausable`).
     */
    function pause() external;
}