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

template RecursiveVedaMerkleProof(LEVELS) {
    // Public signals.
    // [0]
    // First step: The batch nonce in the contract.
    // Subsequent steps: The sha256 digest of the previous steps.
    // [1]
    // Secret leaf hash.
    // [2]
    // Root hash with secret leaf.
    signal input step_in[3];

    // [0]
    // The sha256 digest of the previous steps.
    // [1]
    // Secret leaf hash. Copied from step_in[2].
    // [2]
    // Root hash with secret leaf. Copied from step_in[3].
    signal output step_out[3];

    // Private signals.
    signal input leaf; // Sha256 hash % p of the leaf.
    signal input pathElements[LEVELS]; // Path to the leaf.
    signal input pathIndices[LEVELS]; // Path indicies.
    signal input expectedStepDigest; // The expected sha256 digest of the previous steps.

    // Components.
    component secretHashChecker = HashSingle();
    component secretLeafEqs = IsEqual();
    component digestHasher = Sha256(512);
    component stepIn2Bits = Num2Bits(256);
    component leaf2Bits = Num2Bits(256);
    component bits2StepOut = Bits2Num(256);
    component hashers[LEVELS];
    component switchers[LEVELS];

    // Constrain leaf to not be the secret leaf.
    secretHashChecker.single <== leaf;
    secretLeafEqs.in[0] <== secretHashChecker.out;
    secretLeafEqs.in[1] <== step_in[1];
    secretLeafEqs.out === 0;

    stepIn2Bits.in <== step_in[0];
    leaf2Bits.in <== leaf;

    // Compute step digest.
    for (var i=0; i<256; i++) {
        digestHasher.in[i] <== stepIn2Bits.out[255 - i];
        digestHasher.in[i + 256] <== leaf2Bits.out[255 - i];
    }

    for (var i=0; i<256; i++) {
        bits2StepOut.in[i] <== digestHasher.out[255 - i];
    }
    // Constrain the step digest to be the expected digest.
    bits2StepOut.out === expectedStepDigest;

    // Update step_out[0] and carry through other inputs.
    step_out[0] <== bits2StepOut.out;
    step_out[1] <== step_in[1];
    step_out[2] <== step_in[2];

    // Verify the merkle proof.
    for (var i=0; i<LEVELS; i++) {
        // Setup switchers.
        switchers[i] = Switcher();
        switchers[i].L <== i==0 ? leaf : hashers[i - 1].out;
        switchers[i].R <== pathElements[i];
        switchers[i].sel <== pathIndices[i];
        // Setup hashers.
        hashers[i] = HashLR();
        hashers[i].L <== switchers[i].outL;
        hashers[i].R <== switchers[i].outR;
    }

    // Constrain the root hash to be the expected root hash.
    step_in[2] === hashers[LEVELS - 1].out;

}

component main {public [step_in]} = RecursiveVedaMerkleProof(1);
