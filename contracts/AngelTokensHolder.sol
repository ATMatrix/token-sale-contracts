pragma solidity ^0.4.11;

/*
    Copyright 2017, Jordi Baylina

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/// @title AngelTokensHolder Contract
/// @author hackfisher
/// @dev This contract will hold the tokens of the angels and other parts.
///  Half of the Tokens will not be able to be collected until the contribution period ends.
///  period ends. The other half will not be able to be collected until 6 months after the contribution period ends.


//  collectable tokens
//   |                           |--------   vestedTokens rect
//   |                           |
//   |                           |
//   |                           |
//   |                           |
//   |    _______________________|
//   |   |
//   |   |
//   |   |
//   |   |
//   |   |
//   |   |
//   +===+=======================+------------> time
//     Contrib                 6 Months
//       End


import "./MiniMeToken.sol";
import "./StatusContribution.sol";
import "./SafeMath.sol";
import "./ERC20Token.sol";


contract AngelTokensHolder is Owned {
    using SafeMath for uint256;

    uint256 collectedTokens;
    StatusContribution contribution;
    MiniMeToken att;

    function AngelTokensHolder(address _owner, address _contribution, address _att) {
        owner = _owner;
        contribution = StatusContribution(_contribution);
        att = MiniMeToken(_att);
    }


    /// @notice The Owner will call this method to extract the tokens
    function collectTokens() public onlyOwner {
        uint256 balance = att.balanceOf(address(this));
        uint256 total = collectedTokens.add(balance);

        uint256 finalizedTime = contribution.finalizedTime();

        require(finalizedTime > 0);

        uint256 canExtract = total.div(2);

        if (getTime() > finalizedTime.add(months(6))) {
            canExtract = total;
        }

        canExtract = canExtract.sub(collectedTokens);

        if (canExtract > balance) {
            canExtract = balance;
        }

        collectedTokens = collectedTokens.add(canExtract);
        assert(att.transfer(owner, canExtract));

        TokensWithdrawn(owner, canExtract);
    }

    function months(uint256 m) internal returns (uint256) {
        return m.mul(30 days);
    }

    function getTime() internal returns (uint256) {
        return now;
    }


    //////////
    // Safety Methods
    //////////

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyOwner {
        require(_token != address(att));
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }

        ERC20Token token = ERC20Token(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
        ClaimedTokens(_token, owner, balance);
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event TokensWithdrawn(address indexed _holder, uint256 _amount);
}
