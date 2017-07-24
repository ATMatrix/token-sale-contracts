var MiniMeTokenFactory = artifacts.require("MiniMeTokenFactory");
var ATT = artifacts.require("ATT");
var ATTContribution = artifacts.require("ATTContribution");



contract('Contribution Init Test', function(accounts) {
  let contribution;
  let factory;
  it("Contribution Creation", async function() {
    //try {
      factory = await MiniMeTokenFactory.new();
      contribution = await ATTContribution.new(await factory.address);
    //} catch (error) {
      //assert.fail("Contribution initialze failed.");
    //}
  });

  /*
  it("Check the balance of initialized ATT", function() {
    return ATT.deployed().then(function(instance) {
      return instance.getBalance.call(accounts[0]);
    }).then(function(balance) {
      assert.equal(balance.valueOf(), 0, "0 wasn't in the first account");
    });
  });

  it("The token name should be ATT", function() {
    return ATT.deployed().then(function(instance) {
      return instance.symbol;
    }).then(function(symbol) {
      assert.equal(symbol, "ATT", "token's symbol name is not ATT");
    });
  });
  */
});
