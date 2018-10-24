<p align="center"><a href="#" target="_blank" rel="noopener noreferrer"><img width="100" src="doc/images/Pizza_Hackathon_Logo.png"></a></p>

<h2 align="center">Pizza Coin</h2>

## Brief Synopsis of Pizza Hackathon

<a href="https://www.facebook.com/events/205814763443058/">Pizza Hackathon</a> was the 1st blockchain hackathon event in Thailand which was held on 25-26 August 2018. The objective of this event was to educate blockchain technologies as well as building up thai blockchain developers. The event consisted of education and project hacking sessions in which all participating developers had freedom to develop any project based on any blockchain technologies. There was eventually the project competition among teams of developers at the end of the event.

To find the winning team, we developed a voting system named PizzaCoin. PizzaCoin is a voting system based on <a href="https://www.ethereum.org/">Ethereum</a> blockchain’s <a href="https://solidity.readthedocs.io/en/latest/">smart contract</a> compatible with <a href="https://en.wikipedia.org/wiki/ERC-20">ERC-20 token standard</a>. Each event participant (i.e., all participating developers and all event staffs) would be registered to PizzaCoin contract. The contract allowed a group of developers create and join a team. Meanwhile, any authorized staff was able to perform operations such as revoking some developer from a team, revoking a whole team, changing contract states, etc. All participants would receive equal voting tokens. With PizzaCoin contract, a participating developer was able to give his/her votes to any favourite projects developed by other different teams whereas a staff had freedom to vote to any teams. Each voter could spend voting tokens according to his/her own balance. Specifically, all voting results would be transacted and recorded on the blockchain. As a result, the winning team, who got maximum voting tokens, was judged transparently by the developed PizzaCoin contract automatically without any possible interference even by any event staff.

<br />

## Workflow Design for PizzaCoin Contract

One of the biggest challenges when developing Ethereum smart contract is to find a solution to handling ‘***Out-of-Gas***’ error during deploying the contract onto the blockchain network, due to some block gas limits on Ethereum blockchain. The prototype of our PizzaCoin contract also confronted with these limitations since our contract requires several functional subsystems such as staff management, team and player management, and voting management subsystems. To avoid block gas limit problems, PizzaCoin contract was designed and developed using several advanced concepts and techniques.

PizzaCoin contract consists of eight dependencies including **three contracts**: ***PizzaCoinStaff***, ***PizzaCoinPlayer*** and ***PizzaCoinTeam***, and **five libraries**: ***PizzaCoinStaffDeployer***, ***PizzaCoinPlayerDeployer***, ***PizzaCoinTeamDeployer***, ***PizzaCoinCodeLib*** and ***PizzaCoinCodeLib2***.

PizzaCoin contract acts as a mother contract of all dependencies. In more detail, the contract has three special children contracts, namely **PizzaCoinStaff**, **PizzaCoinPlayer** and **PizzaCoinTeam** contracts which would be deployed by the three deployer libraries named **PizzaCoinStaffDeployer**, **PizzaCoinPlayerDeployer** and **PizzaCoinTeamDeployer** respectively. Furthermore, PizzaCoin contract also has another two proxy libraries named **PizzaCoinCodeLib** and **PizzaCoinCodeLib2** which would be used as libraries for migrating source code of PizzaCoin mother contract.

<br />
<p align="center"><img src="doc/Diagrams/PZC contract deployment (transparent).png" width="600"></p>
<h3 align="center">Figure 1. Deployment of PizzaCoin contract</h3><br />

There are two stages when deploying PizzaCoin contract onto the blockchain. In the first stage, PizzaCoin contract's dependencies including **PizzaCoinStaffDeployer**, **PizzaCoinPlayerDeployer**, **PizzaCoinTeamDeployer**, **PizzaCoinCodeLib** and **PizzaCoinCodeLib2** libraries have to be deployed onto the blockchain one by one as separate transactions. The previously deployed libraries' addresses would then be linked and injected as dependency instances in order to deploy PizzaCoin mother contract to the ethereum network as illustrated in Figure 1.

<br />
<p align="center"><img src="doc/Diagrams/PZC contract initialization-2 (transparent).png"></p>
<h3 align="center">Figure 2. Initialization of PizzaCoin contract</h3><br />

In the second stage, the previously deployed PizzaCoin mother contract must get initialized by a project deployer (a staff who previously deployed PizzaCoin contract). A project deployer initiates three transactions (steps 1.1, 2.1 and 3.1) in order to deploy PizzaCoin children contracts--including **PizzaCoinStaff**, **PizzaCoinPlayer** and **PizzaCoinTeam** contracts--as shown in Figure 2. At this point, we employed a contract factory pattern using the deployer libraries, i.e. **PizzaCoinStaffDeployer**, **PizzaCoinPlayerDeployer** and **PizzaCoinTeamDeployer**, to deploy each corresponding child contract (steps 1.2 - 1.3, 2.2 - 2.3 and 3.2 - 3.3). The resulting children contracts' addresses would then be returned to store on PizzaCoin contract (steps 1.4, 2.4 and 3.4). This way makes PizzaCoin contract know where its children contracts are located on the ethereum blockchain.

<p align="center"><img src="doc/Diagrams/PZC contract with its children contracts and libs (transparent).png" width="800"></p>
<h3 align="center">Figure 3. PizzaCoin contract acts as a contract coordinator for PizzaCoinStaff, PizzaCoinPlayer and PizzaCoinTeam contracts</h3><br />

On the prototype of PizzaCoin contract, we faced '***Out-of-Gas***' error when deploying the contract because the contract contains too many function definitions. The solution to avoiding such the error we have used on a production version is `to migrate almost all the logical source code of each function on PizzaCoin contract to store on proxy libraries named PizzaCoinCodeLib and PizzaCoinCodeLib2 instead` as depicted in Figure 3.

`PizzaCoin contract is considered as a contract coordinator or a reverse proxy contract` for PizzaCoinStaff, PizzaCoinPlayer and PizzaCoinTeam contracts. When a user needs to interact with any contract function, a user just makes a call to PizzaCoin contract right away. For example, a user wants to join some specific team, he/she can achieve this by invoking **registerPlayer** function on PizzaCoin contract. The contract would then interact with its children contracts in order to do register the calling user as a player to the specified team.

In more technical detail when a user makes a call to **PizzaCoin.registerPlayer()** function on PizzaCoin contract, the function will instead forward the request to the delegated function named **PizzaCoinCodeLib.registerPlayer()** on the proxy library PizzaCoinCodeLib in order to process the requesting transaction on behalf of PizzaCoin contract. Next, the delegated function will hand over the process to the real worker function named **PizzaCoinPlayer.registerPlayer()** which is on PizzaCoinPlayer child contract. With these code migration techniques, we can significantly reduce gas consumption when deploying the PizzaCoin mother contract.

<br />

## State Transition on PizzaCoin Contract

<p align="center"><img src="doc/Diagrams/States on the PZC contract (transparent).png"></p>
<h3 align="center">Figure 4. State transition on PizzaCoin contract</h3><br />

There are five states representing the status of PizzaCoin contract including **Initial**, **Registration**, **Registration Locked**, **Voting** and **Voting Finished**. Each state defines a different working context to the contract and it is changable by a staff privilege only. The contract state is unidirectional as illustrated in Figure 4. This means that if the state has been changed from one to another, we cannot change it back to any previous state. 

**Initial** is the first state that is automatically set during PizzaCoin contract getting deployed. The contract state can be changed from Initial to Registration if and only if all the three children contracts (i.e., PizzaCoinStaff, PizzaCoinPlayer and PizzaCoinTeam contracts) have been created by a project deployer (a staff who deployed PizzaCoin contract). A project deployer can create the children contracts by invoking the following functions on PizzaCoin contract in no particular order: **createStaffContract**, **createPlayerContract** and **createTeamContract** (steps 1.1, 2.1 and 3.1 in Figure 2).

Once PizzaCoin contract's state is changed to **Registration**, the contract is opened for registration. During this state, a staff can register a selected user as a new staff. A player can create a team and/or join to an existing team. Furthermore, a staff is allowed to revoke some player from a specific team or even revoke a whole team if necessary. PizzaCoin contract would be closed for registration once the state is changed to **Registration Locked**. Later, a staff can enable voting by changing the contract state to **Voting**. The vote would be opened until the contract state is moved to **Voting Finished**. In this state, PizzaCoin contract would determine the winning team automatically.

<p align="center"><img src="doc/Diagrams/Staff changes the contract state (transparent).png" width="800"></p>
<h3 align="center">Figure 5. An interaction among contracts when a staff changes the contract state</h3><br />

Let's say a staff changes PizzaCoin contract's state from **Registration Locked** to **Voting**. Figure 5 illustrates how PizzaCoin contract interacts with its children contracts. What happens is that as soon as a staff executes **PizzaCoin.startVoting()** function on PizzaCoin contract (step 1), the function would call to the delegated function **PizzaCoinCodeLib2.signalChildrenContractsToStartVoting()** on PizzaCoinCodeLib2 library (step 2). Later, the delegated function would order all the three children contracts to change their state to **Voting** by respectively executing **PizzaCoinStaff.startVoting()**, **PizzaCoinPlayer.startVoting()** and **PizzaCoinTeam.startVoting()** (steps 3.1 - 3.3).

<br />

In addition to understanding the detailed implementation of PizzaCoin voting system, please check out the series of articles named "**PizzaCoin the series**" below.

**PizzaCoin the series consists of 6 articles as follows.**<br />
Part 1: <a href="https://www.serial-coder.com/post/pizza-coin-how-did-we-develop-ethereum-based-voting-system-for-pizza-hackathon/">How Did We Develop Ethereum-based Voting System for Pizza Hackathon?</a><br />
Part 2: <a href="https://www.serial-coder.com/post/pizza-coin-workflow-design-for-pizzacoin-voting-system/">Workflow Design for PizzaCoin Voting System</a><br />
Part 3: <a href="https://www.serial-coder.com/post/pizza-coin-detailed-implementation-of-staff-and-player-contracts/">Detailed Implementation of Staff and Player Contracts</a><br />
Part 4: <a href="https://www.serial-coder.com/post/pizza-coin-detailed-implementation-of-team-contract/">Detailed Implementation of Team Contract</a><br />
Part 5: <a href="https://www.serial-coder.com/post/pizza-coin-deploying-children-contracts-with-contract-factories/">Deploying Children Contracts with Contract Factories</a><br />
Part 6: <a href="https://www.serial-coder.com/post/pizza-coin-integrating-pizzacoin-contract-with-dependencies/">Integrating PizzaCoin Contract with Dependencies</a>

<br />

## Deploy PizzaCoin Contract

### To install Truffle Framework
&emsp;<a href="https://truffleframework.com/docs/truffle/getting-started/installation">Follow this link</a>

### To install Node.JS dependency packages
```
npm install
```

### To get Infura API for free
&emsp;<a href="https://infura.io">Register to get a free api.</a> Note that, the api will be sent to your registered e-mail.

### To set up 'infura-api.secret' file
```
echo "'your-infura-api'" > infura-api.secret  // Your Infura api must be marked with single quotes
```

### To set up 'mnemonic.secret' file
```
echo "'your-secret-mnemonic'" > mnemonic.secret  // Your secret mnemonic must be marked with single quotes
```

### To compile PizzaCoin contract and its dependencies
```
truffle compile
```

### To deploy PizzaCoin contract and its dependencies
```
truffle migrate --network mainnet  // Deploy to Ethereum public main network via Infura
```

<p align="center">or</p>

```
truffle migrate --network ropsten  // Deploy to Ropsten testnet via Infura
```

<p align="center">or</p>

```
truffle migrate --network rinkeby  // Deploy to Rinkeby testnet via Infura
```

<p align="center">or</p>

```
truffle migrate --network kovan  // Deploy to Kovan testnet via Infura
```

<p align="center">or</p>

```
truffle migrate --network rinkeby_localsync  // Deploy to Rinkeby testnet via local Geth node
```

<p align="center">or</p>

```
truffle migrate --network ganache  // Deploy to Ganache local test environment
```

### To initial PizzaCoin contract (use this when integrating the contract with DApp)
```
node init-contract.js <<ethereum_network>>  // For example, run 'node init-contract.js rinkeby'
```

### To execute Node.JS based lazy-web3-wrapper functions (for demonstrating how to interact the contract with web3 node.js backend)
```
node web3-demo.js  // This script supports a connection to Ganache or local Geth/Parity node only
```

<br />

## List of PizzaCoin Contract Address and Its Dependency Addresses
The following addresses point to PizzaCoin contract as well as its dependencies that were used at the hackathon event.

- <b>Ethereum network:</b> <a href="https://kovan.etherscan.io/">Kovan</a>
- <b>PizzaCoin contract:</b> <a href="https://kovan.etherscan.io/address/0x76030b8f0e6e938afabe7662ec248f2b7815e6bb">0x76030b8f0e6e938afabe7662ec248f2b7815e6bb</a>
- <b>PizzaCoinStaffDeployer library:</b> <a href="https://kovan.etherscan.io/address/0x7F8366b1C1aCE62A74531F9D1477428E15Aa1109">0x7F8366b1C1aCE62A74531F9D1477428E15Aa1109</a>
- <b>PizzaCoinPlayerDeployer library:</b> <a href="https://kovan.etherscan.io/address/0x2659a5CEcC38250bf8a0F4f48DBF9C36C4eAB923">0x2659a5CEcC38250bf8a0F4f48DBF9C36C4eAB923</a>
- <b>PizzaCoinTeamDeployer library:</b> <a href="https://kovan.etherscan.io/address/0xD32dC427118DA8CBfc300C6E483C03d7877f3d39">0xD32dC427118DA8CBfc300C6E483C03d7877f3d39</a>
- <b>PizzaCoinCodeLib library:</b> <a href="https://kovan.etherscan.io/address/0xD9ea584DAB76F0BcF6Db85D61AA7Ee5606f15876">0xD9ea584DAB76F0BcF6Db85D61AA7Ee5606f15876</a>
- <b>PizzaCoinCodeLib2 library:</b> <a href="https://kovan.etherscan.io/address/0xFaB51C36088D9651872f2cd610dAE7F82E4F04E0">0xFaB51C36088D9651872f2cd610dAE7F82E4F04E0</a>
- <b>PizzaCoinStaff contract:</b> <a href="https://kovan.etherscan.io/address/0xEa1E67465b688Ea1b30856F55AcD77af43376d01">0xEa1E67465b688Ea1b30856F55AcD77af43376d01</a>
- <b>PizzaCoinPlayer contract:</b> <a href="https://kovan.etherscan.io/address/0x785A811Ad43c733B0FdDd8113E8478bc2AEd02e0">0x785A811Ad43c733B0FdDd8113E8478bc2AEd02e0</a>
- <b>PizzaCoinTeam contract:</b> <a href="https://kovan.etherscan.io/address/0x216C611001b2e8B6ff2cf51C5e9EB39ABE558E35">0x216C611001b2e8B6ff2cf51C5e9EB39ABE558E35</a>
