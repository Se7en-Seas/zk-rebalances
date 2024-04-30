pragma circom 2.0.3;

include "vocdoni-keccak/keccak.circom";
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
    signal input step_in[2];

    // Keccak hash of step_in and some private data.
    signal output step_out[2];

    signal input adder;

    component stepInToBits0 = Num2Bits(128);
    component stepInToBits1 = Num2Bits(128);
    component adderToBits = Num2Bits(256);
    stepInToBits0.in <== step_in[0];
    stepInToBits1.in <== step_in[1];
    adderToBits.in <== adder;

    component hasher = Keccak(512, 256);
    for (var i=0; i<128; i++) {
        hasher.in[i] <== stepInToBits0.out[i];
        hasher.in[i+128] <== stepInToBits1.out[i];
        hasher.in[2 * i + 256] <== adderToBits.out[2 * i];
        hasher.in[2 * i + 256 + 1] <== adderToBits.out[2 * i + 1];
    }

    component bitsToStepOut0 = Bits2Num(128);
    component bitsToStepOut1 = Bits2Num(128);
    for (var i=0; i<128; i++) {
        bitsToStepOut0.in[i] <== hasher.out[i];
        bitsToStepOut1.in[i] <== hasher.out[i + 128];
    }

    step_out[0] <== bitsToStepOut0.out;
    step_out[1] <== bitsToStepOut1.out;
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