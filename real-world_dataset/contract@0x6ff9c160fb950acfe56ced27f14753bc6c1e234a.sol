pragma solidity ^"0.4.24";

contract VestingBase {
    using SafeMath for uint256;
    CovaToken internal cova;
    uint256 internal releaseTime;
    uint256 internal genesisTime;
    uint256 internal THREE_MONTHS = 7890000;
    uint256 internal SIX_MONTHS = 15780000;

    address internal beneficiaryAddress;

    struct Claim {
        bool fromGenesis;
        uint256 pct;
        uint256 delay;
        bool claimed;
    } 

    Claim [] internal beneficiaryClaims;
    uint256 internal totalClaimable;

    event Claimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    function claim() public returns (bool){
        require(msg.sender == beneficiaryAddress); 
        for(uint256 i = 0; i < beneficiaryClaims.length; i++){
            Claim memory cur_claim = beneficiaryClaims[i];
            if(cur_claim.claimed == false){
                if((cur_claim.fromGenesis == false && (cur_claim.delay.add(releaseTime) < block.timestamp)) || (cur_claim.fromGenesis == true && (cur_claim.delay.add(genesisTime) < block.timestamp))){
                    uint256 amount = cur_claim.pct.mul(totalClaimable).div(10000);
                    require(cova.transfer(msg.sender, amount));
                    beneficiaryClaims[i].claimed = true;
                    emit Claimed(msg.sender, amount, block.timestamp);
                }
            }
        }
    }

    function getBeneficiary() public view returns (address) {
        return beneficiaryAddress;
    }

    function getTotalClaimable() public view returns (uint256) {
        return totalClaimable;
    }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}




/**
 * @title Standard ERC20, Cova Token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */

contract CovaToken is ERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private balances;
  mapping (address => mapping (address => uint256)) private allowed;

  uint256 private totalSupply_ = 65 * (10 ** (8 + 18));
  string private constant name_ = 'Covalent Token';                                 // Set the token name for display
  string private constant symbol_ = 'COVA';                                         // Set the token symbol for display
  uint8 private constant decimals_ = 18;                                          // Set the number of decimals for display
  

  constructor () public {
    balances[msg.sender] = totalSupply_;
    emit Transfer(address(0), msg.sender, totalSupply_);
  }

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Token name
  */
  function name() public view returns (string) {
    return name_;
  }

  /**
  * @dev Token symbol
  */
  function symbol() public view returns (string) {
    return symbol_;
  }

  /**
  * @dev Token decinal
  */
  function decimals() public view returns (uint8) {
    return decimals_;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
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
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
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
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

contract VestingAdvisor is VestingBase {
    using SafeMath for uint256;

    constructor(CovaToken _cova, uint256 _releaseTime) public {
        cova = _cova;
        releaseTime = _releaseTime;
        genesisTime = block.timestamp;
        beneficiaryAddress = 0xaD5Bc53f04aD23Ac217809c0276ed12F5cD80e2D;
        totalClaimable = 415520000 * (10 ** 18);
        beneficiaryClaims.push(Claim(false, 3000, SIX_MONTHS, false));
        beneficiaryClaims.push(Claim(false, 3000, THREE_MONTHS.add(SIX_MONTHS), false));
        beneficiaryClaims.push(Claim(false, 4000, THREE_MONTHS.mul(2).add(SIX_MONTHS), false));
    }
}
