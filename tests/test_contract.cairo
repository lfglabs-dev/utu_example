use starknet::ContractAddress;

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};
use utu_example::IBitcoinDepositorDispatcher;
use utu_example::IBitcoinDepositorDispatcherTrait;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

#[test]
fn test_deposit() {
    let contract_address = deploy_contract("BitcoinDepositor");
    let dispatcher = IBitcoinDepositorDispatcher { contract_address };
    let depositor = dispatcher.get_depositor();

    
    // assert(balance_before == 0, 'Invalid initial depositor');
// let depositor_after = dispatcher.get_balance();
// assert(depositor_after == 42, 'Invalid depositor');
}

