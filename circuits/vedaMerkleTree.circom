pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/switcher.circom";
include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/mimc.circom";

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

/***************************************************************************************************
                                            ?ABCDEFG
                                            /      \
                                        ?ABC       DEFG
                                        /   \      /   \
                                      ?A    BC    DE   FG
                                     / \   / \   / \  / \
                                    ?  A  B  C  D  E F  G
***************************************************************************************************/
// TREE_CAPACITY must be a power of 2.
template VedaMerkleTree(TREE_CAPACITY) {
    var layerIterations = 0;
    for (var i=0; 1 != TREE_CAPACITY / (2 ** i); i++) {
        layerIterations++;
    }
    var arrayLength = 0;
    for (var i=0; i<layerIterations; i++) {
        arrayLength += TREE_CAPACITY / 2 ** (i + 1);
    }

    // Public signals.
    signal output rootWithSecret;
    signal output rootWithNull;
    signal output secretLeafHash; // Stored by contract to revert if verification is tried with secret leaf.

    // Private signals.
    // Minus 1 since one leaf is reserved for the secret leaf.
    signal input leafs[TREE_CAPACITY - 1]; // Minus 1 since one leaf is reserved for the secret leaf.
    signal input secretLeaf; // Secret leaf to be added to the tree
    signal input pathIndices[arrayLength];

    // Internal signals.
    signal nullLeaf <== 0;

    // Components.
    component hashersWithNull[arrayLength];
    component hashersWithSecret[layerIterations];
    component switchersWithNull[arrayLength];
    component switchersWithSecret[layerIterations];
    component secretLeafHashser = HashSingle();

    // Hash the secret leaf.
    secretLeafHashser.single <== secretLeaf;
    secretLeafHash <== secretLeafHashser.out;

    // The tree with null and tree with secret will share the majority of the same hashes, with the exception being the
    // first hash of every layer

    // Hash the first layer of leafs.
    // Hash null leaf with leaf zero.
    switchersWithNull[0] = Switcher();
    switchersWithNull[0].L <== nullLeaf;
    switchersWithNull[0].R <== leafs[0];
    switchersWithNull[0].sel <== pathIndices[0];

    hashersWithNull[0] = HashLR();
    hashersWithNull[0].L <== switchersWithNull[0].outL;
    hashersWithNull[0].R <== switchersWithNull[0].outR;

    // Hash secret leaf with leaf zero.
    switchersWithSecret[0] = Switcher();
    switchersWithSecret[0].L <== secretLeaf;
    switchersWithSecret[0].R <== leafs[0];
    switchersWithSecret[0].sel <== pathIndices[0];

    hashersWithSecret[0] = HashLR();
    hashersWithSecret[0].L <== switchersWithSecret[0].outL;
    hashersWithSecret[0].R <== switchersWithSecret[0].outR;

    // Hash the rest of the first layer.
    for (var i=1; i<TREE_CAPACITY / 2; i++) {
        switchersWithNull[i] = Switcher();
        switchersWithNull[i].L <== leafs[i * 2 - 1];
        switchersWithNull[i].R <== leafs[i * 2];
        switchersWithNull[i].sel <== pathIndices[i];

        hashersWithNull[i] = HashLR();
        hashersWithNull[i].L <== switchersWithNull[i].outL;
        hashersWithNull[i].R <== switchersWithNull[i].outR;
    }

    // Hash the first layer of leafs.
    // As for a tree of 8 leafs, with one secret leaf, the majority of hashes between the secret and no secret tree are the same.
    var hashersIndex = 0;
    var offset = TREE_CAPACITY / 2;
    for (var i=1; i<layerIterations; i++) {
        // Start with Null tree.
        // Set up switcher.
        switchersWithNull[offset] = Switcher();
        switchersWithNull[offset].L <== hashersWithNull[hashersIndex].out;
        switchersWithNull[offset].R <== hashersWithNull[hashersIndex + 1].out;
        switchersWithNull[offset].sel <== pathIndices[offset];
        
        // Setup hasher.
        hashersWithNull[offset] = HashLR();
        hashersWithNull[offset].L <== switchersWithNull[offset].outL;
        hashersWithNull[offset].R <== switchersWithNull[offset].outR;

        // Now do the Secret tree.
        // Set up switcher.
        // Since we know these components are used for the first hash of each layer, we do not need to use the offset logic, instead we can just use i.
        // Note we use the same path indices so that both trees use the same indices for the firt element of each layer.
        switchersWithSecret[i] = Switcher();
        switchersWithSecret[i].L <== hashersWithSecret[i-1].out;
        switchersWithSecret[i].R <== hashersWithNull[hashersIndex + 1].out;
        switchersWithSecret[i].sel <== pathIndices[offset];

        // Setup hasher.
        hashersWithSecret[i] = HashLR();
        hashersWithSecret[i].L <== switchersWithSecret[i].outL;
        hashersWithSecret[i].R <== switchersWithSecret[i].outR;

        hashersIndex += 2;

        // Now iterate through the rest of the layer.
        var iterations = TREE_CAPACITY / (2 ** (i + 1));
        for (var j=1; j<iterations; j++) {
            // Setup switcher.
            switchersWithNull[j + offset] = Switcher();
            switchersWithNull[j + offset].L <== hashersWithNull[hashersIndex].out;
            switchersWithNull[j + offset].R <== hashersWithNull[hashersIndex + 1].out;
            switchersWithNull[j + offset].sel <== pathIndices[j + offset];

            // Setup hasher.
            hashersWithNull[j + offset] = HashLR();
            hashersWithNull[j + offset].L <== switchersWithNull[j + offset].outL;
            hashersWithNull[j + offset].R <== switchersWithNull[j + offset].outR;

            hashersIndex += 2;
        }
        offset += iterations;
    }

    // Constrain final root hashes.
    rootWithNull <== hashersWithNull[offset - 1].out;
    rootWithSecret <== hashersWithSecret[layerIterations - 1].out;
}

component main = VedaMerkleTree(1024);