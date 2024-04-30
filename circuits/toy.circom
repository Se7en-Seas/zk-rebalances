pragma circom 2.0.3;

include "../node_modules/circomlib/circuits/sha256/sha256.circom";
include "../node_modules/circomlib/circuits/bitify.circom";

// template Example () {
//     signal input step_in[2];

//     signal output step_out[2];

//     signal input adder;

//     step_out[0] <== step_in[0] + adder;
//     step_out[1] <== step_in[0] + step_in[1];
// }

// component main { public [step_in] } = Example();

template Example () {
    // Initially a nonce, then after first step is the keccak hash of the previous step.
    signal input step_in[1];

    // Keccak hash of step_in and some private data.
    signal output step_out[1];

    signal input adder;

    component stepIn2Bits = Num2Bits(256);
    component adder2Bits = Num2Bits(256);
    stepIn2Bits.in <== step_in[0];
    adder2Bits.in <== adder;

    component hasher = Sha256(512);
    for (var i=0; i<256; i++) {
        hasher.in[i] <== stepIn2Bits.out[255 - i];
        hasher.in[i + 256] <== adder2Bits.out[255 - i];
    }

    component bits2StepOut = Bits2Num(256);
    for (var i=0; i<256; i++) {
        bits2StepOut.in[i] <== hasher.out[255 - i];
    }

    step_out[0] <== bits2StepOut.out;
}

template ExampleN(N) {
    signal input step_in[2];

    signal output step_out[2];

    signal input adder[N];

    component examples[N];

    // Initialize first component.
    examples[0] = Example();
    examples[0].step_in[0] <== step_in[0];
    examples[0].step_in[1] <== step_in[1];
    examples[0].adder <== adder[0];

    for (var i=1; i<N; i++) {
        examples[i] = Example();
        examples[i].step_in[0] <== examples[i-1].step_out[0];
        examples[i].step_in[1] <== examples[i-1].step_out[1];
        examples[i].adder <== adder[i];
    }

    // Assign outputs.
    step_out[0] <== examples[N-1].step_out[0];
    step_out[1] <== examples[N-1].step_out[1];
}

// component main { public [step_in] } = ExampleN(5);
component main { public [step_in] } = Example();

/* INPUT = {
    "step_in": [1, 1],
    "step_out": [1, 2],
    "adder": 0
} */