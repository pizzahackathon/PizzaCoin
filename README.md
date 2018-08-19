<p align="center"><a href="#" target="_blank" rel="noopener noreferrer"><img width="100" src="https://raw.githubusercontent.com/totiz/LiveDashboard/dev/images/Pizza_Hackathon_Logo.png" alt="Vue logo"></a></p>

<h2 align="center">Pizza Coin</h2>

Pizza Coin is a demonstration of Voting system on Blockchain, Utilize <a href="https://www.ethereum.org/">Ehtereum</a> Blockchain with <a href="https://solidity.readthedocs.io/">Smart contracts</a>. Developed for the 1st Thailand's blockchain hackathon named <a href="https://www.facebook.com/events/205814763443058/">Pizza Hackathon 2018</a>.

Pizza Coin is <a href="https://en.wikipedia.org/wiki/ERC-20">ERC20</a> Compatible with voting mechanism, allow player to participate in creating / joining team and voting. Authorized staff can perform "kick player", "kick team", "freeze and transfer tokens" and "start / stop voting".

Each Players and Staffs have same amount of PZC for voting.

### Pizza Coin consist of two parts
<p align="center">
  <a href="#" target="_blank">
    <img width="260px" src="https://raw.githubusercontent.com/totiz/LiveDashboard/dev/images/ethereum-smart-contract.jpeg">
  </a> 
  <a href="#" target="_blank">
    <img width="260px" src="https://raw.githubusercontent.com/totiz/LiveDashboard/dev/images/DApp.png">
  </a>
</p>

## Smart Contract
#### To set up Node.JS packages required by Truffle
```
npm install
```

#### To set up 'mnemonic.secret' file
```
echo "'your-secret-mnemonic'" > mnemonic.secret  // Your secret mnemonic must be marked with single quotes
```

#### To compile PizzaCoin contract and its dependencies
```
truffle compile
```

#### To deploy PizzaCoin contract and its dependencies
```
truffle migrate --network ropsten  // Deploy to Ropsten testnet via Infura
```

```
truffle migrate --network rinkeby  // Deploy to Rinkeby testnet via Infura
```

```
truffle migrate --network rinkeby_localsync  // Deploy to Rinkeby testnet via local Geth node
```

```
truffle migrate --network ganache  // Deploy to Ganache local test environment
```

#### To set up Node.JS packages required by lazy-web3-wrapper functions
```
cd run
npm install
```

#### To execute Node.JS based lazy-web3-wrapper functions (for demo)
```
cd run
node main.js
```


## DApp ( Decentralized Application )
TBD

## Contributors

# Coders
- <a href="https://github.com/serial-coder">Byte</a> (Smart contract)
- <a href="https://github.com/teerapat1739">Game</a> (DApp Team)
- <a href="https://github.com/zent-bank">Bank</a> (DApp Leader board)

# Advisors
- <a href="https://github.com/totiz?tab=repositories">Tot Nattapon </a>
- <a href="https://nuuneoi.com/">Nuuneoi</a>
