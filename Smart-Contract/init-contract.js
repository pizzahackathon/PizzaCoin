#!/usr/bin/env node

/*
* Copyright (c) 2018, Phuwanai Thummavet (serial-coder). All rights reserved.
* Github: https://github.com/serial-coder
* Contact us: mr[dot]thummavet[at]gmail[dot]com
*/

'use strict';

// Import libraries
const Web3             = require('web3'),
      HDWalletProvider = require('truffle-hdwallet-provider'),
      contract         = require('truffle-contract'),
      fs               = require('fs'),
      PizzaCoinJson    = require('./build/contracts/PizzaCoin.json'),
      mnemonic         = require('./mnemonic.secret'),
      infuraApi        = require('./infura-api.secret');

const network = process.argv[2];
if (!network) {
    console.error('Please specify Ethereum network...');
    process.exit(1);
}

const provider = new HDWalletProvider(
    mnemonic, 
    'https://' + network + '.infura.io/' + infuraApi, 
    0
);
const web3 = new Web3(provider);

main();

async function main() {
    try {
        const projectDeployerAddr = provider.getAddresses()[0];
        console.log('Project deployer address: ' + projectDeployerAddr);
        console.log('Network: ' + network);

        // Initial PizzaCoin contract instance
        const contractInstance = await initContractInstance();

        let pizzaCoinAddr, pizzaCoinStaffAddr, pizzaCoinPlayerAddr, pizzaCoinTeamAddr;

        pizzaCoinAddr = contractInstance.address;
        console.log('PizzaCoin address: ' + pizzaCoinAddr);

        let contractState = await contractInstance.getContractState();
        console.log('Contract state: ' + contractState);

        // Create PizzaCoinStaff contract
        console.log('Creating PizzaCoinStaff contract...');
        const staffContractAddr = await contractInstance.createStaffContract({
            from: projectDeployerAddr,
            gas: 4000000,
            gasPrice: 10000000000
        });
        pizzaCoinStaffAddr = staffContractAddr.logs[0].args._contract;
        console.log('... succeeded');

        // Create PizzaCoinPlayer contract
        console.log('Creating PizzaCoinPlayer contract...');
        const playerContractAddr = await contractInstance.createPlayerContract({
            from: projectDeployerAddr,
            gas: 4000000,
            gasPrice: 10000000000
        });
        console.log('... succeeded');

        // Create PizzaCoinTeam contract
        console.log('Creating PizzaCoinTeam contract...');
        const teamContractAddr = await contractInstance.createTeamContract({
            from: projectDeployerAddr,
            gas: 4000000,
            gasPrice: 10000000000
        });
        pizzaCoinPlayerAddr = playerContractAddr.logs[0].args._contract;
        console.log('... succeeded');

        // Change all contracts' state from Initial to Registration
        console.log('Changing a contract state to Registration...');
        await contractInstance.startRegistration({
            from: projectDeployerAddr,
            gas: 1000000,
            gasPrice: 10000000000
        });
        pizzaCoinTeamAddr = teamContractAddr.logs[0].args._contract;
        console.log('... succeeded');

        contractState = await contractInstance.getContractState();
        console.log('Contract state: ' + contractState);

        console.log('--------------- All done ---------------');
        console.log('Project deployer address: ' + projectDeployerAddr);
        console.log('Network: ' + network);
        console.log('PizzaCoin address: ' + pizzaCoinAddr);
        console.log('PizzaCoinStaff address: ' + pizzaCoinStaffAddr);
        console.log('PizzaCoinPlayer address: ' + pizzaCoinPlayerAddr);
        console.log('PizzaCoinTeam address: ' + pizzaCoinTeamAddr);

        // Writing a config file
        /*console.log('\nWriting a config file...');
        await writeContractConfigFile(
            'contract-settings.js',
            network, 
            pizzaCoinAddr, 
            pizzaCoinStaffAddr, 
            pizzaCoinPlayerAddr, 
            pizzaCoinTeamAddr
        );
        console.log('... succeeded');*/

        process.exit(0);
    }
    catch (err) {
        console.error(err);
        process.exit(1);
    }
}

async function initContractInstance() {

    try {
        const PizzaCoinContract = contract(PizzaCoinJson);
        PizzaCoinContract.setProvider(web3.currentProvider);

        fixTruffleContractCompatibilityIssue(PizzaCoinContract);

        // Calling Async function
        const contractInstance = await PizzaCoinContract.deployed();

        return contractInstance;
    }
    catch (err) {
        throw new Error(err);
    }
}

function fixTruffleContractCompatibilityIssue (contract) {
    /*
        Dirty hack for web3@1.0.0 support for localhost testrpc, 
        see 'https://github.com/trufflesuite/truffle-contract
                /issues/56#issuecomment-331084530'
    */
    if ( typeof contract.currentProvider.sendAsync !== 'function' ) {
        contract.currentProvider.sendAsync = () => {
            return contract.currentProvider.send.apply(
                contract.currentProvider, 
                arguments
            );
        }
    }

    return contract;
}

function writeContractConfigFile(
    configFilePath,
    network, 
    pizzaCoinAddr, 
    pizzaCoinStaffAddr, 
    pizzaCoinPlayerAddr, 
    pizzaCoinTeamAddr
) {
    try {
        const fd = fs.openSync(configFilePath, 'w+');
        fs.appendFileSync(fd, "const state = {\n");
        fs.appendFileSync(fd, "    network: '" + network + "',\n");
        fs.appendFileSync(fd, "    etherscanPrefix: 'https://" + network + ".etherscan.io',\n");
        fs.appendFileSync(fd, "    ethereumNode: 'wss://" + network + ".infura.io/_ws', // Only websocker endpoint\n");
        fs.appendFileSync(fd, "    pizzaCoinAddr: '" + pizzaCoinAddr + "',\n");
        fs.appendFileSync(fd, "    pizzaCoinStaffAddr: '" + pizzaCoinStaffAddr + "',\n");
        fs.appendFileSync(fd, "    pizzaCoinPlayerAddr: '" + pizzaCoinPlayerAddr + "',\n");
        fs.appendFileSync(fd, "    pizzaCoinTeamAddr: '" + pizzaCoinTeamAddr + "'\n");
        fs.appendFileSync(fd, "  }\n");
        fs.appendFileSync(fd, "\n");
        fs.appendFileSync(fd, "export default {\n");
        fs.appendFileSync(fd, "    namespaced: true,\n");
        fs.appendFileSync(fd, "    state\n");
        fs.appendFileSync(fd, "}\n");
    }
    catch (err) {
        throw new Error(err);
    }
}