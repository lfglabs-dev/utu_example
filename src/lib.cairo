use starknet::ContractAddress;
use consensus::{types::transaction::Transaction};

#[starknet::interface]
pub trait IBitcoinDepositor<TContractState> {
    fn prove_deposit(ref self: TContractState, deposit_tx: Transaction);
    fn get_depositor(self: @TContractState) -> ContractAddress;
}

#[starknet::contract]
mod BitcoinDepositor {
    use starknet::ContractAddress;
    use consensus::{types::transaction::Transaction, codec::Encode};
    use utils::{hash::Digest, double_sha256::double_sha256_byte_array};

    #[storage]
    struct Storage {
        depositor: ContractAddress,
    }

    #[abi(embed_v0)]
    impl BitcoinDepositorImpl of super::IBitcoinDepositor<ContractState> {
        fn prove_deposit(ref self: ContractState, deposit_tx: Transaction) {
            let _tx_id: Digest = double_sha256_byte_array(@deposit_tx.encode());
        }

        fn get_depositor(self: @ContractState) -> ContractAddress {
            self.depositor.read()
        }
    }
}
