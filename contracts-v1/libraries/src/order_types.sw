library;

use std::{block::timestamp};

pub enum Side {
    Buy: (),
    Sell: (),
}

impl core::ops::Eq for Side {
    fn eq(self, other: Self) -> bool {
        match (self, other) {
            (Side::Buy, Side::Buy) => true,
            (Side::Sell, Side::Sell) => true,
            _ => false,
        }
    }
}

pub enum TokenType {
    Erc721: (),
    Erc1155: (),
    Other: (),
}

impl core::ops::Eq for TokenType {
    fn eq(self, other: Self) -> bool {
        match (self, other) {
            (TokenType::Erc721, TokenType::Erc721) => true,
            (TokenType::Erc1155, TokenType::Erc1155) => true,
            (TokenType::Other, TokenType::Other) => true,
            _ => false,
        }
    }
}

pub struct ExtraParams {
    pub extra_address_param: Address,
    pub extra_contract_param: ContractId,
    pub extra_u64_param: u64,
}

pub struct MakerOrder {
    pub side: Side,
    pub maker: Address,
    pub collection: ContractId,
    pub token_id: SubId,
    pub price: u64,
    pub amount: u64,
    pub nonce: u64,
    pub strategy: ContractId,
    pub payment_asset: AssetId,
    pub extra_params: ExtraParams,
}

// impl MakerOrder {
//     pub fn new(input: MakerOrderInput) -> MakerOrder {
//         MakerOrder {
//             side: input.side,
//             maker: input.maker,
//             collection: input.collection,
//             token_id: input.token_id,
//             price: input.price,
//             amount: input.amount,
//             nonce: input.nonce,
//             strategy: input.strategy,
//             payment_asset: input.payment_asset,
//             start_time: timestamp(),
//             end_time: timestamp() + input.expiration_range,
//             extra_params: input.extra_params,
//         }
//     }
// }

pub struct TakerOrder {
    pub side: Side,
    pub taker: Address,
    pub maker: Address,
    pub nonce: u64,
    pub price: u64,
    pub token_id: SubId,
    pub collection: ContractId,
    pub strategy: ContractId,
    pub extra_params: ExtraParams,
}
