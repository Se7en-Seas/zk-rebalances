use std::{collections::HashMap, env::current_dir, time::Instant};

use nova_scotia::{
    circom::reader::load_r1cs, create_public_params,
    create_recursive_circuit, FileLocation, F, S
};
use nova_snark::{provider, PublicParams, CompressedSNARK};
use serde_json::json;

// TODO functionize this like the zator code.
fn main() {
    let iteration_count = 2;
    let root = current_dir().unwrap();
    type G1 = provider::bn256_grumpkin::bn256::Point;
    type G2 = provider::bn256_grumpkin::grumpkin::Point;
    // type G1 = pasta_curves::pallas::Point;
    // type G2 = pasta_curves::vesta::Point;

    let circuit_file = root.join("build/recursiveVedaMerkleProof.r1cs");
    let witness_generator_file = root.join("build/recursiveVedaMerkleProof_js/recursiveVedaMerkleProof.wasm");
    let fl = FileLocation::PathBuf(circuit_file);
    let s0 = Instant::now();
    println!("Loading R1CS file...");
    let r1cs = load_r1cs::<G1, G2>(&fl); // loads R1CS file into memory
    println!("R1CS file loaded in {:?}", s0.elapsed());

    // Create private_inputs.
    let s1 = Instant::now();
    println!("Creating private inputs...");
    let mut private_inputs = Vec::new();
    let mut private_input_0 = HashMap::new();
    private_input_0.insert("leaf".to_string(), json!("19321998414906712342737093331922571923461328494325615870852140381009276079041"));
    private_input_0.insert("pathElements".to_string(), json!(["556394723030469102187691977268492641419685995573696209705695064770672291535"]));
    private_input_0.insert("pathIndices".to_string(), json!([0]));
    private_input_0.insert("expectedStepDigest".to_string(), json!("5278850737375532418257002990256989970442868547265647747102965515540374714661"));
    private_inputs.push(private_input_0);

    let mut private_input_1 = HashMap::new();
    private_input_1.insert("leaf".to_string(), json!("556394723030469102187691977268492641419685995573696209705695064770672291535"));
    private_input_1.insert("pathElements".to_string(), json!(["19321998414906712342737093331922571923461328494325615870852140381009276079041"]));
    private_input_1.insert("pathIndices".to_string(), json!([1]));
    private_input_1.insert("expectedStepDigest".to_string(), json!("6026633109103954617425446211766921388684641560832459945905859224654515400382"));
    private_inputs.push(private_input_1);


    // for i in 0..iteration_count {
    //     let mut private_input = HashMap::new();
    //     private_input.insert("leaf".to_string(), json!(i));
    //     private_inputs.push(private_input);
    // }
    println!("Private Inputs created in {:?}", s1.elapsed());

    let s3 = Instant::now();
    println!("Creating public params...");
    let start_public_input = [F::<G1>::from(1), F::<G1>::from(0), F::<G1>::from_raw([16562997167074987800,11743143821083967037, 9598410008986871971, 1418635740345084031])];
    // let start_public_input = [F::<G1>::from(10)];
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

    println!("Compressing a RecursiveSNARK...");
    let s4 = Instant::now();
    let (pk, vk) = CompressedSNARK::<_,_,_,_, S<G1>, S<G2>>::setup(&pp).unwrap();
    let res = CompressedSNARK::<_,_,_,_, S<G1>, S<G2>>::prove(&pp, &pk, &recursive_snark);

    println!(
        "CompressedSNARK::prove: {:?}, took {:?}",
        res.is_ok(),
        s4.elapsed()
    );
    assert!(res.is_ok());

    // Below is what would go to operators.
    let compressed_snark = res.unwrap();

    let z0_secondary = [F::<G2>::from(0)];

    // verify the compressed SNARK
    println!("Verifying a CompressedSNARK...");
    let s5 = Instant::now();
    let res = compressed_snark.verify(
        &vk,
        iteration_count,
        start_public_input.to_vec(),
        z0_secondary.to_vec(),
    );
    println!(
        "CompressedSNARK::verify: {:?}, took {:?}",
        res.is_ok(),
        s5.elapsed()
    );
    assert!(res.is_ok());
    println!(
        "CompressedSNARK::verify output: {:?}",
        res
    );

}