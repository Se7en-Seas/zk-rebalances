// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
        counter.setNumber(0);
    }

    function testSha256Hash() public {
        uint256 nonce = 10;

        uint256 p = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

        uint256 digest = uint256(sha256(abi.encodePacked(nonce, uint256(0)))) % p;
        for (uint256 i=1; i<5; i++) {
            digest = uint256(sha256(abi.encodePacked(digest, uint256(i)))) % p;
        }

        console.log("digest: %d", digest);
        console.logBytes32(bytes32(digest));
    }
}
