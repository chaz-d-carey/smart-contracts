library;

pub enum AssetManagerErrors {
    Initialized: (),
    OnlyOwner: (),
    AssetAlreadySupported: (),
    AssetNotSupported: (),
    ZeroLengthVec: (),
    IndexOutOfBound: (),
}
