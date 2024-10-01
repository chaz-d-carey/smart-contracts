library;

use std::{auth::msg_sender, hash::sha256, storage::storage_api::{read, write}};

/// Determines the state of ownership.
pub enum State {
    /// The ownership has not been set.
    Uninitialized: (),
    /// The user which has been given ownership.
    Initialized: Identity,
    /// The ownership has been given up and can never be set again.
    Revoked: (),
}

impl core::ops::Eq for State {
    fn eq(self, other: Self) -> bool {
        match (self, other) {
            (State::Initialized(owner1), State::Initialized(owner2)) => {
                owner1 == owner2
            },
            (State::Uninitialized, State::Uninitialized) => true,
            (State::Revoked, State::Revoked) => true,
            _ => false,
        }
    }
}

/// Error log for when access is denied.
pub enum AccessError {
    /// Emiited when an owner has already been set.
    CannotReinitialized: (),
    /// Emitted when the caller is not the owner of the contract.
    NotOwner: (),
}

/// Logged when ownership is renounced.
pub struct OwnershipRenounced {
    /// The user which revoked the ownership.
    previous_owner: Identity,
}

/// Logged when ownership is given to a user.
pub struct OwnershipSet {
    /// The user which is now the owner.
    new_owner: Identity,
}

/// Logged when ownership is given from one user to another.
pub struct OwnershipTransferred {
    /// The user which is now the owner.
    new_owner: Identity,
    /// The user which has given up their ownership.
    previous_owner: Identity,
}

pub struct Ownership {
    state: State,
}

impl Ownership {
    pub fn uninitialized() -> Self {
        Self {
            state: State::Uninitialized,
        }
    }

    pub fn initialized(identity: Identity) -> Self {
        Self {
            state: State::Initialized(identity),
        }
    }

    pub fn revoked() -> Self {
        Self {
            state: State::Revoked,
        }
    }
}

impl StorageKey<Ownership> {
    #[storage(read)]
    pub fn owner(self) -> State {
        match self.try_read() {
            Option::Some(ownership) => ownership.state,
            Option::None => State::Uninitialized,
        }
    }
}

impl StorageKey<Ownership> {
    #[storage(read)]
    pub fn only_owner(self) {
        require(
            self.owner() == State::Initialized(msg_sender().unwrap()),
            AccessError::NotOwner,
        );
    }
}

impl StorageKey<Ownership> {
    #[storage(read, write)]
    pub fn set_ownership(self, new_owner: Identity) {
        require(
            self.owner() == State::Uninitialized,
            AccessError::CannotReinitialized,
        );

        self.write(Ownership::initialized(new_owner));

        log(OwnershipSet { new_owner });
    }

    #[storage(read, write)]
    pub fn renounce_ownership(self) {
        self.only_owner();

        self.write(Ownership::revoked());

        log(OwnershipRenounced {
            previous_owner: msg_sender().unwrap(),
        });
    }

    #[storage(read, write)]
    pub fn transfer_ownership(self, new_owner: Identity) {
        self.only_owner();

        self.write(Ownership::initialized(new_owner));

        log(OwnershipTransferred {
            new_owner,
            previous_owner: msg_sender().unwrap(),
        });
    }
}
