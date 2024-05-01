pragma circom 2.0.0;

include "vocdoni-keccak/keccak.circom";
include "../node_modules/circomlib/circuits/bitify.circom";

template KeccakToy() {
    signal input a;
    // signal keccak_in[256];
    // signal keccak_out[256];
    signal output out;

    component toNBits = Num2Bits(256); // (1)
    component fromNBits = Bits2Num(256);
    
    // need to build N keccak circuits to perform N-times hashing
    component keccak = Keccak(256,256);

    toNBits.in <== a;

    signal reverse[256];
    var i;

    for (i=0; i<256; i++) {
        reverse[i] <== toNBits.out[255-i];
    }

    for (i=0; i< 256 / 8; i++) {
        for (var j=0; j<8; j++) {
            keccak.in[8*i + j] <== reverse[8*i + (7-j)];
        }
    }
    
    for (i=0; i<256 / 8; i++) {
        for (var j=0; j<8; j++) {
            fromNBits.in[8*i + j] <== keccak.out[256 - 8*(i+1) + j];
        }
    }
    out <== fromNBits.out;
}

component main = KeccakToy();