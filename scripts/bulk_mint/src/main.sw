script;

use src_3::SRC3;
use src20::SRC20;
use std::bytes_conversions::{u64::*, b256::*};


/// script that mints tokens like ERC721 style
fn main(id: ContractId, to: Identity, amount: u64) -> (u64, b256) {
    let collection = abi(SRC3, id.into());
    let asset = abi(SRC20, id.into());

    let mut i = 0;
    // while amount > i {
    //     let next_mint = asset.total_assets() + 1;
    //     let byte_id = next_mint.to_le_bytes();
    //     let sub_id = b256::from_le_bytes(byte_id);
    //     collection.mint(to, sub_id, 1);

    //     i += 1;
    // }
    let next_mint = asset.total_assets() + 1;
    let byte_id = next_mint.to_le_bytes();
    let sub_id = b256::from_le_bytes(byte_id);
    return (next_mint, sub_id);
}
