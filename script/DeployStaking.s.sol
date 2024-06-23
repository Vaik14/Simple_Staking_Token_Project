// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/Script.sol";
import {Token} from "../src/Token.sol";
import {TokenStaking} from "../src/TokenStaking.sol";

contract DeployStaking is Script{
    Token public token;
    TokenStaking public staking;
   

    function run()public returns(TokenStaking) {
        token = new Token();
        address tokenAddress = address(token);
        staking = new TokenStaking(tokenAddress);
        return staking;
    }
}