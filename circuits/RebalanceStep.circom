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

template RebalanceStep () {
    signal input in;
    signal output out;
    component k = keccakn(3);

    k.in[0] <== in;
    k.in[1] <== in;
    k.in[2] <== in;
    out <== k.out;
}

component main = RebalanceStep();

/* INPUT = {
    "step_in": [1, 1],
    "step_out": [1, 2],
    "adder": 0
} */