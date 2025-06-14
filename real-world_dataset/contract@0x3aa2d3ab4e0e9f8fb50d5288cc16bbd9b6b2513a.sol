pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

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

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
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
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
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
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: openzeppelin-solidity/contracts/token/ERC20/BurnableToken.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

// File: contracts/BancrypToken.sol

/// @title BancrypToken
/// @author Bancryp
contract BancrypToken is StandardToken, BurnableToken {
  string public symbol  = "XBANC";
  string public name    = "XBANC";
  uint8 public decimals = 18;

  // Transfers will only be avaiable after the transfer time start
  // 12/31/2018 @ 11:59pm (UTC)
  uint256 public constant TRANSFERABLE_START_TIME = 1546300799;
  
  // Wallets for tokens split amongst team,
  // advisors, reserve fund and social cause addresses
  // Note: Those address will be replaced by the real addresses before the main net deploy
  address public constant ADVISORS_WALLET     = 0x0fC8c4288841CB199bDdbf385BD762938f5A8328;
  address public constant BANCRYP_WALLET      = 0xcafBCD7F36ae4506E4331a27CC6CAF12fD35E83C;
  address public constant FUNDS_WALLET        = 0x66fC388e7AF7ee6198D849A37B89a813d559913a;
  address public constant RESERVE_FUND_WALLET = 0xb8dc7BfB6D987464b2006aBd6B7511C8D2Ebe50f;
  address public constant SOCIAL_CAUSE_WALLET = 0xd71383C04F67e2Db7F95aC58c9B2509Cf15AAa95;
  address public constant TEAM_WALLET         = 0x2b400ee4Ff17dE03453e325e9198E6C9c4F88243;

  // 300.000.000 in initial supply
  uint256 public constant INITIAL_SUPPLY = 300000000;

  // Allows transfer only after TRANSFERABLE_START_TIME
  // With an exception of the wallets allowed on require function
  modifier onlyWhenTransferEnabled(address _to) {
    if ( now <= TRANSFERABLE_START_TIME ) {
      // Only some wallets to transfer
      // in case of transfer isn't available yet
      require(msg.sender == TEAM_WALLET || msg.sender == ADVISORS_WALLET ||
        msg.sender == RESERVE_FUND_WALLET || msg.sender == SOCIAL_CAUSE_WALLET ||
        msg.sender == FUNDS_WALLET || msg.sender == BANCRYP_WALLET ||
        _to == BANCRYP_WALLET, "Forbidden to transfer right now");
    }
    _;
  }

  // Helper to test valid destion to transfer
  modifier validDestination(address to) {
    require(to != address(this));
    _;
  }

  /// @notice Constructor called on deploy of the contract which sets wallets
  /// for team, advisors, reserve fund and social cause, the rest is are for
  /// public sale
  /// will be open to public other than wallets on this constructor
  constructor() public {  
    // After the initial supply been split amongst team, advisors, 
    // reserve and social cause the value available will be 195.000.000
    totalSupply_ = INITIAL_SUPPLY * (10 ** uint256(decimals));
    balances[FUNDS_WALLET] = totalSupply_;
  }

  /// @dev override transfer token for a specified address to add onlyWhenTransferEnabled
  /// @param _to The address to transfer to.
  /// @param _value The amount to be transferred.
  function transfer(address _to, uint256 _value)
      public
      validDestination(_to)
      onlyWhenTransferEnabled(_to)
      returns (bool) 
  {
      return super.transfer(_to, _value);
  }

  /// @dev override transferFrom token for a specified address to add onlyWhenTransferEnabled and validDestination
  /// @param _from The address to transfer from.
  /// @param _to The address to transfer to.
  /// @param _value The amount to be transferred.
  function transferFrom(address _from, address _to, uint256 _value)
    public
    validDestination(_to)
    onlyWhenTransferEnabled(_to)
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  /// @dev Burns a specific amount of tokens.
  /// @param _value The amount of token to be burned.
  function burn(uint256 _value) public {
    require(msg.sender == FUNDS_WALLET, "Only funds wallet can burn");
    _burn(msg.sender, _value);
  }
}
