pragma solidity ^0.4.24;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        // Prevent transfer to 0x0 address.
        require(newOwner != 0x0);
        owner = newOwner;
    }
}

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract TokenERC20 {
    using SafeMath for uint;

    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    
    event Approval(address indexed tokenOwner, address indexed spender, uint value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function TokenERC20() public {
        totalSupply = 160000000 * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = 'LEXIT';                                   // Set the name for display purposes
        symbol = 'LXT';                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
        // Subtract from the sender
        balanceOf[_from] = balanceOf[_from].sub(_value);
        // Add the same to the recipient
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        approve(_spender, _value);
        spender.receiveApproval(msg.sender, _value, this, _extraData);
        return true;
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);            // Subtract from the sender
        totalSupply = totalSupply.sub(_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] = balanceOf[_from].sub(_value);                         // Subtract from the targeted balance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);             // Subtract from the sender's allowance
        totalSupply = totalSupply.sub(_value);                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}

/******************************************/
/*       LEXIT TOKEN STARTS HERE       */
/******************************************/

contract LexitToken is owned, TokenERC20 {
    using SafeMath for uint;

    uint256 public sellPrice;
    uint256 public buyPrice;

    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function LexitToken() TokenERC20() public {
        sellPrice = 1000 * 10 ** uint256(decimals);
        buyPrice =  1 * 10 ** uint256(decimals);
    }

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
        require (balanceOf[_to].add(_value) > balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balanceOf[_from] = balanceOf[_from].sub(_value);                         // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);                           // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] = balanceOf[target].add(mintedAmount);
        totalSupply = totalSupply.add(mintedAmount);
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    /// @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
    /// @param newSellPrice Price the users can sell to the contract
    /// @param newBuyPrice Price users can buy from the contract
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        require(newSellPrice > 0);
        require(newBuyPrice > 0);
        sellPrice = newSellPrice;        
        buyPrice = newBuyPrice;
    }

    /// @notice Buy tokens from contract by sending ether
    function buy() payable public {
        uint amount = msg.value.div(buyPrice);               // calculates the amount
        _transfer(this, msg.sender, amount);              // makes the transfers
    }

    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function sell(uint256 amount) public {
        require(address(this).balance >= amount.mul(sellPrice));      // checks if the contract has enough ether to buy
        _transfer(msg.sender, this, amount);              // makes the transfers
        msg.sender.transfer(amount.mul(sellPrice));          // sends ether to the seller. It's important to do this last to avoid recursion attacks
    }
    
    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}

contract LxtBountyDistribution is owned {
    using SafeMath for uint;
    
    LexitToken public LXT;
    address public LXT_OWNER; 

    uint256 private constant decimalFactor = 10**uint256(18);

    uint256 public grandTotalClaimed = 0;

    struct Allocation {
        uint256 totalAllocated; // Total tokens allocated
        uint256 amountClaimed;  // Total tokens claimed
    }
  
    mapping(address => Allocation) public allocations;

    mapping (address => bool) public admins;

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }

    function LxtBountyDistribution(LexitToken _tokenContract, address _withdrawnWallet) public {
        LXT = _tokenContract;
        LXT_OWNER = _withdrawnWallet;
    }

    function updateLxtOwner(address _withdrawnWallet) public onlyOwnerOrAdmin {
        LXT_OWNER = _withdrawnWallet;
    }
 
    function setAdmin(address _admin, bool _isAdmin) public onlyOwnerOrAdmin {
        admins[_admin] = _isAdmin;
    }
 
    function setAllocation (address _recipient, uint256 _amount) public onlyOwnerOrAdmin {
        uint256 amount = _amount * decimalFactor;
        uint256 totalAllocated = allocations[_recipient].totalAllocated.add(amount);
        allocations[_recipient] = Allocation(totalAllocated, allocations[_recipient].amountClaimed);
    }

    function setAllocations (address[] _recipients, uint256[] _amounts) public onlyOwnerOrAdmin {
        require(_recipients.length == _amounts.length);

        for (uint256 addressIndex = 0; addressIndex < _recipients.length; addressIndex++) {
            address recipient = _recipients[addressIndex];
            uint256 amount = _amounts[addressIndex] * decimalFactor;

            uint256 totalAllocated = allocations[recipient].totalAllocated.add(amount);
            allocations[recipient] = Allocation(totalAllocated, allocations[recipient].amountClaimed);
        }
    }

    function updateAllocation (address _recipient, uint256 _amount, uint256 _claimedAmount) public onlyOwnerOrAdmin {
        require(_recipient != address(0));

        uint256 amount = _amount * decimalFactor;
        allocations[_recipient] = Allocation(amount, _claimedAmount);
    }

    function transferToken (address _recipient) public onlyOwnerOrAdmin {
        Allocation storage allocation = allocations[_recipient];
        if (allocation.totalAllocated > 0) {
            uint256 amount = allocation.totalAllocated.sub(allocation.amountClaimed);
            require(LXT.transferFrom(LXT_OWNER, _recipient, amount));
            allocation.amountClaimed = allocation.amountClaimed.add(amount);
            grandTotalClaimed = grandTotalClaimed.add(amount);
        }
    }

    function transferTokens (address[] _recipients) public onlyOwnerOrAdmin {
        for (uint256 addressIndex = 0; addressIndex < _recipients.length; addressIndex++) {
            address recipient = _recipients[addressIndex];
            Allocation storage allocation = allocations[recipient];
            if (allocation.totalAllocated > 0) {
                uint256 amount = allocation.totalAllocated.sub(allocation.amountClaimed);
                require(LXT.transferFrom(LXT_OWNER, recipient, amount));
                allocation.amountClaimed = allocation.amountClaimed.add(amount);
                grandTotalClaimed = grandTotalClaimed.add(amount);
            }
        }
    }
    
}
