# Pizza Coin developed for the 1st Thailand's blockchain hackathon (Pizza Hackathon 2018)

## To compile PizzaCoin contract and its dependencies
```
truffle compile
```

## To deploy PizzaCoin contract and its dependencies to Ganache local test environment
```
truffle migrate --network dev_ganache
```

## To deploy PizzaCoin contract and its dependencies to Rinkeby Testnet
```
truffle migrate --network dev_rinkeby
```

## To setup Node.JS packages required by lazy-web3-wrapper functions
```
cd run
npm install
```

## To execute Node.JS based lazy-web3-wrapper functions (for demo)
```
cd run
node main.js
```