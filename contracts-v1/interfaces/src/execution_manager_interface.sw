library;

abi ExecutionManager {
    #[storage(read, write)]
    fn initialize();

    #[storage(read, write)]
    fn add_strategy(strategy: ContractId);

    #[storage(read, write)]
    fn remove_strategy(index: u64);

    #[storage(read)]
    fn is_strategy_whitelisted(strategy: ContractId) -> bool;

    #[storage(read)]
    fn get_whitelisted_strategy(index: u64) -> Option<ContractId>;

    #[storage(read)]
    fn get_count_whitelisted_strategies() -> u64;

    // Ownable
    #[storage(read)]
    fn owner() -> Option<Identity>;

    #[storage(read, write)]
    fn transfer_ownership(new_owner: Identity);

    #[storage(read, write)]
    fn renounce_ownership();
}
