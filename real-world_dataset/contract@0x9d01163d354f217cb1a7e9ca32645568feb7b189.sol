pragma solidity ^0.4.17;

contract Ownable {
    
    address public owner;

    event OwnershipTransferred(address from, address to);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);
        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

}

library SafeMath {
    
    function mul(uint256 a, uint256 b) internal  returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20 {
    uint256 public totalSupply;
    uint8 public decimals;
    string public name;
    string public symbol;
    function balanceOf(address who) constant public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function allowance(address owner, address spender) constant public returns (uint256);
    function transferFrom(address from, address to, uint256 value) public  returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SHNZ is ERC20, Ownable {
    
    using SafeMath for uint256;
    
    uint256 private tokensSold;
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;
  
    event TokensIssued(address from, address to, uint256 amount);

    function SHNZ() public {
        totalSupply = 1000000000000000000;
        decimals = 8;
        name = "ShizzleNizzle";
        symbol = "SHNZ";
        balances[this] = totalSupply;
    }

    function balanceOf(address _addr) public constant returns (uint256) {
        return balances[_addr];
    }

    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function approve(address _spender, uint256 _amount) public returns (bool) {
        allowances[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowances[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
        require(allowances[_from][msg.sender] >= _amount && balances[_from] >= _amount);
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_amount);
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }
    
    function issueTokens(address _to, uint256 _amount) public onlyOwner {
        require(_to != 0x0 && _amount > 0);
        if (balances[this] <= _amount) {
            balances[_to] = balances[_to].add(balances[this]);
            Transfer(0x0, _to, balances[this]);
            balances[this] = 0;
        } else {
            balances[this] = balances[this].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            Transfer(0x0, _to, _amount);
        }
    }

    function getTotalSupply() public constant returns (uint256) {
        return totalSupply;
    }
}

contract TokenSale is Ownable {

    using SafeMath for uint256;

    uint256 public rate;
    uint256 public ETHcap;
    uint256 public totalRaised;
    SHNZ public token;


    function TokenSale() public {
        token = new SHNZ();
        ETHcap = 589811999999971700000000;
        rate = 1695455501075;
        owner = 0x7e826E85CbA4d3AAaa1B484f53BE01D10F527Fd6;
    }

    function() public payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address _beneficiary) public payable {
        require(_beneficiary != 0x0 && totalRaised < ETHcap);
        totalRaised = totalRaised.add(msg.value);
        uint256 weiAmount = msg.value;
        if (totalRaised > ETHcap) {
            msg.sender.transfer(totalRaised.sub(ETHcap));
            weiAmount = weiAmount.sub(totalRaised.sub(ETHcap));
            totalRaised = totalRaised.sub(totalRaised.sub(ETHcap));
        }
        token.issueTokens(msg.sender, weiAmount.mul(rate).div(1000000000000000000));
        forwardFunds(weiAmount);
    }

    function forwardFunds(uint256 _amount) internal {
        owner.transfer(_amount);
    }
    
    function issueTokens(address _beneficiary, uint256 _amount) onlyOwner {
        require(_beneficiary != 0x0 && _amount > 0);
        token.issueTokens(_beneficiary, _amount.mul(100000000));
        ETHcap = ETHcap.sub(_amount.mul(100000000000000000000000000).div(rate));
    }
}
