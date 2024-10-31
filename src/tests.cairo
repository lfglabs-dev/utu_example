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

    // utu.register_blocks(array![block_150013].span());

    bitcoin_depositor.prove_deposit(tx, 0, 868239, block_150013, siblings);

    // let depositor_after = bitcoin_depositor.get_depositor();
    // assert(depositor_after == caller, 'Invalid depositor');
    stop_cheat_caller_address_global();
}

