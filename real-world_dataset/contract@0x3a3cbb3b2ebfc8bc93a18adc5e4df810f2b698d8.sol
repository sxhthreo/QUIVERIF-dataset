pragma solidity ^0.4.15;

//
// BUZZ is a voucher used as payment within Buzz.im website. 
// You can use this token to pay for advertising on the network.
// Ofcourse you can also use Fiat currencies and pay with credit
// card, but the amount of Buzz credited to your account will be
// converted according to current exchange rate on decetralized
// exchanges.
//

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
    assert(c >= a);
    return c;
  }
}
contract Base {
    modifier only(address allowed) {
        require(msg.sender == allowed);
        _;
    }
}

contract Owned is Base {
    address public owner;
    address newOwner;
    function Owned() public {
        owner = msg.sender;
    }
    function transferOwnership(address _newOwner) only(owner) public {
        newOwner = _newOwner;
    }
    function acceptOwnership() only(newOwner) public {
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    event OwnershipTransferred(address indexed _from, address indexed _to);
}

contract ERC20 is Owned {
    using SafeMath for uint;
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    function transfer(address _to, uint _value) isStartedOnly public returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint _value) isStartedOnly public returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    function balanceOf(address _owner) constant public returns (uint balance) {
        return balances[_owner];
    }
    function approve_fixed(address _spender, uint _currentValue, uint _value) isStartedOnly public returns (bool success) {
        if(allowed[msg.sender][_spender] == _currentValue){
            allowed[msg.sender][_spender] = _value;
            Approval(msg.sender, _spender, _value);
            return true;
        } else {
            return false;
        }
    }
    function approve(address _spender, uint _value) isStartedOnly public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) constant public returns (uint remaining) {
        return allowed[_owner][_spender];
    }
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    uint public totalSupply;
    bool    public isStarted = false;
    modifier isStartedOnly() {
        require(isStarted);
        _;
    }

}

contract BUZZ is ERC20 {
    using SafeMath for uint;
    string public name = "Buzz.im";
    string public symbol = "BUZZ";
    uint8 public decimals = 18;
    modifier isNotStartedOnly() {
        require(!isStarted);
        _;
    }
    function getTotalSupply()
    public
    constant
    returns(uint)
    {
        return totalSupply;
    }
    
    // Bootstrap the contract and make the tokens
    // transferrable. No more minting will be possible.
    function start()
    public
    only(owner)
    isNotStartedOnly
    {
        isStarted = true;
    }

    function multiTransfer(address[] dests, uint[] values) public
    only(owner)
    isStartedOnly
    returns (uint) {
        uint i = 0;
        while (i < dests.length) {
           transfer(dests[i], values[i]);
           i += 1;
        }
        return(i);
    }

    //
    // before start:
    // 
    function mint(address _to, uint _amount) public
    only(owner)
    isNotStartedOnly
    returns(bool)
    {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }
}
