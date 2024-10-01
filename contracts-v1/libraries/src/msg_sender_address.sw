library;

use std::{
    address::*,
    auth::*,
    context::*,
    call_frames::*,
    result::*,
    revert::revert,
    identity::Identity,
};

/// Return the sender as an Address or panic
pub fn get_msg_sender_address_or_panic() -> Address {
   let sender: Result<Identity, AuthError> = msg_sender();
   if let Identity::Address(address) = sender.unwrap() {
      address
   } else {
      revert(31);
   }

   // match msg_sender() {
   //    Ok(Identity::Address(address)) => address,
   //    _ => revert(31)
   // }
}

/// Return the sender as a ContractId or panic
pub fn get_msg_sender_contract_or_panic() -> ContractId {
    let sender: Result<Identity, AuthError> = msg_sender();
    if let Identity::ContractId(contract_Id) = sender.unwrap() {
       contract_Id
    } else {
       revert(31);
    }
}
