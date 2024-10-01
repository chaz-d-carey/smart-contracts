library;

pub enum StrategyAuctionErrors {
    OnlyOwner: (),
    Initialized: (),
    ExchangeAlreadyInitialized: (),
    OrderCancelledOrExpired: (),
    FeeTooHigh: (),
    CallerMustBeTheExchange: (),
    ItemIsNotOnAuction: (),
    OwnerCanNotPlaceBid: (),
    BidMustBeHigherThanPreviousOne: (),
    BidMustBeNonZero: (),
    BidMustBeHigherThanStartingPrice: (),
    ItemIsAlreadyOnAuction: (),
}
