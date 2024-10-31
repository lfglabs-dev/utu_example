mod pk_script;
mod merkle_root;
#[cfg(test)]
mod tests;

use starknet::ContractAddress;
use consensus::{types::transaction::Transaction};
use utils::hash::Digest;
use utu_relay::bitcoin::block::BlockHeader;

#[starknet::interface]
pub trait IBitcoinDepositor<TContractState> {
    fn prove_deposit(
        ref self: TContractState,
        deposit_tx: Transaction,
        output_id: usize,
        block_height: u64,
        block_header: BlockHeader,
        tx_inclusion: Array<(Digest, bool)>
    );
    fn get_depositor(self: @TContractState) -> ContractAddress;
}

#[starknet::contract]
mod BitcoinDepositor {
    use crate::{pk_script::extract_p2pkh_target, merkle_root::compute_merkle_root};
    use utu_relay::bitcoin::block::BlockHashTrait;
    use starknet::{ContractAddress, get_caller_address};
    use consensus::{codec::Encode, types::transaction::Transaction};
    use utils::{hash::Digest, double_sha256::double_sha256_byte_array};
    use core::num::traits::Zero;
    use utu_relay::{
        interfaces::{IUtuRelayDispatcher, IUtuRelayDispatcherTrait}, bitcoin::block::BlockHeader
    };

    #[storage]
    struct Storage {
        depositor: ContractAddress,
        utu_address: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, utu_address: ContractAddress) {
        self.utu_address.write(utu_address);
    }

    #[abi(embed_v0)]
    impl BitcoinDepositorImpl of super::IBitcoinDepositor<ContractState> {
        fn prove_deposit(
            ref self: ContractState,
            deposit_tx: Transaction,
            output_id: usize,
            block_height: u64,
            block_header: BlockHeader,
            tx_inclusion: Array<(Digest, bool)>
        ) {
            assert(self.depositor.read() == Zero::zero(), 'too late, someone deposited');

            // the depositor tells us which output to check
            let output_to_check = deposit_tx.outputs[output_id];

            // we verify its amount
            assert(*output_to_check.value > 100_000_000_u64, 'you sent less than 1 BTC');

            // we verify this is a P2PKH and we are the receiver
            let tx_bytes_legacy = @deposit_tx.encode();
            let txid = double_sha256_byte_array(tx_bytes_legacy);
            println!("txid: {}", txid);

            let target = extract_p2pkh_target(*output_to_check.pk_script);
            println!("target: {}", target);

            println!("yolo");

            // assert(target == "1LgXWxpELt2o9hPGiwqDT1B5Z7994MQPTN", 'wrong receiver');

            let merkle_root = compute_merkle_root(txid, tx_inclusion);
            assert(
                block_header.merkle_root_hash.value == merkle_root.value, 'invalid inclusion proof'
            );
            let block_digest = block_header.hash();
            println!("block_digest: {}", block_digest);

            let utu = IUtuRelayDispatcher { contract_address: self.utu_address.read() };
            let canonical_block_digest = utu.get_block(block_height);
            assert(canonical_block_digest == block_digest, 'invalid block digest');

            // if all good, we update the receiver
            self.depositor.write(get_caller_address());
        }

        fn get_depositor(self: @ContractState) -> ContractAddress {
            self.depositor.read()
        }
    }
}
