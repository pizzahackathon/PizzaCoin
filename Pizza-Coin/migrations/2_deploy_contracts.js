var PizzaCoin = artifacts.require("./PizzaCoin.sol");
var PizzaCoinStaffDeployer = artifacts.require("./PizzaCoinStaffDeployer.sol");
var PizzaCoinPlayerDeployer = artifacts.require("./PizzaCoinPlayerDeployer.sol");
var PizzaCoinTeamDeployer = artifacts.require("./PizzaCoinTeamDeployer.sol");
var PizzaCoinCodeLib = artifacts.require("./PizzaCoinCodeLib.sol");
var PizzaCoinCodeLib2 = artifacts.require("./PizzaCoinCodeLib2.sol");

/*var PizzaCoinStaff = artifacts.require("./PizzaCoinStaff.sol");
var PizzaCoinPlayer = artifacts.require("./PizzaCoinPlayer.sol");
var PizzaCoinTeam = artifacts.require("./PizzaCoinTeam.sol");*/

module.exports = function(deployer) {
  deployer.deploy(PizzaCoinStaffDeployer);
  deployer.deploy(PizzaCoinPlayerDeployer);
  deployer.deploy(PizzaCoinTeamDeployer);
  deployer.deploy(PizzaCoinCodeLib);
  deployer.deploy(PizzaCoinCodeLib2);

  deployer.link(PizzaCoinStaffDeployer, PizzaCoin);
  deployer.link(PizzaCoinPlayerDeployer, PizzaCoin);
  deployer.link(PizzaCoinTeamDeployer, PizzaCoin);
  deployer.link(PizzaCoinCodeLib, PizzaCoin);
  deployer.link(PizzaCoinCodeLib2, PizzaCoin);

  /*deployer.deploy(PizzaCoinStaff, 3);
  deployer.deploy(PizzaCoinPlayer, 3);
  deployer.deploy(PizzaCoinTeam);*/

  deployer.deploy(PizzaCoin, "Phuwanai Thummavet", 3);
};