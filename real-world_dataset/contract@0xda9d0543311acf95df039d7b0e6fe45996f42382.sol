// File: contracts/utils/LoggingErrors.sol

pragma solidity ^0.4.11;

/**
 * @title Log Various Error Types
 * @author Adam Lemmon <adam@oraclize.it>
 * @dev Inherit this contract and your may now log errors easily
 * To support various error types, params, etc.
 */
contract LoggingErrors {
  /**
  * Events
  */
  event LogErrorString(string errorString);

  /**
  * Error cases
  */

  /**
   * @dev Default error to simply log the error message and return
   * @param _errorMessage The error message to log
   * @return ALWAYS false
   */
  function error(string _errorMessage) internal returns(bool) {
    emit LogErrorString(_errorMessage);
    return false;
  }
}

// File: contracts/wallet/WalletConnector.sol

pragma solidity ^0.4.15;


/**
 * @title Wallet Connector
 * @dev Connect the wallet contract to the correct Wallet Logic version
 */
contract WalletConnector is LoggingErrors {
  /**
   * Storage
   */
  address public owner_;
  address public latestLogic_;
  uint256 public latestVersion_;
  mapping(uint256 => address) public logicVersions_;
  uint256 public birthBlock_;

  /**
   * Events
   */
  event LogLogicVersionAdded(uint256 version);
  event LogLogicVersionRemoved(uint256 version);

  /**
   * @dev Constructor to set the latest logic address
   * @param _latestVersion Latest version of the wallet logic
   * @param _latestLogic Latest address of the wallet logic contract
   */
  function WalletConnector (
    uint256 _latestVersion,
    address _latestLogic
  ) public {
    owner_ = msg.sender;
    latestLogic_ = _latestLogic;
    latestVersion_ = _latestVersion;
    logicVersions_[_latestVersion] = _latestLogic;
    birthBlock_ = block.number;
  }

  /**
   * Add a new version of the logic contract
   * @param _version The version to be associated with the new contract.
   * @param _logic New logic contract.
   * @return Success of the transaction.
   */
  function addLogicVersion (
    uint256 _version,
    address _logic
  ) external
    returns(bool)
  {
    if (msg.sender != owner_)
      return error('msg.sender != owner, WalletConnector.addLogicVersion()');

    if (logicVersions_[_version] != 0)
      return error('Version already exists, WalletConnector.addLogicVersion()');

    // Update latest if this is the latest version
    if (_version > latestVersion_) {
      latestLogic_ = _logic;
      latestVersion_ = _version;
    }

    logicVersions_[_version] = _logic;
    LogLogicVersionAdded(_version);

    return true;
  }

  /**
   * @dev Remove a version. Cannot remove the latest version.
   * @param  _version The version to remove.
   */
  function removeLogicVersion(uint256 _version) external {
    require(msg.sender == owner_);
    require(_version != latestVersion_);
    delete logicVersions_[_version];
    LogLogicVersionRemoved(_version);
  }

  /**
   * Constants
   */

  /**
   * Called from user wallets in order to upgrade their logic.
   * @param _version The version to upgrade to. NOTE pass in 0 to upgrade to latest.
   * @return The address of the logic contract to upgrade to.
   */
  function getLogic(uint256 _version)
    external
    constant
    returns(address)
  {
    if (_version == 0)
      return latestLogic_;
    else
      return logicVersions_[_version];
  }
}

// File: contracts/wallet/WalletBuilderInterface.sol

pragma solidity ^0.4.15;



/**
 * @title Wallet to hold and trade ERC20 tokens and ether
 */
interface WalletBuilderInterface {

  /**
   * @dev build a new trading wallet and returns its address
   * @param _owner user EOA of the created trading wallet
   * @param _exchange exchange address
   */
  function buildWallet(address _owner, address _exchange) external returns(address);
}

// File: contracts/token/ERC20Interface.sol

pragma solidity ^0.4.11;

interface Token {
  /// @return total amount of tokens
  function totalSupply() external constant returns (uint256 supply);

  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) external constant returns (uint256 balance);

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) external returns (bool success);

  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

  /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of wei to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) external returns (bool success);

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) external constant returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  function decimals() external constant returns(uint);
  function name() external constant returns(string);
}

// File: contracts/wallet/WalletV3.sol

pragma solidity ^0.4.15;




/**
 * @title Wallet to hold and trade ERC20 tokens and ether
 * @dev User wallet to interact with the exchange.
 * all tokens and ether held in this wallet, 1 to 1 mapping to user EOAs.
 */
contract WalletV3 is LoggingErrors {
  /**
   * Storage
   */
  // Vars included in wallet logic "lib", the order must match between Wallet and Logic
  address public owner_;
  address public exchange_;
  mapping(address => uint256) public tokenBalances_;

  address public logic_; // storage location 0x3 loaded for delegatecalls so this var must remain at index 3
  uint256 public birthBlock_;

  WalletConnector private connector_;

  /**
   * Events
   */
  event LogDeposit(address token, uint256 amount, uint256 balance);
  event LogWithdrawal(address token, uint256 amount, uint256 balance);

  /**
   * @dev Contract constructor. Set user as owner and connector address.
   * @param _owner The address of the user's EOA, wallets created from the exchange
   * so must past in the owner address, msg.sender == exchange.
   * @param _connector The wallet connector to be used to retrieve the wallet logic
   */
  constructor(address _owner, address _connector, address _exchange) public {
    owner_ = _owner;
    connector_ = WalletConnector(_connector);
    exchange_ = _exchange;
    logic_ = connector_.latestLogic_();
    birthBlock_ = block.number;
  }

  function () external payable {}

  /**
  * External
  */

  /**
   * @dev Deposit ether into this wallet, default to address 0 for consistent token lookup.
   */
  function depositEther()
    external
    payable
  {
    require(
      logic_.delegatecall(abi.encodeWithSignature('deposit(address,uint256)', 0, msg.value)),
      "depositEther() failed"
    );
  }

  /**
   * @dev Deposit any ERC20 token into this wallet.
   * @param _token The address of the existing token contract.
   * @param _amount The amount of tokens to deposit.
   * @return Bool if the deposit was successful.
   */
  function depositERC20Token (
    address _token,
    uint256 _amount
  ) external
    returns(bool)
  {
    // ether
    if (_token == 0)
      return error('Cannot deposit ether via depositERC20, Wallet.depositERC20Token()');

    require(
      logic_.delegatecall(abi.encodeWithSignature('deposit(address,uint256)', _token, _amount)),
      "depositERC20Token() failed"
    );
    return true;
  }

  /**
   * @dev The result of an order, update the balance of this wallet.
   * param _token The address of the token balance to update.
   * param _amount The amount to update the balance by.
   * param _subtractionFlag If true then subtract the token amount else add.
   * @return Bool if the update was successful.
   */
  function updateBalance (
    address /*_token*/,
    uint256 /*_amount*/,
    bool /*_subtractionFlag*/
  ) external
    returns(bool)
  {
    assembly {
      calldatacopy(0x40, 0, calldatasize)
      delegatecall(gas, sload(0x3), 0x40, calldatasize, 0, 32)
      return(0, 32)
      pop
    }
  }

  /**
   * User may update to the latest version of the exchange contract.
   * Note that multiple versions are NOT supported at this time and therefore if a
   * user does not wish to update they will no longer be able to use the exchange.
   * @param _exchange The new exchange.
   * @return Success of this transaction.
   */
  function updateExchange(address _exchange)
    external
    returns(bool)
  {
    if (msg.sender != owner_)
      return error('msg.sender != owner_, Wallet.updateExchange()');

    // If subsequent messages are not sent from this address all orders will fail
    exchange_ = _exchange;

    return true;
  }

  /**
   * User may update to a new or older version of the logic contract.
   * @param _version The versin to update to.
   * @return Success of this transaction.
   */
  function updateLogic(uint256 _version)
    external
    returns(bool)
  {
    if (msg.sender != owner_)
      return error('msg.sender != owner_, Wallet.updateLogic()');

    address newVersion = connector_.getLogic(_version);

    // Invalid version as defined by connector
    if (newVersion == 0)
      return error('Invalid version, Wallet.updateLogic()');

    logic_ = newVersion;
    return true;
  }

  /**
   * @dev Verify an order that the Exchange has received involving this wallet.
   * Internal checks and then authorize the exchange to move the tokens.
   * If sending ether will transfer to the exchange to broker the trade.
   * param _token The address of the token contract being sold.
   * param _amount The amount of tokens the order is for.
   * param _fee The fee for the current trade.
   * param _feeToken The token of which the fee is to be paid in.
   * @return If the order was verified or not.
   */
  function verifyOrder (
    address /*_token*/,
    uint256 /*_amount*/,
    uint256 /*_fee*/,
    address /*_feeToken*/
  ) external
    returns(bool)
  {
    assembly {
      calldatacopy(0x40, 0, calldatasize)
      delegatecall(gas, sload(0x3), 0x40, calldatasize, 0, 32)
      return(0, 32)
      pop
    }
  }

  /**
   * @dev Withdraw any token, including ether from this wallet to an EOA.
   * param _token The address of the token to withdraw.
   * param _amount The amount to withdraw.
   * @return Success of the withdrawal.
   */
  function withdraw(address /*_token*/, uint256 /*_amount*/)
    external
    returns(bool)
  {
    if(msg.sender != owner_)
      return error('msg.sender != owner, Wallet.withdraw()');

    assembly {
      calldatacopy(0x40, 0, calldatasize)
      delegatecall(gas, sload(0x3), 0x40, calldatasize, 0, 32)
      return(0, 32)
      pop
    }
  }

  /**
   * Constants
   */

  /**
   * @dev Get the balance for a specific token.
   * @param _token The address of the token contract to retrieve the balance of.
   * @return The current balance within this contract.
   */
  function balanceOf(address _token)
    public
    view
    returns(uint)
  {
    if (_token == address(0)) {
      return address(this).balance;
    } else {
      return Token(_token).balanceOf(this);
    }
  }

  function walletVersion() external pure returns(uint){
    return 3;
  }
}

// File: contracts/wallet/WalletV3Builder.sol

pragma solidity ^0.4.15;



/**
 * @title Wallet to hold and trade ERC20 tokens and ether
 * @dev User wallet to interact with the exchange.
 * all tokens and ether held in this wallet, 1 to 1 mapping to user EOAs.
 */
contract WalletV3Builder is WalletBuilderInterface {

  address public connector;

  /**
   * @dev Contract constructor. Set user as owner and connector address.
   * @param _connector The wallet connector to be used to retrieve the wallet logic
   */
  constructor (address _connector) public {
    connector = _connector;
  }

  /**
   * @dev build a new trading wallet and returns its address
   * @param _owner user EOA of the created trading wallet
   * @param _exchange exchange address
   */
  function buildWallet(address _owner, address _exchange) external returns(address) {
    return new WalletV3(_owner, connector, _exchange);
  }
}
