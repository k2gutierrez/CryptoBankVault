// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IYieldToken {

    /**
     * 
     * @param to address to mint ERC20 tokens
     * @param amount amount of tokens to mint
     */
    function mint(address to, uint256 amount) external;
}