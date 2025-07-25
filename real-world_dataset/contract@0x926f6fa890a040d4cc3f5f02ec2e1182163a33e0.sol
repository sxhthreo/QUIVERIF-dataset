pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


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
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
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
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}


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
  function Ownable() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
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

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
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
}


contract OilVisionShare is StandardToken, Ownable {
    using SafeMath for uint;

    string public name = "Oil Vision Share";
    string public symbol = "OVS";
	
    string public constant description = "http://oil.vision The oil.vision Project is an investment platform managed by the Japanese company eKen. We invest in the oil industry around the world. In our project we use both traditional investments in yen and modern investments in cryptocurrency.";
	
    uint public decimals = 2;
	uint public constant INITIAL_SUPPLY = 1000000000 * 10**2 ;

	/* Distributors */
    mapping (address => bool) public distributors;
	/* Distributors amount */
    mapping (address => uint) private distributorsAmount;
	
	address[] public distributorsList;

    bool public byuoutActive;
    uint public byuoutCount;
    uint public priceForBasePart;

    function OilVisionShare() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }

	/* Token can receive ETH */
    function() external payable {

    }

	/* define who can transfer Tokens: owner and distributors */
    modifier canTransfer() {
        require(distributors[msg.sender] || msg.sender == owner);
        _;
    }
	
	/* set distributor for address: state true/false = on/off distributing */
    function setDistributor(address distributor, bool state, uint amount) external onlyOwner{
		distributorsList.push(distributor);
        distributors[distributor] = state;
		/* new */
        distributorsAmount[distributor] = amount;
    }
	/* set distributor for address: state true/false = on/off distributing */
    function setDistributorAmount(address distributor, bool state, uint amount) external onlyOwner{
        distributors[distributor] = state;
        distributorsAmount[distributor] = amount;
    }
	
	
	/* buyout mode is set to flag "status" value, true/false */
    function setByuoutActive(bool status) public onlyOwner {
        byuoutActive = status;
    }

	/* set Max token count to buyout */
    function setByuoutCount(uint count) public onlyOwner {
        byuoutCount = count;
    }

	/* set Token base-part prise in "wei" */
    function setPriceForBasePart(uint newPriceForBasePart) public onlyOwner {
        priceForBasePart = newPriceForBasePart;
    }

	/* send Tokens to any investor by owner or distributor */
    function sendToInvestor(address investor, uint value) public canTransfer {
        require(investor != 0x0 && value > 0);
        require(value <= balances[owner]);

		/* new */
		require(distributorsAmount[msg.sender] >= value && value > 0);
		distributorsAmount[msg.sender] = distributorsAmount[msg.sender].sub(value);
		
        balances[owner] = balances[owner].sub(value);
        balances[investor] = balances[investor].add(value);
        addTokenHolder(investor);
        Transfer(owner, investor, value);
    }

	/* transfer method, with byuout */
    function transfer(address to, uint value) public returns (bool success) {
        require(to != 0x0 && value > 0);

        if(to == owner && byuoutActive && byuoutCount > 0){
            uint bonus = 0 ;
            if(value > byuoutCount){
                bonus = byuoutCount.mul(priceForBasePart);
                byuoutCount = 0;
            }else{
                bonus = value.mul(priceForBasePart);
                byuoutCount = byuoutCount.sub(value);
            }
            msg.sender.transfer(bonus);
        }

        addTokenHolder(to);
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint value) public returns (bool success) {
        require(to != 0x0 && value > 0);
        addTokenHolder(to);
        return super.transferFrom(from, to, value);
    }

    /* Token holders */

    mapping(uint => address) public indexedTokenHolders;
    mapping(address => uint) public tokenHolders;
    uint public tokenHoldersCount = 0;

    function addTokenHolder(address investor) private {
        if(investor != owner && indexedTokenHolders[0] != investor && tokenHolders[investor] == 0){
            tokenHolders[investor] = tokenHoldersCount;
            indexedTokenHolders[tokenHoldersCount] = investor;
            tokenHoldersCount ++;
        }
    }
}
