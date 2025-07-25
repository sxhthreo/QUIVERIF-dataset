pragma solidity ^0.4.15;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
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
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title Math
 * @dev Assorted math operations
 */

library Math {
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}

contract GreedTokenICO is StandardToken, Ownable {
    using SafeMath for uint256;
    using Math for uint256;

    string public name = "GREED TOKEN";
    string public symbol = "GREED";
    uint256 public decimals = 18;

    uint256 public constant EXCHANGE_RATE = 700; 
    uint256 constant TOP_MULT = 1000 * (uint256(10) ** decimals);
    uint256 public bonusMultiplier = 1000 * (uint256(10) ** decimals);
    
    uint256 public totalSupply = 3140000000 * (uint256(10) ** decimals);
    uint256 public startTimestamp = 1510398671; // timestamp after which ICO will start
    uint256 public durationSeconds = 2682061; // up to 2017-12-12 12:12:12

    address public icoWallet = 0xf34175829b0fc596814009df978c77b5cb47b24f;
	address public vestContract = 0xfbadbf0a1296d2da94e59d76107c61581d393196;		

    uint256 public totalRaised; // total ether raised (in wei)
    uint256 public totalContributors;
    uint256 public totalTokensSold;

    uint256 public icoSupply;
    uint256 public vestSupply;
    
    bool public icoOpen = false;
    bool public icoFinished = false;


    function GreedTokenICO () public {
        // Supply of tokens to be distributed 
        icoSupply = totalSupply.mul(10).div(100); // 10% of supply
        vestSupply = totalSupply.mul(90).div(100); // 90% of supply
        
        // Transfer the tokens to ICO and Vesting Contract
        // Other tokens will be vested at the end of ICO
        balances[icoWallet] = icoSupply;
        balances[vestContract] = vestSupply;
         
        Transfer(0x0, icoWallet, icoSupply);
        Transfer(0x0, vestContract, vestSupply);
    }

    function() public isIcoOpen payable {
        require(msg.value > 0);
        
        uint256 valuePlus = 50000000000000000; // 0.05 ETH
        uint256 ONE_ETH = 1000000000000000000;
        uint256 tokensLeft = balances[icoWallet];
        uint256 ethToPay = msg.value;
        uint256 tokensBought;

        if (msg.value >= valuePlus) {
            tokensBought = msg.value.mul(EXCHANGE_RATE).mul(bonusMultiplier).div(ONE_ETH);
	        if (tokensBought > tokensLeft) {
		        ethToPay = tokensLeft.mul(ONE_ETH).div(bonusMultiplier).div(EXCHANGE_RATE);
		        tokensBought = tokensLeft;
		        icoFinished = true;
		        icoOpen = false;
	        }
		} else {
            tokensBought = msg.value.mul(EXCHANGE_RATE);
	        if (tokensBought > tokensLeft) {
		        ethToPay = tokensLeft.div(EXCHANGE_RATE);
		        tokensBought = tokensLeft;
		        icoFinished = true;
		        icoOpen = false;
	        }
		}

        icoWallet.transfer(ethToPay);
        totalRaised = totalRaised.add(ethToPay);
        totalContributors = totalContributors.add(1);
        totalTokensSold = totalTokensSold.add(tokensBought);

        balances[icoWallet] = balances[icoWallet].sub(tokensBought);
        balances[msg.sender] = balances[msg.sender].add(tokensBought);
        Transfer(icoWallet, msg.sender, tokensBought);

        uint256 refund = msg.value.sub(ethToPay);
        if (refund > 0) {
            msg.sender.transfer(refund);
        }

        bonusMultiplier = TOP_MULT.sub(totalRaised);

        if (bonusMultiplier < ONE_ETH) {
		        icoFinished = true;
		        icoOpen = false;
        }
        

    }

    function transfer(address _to, uint _value) public isIcoFinished returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public isIcoFinished returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    modifier isIcoOpen() {
        uint256 blocktime = now;

        require(icoFinished == false);        
        require(blocktime >= startTimestamp);
        require(blocktime <= (startTimestamp + durationSeconds));
        require(totalTokensSold < icoSupply);

        if (icoOpen == false && icoFinished == false) {
            icoOpen = true;
        }

        _;
    }

    modifier isIcoFinished() {
        uint256 blocktime = now;
        
        require(blocktime >= startTimestamp);
        require(icoFinished == true || totalTokensSold >= icoSupply || (blocktime >= (startTimestamp + durationSeconds)));
        if (icoFinished == false) {
            icoFinished = true;
            icoOpen = false;
        }
        _;
    }
    
    function endICO() public isIcoFinished onlyOwner {
    
        uint256 tokensLeft;
        
        // Tokens left will be transfered to second token sale
        tokensLeft = balances[icoWallet];
		balances[vestContract] = balances[vestContract].add(tokensLeft);
		vestSupply = vestSupply.add(tokensLeft);
		balances[icoWallet] = 0;
        Transfer(icoWallet, vestContract, tokensLeft);
    }
    
}
