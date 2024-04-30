pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/switcher.circom";
include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/mimc.circom";
include "vocdoni-keccak/keccak.circom";
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

template RecursiveVedaMerkleProof(LEVELS) {
    // Public signals.
    // [0-1]
    // First step: The batch nonce in the contract.
    // Subsequent steps: The keccak digest of the previous steps.
    // [2]
    // Secret leaf hash.
    // [3]
    // Root hash with secret leaf.
    signal input step_in[4];

    // [0-1]
    // The keccak digest of the previous steps.
    // [2]
    // Secret leaf hash. Copied from step_in[2].
    // [3]
    // Root hash with secret leaf. Copied from step_in[3].
    signal input step_out[2];

    // Private signals.
}