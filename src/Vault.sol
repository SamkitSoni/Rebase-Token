// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IRebaseToken} from "./interfaces/IRebaseToken.sol";

contract Vault {
    // we need to pass the token address to the constructor
    //create a deposit function that mints tokens to the user
    //create a reedem function that burns tokens from the user and sends the user ETH
    //create a way to add rewards to the vault

    error Vault__ReedemFailed();

    IRebaseToken private immutable i_rebaseToken;

    event Deposit(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);

    constructor(IRebaseToken _rebaseToken) {
        i_rebaseToken = _rebaseToken;
    }

    receive() external payable {}

    function deposit() external payable {
        // mint the tokens to the user
        i_rebaseToken.mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }
    /**
     *
     * @param _amount Amount of tokens to redeem
     * @dev If _amount is type(uint256).max, redeem all the tokens
     * @notice Allow users to redeem their tokens for ETH
     */

    function redeem(uint256 _amount) external {
        //is a convenience feature often used in smart contracts to allow users to burn their entire token balance without needing to know or specify the exact amount.
        if (_amount == type(uint256).max) {
            _amount = i_rebaseToken.balanceOf(msg.sender);
        }
        i_rebaseToken.burn(msg.sender, _amount);
        // send the user ETH
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        if (!success) {
            revert Vault__ReedemFailed();
        }
        emit Redeem(msg.sender, _amount);
    }

    function getRebaseToken() external view returns (address) {
        return address(i_rebaseToken);
    }
}
