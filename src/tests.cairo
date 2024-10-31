use starknet::contract_address_const;
use core::num::traits::Zero;
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address_global,
    stop_cheat_caller_address_global
};
use utu_example::{IBitcoinDepositorDispatcher, IBitcoinDepositorDispatcherTrait};
use consensus::{types::transaction::{Transaction, TxIn, TxOut, OutPoint}};
use utils::hex::{from_hex, hex_to_hash_rev};
use utu_relay::{
    interfaces::{IUtuRelayDispatcher, IUtuRelayDispatcherTrait}, utils::hash::Digest,
    bitcoin::block::{BlockHeader, BlockHeaderTrait, BlockHashImpl}
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
    // tx 4ff32a7e58200897220ce4615e30e3e414991222d7eda27e693116abea8b8f33
    let tx = Transaction {
        version: 1_u32,
        is_segwit: false,
        inputs: array![
            TxIn {
                script: @from_hex(
                    "493046022100838b5bd094d57898d359569af330312e2dd99f8a1db7add92dc1704808625dbf022100978160771ea1e3ffe014e1fa7559f0bb5ffd32f6b63f19225bf3be110c2f2d65014104c273b18442afb2263698a09da205bb7a18f23037f9c285fc789874fe012ac32b40a18f12191a0015f2506b5a395d9845005b90a34a813715e9cc5dbf8024ca18"
                ),
                sequence: 0xffffffff,
                previous_output: OutPoint {
                    txid: hex_to_hash_rev(
                        "b8a75476112bb2322af0331646100fe44f26fee85f452001589f6d9672b763a7"
                    ),
                    vout: 0_u32,
                    data: Default::default(),
                    block_height: Default::default(),
                    median_time_past: Default::default(),
                    is_coinbase: false,
                },
                witness: array![].span()
            },
            TxIn {
                script: @from_hex(
                    "48304502200b2ff9ed1689c9403b4bf0aca89fa4a53004c2c6ad66b4df25ae8361eef172cc022100c8f5fcd4eeb02762d9b40de1013ad7283042585caec8e60be873689de8e29a4a014104cdadb5199b0d9d356ae03fbf891f28d761547d79a0c5dae24998fa84a147e39f27ce03cd8efd8bd27e9dffc78744d66b2942b76801f79ae4028028e7122a3bb1"
                ),
                sequence: 0xffffffff,
                previous_output: OutPoint {
                    txid: hex_to_hash_rev(
                        "a7ed5e908fa1951c912fd39cd72a37410ca78fc75de65180b8568a622f4e3a97"
                    ),
                    vout: 1_u32,
                    data: Default::default(),
                    block_height: Default::default(),
                    median_time_past: Default::default(),
                    is_coinbase: false,
                },
                witness: array![].span()
            },
            TxIn {
                script: @from_hex(
                    "493046022100f814323e8be180dd90d063adb8f94b31801fb68ce97eb1acb32970a390bfa72f02210085ed8af17e90e2415d400d7cb08311535243d55461be9982bb3408271aa954aa0141045d21d60c22da05383ef130e3fc314b28c7dd378c762931f8c85e5e708d97b9779d83135a8c3cfe202f435e2781c99329043080627c5eb71f73be103fe45c2028"
                ),
                sequence: 0xffffffff,
                previous_output: OutPoint {
                    txid: hex_to_hash_rev(
                        "66ce602f26ae00d128ea83e5afddf8c1cd226b7148322bb090779199f63f9ff5"
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
                value: 1050000_u64,
                pk_script: @from_hex("76a914bafe7b8f25824ff18f698d2878d50c6fc43dd1d088ac"),
                cached: false,
            },
            TxOut {
                value: 111950000_u64,
                pk_script: @from_hex("76a914ef48d8584b96d95992a664d524e52007b036754188ac"),
                cached: false,
            }
        ]
            .span(),
        lock_time: 0
    };

    let siblings = array![
        (hex_to_hash_rev("8bfa0f7edb3caa2a3e8e028cf5fa196d078e6f9d7b9f2699f79f28bb181f8566"), true),
        (hex_to_hash_rev("8a5d61f4ba10158897cce12d0224112e7471c001ff787cd0678b9283140a6bc6"), true),
        (hex_to_hash_rev("c2c314fd9e672b70e9b8463a542fbc97400e3bed8702ebf0227d9725e7a8a120"), true),
        (
            hex_to_hash_rev("568eaa8a3c36b3123abc0d28fbc9a6db7bbf8f42158d44e3b747762354378dda"),
            false
        ),
        (hex_to_hash_rev("2675bcd84c5bcb94ead1ffc9986f7c011bac7fc9af3504d9769a949a76ae9026"), true),
        (
            hex_to_hash_rev("81c29c6d2d2841c1230817a968e1260185f064131dbbbd415be570e55582b097"),
            false
        ),
    ];

    let prev_block_hash = Digest {
        value: [
            0xe49d58fa,
            0xd7aaf349,
            0xe0ef1656,
            0x64426db5,
            0x5fccb192,
            0x24c2b614,
            0xd4060000,
            0x00000000
        ]
    };
    let merkle_root_hash = Digest {
        value: [
            0x80934c0b,
            0xd904cdef,
            0xfa531241,
            0x48822847,
            0xe3699edb,
            0x1cef7ae7,
            0x185fca78,
            0x74935aa2
        ]
    };
    let block_150013 = BlockHeader {
        version: 0x01000000,
        prev_block_hash,
        merkle_root_hash,
        time: 0x9c4fa04e,
        bits: 0x1a0b6d4b,
        nonce: 0x2c70a6d8,
    };
    println!("hash: {}", block_150013.hash());

    // utu.register_blocks(array![block_150013].span());

    // bitcoin_depositor.prove_deposit(tx, 1, 150013, block_150013, siblings);

    // let depositor_after = bitcoin_depositor.get_depositor();
    // assert(depositor_after == caller, 'Invalid depositor');
    stop_cheat_caller_address_global();
}




