pragma solidity ^0.4.2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/ATT.sol";

contract TestATT {

  function testSettingsWithDeployedContract() {
    ATT att = ATT(DeployedAddresses.ATT());

    //string memory symbol = "ATT";

    //Assert.equal(att.symbol(), symbol, "ATT token contract should have the symbol of ATT.");
  }

  function testSettingsWithWithNewATT() {
    MiniMeTokenFactory factory = new MiniMeTokenFactory();
    ATT att = new ATT(factory);

    //string memory symbol = "ATT";

    //Assert.equal(att.symbol(), symbol, "ATT token contract should have the symbol of ATT.");
  }

}
