library;

use std::{contract_id::ContractId, identity::Identity};

abi TransferManager {
    #[storage(read, write)]
    fn initialize(exchange_contract: ContractId);

    #[storage(read)]
    fn transfer_nft(
        collection: ContractId,
        from: Identity,
        to: Identity,
        token_id: u64,
        amount: u64
    );

    #[storage(read)]
    fn get_exchange() -> ContractId;
}
