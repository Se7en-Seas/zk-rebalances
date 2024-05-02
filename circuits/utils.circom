pragma circom 2.0.0;

include "vocdoni-keccak/keccak.circom";
include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/comparators.circom";

// TODO when hashing the Token Delta values it is important to hash them as uint256 since solidity does not support hashing them as 254 bit numbers.
// So maybe I actually dont even need to do anything, just pass the fields to this function, then the Num2Bits logic adds 2 zeroes to the front!
template Keccakn(N) {
    signal input in[N];
    signal output out;

    component in2Bits[N]; // = Num2Bits(256); // (1)
    component keccak = Keccak(N*256,256);
    component bits2Out = Bits2Num(256);
    
    // Setup Num2Bits components.
    for (var i=0; i<N; i++) {
        in2Bits[i] = Num2Bits(256);
        in2Bits[i].in <== in[i];
    }

    // Reverse all input bits.
    signal reverse[N][256];
    for (var i=0; i<N; i++) {
        for (var j=0; j<256; j++) {
            reverse[i][j] <== in2Bits[i].out[255-j];
        }
    }

    // Assign all inputs to keccak.
    for (var n=0; n<N; n++) {
        for (var i=0; i< 256 / 8; i++) {
            for (var j=0; j<8; j++) {
                keccak.in[8*i + j + (256 * n)] <== reverse[n][8*i + (7-j)];
            }
        }
    }
    
    for (var i=0; i<256 / 8; i++) {
        for (var j=0; j<8; j++) {
            bits2Out.in[8*i + j] <== keccak.out[256 - 8*(i+1) + j];
        }
    }
    out <== bits2Out.out;
}

// Token prices are packed as follows.
// LSB (160 bits Token Address) (88 bits Token Price) MSB
template UnpackTokenPrice() {
    signal input in;
    signal output token;
    signal output price;

    component in2Bits = Num2Bits(248);
    component bits2Token = Bits2Num(160);
    component bits2Price = Bits2Num(88);

    in2Bits.in <== in;
    for (var i=0; i<160; i++) {
        bits2Token.in[i] <== in2Bits.out[i];
    }

    for (var i=0; i<88; i++) {
        bits2Price.in[i] <== in2Bits.out[160 + i];
    }

    token <== bits2Token.out;
    price <== bits2Price.out;
}

// Token deltas are packed as follows.
// LSB (160 bits Token Address) (88 bits Token Delta) (1 bit for sign) MSB
template UnpackTokenDelta() {
    signal input in;
    signal output token;
    signal output delta;
    signal output sign;

    component in2Bits = Num2Bits(249);
    component bits2Token = Bits2Num(160);
    component bits2Delta = Bits2Num(88);

    in2Bits.in <== in;
    for (var i=0; i<160; i++) {
        bits2Token.in[i] <== in2Bits.out[i];
    }

    for (var i=0; i<88; i++) {
        bits2Delta.in[i] <== in2Bits.out[160 + i];
    }


    token <== bits2Token.out;
    delta <== bits2Delta.out;
    sign <== in2Bits.out[248]; // No need to constrain sign to 0 or 1 since we are reading a bit.
}
// Create an instance of this component per Token Delta.
// Then use 2 calcualte totals to summ the positive and negative deltas.
// Then the final value output will be the 
// previousValue + positiveTotal - negativeTotal + offset
// Where offset is the half way point of the prime number, 
template DetermineValueChange(N) {
    signal input deltaIn; // The Token Delta.
    signal input pricesIn[N]; // Array of Token Prices.
    signal output positiveValueChange;
    signal output negativeValueChange;

    component unpackDelta = UnpackTokenDelta();
    component unpackPrices[N];

    // Unpack everything.
    unpackDelta.in <== deltaIn;
    for (var i=0; i<N; i++) {
        unpackPrices[i] = UnpackTokenPrice();
        unpackPrices[i].in <== pricesIn[i];
    }

    signal positiveSums[N];
    signal negativeSums[N];
    signal amount[N];
    signal amountAdjusted[N];
    component tokenEqs[N];
    component signEqs[N][2];
    signal multiplier[N][2];
    component positiveTotal = CalculateTotal(N);
    component negativeTotal = CalculateTotal(N);

    for (var i=0; i<N; i++) {
        tokenEqs[i] = IsEqual();
        tokenEqs[i].in[0] <== unpackDelta.token;
        tokenEqs[i].in[1] <== unpackPrices[i].token;

        amount[i] <== unpackDelta.delta * unpackPrices[i].price; // TODO need a way to check for overflow, or should check to see what would cause overflow.
        amountAdjusted[i] <== amount[i] / 100000000; // Divide out 1e8 to get the actual amount.

        signEqs[i][0] = IsEqual();
        signEqs[i][0].in[0] <== unpackDelta.sign;
        signEqs[i][0].in[1] <== 0;

        signEqs[i][1] = IsEqual();
        signEqs[i][1].in[0] <== unpackDelta.sign;
        signEqs[i][1].in[1] <== 1;

        multiplier[i][0] <== signEqs[i][0].out * tokenEqs[i].out;
        multiplier[i][1] <== signEqs[i][1].out * tokenEqs[i].out;

        // TODO maybe I can just have this calculate total inputs be assigned here and remove the positiveSums and negativeSums signals?
        positiveSums[i] <== multiplier[i][0] * amountAdjusted[i];
        negativeSums[i] <== multiplier[i][1] * amountAdjusted[i];

        positiveTotal.in[i] <== positiveSums[i];
        negativeTotal.in[i] <== negativeSums[i];
    }


    positiveValueChange <== positiveTotal.out;
    negativeValueChange <== negativeTotal.out;
}

template CalculateTotal(n) {
    signal input in[n];
    signal output out;

    signal sums[n];

    sums[0] <== in[0];

    for (var i = 1; i < n; i++) {
        sums[i] <== sums[i-1] + in[i];
    }

    out <== sums[n-1];
}