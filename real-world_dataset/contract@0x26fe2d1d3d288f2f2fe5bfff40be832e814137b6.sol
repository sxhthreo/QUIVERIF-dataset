pragma solidity 0.4.18;

/*===========================================
=                                           =
=     Provided by KEPLER LAB                =
=     Please visit https://keplerlab.io/    =
=                                           =
============================================*/


library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a / b;
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
}

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Pausable is Ownable {
    event Paused();
    event Unpaused();

    bool public pause = false;

    modifier whenNotPaused() {
        require(!pause);
        _;
    }

    modifier whenPaused() {
        require(pause);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        pause = true;
        Paused();
    }

    function unpause() onlyOwner whenPaused public {
        pause = false;
        Unpaused();
    }
}

contract StandardToken is ERC20, Pausable {
    using SafeMath for uint256;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    event AddSupply(address indexed from, uint256 value);
    event Burn(address indexed from, uint256 value);

    function transfer(address _to, uint256 _value) whenNotPaused public returns (bool) {
        require(_to != address(0));
        require(_value > 0);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused public returns (bool) {
        require(_from != address(0));
        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function addSupply(uint256 _value) onlyOwner public returns (bool success) {
        require(_value > 0);      
        balances[msg.sender] = balances[msg.sender].add(_value);                    
        totalSupply = totalSupply.add(_value);                          
        AddSupply(msg.sender, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(_value > 0); 
        require(balances[msg.sender] >= _value);         
        balances[msg.sender] = balances[msg.sender].sub(_value);                    
        totalSupply = totalSupply.sub(_value);                          
        Burn(msg.sender, _value);
        return true;
    }
}

contract JLCToken is StandardToken {

    string public name = "JavisHK Coin";
    string public symbol = "JLC";
    uint public decimals = 18;

    uint public constant TOTAL_SUPPLY    = 10000e18;
    address public constant WALLET_JLC   = 0x6a0Dc4629C0a6A655e8E4DC80b017145b1774622; 

    function JLCToken() public {
        balances[msg.sender] = TOTAL_SUPPLY;
        totalSupply = TOTAL_SUPPLY;

        transfer(WALLET_JLC, TOTAL_SUPPLY);
    }

    function() payable public { }

    function withdrawEther() public {
        if (address(this).balance > 0)
		    owner.send(address(this).balance);
	}

    function withdrawSelfToken() public {
        if(balanceOf(this) > 0)
            this.transfer(WALLET_JLC, balanceOf(this));
    }

    function close() public onlyOwner {
        selfdestruct(owner);
    }
}
