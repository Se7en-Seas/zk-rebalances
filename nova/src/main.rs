use std::{collections::HashMap, env::current_dir, time::Instant, path::{Path, PathBuf}};

use nova_scotia::{
    circom::reader::load_r1cs, create_public_params,
    create_recursive_circuit, FileLocation, F, S,
};
use nova_snark::{provider, CompressedSNARK, PublicParams};
use serde_json::json;

fn main() {
    let iteration_count = 5;
    let root = current_dir().unwrap();
    type G1 = provider::bn256_grumpkin::bn256::Point;
    type G2 = provider::bn256_grumpkin::grumpkin::Point;

    let circuit_file = root.join("toy.r1cs");
    let witness_generator_file = root.join("toy_js/toy.wasm");
    let fl = FileLocation::PathBuf(circuit_file);

    let r1cs = load_r1cs::<G1, G2>(&fl); // loads R1CS file into memory

    let pp = create_public_params::<G1, G2>(r1cs.clone());

    // Create private_inputs.
    let mut private_inputs = Vec::new();
    for i in 0..iteration_count {
        let mut private_input = HashMap::new();
        private_input.insert("adder".to_string(), json!(i));
        private_inputs.push(private_input);
    }

    let start_public_input = [F::<G1>::from(10), F::<G1>::from(10)];

    let pp: PublicParams<G1, G2, _, _> = create_public_params(r1cs.clone());

    let recursive_snark = create_recursive_circuit(
        FileLocation::PathBuf(witness_generator_file),
        r1cs,
        private_inputs,
        start_public_input.to_vec(),
        &pp,
    ).unwrap();

    println!("Verifying a RecursiveSNARK...");
    let start = Instant::now();
    let res = recursive_snark.verify(
        &pp,
        iteration_count,
        &start_public_input.clone(),
        &[F::<G2>::zero()],
    );
    println!(
        "RecursiveSNARK::verify: {:?}, took {:?}",
        res,
        start.elapsed()
    );
    let verifier_time = start.elapsed();
    assert!(res.is_ok());
}