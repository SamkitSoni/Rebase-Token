// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IRebaseToken {
    function mint(address _to, uint256 _amount) external;
    function burn(address _from, uint256 _amount) external;
    function setInterestRate(uint256 _newInterestRate) external;
    function balanceOf(address _user) external view returns (uint256);
    function getInterestRate() external view returns (uint256);
    function grantMintAndBurnRole(address _account) external;
    function transfer(address _recipient, uint256 _amount) external returns (bool);
}
