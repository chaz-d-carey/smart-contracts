library;

use std::{
    address::Address,
    contract_id::ContractId,
    identity::Identity,
};

pub const ZERO_B256 = 0x0000000000000000000000000000000000000000000000000000000000000000;
pub const ZERO_ADDRESS = Address::from(ZERO_B256);
pub const ZERO_ASSET_ID = AssetId::from(ZERO_B256);
pub const ZERO_CONTRACT_ID = ContractId::from(ZERO_B256);
pub const ZERO_IDENTITY_ADDRESS = Identity::Address(ZERO_ADDRESS);
pub const ZERO_IDENTITY_CONTRACT = Identity::ContractId(ZERO_CONTRACT_ID);
