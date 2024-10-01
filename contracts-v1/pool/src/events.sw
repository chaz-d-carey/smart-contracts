library;

use std::{identity::Identity};

pub struct Deposit {
    pub address: Identity,
    pub asset: AssetId,
    pub amount: u64,
}

pub struct Withdrawal {
    pub address: Identity,
    pub asset: AssetId,
    pub amount: u64,
}

pub struct Transfer {
    pub from: Identity,
    pub to: Identity,
    pub asset: AssetId,
    pub amount: u64,
}
