pragma solidity ^0.4.13;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract MartinLarbaoui2 is Ownable  {
    using SafeMath for uint256;

    

    
    /*Variables about the token contract */    
    Peculium public pecul; // The Peculium token
    bool public initPecul; // boolean to know if the Peculium token address has been init
    
    event InitializedToken(address contractToken);
    
    /*Variables about the client manager */
    address public clientmanager ; // address of the client manager 
    uint256 public clientmanagerShare; // nb token for the clientmanager
    bool public First_pay_clientmanager; // boolean to test if the first pay has been send to the clientmanager
    uint256 public first_pay; // pourcent of the first pay rate
    uint256 public montly_pay; // pourcent of the montly pay rate
    bool public clientInit; // boolean to know if the client address has been init
    uint256 public payday; // Day when the client manager is paid
    uint256 public nbMonthsPay; // The montly pay is sent for 6 months

    event InitializedManager(address ManagerAdd);
    event FirstPaySend(uint256 first,address receiver);
    event MonthlyPaySend(uint256 monthPay,address receiverMonthly);
    
    
    //Constructor
    function Larbaoui() {
        
        clientmanagerShare = SafeMath.mul(7000000,(10**8)); // we allocate 72 million token to the client manager (maybe to change)
        
        first_pay = SafeMath.div(SafeMath.mul(40,clientmanagerShare),100); // first pay is 40%
        montly_pay = SafeMath.div(SafeMath.mul(10,clientmanagerShare),100); // other pay are 10%
        nbMonthsPay = 0;
        
        First_pay_clientmanager=true;
        initPecul = false;
        clientInit==false;
        

    }
    
    
    /***  Functions of the contract ***/
    
    function InitPeculiumAdress(address peculAdress) onlyOwner 
    { // We init the address of the token
    
        pecul = Peculium(peculAdress);
        payday = now;
        initPecul = true;
        InitializedToken(peculAdress);
    
    }
    
    function change_client_manager (address public_key) onlyOwner 
    { // to change the client manager address
    
        clientmanager = public_key;
        clientInit=true;
        InitializedManager(public_key);
    
    }
    
    function transferManager() onlyOwner Initialize clientManagerInit 
    { // Transfer pecul for the client manager
        
        require(now > payday);
    
        if(First_pay_clientmanager==false && nbMonthsPay < 6)
        {

            pecul.transfer(clientmanager,montly_pay);
            payday = payday.add( 31 days);
            nbMonthsPay=nbMonthsPay.add(1);
            MonthlyPaySend(montly_pay,clientmanager);
        
        }
        
        if(First_pay_clientmanager==true)
        {

            pecul.transfer(clientmanager,first_pay);
            payday = payday.add( 31 days);
            First_pay_clientmanager=false;
            FirstPaySend(first_pay,clientmanager);
        
        }


        
    }
        /***  Modifiers of the contract ***/
    
    modifier Initialize { // We need to initialize first the token contract
        require (initPecul==true);
        _;
        }
        modifier clientManagerInit { // We need to initialize first the address of the clientManager
        require (clientInit==true);
        _;
        } 

}

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

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
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool)  {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

contract Peculium is BurnableToken,Ownable { // Our token is a standard ERC20 Token with burnable and ownable aptitude

    using SafeMath for uint256; // We use safemath to do basic math operation (+,-,*,/)
    using SafeERC20 for ERC20Basic; 

        /* Public variables of the token for ERC20 compliance */
    string public name = "Peculium"; //token name 
        string public symbol = "PCL"; // token symbol
        uint256 public decimals = 8; // token number of decimal
        
        /* Public variables specific for Peculium */
        uint256 public constant MAX_SUPPLY_NBTOKEN   = 20000000000*10**8; // The max cap is 20 Billion Peculium

    uint256 public dateStartContract; // The date of the deployment of the token
    mapping(address => bool) public balancesCanSell; // The boolean variable, to frost the tokens
    uint256 public dateDefrost; // The date when the owners of token can defrost their tokens


        /* Event for the freeze of account */
     event FrozenFunds(address target, bool frozen);          
         event Defroze(address msgAdd, bool freeze);
    


   
    //Constructor
    function Peculium() {
        totalSupply = MAX_SUPPLY_NBTOKEN;
        balances[owner] = totalSupply; // At the beginning, the owner has all the tokens. 
        balancesCanSell[owner] = true; // The owner need to sell token for the private sale and for the preICO, ICO.
        
        dateStartContract=now;
        dateDefrost = dateStartContract + 85 days; // everybody can defrost his own token after the 25 january 2018 (85 days after 1 November)

    }

    /*** Public Functions of the contract ***/    
    
    function defrostToken() public 
    { // Function to defrost your own token, after the date of the defrost
    
        require(now>dateDefrost);
        balancesCanSell[msg.sender]=true;
        Defroze(msg.sender,true);
    }
                
    function transfer(address _to, uint256 _value) public returns (bool) 
    { // We overright the transfer function to allow freeze possibility
    
        require(balancesCanSell[msg.sender]);
        return BasicToken.transfer(_to,_value);
    
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) 
    { // We overright the transferFrom function to allow freeze possibility (need to allow before)
    
        require(balancesCanSell[msg.sender]);    
        return StandardToken.transferFrom(_from,_to,_value);
    
    }

    /***  Owner Functions of the contract ***/    

       function freezeAccount(address target, bool canSell) onlyOwner 
       {
        
            balancesCanSell[target] = canSell;
            FrozenFunds(target, canSell);
        
        }


    /*** Others Functions of the contract ***/    
    
    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
            return true;
    }

      function getBlockTimestamp() constant returns (uint256)
      {
        
            return now;
      
      }

      function getOwnerInfos() constant returns (address ownerAddr, uint256 ownerBalance)  
      { // Return info about the public address and balance of the account of the owner of the contract
        
            ownerAddr = owner;
        ownerBalance = balanceOf(ownerAddr);
      
      }

}
