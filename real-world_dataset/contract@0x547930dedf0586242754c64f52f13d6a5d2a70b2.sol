pragma solidity 0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a / b;
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

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC20Interface {
    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) returns (bool success);
    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) constant returns (uint256 balance);
}

contract MpctLockupCommunity is Ownable {
    using SafeMath for uint256;
    ERC20Interface token;

    address public constant tokenAddress = 0x2e919B36e8865F7B0e76691150d0Bbc93846798C;
    address public wallet = 0x9dD74C954C73F73226526A0532bB02314554041F;
    uint256 public lockupDate = 1530057600; 
    uint256 public initLockupAmt = 700000000e18;

    function MpctLockupCommunity () public {
        token = ERC20Interface(tokenAddress);
    }

    function setLockupAmt(uint256 _amt) public onlyOwner {
        initLockupAmt = _amt;
    }

    function setLockupDate(uint _date) public onlyOwner {
        lockupDate = _date;
    }

    function setWallet(address _dest) public onlyOwner {
        wallet = _dest;
    }

    function withdraw() public {
        uint256 currBalance = token.balanceOf(this);
        uint256 currLocking = getCurrLocking();

        require(currBalance > currLocking);

        token.transfer(wallet, currBalance-currLocking);
    }

    function getCurrLocking()
        public
		view
        returns (uint256)
	{
        uint256 diff = (now - lockupDate) / 31104000; // year diff
        uint256 partition = 10;

        if (diff >= partition) 
            return 0;
        else
            return initLockupAmt.mul(partition-diff).div(partition);
    }
}
