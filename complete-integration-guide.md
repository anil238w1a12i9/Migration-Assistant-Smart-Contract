# Complete Migration Assistant Integration Guide

## 📋 Overview
This guide will walk you through integrating your Migration Assistant Smart Contract with a React frontend on the Aptos blockchain.

## 🎯 Prerequisites

### System Requirements
```bash
# Node.js (v18 or higher)
node --version

# NPM or Yarn
npm --version

# Aptos CLI
aptos --version

# Git
git --version
```

## 📁 Project Structure
```
migration-assistant/
├── backend/
│   ├── sources/
│   │   └── MigrationAssistant.move
│   ├── Move.toml
│   └── README.md
├── frontend/
│   ├── public/
│   ├── src/
│   │   ├── components/
│   │   ├── utils/
│   │   ├── hooks/
│   │   └── App.js
│   ├── package.json
│   └── .env
└── README.md
```

## 🚀 Step 1: Backend Setup & Deployment

### 1.1 Initialize Aptos Project
```bash
# Create project directory
mkdir migration-assistant
cd migration-assistant

# Initialize Aptos project
aptos init

# Create Move project structure
mkdir sources
```

### 1.2 Deploy Smart Contract
```bash
# Compile the contract
aptos move compile

# Deploy to testnet (replace with your address)
aptos move publish --named-addresses addr=0x9d87dfd8c86c6bfb8b160782fec651484f677de0fc0b2edc903df669987f398c

# Verify deployment
aptos account list --query modules
```

### 1.3 Test Contract Functions
```bash
# Initialize migration tools
aptos move run \
  --function-id 0x9d87dfd8c86c6bfb8b160782fec651484f677de0fc0b2edc903df669987f398c::DataMigrator::initialize_migration_tools

# Test migration
aptos move run \
  --function-id 0x9d87dfd8c86c6bfb8b160782fec651484f677de0fc0b2edc903df669987f398c::DataMigrator::migrate_data \
  --args u64:1 u64:2 "vector<u8>:[104,101,108,108,111]"
```

## 🎨 Step 2: Frontend Setup

### 2.1 Create React App
```bash
# Create React application
npx create-react-app frontend
cd frontend

# Install Aptos dependencies
npm install @aptos-labs/ts-sdk
npm install @aptos-labs/wallet-adapter-react
npm install @aptos-labs/wallet-adapter-ant-design
npm install @aptos-labs/wallet-adapter-petra-plugin
npm install @aptos-labs/wallet-adapter-pontem-plugin
npm install @aptos-labs/wallet-adapter-rise-plugin
npm install @aptos-labs/wallet-adapter-martian-plugin

# Install UI dependencies
npm install lucide-react
npm install tailwindcss
npx tailwindcss init
```

### 2.2 Configure Tailwind CSS
```javascript
// tailwind.config.js
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

```css
/* src/index.css */
@tailwind base;
@tailwind components;
@tailwind utilities;
```

### 2.3 Environment Configuration
```bash
# Create .env file in frontend directory
touch .env
```

```env
# .env
REACT_APP_APTOS_NETWORK=testnet
REACT_APP_CONTRACT_ADDRESS=0x9d87dfd8c86c6bfb8b160782fec651484f677de0fc0b2edc903df669987f398c
REACT_APP_MODULE_NAME=DataMigrator
REACT_APP_APTOS_NODE_URL=https://testnet.aptoslabs.com/v1
REACT_APP_APTOS_FAUCET_URL=https://testnet.aptoslabs.com
```

## 🔧 Step 3: Create Integration Files

### 3.1 Aptos Client Setup
```javascript
// src/utils/aptosClient.js
import { Aptos, AptosConfig, Network } from '@aptos-labs/ts-sdk';

const network = process.env.REACT_APP_APTOS_NETWORK === 'mainnet' 
  ? Network.MAINNET 
  : Network.TESTNET;

const aptosConfig = new AptosConfig({ 
  network,
  fullnode: process.env.REACT_APP_APTOS_NODE_URL,
});

export const aptos = new Aptos(aptosConfig);

export const CONTRACT_ADDRESS = process.env.REACT_APP_CONTRACT_ADDRESS;
export const MODULE_NAME = process.env.REACT_APP_MODULE_NAME;
```

### 3.2 Contract Interaction Functions
```javascript
// src/utils/contractFunctions.js
import { aptos, CONTRACT_ADDRESS, MODULE_NAME } from './aptosClient';

export const initializeMigrationTools = async (account) => {
  try {
    const transaction = await aptos.transaction.build.simple({
      sender: account.address,
      data: {
        function: `${CONTRACT_ADDRESS}::${MODULE_NAME}::initialize_migration_tools`,
        functionArguments: []
      }
    });

    const response = await aptos.signAndSubmitTransaction({
      signer: account,
      transaction
    });

    await aptos.waitForTransaction({ 
      transactionHash: response.hash,
      options: { timeoutSecs: 30 }
    });
    
    return response;
  } catch (error) {
    console.error('Initialize error:', error);
    throw error;
  }
};

export const migrateData = async (account, fromVersion, toVersion, dataHash) => {
  try {
    // Convert string hash to bytes
    const hashBytes = new TextEncoder().encode(dataHash);
    
    const transaction = await aptos.transaction.build.simple({
      sender: account.address,
      data: {
        function: `${CONTRACT_ADDRESS}::${MODULE_NAME}::migrate_data`,
        functionArguments: [
          fromVersion,
          toVersion,
          Array.from(hashBytes)
        ]
      }
    });

    const response = await aptos.signAndSubmitTransaction({
      signer: account,
      transaction
    });

    await aptos.waitForTransaction({ 
      transactionHash: response.hash,
      options: { timeoutSecs: 30 }
    });
    
    return response;
  } catch (error) {
    console.error('Migration error:', error);
    throw error;
  }
};

export const getMigrationTools = async (address) => {
  try {
    const resource = await aptos.getAccountResource({
      accountAddress: address,
      resourceType: `${CONTRACT_ADDRESS}::${MODULE_NAME}::MigrationTools`
    });
    return resource.data;
  } catch (error) {
    console.error('Get migration tools error:', error);
    return null;
  }
};

export const getMigrationRecord = async (address) => {
  try {
    const resource = await aptos.getAccountResource({
      accountAddress: address,
      resourceType: `${CONTRACT_ADDRESS}::${MODULE_NAME}::MigrationRecord`
    });
    return resource.data;
  } catch (error) {
    console.error('Get migration record error:', error);
    return null;
  }
};

export const getAccountBalance = async (address) => {
  try {
    const resources = await aptos.getAccountResources({ accountAddress: address });
    const aptosCoin = resources.find(r => r.type === '0x1::coin::CoinStore<0x1::aptos_coin::AptosCoin>');
    return aptosCoin ? parseInt(aptosCoin.data.coin.value) / 100000000 : 0; // Convert to APT
  } catch (error) {
    console.error('Get balance error:', error);
    return 0;
  }
};
```

### 3.3 Wallet Provider Setup
```javascript
// src/components/WalletProvider.js
import { WalletProvider, useWallet } from '@aptos-labs/wallet-adapter-react';
import { PetraWallet } from '@aptos-labs/wallet-adapter-petra-plugin';
import { PontemWallet } from '@aptos-labs/wallet-adapter-pontem-plugin';
import { RiseWallet } from '@aptos-labs/wallet-adapter-rise-plugin';
import { MartianWallet } from '@aptos-labs/wallet-adapter-martian-plugin';

const wallets = [
  new PetraWallet(),
  new PontemWallet(),
  new RiseWallet(),
  new MartianWallet(),
];

export function AppWalletProvider({ children }) {
  return (
    <WalletProvider plugins={wallets} autoConnect={false}>
      {children}
    </WalletProvider>
  );
}

export { useWallet };
```

### 3.4 Custom Hooks
```javascript
// src/hooks/useContract.js
import { useState } from 'react';
import { useWallet } from '@aptos-labs/wallet-adapter-react';
import { 
  initializeMigrationTools, 
  migrateData, 
  getMigrationTools, 
  getMigrationRecord,
  getAccountBalance
} from '../utils/contractFunctions';

export const useContract = () => {
  const { account, connected } = useWallet();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const initialize = async () => {
    if (!account || !connected) throw new Error('Wallet not connected');
    
    setLoading(true);
    setError(null);
    
    try {
      const result = await initializeMigrationTools(account);
      return result;
    } catch (err) {
      setError(err.message);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const migrate = async (fromVersion, toVersion, dataHash) => {
    if (!account || !connected) throw new Error('Wallet not connected');
    
    setLoading(true);
    setError(null);
    
    try {
      const result = await migrateData(account, fromVersion, toVersion, dataHash);
      return result;
    } catch (err) {
      setError(err.message);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const getTools = async () => {
    if (!account) return null;
    return await getMigrationTools(account.address);
  };

  const getRecord = async () => {
    if (!account) return null;
    return await getMigrationRecord(account.address);
  };

  const getBalance = async () => {
    if (!account) return 0;
    return await getAccountBalance(account.address);
  };

  return {
    initialize,
    migrate,
    getTools,
    getRecord,
    getBalance,
    loading,
    error,
    account,
    connected
  };
};
```

## 🔗 Step 4: Main App Integration

### 4.1 Update App.js
```javascript
// src/App.js
import React from 'react';
import { AppWalletProvider } from './components/WalletProvider';
import MigrationAssistant from './components/MigrationAssistant';
import './index.css';

function App() {
  return (
    <AppWalletProvider>
      <div className="App">
        <MigrationAssistant />
      </div>
    </AppWalletProvider>
  );
}

export default App;
```

### 4.2 Error Handling Utility
```javascript
// src/utils/errorHandler.js
export const handleContractError = (error) => {
  const errorString = error.toString().toLowerCase();
  
  if (errorString.includes('1') || errorString.includes('not_authorized')) {
    return 'Not authorized to perform this action';
  } else if (errorString.includes('2') || errorString.includes('already_exists')) {
    return 'Migration tools already exist for this account';
  } else if (errorString.includes('3') || errorString.includes('invalid_version')) {
    return 'Invalid version numbers provided';
  } else if (errorString.includes('insufficient')) {
    return 'Insufficient APT balance for gas fees';
  } else if (errorString.includes('sequence_number')) {
    return 'Transaction sequence error. Please try again.';
  } else if (errorString.includes('timeout')) {
    return 'Transaction timeout. Please check the explorer.';
  }
  
  return error.message || 'Unknown contract error';
};
```

## 📱 Step 5: Testing & Deployment

### 5.1 Local Testing
```bash
# Start frontend development server
cd frontend
npm start

# Test contract functions
# 1. Connect wallet (Petra recommended)
# 2. Get test APT from faucet
# 3. Initialize migration tools
# 4. Test data migration
```

### 5.2 Faucet Integration (Testnet)
```javascript
// src/utils/faucet.js
export const requestTestnetAPT = async (address) => {
  try {
    const response = await fetch(`${process.env.REACT_APP_APTOS_FAUCET_URL}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        address: address,
        amount: 100000000, // 1 APT
      }),
    });
    
    if (!response.ok) {
      throw new Error('Failed to request testnet APT');
    }
    
    return await response.json();
  } catch (error) {
    console.error('Faucet error:', error);
    throw error;
  }
};
```

### 5.3 Production Build
```bash
# Build for production
npm run build

# Serve locally to test
npx serve -s build
```

## 🌐 Step 6: Deployment Options

### 6.1 Vercel Deployment
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel --prod
```

### 6.2 Netlify Deployment
```bash
# Build project
npm run build

# Deploy to Netlify (drag & drop build folder)
# Or connect GitHub repository
```

### 6.3 GitHub Pages
```bash
# Install gh-pages
npm install --save-dev gh-pages

# Add to package.json
"homepage": "https://yourusername.github.io/migration-assistant",
"scripts": {
  "predeploy": "npm run build",
  "deploy": "gh-pages -d build"
}

# Deploy
npm run deploy
```

## 🐛 Step 7: Troubleshooting

### Common Issues & Solutions

**Issue: "Module not found"**
```bash
# Solution: Verify contract address
aptos account list --query modules --account 0x9d87dfd8c86c6bfb8b160782fec651484f677de0fc0b2edc903df669987f398c
```

**Issue: "Insufficient gas"**
```javascript
// Solution: Add gas estimation
const gasEstimate = await aptos.transaction.simulate.simple({
  signerPublicKey: account.publicKey,
  transaction
});
```

**Issue: "Wallet connection failed"**
```javascript
// Solution: Check wallet availability
if (!window.aptos) {
  throw new Error('Petra wallet not found');
}
```

## 📊 Step 8: Monitoring & Analytics

### 8.1 Transaction Monitoring
```javascript
// src/utils/monitoring.js
export const trackTransaction = async (txHash, operation) => {
  try {
    const txData = await aptos.getTransactionByHash({ transactionHash: txHash });
    
    // Log successful transaction
    console.log(`${operation} successful:`, {
      hash: txHash,
      gasUsed: txData.gas_used,
      success: txData.success
    });
    
    return txData;
  } catch (error) {
    console.error(`${operation} failed:`, error);
    throw error;
  }
};
```

### 8.2 Performance Metrics
```javascript
// src/utils/metrics.js
export const measurePerformance = (operation, startTime) => {
  const endTime = performance.now();
  const duration = endTime - startTime;
  
  console.log(`${operation} took ${duration.toFixed(2)} milliseconds`);
  return duration;
};
```

## ✅ Verification Checklist

- [ ] Smart contract deployed successfully
- [ ] Frontend connects to wallet
- [ ] Contract functions work correctly
- [ ] Error handling implemented
- [ ] Transaction confirmations working
- [ ] Gas estimation functional
- [ ] UI responsive on mobile
- [ ] Production build successful
- [ ] Deployment completed
- [ ] Testing on testnet complete

## 🚀 Going Live

### Mainnet Deployment
1. **Test thoroughly on testnet**
2. **Audit smart contract** (recommended)
3. **Deploy to mainnet** using production keys
4. **Update frontend environment** to mainnet
5. **Monitor initial transactions**

### Production Environment Variables
```env
REACT_APP_APTOS_NETWORK=mainnet
REACT_APP_CONTRACT_ADDRESS=<your_mainnet_address>
REACT_APP_APTOS_NODE_URL=https://mainnet.aptoslabs.com/v1
```

This comprehensive guide should help you successfully integrate and deploy your Migration Assistant project from smart contract to production frontend! 🎉