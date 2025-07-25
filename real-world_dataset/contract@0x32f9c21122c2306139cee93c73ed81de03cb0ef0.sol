pragma solidity ^0.4.24;

// File: openzeppelin-eth/contracts/token/ERC20/IERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

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

// File: openzeppelin-eth/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

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

// File: contracts/dex/ITokenConverter.sol

contract ITokenConverter {    
    using SafeMath for uint256;

    /**
    * @dev Makes a simple ERC20 -> ERC20 token trade
    * @param _srcToken - IERC20 token
    * @param _destToken - IERC20 token 
    * @param _srcAmount - uint256 amount to be converted
    * @param _destAmount - uint256 amount to get after conversion
    * @return uint256 for the change. 0 if there is no change
    */
    function convert(
        IERC20 _srcToken,
        IERC20 _destToken,
        uint256 _srcAmount,
        uint256 _destAmount
        ) external returns (uint256);

    /**
    * @dev Get exchange rate and slippage rate. 
    * Note that these returned values are in 18 decimals regardless of the destination token's decimals.
    * @param _srcToken - IERC20 token
    * @param _destToken - IERC20 token 
    * @param _srcAmount - uint256 amount to be converted
    * @return uint256 of the expected rate
    * @return uint256 of the slippage rate
    */
    function getExpectedRate(IERC20 _srcToken, IERC20 _destToken, uint256 _srcAmount) 
        public view returns(uint256 expectedRate, uint256 slippageRate);
}

// File: contracts/dex/IKyberNetwork.sol

contract IKyberNetwork {
    function trade(
        IERC20 _srcToken,
        uint _srcAmount,
        IERC20 _destToken,
        address _destAddress, 
        uint _maxDestAmount,	
        uint _minConversionRate,	
        address _walletId
        ) 
        public payable returns(uint);

    function getExpectedRate(IERC20 _srcToken, IERC20 _destToken, uint _srcAmount) 
        public view returns(uint expectedRate, uint slippageRate);
}

// File: contracts/libs/SafeERC20.sol

/**
* @dev Library to perform safe calls to standard method for ERC20 tokens.
* Transfers : transfer methods could have a return value (bool), revert for insufficient funds or
* unathorized value.
*
* Approve: approve method could has a return value (bool) or does not accept 0 as a valid value (BNB token).
* The common strategy used to clean approvals.
*/
library SafeERC20 {
    /**
    * @dev Transfer token for a specified address
    * @param _token erc20 The address of the ERC20 contract
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the _value of tokens to be transferred
    */
    function safeTransfer(IERC20 _token, address _to, uint256 _value) internal returns (bool) {
        uint256 prevBalance = _token.balanceOf(address(this));

        require(prevBalance >= _value, "Insufficient funds");

        _token.transfer(_to, _value);

        require(prevBalance - _value == _token.balanceOf(address(this)), "Transfer failed");

        return true;
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param _token erc20 The address of the ERC20 contract
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the _value of tokens to be transferred
    */
    function safeTransferFrom(
        IERC20 _token,
        address _from,
        address _to, 
        uint256 _value
    ) internal returns (bool) 
    {
        uint256 prevBalance = _token.balanceOf(_from);

        require(prevBalance >= _value, "Insufficient funds");
        require(_token.allowance(_from, address(this)) >= _value, "Insufficient allowance");

        _token.transferFrom(_from, _to, _value);

        require(prevBalance - _value == _token.balanceOf(_from), "Transfer failed");

        return true;
    }

   /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * 
   * @param _token erc20 The address of the ERC20 contract
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
    function safeApprove(IERC20 _token, address _spender, uint256 _value) internal returns (bool) {
        bool success = address(_token).call(abi.encodeWithSelector(
            _token.approve.selector,
            _spender,
            _value
        )); 

        if (!success) {
            return false;
        }

        require(_token.allowance(address(this), _spender) == _value, "Approve failed");

        return true;
    }

   /** 
   * @dev Clear approval
   * Note that if 0 is not a valid value it will be set to 1.
   * @param _token erc20 The address of the ERC20 contract
   * @param _spender The address which will spend the funds.
   */
    function clearApprove(IERC20 _token, address _spender) internal returns (bool) {
        bool success = safeApprove(_token, _spender, 0);

        if (!success) {
            return safeApprove(_token, _spender, 1);
        }

        return true;
    }
}

// File: contracts/dex/KyberConverter.sol

/**
* @dev Contract to encapsulate Kyber methods which implements ITokenConverter.
* Note that need to create it with a valid kyber address
*/
contract KyberConverter is ITokenConverter {
    using SafeERC20 for IERC20;

    IKyberNetwork public  kyber;
    address public walletId;
    uint256 public change;
    uint256 public prevSrcBalance;
    uint256 public amount;
    uint256 public srcAmount;
    uint256 public destAmount;

    constructor (IKyberNetwork _kyber, address _walletId) public {
        kyber = _kyber;
        walletId = _walletId;
    }
    
    function convert(
        IERC20 _srcToken,
        IERC20 _destToken,
        uint256 _srcAmount,
        uint256 _destAmount
    ) 
    external returns (uint256)
    {
        srcAmount = _srcAmount;
        destAmount = _destAmount;
        // Save prev src token balance 
        prevSrcBalance = _srcToken.balanceOf(address(this));

        // Transfer tokens to be converted from msg.sender to this contract
        require(
            _srcToken.safeTransferFrom(msg.sender, address(this), _srcAmount),
            "Could not transfer _srcToken to this contract"
        );

        // Approve Kyber to use _srcToken on belhalf of this contract
        require(
            _srcToken.safeApprove(kyber, _srcAmount),
            "Could not approve kyber to use _srcToken on behalf of this contract"
        );

        // Trade _srcAmount from _srcToken to _destToken
        // Note that minConversionRate is set to 0 cause we want the lower rate possible
        amount = kyber.trade(
            _srcToken,
            _srcAmount,
            _destToken,
            address(this),
            _destAmount,
            0,
            walletId
        );

        // Clean kyber to use _srcTokens on belhalf of this contract
        require(
            _srcToken.clearApprove(kyber),
            "Could not clean approval of kyber to use _srcToken on behalf of this contract"
        );

        // Check if the amount traded is equal to the expected one
        require(amount == _destAmount, "Amount bought is not equal to dest amount");

        // // Return the change of src token
        change = _srcToken.balanceOf(address(this)).sub(prevSrcBalance);
        // require(
        //     _srcToken.safeTransfer(msg.sender, change),
        //     "Could not transfer change to sender"
        // );


        // Transfer amount of _destTokens to msg.sender
        require(
            _destToken.safeTransfer(msg.sender, amount),
            "Could not transfer amount of _destToken to msg.sender"
        );

        return 0;
    }

    function getExpectedRate(IERC20 _srcToken, IERC20 _destToken, uint256 _srcAmount) 
    public view returns(uint256 expectedRate, uint256 slippageRate) 
    {
        (expectedRate, slippageRate) = kyber.getExpectedRate(_srcToken, _destToken, _srcAmount);
    }
}
