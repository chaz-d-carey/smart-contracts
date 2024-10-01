library;

pub struct RoyaltyInfo {
    pub collection: ContractId,
    pub receiver: Identity,
    pub fee: u64
}

pub struct RoyaltyRegistryEvent {
    pub royalty_info: RoyaltyInfo
}

abi RoyaltyManager {
    #[storage(read, write)]
    fn initialize();

    #[storage(read, write)]
    fn register_royalty_info(
        collection: ContractId,
        receiver: Identity,
        fee: u64
    );

    #[storage(read)]
    fn get_royalty_info(collection: ContractId) -> Option<RoyaltyInfo>;

    #[storage(read, write)]
    fn set_royalty_fee_limit(fee_limit: u64);

    #[storage(read)]
    fn get_royalty_fee_limit() -> u64;

    // Ownable
    #[storage(read)]
    fn owner() -> Option<Identity>;

    #[storage(read, write)]
    fn transfer_ownership(new_owner: Identity);

    #[storage(read, write)]
    fn renounce_ownership();
}
