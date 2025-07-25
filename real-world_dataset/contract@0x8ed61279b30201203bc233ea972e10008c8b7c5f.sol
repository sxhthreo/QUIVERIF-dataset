pragma solidity ^0.4.16;

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

 contract ERC20Interface {
     function balanceOf(address _owner) constant returns (uint256 balance);
     function transfer(address _to, uint256 _value) returns (bool success);
     function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
     function approve(address _spender, uint256 _value) returns (bool success);
     function allowance(address _owner, address _spender) constant returns (uint256 remaining);
        
     event Transfer(address indexed _from, address indexed _to, uint256 _value);
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    }

 contract GenesisToken is ERC20Interface {
     
     using SafeMath for uint256;
     
     string public constant symbol = "GEN";
     string public constant name = "Genesis";
     uint8 public constant decimals = 18;
     uint256 _totalSupply = 16000000000000000000000000;
     
     address public owner;
 
    mapping(address => uint256) balances;
    
    mapping(address => mapping (address => uint256)) allowed;
    
    modifier onlyOwner() {
         if (msg.sender != owner) {
             revert();
         }
         _;
     }
     
    function GenesisToken() {
        owner = msg.sender;
        balances[owner] = _totalSupply;
    } 
    
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (balances[msg.sender] >= _amount 
             && _amount > 0
             && balances[_to] + _amount > balances[_to]) {
             balances[msg.sender] = balances[msg.sender].sub(_amount);
             balances[_to] = balances[_to].add(_amount);
             Transfer(msg.sender, _to, _amount);
             return true;
         } else {
             return false;
         }
    }
    
    function transferFrom(
            address _from,
            address _to,
            uint256 _amount
        )   returns (bool success) {
            if (balances[_from] >= _amount
             && allowed[_from][msg.sender] >= _amount
             && _amount > 0
             && balances[_to] + _amount > balances[_to]) {
             balances[_from] = balances[_from].sub(_amount);
             allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
             balances[_to] = balances[_to].add(_amount);
             Transfer(_from, _to, _amount);
             return true;
         }  else {
             return false;
         }
    }
    
    function approve(address _spender, uint256 _amount) returns (bool success) {
         allowed[msg.sender][_spender] = _amount;
         Approval(msg.sender, _spender, _amount);
         return true;
    }
    
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
         return allowed[_owner][_spender];
    }
	
	function airdrop(uint256 amount, address[] addresses) onlyOwner {
    for (uint i = 0; i < addresses.length; i++) {
      balances[owner].sub(amount);
      balances[addresses[i]].add(amount);
      Transfer(owner, addresses[i], amount);
    }
  }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}
