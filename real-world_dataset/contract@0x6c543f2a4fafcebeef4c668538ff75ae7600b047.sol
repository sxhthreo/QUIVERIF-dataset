// Copyright (C) 2017 DappHub, LLC

pragma solidity ^0.4.11;

//import "ds-exec/exec.sol";

contract DSExec {
    function tryExec( address target, bytes calldata, uint value)
    internal
    returns (bool call_ret)
    {
        return target.call.value(value)(calldata);
    }
    function exec( address target, bytes calldata, uint value)
    internal
    {
        if(!tryExec(target, calldata, value)) {
            throw;
        }
    }

    // Convenience aliases
    function exec( address t, bytes c )
    internal
    {
        exec(t, c, 0);
    }
    function exec( address t, uint256 v )
    internal
    {
        bytes memory c; exec(t, c, v);
    }
    function tryExec( address t, bytes c )
    internal
    returns (bool)
    {
        return tryExec(t, c, 0);
    }
    function tryExec( address t, uint256 v )
    internal
    returns (bool)
    {
        bytes memory c; return tryExec(t, c, v);
    }
}

//import "ds-auth/auth.sol";
contract DSAuthority {
    function canCall(
    address src, address dst, bytes4 sig
    ) constant returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    function DSAuth() {
        owner = msg.sender;
        LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
    auth
    {
        owner = owner_;
        LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
    auth
    {
        authority = authority_;
        LogSetAuthority(authority);
    }

    modifier auth {
        assert(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }

    function assert(bool x) internal {
        if (!x) throw;
    }
}

//import "ds-note/note.sol";
contract DSNote {
    event LogNote(
    bytes4   indexed  sig,
    address  indexed  guy,
    bytes32  indexed  foo,
    bytes32  indexed  bar,
    uint        wad,
    bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;

        assembly {
        foo := calldataload(4)
        bar := calldataload(36)
        }

        LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
    }
}


//import "ds-math/math.sol";
contract DSMath {

    /*
    standard uint256 functions
     */

    function add(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x * y;
        assert(x == 0 || z / x == y);
    }

    function div(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x / y;
    }

    function min(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x <= y ? x : y;
    }
    function max(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x >= y ? x : y;
    }

    /*
    uint128 functions (h is for half)
     */


    function hadd(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x + y) >= x);
    }

    function hsub(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x - y) <= x);
    }

    function hmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = x * y;
        assert(x == 0 || z / x == y);
    }

    function hdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = x / y;
    }

    function hmin(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x <= y ? x : y;
    }
    function hmax(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x >= y ? x : y;
    }


    /*
    int256 functions
     */

    function imin(int256 x, int256 y) constant internal returns (int256 z) {
        return x <= y ? x : y;
    }
    function imax(int256 x, int256 y) constant internal returns (int256 z) {
        return x >= y ? x : y;
    }

    /*
    WAD math
     */

    uint128 constant WAD = 10 ** 18;

    function wadd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }

    function wsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }

    function wmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + WAD / 2) / WAD);
    }

    function wdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
    }

    function wmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }
    function wmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }

    /*
    RAY math
     */

    uint128 constant RAY = 10 ** 27;

    function radd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }

    function rsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }

    function rmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + RAY / 2) / RAY);
    }

    function rdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * RAY + y / 2) / y);
    }

    function rpow(uint128 x, uint64 n) constant internal returns (uint128 z) {
        // This famous algorithm is called "exponentiation by squaring"
        // and calculates x^n with x as fixed-point and n as regular unsigned.
        //
        // It's O(log n), instead of O(n) for naive repeated multiplication.
        //
        // These facts are why it works:
        //
        //  If n is even, then x^n = (x^2)^(n/2).
        //  If n is odd,  then x^n = x * x^(n-1),
        //   and applying the equation for even x gives
        //    x^n = x * (x^2)^((n-1) / 2).
        //
        //  Also, EVM division is flooring and
        //    floor[(n-1) / 2] = floor[n / 2].

        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }

    function rmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }
    function rmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }

    function cast(uint256 x) constant internal returns (uint128 z) {
        assert((z = uint128(x)) == x);
    }

}

//import "erc20/erc20.sol";
contract ERC20 {
    function totalSupply() constant returns (uint supply);
    function balanceOf( address who ) constant returns (uint value);
    function allowance( address owner, address spender ) constant returns (uint _allowance);

    function transfer( address to, uint value) returns (bool ok);
    function transferFrom( address from, address to, uint value) returns (bool ok);
    function approve( address spender, uint value ) returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}



//import "ds-token/base.sol";
contract DSTokenBase is ERC20, DSMath {
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _approvals;

    function DSTokenBase(uint256 supply) {
        _balances[msg.sender] = supply;
        _supply = supply;
    }

    function totalSupply() constant returns (uint256) {
        return _supply;
    }
    function balanceOf(address src) constant returns (uint256) {
        return _balances[src];
    }
    function allowance(address src, address guy) constant returns (uint256) {
        return _approvals[src][guy];
    }

    function transfer(address dst, uint wad) returns (bool) {
        assert(_balances[msg.sender] >= wad);

        _balances[msg.sender] = sub(_balances[msg.sender], wad);
        _balances[dst] = add(_balances[dst], wad);

        Transfer(msg.sender, dst, wad);

        return true;
    }

    function transferFrom(address src, address dst, uint wad) returns (bool) {
        assert(_balances[src] >= wad);
        assert(_approvals[src][msg.sender] >= wad);

        _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

        Transfer(src, dst, wad);

        return true;
    }

    function approve(address guy, uint256 wad) returns (bool) {
        _approvals[msg.sender][guy] = wad;

        Approval(msg.sender, guy, wad);

        return true;
    }

}


//import "ds-stop/stop.sol";
contract DSStop is DSAuth, DSNote {

    bool public stopped;

    modifier stoppable {
        assert (!stopped);
        _;
    }
    function stop() auth note {
        stopped = true;
    }
    function start() auth note {
        stopped = false;
    }

}


//import "ds-token/token.sol";
contract DSToken is DSTokenBase(0), DSStop {

    bytes32  public  symbol;
    uint256  public  decimals = 18; // standard token precision. override to customize
    address  public  generator;

    modifier onlyGenerator {
        if(msg.sender!=generator) throw;
        _;
    }

    function DSToken(bytes32 symbol_) {
        symbol = symbol_;
        generator=msg.sender;
    }

    function transfer(address dst, uint wad) stoppable note returns (bool) {
        return super.transfer(dst, wad);
    }
    function transferFrom(
    address src, address dst, uint wad
    ) stoppable note returns (bool) {
        return super.transferFrom(src, dst, wad);
    }
    function approve(address guy, uint wad) stoppable note returns (bool) {
        return super.approve(guy, wad);
    }

    function push(address dst, uint128 wad) returns (bool) {
        return transfer(dst, wad);
    }
    function pull(address src, uint128 wad) returns (bool) {
        return transferFrom(src, msg.sender, wad);
    }

    function mint(uint128 wad) auth stoppable note {
        _balances[msg.sender] = add(_balances[msg.sender], wad);
        _supply = add(_supply, wad);
    }
    function burn(uint128 wad) auth stoppable note {
        _balances[msg.sender] = sub(_balances[msg.sender], wad);
        _supply = sub(_supply, wad);
    }

    // owner can transfer token even stop,
    function generatorTransfer(address dst, uint wad) onlyGenerator note returns (bool) {
        return super.transfer(dst, wad);
    }

    // Optional token name

    bytes32   public  name = "";

    function setName(bytes32 name_) auth {
        name = name_;
    }

}



contract KeyRewardPool is DSStop , DSMath{

    DSToken public key;
    uint public rewardStartTime;

    uint constant public yearlyRewardPercentage = 10; // 10% of remaining tokens
    uint public totalRewardThisYear;
    uint public collectedTokens;
    address public withdrawer;

    event TokensWithdrawn(address indexed _holder, uint _amount);
    event LogSetWithdrawer(address indexed _withdrawer);

    modifier onlyWithdrawer {
        require(msg.sender == withdrawer);
        _;
    }

    function KeyRewardPool(uint _rewardStartTime, address _key, address _withdrawer){
        require(_rewardStartTime != 0 );
        require(_key != address(0) );
        require(_withdrawer != address(0) );

        rewardStartTime = _rewardStartTime;
        key = DSToken(_key);
        withdrawer = _withdrawer;
    }

    // @notice call this method to extract the tokens
    function collectToken() stoppable onlyWithdrawer{
        uint _time = time();
        var _key = key;  // create a in memory variable for storage variable will save gas usage.

        require(_time > rewardStartTime);

        uint balance = _key.balanceOf(address(this));
        uint total = add(collectedTokens, balance);

        uint remainingTokens = total;

        uint yearCount = yearFor(_time);

        for(uint i = 0; i < yearCount; i++) {
            remainingTokens =  div( mul(remainingTokens, 100 - yearlyRewardPercentage), 100);
        }
        //
        totalRewardThisYear =  div( mul(remainingTokens, yearlyRewardPercentage), 100);

        // the reward will be increasing linearly in one year.
        uint canExtractThisYear = div( mul(totalRewardThisYear, (_time - rewardStartTime)  % 365 days), 365 days);

        uint canExtract = canExtractThisYear + total - remainingTokens;

        canExtract = sub(canExtract, collectedTokens);

        if(canExtract > balance) {
            canExtract = balance;
        }

        
        collectedTokens = add(collectedTokens, canExtract);

        assert(_key.transfer(withdrawer, canExtract)); // Fix potential re-entry bug.
        TokensWithdrawn(withdrawer, canExtract);
    }


    function yearFor(uint timestamp) constant returns(uint) {
        return timestamp < rewardStartTime
            ? 0
            : sub(timestamp, rewardStartTime) / (365 days);
    }

    // overrideable for easy testing
    function time() constant returns (uint) {
        return now;
    }

    function setWithdrawer(address _withdrawer) auth {
        withdrawer = _withdrawer;
        LogSetWithdrawer(_withdrawer);
    }

    // @notice This method can be used by the controller to extract mistakenly
    //  sent tokens to this contract.
    // @param dst The address that will be receiving the tokens
    // @param wad The amount of tokens to transfer
    // @param _token The address of the token contract that you want to recover
    function transferTokens(address dst, uint wad, address _token) public auth note {
        require( _token != address(key));
        if (wad > 0) {
            ERC20 token = ERC20(_token);
            token.transfer(dst, wad);
        }
    }

    
}
