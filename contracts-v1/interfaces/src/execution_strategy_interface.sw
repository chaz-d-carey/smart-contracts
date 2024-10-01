library;

use libraries::{
    order_types::*,
    execution_result::*,
};

abi ExecutionStrategy {
    #[storage(read, write)]
    fn initialize(exchange: ContractId, fee: u64);

    #[storage(read, write)]
    fn execute_order(order: TakerOrder) -> ExecutionResult;

    #[storage(read, write)]
    fn place_order(order: MakerOrder);

    #[storage(read, write)]
    fn update_order(order: MakerOrder);

    #[storage(read, write)]
    fn cancel_order(
        maker: Address,
        nonce: u64,
        side: Side
    );

    #[storage(read, write)]
    fn set_exchange(exchange_contract: ContractId);

    #[storage(read, write)]
    fn set_protocol_fee(fee: u64);

    #[storage(read)]
    fn get_protocol_fee() -> u64;

    #[storage(read)]
    fn get_exchange() -> ContractId;

    #[storage(read)]
    fn get_maker_order_of_user(
        user: Address,
        nonce: u64,
        side: Side
    ) -> Option<MakerOrder>;

    #[storage(read)]
    fn is_valid_order(
        user: Address,
        nonce: u64,
        side: Side
    ) -> bool;

    #[storage(read)]
    fn get_order_nonce_of_user(user: Address, side: Side) -> u64;

    #[storage(read)]
    fn get_min_order_nonce_of_user(user: Address, side: Side) -> u64;

    // Ownable
    #[storage(read)]
    fn owner() -> Option<Identity>;

    #[storage(read, write)]
    fn transfer_ownership(new_owner: Identity);

    #[storage(read, write)]
    fn renounce_ownership();
}
