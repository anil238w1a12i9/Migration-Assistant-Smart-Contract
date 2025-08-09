module addr::DataMigrator {
    use aptos_framework::signer;
    use aptos_framework::timestamp;
    use std::error;
    use std::vector;
    const E_NOT_AUTHORIZED: u64 = 1;
    const E_MIGRATION_ALREADY_EXISTS: u64 = 2;
    const E_INVALID_VERSION: u64 = 3;

    struct MigrationRecord has store, key {
        from_version: u64,      
        to_version: u64,        
        data_hash: vector<u8>,  
        migrated_at: u64,       
        is_verified: bool,      
    }

    struct MigrationTools has store, key {
        supported_versions: vector<u64>,  
        migration_count: u64,             
    }

    public fun initialize_migration_tools(owner: &signer) acquires MigrationTools {
        let owner_addr = signer::address_of(owner);
        
        assert!(!exists<MigrationTools>(owner_addr), error::already_exists(E_MIGRATION_ALREADY_EXISTS));
        
        let tools = MigrationTools {
            supported_versions: vector::empty<u64>(),
            migration_count: 0,
        };
        
        move_to(owner, tools);
        
        let tools_ref = borrow_global_mut<MigrationTools>(owner_addr);
        vector::push_back(&mut tools_ref.supported_versions, 1);
    }

    public fun migrate_data(
        owner: &signer, 
        from_version: u64, 
        to_version: u64, 
        data_hash: vector<u8>
    ) acquires MigrationTools {
        let owner_addr = signer::address_of(owner);
        
        assert!(exists<MigrationTools>(owner_addr), error::not_found(E_NOT_AUTHORIZED));
        
        assert!(from_version < to_version, error::invalid_argument(E_INVALID_VERSION));
        
        let migration = MigrationRecord {
            from_version,
            to_version,
            data_hash,
            migrated_at: timestamp::now_seconds(),
            is_verified: false,
        };
        
        move_to(owner, migration);
        
        let tools = borrow_global_mut<MigrationTools>(owner_addr);
        tools.migration_count = tools.migration_count + 1;
        
        if (!vector::contains(&tools.supported_versions, &to_version)) {
            vector::push_back(&mut tools.supported_versions, to_version);
        };
    }
}
