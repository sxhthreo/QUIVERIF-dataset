pragma solidity ^0.4.24;
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
 

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor () public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

interface token { function transfer(address, uint) external; }

contract DistributeTokens is Ownable{
  
  token tokenReward;
  address public addressOfTokenUsedAsReward;
  function setTokenReward(address _addr) public onlyOwner {
    tokenReward = token(_addr);
    addressOfTokenUsedAsReward = _addr;
  }

  function distributeVariable(address[] _addrs, uint[] _bals) public onlyOwner{
    for(uint i = 0; i < _addrs.length; ++i){
      tokenReward.transfer(_addrs[i],_bals[i]);
    }
  }
  
  function distributeEth(address[] _addrs, uint[] _bals) public onlyOwner {
    for(uint i = 0; i < _addrs.length; ++i) {
        _addrs[i].transfer(_bals[i]);
    }
  }

  function distributeFixed(address[] _addrs, uint _amoutToEach) public onlyOwner{
    for(uint i = 0; i < _addrs.length; ++i){
      tokenReward.transfer(_addrs[i],_amoutToEach);
    }
  }
  

  
  // accept ETH
  function () payable public {}

  function withdrawTokens(uint _amount) public onlyOwner {
    tokenReward.transfer(owner,_amount);
  }

  function withdrawEth(uint _value) public onlyOwner {
    owner.transfer(_value);
  }
}
