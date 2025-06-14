pragma solidity ^0.4.11;
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }
  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
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
  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}
contract Ownable {
    address public owner;
    function Ownable() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}
/*
 * Pausable
 * Abstract contract that allows children to implement an
 * emergency stop mechanism.
 */
contract Pausable is Ownable {
  bool public stopped;
  modifier stopInEmergency {
    if (stopped) {
      throw;
    }
    _;
  }
  
  modifier onlyInEmergency {
    if (!stopped) {
      throw;
    }
    _;
  }
  // called by the owner on emergency, triggers stopped state
  function emergencyStop() external onlyOwner {
    stopped = true;
  }
  // called by the owner on end of emergency, returns to normal state
  function release() external onlyOwner onlyInEmergency {
    stopped = false;
  }
}
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}
/*
 * PullPayment
 * Base contract supporting async send for pull payments.
 * Inherit from this contract and use asyncSend instead of send.
 */
contract PullPayment {
  using SafeMath for uint;
  
  mapping(address => uint) public payments;
  event LogRefundETH(address to, uint value);
  /**
  *  Store sent amount as credit to be pulled, called by payer 
  **/
  function asyncSend(address dest, uint amount) internal {
    payments[dest] = payments[dest].add(amount);
  }
  // withdraw accumulated balance, called by payee
  function withdrawPayments() {
    address payee = msg.sender;
    uint payment = payments[payee];
    
    if (payment == 0) {
      throw;
    }
    if (this.balance < payment) {
      throw;
    }
    payments[payee] = 0;
    if (!payee.send(payment)) {
      throw;
    }
    LogRefundETH(payee,payment);
  }
}
contract BasicToken is ERC20Basic {
  
  using SafeMath for uint;
  
  mapping(address => uint) balances;
  
  /*
   * Fix for the ERC20 short address attack  
  */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
}
contract StandardToken is BasicToken, ERC20 {
  mapping (address => mapping (address => uint)) allowed;
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];
    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }
  function approve(address _spender, uint _value) {
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}
/**
 *  NewHope token contract. Implements
 */
contract NewHope is StandardToken, Ownable {
  string public constant name = "NewHope";
  string public constant symbol = "NewH";
  uint public constant decimals = 6;
  // Constructor
  function NewHope() {
      totalSupply = 1000000000000;//1M
      balances[msg.sender] = totalSupply; // Send all tokens to owner
  }
  /**
   *  Burn away the specified amount of NewHope tokens
   */
  function burn(uint _value) onlyOwner returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Transfer(msg.sender, 0x0, _value);
    return true;
  }
}
/*
  Crowdsale Smart Contract for the NewHope.org project
  This smart contract collects ETH, and in return emits NewHope tokens to the backers
*/
contract Crowdsale is Pausable, PullPayment {
    
    using SafeMath for uint;
    struct Backer {
        uint weiReceived; // Amount of Ether given
        uint coinSent;
    }
    /*
    * Constants
    */
    /* Minimum number of NewHope to sell */
    uint public constant MIN_CAP = 50000000000; // 50,000 NewHopes
    /* Maximum number of NewHope to sell */
    uint public constant MAX_CAP = 700000000000; // 700,000 NewHopes
    /* Minimum amount to invest */
    uint public constant MIN_INVEST_ETHER = 100 finney;
    /* Crowdsale period */
    uint private constant CROWDSALE_PERIOD = 5 days;
    /* Number of NewHopes per Ether */
    uint public constant COIN_PER_ETHER = 9000000000; // 9,000 NewHopes
    /*
    * Variables
    */
    /* NewHope contract reference */
    NewHope public coin;
    /* Multisig contract that will receive the Ether */
    address public multisigEther;
    /* Number of Ether received */
    uint public etherReceived;
    /* Number of NewHopes sent to Ether contributors */
    uint public coinSentToEther;
    /* Crowdsale start time */
    uint public startTime;
    /* Crowdsale end time */
    uint public endTime;
    /* Is crowdsale still on going */
    bool public crowdsaleClosed;
    /* Backers Ether indexed by their Ethereum address */
    mapping(address => Backer) public backers;
    /*
    * Modifiers
    */
    modifier minCapNotReached() {
        if ((now < endTime) || coinSentToEther >= MIN_CAP ) throw;
        _;
    }
    modifier respectTimeFrame() {
        if ((now < startTime) || (now > endTime )) throw;
        _;
    }
    /*
     * Event
    */
    event LogReceivedETH(address addr, uint value);
    event LogCoinsEmited(address indexed from, uint amount);
    /*
     * Constructor
    */
    function Crowdsale(address _NewHopeAddress, address _to) {
        coin = NewHope(_NewHopeAddress);
        multisigEther = _to;
    }
    /* 
     * The fallback function corresponds to a donation in ETH
     */
    function() stopInEmergency respectTimeFrame payable {
        receiveETH(msg.sender);
    }
    /* 
     * To call to start the crowdsale
     */
    function start() onlyOwner {
        if (startTime != 0) throw; // Crowdsale was already started
        startTime = now ;            
        endTime =  now + CROWDSALE_PERIOD;    
    }
    /*
     *  Receives a donation in Ether
    */
    function receiveETH(address beneficiary) internal {
        if (msg.value < MIN_INVEST_ETHER) throw; // Don't accept funding under a predefined threshold
        
        uint coinToSend = bonus(msg.value.mul(COIN_PER_ETHER).div(1 ether)); // Compute the number of NewHope to send
        if (coinToSend.add(coinSentToEther) > MAX_CAP) throw;    
        Backer backer = backers[beneficiary];
        coin.transfer(beneficiary, coinToSend); // Transfer NewHopes right now 
        backer.coinSent = backer.coinSent.add(coinToSend);
        backer.weiReceived = backer.weiReceived.add(msg.value); // Update the total wei collected during the crowdfunding for this backer    
        etherReceived = etherReceived.add(msg.value); // Update the total wei collected during the crowdfunding
        coinSentToEther = coinSentToEther.add(coinToSend);
        // Send events
        LogCoinsEmited(msg.sender ,coinToSend);
        LogReceivedETH(beneficiary, etherReceived); 
    }
    
    /*
     *Compute the NewHope bonus according to the investment period
     */
    function bonus(uint amount) internal constant returns (uint) {
        if (now < startTime.add(1 days)) return amount.add(amount.div(2));   // bonus 50%
        return amount;
    }
    /*  
     * Finalize the crowdsale, should be called after the refund period
    */
    function finalize() onlyOwner public {
        if (now < endTime) { // Cannot finalise before CROWDSALE_PERIOD or before selling all coins
            if (coinSentToEther == MAX_CAP) {
            } else {
                throw;
            }
        }
        if (coinSentToEther < MIN_CAP && now < endTime + 3 days) throw; // If MIN_CAP is not reached donors have 15days to get refund before we can finalise
        if (!multisigEther.send(this.balance)) throw; // Move the remaining Ether to the multisig address
        
        uint remains = coin.balanceOf(this);
        if (remains > 0) { // Burn the rest of NewHopes
            if (!coin.burn(remains)) throw ;
        }
        crowdsaleClosed = true;
    }
    /*  
    * Failsafe drain
    */
    function drain() onlyOwner {
        if (!owner.send(this.balance)) throw;
    }
    /**
     * Allow to change the team multisig address in the case of emergency.
     */
    function setMultisig(address addr) onlyOwner public {
        if (addr == address(0)) throw;
        multisigEther = addr;
    }
    /**
     * Manually back NewHope owner address.
     */
    function backNewHopeOwner() onlyOwner public {
        coin.transferOwnership(owner);
    }
    /**
     * Transfer remains to owner in case if impossible to do min invest
     */
    function getRemainCoins() onlyOwner public {
        var remains = MAX_CAP - coinSentToEther;
        uint minCoinsToSell = bonus(MIN_INVEST_ETHER.mul(COIN_PER_ETHER) / (1 ether));
        if(remains > minCoinsToSell) throw;
        Backer backer = backers[owner];
        coin.transfer(owner, remains); // Transfer NewHopes right now 
        backer.coinSent = backer.coinSent.add(remains);
        coinSentToEther = coinSentToEther.add(remains);
        // Send events
        LogCoinsEmited(this ,remains);
        LogReceivedETH(owner, etherReceived); 
    }
    /* 
     * When MIN_CAP is not reach:
     * 1) backer call the "approve" function of the NewHope token contract with the amount of all NewHopes they got in order to be refund
     * 2) backer call the "refund" function of the Crowdsale contract with the same amount of NewHopes
     * 3) backer call the "withdrawPayments" function of the Crowdsale contract to get a refund in ETH
     */
    function refund(uint _value) minCapNotReached public {
        
        if (_value != backers[msg.sender].coinSent) throw; // compare value from backer balance
        coin.transferFrom(msg.sender, address(this), _value); // get the token back to the crowdsale contract
        if (!coin.burn(_value)) throw ; // token sent for refund are burnt
        uint ETHToSend = backers[msg.sender].weiReceived;
        backers[msg.sender].weiReceived=0;
        if (ETHToSend > 0) {
            asyncSend(msg.sender, ETHToSend); // pull payment to get refund in ETH
        }
    }
}
