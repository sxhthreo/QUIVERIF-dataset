pragma solidity ^0.4.21;

contract FlowNet {

  mapping (address => uint256) public balances;
  mapping (address => mapping (address => uint256)) public allowed;

  string public name = 'FlowNet';
  uint8 public decimals = 18;
  string public symbol = 'FNT';

  uint256 public totalSupply = 20000*10000 * 1000*1000*1000 * 1000*1000*1000;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  constructor() public {
    balances[msg.sender] = totalSupply;
  }

  /// @return total amount of tokens
  function totalSupply() public view returns (uint256 remaining) {
    return totalSupply;
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
    allowed[_from][msg.sender] -= _value;
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
}
