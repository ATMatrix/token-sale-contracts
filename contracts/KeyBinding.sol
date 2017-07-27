pragma solidity ^0.4.11;

import "./Owned.sol";

contract KeyBinding is Owned {
    mapping (address => string) public keys;

    string public  secondRoundKey;      // what kind of key would it like, if it is EVM, then may be no need to bind it.
    string public  reserveKey;          // Public key of founders

    function KeyBinding(string _secondRoundKey, string _reserveKey) {
        secondRoundKey = _secondRoundKey;
        reserveKey = _reserveKey;
    }

    function initialize() public onlyOwner {
        // Address 0xb1 is provably non-transferrable
        keys[0xb1] = secondRoundKey;
        LogRegister(0xb1, secondRoundKey);

        // Address 0xb2 is provably non-transferrable
        keys[0xb2] = reserveKey;
        // tokens reserve to 0xb2
        LogRegister(0xb2, reserveKey);
    }

    // Value should be a public key.  Read full key import policy.
    // Manually registering requires a base58
    // encoded using the ATMatrix public key format.
    function register(string key) {
        // TODO: Do we need to set up a deadline for end of the binding keys.
        assert(bytes(key).length <= 64);
        
        keys[msg.sender] = key;
        LogRegister(msg.sender, key);
    }

    event LogRegister (address user, string key);
}