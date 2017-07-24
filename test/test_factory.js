//var MiniMeTokenFactory = artifacts.require("MiniMeTokenFactory");
var MiniMeTokenFactory = artifacts.require("MiniMeTokenFactory");

contract('Factory Init Test', function(accounts) {

  it("Check the initialize of token factory", function() {

    return MiniMeTokenFactory.deployed().then(function(f){
      return f.address;
    });
  });
});
