pragma solidity ^0.4.25;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a && c >= b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }


}




contract owned { //Contract used to only allow the owner to call some functions
	address public owner;

	function owned() public {
	owner = msg.sender;
	}

	modifier onlyOwner {
	require(msg.sender == owner);
	_;
	}

	function transferOwnership(address newOwner) onlyOwner public {
	owner = newOwner;
	}
}


contract TokenERC20 {

	using SafeMath for uint256;
	// Public variables of the token
	string public name;
	string public symbol;
	uint8 public decimals = 18;
	//
	uint256 public totalSupply;


	// This creates an array with all balances
	mapping (address => uint256) public balanceOf;
	mapping (address => mapping (address => uint256)) public allowance;

	// This generates a public event on the blockchain that will notify clients
	event Transfer(address indexed from, address indexed to, uint256 value);

	// This notifies clients about the amount burnt
	event Burn(address indexed from, uint256 value);


	function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
		totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
		name = tokenName;                                   // Set the name for display purposes
		symbol = tokenSymbol;                               // Set the symbol for display purposes
	}


	function _transfer(address _from, address _to, uint _value) internal {
		// Prevent transfer to 0x0 address. Use burn() instead
		require(_to != 0x0);
		// Check for overflows
		// Save this for an assertion in the future
		uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
		// Subtract from the sender
		balanceOf[_from] = balanceOf[_from].sub(_value);
		// Add the same to the recipient
		balanceOf[_to] = balanceOf[_to].add(_value);
		emit Transfer(_from, _to, _value);
		// Asserts are used to use static analysis to find bugs in your code. They should never fail
		assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
	}


	function transfer(address _to, uint256 _value) public {
		_transfer(msg.sender, _to, _value);
	}


	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
		_transfer(_from, _to, _value);
		return true;
	}


	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowance[msg.sender][_spender] = _value;
		return true;
	}


	function burn(uint256 _value) public returns (bool success) {
		balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);            // Subtract from the sender
		totalSupply = totalSupply.sub(_value);                      // Updates totalSupply
		emit Burn(msg.sender, _value);
		return true;
	}



	function burnFrom(address _from, uint256 _value) public returns (bool success) {
		balanceOf[_from] = balanceOf[_from].sub(_value);                         // Subtract from the targeted balance
		allowance[_from][msg.sender] =allowance[_from][msg.sender].sub(_value);             // Subtract from the sender's allowance
		totalSupply = totalSupply.sub(_value);                              // Update totalSupply
		emit Burn(_from, _value);
		return true;
	}


}

/******************************************/
/*       Token STARTS HERE       */
/******************************************/

contract Token is owned, TokenERC20  {

	//Modify these variables
	uint256 _initialSupply=420000000; 
	string _tokenName="testdist";  
	string _tokenSymbol="tsdt";
	address wallet1 = 0x8012Eb27b9F5Ac2b74A975a100F60d2403365871;
	uint256 public startTime;

	mapping (address => bool) public frozenAccount;

	/* Initializes contract with initial supply tokens to the creator of the contract */
	function Token( ) TokenERC20(_initialSupply, _tokenName, _tokenSymbol) public {

		startTime = now;

		balanceOf[wallet1] = totalSupply;

	}

	function _transfer(address _from, address _to, uint _value) internal {
		require(_to != 0x0);

		uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
		balanceOf[_from] = balanceOf[_from].sub(_value);
		balanceOf[_to] = balanceOf[_to].add(_value);
		emit Transfer(_from, _to, _value);
		assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
	}


}
