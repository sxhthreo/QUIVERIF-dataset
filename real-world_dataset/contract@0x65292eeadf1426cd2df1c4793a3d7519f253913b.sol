pragma solidity ^0.4.16;

/*
    Overflow protected math functions
*/
contract SafeMath {
    /**
        constructor
    */
    function SafeMath() {
    }

    /**
        @dev returns the sum of _x and _y, asserts if the calculation overflows

        @param _x   value 1
        @param _y   value 2

        @return sum
    */
    function safeAdd(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

    /**
        @dev returns the difference of _x minus _y, asserts if the subtraction results in a negative number

        @param _x   minuend
        @param _y   subtrahend

        @return difference
    */
    function safeSub(uint256 _x, uint256 _y) internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    /**
        @dev returns the product of multiplying _x by _y, asserts if the calculation overflows

        @param _x   factor 1
        @param _y   factor 2

        @return product
    */
    function safeMul(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    // these functions aren't abstract since the compiler emits automatically generated getter functions as external
    function name() public constant returns (string name) { name; }
    function symbol() public constant returns (string symbol) { symbol; }
    function decimals() public constant returns (uint8 decimals) { decimals; }
    function totalSupply() public constant returns (uint256 totalSupply) { totalSupply; }
    function balanceOf(address _owner) public constant returns (uint256 balance) { _owner; balance; }
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) { _owner; _spender; remaining; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

/**
    COSS Token implementation
*/
contract COSSToken is IERC20Token, SafeMath {
    string public standard = 'COSS';
    string public name = 'COSS';
    string public symbol = 'COSS';
    uint8 public decimals = 18;
    uint256 public totalSupply = 54359820;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping (address => string) public revenueShareIdentifierList;
    mapping (address => string) public revenueShareCurrency;
    mapping (address => uint256) public revenueShareDistribution;

    uint256 public decimalMultiplier = 1000000000000000000;
    address public revenueShareOwnerAddress;
    address public icoWalletAddress = 0x0d6b5a54f940bf3d52e438cab785981aaefdf40c;
    address public futureFundingWalletAddress = 0x1e1f9b4dae157282b6be74d0e9d48cd8298ed1a8;
    address public charityWalletAddress = 0x7dbb1f2114d1bedca41f32bb43df938bcfb13e5c;
    address public capWalletAddress = 0x49a72a02c7f1e36523b74259178eadd5c3c27173;
    address public shareholdersWalletAddress = 0xda3705a572ceb85e05b29a0dc89082f1d8ab717d;
    address public investorWalletAddress = 0xa08e7f6028e7d2d83a156d7da5db6ce0615493b9;

    /**
        @dev constructor
    */
    function COSSToken() {
        revenueShareOwnerAddress = msg.sender;
        balanceOf[icoWalletAddress] = safeMul(80000000,decimalMultiplier);
        balanceOf[futureFundingWalletAddress] = safeMul(50000000,decimalMultiplier);
        balanceOf[charityWalletAddress] = safeMul(10000000,decimalMultiplier);
        balanceOf[capWalletAddress] = safeMul(20000000,decimalMultiplier);
        balanceOf[shareholdersWalletAddress] = safeMul(30000000,decimalMultiplier);
        balanceOf[investorWalletAddress] = safeMul(10000000,decimalMultiplier);
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    function activateRevenueShareIdentifier(string _revenueShareIdentifier) {
        revenueShareIdentifierList[msg.sender] = _revenueShareIdentifier;
    }

    function addRevenueShareCurrency(address _currencyAddress,string _currencyName) {
        if (msg.sender == revenueShareOwnerAddress) {
            revenueShareCurrency[_currencyAddress] = _currencyName;
            revenueShareDistribution[_currencyAddress] = 0;
        }
    }

    function saveRevenueShareDistribution(address _currencyAddress, uint256 _value) {
        if (msg.sender == revenueShareOwnerAddress) {
            revenueShareDistribution[_currencyAddress] = safeAdd(revenueShareDistribution[_currencyAddress], _value);
        }
    }

    /**
        @dev send tokens
        throws on any error rather then return a false flag to minimize user errors

        @param _to      target address
        @param _value   transfer amount

        @return true if the transfer was successful, false if it wasn't
    */
    function transfer(address _to, uint256 _value)
        public
        validAddress(_to)
        returns (bool success)
    {
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
        @dev an account/contract attempts to get the coins
        throws on any error rather then return a false flag to minimize user errors

        @param _from    source address
        @param _to      target address
        @param _value   transfer amount

        @return true if the transfer was successful, false if it wasn't
    */
    function transferFrom(address _from, address _to, uint256 _value)
        public
        validAddress(_from)
        validAddress(_to)
        returns (bool success)
    {
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
        @dev allow another account/contract to spend some tokens on your behalf
        throws on any error rather then return a false flag to minimize user errors

        also, to minimize the risk of the approve/transferFrom attack vector
        (see https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/), approve has to be called twice
        in 2 separate transactions - once to change the allowance to 0 and secondly to change it to the new allowance value

        @param _spender approved address
        @param _value   allowance amount

        @return true if the approval was successful, false if it wasn't
    */
    function approve(address _spender, uint256 _value)
        public
        validAddress(_spender)
        returns (bool success)
    {
        // if the allowance isn't 0, it can only be updated to 0 to prevent an allowance change immediately after withdrawal
        require(_value == 0 || allowance[msg.sender][_spender] == 0);

        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}
