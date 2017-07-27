pragma solidity ^0.4.11;

import "./Owned.sol";
import "./MiniMeToken.sol";
import "./SafeMath.sol";
import "./ERC20Token.sol";

contract ATTContribution is Owned, TokenController {
    using SafeMath for uint256;

    uint256 constant public failSafeLimit = 300000 ether;
    uint256 constant public exchangeRate = 10000;   // will be set before the token sale.
    uint256 constant public maxGasPrice = 50000000000;  // 50GWei
    uint256 constant public maxCallFrequency = 100;

    uint256 constant public maxFirstRoundTokenLimit = 90000000 ether; // ATT have same precision with ETH


    MiniMeToken public  ATT;            // The ATT token itself
    string public  secondRoundKey;      // what kind of key would it like, if it is EVM, then may be no need to bind it.
    string public  reserveKey;          // Public key of founders

    address public attController;

    address public destEthFoundation;
    address public destTokensAngel;

    mapping (address => string) public keys;

    uint256 public startTime;
    uint256 public endTime;

    uint256 public totalCollected;
    uint256 public totalTokenGenerated;

    uint256 public finalizedBlock;
    uint256 public finalizedTime;

    mapping (address => uint256) public lastCallBlock;

    bool public paused;

    modifier initialized() {
        require(address(ATT) != 0x0);
        _;
    }

    modifier contributionOpen() {
        require(time() >= startTime &&
              time() <= endTime &&
              finalizedBlock == 0 &&
              address(ATT) != 0x0);
        _;
    }

    modifier notPaused() {
        require(!paused);
        _;
    }

    function ATTContribution() {
        paused = false;
    }


    /// @notice This method should be called by the owner before the contribution
    ///  period starts This initializes most of the parameters
    /// @param _att Address of the ATT token contract
    /// @param _attController Token controller for the ATT that will be transferred after
    ///  the contribution finalizes.
    /// @param _startTime Time when the contribution period starts
    /// @param _endTime The time that the contribution period ends
    /// @param _destEthFoundation Destination address where the contribution ether is sent
    /// @param _destTokensAngel Address where the tokens for the angels are sent
    function initialize(
        address _att,
        address _attController,
        uint _startTime,
        uint _endTime,
        address _destEthFoundation,
        address _destTokensAngel
    ) public onlyOwner {
      // Initialize only once
      require(address(ATT) == 0x0);

      ATT = MiniMeToken(_att);
      require(ATT.totalSupply() == 0);
      require(ATT.controller() == address(this));
      require(ATT.decimals() == 18);  // Same amount of decimals as ETH

      startTime = _startTime;
      endTime = _endTime;

      assert(startTime < endTime);

      require(_attController != 0x0);
      attController = _attController;

      require(_destEthFoundation != 0x0);
      destEthFoundation = _destEthFoundation;

      require(_destTokensAngel != 0x0);
      destTokensAngel = _destTokensAngel;

      // Address 0xb1 is provably non-transferrable
      keys[0xb1] = secondRoundKey;
      LogRegister(0xb1, secondRoundKey);

      // Address 0xb2 is provably non-transferrable
      keys[0xb2] = reserveKey;
      // tokens reserve to 0xb2
      LogRegister(0xb2, reserveKey);
  }

  /// @notice If anybody sends Ether directly to this contract, consider he is
  ///  getting ATTs.
  function () public payable notPaused {
      proxyPayment(msg.sender);
  }


  //////////
  // MiniMe Controller functions
  //////////

  /// @notice This method will generally be called by the ATT token contract to
  ///  acquire ATTs. Or directly from third parties that want to acquire ATTs in
  ///  behalf of a token holder.
  /// @param _th ATT holder where the ATTs will be minted.
  function proxyPayment(address _th) public payable notPaused initialized contributionOpen returns (bool) {
      require(_th != 0x0);

      doBuy(_th, msg.value);
      return true;
  }

  function onTransfer(address, address, uint256) public returns (bool) {
      return false;
  }

  function onApprove(address, address, uint256) public returns (bool) {
      return false;
  }

  function doBuy(address _th, uint256 _toFund) internal {
      assert(msg.value >= _toFund);  // Not needed, but double check.
      assert(totalCollected <= failSafeLimit);
      assert(totalTokenGenerated < maxFirstRoundTokenLimit);

      uint256 endOfFirstWeek = startTime.add(1 weeks);
      uint256 endOfSecondWeek = startTime.add(1 weeks);
      uint256 finalExchangeRate = exchangeRate;
      if (now < endOfFirstWeek)
      {
          // 10% Bonus in first week
          finalExchangeRate = exchangeRate.mul(110).div(100);
      } else if (now < endOfSecondWeek)
      {
          // 5% Bonus in first week
          finalExchangeRate = exchangeRate.mul(105).div(100);
      }

      if (_toFund > 0) {
          uint256 tokensGenerated = _toFund.mul(finalExchangeRate);

          uint256 tokensToBeGenerated = totalTokenGenerated.add(tokensGenerated);
          if (tokensToBeGenerated > maxFirstRoundTokenLimit)
          {
              tokensGenerated = maxFirstRoundTokenLimit - totalTokenGenerated;
              _toFund = tokensGenerated.div(finalExchangeRate);
          }

          assert(ATT.generateTokens(_th, tokensGenerated));
          destEthFoundation.transfer(_toFund);

          totalTokenGenerated = totalTokenGenerated.add(tokensGenerated);
          totalCollected = totalCollected.add(_toFund);
          NewSale(_th, _toFund, tokensGenerated);
      }

      uint256 toReturn = msg.value.sub(_toFund);
      if (toReturn > 0) {
          // TODO: If the call comes from the Token controller,
          // then we return it to the token Holder.
          // Otherwise we return to the sender.
          if (msg.sender == address(ATT)) {
              _th.transfer(toReturn);
          } else {
              msg.sender.transfer(toReturn);
          }
      }
  }

  // NOTE on Percentage format
  // Right now, Solidity does not support decimal numbers. (This will change very soon)
  //  So in this contract we use a representation of a percentage that consist in
  //  expressing the percentage in "x per 10**18"
  // This format has a precision of 16 digits for a percent.
  // Examples:
  //  3%   =   3*(10**16)
  //  100% = 100*(10**16) = 10**18
  //
  // To get a percentage of a value we do it by first multiplying it by the percentage in  (x per 10^18)
  //  and then divide it by 10**18
  //
  //              Y * X(in x per 10**18)
  //  X% of Y = -------------------------
  //               100(in x per 10**18)
  //


  /// @notice This method will can be called by the owner before the contribution period
  ///  end or by anybody after the `endBlock`. This method finalizes the contribution period
  ///  by creating the remaining tokens and transferring the controller to the configured
  ///  controller.
  function finalize() public initialized {
      require(time() >= startTime);
      require(msg.sender == owner || time() > endTime);
      require(finalizedBlock == 0);

      finalizedBlock = getBlockNumber();
      finalizedTime = now;

      uint256 tokensToSecondRound = 90000000 ether;

      uint256 tokensToReserve = 90000000 ether;

      uint256 tokensToAngelAndOther = 30000000 ether;

      // totalTokenGenerated should equal to ATT.totalSupply()

      // If tokens in first round is not sold out, they will be added to second round and frozen together
      tokensToSecondRound = tokensToSecondRound.add(maxFirstRoundTokenLimit).sub(totalTokenGenerated);

      uint256 totalTokens = 300000000 ether;

      require(totalTokens == ATT.totalSupply().add(tokensToSecondRound).add(tokensToReserve).add(tokensToAngelAndOther));

      assert(ATT.generateTokens(0xb1, tokensToSecondRound));

      assert(ATT.generateTokens(0xb2, tokensToReserve));

      assert(ATT.generateTokens(destTokensAngel, tokensToAngelAndOther));

      // totalTokens should equal to ATT.totalSupply()

      ATT.changeController(attController);

      Finalized();
  }

  function percent(uint256 p) internal returns (uint256) {
      return p.mul(10**16);
  }

  function time() constant returns (uint) {
      return block.timestamp;
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

  //////////
  // Constant functions
  //////////

  /// @return Total tokens issued in weis.
  function tokensIssued() public constant returns (uint256) {
      return ATT.totalSupply();
  }

  //////////
  // Testing specific methods
  //////////

  /// @notice This function is overridden by the test Mocks.
  function getBlockNumber() internal constant returns (uint256) {
      return block.number;
  }

  //////////
  // Safety Methods
  //////////

  /// @notice This method can be used by the controller to extract mistakenly
  ///  sent tokens to this contract.
  /// @param _token The address of the token contract that you want to recover
  ///  set to 0 in case you want to extract ether.
  function claimTokens(address _token) public onlyOwner {
      if (ATT.controller() == address(this)) {
          ATT.claimTokens(_token);
      }
      if (_token == 0x0) {
          owner.transfer(this.balance);
          return;
      }

      ERC20Token token = ERC20Token(_token);
      uint256 balance = token.balanceOf(this);
      token.transfer(owner, balance);
      ClaimedTokens(_token, owner, balance);
  }

  /// @notice Pauses the contribution if there is any issue
  function pauseContribution() onlyOwner {
      paused = true;
  }

  /// @notice Resumes the contribution
  function resumeContribution() onlyOwner {
      paused = false;
  }

  event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
  event NewSale(address indexed _th, uint256 _amount, uint256 _tokens);
  event Finalized();

  event LogBuy      (uint window, address user, uint amount);
  event LogClaim    (uint window, address user, uint amount);
  event LogRegister (address user, string key);
  event LogCollect  (uint amount);
  event LogFreeze   ();
}
