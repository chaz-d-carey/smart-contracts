library;

pub enum StrategyFixedPriceErrors {
    OnlyOwner: (),
    Initialized: (),
    ExchangeAlreadyInitialized: (),
    FeeTooHigh: (),
    CallerMustBeTheExchange: (),
    OrderMismatchedToUpdate: (),
}
