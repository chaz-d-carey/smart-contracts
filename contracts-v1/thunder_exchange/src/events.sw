library;

use libraries::order_types::*;

pub struct OrderPlaced {
    pub order: MakerOrder,
}

pub struct OrderUpdated {
    pub order: MakerOrder,
}

pub struct OrderExecuted {
    pub order: TakerOrder,
}

pub struct OrderCanceled {
    pub user: Address,
    pub strategy: ContractId,
    pub side: Side,
    pub nonce: u64,
}
