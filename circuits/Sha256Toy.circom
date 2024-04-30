pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/sha256/sha256.circom";
include "../node_modules/circomlib/circuits/bitify.circom";

template Sha256Toy() {
    signal input a;

    signal output out;

    signal input adder;

    component toBits0 = Num2Bits(256);
    component toBits1 = Num2Bits(256);
    component h = Sha256(512);

    toBits0.in <== a;
    toBits1.in <== adder;

    for (var i = 0; i < 256; i++) {
        h.in[i] <== toBits0.out[255-i];
    }
    
    for (var i = 0; i < 256; i++) {
        h.in[i + 256] <== toBits1.out[255-i];
    }
    component n2bHashInputsOut = Bits2Num(256);

    for (var i = 0; i < 256; i++) {
        n2bHashInputsOut.in[i] <== h.out[255-i];
    }

    out <== n2bHashInputsOut.out;
}

component main { public [a] } = Sha256Toy();
