use std::{collections::HashMap, env::current_dir, time::Instant};

use nova_scotia::{
    circom::reader::load_r1cs, create_public_params,
    create_recursive_circuit, FileLocation, F, 
};
use nova_snark::{provider, PublicParams, CompressedSNARK};
use serde_json::json;

fn main() {
    let iteration_count = 5;
    let root = current_dir().unwrap();
    type G1 = provider::bn256_grumpkin::bn256::Point;
    type G2 = provider::bn256_grumpkin::grumpkin::Point;

    let circuit_file = root.join("build/toy.r1cs");
    let witness_generator_file = root.join("build/toy_js/toy.wasm");
    let fl = FileLocation::PathBuf(circuit_file);
    let s0 = Instant::now();
    println!("Loading R1CS file...");
    let r1cs = load_r1cs::<G1, G2>(&fl); // loads R1CS file into memory
    println!("R1CS file loaded in {:?}", s0.elapsed());

    // Create private_inputs.
    let s1 = Instant::now();
    println!("Creating private inputs...");
    let mut private_inputs = Vec::new();
    for i in 0..iteration_count {
        let mut private_input = HashMap::new();
        private_input.insert("adder".to_string(), json!(i));
        private_inputs.push(private_input);
    }
    println!("Private Inputs created in {:?}", s1.elapsed());

    let s3 = Instant::now();
    println!("Creating public params...");
    let start_public_input = [F::<G1>::from(10)];
    let pp: PublicParams<G1, G2, _, _> = create_public_params(r1cs.clone());
    println!("Public params created in {:?}", s3.elapsed());

    let s2 = Instant::now();
    println!("Creating a RecursiveSNARK...");
    let recursive_snark = create_recursive_circuit(
        FileLocation::PathBuf(witness_generator_file),
        r1cs,
        private_inputs,
        start_public_input.to_vec(),
        &pp,
    ).unwrap();
    println!("RecursiveSNARK created in {:?}", s2.elapsed());

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
    assert!(res.is_ok());

    // let compressedSNARK = CompressedSNARK::<<G1, G2, C1<G1>, C2<G2>>::setup(&pp).unwrap();

}