pragma circom 2.0.0;

include "vocdoni-keccak/keccak.circom";
include "../node_modules/circomlib/circuits/bitify.circom";

// TODO when hashing the Token Delta values it is important to hash them as uint256 since solidity does not support hashing them as 254 bit numbers.
// So maybe I actually dont even need to do anything, just pass the fields to this function, then the Num2Bits logic adds 2 zeroes to the front!
template Keccakn(N) {
    signal input in[N];
    signal output out;

    component in2Bits[N]; // = Num2Bits(256); // (1)
    component keccak = Keccak(N*256,256);
    component bits2Out = Bits2Num(256);
    
    // Setup Num2Bits components.
    for (var i=0; i<N; i++) {
        in2Bits[i] = Num2Bits(256);
        in2Bits[i].in <== in[i];
    }

    // Reverse all input bits.
    signal reverse[N][256];
    for (var i=0; i<N; i++) {
        for (var j=0; j<256; j++) {
            reverse[i][j] <== in2Bits[i].out[255-j];
        }
    }

    // Assign all inputs to keccak.
    for (var n=0; n<N; n++) {
        for (var i=0; i< 256 / 8; i++) {
            for (var j=0; j<8; j++) {
                keccak.in[8*i + j + (256 * n)] <== reverse[n][8*i + (7-j)];
            }
        }
    }
    
    for (var i=0; i<256 / 8; i++) {
        for (var j=0; j<8; j++) {
            bits2Out.in[8*i + j] <== keccak.out[256 - 8*(i+1) + j];
        }
    }
    out <== bits2Out.out;
}

// Token prices are packed as follows.
// (160 bits Token Address) (88 bits Token Price)
template UnpackTokenPrice() {
    signal input in;
    signal output token;
    signal output price;

    component in2Bits = Num2Bits(248);
    component bits2Token = Bits2Num(160);
    component bits2Price = Bits2Num(88);

    in2Bits.in <== in;
    for (var i=0; i<160; i++) {
        bits2Token.in[i] <== in2Bits.out[i];
    }

    for (var i=0; i<88; i++) {
        bits2Price.in[i] <== in2Bits.out[160 + i];
    }

    token <== bits2Token.out;
    price <== bits2Price.out;
}

template UnpackTokenDelta() {
    signal input in;
    signal output token;
    signal output delta;
    signal output sign;

    component in2Bits = Num2Bits(249);
    component bits2Token = Bits2Num(160);
    component bits2Delta = Bits2Num(88);

    in2Bits.in <== in;
    for (var i=0; i<160; i++) {
        bits2Token.in[i] <== in2Bits.out[i];
    }

    for (var i=0; i<88; i++) {
        bits2Delta.in[i] <== in2Bits.out[160 + i];
    }


    token <== bits2Token.out;
    delta <== bits2Delta.out;
    sign <== in2Bits.out[248]; // No need to constrain sign to 0 or 1 since we are reading a bit.
}