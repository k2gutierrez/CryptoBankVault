// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ERC20 } from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract YieldToken is ERC20, Ownable {
    constructor(string memory _name, string memory _symbol, address _owner) ERC20(_name, _symbol) Ownable(_owner) {}

    /**
     * @dev Function to mint reward tokens.
     * Only the Bank contract (when assigned as owner) will be able to call it.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
