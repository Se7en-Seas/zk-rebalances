pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/switcher.circom";
include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/mimc.circom";
include "../node_modules/circomlib/circuits/sha256/sha256.circom";
include "../node_modules/circomlib/circuits/bitify.circom";

// Hash left and right inputs using Poseidon.
template HashLR() {
    signal input L;
    signal input R;
    signal output out;

    component hasher = Poseidon(2);
    hasher.inputs[0] <== L;
    hasher.inputs[1] <== R;

    hasher.out ==> out;
}

template HashSingle() {
    signal input single;
    signal output out;

    component hasher = Poseidon(1);
    hasher.inputs[0] <== single;

    hasher.out ==> out;
}

component main = HashLR();
