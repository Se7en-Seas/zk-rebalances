// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";
import {PoseidonT2} from "../src/PoseidonT2.sol";
import {PoseidonT3} from "../src/PoseidonT3.sol";


contract CounterTest is Test {
    using PoseidonT2 for uint256[1];
    using PoseidonT3 for uint256[2];

    function setUp() public {
    }

    function testPoseidonMerkleTree() external {
        uint256 p = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

        uint256 a = 1;
        uint256 b = 2;

        uint256 leafA = uint256(sha256(abi.encodePacked(a))) % p;
        uint256 leafB = uint256(sha256(abi.encodePacked(b))) % p;

        uint256 root = [leafA, leafB].hash();

        // console.log("root: %d", root);
        // console.log("leaf a: %d", leafA);
        // console.log("leaf b: %d", leafB);

        uint256 step_in_0;
        uint256 step_in_1;
        uint256 step_in_2;
        uint256 leaf;
        uint256 path_elements_0;
        uint256 path_indices_0;
        uint256 expected_digest;
        // To prove leaf a is in the tree.
        step_in_0 = 1; // nonce
        step_in_1 = 0; // secret leaf hash that we wont worry about for now.
        step_in_2 = root; // root hash
        leaf = leafA;
        path_elements_0 = leafB;
        path_indices_0 = 0;
        expected_digest = uint256(sha256(abi.encodePacked(step_in_0, leaf))) % p;

        console.log("Root");
        console.logBytes32(bytes32(root));

        // Convert step_in_2 to an array of u64 elements.
        uint64[4] memory _step_in_2 = [uint64(step_in_2), uint64(step_in_2 >> 64), uint64(step_in_2 >> 128), uint64(step_in_2 >> 192)];

        // Console log everything.
        console.log("Proof for leaf A");
        console.log("step_in_0: %d", step_in_0);
        console.log("step_in_1: %d", step_in_1);
        console.log("step_in_2: %d", step_in_2);
        console.log("step in 2 array 0: %d", _step_in_2[0]);
        console.log("step in 2 array 1: %d", _step_in_2[1]);
        console.log("step in 2 array 2: %d", _step_in_2[2]);
        console.log("step in 2 array 3: %d", _step_in_2[3]);
        console.log("leaf: %d", leaf);
        console.log("path_elements_0: %d", path_elements_0);
        console.log("path_indices_0: %d", path_indices_0);
        console.log("expected_digest: %d", expected_digest);

        console.log("--------------------------------------------------------------");

        // To prove leaf b is in the tree.
        step_in_0 = expected_digest; // previous digest
        step_in_1 = 0; // secret leaf hash that we wont worry about for now.
        step_in_2 = root; // root hash
        leaf = leafB;
        path_elements_0 = leafA;
        path_indices_0 = 1;
        expected_digest = uint256(sha256(abi.encodePacked(step_in_0, leaf))) % p;

        console.log("Proof for leaf B");
        // console.log("step_in_0: %d", step_in_0);
        // console.log("step_in_1: %d", step_in_1);
        // console.log("step_in_2: %d", step_in_2);
        console.log("leaf: %d", leaf);
        console.log("path_elements_0: %d", path_elements_0);
        console.log("path_indices_0: %d", path_indices_0);
        console.log("expected_digest: %d", expected_digest);

        console.logBytes32(bytes32(expected_digest));

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

    function testKeccakHash() public {
        uint256 nonce = 10;

        uint256 p = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

        uint256 digest = uint256(keccak256(abi.encodePacked(uint256(10), uint256(20), uint256(30), uint256(404304034434)))) % p;

        console.log("digest: %d", digest);
    }

    function testPackTokenPrice() public {
        uint160 token = uint160(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        uint88 price = uint88(3_000e8);

        uint256 packed = (uint256(price) << 160) | uint256(token);

        console.log("packed: %d", packed);
        console.log("token: %d", uint160(packed));
        console.log("token: %d", token);
        console.log("price: %d", price);
    }

        function testPackTokenDelta() public {
        uint8 sign = 0;
        uint88 delta = uint88(1e8);
        uint160 token = uint160(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

        uint256 packed = (uint256(sign) << 248) | (uint256(delta) << 160) | uint256(token);

        console.log("packed: %d", packed);
        console.log("token: %d", token);
        console.log("delta: %d", delta);
        console.log("sign: %d", sign);
    }

    function testRebalanceStep() public {
        uint8 sign = 1;
        uint88 delta = uint88(1_034e8);
        uint160 token = uint160(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

        uint256 tokenDelta = (uint256(sign) << 248) | (uint256(delta) << 160) | uint256(token);

        uint88 price = uint88(3_000e8);

        uint256 tokenPrice = (uint256(price) << 160) | uint256(token);

        uint256 p = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

        console.log("Offset", p / 2);
        console.log("tokenDelta: %d", tokenDelta);
        console.log("tokenPrice: %d", tokenPrice);

        uint256 valueDeltaOffset = 10944121435919637611123202872628637544274182200208017171849101783087904247808;
        int256 valueDelta = int256(valueDeltaOffset) - int256(p / 2);

        if (valueDelta < 0) {
            console.log("valueDelta: (-)%d", uint256(valueDelta * -1));
        } else {
            console.log("valueDelta: %d", uint256(valueDelta));
        }
    }
}
