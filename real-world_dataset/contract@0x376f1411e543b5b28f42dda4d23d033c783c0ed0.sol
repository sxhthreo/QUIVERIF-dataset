// File: openzeppelin-solidity-v1.12.0/contracts/ownership/Ownable.sol

pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: openzeppelin-solidity-v1.12.0/contracts/ownership/Claimable.sol

pragma solidity ^0.4.24;



/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

// File: contracts/utils/Adminable.sol

pragma solidity 0.4.25;


/**
 * @title Adminable.
 */
contract Adminable is Claimable {
    address[] public adminArray;

    struct AdminInfo {
        bool valid;
        uint256 index;
    }

    mapping(address => AdminInfo) public adminTable;

    event AdminAccepted(address indexed _admin);
    event AdminRejected(address indexed _admin);

    /**
     * @dev Reverts if called by any account other than one of the administrators.
     */
    modifier onlyAdmin() {
        require(adminTable[msg.sender].valid, "caller is illegal");
        _;
    }

    /**
     * @dev Accept a new administrator.
     * @param _admin The administrator's address.
     */
    function accept(address _admin) external onlyOwner {
        require(_admin != address(0), "administrator is illegal");
        AdminInfo storage adminInfo = adminTable[_admin];
        require(!adminInfo.valid, "administrator is already accepted");
        adminInfo.valid = true;
        adminInfo.index = adminArray.length;
        adminArray.push(_admin);
        emit AdminAccepted(_admin);
    }

    /**
     * @dev Reject an existing administrator.
     * @param _admin The administrator's address.
     */
    function reject(address _admin) external onlyOwner {
        AdminInfo storage adminInfo = adminTable[_admin];
        require(adminArray.length > adminInfo.index, "administrator is already rejected");
        require(_admin == adminArray[adminInfo.index], "administrator is already rejected");
        // at this point we know that adminArray.length > adminInfo.index >= 0
        address lastAdmin = adminArray[adminArray.length - 1]; // will never underflow
        adminTable[lastAdmin].index = adminInfo.index;
        adminArray[adminInfo.index] = lastAdmin;
        adminArray.length -= 1; // will never underflow
        delete adminTable[_admin];
        emit AdminRejected(_admin);
    }

    /**
     * @dev Get an array of all the administrators.
     * @return An array of all the administrators.
     */
    function getAdminArray() external view returns (address[] memory) {
        return adminArray;
    }

    /**
     * @dev Get the total number of administrators.
     * @return The total number of administrators.
     */
    function getAdminCount() external view returns (uint256) {
        return adminArray.length;
    }
}

// File: contracts/wallet_trading_limiter/interfaces/IWalletsTradingDataSource.sol

pragma solidity 0.4.25;

/**
 * @title Wallets Trading Data Source Interface.
 */
interface IWalletsTradingDataSource {
    /**
     * @dev Increment the value of a given wallet.
     * @param _wallet The address of the wallet.
     * @param _value The value to increment by.
     * @param _limit The limit of the wallet.
     */
    function updateWallet(address _wallet, uint256 _value, uint256 _limit) external;
}

// File: contracts/contract_address_locator/interfaces/IContractAddressLocator.sol

pragma solidity 0.4.25;

/**
 * @title Contract Address Locator Interface.
 */
interface IContractAddressLocator {
    /**
     * @dev Get the contract address mapped to a given identifier.
     * @param _identifier The identifier.
     * @return The contract address.
     */
    function getContractAddress(bytes32 _identifier) external view returns (address);

    /**
     * @dev Determine whether or not a contract address is relates to one of the given identifiers.
     * @param _contractAddress The contract address to look for.
     * @param _identifiers The identifiers.
     * @return Is the contract address relates to one of the identifiers.
     */
    function isContractAddressRelates(address _contractAddress, bytes32[] _identifiers) external view returns (bool);
}

// File: contracts/contract_address_locator/ContractAddressLocatorHolder.sol

pragma solidity 0.4.25;


/**
 * @title Contract Address Locator Holder.
 * @dev Hold a contract address locator, which maps a unique identifier to every contract address in the system.
 * @dev Any contract which inherits from this contract can retrieve the address of any contract in the system.
 * @dev Thus, any contract can remain "oblivious" to the replacement of any other contract in the system.
 * @dev In addition to that, any function in any contract can be restricted to a specific caller.
 */
contract ContractAddressLocatorHolder {
    bytes32 internal constant _IAuthorizationDataSource_ = "IAuthorizationDataSource";
    bytes32 internal constant _ISGNConversionManager_    = "ISGNConversionManager"      ;
    bytes32 internal constant _IModelDataSource_         = "IModelDataSource"        ;
    bytes32 internal constant _IPaymentHandler_          = "IPaymentHandler"            ;
    bytes32 internal constant _IPaymentManager_          = "IPaymentManager"            ;
    bytes32 internal constant _IPaymentQueue_            = "IPaymentQueue"              ;
    bytes32 internal constant _IReconciliationAdjuster_  = "IReconciliationAdjuster"      ;
    bytes32 internal constant _IIntervalIterator_        = "IIntervalIterator"       ;
    bytes32 internal constant _IMintHandler_             = "IMintHandler"            ;
    bytes32 internal constant _IMintListener_            = "IMintListener"           ;
    bytes32 internal constant _IMintManager_             = "IMintManager"            ;
    bytes32 internal constant _IPriceBandCalculator_     = "IPriceBandCalculator"       ;
    bytes32 internal constant _IModelCalculator_         = "IModelCalculator"        ;
    bytes32 internal constant _IRedButton_               = "IRedButton"              ;
    bytes32 internal constant _IReserveManager_          = "IReserveManager"         ;
    bytes32 internal constant _ISagaExchanger_           = "ISagaExchanger"          ;
    bytes32 internal constant _IMonetaryModel_               = "IMonetaryModel"              ;
    bytes32 internal constant _IMonetaryModelState_          = "IMonetaryModelState"         ;
    bytes32 internal constant _ISGAAuthorizationManager_ = "ISGAAuthorizationManager";
    bytes32 internal constant _ISGAToken_                = "ISGAToken"               ;
    bytes32 internal constant _ISGATokenManager_         = "ISGATokenManager"        ;
    bytes32 internal constant _ISGNAuthorizationManager_ = "ISGNAuthorizationManager";
    bytes32 internal constant _ISGNToken_                = "ISGNToken"               ;
    bytes32 internal constant _ISGNTokenManager_         = "ISGNTokenManager"        ;
    bytes32 internal constant _IMintingPointTimersManager_             = "IMintingPointTimersManager"            ;
    bytes32 internal constant _ITradingClasses_          = "ITradingClasses"         ;
    bytes32 internal constant _IWalletsTradingLimiterValueConverter_        = "IWalletsTLValueConverter"       ;
    bytes32 internal constant _IWalletsTradingDataSource_       = "IWalletsTradingDataSource"      ;
    bytes32 internal constant _WalletsTradingLimiter_SGNTokenManager_          = "WalletsTLSGNTokenManager"         ;
    bytes32 internal constant _WalletsTradingLimiter_SGATokenManager_          = "WalletsTLSGATokenManager"         ;
    bytes32 internal constant _IETHConverter_             = "IETHConverter"   ;
    bytes32 internal constant _ITransactionLimiter_      = "ITransactionLimiter"     ;
    bytes32 internal constant _ITransactionManager_      = "ITransactionManager"     ;
    bytes32 internal constant _IRateApprover_      = "IRateApprover"     ;

    IContractAddressLocator private contractAddressLocator;

    /**
     * @dev Create the contract.
     * @param _contractAddressLocator The contract address locator.
     */
    constructor(IContractAddressLocator _contractAddressLocator) internal {
        require(_contractAddressLocator != address(0), "locator is illegal");
        contractAddressLocator = _contractAddressLocator;
    }

    /**
     * @dev Get the contract address locator.
     * @return The contract address locator.
     */
    function getContractAddressLocator() external view returns (IContractAddressLocator) {
        return contractAddressLocator;
    }

    /**
     * @dev Get the contract address mapped to a given identifier.
     * @param _identifier The identifier.
     * @return The contract address.
     */
    function getContractAddress(bytes32 _identifier) internal view returns (address) {
        return contractAddressLocator.getContractAddress(_identifier);
    }



    /**
     * @dev Determine whether or not the sender is relates to one of the identifiers.
     * @param _identifiers The identifiers.
     * @return Is the sender relates to one of the identifiers.
     */
    function isSenderAddressRelates(bytes32[] _identifiers) internal view returns (bool) {
        return contractAddressLocator.isContractAddressRelates(msg.sender, _identifiers);
    }

    /**
     * @dev Verify that the caller is mapped to a given identifier.
     * @param _identifier The identifier.
     */
    modifier only(bytes32 _identifier) {
        require(msg.sender == getContractAddress(_identifier), "caller is illegal");
        _;
    }

}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;

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

// File: contracts/wallet_trading_limiter/WalletsTradingDataSource.sol

pragma solidity 0.4.25;





/**
 * Details of usage of licenced software see here: https://www.saga.org/software/readme_v1
 */

/**
 * @title Wallets Trading Data Source.
 */
contract WalletsTradingDataSource is IWalletsTradingDataSource, ContractAddressLocatorHolder, Adminable {
    string public constant VERSION = "1.0.0";

    using SafeMath for uint256;

    mapping(address => uint256) public values;

    bytes32[] public walletTradingLimitersContractLocatorIdentifier;

    /**
     * @dev Create the contract.
     * @param _contractAddressLocator The contract address locator.
     */
    constructor(IContractAddressLocator _contractAddressLocator) ContractAddressLocatorHolder(_contractAddressLocator) public {
        bytes32[] memory _walletTradingLimitersContractLocatorIdentifier = new bytes32[](2);
        _walletTradingLimitersContractLocatorIdentifier[0] = _WalletsTradingLimiter_SGNTokenManager_;
        _walletTradingLimitersContractLocatorIdentifier[1] = _WalletsTradingLimiter_SGATokenManager_;
        walletTradingLimitersContractLocatorIdentifier = _walletTradingLimitersContractLocatorIdentifier;
    }

    /**
     * @dev Reverts if called by any address other than one of the wallet trading limiters.
     */
    modifier onlyWalletsTradingLimiters {
        require(isSenderAddressRelates(walletTradingLimitersContractLocatorIdentifier), "caller is illegal");
        _;
    }

    /**
     * @dev Increment the value of a given wallet.
     * @param _wallet The address of the wallet.
     * @param _value The value to increment by.
     * @param _limit The limit of the wallet.
     */
    function updateWallet(address _wallet, uint256 _value, uint256 _limit) external onlyWalletsTradingLimiters {
        uint256 value = values[_wallet].add(_value);
        require(value <= _limit, "trade-limit has been reached");
        values[_wallet] = value;
    }

    /**
     * @dev Reset the values of given wallets.
     * @param _wallets The addresses of the wallets.
     */
    function resetWallets(address[] _wallets) external onlyAdmin {
        for (uint256 i = 0; i < _wallets.length; i++)
            values[_wallets[i]] = 0;
    }
}
