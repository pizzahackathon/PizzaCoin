# Pizza Coin developed for the 1st Thailand's blockchain hackathon (Pizza Hackathon 2018)

## To set up Node.JS packages required by Truffle
```
npm install
```

## To set up 'mnemonic.secret' file
```
echo "'your-secret-mnemonic'" > mnemonic.secret  // Your secret mnemonic must be marked with single quotes
```

## To compile PizzaCoin contract and its dependencies
```
truffle compile
```

## To deploy PizzaCoin contract and its dependencies
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

## To set up Node.JS packages required by lazy-web3-wrapper functions
```
cd run
npm install
```

## To execute Node.JS based lazy-web3-wrapper functions (for demo)
```
cd run
node main.js
```