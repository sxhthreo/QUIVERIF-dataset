pragma solidity ^0.4.4;

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
    assert(c >= a && c>=b);
    return c;
  }
}


// source : https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
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

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }


contract HappyLoadTokens is ERC20Interface {
  using SafeMath for uint;

  // State variables
  string public name = 'Happyload';
  string public symbol = 'HLO';
  uint public decimals = 18;
  address public owner;
  uint public totalSupply = 25000000 * (10 ** 18);
  bool public emergencyFreeze;

  // mappings
  mapping (address => uint) balances;
  mapping (address => mapping (address => uint) ) allowed;
  mapping (address => bool) frozen;


  // constructor
  constructor () public {
    owner = msg.sender;
    balances[owner] = totalSupply;
    emit Transfer(0x0, owner, totalSupply);
  }

  // events
  event OwnershipTransferred(address indexed _from, address indexed _to);
  event Burn(address indexed from, uint256 amount);
  event Freezed(address targetAddress, bool frozen);
  event EmerygencyFreezed(bool emergencyFreezeStatus);
  


  // Modifiers
  modifier onlyOwner {
    require(msg.sender == owner);
     _;
  }

  modifier unfreezed(address _account) {
    require(!frozen[_account]);
    _;
  }
  
  modifier noEmergencyFreeze() { 
    require(!emergencyFreeze);
    _; 
  }
  


  // functions

  // ------------------------------------------------------------------------
  // Transfer Token
  // ------------------------------------------------------------------------
  function transfer(address _to, uint _value) unfreezed(_to) unfreezed(msg.sender) noEmergencyFreeze() public returns (bool success) {
    require(_to != 0x0);
    require(balances[msg.sender] >= _value); 
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  // ------------------------------------------------------------------------
  // Approve others to spend on your behalf
  // ------------------------------------------------------------------------
  /* 
    While changing approval, the allowed must be changed to 0 than then to updated value
    The smart contract enforces this for security reasons
   */
  function approve(address _spender, uint _value) unfreezed(_spender) unfreezed(msg.sender) noEmergencyFreeze() public returns (bool success) {
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition 
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  // ------------------------------------------------------------------------
  // Approve and call : If approve returns true, it calls receiveApproval method of contract
  // ------------------------------------------------------------------------
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success)
    {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

  // ------------------------------------------------------------------------
  // Transferred approved amount from other's account
  // ------------------------------------------------------------------------
  function transferFrom(address _from, address _to, uint _value) unfreezed(_to) unfreezed(_from) unfreezed(msg.sender) noEmergencyFreeze() public returns (bool success) {
    require(_value <= allowed[_from][msg.sender]);
    require (_value <= balances[_from]);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }


  // ------------------------------------------------------------------------
  // Burn (Destroy tokens)
  // ------------------------------------------------------------------------
  function burn(uint256 _value) unfreezed(msg.sender) public returns (bool success) {
    require(balances[msg.sender] >= _value);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(msg.sender, _value);
    return true;
  }

  // ------------------------------------------------------------------------
  //               ONLYOWNER METHODS                             
  // ------------------------------------------------------------------------


  // ------------------------------------------------------------------------
  // Transfer Ownership
  // ------------------------------------------------------------------------
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    owner = _newOwner;
    emit OwnershipTransferred(owner, _newOwner);
  }


  // ------------------------------------------------------------------------
  //               CONSTANT METHODS
  // ------------------------------------------------------------------------


  // ------------------------------------------------------------------------
  // Check Allowance : Constant
  // ------------------------------------------------------------------------
  function allowance(address _tokenOwner, address _spender) public constant returns (uint remaining) {
    return allowed[_tokenOwner][_spender];
  }

  // ------------------------------------------------------------------------
  // Check Balance : Constant
  // ------------------------------------------------------------------------
  function balanceOf(address _tokenOwner) public constant returns (uint balance) {
    return balances[_tokenOwner];
  }

  // ------------------------------------------------------------------------
  // Total supply : Constant
  // ------------------------------------------------------------------------
  function totalSupply() public constant returns (uint) {
    return totalSupply;
  }

  // ------------------------------------------------------------------------
  // Get Freeze Status : Constant
  // ------------------------------------------------------------------------
  function isFreezed(address _targetAddress) public constant returns (bool) {
    return frozen[_targetAddress];
  }



  // ------------------------------------------------------------------------
  // Prevents contract from accepting ETH
  // ------------------------------------------------------------------------
  function () public payable {
    revert();
  }

  // ------------------------------------------------------------------------
  // Owner can transfer out any accidentally sent ERC20 tokens
  // ------------------------------------------------------------------------
  function transferAnyERC20Token(address _tokenAddress, uint _value) public onlyOwner returns (bool success) {
      return ERC20Interface(_tokenAddress).transfer(owner, _value);
  }
}
