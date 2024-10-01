library;

pub enum ExecutionManagerErrors {
    OnlyOwner: (),
    Initialized: (),
    StrategyAlreadyWhitelisted: (),
    StrategyNotWhitelisted: (),
    ZeroLengthVec: (),
    IndexOutOfBound: (),
}
