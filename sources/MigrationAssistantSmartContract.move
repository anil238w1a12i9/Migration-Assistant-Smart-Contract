module addr::DataMigrator {
    use aptos_framework::signer;
    use aptos_framework::timestamp;
    use std::error;
    use std::vector;

    /// Error codes
    const E_NOT_AUTHORIZED: u64 = 1;
    const E_MIGRATION_ALREADY_EXISTS: u64 = 2;
    const E_INVALID_VERSION: u64 = 3;

    /// Struct representing migration data between contract versions
    struct MigrationRecord has store, key {
        from_version: u64,      // Source contract version
        to_version: u64,        // Target contract version
        data_hash: vector<u8>,  // Hash of migrated data for verification
        migrated_at: u64,       // Timestamp of migration
        is_verified: bool,      // Whether migration was verified
    }

    /// Struct to store migration tools and utilities
    struct MigrationTools has store, key {
        supported_versions: vector<u64>,  // List of supported versions
        migration_count: u64,             // Total number of migrations
    }

    /// Function to initialize migration tools for a contract owner
    public fun initialize_migration_tools(owner: &signer) acquires MigrationTools {
        let owner_addr = signer::address_of(owner);
        
        // Ensure migration tools don't already exist
        assert!(!exists<MigrationTools>(owner_addr), error::already_exists(E_MIGRATION_ALREADY_EXISTS));
        
        let tools = MigrationTools {
            supported_versions: vector::empty<u64>(),
            migration_count: 0,
        };
        
        move_to(owner, tools);
        
        // Add initial version support
        let tools_ref = borrow_global_mut<MigrationTools>(owner_addr);
        vector::push_back(&mut tools_ref.supported_versions, 1);
    }

    /// Function to migrate data from one contract version to another
    public fun migrate_data(
        owner: &signer, 
        from_version: u64, 
        to_version: u64, 
        data_hash: vector<u8>
    ) acquires MigrationTools {
        let owner_addr = signer::address_of(owner);
        
        // Verify migration tools exist
        assert!(exists<MigrationTools>(owner_addr), error::not_found(E_NOT_AUTHORIZED));
        
        // Validate version numbers
        assert!(from_version < to_version, error::invalid_argument(E_INVALID_VERSION));
        
        // Create migration record
        let migration = MigrationRecord {
            from_version,
            to_version,
            data_hash,
            migrated_at: timestamp::now_seconds(),
            is_verified: false,
        };
        
        // Store migration record
        move_to(owner, migration);
        
        // Update migration count
        let tools = borrow_global_mut<MigrationTools>(owner_addr);
        tools.migration_count = tools.migration_count + 1;
        
        // Add new version to supported versions if not exists
        if (!vector::contains(&tools.supported_versions, &to_version)) {
            vector::push_back(&mut tools.supported_versions, to_version);
        };
    }
}