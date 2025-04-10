// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
    * @title RebaseToken
    * @author Samkit Soni
    * @dev This is a cross-chain rebase token tht incentivises users to deposit into a vault and gain interest.
    * @notice The interest rate in the smart contract can only decrease.
    * @notice Each user will have their own interest rate that is the global interest at the time of depositing.
    */
contract RebaseToken is ERC20 {
    error RebaseToken__InterestRateCanOnlyDecrease();

    uint256 private s_interestRate = 5e10;
    uint256 private constant INTEREST_RATE_PRECISION = 1e18;

    mapping (address => uint256) public s_userInterestRate;
    mapping (address => uint256) public s_userLastUpdatedTimestamp;

    event InterestRateChanged(uint256 newInterestRate);

    constructor() ERC20("RebaseToken", "RBT") {}

    function setInterestRate(uint256 _newInterestRate) external {
        //Set the interest rate
        if(s_interestRate > _newInterestRate) {
            revert RebaseToken__InterestRateCanOnlyDecrease();
        }
        s_interestRate = _newInterestRate; 
        emit InterestRateChanged(_newInterestRate);
    }

    function mint(address _to, uint256 _amount) external {
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = s_interestRate;
        _mint(_to, _amount);
    }

    function balanceOf(address _user) public view override returns (uint256) {
        return (super.balanceOf(_user) * _calculateUserAccumulatedInterest(_user)) / INTEREST_RATE_PRECISION;
    }

    function _calculateUserAccumulatedInterest(address _user) internal view returns (uint256 interest) {
        uint256 timeElapsed = block.timestamp - s_userLastUpdatedTimestamp[_user];
        interest = INTEREST_RATE_PRECISION + (s_userInterestRate[_user] * timeElapsed);
        return interest;
    }

    function _mintAccruedInterest(address _user) internal {
        //Find thier current balance of rebase tokens that have been minted to the user
        //Calculate their current balance including any interest -> balaceOf
        //Calculate the number of tokens that needed to be minted to the user -> (2)-(1)
        //Call _mint to mint the tokens to the user
        //Set the users last updated timestamp
        s_userLastUpdatedTimestamp[_user] = block.timestamp;

        uint256 interest = (s_interestRate * balanceOf(_user)) / 1e18;
        _mint(_user, interest);
    }

    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }

    function getUserInterestRate(address _user) external view returns (uint256) {
        return s_userInterestRate[_user];
    }
}