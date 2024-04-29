#!/bin/bash

# this is experimental, educational, dirty script, DO NOT USE IN PRODUCTION :)

# Stop execution if any step returns non-zero (non success) status
set -e

echo
echo
echo

CIRCUIT_NAME=$1
if [ ! $1 ]; then
    echo "You should pass <name> of the existing <name>.circom template to run all. Example: ./run_all.sh multiplier2"
    exit 1
fi

BUILD_DIR=build
if [ ${#BUILD_DIR} -lt 1 ]; then 
    echo "BUILD_DIR var is empty, exiting";
    exit 2;
fi
echo "Removing previous build dir ./$BUILD_DIR to create new empty"
rm -rf ./$BUILD_DIR
if [ ! -d "$BUILD_DIR" ]; then
    mkdir "$BUILD_DIR"
fi

if [ ! -f circuits/${CIRCUIT_NAME}.circom ]; then
    echo "circuits/${CIRCUIT_NAME}.circom template doesn't exist, exit..."
    exit 3
fi

# directory to keep PowersOfTau, zkeys, and other non-circuit-dependent files
POTS_DIR=pots


# power value for "powersOfTau28" pre-generated setup files
POWERTAU=24

# uncomment to output every actual command being run
# set -x

echo
echo "Starting pre-setup phase, downloading/generating powersOfTau files"
# create dir for downloaded 'powersOfTau28*' files if doesn't exist
mkdir -p ${POTS_DIR}

# To generate setup by yourself, don't download below, use:
# snarkjs powersoftau new bn128 ${POWERTAU} powersOfTau28_hez_final_${POWERTAU}.ptau -v
if [ ! -f  ${POTS_DIR}/powersOfTau28_hez_final_${POWERTAU}.ptau ]; then 
    echo "Downloading powersOfTau28_hez_final_${POWERTAU}.ptau from github (to skip generation)"
    wget -O "${POTS_DIR}/powersOfTau28_hez_final_${POWERTAU}.ptau" \
        "https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_${POWERTAU}.ptau"
    echo "${POTS_DIR}/powersOfTau28_hez_final_${POWERTAU}.ptau downloaded "
else
    echo "${POTS_DIR}/powersOfTau28_hez_final_${POWERTAU}.ptau already exists, using current"
fi

echo
echo "Building R1CS for circuit ${CIRCUIT_NAME}.circom"
if ! time circom circuits/${CIRCUIT_NAME}.circom --r1cs --wasm --sym --output "$BUILD_DIR"; then
    echo "circuits/${CIRCUIT_NAME}.circom compilation to r1cs failed. Exiting..."
    exit 4
fi

echo "Info about circuits/${CIRCUIT_NAME}.circom R1CS constraints system"
snarkjs info -c ${BUILD_DIR}/${CIRCUIT_NAME}.r1cs

# echo "Printing constraints
# snarkjs r1cs print ${BUILD_DIR}/${CIRCUIT_NAME}.r1cs ${BUILD_DIR}/${CIRCUIT_NAME}.sym

echo
echo "Setup proving system on built ${BUILD_DIR}/${CIRCUIT_NAME}.r1cs (generation of proving and verification keys)"
snarkjs groth16 setup ${BUILD_DIR}/${CIRCUIT_NAME}.r1cs ${POTS_DIR}/powersOfTau28_hez_final_${POWERTAU}.ptau \
    ${BUILD_DIR}/${CIRCUIT_NAME}.zkey

echo "Exporting verification key to ${BUILD_DIR}/${CIRCUIT_NAME}_verification_key.json"
snarkjs zkey export verificationkey ${BUILD_DIR}/${CIRCUIT_NAME}.zkey \
    ${BUILD_DIR}/${CIRCUIT_NAME}_verification_key.json

echo "Output size of ${BUILD_DIR}/${CIRCUIT_NAME}_verification_key.json"
echo "[PROFILE]" `du -kh "${BUILD_DIR}/${CIRCUIT_NAME}_verification_key.json"`

echo "Output size of ${BUILD_DIR}/${CIRCUIT_NAME}.zkey"
echo "[PROFILE]" `du -kh "${BUILD_DIR}/${CIRCUIT_NAME}.zkey"`


echo
echo "Going to client's side into \"${BUILD_DIR}/${CIRCUIT_NAME}_js\" folder"
cd ${BUILD_DIR}/${CIRCUIT_NAME}_js


# insert construction of inputs here
echo "Create inputs for circuit '$CIRCUIT_NAME' in ${CIRCUIT_NAME}_input.json"
if [[ $CIRCUIT_NAME == "multiplier2" ]]; then
    echo "{\"a\": \"3\", \"b\": \"11\"}" > ./${CIRCUIT_NAME}_input.json
elif [[ $CIRCUIT_NAME == "powerabn" ]]; then
    echo "{\"a\": \"3\", \"b\": \"11\"}" > ./${CIRCUIT_NAME}_input.json
elif [[ $CIRCUIT_NAME == "keccakn" ]]; then
    echo "{\"a\": \"1\"}" > ./${CIRCUIT_NAME}_input.json
elif [[ $CIRCUIT_NAME == "mimcn" ]]; then
    echo "{\"a\": \"1\"}" > ./${CIRCUIT_NAME}_input.json
elif [[ $CIRCUIT_NAME == "multimimcn" ]]; then
    echo "{\"a\": \"8904385298540932584375984375983427598475\", \"b\": \"11432532454949349845858585855555985734985743987592843759\"}" > ./${CIRCUIT_NAME}_input.json
elif [[ $CIRCUIT_NAME == "mimc_sponge_n" ]]; then
    echo "{\"a\": \"1\"}" > ./${CIRCUIT_NAME}_input.json
elif [[ $CIRCUIT_NAME == "pedersenn" ]]; then
    echo "{\"a\": \"1\"}" > ./${CIRCUIT_NAME}_input.json
elif [[ $CIRCUIT_NAME == "secret_merkle_tree" ]]; then
    echo "{\"keccakLeafs\": [\"1\", \"2\", \"3\", \"4\"], \"secret\": \"10\", \"pathIndices\": [\"0\"]}" > ./${CIRCUIT_NAME}_input.json
elif [[ $CIRCUIT_NAME == "secret_merkle_proof" ]]; then
    echo "{\"keccakLeaf\": [\"1\", \"2\"], \"secret\": \"10\", \"pathIndices\": [\"0\"], \"pathElements\": [\"20720647776736805995271599293687983903163066371706795988900528210329614571103\"], \"root\": \"12496568937140143640907443226343187050369326205835973023618878027235704289017\"}" > ./${CIRCUIT_NAME}_input.json
elif [[ $CIRCUIT_NAME == "QuinSelector" ]]; then
    echo "{\"in\": [\"10\", \"20\"], \"index\": \"0\"}" > ./${CIRCUIT_NAME}_input.json
elif [[ $CIRCUIT_NAME == "shuffled_merkle_tree" ]]; then
    echo "{\"keccakLeafs\": [\"1\", \"2\", \"3\", \"4\"], \"pathIndices\": [\"0\"], \"leafIndices\": [\"1\", \"0\"]}" > ./${CIRCUIT_NAME}_input.json
elif [[ $CIRCUIT_NAME == "vedaMerkleTree" ]]; then
    echo "{\"leafsInTwo\": [[\"1\", \"2\"], [\"3\", \"4\"], [\"5\", \"6\"]], \"pathIndices\": [\"1\", \"0\", \"0\"], \"secretLeaf\": \"100\"}" > ./${CIRCUIT_NAME}_input.json
elif [[ $CIRCUIT_NAME == "vedaMerkleProof" ]]; then
    echo "{\"leafInTwo\": [\"1\", \"2\"], \"secretLeafHash\": \"13280099886815029221288666002737874468148381556221134405564391793586496323681\", \"rootWithSecret\": \"12247190692179946320417539434998885926062420871238534164534302033690612888116\", \"pathElements\": [\"100\", \"7179436869341541572761140212288781131921875879700904991609792924799895462951\"], \"pathIndices\": [\"0\", \"0\"]}" > ./${CIRCUIT_NAME}_input.json
else
    echo "[ERROR] No inputs: create branch for CIRCUIT_NAME '$CIRCUIT_NAME' with input data in run_all.sh script"
    exit 1
fi

echo "Generate witness from ${CIRCUIT_NAME}_input.json, using ${CIRCUIT_NAME}.wasm, saving to ${CIRCUIT_NAME}_witness.wtns"
time \
    node generate_witness.js ${CIRCUIT_NAME}.wasm ./${CIRCUIT_NAME}_input.json \
        ./${CIRCUIT_NAME}_witness.wtns

echo "Starting proving that we have a witness (our ${CIRCUIT_NAME}_input.json in form of ${CIRCUIT_NAME}_witness.wtn)"
echo "Proof and public signals are saved to ${CIRCUIT_NAME}_proof.json and ${CIRCUIT_NAME}_public.json"
time \
    snarkjs groth16 prove ../${CIRCUIT_NAME}.zkey ./${CIRCUIT_NAME}_witness.wtns \
        ./${CIRCUIT_NAME}_proof.json \
        ./${CIRCUIT_NAME}_public.json

echo "Checking proof of knowledge of private inputs for ${CIRCUIT_NAME}_public.json using ${CIRCUIT_NAME}_verification_key.json"
time \
    snarkjs groth16 verify ../${CIRCUIT_NAME}_verification_key.json \
        ./${CIRCUIT_NAME}_public.json \
        ./${CIRCUIT_NAME}_proof.json

echo "Output sizes of client's side files":
echo "[PROFILE]" `du -kh "${CIRCUIT_NAME}.wasm"`
echo "[PROFILE]" `du -kh "${CIRCUIT_NAME}_witness.wtns"`

set +x

