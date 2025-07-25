pragma solidity ^0.4.17;

contract owned {

    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract tokenRecipient { 
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
} 

contract IERC20Token {

  // Get the total token supply
  function totalSupply() constant returns (uint256 totalSupply);

  // Get the account balance of another account with address _owner
  function balanceOf(address _owner) constant returns (uint256 balance) {}

  // Send _value amount of tokens to address _to
  function transfer(address _to, uint256 _value) returns (bool success) {}

  // Send _value amount of tokens from address _from to address _to
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

  // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
  // If this function is called again it overwrites the current allowance with _value.
  // this function is required for some DEX functionality
  function approve(address _spender, uint256 _value) returns (bool success) {}

  // Returns the amount which _spender is still allowed to withdraw from _owner
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

  // Triggered when tokens are transferred
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  
  // Triggered whenever approve(address _spender, uint256 _value) is called
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
} 

contract ValusToken is IERC20Token, owned{

  /* Public variables of the token */
  string public standard = "VALUS token v1.0";
  string public name = "VALUS";
  string public symbol = "VLS";
  uint8 public decimals = 18;
  address public crowdsaleContractAddress;
  uint256 public tokenFrozenUntilBlock;

  /* Private variables of the token */
  uint256 supply = 0;
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowances;
  mapping (address => bool) restrictedAddresses;

  /* Events */
  event Mint(address indexed _to, uint256 _value);
  event Burn(address indexed _from, uint256 _value);
  event TokenFrozen(uint256 _frozenUntilBlock, string _reason);

  /* Initializes contract and  sets restricted addresses */
  function ValusToken() {
    restrictedAddresses[0x0] = true;
    restrictedAddresses[0x8F8e5e6515c3e6088c327257bDcF2c973B1530ad] = true;
    restrictedAddresses[address(this)] = true;
    crowdsaleContractAddress = 0x8F8e5e6515c3e6088c327257bDcF2c973B1530ad;
  }

  /* Returns total supply of issued tokens */
  function totalSupply() constant returns (uint256 totalSupply) {
    return supply;
  }

  /* Returns balance of address */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  /* Transfers tokens from your address to other */
  function transfer(address _to, uint256 _value) returns (bool success) {
    if (block.number < tokenFrozenUntilBlock) throw;    // Throw if token is frozen
    if (restrictedAddresses[_to]) throw;                // Throw if recipient is restricted address
    if (balances[msg.sender] < _value) throw;           // Throw if sender has insufficient balance
    if (balances[_to] + _value < balances[_to]) throw;  // Throw if owerflow detected
    balances[msg.sender] -= _value;                     // Deduct senders balance
    balances[_to] += _value;                            // Add recivers blaance 
    Transfer(msg.sender, _to, _value);                  // Raise Transfer event
    return true;
  }

  /* Approve other address to spend tokens on your account */
  function approve(address _spender, uint256 _value) returns (bool success) {
    if (block.number < tokenFrozenUntilBlock) throw;    // Throw if token is frozen        
    allowances[msg.sender][_spender] = _value;          // Set allowance         
    Approval(msg.sender, _spender, _value);             // Raise Approval event         
    return true;
  }

  /* Approve and then communicate the approved contract in a single tx */ 
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {            
    tokenRecipient spender = tokenRecipient(_spender);              // Cast spender to tokenRecipient contract         
    approve(_spender, _value);                                      // Set approval to contract for _value         
    spender.receiveApproval(msg.sender, _value, this, _extraData);  // Raise method on _spender contract         
    return true;     
  }     

  /* A contract attempts to get the coins */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {      
    if (block.number < tokenFrozenUntilBlock) throw;    // Throw if token is frozen
    if (restrictedAddresses[_to]) throw;                // Throw if recipient is restricted address  
    if (balances[_from] < _value) throw;                // Throw if sender does not have enough balance     
    if (balances[_to] + _value < balances[_to]) throw;  // Throw if overflow detected    
    if (_value > allowances[_from][msg.sender]) throw;  // Throw if you do not have allowance       
    balances[_from] -= _value;                          // Deduct senders balance    
    balances[_to] += _value;                            // Add recipient blaance         
    allowances[_from][msg.sender] -= _value;            // Deduct allowance for this address         
    Transfer(_from, _to, _value);                       // Raise Transfer event
    return true;     
  }         

  /* Get the amount of allowed tokens to spend */     
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {         
    return allowances[_owner][_spender];
  }         

  /* Issue new tokens */     
  function mintTokens(address _to, uint256 _amount) {         
    if (msg.sender != crowdsaleContractAddress) throw;            // Only Crowdsale address can mint tokens        
    if (restrictedAddresses[_to]) throw;                    // Throw if user wants to send to restricted address       
    if (balances[_to] + _amount < balances[_to]) throw;     // Check for overflows
    supply += _amount;                                      // Update total supply
    balances[_to] += _amount;                               // Set minted coins to target
    Mint(_to, _amount);                                     // Create Mint event       
    Transfer(0x0, _to, _amount);                            // Create Transfer event from 0x
  }     

  /* Stops all token transfers in case of emergency */
  function freezeTransfersUntil(uint256 _frozenUntilBlock, string _reason) onlyOwner {      
    tokenFrozenUntilBlock = _frozenUntilBlock;
    TokenFrozen(_frozenUntilBlock, _reason);
  }

  function isRestrictedAddress(address _querryAddress) constant returns (bool answer){
    return restrictedAddresses[_querryAddress];
  }
}
