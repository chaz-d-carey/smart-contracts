contract;

mod errors;
mod events;

use errors::*;
use events::*;
use std::{
    address::Address,
    auth::*,
    call_frames::*,
    constants::*,
    context::*,
    contract_id::ContractId,
    hash::Hash,
    logging::log,
    identity::Identity,
    revert::*,
    asset::*,
    storage::storage_map::*,
};

use interfaces::{
    asset_manager_interface::*,
    pool_interface::*,
};
use libraries::{
    msg_sender_address::*,
    constants::*,
    ownable::*,
};

storage {
    /// Whether the contract is initialized or not
    is_initialized: bool = false,
    /// Owner of the contract
    owner: Ownership = Ownership::uninitialized(),
    /// Thunder Exchange contractId
    exchange: Option<ContractId> = Option::None,
    /// Asset Manager contractId
    asset_manager: Option<ContractId> = Option::None,
    /// Bid balance of the Identity
    balance_of: StorageMap<(Identity, AssetId), u64> = StorageMap {},
}

/// This contract handles bid balance of the Identity for supported assets
/// Bid balance is used for offering on the platform
/// Users can deposit any supported asset into this pool contract
/// It works similar to wrapper contracts.
impl Pool for Contract {
    #[storage(read, write)]

    // Initializes the contract, sets the owner,
    // exchange contract, and asset manager contract
    fn initialize(exchange: ContractId, asset_manager: ContractId) {
        require(
            !_is_initialized(),
            PoolErrors::Initialized
        );
        storage.is_initialized.write(true);

        let caller = get_msg_sender_address_or_panic();
        storage.owner.set_ownership(Identity::Address(caller));
        storage.exchange.write(Option::Some(exchange));
        storage.asset_manager.write(Option::Some(asset_manager));
    }

    /// Returns the total supply of the asset in this contract
    fn total_supply(asset: AssetId) -> u64 {
        this_balance(asset)
    }

    /// Returns the balance of the user by the assetId
    #[storage(read)]
    fn balance_of(account: Identity, asset: AssetId) -> u64 {
        _balance_of(account, asset)
    }

    /// Deposits the supported asset into this contract
    /// and assign the deposited amount to the depositer as bid balance
    #[storage(read, write), payable]
    fn deposit() {
        let asset_manager_addr = storage.asset_manager.read().unwrap().bits();
        let asset_manager = abi(AssetManager, asset_manager_addr);
        require(asset_manager.is_asset_supported(msg_asset_id()), PoolErrors::AssetNotSupported);

        let address = msg_sender().unwrap();
        let amount = msg_amount();
        let asset = msg_asset_id();

        let current_balance = _balance_of(address, asset);
        let new_balance = current_balance + amount;
        storage.balance_of.insert((address, asset), new_balance);

        log(Deposit {
            address,
            asset,
            amount
        });
    }

    /// Withdraws the amount of assetId from the contract
    /// and sends to sender if sender has enough balance
    #[storage(read, write)]
    fn withdraw(asset: AssetId, amount: u64) {
        let sender = msg_sender().unwrap();
        let current_balance = _balance_of(sender, asset);
        require(current_balance >= amount, PoolErrors::AmountHigherThanBalance);

        // let asset_manager_addr = storage.asset_manager.read().unwrap().bits();
        // let asset_manager = abi(AssetManager, asset_manager_addr);
        // require(asset_manager.is_asset_supported(asset), PoolErrors::AssetNotSupported);

        let new_balance = current_balance - amount;
        storage.balance_of.insert((sender, asset), new_balance);

        transfer(sender, asset, amount);

        log(Withdrawal {
            address: sender,
            asset,
            amount,
        });
    }

    /// Transfers the amount of bid balance from Identity to another Identity.
    /// Only callable by Thunder Exchange contract.
    /// It is used in accepting offers where the bid balance
    /// is removed from the offerer by the amount of the offer and sent to the exchange contract
    /// to unwrap the bid balance and send the amount to the user who accepted the offer after deducting the fees.
    #[storage(read, write)]
    fn transfer_from(from: Identity, to: Identity, asset: AssetId, amount: u64) -> bool {
        let caller = get_msg_sender_contract_or_panic();
        let exchange = storage.exchange.read().unwrap();
        require(caller == exchange, PoolErrors::CallerMustBeTheExchange);

        _transfer(from, to, asset, amount);

        true
    }

    /// Setters
    #[storage(read, write)]
    fn set_exchange(exchange_contract: ContractId) {
        storage.owner.only_owner();

        storage.exchange.write(Option::Some(exchange_contract));
    }

    #[storage(read, write)]
    fn set_asset_manager(asset_manager: ContractId) {
        storage.owner.only_owner();

        storage.asset_manager.write(Option::Some(asset_manager));
    }

    /// Getters
    #[storage(read)]
    fn get_asset_manager() -> ContractId {
        storage.asset_manager.read().unwrap()
    }

    #[storage(read)]
    fn get_exchange() -> ContractId {
        storage.exchange.read().unwrap()
    }

    /// Ownable
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
fn _balance_of(account: Identity, asset: AssetId) -> u64 {
    let status = storage.balance_of.get((account, asset)).try_read();
    match status {
        Option::Some(balance) => balance,
        Option::None => 0,
    }
}

/// Bid balance transfer helper function
#[storage(read, write)]
fn _transfer(from: Identity, to: Identity, asset: AssetId, amount: u64) {
    require(
        to != ZERO_IDENTITY_ADDRESS &&
        to != ZERO_IDENTITY_CONTRACT,
        PoolErrors::IdentityMustBeNonZero
    );
    require(from != to, PoolErrors::FromToSameAddress);

    let from_balance = _balance_of(from, asset);
    require(from_balance >= amount, PoolErrors::AmountHigherThanBalance);
    storage.balance_of.insert((from, asset), from_balance - amount);

    let to_balance = _balance_of(to, asset);
    storage.balance_of.insert((to, asset), to_balance + amount);

    log(Transfer {
        from,
        to,
        asset,
        amount,
    });
}
