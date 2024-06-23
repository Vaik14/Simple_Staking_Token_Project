// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";
import {Token} from "../src/Token.sol";

contract DeployToken is Script {
    Token public token;

    function run ()public returns(Token){
        token = new Token();
        return token;
    }
}