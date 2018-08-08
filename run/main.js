#!/usr/bin/env node

/*
* Copyright (c) 2018, Phuwanai Thummavet (serial-coder). All rights reserved.
* Github: https://github.com/serial-coder
* Contact us: mr[dot]thummavet[at]gmail[dot]com
*/

'use strict';

// Import libraries
var Web3               = require('web3'),
    PizzaCoinJson      = require('../build/contracts/PizzaCoin.json'),
    PizzaCoinStaffJson = require('../build/contracts/PizzaCoinStaff.json'),
    PizzaCoinPlayerJson = require('../build/contracts/PizzaCoinPlayer.json'),
    PizzaCoinTeamJson = require('../build/contracts/PizzaCoinTeam.json'),
    pe = require('parse-error');

var web3 = new Web3(new Web3.providers.WebsocketProvider('ws://localhost:7545'));    // Ganache
//var web3 = new Web3(new Web3.providers.WebsocketProvider('ws://localhost:8546'));  // Rinkeby
//var web3 = new Web3('http://localhost:7545');  // Ganache
//var web3 = new Web3('http://localhost:8545');  // Rinkeby

var PizzaCoin = new web3.eth.Contract(
    PizzaCoinJson.abi,
    PizzaCoinJson.networks[5777].address    // Ganache
    //PizzaCoinJson.networks[4].address     // Rinkeby
);

main();

function callContractFunction(contractFunction) {
    return contractFunction
        .then(receipt => {
            return [null, receipt];
        })
        .catch(err => {
            return [pe(err), null];
        });
}

async function main() {
    let ethAccounts = await web3.eth.getAccounts();

    console.log('Project deployer address: ' + ethAccounts[0]);

    try {
        // Subscribe to 'TeamVoted' event (this requires a web3-websocket provider)
        let subscription = subscribeEvent();

        // Initialized contracts
        let [
            staffContractAddr, 
            playerContractAddr, 
            teamContractAddr
        ] = await initContracts(ethAccounts[0]);

        console.log('\nInitializing contracts succeeded...');
        console.log('PizzaCoin address: ' + PizzaCoinJson.networks[5777].address);  // Ganache
        //console.log('PizzaCoin address: ' + PizzaCoinJson.networks[4].address);   // Rinkeby
        console.log('PizzaCoinStaff address: ' + staffContractAddr);
        console.log('PizzaCoinPlayer address: ' + playerContractAddr);
        console.log('PizzaCoinTeam address: ' + teamContractAddr);

        let PizzaCoinStaff = new web3.eth.Contract(
            PizzaCoinStaffJson.abi,
            staffContractAddr
        );

        let PizzaCoinPlayer = new web3.eth.Contract(
            PizzaCoinPlayerJson.abi,
            playerContractAddr
        );

        let PizzaCoinTeam = new web3.eth.Contract(
            PizzaCoinTeamJson.abi,
            teamContractAddr
        );

        // Register a staff
        await registerStaff(ethAccounts[0], ethAccounts[1], 'bright');

        // Register a staff
        await registerStaff(ethAccounts[0], ethAccounts[2], 'bright');

        // Kick a staff
        await kickStaff(ethAccounts[0], ethAccounts[2]);

        // Register a staff
        await registerStaff(ethAccounts[0], ethAccounts[2], 'bright');

        // Create a team
        await createTeam(ethAccounts[3], 'serial-coder', 'pizza');

        // Register a player
        await registerPlayer(ethAccounts[4], 'bright', 'pizza');

        // Register a player
        await registerPlayer(ethAccounts[5], 'bright', 'pizza');

        // Create a team
        await createTeam(ethAccounts[6], 'robert', 'pizzaHack');

        // Register a player
        await registerPlayer(ethAccounts[7], 'bob', 'pizzaHack');

        // Kick a player
        await kickPlayer(ethAccounts[0], ethAccounts[6], 'pizzaHack');

        // Kick the first found player in team
        let nextStartSearchingIndex = await kickFirstFoundPlayerInTeam(ethAccounts[0], 'pizzaHack', 0);
        console.log('nextStartSearchingIndex: ' + nextStartSearchingIndex);

        // Kick a team
        //await kickTeam(ethAccounts[0], 'pizzaHack');

        // Create a team
        await createTeam(ethAccounts[8], 'john', 'pizzaCoin');

        // Register a player
        await registerPlayer(ethAccounts[9], 'james', 'pizzaCoin');

        // Change all contracts' state from Registration to RegistrationLocked
        await lockRegistration(ethAccounts[0]);

        // Change all contracts' state from RegistrationLocked to Voting
        await startVoting(ethAccounts[0]);

        // Vote to a team
        await voteTeam(ethAccounts[0], 'pizza', 1);
        await voteTeam(ethAccounts[0], 'pizza', 1);
        await voteTeam(ethAccounts[0], 'pizzaHack', 1);

        await voteTeam(ethAccounts[3], 'pizzaHack', 1);
        await voteTeam(ethAccounts[3], 'pizzaHack', 2);

        await voteTeam(ethAccounts[1], 'pizza', 3);

        await voteTeam(ethAccounts[5], 'pizzaCoin', 3);
        await voteTeam(ethAccounts[2], 'pizzaCoin', 2);

        // Get a total number of voters to the specific team
        let totalVoters = await getTotalVotersToTeam(PizzaCoinTeam, 'pizzaCoin');
        console.log('totalVoters: ' + totalVoters + '\n');

        let i = 0;
        while (true) 
        {
            let [endOfList, voter, voteWeight] = await getVoteResultAtIndexToTeam(PizzaCoinTeam, 'pizzaCoin', i);
            if (endOfList) {
                break;
            }
            console.log('voter: ' + voter);
            console.log('voteWeight: ' + voteWeight + '\n');
            i++;
        }

        // Change all contracts' state from Voting to VotingFinished
        await stopVoting(ethAccounts[0]);

        // Get a maximum voting point
        let maxTeamVotingPoint = await getMaxTeamVotingPoint(PizzaCoinTeam);
        console.log('maxTeamVotingPoint: ' + maxTeamVotingPoint);

        // Get a total number of winner teams
        let totalWinners = await getTotalWinnerTeams(PizzaCoinTeam);
        console.log('totalWinners: ' + totalWinners + '\n');

        let startSearchingIndex = 0;
        let endOfList, teamName, totalVoted;
        while (true) 
        {
            [
                endOfList, 
                startSearchingIndex, 
                teamName, 
                totalVoted
            ] = await getFirstFoundWinnerTeam(PizzaCoinTeam, startSearchingIndex);

            if (endOfList) {
                break;
            }
            console.log('teamName: ' + teamName);
            console.log('totalVoted: ' + totalVoted + '\n');
        }

        // Unsubscribes the event subscription (this does not work!!)
        unsubscribeEvent(subscription);
    }
    catch (err) {
        return console.error(err);
    }
}

function subscribeEvent() {
    // Subscribe to 'TeamVoted' event (this requires a web3-websocket provider)
    // See: https://web3js.readthedocs.io/en/1.0/web3-eth-contract.html#contract-events
    let subscription = PizzaCoin.events.TeamVoted(null, (err, result) => {
        if (err) {
            throw new Error(err);
        }
        
        let teamName, totalVoted;
        teamName = result.returnValues._teamName;
        totalVoted = result.returnValues._totalVoted;

        console.log('***** Event catched *****');
        console.log('teamName: ' + teamName);
        console.log('totalVoted: ' + totalVoted);
    });

    return subscription;
}

function unsubscribeEvent(subscription) {
    // Unsubscribes the event subscription (this does not work!!)
    subscription.unsubscribe((err, success) => {
        if (err) {
            throw new Error(err);
        }
            
        console.log('***** Successfully unsubscribed! *****');
        console.log(success);
    });
}

async function getFirstFoundWinnerTeam(PizzaCoinTeam, startSearchingIndex) {
    let err;
    let tupleReturned;

    //console.log('\nQuerying for the first found winner team (by the index of voters) ...');
    [err, tupleReturned] = await callContractFunction(
        PizzaCoinTeam.methods.getFirstFoundWinnerTeam(startSearchingIndex).call({})
    );

    if (err) {
        throw new Error(err.message);
    }
    //console.log('... succeeded');

    return [
        tupleReturned._endOfList, 
        tupleReturned._nextStartSearchingIndex, 
        tupleReturned._teamName, 
        tupleReturned._totalVoted
    ];
}

async function getTotalWinnerTeams(PizzaCoinTeam) {
    let err, totalWinners;

    console.log('\nQuerying for a total number of winner teams ...');
    [err, totalWinners] = await callContractFunction(
        PizzaCoinTeam.methods.getTotalWinnerTeams().call({})
    );

    if (err) {
        throw new Error(err.message);
    }
    console.log('... succeeded');
    return totalWinners;
}

async function getMaxTeamVotingPoint(PizzaCoinTeam) {
    let err, maxTeamVotingPoints;

    console.log('\nQuerying for a maximum voting point ...');
    [err, maxTeamVotingPoints] = await callContractFunction(
        PizzaCoinTeam.methods.getMaxTeamVotingPoint().call({})
    );

    if (err) {
        throw new Error(err.message);
    }
    console.log('... succeeded');
    return maxTeamVotingPoints;
}

async function getVoteResultAtIndexToTeam(PizzaCoinTeam, teamName, voterIndex) {
    let err;
    let tupleReturned;

    //console.log('\nQuerying for a voting result (by the index of voters) to a specified team --> "' + teamName + '" ...');
    [err, tupleReturned] = await callContractFunction(
        PizzaCoinTeam.methods.getVoteResultAtIndexToTeam(teamName, voterIndex).call({})
    );

    if (err) {
        throw new Error(err.message);
    }
    //console.log('... succeeded');
    return [tupleReturned._endOfList, tupleReturned._voter, tupleReturned._voteWeight];
}

async function getTotalVotersToTeam(PizzaCoinTeam, teamName) {
    let err, totalVoters;

    console.log('\nQuerying for a total number of voters to the specific team --> "' + teamName + '" ...');
    [err, totalVoters] = await callContractFunction(
        PizzaCoinTeam.methods.getTotalVotersToTeam(teamName).call({})
    );

    if (err) {
        throw new Error(err.message);
    }
    console.log('... succeeded');
    return totalVoters;
}

// For both a staff and a player
async function voteTeam(voterAddr, teamName, votingWeight) {
    let err, receipt;
    console.log('\nVoting to a team -->  team: "' + teamName + '" weight: "' + votingWeight + '" ...');

    // Vote to a team
    [err, receipt] = await callContractFunction(
        PizzaCoin.methods.voteTeam(teamName, votingWeight).send({
            from: voterAddr,
            gas: 6500000,
            gasPrice: 10000000000
        })
    );

    if (err) {
        throw new Error(err.message);
    }
    console.log('... succeeded');
}

async function lockRegistration(projectDeployerAddr)
{
    let err, receipt;
    let state;

    // Change all contracts' state from Registration to RegistrationLocked
    console.log("\nChanging the contracts' state to RegistrationLocked ...");
    [err, receipt] = await callContractFunction(
        PizzaCoin.methods.lockRegistration().send({
            from: projectDeployerAddr,
            gas: 6500000,
            gasPrice: 10000000000
        })
    );
    console.log('... succeeded');

    if (err) {
        throw new Error(err.message);
    }

    // Check the contracts' state
    console.log("\nValidating the contracts' state ...");
    [err, state] = await callContractFunction(
        PizzaCoin.methods.getContractState().call({
            from: projectDeployerAddr
        })
    );

    if (err || state !== 'Registration Locked') {
        throw new Error("Changing contracts' state failed");
    }
    console.log('... succeeded');
}

async function startVoting(projectDeployerAddr)
{
    let err, receipt;
    let state;

    // Change all contracts' state from RegistrationLocked to Voting
    console.log("\nChanging the contracts' state to Voting ...");
    [err, receipt] = await callContractFunction(
        PizzaCoin.methods.startVoting().send({
            from: projectDeployerAddr,
            gas: 6500000,
            gasPrice: 10000000000
        })
    );
    console.log('... succeeded');

    if (err) {
        throw new Error(err.message);
    }

    // Check the contracts' state
    console.log("\nValidating the contracts' state ...");
    [err, state] = await callContractFunction(
        PizzaCoin.methods.getContractState().call({
            from: projectDeployerAddr
        })
    );

    if (err || state !== 'Voting') {
        throw new Error("Changing contracts' state failed");
    }
    console.log('... succeeded');
}

async function stopVoting(projectDeployerAddr)
{
    let err, receipt;
    let state;

    // Change all contracts' state from Voting to VotingFinished
    console.log("\nChanging the contracts' state to Voting ...");
    [err, receipt] = await callContractFunction(
        PizzaCoin.methods.stopVoting().send({
            from: projectDeployerAddr,
            gas: 6500000,
            gasPrice: 10000000000
        })
    );
    console.log('... succeeded');

    if (err) {
        throw new Error(err.message);
    }

    // Check the contracts' state
    console.log("\nValidating the contracts' state ...");
    [err, state] = await callContractFunction(
        PizzaCoin.methods.getContractState().call({
            from: projectDeployerAddr
        })
    );

    if (err || state !== 'Voting Finished') {
        throw new Error("Changing contracts' state failed");
    }
    console.log('... succeeded');
}

async function registerPlayer(playerAddr, playerName, teamName) {
    let err, receipt;
    console.log('\nRegistering a player --> "' + playerAddr + '" ...');

    // Register a player
    [err, receipt] = await callContractFunction(
        PizzaCoin.methods.registerPlayer(playerName, teamName).send({
            from: playerAddr,
            gas: 6500000,
            gasPrice: 10000000000
        })
    );

    if (err) {
        throw new Error(err.message);
    }
    console.log('... succeeded');
}

async function kickPlayer(kickerAddr, playerAddr, teamName) {
    let err, receipt;
    console.log('\nKicking a player --> "' + playerAddr + '" ...');

    // Kick a player
    [err, receipt] = await callContractFunction(
        PizzaCoin.methods.kickPlayer(playerAddr, teamName).send({
            from: kickerAddr,
            gas: 6500000,
            gasPrice: 10000000000
        })
    );

    if (err) {
        throw new Error(err.message);
    }
    console.log('... succeeded');
}

async function kickFirstFoundPlayerInTeam(kickerAddr, teamName, startSearchingIndex) {
    let err, receipt;
    console.log('\nKicking the first found player in team --> "' + teamName + '" ...');

    // Kick the first found player in team
    [err, receipt] = await callContractFunction(
        PizzaCoin.methods.kickFirstFoundPlayerInTeam(teamName, startSearchingIndex).send({
            from: kickerAddr,
            gas: 6500000,
            gasPrice: 10000000000
        })
    );

    if (err) {
        throw new Error(err.message);
    }
    console.log('... succeeded');
    return receipt.events.FirstFoundPlayerInTeamKicked.returnValues._nextStartSearchingIndex;
}

async function createTeam(creatorAddr, creatorName, teamName) {
    let err, receipt;
    console.log('\nCreating a new team --> "' + teamName + '" ...');

    // Create a new team
    [err, receipt] = await callContractFunction(
        PizzaCoin.methods.createTeam(teamName, creatorName).send({
            from: creatorAddr,
            gas: 6500000,
            gasPrice: 10000000000
        })
    );

    if (err) {
        throw new Error(err.message);
    }
    console.log('... succeeded');
}

async function kickTeam(kickerAddr, teamName) {
    let err, receipt;
    console.log('\nKicking a team --> "' + teamName + '" ...');

    // Create a new team
    [err, receipt] = await callContractFunction(
        PizzaCoin.methods.kickTeam(teamName).send({
            from: kickerAddr,
            gas: 6500000,
            gasPrice: 10000000000
        })
    );

    if (err) {
        throw new Error(err.message);
    }
    console.log('... succeeded');
}

async function registerStaff(registrarAddr, staffAddr, staffName) {
    let err, receipt;
    console.log('\nRegistering a staff --> "' + staffAddr + '" ...');

    // Register a staff
    [err, receipt] = await callContractFunction(
        PizzaCoin.methods.registerStaff(staffAddr, staffName).send({
            from: registrarAddr,
            gas: 6500000,
            gasPrice: 10000000000
        })
    );
    
    if (err) {
        throw new Error(err.message);
    }
    console.log('... succeeded');
}

async function kickStaff(kickerAddr, staffAddr) {
    let err, receipt;
    console.log('\nKicking a staff --> "' + staffAddr + '" ...');

    // Kick a staff
    [err, receipt] = await callContractFunction(
        PizzaCoin.methods.kickStaff(staffAddr).send({
            from: kickerAddr,
            gas: 6500000,
            gasPrice: 10000000000
        })
    );

    if (err) {
        throw new Error(err.message);
    }
    console.log('... succeeded');
}

async function initContracts(projectDeployerAddr) {
    let err, receipt;
    let staffContractAddr, playerContractAddr, teamContractAddr;
    let state;

    // Create PizzaCoinStaff contract
    console.log('\nCreating PizzaCoinStaff contract ...');
    [err, receipt] = await callContractFunction(
        PizzaCoin.methods.createStaffContract().send({
            from: projectDeployerAddr,
            gas: 6500000,
            gasPrice: 10000000000
        })
    );

    if (err) {
        throw new Error(err.message);
    }
    console.log('... succeeded');

    staffContractAddr = receipt.events.ChildContractCreated.returnValues._contract;

    // Create PizzaCoinPlayer contract
    console.log('\nCreating PizzaCoinPlayer contract ...');
    [err, receipt] = await callContractFunction(
        PizzaCoin.methods.createPlayerContract().send({
            from: projectDeployerAddr,
            gas: 6500000,
            gasPrice: 10000000000
        })
    );

    if (err) {
        throw new Error(err.message);
    }
    console.log('... succeeded');

    playerContractAddr = receipt.events.ChildContractCreated.returnValues._contract;

    // Create PizzaCoinTeam contract
    console.log('\nCreating PizzaCoinTeam contract ...');
    [err, receipt] = await callContractFunction(
        PizzaCoin.methods.createTeamContract().send({
            from: projectDeployerAddr,
            gas: 6500000,
            gasPrice: 10000000000
        })
    );

    if (err) {
        throw new Error(err.message);
    }
    console.log('... succeeded');

    teamContractAddr = receipt.events.ChildContractCreated.returnValues._contract;

    // Change all contracts' state from Initial to Registration
    console.log("\nStarting the contracts' registration state ...");
    [err, receipt] = await callContractFunction(
        PizzaCoin.methods.startRegistration().send({
            from: projectDeployerAddr,
            gas: 6500000,
            gasPrice: 10000000000
        })
    );
    console.log('... succeeded');

    if (err) {
        throw new Error(err.message);
    }

    // Check the contracts' state
    console.log("\nValidating the contracts' registration state ...");
    [err, state] = await callContractFunction(
        PizzaCoin.methods.getContractState().call({
            from: projectDeployerAddr
        })
    );

    if (err || state !== 'Registration') {
        throw new Error("Changing contracts' state failed");
    }
    console.log('... succeeded');

    return [staffContractAddr, playerContractAddr, teamContractAddr];
}