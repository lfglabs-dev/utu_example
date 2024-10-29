use starknet::contract_address_const;
use core::num::traits::Zero;
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address_global,
    stop_cheat_caller_address_global
};
use utu_example::{IBitcoinDepositorDispatcher, IBitcoinDepositorDispatcherTrait};
use consensus::{types::transaction::{Transaction, TxIn, TxOut, OutPoint}};
use utils::hex::{from_hex, hex_to_hash_rev};

fn deploy_contract(name: ByteArray) -> IBitcoinDepositorDispatcher {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    IBitcoinDepositorDispatcher { contract_address }
}

#[test]
fn test_deposit() {
    let bitcoin_depositor = deploy_contract("BitcoinDepositor");
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

    let inclusion_proof = array![];
    bitcoin_depositor.prove_deposit(tx, 1, inclusion_proof.span());
    let depositor_after = bitcoin_depositor.get_depositor();
    assert(depositor_after == caller, 'Invalid depositor');
    stop_cheat_caller_address_global();
}

