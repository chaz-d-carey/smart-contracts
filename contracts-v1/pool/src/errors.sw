library;

pub enum PoolErrors {
    OnlyOwner: (),
    Initialized: (),
    AssetNotSupported: (),
    AmountHigherThanBalance: (),
    CallerMustBeTheExchange: (),
    IdentityMustBeNonZero: (),
    FromToSameAddress: (),
}
