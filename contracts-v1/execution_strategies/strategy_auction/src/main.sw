contract;

mod errors;

use interfaces::{
    execution_strategy_interface::ExecutionStrategy,
    thunder_exchange_interface::ThunderExchange,
    royalty_manager_interface::*
};

use libraries::{
    execution_result::*,
    msg_sender_address::*,
    order_types::*,
    ownable::*,
    constants::*,
};
use errors::*;

use std::{
    block::timestamp,
    call_frames::*,
    contract_id::ContractId,
    hash::Hash,
    revert::*,
    storage::storage_map::*
};

storage {
    is_initialized: bool = false,
    owner: Ownership = Ownership::uninitialized(),
    protocol_fee: u64 = 0,
    exchange: Option<ContractId> = Option::None,

    auction_item: StorageMap<(ContractId, SubId), Option<MakerOrder>> = StorageMap {},
    auction_highest_bid: StorageMap<(ContractId, SubId), Option<MakerOrder>> = StorageMap {},

    sell_order: StorageMap<(Address, u64), Option<MakerOrder>> = StorageMap {},
    user_sell_order_nonce: StorageMap<Address, u64> = StorageMap {},
    user_min_sell_order_nonce: StorageMap<Address, u64> = StorageMap {},
}

/// !!! INFO !!! This contract is out of the scope
impl ExecutionStrategy for Contract {
    #[storage(read, write)]
    fn initialize(exchange: ContractId) {
        require(
            !_is_initialized(),
            StrategyAuctionErrors::Initialized
        );
        storage.is_initialized.write(true);

        let caller = get_msg_sender_address_or_panic();
        storage.owner.set_ownership(Identity::Address(caller));
        storage.exchange.write(Option::Some(exchange));
    }

    #[storage(read, write)]
    fn place_order(order: MakerOrder) {
        only_exchange();

        match order.side {
            Side::Buy => {
                _place_buy_order(order)
            },
            Side::Sell => {
                //_validate_token_balance_and_approval(order, token_type);
                _place_sell_order(order)
            }
        }
    }

    #[storage(read, write)]
    fn update_order(order: MakerOrder) {
        only_exchange();

        match order.side {
            Side::Buy => {
                _place_buy_order(order)
            },
            Side::Sell => {
                //_validate_token_balance_and_approval(order, token_type);
                _place_sell_order(order)
            }
        }
    }

    #[storage(read, write)]
    fn cancel_order(
        maker: Address,
        nonce: u64,
        side: Side
    ) {
        only_exchange();

        match side {
            Side::Buy => (),
            Side::Sell => {
                let sell_order = _sell_order(maker, nonce);
                require(
                    _is_valid_order(sell_order),
                    StrategyAuctionErrors::OrderCancelledOrExpired
                );
                let none: Option<MakerOrder> = Option::None;
                storage.sell_order.insert((maker, nonce), none);
                storage.auction_item.insert(
                    (
                        sell_order.unwrap().collection,
                        sell_order.unwrap().token_id
                    ),
                    none
                );
            },
        }
    }

    #[storage(read, write)]
    fn execute_order(order: TakerOrder) -> ExecutionResult {
        only_exchange();

        let auction = _auction_item(order.collection, order.token_id);
        let highest_bid = match order.side {
            Side::Buy => Option::None,
            Side::Sell => _auction_highest_bid(order.collection, order.token_id),
        };

        if (highest_bid.is_none()) {
            return ExecutionResult {
                is_executable: false,
                collection: ZERO_CONTRACT_ID,
                token_id: ZERO_B256,
                amount: 0,
                payment_asset: ZERO_ASSET_ID,
            }
        }

        let execution_result = ExecutionResult::s2(auction.unwrap(), highest_bid.unwrap());
        if (execution_result.is_executable) {
            _execute_order(auction.unwrap());
        }

        execution_result
    }

    #[storage(read, write)]
    fn set_exchange(exchange_contract: ContractId) {
        storage.owner.only_owner();

        storage.exchange.write(Option::Some(exchange_contract));
    }

    #[storage(read, write)]
    fn set_protocol_fee(fee: u64) {
        storage.owner.only_owner();

        require(fee <= 500, StrategyAuctionErrors::FeeTooHigh);

        storage.protocol_fee.write(fee);
    }

    #[storage(read)]
    fn get_protocol_fee() -> u64 {
        storage.protocol_fee.read()
    }

    #[storage(read)]
    fn get_exchange() -> ContractId {
        storage.exchange.read().unwrap()
    }

    #[storage(read)]
    fn get_maker_order_of_user(
        user: Address,
        nonce: u64,
        side: Side
    ) -> Option<MakerOrder> {
        match side {
            Side::Buy => Option::None,
            Side::Sell => _sell_order(user, nonce),
        }
    }

    #[storage(read)]
    fn is_valid_order(
        maker: Address,
        nonce: u64,
        side: Side
    ) -> bool {
        let maker_order = match side {
            Side::Buy => Option::None,
            Side::Sell => _sell_order(maker, nonce),
        };
        _is_valid_order(maker_order)
    }

    #[storage(read)]
    fn get_order_nonce_of_user(user: Address, side: Side) -> u64 {
        match side {
            Side::Buy => 0,
            Side::Sell => _user_sell_order_nonce(user),
        }
    }

    #[storage(read)]
    fn get_min_order_nonce_of_user(user: Address, side: Side) -> u64 {
        match side {
            Side::Buy => 0,
            Side::Sell => _user_min_sell_order_nonce(user),
        }
    }

    /// Ownable ///
    #[storage(read)]
    fn owner() -> Option<Identity> {
        _owner()
    }

    #[storage(read, write)]
    fn transfer_ownership(new_owner: Identity) {
        storage.owner.only_owner();
        storage.owner.transfer_ownership(new_owner);
    }

    #[storage(read, write)]
    fn renounce_ownership() {
        storage.owner.only_owner();
        storage.owner.renounce_ownership();
    }
}

#[storage(read)]
fn _is_initialized() -> bool {
    match storage.is_initialized.try_read() {
        Option::Some(is_initialized) => is_initialized,
        Option::None => false,
    }
}

#[storage(read)]
fn _owner() -> Option<Identity> {
    match storage.owner.owner() {
        State::Initialized(owner) => Option::Some(owner),
        _ => Option::None,
    }
}

#[storage(read)]
fn only_exchange() {
    let caller = get_msg_sender_contract_or_panic();
    let exchange = storage.exchange.read().unwrap();
    require(caller == exchange, StrategyAuctionErrors::CallerMustBeTheExchange);
}

#[storage(read)]
fn _auction_item(collection: ContractId, id: SubId) -> Option<MakerOrder> {
    let status = storage.auction_item.get((collection, id)).try_read();
    match status {
        Option::Some(order) => order,
        Option::None => Option::None,
    }
}

#[storage(read)]
fn _auction_highest_bid(collection: ContractId, id: SubId) -> Option<MakerOrder> {
    let status = storage.auction_highest_bid.get((collection, id)).try_read();
    match status {
        Option::Some(order) => order,
        Option::None => Option::None,
    }
}

#[storage(read)]
fn _sell_order(address: Address, nonce: u64) -> Option<MakerOrder> {
    let status = storage.sell_order.get((address, nonce)).try_read();
    match status {
        Option::Some(order) => order,
        Option::None => Option::None,
    }
}

#[storage(read)]
fn _user_sell_order_nonce(address: Address) -> u64 {
    let status = storage.user_sell_order_nonce.get(address).try_read();
    match status {
        Option::Some(nonce) => nonce,
        Option::None => 0,
    }
}

#[storage(read)]
fn _user_min_sell_order_nonce(address: Address) -> u64 {
    let status = storage.user_min_sell_order_nonce.get(address).try_read();
    match status {
        Option::Some(nonce) => nonce,
        Option::None => 0,
    }
}

#[storage(read)]
fn _is_valid_order(maker_order: Option<MakerOrder>) -> bool {
    if (maker_order.is_some()) {
        let unwraped_order = maker_order.unwrap();
        let end_time = unwraped_order.end_time;

        let nonce = match unwraped_order.side {
            Side::Buy => 0,
            Side::Sell => _user_sell_order_nonce(unwraped_order.maker),
        };

        let min_nonce = match unwraped_order.side {
            Side::Buy => 0,
            Side::Sell => _user_min_sell_order_nonce(unwraped_order.maker),
        };

        let status = (
            (end_time >= timestamp()) &&
            (unwraped_order.nonce <= nonce) &&
            (min_nonce < unwraped_order.nonce)
        );
        return status;
    }
    return false;
}

#[storage(read, write)]
fn _place_buy_order(order: MakerOrder) {
    let auction = _auction_item(order.collection, order.token_id);
    let highest_bid = _auction_highest_bid(order.collection, order.token_id);

    require(
        _is_valid_order(auction),
        StrategyAuctionErrors::ItemIsNotOnAuction
    );
    require(
        order.maker != auction.unwrap().maker,
        StrategyAuctionErrors::OwnerCanNotPlaceBid
    );

    match highest_bid {
        Option::Some(bid) => {
            require(
                order.price >= ((bid.price * 1100) / 1000),
                StrategyAuctionErrors::BidMustBeHigherThanPreviousOne
            );
        },
        Option::None => {
            require(order.price > 0, StrategyAuctionErrors::BidMustBeNonZero);

            let starting_price = auction.unwrap().extra_params.extra_u64_param;
            if (starting_price > 0) {
                require(
                    order.price >= starting_price,
                    StrategyAuctionErrors::BidMustBeHigherThanStartingPrice
                );
            }
        },
    }

    if (auction.unwrap().end_time - timestamp() <= 600) {
        let mut unwrapped_auction = auction.unwrap();
        unwrapped_auction.end_time += 600;
        storage.auction_item.insert((order.collection, order.token_id), Option::Some(unwrapped_auction));
    }

    storage.auction_highest_bid.insert((order.collection, order.token_id), Option::Some(order));
}

#[storage(read, write)]
fn _place_sell_order(order: MakerOrder) {
    let nonce = storage.user_sell_order_nonce
        .get(order.maker)
        .read();

    require(
        !_is_valid_order(_auction_item(order.collection, order.token_id)),
        StrategyAuctionErrors::ItemIsAlreadyOnAuction
    );

    if (order.nonce == nonce + 1) {
        // Place sell order
        let nonce = _user_sell_order_nonce(order.maker);
        storage.user_sell_order_nonce.insert(order.maker, nonce + 1);
        storage.sell_order.insert((order.maker, nonce + 1), Option::Some(order));
        storage.auction_item.insert((order.collection, order.token_id), Option::Some(order));
    } else {
        revert(113);
    }
}

#[storage(write)]
fn _execute_order(maker_order: MakerOrder) {
    let none: Option<MakerOrder> = Option::None;
    match maker_order.side {
        Side::Buy => (),
        Side::Sell => {
            storage.auction_highest_bid.insert((maker_order.collection, maker_order.token_id), none);
            storage.auction_item.insert((maker_order.collection, maker_order.token_id), none);
            storage.sell_order.insert((maker_order.maker, maker_order.nonce), none);
        },
    }
}
