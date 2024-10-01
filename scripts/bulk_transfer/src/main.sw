script;

use std::asset::*;

struct Transfer {
    to: Address,
    asset: AssetId,
    amount: u64
}

fn main(transfers: Vec<Transfer>) {
    let mut i = 0;
    let length = transfers.len();

    while i < length {
        let transfer_info = transfers.get(i).unwrap();
        transfer(
            Identity::Address(transfer_info.to),
            transfer_info.asset,
            transfer_info.amount
        );

        i += 1;
    }
}
