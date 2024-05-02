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
    signal input in[4];
    signal output out;
    component k = Keccakn(4);

    k.in[0] <== in[0];
    k.in[1] <== in[1];
    k.in[2] <== in[2];
    k.in[3] <== in[3];
    out <== k.out;
}

component main = RebalanceStep();

/* INPUT = {
    "step_in": [1, 1],
    "step_out": [1, 2],
    "adder": 0
} */