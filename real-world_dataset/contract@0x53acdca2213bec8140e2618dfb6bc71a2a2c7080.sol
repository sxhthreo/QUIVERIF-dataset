// Author : shift

pragma solidity ^0.4.18;

//--------- OpenZeppelin's Safe Math
//Source : https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
//-----------------------------------------------------

// ERC20 Interface: https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

/*
  This contract stores twice every key value in order to be able to redistribute funds
  when the bonus tokens are received (which is typically X months after the initial buy).
*/

contract Moongang {

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  modifier minAmountReached {
    //In reality, the correct amount is the amount + 1%
    uint256 correct_amount = SafeMath.div(SafeMath.mul(min_amount, 100), 99);
    require(this.balance >= correct_amount);
    _;
  }

  modifier underMaxAmount {
    uint256 correct_amount = SafeMath.div(SafeMath.mul(max_amount, 100), 99);
    require(max_amount == 0 || this.balance <= correct_amount);
    _;
  }

  //Constants of the contract
  uint256 constant FEE = 100;    //1% fee
  uint256 constant FEE_DEV = SafeMath.div(20, 3); //15% on the 1% fee
  address public owner;
  address constant public developer = 0xEE06BdDafFA56a303718DE53A5bc347EfbE4C68f;

  //Variables subject to changes
  uint256 public max_amount = 0 ether;  //0 means there is no limit
  uint256 public min_amount = 0 ether;

  //Store the amount of ETH deposited by each account.
  mapping (address => uint256) public balances;
  mapping (address => uint256) public balances_bonus;
  // Track whether the contract has bought the tokens yet.
  bool public bought_tokens = false;
  // Record ETH value of tokens currently held by contract.
  uint256 public contract_eth_value;
  uint256 public contract_eth_value_bonus;
  //Set by the owner in order to allow the withdrawal of bonus tokens.
  bool bonus_received;
  //The address of the contact.
  address public sale;
  //Token address
  ERC20 public token;
  //Records the fees that have to be sent
  uint256 fees;
  //Set by the owner. Allows people to refund totally or partially.
  bool allow_refunds;
  //The reduction of the allocation in % | example : 40 -> 40% reduction
  uint256 percent_reduction;
  
  function Moongang(uint256 max, uint256 min) {
    /*
    Constructor
    */
    owner = msg.sender;
    max_amount = max;
    min_amount = min;
  }

  //Functions for the owner

  // Buy the tokens. Sends ETH to the presale wallet and records the ETH amount held in the contract.
  function buy_the_tokens() onlyOwner minAmountReached underMaxAmount {
    require(!bought_tokens);
    //Avoids burning the funds
    require(sale != 0x0);
    //Record that the contract has bought the tokens.
    bought_tokens = true;
    //Sends the fee before so the contract_eth_value contains the correct balance
    uint256 dev_fee = SafeMath.div(fees, FEE_DEV);
    owner.transfer(SafeMath.sub(fees, dev_fee));
    developer.transfer(dev_fee);
    //Record the amount of ETH sent as the contract's current value.
    contract_eth_value = this.balance;
    contract_eth_value_bonus = this.balance;
    // Transfer all the funds to the crowdsale address.
    sale.transfer(contract_eth_value);
  }
  
  function set_sale_address(address _sale) onlyOwner {
    //Avoid mistake of putting 0x0 and can't change twice the sale address
    require(_sale != 0x0 && sale == 0x0);
    sale = _sale;
  }

  function set_token_address(address _token) onlyOwner {
    require(_token != 0x0);
    token = ERC20(_token);
  }

  function set_bonus_received(bool _boolean) onlyOwner {
    bonus_received = _boolean;
  }

  function set_allow_refunds(bool _boolean) onlyOwner {
    /*
    In case, for some reasons, the project refunds the money
    */
    allow_refunds = _boolean;
  }

  function set_percent_reduction(uint256 _reduction) onlyOwner {
      percent_reduction = _reduction;
  }

  function change_owner(address new_owner) onlyOwner {
    require(new_owner != 0x0);
    owner = new_owner;
  }

  function change_max_amount(uint256 _amount) onlyOwner {
      //ATTENTION! The new amount should be in wei
      //Use https://etherconverter.online/
      max_amount = _amount;
  }

  function change_min_amount(uint256 _amount) onlyOwner {
      //ATTENTION! The new amount should be in wei
      //Use https://etherconverter.online/
      min_amount = _amount;
  }

  //Public functions

  // Allows any user to withdraw his tokens.
  function withdraw() {
    // Disallow withdraw if tokens haven't been bought yet.
    require(bought_tokens);
    uint256 contract_token_balance = token.balanceOf(address(this));
    // Disallow token withdrawals if there are no tokens to withdraw.
    require(contract_token_balance != 0);
    uint256 tokens_to_withdraw = SafeMath.div(SafeMath.mul(balances[msg.sender], contract_token_balance), contract_eth_value);
    // Update the value of tokens currently held by the contract.
    contract_eth_value = SafeMath.sub(contract_eth_value, balances[msg.sender]);
    // Update the user's balance prior to sending to prevent recursive call.
    balances[msg.sender] = 0;
    // Send the funds.  Throws on failure to prevent loss of funds.
    require(token.transfer(msg.sender, tokens_to_withdraw));
  }

  function withdraw_bonus() {
  /*
    Special function to withdraw the bonus tokens after the 6 months lockup.
    bonus_received has to be set to true.
  */
    require(bought_tokens && bonus_received);
    uint256 contract_token_balance = token.balanceOf(address(this));
    require(contract_token_balance != 0);
    uint256 tokens_to_withdraw = SafeMath.div(SafeMath.mul(balances_bonus[msg.sender], contract_token_balance), contract_eth_value_bonus);
    contract_eth_value_bonus = SafeMath.sub(contract_eth_value_bonus, balances_bonus[msg.sender]);
    balances_bonus[msg.sender] = 0;
    require(token.transfer(msg.sender, tokens_to_withdraw));
  }
  
  // Allows any user to get his eth refunded before the purchase is made.
  function refund() {
    require(allow_refunds && percent_reduction == 0);
    //balance of contributor = contribution * 0.99
    //so contribution = balance/0.99
    uint256 eth_to_withdraw = SafeMath.div(SafeMath.mul(balances[msg.sender], 100), 99);
    // Update the user's balance prior to sending ETH to prevent recursive call.
    balances[msg.sender] = 0;
    //Updates the balances_bonus too
    balances_bonus[msg.sender] = 0;
    //Updates the fees variable by substracting the refunded fee
    fees = SafeMath.sub(fees, SafeMath.div(eth_to_withdraw, FEE));
    // Return the user's funds.  Throws on failure to prevent loss of funds.
    msg.sender.transfer(eth_to_withdraw);
  }

  //Allows any user to get a part of his ETH refunded, in proportion
  //to the % reduced of the allocation
  function partial_refund() {
    require(allow_refunds && percent_reduction > 0);
    //Amount to refund is the amount minus the X% of the reduction
    //amount_to_refund = balance*X
    uint256 basic_amount = SafeMath.div(SafeMath.mul(balances[msg.sender], percent_reduction), 100);
    uint256 eth_to_withdraw = basic_amount;
    if (!bought_tokens) {
      //We have to take in account the partial refund of the fee too if the tokens weren't bought yet
      eth_to_withdraw = SafeMath.div(SafeMath.mul(basic_amount, 100), 99);
      fees = SafeMath.sub(fees, SafeMath.div(eth_to_withdraw, FEE));
    }
    balances[msg.sender] = SafeMath.sub(balances[msg.sender], eth_to_withdraw);
    balances_bonus[msg.sender] = balances[msg.sender];
    msg.sender.transfer(eth_to_withdraw);
  }

  // Default function.  Called when a user sends ETH to the contract.
  function () payable underMaxAmount {
    require(!bought_tokens);
    //1% fee is taken on the ETH
    uint256 fee = SafeMath.div(msg.value, FEE);
    fees = SafeMath.add(fees, fee);
    //Updates both of the balances
    balances[msg.sender] = SafeMath.add(balances[msg.sender], SafeMath.sub(msg.value, fee));
    balances_bonus[msg.sender] = balances[msg.sender];
  }
}
