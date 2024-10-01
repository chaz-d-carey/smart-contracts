library;

pub enum RoyaltyManagerErrors {
    OnlyOwner: (),
    Initialized: (),
    CallerMustBeOwnerOrAdmin: (),
    FeeHigherThanLimit: (),
    FeeLimitTooHigh: (),
    ZeroAddress: (),
}
