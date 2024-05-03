pragma circom 2.0.3;

include "utils.circom";

// template Example () {
//     signal input step_in[2];

//     signal output step_out[2];

//     signal input adder;

//     step_out[0] <== step_in[0] + adder;
//     step_out[1] <== step_in[0] + step_in[1];
// }

// component main { public [step_in] } = Example();
// TODO I need overflow protection in this logic, so if we dont just roll over when we hit the max value, or zero.
// Eventhough this is fairly unlikely to happen with a rebalance that is actually possible.
// My idea is to have a simple template that adds the 2 numbers together, then enforces that the result is greater than the first number.
// then for subtracintg, we subtract the 2 numbers, then enforce that the result is less than the first number.
template RebalanceStep (LEVELS, TOKEN_DELTA_COUNT, TOKEN_PRICE_COUNT) {
    // Public signals.
    // step_in[0] = nonce or previous rebalance digest
    // step_in[1] = secret leaf hash
    // step_in[2] = root hash
    // step_in[3] = rebalance value delta, input should be the order of the scalar field / 2;
    // step_in[4] = token price 0
    // ...
    // step_in[4 + TOKEN_PRICE_COUNT -1] = The final token price.
    signal input step_in[4 + TOKEN_PRICE_COUNT];

    // step_out[0] = current rebalance digest
    // step_out[1] = secret leaf hash
    // step_out[2] = root hash
    // step_out[3] = current rebalance value delta
    // step_out[4] = token price 0
    // ...
    // step_out[4 + TOKEN_PRICE_COUNT -1] = the final token price.
    signal output step_out[4 + TOKEN_PRICE_COUNT];

    // Private signals
    signal input leaf; // keccak hash of the leaf used for rebalance action( note contract must % order of the scalar field).
    signal input pathElements[LEVELS]; // Path to the leaf.
    signal input pathIndices[LEVELS]; // Path indicies.
    signal input tokenDeltas[TOKEN_DELTA_COUNT]; // The token deltas from this action

    // Rename input signals for readability.
    signal nonceOrPreviousDigest <== step_in[0];
    signal secretLeafHash <== step_in[1];
    signal rootHash <== step_in[2];
    signal previousRebalanceValueDelta <== step_in[3];
    signal tokenPrices[TOKEN_PRICE_COUNT];
    for (var i=0; i<TOKEN_PRICE_COUNT; i++) {
        tokenPrices[i] <== step_in[i + 4];
    }

    // Carry through constant signals.
    step_out[1] <== secretLeafHash;
    step_out[2] <== rootHash;
    for (var i=0; i<TOKEN_PRICE_COUNT; i++) {
        step_out[i + 4] <== tokenPrices[i];
    }

    // Make sure the private leaf is not the secret leaf.
    component secretHashChecker = HashSingle();
    component secretLeafEqs = IsEqual();
    secretHashChecker.single <== leaf;
    secretLeafEqs.in[0] <== secretHashChecker.out;
    secretLeafEqs.in[1] <== secretLeafHash;
    secretLeafEqs.out === 0;

    // Verify the merkle proof.
    component hashers[LEVELS];
    component switchers[LEVELS];
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
    rootHash === hashers[LEVELS - 1].out;

    // Compute changes to rebalance value delta.
    component calcRebalanceDelta = CalculateRebalanceValueDelta(TOKEN_DELTA_COUNT, TOKEN_PRICE_COUNT);
    calcRebalanceDelta.previousDelta <== previousRebalanceValueDelta;
    for (var i=0; i<TOKEN_DELTA_COUNT; i++) {
        calcRebalanceDelta.tokenDeltas[i] <== tokenDeltas[i];
    }
    for (var i=0; i<TOKEN_PRICE_COUNT; i++) {
        calcRebalanceDelta.tokenPrices[i] <== tokenPrices[i];
    }
    step_out[3] <== calcRebalanceDelta.rebalanceValueDelta;

    // Compute the current rebalance digest.
    // currentRebalanceDigest = keccak(previousRebalanceDigest, leaf, keccak(tokenDeltas))
    component tokenDeltasHasher = Keccakn(TOKEN_DELTA_COUNT);
    for (var i=0; i<TOKEN_DELTA_COUNT; i++) {
        tokenDeltasHasher.in[i] <== tokenDeltas[i];
    }
    component rebalanceDigestHasher = Keccakn(3);
    rebalanceDigestHasher.in[0] <== nonceOrPreviousDigest;
    rebalanceDigestHasher.in[1] <== leaf;
    rebalanceDigestHasher.in[2] <== tokenDeltasHasher.out;

    step_out[0] <== rebalanceDigestHasher.out;
}

component main {public [step_in]} = RebalanceStep(10, 4, 9);