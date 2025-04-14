// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title RebaseToken
 * @author Samkit Soni
 * @dev This is a cross-chain rebase token tht incentivises users to deposit into a vault and gain interest.
 * @notice The interest rate in the smart contract can only decrease.
 * @notice Each user will have their own interest rate that is the global interest at the time of depositing.
 */
contract RebaseToken is ERC20, Ownable, AccessControl {
    error RebaseToken__InterestRateCanOnlyDecrease();

    uint256 private constant INTEREST_RATE_PRECISION = 1e18;
    bytes32 private constant MINT_AND_BURN_ROLE = keccak256("MINT_AND_BURN_ROLE");
    uint256 private INTEREST_RATE = (5 * INTEREST_RATE_PRECISION) / 1e8;

    mapping(address => uint256) public s_userInterestRate;
    mapping(address => uint256) public s_userLastUpdatedTimestamp;

    event InterestRateChanged(uint256 newInterestRate);

    constructor() ERC20("RebaseToken", "RBT") Ownable(msg.sender) {}

    function grantMintAndBurnRole(address _account) external onlyOwner {
        // Grant the mint and burn role to the account
        _grantRole(MINT_AND_BURN_ROLE, _account);
    }

    function setInterestRate(uint256 _newInterestRate) external onlyOwner {
        //Set the interest rate
        if (INTEREST_RATE <= _newInterestRate) {
            revert RebaseToken__InterestRateCanOnlyDecrease();
        }
        INTEREST_RATE = _newInterestRate;
        emit InterestRateChanged(_newInterestRate);
    }

    function mint(address _to, uint256 _amount, uint256 _userInterestRate) external onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = _userInterestRate;
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(_from);
        _burn(_from, _amount);
    }

    function balanceOf(address _user) public view override returns (uint256) {
        return (super.balanceOf(_user) * _calculateUserAccumulatedInterest(_user)) / INTEREST_RATE_PRECISION;
    }

    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[msg.sender];
        }
        return super.transfer(_recipient, _amount);
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccruedInterest(_sender);
        _mintAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_sender);
        }
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[_sender];
        }
        return super.transferFrom(_sender, _recipient, _amount);
    }

    function _calculateUserAccumulatedInterest(address _user) internal view returns (uint256 interest) {
        uint256 timeElapsed = block.timestamp - s_userLastUpdatedTimestamp[_user];
        interest = INTEREST_RATE_PRECISION + (s_userInterestRate[_user] * timeElapsed);
    }

    /**
     * @notice Mint the accured interest to the user since the last time they interacted with the protocol.
     * @param _user The address of the user to mint the interest to.
     */
    function _mintAccruedInterest(address _user) internal {
        //Find their current balance of rebase tokens that have been minted to the user
        uint256 prevBalance = super.balanceOf(_user);
        //Calculate their current balance including any interest -> balaceOf
        uint256 currentBalance = balanceOf(_user);
        //Calculate the number of tokens that needed to be minted to the user -> (2)-(1)
        uint256 amountToMint = currentBalance - prevBalance;
        //Call _mint to mint the tokens to the user
        if (amountToMint > 0) {
            _mint(_user, amountToMint);
        }
        //Set the users last updated timestamp
        s_userLastUpdatedTimestamp[_user] = block.timestamp;
    }

    function getInterestRate() external view returns (uint256) {
        return INTEREST_RATE;
    }

    function getUserInterestRate(address _user) external view returns (uint256) {
        return s_userInterestRate[_user];
    }

    function principleBalanceOf(address _user) external view returns (uint256) {
        return super.balanceOf(_user);
    }
}
