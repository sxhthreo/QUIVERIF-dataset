pragma solidity ^0.4.19;

// Created by your Messiah, you are just little multimedia goats

contract ERC20MAD {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
/*
   ERC20 interface
  see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20MAD {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
/*  SafeMath - the lowest gas library
  Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
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

contract SeaToken is ERC20MAD {
    
  using SafeMath for uint256;
  mapping(address => uint256) balances;
      modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }
 
 function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
 
  /*
  Gets the balance of the specified address.
   param _owner The address to query the the balance of. 
   return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
 
}
 
/* Implementation of the basic standard token.
  https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is ERC20, SeaToken {
 
  mapping (address => mapping (address => uint256)) allowed;
 
  /*
    Transfer tokens from one address to another
    param _from address The address which you want to send tokens from
    param _to address The address which you want to transfer to
    param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];
 
    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);
 
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
 
  /*
  Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   param _spender The address which will spend the funds.
   param _value The amount of Roman Lanskoj's tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {
 
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
 
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
 
  /*
  Function to check the amount of tokens that an owner allowed to a spender.
  param _owner address The address which owns the funds.
  param _spender address The address which will spend the funds.
  return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
}
}
 
/*
The Ownable contract has an owner address, and provides basic authorization control
 functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    //owner
  address public owner;
  function Ownable() {
    owner = 0x66C2E6dd4B83CA376EFA05809Ae8e0C26911f46B;
  }
  /*
  Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
 
  /*
  Allows the current owner to transfer control of the contract to a newOwner.
  param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }
}
    
contract MARIADARIOCoin is StandardToken, Ownable {
  string public constant name = "MARIADARIO";
  string public constant symbol = "MAD";
  uint public constant decimals = 3;
  uint256 public initialSupply;
   string public price = '1 billion Dollars per 1 MAD';
    
  function MARIADARIOCoin () { 
     totalSupply = 100000000 * 10 ** decimals;
      balances[owner] = totalSupply;
      initialSupply = totalSupply; 
        Transfer(2017, this, totalSupply);
        Transfer(this, owner, totalSupply);
  }
}


/*

  Ⓒ2017 MARIADARIO
  Token for friends
  xsweep2@gmail.com

 */
