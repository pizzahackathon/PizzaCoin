## LiveDashboard

# Run Team Dashboard
- npm install
- npm run serve

# Run Leader Board
- npm install
- npm run serve

# Run Leader Board Api server
- node run

# Configure
## store/system.js
- **network**: Ethereum network 'mainnet', 'ropsten', 'rinkeby', 'kova' or etc.
- **etherscanPrefix**: Etherscan url, you need to configure according to network.
- **ethereumNode**: Public or Private Ethereum node, in case of user don't have Web3 provider like 'Metmask'. **Web socker** is need for Leader Board that checking real time incoming votes. exp: 'wss://rinkeby.infura.io/_ws'
- **pizzaCoinAddr**: Deployed Pizza Coin Contract Address
- **pizzaCoinStaffAddr**: Deployed Pizza Coin Staff Address
- **pizzaCoinStaffAddr**: Deployed Pizza Coin Team Address
- **pizzaCoinPlayerAddr**: Deployed Pizza Coin Player Address

* For pizzaCoinAddr, pizzaCoinStaffAddr, pizzaCoinStaffAddr and pizzaCoinPlayerAddr please consult in Pizza-Coin directory.
