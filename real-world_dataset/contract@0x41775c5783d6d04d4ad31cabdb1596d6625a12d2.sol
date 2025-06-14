pragma solidity ^0.4.18;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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


/**
* @dev Open Zepelin Standard token contract
*/
contract StandardToken {
    using SafeMath for uint256;

    uint256 public totalSupply;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

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
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
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
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
}


contract StupidToken is StandardToken {

    string public constant name = "Stupid token";
    string public constant symbol = "BBZ";
    uint8 public constant decimals = 18;

    address public owner;

    uint256 public constant totalSupply = 2200000000 * (10 ** uint256(decimals));
    uint256 public constant lockedAmount = 440000000 * (10 ** uint256(decimals));

    uint256 public lockReleaseTime;

    bool public allowTrading = false;

    function StupidToken() public {
        owner = msg.sender;
        balances[owner] = totalSupply;
        lockReleaseTime = now + 1 years;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        if (!allowTrading) {
            require(msg.sender == owner);
        }
        
        //Do not allow owner to spend locked amount until lock is released
        if (msg.sender == owner && now < lockReleaseTime) {
            require(balances[msg.sender].sub(_value) >= lockedAmount); 
        }

        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if (!allowTrading) {
            require(_from == owner);
        }

        //Do not allow owner to spend locked amount until lock is released
        if (_from == owner && now < lockReleaseTime) {
            require(balances[_from].sub(_value) >= lockedAmount); 
        }

        return super.transferFrom(_from, _to, _value);
    }

    function setAllowTrading(bool _allowTrading) public {
        require(msg.sender == owner);
        allowTrading = _allowTrading;
    }
}
