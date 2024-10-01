library;

abi Pool {
    #[storage(read, write)]
    fn initialize(exchange: ContractId, asset_manager: ContractId);

    fn total_supply(asset: AssetId) -> u64;

    #[storage(read)]
    fn balance_of(account: Identity, asset: AssetId) -> u64;

    #[storage(read, write), payable]
    fn deposit();

    #[storage(read, write)]
    fn withdraw(asset: AssetId, amount: u64);

    #[storage(read, write)]
    fn transfer_from(from: Identity, to: Identity, asset: AssetId, amount: u64) -> bool;

    #[storage(read, write)]
    fn set_exchange(exchange_contract: ContractId);

    #[storage(read, write)]
    fn set_asset_manager(asset_manager: ContractId);

    #[storage(read)]
    fn get_asset_manager() -> ContractId;

    #[storage(read)]
    fn get_exchange() -> ContractId;

    // Ownable
    #[storage(read)]
    fn owner() -> Option<Identity>;

    #[storage(read, write)]
    fn transfer_ownership(new_owner: Identity);

    #[storage(read, write)]
    fn renounce_ownership();
}
