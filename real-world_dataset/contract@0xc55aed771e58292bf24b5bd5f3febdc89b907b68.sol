pragma solidity ^0.4.24;

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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * @dev The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  function HasNoEther() public payable {
    require(msg.value == 0);
  }

  /**
   * @dev Disallows direct send by settings a default function without the `payable` flag.
   */
  function() external {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    assert(owner.send(this.balance));
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

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

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
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

}

contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
	

}

contract VoteToken is HasNoEther, BurnableToken {
	
    struct stSuggestion {
		string  text;	//suggestion text (question)
		uint256 total_yes;	//votes score
		uint256 total_no;	//votes score
		uint256 timeStop; //timestamp
		bool 	finished;
		uint	voters_count;
		mapping(uint 	 => address) voters_addrs; //Voted addresses
		mapping(address  => uint256) voters_value; //Voted values
    }
	
	// List of all suggestions
	uint lastID;
    mapping (uint => stSuggestion) suggestions;
	
	// Price per Suggestion
    uint256 public Price;
	
	function setSuggPrice( uint256 newPrice ) public onlyOwner 
    {
        Price = newPrice;
    }

	function getListSize() public view returns (uint count) 
    {
        return lastID;
    }
	
	function addSuggestion(string s, uint  forDays) public returns (uint newID)
    {
        require ( Price <= balances[msg.sender] );
       
		newID = lastID++;
        suggestions[newID].text = s;
        suggestions[newID].total_yes = 0;
        suggestions[newID].total_no  = 0;
        suggestions[newID].timeStop =  now + forDays * 1 days;
        suggestions[newID].finished = false;
        suggestions[newID].voters_count = 0;

		balances[msg.sender] = balances[msg.sender].sub(Price);
        totalSupply = totalSupply.sub(Price);
    }
	
	function getSuggestion(uint id) public constant returns(string, uint256, uint256, uint256, bool, uint )
    {
		require ( id <= lastID );
        return (
            suggestions[id].text,
            suggestions[id].total_yes,
            suggestions[id].total_no,
            suggestions[id].timeStop,
            suggestions[id].finished,
            suggestions[id].voters_count
            );
    } 
	
	function isSuggestionNeedToFinish(uint id) public view returns ( bool ) 
    {
		if ( id > lastID ) return false;
		if ( suggestions[id].finished ) return false;
		if ( now <= suggestions[id].timeStop ) return false;
		
        return true;
    } 
	
	function finishSuggestion( uint id ) public returns (bool)
	{
	    
		if ( !isSuggestionNeedToFinish(id) ) return false;
		
		uint i;
		address addr;
		uint256 val;
		for ( i = 1; i <= suggestions[id].voters_count; i++){
			addr = suggestions[id].voters_addrs[i];
			val  = suggestions[id].voters_value[addr];
			
			balances[addr] = balances[addr].add( val );
			totalSupply = totalSupply.add( val );
		}
		suggestions[id].finished = true;
		
		return true;
	}
	
	function Vote( uint id, bool MyVote, uint256 Value ) public returns (bool)
	{
		if ( id > lastID ) return false;
		if ( Value > balances[msg.sender] ) return false;
		if ( suggestions[id].finished ) return false;
	
		if (MyVote)
			suggestions[id].total_yes += Value;
		else
			suggestions[id].total_no  += Value;
		
		suggestions[id].voters_count++;
		suggestions[id].voters_addrs[ suggestions[id].voters_count ] = msg.sender;
		suggestions[id].voters_value[msg.sender] = suggestions[id].voters_value[msg.sender].add(Value);
		
		balances[msg.sender] = balances[msg.sender].sub(Value);
		
		totalSupply = totalSupply.sub(Value);
		
		return true;
	}
	
	
}



contract YourVoteMatters is VoteToken {

    string public constant name = "YourVoteMatters";
    string public constant symbol = "YVM";
    uint8 public constant decimals = 18;
    uint256 constant INITIAL_SUPPLY = 10000 * (10 ** uint256(decimals));

    /**
    * @dev Constructor that gives msg.sender all of existing tokens.
    */
    function YourVoteMatters() public {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        Transfer(address(0), msg.sender, totalSupply);
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        return super.transfer(_to, _value);
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function multiTransfer(address[] recipients, uint256[] amounts) public {
        require(recipients.length == amounts.length);
        for (uint i = 0; i < recipients.length; i++) {
            transfer(recipients[i], amounts[i]);
        }
    }
	
	/**
	* @dev Create `mintedAmount` tokens
    * @param mintedAmount The amount of tokens it will minted
	**/
    function mintToken(uint256 mintedAmount) public onlyOwner {
			totalSupply += mintedAmount;
			balances[owner] += mintedAmount;
			Transfer(address(0), owner, mintedAmount);
    }
}
