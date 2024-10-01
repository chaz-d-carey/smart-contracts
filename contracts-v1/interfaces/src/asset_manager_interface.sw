library;

abi AssetManager {
    #[storage(read, write)]
    fn initialize();

    #[storage(read, write)]
    fn add_asset(asset: AssetId);

    #[storage(read, write)]
    fn remove_asset(index: u64);

    #[storage(read)]
    fn is_asset_supported(asset: AssetId) -> bool;

    #[storage(read)]
    fn get_supported_asset(index: u64) -> Option<AssetId>;

    #[storage(read)]
    fn get_count_supported_assets() -> u64;

    // Ownable
    #[storage(read)]
    fn owner() -> Option<Identity>;

    #[storage(read, write)]
    fn transfer_ownership(new_owner: Identity);

    #[storage(read, write)]
    fn renounce_ownership();
}
