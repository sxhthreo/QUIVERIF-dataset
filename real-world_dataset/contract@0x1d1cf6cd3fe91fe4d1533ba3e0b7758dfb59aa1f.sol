pragma solidity ^ 0.4 .11;





contract tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}


contract ERC20 {

    function totalSupply() constant returns(uint _totalSupply);

    function balanceOf(address who) constant returns(uint256);

    function transfer(address to, uint value) returns(bool ok);

    function transferFrom(address from, address to, uint value) returns(bool ok);

    function approve(address spender, uint value) returns(bool ok);

    function allowance(address owner, address spender) constant returns(uint);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

}

contract Burner { function dragonHandler( uint256 _amount){} }
 
contract Dragon is ERC20 {


    string public standard = 'DRAGON 1.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
  
    
    address public owner;
    mapping( address => uint256) public balanceOf;
    mapping( uint => address) public accountIndex;
    uint accountCount;
    
    mapping(address => mapping(address => uint256)) public allowance;
    address public burner;
    bool public burnerSet;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed spender, uint value);
    event Message ( address a, uint256 amount );
    event Burn(address indexed from, uint256 value);

    
    function Dragon() {
         
        uint supply = 50000000000000000; 
        appendTokenHolders( msg.sender );
        balanceOf[msg.sender] =  supply;
        totalSupply = supply; // 
        name = "DRAGON"; // Set the name for display purposes
        symbol = "DRG"; // Set the symbol for display purposes
        decimals = 8; // Amount of decimals for display purposes
        owner = msg.sender;
        
  
    }
    
    
    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }

     modifier onlyBurner() {
        if (msg.sender != burner) {
            throw;
        }
        _;
    }
    
    function changeOwnership( address _owner ) onlyOwner {
        
        owner = _owner;
        
    }
    
    function setBurner( address _burner ) onlyOwner {
        require ( !burnerSet );
        burner = _burner;
        burnerSet = true;
        
    }

    function burnCheck( address _tocheck , uint256 amount ) internal {
        
        if ( _tocheck != burner )return;
        
        Burner burn = Burner ( burner );
        burn.dragonHandler( amount );
        
        
    }
    
    function burnDragons ( uint256 _amount ) onlyBurner{
        
        
        burn( _amount );
        
        
    }
    
    function balanceOf(address tokenHolder) constant returns(uint256) {

        return balanceOf[tokenHolder];
    }

    function totalSupply() constant returns(uint256) {

        return totalSupply;
    }

    function getAccountCount() constant returns(uint256) {

        return accountCount;
    }

    function getAddress(uint slot) constant returns(address) {

        return accountIndex[slot];

    }

    
    function appendTokenHolders(address tokenHolder) private {

        if (balanceOf[tokenHolder] == 0) {
            if ( tokenHolder == burner ) return;
            accountIndex[accountCount] = tokenHolder;
            accountCount++;
        }

    }

    
    function transfer(address _to, uint256 _value) returns(bool ok) {
        if (_to == 0x0) throw; 
        if (balanceOf[msg.sender] < _value) throw; 
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;
        
        appendTokenHolders(_to);
        balanceOf[msg.sender] -= _value; 
        balanceOf[_to] += _value; 
        Transfer(msg.sender, _to, _value); 
        burnCheck( _to, _value );
        
        return true;
    }
    
    function approve(address _spender, uint256 _value)
    returns(bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval( msg.sender ,_spender, _value);
        return true;
    }

 
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    returns(bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
        return allowance[_owner][_spender];
    }

 
    function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
        if (_to == 0x0) throw;  
        if (balanceOf[_from] < _value) throw;  
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        if (_value > allowance[_from][msg.sender]) throw; 
        appendTokenHolders(_to);
        balanceOf[_from] -= _value; 
        balanceOf[_to] += _value; 
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
       
        return true;
    }
  
    function burn(uint256 _value) returns(bool success) {
        if (balanceOf[msg.sender] < _value) throw; 
        if( totalSupply -  _value < 2100000000000000) throw;
        balanceOf[msg.sender] -= _value; 
        totalSupply -= _value; 
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) returns(bool success) {
    
        if (balanceOf[_from] < _value) throw; 
        if (_value > allowance[_from][msg.sender]) throw; 
        balanceOf[_from] -= _value; 
        totalSupply -= _value; 
        Burn(_from, _value);
        return true;
    }
 
    
}
