pragma solidity ^0.4.11;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0 uint256 c = a / b;
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract token { function transfer(address receiver, uint amount){  } }
contract Crowdsale {
  using SafeMath for uint256;

  // uint256 durationInMinutes;
  // address where funds are collected
  address public wallet;
  // token address
  address public addressOfTokenUsedAsReward;

  uint256 public price = 300;
  uint256 public minBuy;
  uint256 public maxBuy;

  token tokenReward;

  // mapping (address => uint) public contributions;
  


  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  // uint256 public endTime;
  // amount of raised money in wei
  uint256 public weiRaised;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale() {
    //You will change this to your wallet where you need the ETH 
    wallet = 0xc076b054EF62aCCE747175F698FC3Dbec9B7A36F;
    // durationInMinutes = _durationInMinutes;
    //Here will come the checksum address we got
    addressOfTokenUsedAsReward = 0xd62e9252F1615F5c1133F060CF091aCb4b0faa2b;


    tokenReward = token(addressOfTokenUsedAsReward);
  }

  bool public started = false;

  function startSale(uint256 _delayInMinutes){
    if (msg.sender != wallet) throw;
    startTime = now + _delayInMinutes*1 minutes;
    started = true;
  }

  function stopSale(){
    if(msg.sender != wallet) throw;
    started = false;
  }

  function setPrice(uint256 _price){
    if(msg.sender != wallet) throw;
    price = _price;
  }

  function setMinBuy(uint256 _minBuy){
    if(msg.sender!=wallet) throw;
    minBuy = _minBuy;
  }

  function setMaxBuy(uint256 _maxBuy){
    if(msg.sender != wallet) throw;
    maxBuy = _maxBuy;
  }

  function changeWallet(address _wallet){
    if(msg.sender != wallet) throw;
    wallet = _wallet;
  }

  function changeTokenReward(address _token){
    if(msg.sender!=wallet) throw;
    tokenReward = token(_token);
  }

  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be sent
    uint256 tokens = (weiAmount) * price;//weiamount * price 

    if(minBuy!=0){
      if(tokens < minBuy*10**18) throw;
    }

    if(maxBuy!=0){
      if(tokens > maxBuy*10**18) throw;
    }

    // update state
    weiRaised = weiRaised.add(weiAmount);
    
    // if(contributions[msg.sender].add(weiAmount)>10*10**18) throw;
    // contributions[msg.sender] = contributions[msg.sender].add(weiAmount);

    tokenReward.transfer(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    // wallet.transfer(msg.value);
    if (!wallet.send(msg.value)) {
      throw;
    }
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = started&&(now>=startTime);
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  function withdrawTokens(uint256 _amount) {
    if(msg.sender!=wallet) throw;
    tokenReward.transfer(wallet,_amount);
  }
}
