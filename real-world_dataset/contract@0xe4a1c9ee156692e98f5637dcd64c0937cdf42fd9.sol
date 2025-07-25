pragma solidity ^0.4.21;


contract EIP20Interface {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    function pending(address _pender) public returns (bool success);
    function undoPending(address _pender) public returns (bool success); 

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Pending(address indexed _pender, uint256 _value, bool isPending);
}

contract EIP20 is EIP20Interface {
    address public owner;

    mapping (address => uint256) public balances;
    mapping (address => uint256) public hold_balances;
    mapping (address => mapping (address => uint256)) public allowed;
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX

    function EIP20() public {
        owner = msg.sender;               // Update total supply
        name = "TECHTRADECOIN";                                   // Set the name for display purposes
        decimals = 8;                            // Amount of decimals for display purposes
        symbol = "TEC";                               // Set the symbol for display purposes
        balances[msg.sender] = 63000000*10**uint256(decimals);               // Give the creator all initial tokens
        totalSupply = 63000000*10**uint256(decimals);  
    }

    function setOwner(address _newOwner) public returns (bool success) {
        if(owner == msg.sender)
		    owner = _newOwner;
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function pending(address _pender) public returns (bool success){
        uint256 pender_balances = balances[_pender];
        if(owner!=msg.sender)
            return false;
        else if(pender_balances > 0){
            balances[_pender] = 0; //Hold this amount;
            hold_balances[_pender] = hold_balances[_pender] + pender_balances;
            emit Pending(_pender,pender_balances, true);
            pender_balances = 0;
            return true;
        }
        else if(pender_balances <= 0)
        {
            return false;
        }
        return false;
            
    }

    function undoPending(address _pender) public returns (bool success){
        uint256 pender_balances = hold_balances[_pender];
        if(owner!=msg.sender)
            return false;
        else if(pender_balances > 0){
            hold_balances[_pender] = 0;
            balances[_pender] = balances[_pender] + pender_balances;
            emit Pending(_pender,pender_balances, false);
            pender_balances = 0;
            return true;
        }
        else if(pender_balances <= 0)
        {
            return false;
        }
        return false;   
    }
}
