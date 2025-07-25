pragma solidity ^0.4.17;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract OysterPearl {
    // Public variables of the token
    string public name = "Oyster Pearl";
    string public symbol = "TPRL";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public funds = 0;
    address public owner;
    bool public saleClosed = false;
    bool public ownerLock = false;
    uint256 public claimAmount;
    uint256 public payAmount;
    uint256 public feeAmount;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public buried;
    mapping (address => uint256) public claimed;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    
    event Bury(address indexed target, uint256 value);
    
    event Claim(address indexed payout, address indexed fee);

    /**
     * Constructor function
     *
     * Initializes contract
     */
    function OysterPearl() public {
        owner = msg.sender;
        totalSupply = 0;
        totalSupply += 25000000 * 10 ** uint256(decimals); //marketing share (5%)
        totalSupply += 75000000 * 10 ** uint256(decimals); //devfund share (15%)
        totalSupply += 1000000 * 10 ** uint256(decimals);  //allocation to match PREPRL supply
        balanceOf[owner] = totalSupply;
        
        claimAmount = 5 * 10 ** (uint256(decimals) - 1);
        payAmount = 4 * 10 ** (uint256(decimals) - 1);
        feeAmount = 1 * 10 ** (uint256(decimals) - 1);
    }
    
    modifier onlyOwner {
        require(!ownerLock);
        require(block.number < 8000000);
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
    
    function selfLock() public onlyOwner {
        ownerLock = true;
    }
    
    function amendAmount(uint8 claimAmountSet, uint8 payAmountSet, uint8 feeAmountSet) public onlyOwner {
        require(claimAmountSet == (payAmountSet + feeAmountSet));
        claimAmount = claimAmountSet * 10 ** (uint256(decimals) - 1);
        payAmount = payAmountSet * 10 ** (uint256(decimals) - 1);
        feeAmount = feeAmountSet * 10 ** (uint256(decimals) - 1);
    }
    
    function closeSale() public onlyOwner {
        saleClosed = true;
    }

    function openSale() public onlyOwner {
        saleClosed = false;
    }
    
    function bury() public {
        require(balanceOf[msg.sender] > claimAmount);
        require(!buried[msg.sender]);
        buried[msg.sender] = true;
        claimed[msg.sender] = 1;
        Bury(msg.sender, balanceOf[msg.sender]);
    }
    
    function claim(address _payout, address _fee) public {
        require(buried[msg.sender]);
        require(claimed[msg.sender] == 1 || (block.timestamp - claimed[msg.sender]) >= 60);
        require(balanceOf[msg.sender] >= claimAmount);
        claimed[msg.sender] = block.timestamp;
        balanceOf[msg.sender] -= claimAmount;
        balanceOf[_payout] -= payAmount;
        balanceOf[_fee] -= feeAmount;
        Claim(_payout, _fee);
    }
    
    function () payable public {
        require(!saleClosed);
        require(msg.value >= 1 finney);
        uint256 amount = msg.value * 5000;                // calculates the amount
        require(totalSupply + amount <= (500000000 * 10 ** uint256(decimals)));
        totalSupply += amount;                            // increases the total supply 
        balanceOf[msg.sender] += amount;                  // adds the amount to buyer's balance
        funds += msg.value;                               // track eth amount raised
        Transfer(this, msg.sender, amount);               // execute an event reflecting the change
    }
    
    function withdrawFunds() public onlyOwner {
        owner.transfer(this.balance);
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        require(!buried[_from]);
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
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
        allowance[_from][msg.sender] -= _value;
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
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
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
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
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
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }
}
