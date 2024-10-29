mod pk_script;
mod merkle_root;

use starknet::ContractAddress;
use consensus::{types::transaction::Transaction};
use utils::hash::Digest;


#[starknet::interface]
pub trait IBitcoinDepositor<TContractState> {
    fn prove_deposit(
        ref self: TContractState,
        deposit_tx: Transaction,
        output_id: usize,
        tx_inclusion: Span<(Digest, bool)>
    );
    fn get_depositor(self: @TContractState) -> ContractAddress;
}

#[starknet::contract]
mod BitcoinDepositor {
    use starknet::{ContractAddress, get_caller_address};
    use consensus::types::transaction::Transaction;
    use utils::hash::Digest;
    use core::num::traits::Zero;
    use crate::pk_script::extract_p2pkh_target;

    #[storage]
    struct Storage {
        depositor: ContractAddress,
    }

    #[abi(embed_v0)]
    impl BitcoinDepositorImpl of super::IBitcoinDepositor<ContractState> {
        fn prove_deposit(
            ref self: ContractState,
            deposit_tx: Transaction,
            output_id: usize,
            tx_inclusion: Span<(Digest, bool)>
        ) {
            assert(self.depositor.read() == Zero::zero(), 'too late, someone deposited');

            // the depositor tells us which output to check
            let output_to_check = deposit_tx.outputs[output_id];

            // we verify its amount
            assert(*output_to_check.value > 100_000_000_u64, 'you sent less than 1 BTC');

            // we verify this is a P2PKH and we are the receiver
            assert(
                extract_p2pkh_target(*output_to_check.pk_script) == "1NpDmDPRJX1yoke5qhrUQBKBByWqFSQ17A",
                'wrong receiver'
            );

            // if all good, we update the receiver
            self.depositor.write(get_caller_address());
        }

        fn get_depositor(self: @ContractState) -> ContractAddress {
            self.depositor.read()
        }
    }
}
