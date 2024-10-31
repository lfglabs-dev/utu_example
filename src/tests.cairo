use starknet::contract_address_const;
use core::num::traits::Zero;
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address_global,
    stop_cheat_caller_address_global
};
use utu_example::{IBitcoinDepositorDispatcher, IBitcoinDepositorDispatcherTrait};
use consensus::{types::transaction::{Transaction, TxIn, TxOut, OutPoint}};
use utils::{hex::{from_hex, hex_to_hash_rev}, hash::DigestImpl};
use utu_relay::{
    interfaces::{IUtuRelayDispatcher, IUtuRelayDispatcherTrait, HeightProof},
    bitcoin::block::{BlockHeaderTrait, BlockHashImpl}
};

fn deploy_contracts() -> (IBitcoinDepositorDispatcher, IUtuRelayDispatcher) {
    let contract = declare("UtuRelay").unwrap().contract_class();
    let (utu_contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();

    let contract = declare("BitcoinDepositor").unwrap().contract_class();
    let (btc_contract_address, _) = contract.deploy(@array![utu_contract_address.into()]).unwrap();

    (
        IBitcoinDepositorDispatcher { contract_address: btc_contract_address },
        IUtuRelayDispatcher { contract_address: utu_contract_address }
    )
}

#[test]
fn test_deposit() {
    let (bitcoin_depositor, utu) = deploy_contracts();
    let caller = contract_address_const::<123>();
    start_cheat_caller_address_global(caller);
    let depositor_before = bitcoin_depositor.get_depositor();
    assert_eq!(depositor_before, Zero::zero());
    // tx fa89c32152bf324cd1d47d48187f977c7e0f380f6f78132c187ce27923f62fcc
    let tx = Transaction {
        version: 2_u32,
        is_segwit: false,
        inputs: array![
            TxIn {
                script: @from_hex(
                    "483045022100b48355267ec0dd5d542cf91e8af4d6dbe7aab97c38cdaa0d11388982ecd21682022001ca88ae99dfc199c9dc3244e77c0c07d54e3a67a66a61defab376f9a5b512400141043577d3135275fdc03da1665722e40ca4e5737d9b8ab4685994a9cdaef7fe15a5e13a6584221d1d7eeabc6a8725bad898cf0233631912a259cba2b8e34f167d9c"
                ),
                sequence: 0xffffffff,
                previous_output: OutPoint {
                    txid: hex_to_hash_rev(
                        "8813df6d1acff8f7cadbd54734616f0391074d05ba8aeb3a5a9469ce50af4860"
                    ),
                    vout: 1_u32,
                    data: Default::default(),
                    block_height: Default::default(),
                    median_time_past: Default::default(),
                    is_coinbase: false,
                },
                witness: array![].span()
            }
        ]
            .span(),
        outputs: array![
            TxOut {
                value: 100043947_u64, // 1.00043947 BTC in satoshis
                pk_script: @from_hex("76a914d7e4161c4e2d4a5cd559d8accf208a2df867873088ac"),
                cached: false,
            }
        ]
            .span(),
        lock_time: 0
    };

    let siblings = array![
        (hex_to_hash_rev("51062a1510fc7ebc1d673412524b7073bb5175681e91f2fc892269aa65bfeaa7"), true),
        (
            hex_to_hash_rev("c15911a240d89d1c8a573076e196430ceda007876ca90c519e4a7f6ff79739e0"),
            false
        ),
        (
            hex_to_hash_rev("2d8485381c1c75e7cc1c52b069624a8af7fd0e5e981b2d9ea61ed38e774a9f20"),
            false
        ),
        (
            hex_to_hash_rev("8fb144635252fd1be34ef99355fdd2fa2c78e625faf746f66ad10af5a21b7a5c"),
            false
        ),
        (
            hex_to_hash_rev("849bff3bc184ae0df0b3d3bb560a68186cb711eb3a83dbfa890a4e6cc2487a47"),
            false
        ),
        (
            hex_to_hash_rev("c3e238ef8453b701b200ad05c5fbf88e2928589be3a3808687e1e2dd3d540170"),
            false
        ),
        (
            hex_to_hash_rev("82efe04d29ce3f27e71df0d496b24ec420b193d38e6e2c6b9dc126c08aad31cf"),
            false
        ),
        (
            hex_to_hash_rev("749d481a6c62fb88d3cf7a768cc50bbc02e8968d5e1151222ee939c87b4ade7c"),
            false
        ),
        (
            hex_to_hash_rev("f22343dd5c840c82a12afb0f0961dfebd73f568783cdfb5d9bd7531095922b04"),
            false
        ),
        (
            hex_to_hash_rev("3a23346a49a08e95cca72b16f93bb92aa115e66343b8ca58deba4fe02f52c397"),
            false
        ),
        (
            hex_to_hash_rev("c05714916a7088e105377682944fc1d04c295c378b560f2a643a2a584a706b98"),
            false
        ),
        (
            hex_to_hash_rev("0e962a3c3aa944fa042e035851b2aa3c2c4a5173344684e7c2291ead8940a2b7"),
            false
        ),
    ];

    let block_868239 = BlockHeaderTrait::new(
        744677376_u32, // version (0x2c62e000)
        hex_to_hash_rev(
            "00000000000000000001f9fb950ed8f038fd2cc7330de564ba35c30fc5a7683e"
        ), // prev_block_hash
        hex_to_hash_rev(
            "178d1d365faba2ca73698bce4bd4abf69a19b56047c910c00ac403d3bfe9c31f"
        ), // merkle_root_hash
        1730373503_u32, // time
        0x1702f128_u32, // bits
        3748435122_u32, // nonce
    );

    let coinbase_raw_tx = from_hex(
        "01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff56038f3f0d194d696e656420627920416e74506f6f6c2021000f0465ccbb9dfabe6d6d07cf5e92a794c3e9c45e6bacf77e99d91c0e84e28405b04689c16c85ec82c28c10000000000000000000a69f22345e0100000000ffffffff05220200000000000017a91442402a28dd61f2718a4b27ae72a4791d5bbdade787ee323b130000000017a9145249bdf2c131d43995cff42e8feee293f79297a8870000000000000000266a24aa21a9ed882945dcdbaa7c817c5f0dfb25b735f05feef3a9ad1fb6e697d448af5146da6600000000000000002f6a2d434f52450142fdeae88682a965939fee9b7b2bd5b99694ff644e3ecda72cb7961caa4b541b1e322bcfe0b5a03000000000000000002b6a2952534b424c4f434b3a05ffec80772cb05eb6ffbe3558185800635415e4aac8225ca7dad9080068928b00000000"
    );

    let merkle_branch = [
        hex_to_hash_rev("fa89c32152bf324cd1d47d48187f977c7e0f380f6f78132c187ce27923f62fcc"),
        hex_to_hash_rev("c15911a240d89d1c8a573076e196430ceda007876ca90c519e4a7f6ff79739e0"),
        hex_to_hash_rev("2d8485381c1c75e7cc1c52b069624a8af7fd0e5e981b2d9ea61ed38e774a9f20"),
        hex_to_hash_rev("8fb144635252fd1be34ef99355fdd2fa2c78e625faf746f66ad10af5a21b7a5c"),
        hex_to_hash_rev("849bff3bc184ae0df0b3d3bb560a68186cb711eb3a83dbfa890a4e6cc2487a47"),
        hex_to_hash_rev("c3e238ef8453b701b200ad05c5fbf88e2928589be3a3808687e1e2dd3d540170"),
        hex_to_hash_rev("82efe04d29ce3f27e71df0d496b24ec420b193d38e6e2c6b9dc126c08aad31cf"),
        hex_to_hash_rev("749d481a6c62fb88d3cf7a768cc50bbc02e8968d5e1151222ee939c87b4ade7c"),
        hex_to_hash_rev("f22343dd5c840c82a12afb0f0961dfebd73f568783cdfb5d9bd7531095922b04"),
        hex_to_hash_rev("3a23346a49a08e95cca72b16f93bb92aa115e66343b8ca58deba4fe02f52c397"),
        hex_to_hash_rev("c05714916a7088e105377682944fc1d04c295c378b560f2a643a2a584a706b98"),
        hex_to_hash_rev("0e962a3c3aa944fa042e035851b2aa3c2c4a5173344684e7c2291ead8940a2b7")
    ].span();
    let height_proof = Option::Some(
        HeightProof { header: block_868239, coinbase_raw_tx, merkle_branch }
    );

    utu.register_blocks(array![block_868239].span());
    utu.update_canonical_chain(868239, 868239, block_868239.hash(), height_proof);
    bitcoin_depositor.prove_deposit(tx, 0, 868239, block_868239, siblings);

    // let depositor_after = bitcoin_depositor.get_depositor();
    // assert(depositor_after == caller, 'Invalid depositor');
    stop_cheat_caller_address_global();
}

