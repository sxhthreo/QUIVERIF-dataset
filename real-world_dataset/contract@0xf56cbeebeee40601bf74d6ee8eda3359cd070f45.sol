pragma solidity ^0.4.19;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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
    assert(c >= a);
    return c;
  }
}

/* erc20 interface*/
interface ERC20 {

	function totalSupply() public view returns (uint256);
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	function allowance(address owner, address spender) public view returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}


/* Nuk Test token */
contract NukTestToken is ERC20 {
	
	using SafeMath for uint256;	
	address public owner;	

	string public constant name = "NukTest"; 
  	string public constant symbol = "Nkt"; 
  	uint8 public constant decimals = 0; 

  	uint256 public constant INITIAL_SUPPLY = 20000000000;

	uint256 totalSupply_;

	mapping(address => uint256) balances;
	mapping (address => mapping (address => uint256)) internal allowed;

	event Burn(address indexed burner, uint256 value);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	modifier onlyOwner() {
    	require(msg.sender == owner);
    	_;
  	}

	function NukTestToken() public {
        owner = msg.sender;		
		totalSupply_ = INITIAL_SUPPLY;
    	balances[owner] = INITIAL_SUPPLY;
    	Transfer(0x0, owner, INITIAL_SUPPLY);
	}


	function totalSupply() public view returns (uint256) {
    	return totalSupply_;
  	}

  	function transfer(address _to, uint256 _value) public returns (bool) {
	    require(_to != address(0));
	    require(_value <= balances[msg.sender]);

	    // SafeMath.sub will throw if there is not enough balance.
	    balances[msg.sender] = balances[msg.sender].sub(_value);
	    balances[_to] = balances[_to].add(_value);
	    Transfer(msg.sender, _to, _value);
	    return true;
	}

	function balanceOf(address _owner) public view returns (uint256 balance) {
	    return balances[_owner];
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
	    require(_to != address(0));
	    require(_value <= balances[_from]);
	    require(_value <= allowed[_from][msg.sender]);

	    balances[_from] = balances[_from].sub(_value);
	    balances[_to] = balances[_to].add(_value);
	    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
	    Transfer(_from, _to, _value);
	    return true;
	 }

	 function approve(address _spender, uint256 _value) public returns (bool) {
	    allowed[msg.sender][_spender] = _value;
	    Approval(msg.sender, _spender, _value);
	    return true;
	 }

	function allowance(address _owner, address _spender) public view returns (uint256) {
    	return allowed[_owner][_spender];
  	}

  	function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
	    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
	    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
	    return true;
	}

	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
	    uint oldValue = allowed[msg.sender][_spender];
	    if (_subtractedValue > oldValue) {
	      allowed[msg.sender][_spender] = 0;
	    } else {
	      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
	    }
	    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
	    return true;
	}

	function burn(uint256 _value) public {
	    require(_value <= balances[msg.sender]);   
		address burner = msg.sender;
	    balances[burner] = balances[burner].sub(_value);
	    totalSupply_ = totalSupply_.sub(_value);
	    Burn(burner, _value);
	}


	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}

}
