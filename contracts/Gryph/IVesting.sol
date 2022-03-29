// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVesting {
  /**
   * @dev Returns true if can vest
   */
  function canVest(uint256 amount) external view returns(bool);

  /**
   * @dev Returns the current ether price per token
   */
  function currentTokenPrice() external view returns(uint256);
  
  /**
   * @dev Allows anyone to invest during the current stage for an `amount`
   */
  function buy(address beneficiary, uint256 amount) external payable;

  /**
   * @dev Allow an admin to manually vest a `beneficiary` for an `amount`
   */
  function vest(address beneficiary, uint256 amount) external;
}