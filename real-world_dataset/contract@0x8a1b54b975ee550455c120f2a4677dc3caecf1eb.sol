/*
Capital Technologies & Research - Bounty Distribution Smart Contract
https://www.mycapitalco.in
*/

pragma solidity 0.4.24;
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract CapitalBountyDelivery is Ownable {
using SafeMath for uint256;
    ERC20 public token_call;
    ERC20 public token_callg;
	mapping (address => bool) public distributedFirst;
	mapping (address => bool) public distributedSecond;
	uint public sentFirst;
	uint public sentSecond;
    event DistributeFirst(address indexed userWallet, uint token_call, uint token_callg);
	event DistributeSecond(address indexed userWallet, uint token_call, uint token_callg);
	event AdminWithdrawn(address indexed adminWallet, uint token_call, uint token_callg);
    constructor (ERC20 _token_call, ERC20 _token_callg) public {
        require(_token_call != address(0));
        require(_token_callg != address(0));
        token_call = _token_call;
        token_callg = _token_callg;
    }
    function () public payable {
    }
    function sendFirst(address userWallet, uint call) public onlyOwner {
		require(now >= 1531958400);
		require(userWallet != address(0));
		require(!distributedFirst[userWallet]);
        uint _call = call * 10 ** 18;
		uint _callg = _call.mul(200);
		distributedFirst[userWallet] = true;
        require(token_call.transfer(userWallet, _call));
        require(token_callg.transfer(userWallet, _callg));
		sentFirst = sentFirst.add(_call);
        emit DistributeFirst(userWallet, _call, _callg);
    }
	function sendSecond(address userWallet, uint call) public onlyOwner {
		require(now >= 1538179200);
		require(userWallet != address(0));
		require(!distributedSecond[userWallet]);
        uint _call = call * 10 ** 18;
		uint _callg = _call.mul(200);
		distributedSecond[userWallet] = true;
        require(token_call.transfer(userWallet, _call));
        require(token_callg.transfer(userWallet, _callg));
		sentSecond = sentSecond.add(_call);
        emit DistributeSecond(userWallet, _call, _callg);
    }
	function sendFirstBatch(address[] _userWallet, uint[] call) public onlyOwner {
		require(now >= 1531958400);
		for(uint256 i = 0; i < _userWallet.length; i++) {
			if (!distributedFirst[_userWallet[i]]) {
				uint _call = call[i] * 10 ** 18;
				uint _callg = _call.mul(200);
				distributedFirst[_userWallet[i]] = true;
				require(token_call.transfer(_userWallet[i], _call));
				require(token_callg.transfer(_userWallet[i], _callg));
				sentFirst = sentFirst.add(_call);
				emit DistributeFirst(_userWallet[i], _call, _callg);
			}
		}
    }
	function sendSecondBatch(address[] _userWallet, uint[] call) public onlyOwner {
		require(now >= 1538179200); 
		for(uint256 i = 0; i < _userWallet.length; i++) {
			if (!distributedSecond[_userWallet[i]]) {
				uint _call = call[i] * 10 ** 18;
				uint _callg = _call.mul(200);
				distributedSecond[_userWallet[i]] = true;
				require(token_call.transfer(_userWallet[i], _call));
				require(token_callg.transfer(_userWallet[i], _callg));
				sentSecond = sentSecond.add(_call);
				emit DistributeSecond(_userWallet[i], _call, _callg);
			}
		}
    }
	function withdrawTokens(address adminWallet) public onlyOwner {
        require(adminWallet != address(0));
        uint call_balance = token_call.balanceOf(this);
        uint callg_balance = token_callg.balanceOf(this);
        token_call.transfer(adminWallet, call_balance);
        token_callg.transfer(adminWallet, callg_balance);
        emit AdminWithdrawn(adminWallet, call_balance, callg_balance);
    }
}
