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
    signal input tokenDelta;
    signal input tokenPrice[1];
    signal output positiveValueChange;
    signal output negativeValueChange;
    component val = DetermineValueChange(1);

    val.deltaIn <== tokenDelta;
    val.pricesIn[0] <== tokenPrice[0];
    positiveValueChange <== val.positiveValueChange;
    negativeValueChange <== val.negativeValueChange;

}

component main = RebalanceStep();

/* INPUT = {
    "step_in": [1, 1],
    "step_out": [1, 2],
    "adder": 0
} */