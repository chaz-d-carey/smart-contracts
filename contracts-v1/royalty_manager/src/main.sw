contract;

mod errors;

use interfaces::{royalty_manager_interface::*, ownable_interface::*};
use libraries::{msg_sender_address::*, ownable::*, constants::*};
use errors::*;

use std::{
    auth::msg_sender,
    contract_id::ContractId,
    logging::log,
    hash::Hash,
    identity::Identity,
    revert::revert,
    storage::storage_map::*
};

storage {
    /// Whether the contract is initialized or not
    is_initialized: bool = false,
    /// Owner of the contract
    owner: Ownership = Ownership::uninitialized(),
    /// Map that stores royalty info of the collection
    royalty_info: StorageMap<ContractId, Option<RoyaltyInfo>> = StorageMap {},
    /// Royalty fee limit that can be set by the owner
    fee_limit: u64 = 0,
}

/// This contract manages royalty related data
impl RoyaltyManager for Contract {

    /// Initializes the contract and sets the owner
    #[storage(read, write)]
    fn initialize() {
        require(
            !_is_initialized(),
            RoyaltyManagerErrors::Initialized
        );
        storage.is_initialized.write(true);

        let caller = get_msg_sender_address_or_panic();
        storage.owner.set_ownership(Identity::Address(caller));
    }

    /// Stores royalty info by admin or owner of the NFT collection contract
    #[storage(read, write)]
    fn register_royalty_info(
        collection: ContractId,
        receiver: Identity,
        fee: u64
    ) {
        require(
            collection != ZERO_CONTRACT_ID &&
            receiver != ZERO_IDENTITY_ADDRESS,
            RoyaltyManagerErrors::ZeroAddress
        );

        let ownable = abi(Ownable, collection.into());
        let caller = msg_sender().unwrap();
        let owner = match ownable.owner() {
            State::Initialized(owner) => owner,
            _ => ZERO_IDENTITY_ADDRESS,
        };

        require(
            owner == caller ||
            ownable.is_admin(caller),
            RoyaltyManagerErrors::CallerMustBeOwnerOrAdmin
        );

        require(fee <= storage.fee_limit.read(), RoyaltyManagerErrors::FeeHigherThanLimit);

        let info = RoyaltyInfo {
            collection: collection,
            receiver: receiver,
            fee: fee
        };

        let option_info: Option<RoyaltyInfo> = Option::Some(info);
        storage.royalty_info.insert(collection, option_info);

        log(RoyaltyRegistryEvent {
            royalty_info: info
        });
    }

    /// Returns the royalty info of the NFT collection
    #[storage(read)]
    fn get_royalty_info(collection: ContractId) -> Option<RoyaltyInfo> {
        let none: Option<RoyaltyInfo> = Option::None;
        let status = storage.royalty_info.get(collection).try_read();
        match status {
            Option::Some(royalty_info) => {
                let unwraped = royalty_info.unwrap();
                let fee = storage.fee_limit.read();
                if (unwraped.fee > fee) {
                    let new_royalty_info = RoyaltyInfo {
                        collection: unwraped.collection,
                        receiver: unwraped.receiver,
                        fee
                    };
                    Option::Some(new_royalty_info)
                } else {
                    royalty_info
                }
            },
            Option::None => none,
        }
    }

    /// Sets the max limit of the royalty that can be set for collections
    #[storage(read, write)]
    fn set_royalty_fee_limit(new_fee_limit: u64) {
        storage.owner.only_owner();

        require(new_fee_limit <= 1000, RoyaltyManagerErrors::FeeLimitTooHigh);

        storage.fee_limit.write(new_fee_limit)
    }

    #[storage(read)]
    fn get_royalty_fee_limit() -> u64 {
        storage.fee_limit.read()
    }

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
