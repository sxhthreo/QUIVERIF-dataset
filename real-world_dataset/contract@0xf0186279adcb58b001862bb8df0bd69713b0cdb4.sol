pragma solidity ^0.4.11;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
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

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
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

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract VanilCoin is MintableToken {
  	
	string public name = "Vanil";
  	string public symbol = "VAN";
  	uint256 public decimals = 18;
  
  	// tokens locked for one week after ICO, 8 Oct 2017, 0:0:0 GMT: 1507420800
  	uint public releaseTime = 1507420800;
  
	modifier canTransfer(address _sender, uint256 _value) {
		require(_value <= transferableTokens(_sender, now));
	   	_;
	}
	
	function transfer(address _to, uint256 _value) canTransfer(msg.sender, _value) returns (bool) {
		return super.transfer(_to, _value);
	}
	
	function transferFrom(address _from, address _to, uint256 _value) canTransfer(_from, _value) returns (bool) {
		return super.transferFrom(_from, _to, _value);
	}
	
	function transferableTokens(address holder, uint time) constant public returns (uint256) {
		
		uint256 result = 0;
				
		if(time > releaseTime){
			result = balanceOf(holder);
		}
		
		return result;
	}
	
}



contract ETH888CrowdsaleS1 {

	using SafeMath for uint256;
	
	// The token being sold
	MintableToken public token;
	
	// address where funds are collected
	address public wallet;
	
	// how many token units a buyer gets per wei
	uint256 public rate = 1250;
	
	// timestamps for ICO starts and ends
	uint public startTimestamp;
	uint public endTimestamp;
	
	// amount of raised money in wei
	uint256 public weiRaised;
	
	// first round ICO cap
	uint256 public cap;
	
	/**
	   * event for token purchase logging
	   * @param purchaser who paid for the tokens
	   * @param beneficiary who got the tokens
	   * @param value weis paid for purchase
	   * @param amount amount of tokens purchased
	   */ 
	event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
	
	function ETH888CrowdsaleS1(address _wallet) {
		
		require(_wallet != 0x0);
		
		// 11 Aug 2017, 00:00:00 GMT: 1502409600
		startTimestamp = 1502409600;
		
		// 30 Sep 2017, 23:59:59 GMT: 1506815999
		endTimestamp = 1506815999;
		
		token = createTokenContract();
		
		// maximum 8000 ETH for this stage 1 crowdsale
		cap = 8000 ether;
		
		wallet = _wallet;
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

		// calculate token amount to be created
		uint256 tokens = weiAmount.mul(rate);

		// update state
		weiRaised = weiRaised.add(weiAmount);

		token.mint(beneficiary, tokens);
		TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

		forwardFunds();
	}

	// send ether to the fund collection wallet
	function forwardFunds() internal {
		wallet.transfer(msg.value);
	}	
	
	// @return true if investors can buy at the moment
	function validPurchase() internal constant returns (bool) {
		bool withinCap = weiRaised.add(msg.value) <= cap;
		
		uint current = now;
		bool withinPeriod = current >= startTimestamp && current <= endTimestamp;
		bool nonZeroPurchase = msg.value != 0;
		
		return withinPeriod && nonZeroPurchase && withinCap && msg.value >= 1000 szabo;
	}

	// @return true if crowdsale event has ended
	function hasEnded() public constant returns (bool) {
		bool capReached = weiRaised >= cap;
		
		return now > endTimestamp || capReached;
	}
	
	// creates the token to be sold.
	function createTokenContract() internal returns (MintableToken) {
		return new VanilCoin();
	}
	
}
