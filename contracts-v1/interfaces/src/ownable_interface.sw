library;

use std::identity::Identity;
use libraries::{ownable::State};

abi Ownable {
    #[storage(read)]
    fn owner() -> State;

    #[storage(read)]
    fn is_admin(admin: Identity) -> bool;
}
