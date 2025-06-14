pragma solidity ^0.4.25;

/**

 *
 */
contract test {
    //use library for safe math operations
    using SafeMath for uint;

    // array containing information about beneficiaries
    mapping(address => uint) public userDeposit;
    //array containing information about the time of payment
    mapping(address => uint) public userTime;
    //array containing information on interest paid
    mapping(address => uint) public percentWithdrawn;
    //array containing information on interest paid (without tax)
    mapping(address => uint) public percentWithdrawnPure;

    //fund fo transfer percent for advertising
    address private constant ADDRESS_ADV_FUND = 0x51A2BF880F4db7713E95498833308ffE4D61d080;
    //wallet for a charitable foundation
    address private constant ADDRESS_CHARITY_FUND = 0x1e8f7BD53c898625cDc2416ae5f1c446A16dd8D9;
    //time through which you can take dividends
    uint private constant TIME_QUANT = 1 hours;

    //percent for a charitable foundation
    uint private constant PERCENT_CHARITY_FUND = 1000;
    //start percent 0.27% per hour
    uint private constant PERCENT_START = 270;
    uint private constant PERCENT_LOW = 320;
    uint private constant PERCENT_MIDDLE = 380;
    uint private constant PERCENT_HIGH = 400;

    //Adv tax for holders (10% for impatient, 4% for strong holders)
    uint private constant PERCENT_ADV_VERY_HIGH = 10000;
    uint private constant PERCENT_ADV_HIGH = 9000;
    uint private constant PERCENT_ADV_ABOVE_MIDDLE = 8000;
    uint private constant PERCENT_ADV_MIDDLE = 7000;
    uint private constant PERCENT_ADV_BELOW_MIDDLE = 6000;
    uint private constant PERCENT_ADV_LOW = 5000;
    uint private constant PERCENT_ADV_LOWEST = 4000;

    //All percent should be divided by this
    uint private constant PERCENT_DIVIDER = 100000;

    //interest rate increase steps
    uint private constant STEP_LOW = 1000 ether;
    uint private constant STEP_MIDDLE = 2500 ether;
    uint private constant STEP_HIGH = 5000 ether;
    
    uint public countOfInvestors = 0;
    uint public countOfCharity = 0;

    modifier isIssetUser() {
        require(userDeposit[msg.sender] > 0, "Deposit not found");
        _;
    }

    modifier timePayment() {
        require(now >= userTime[msg.sender].add(TIME_QUANT), "Too fast payout request");
        _;
    }

    //return of interest on the deposit
    function collectPercent() isIssetUser timePayment internal {

        //if the user received 200% or more of his contribution, delete the user
        if ((userDeposit[msg.sender].mul(2)) <= percentWithdrawnPure[msg.sender]) {
            _delete(msg.sender); //User has withdrawn more than x2
        } else {
            uint payout = payoutAmount(msg.sender);
            _payout(msg.sender, payout);
        }
    }

    //calculation of the current interest rate on the deposit
    function percentRate() public view returns(uint) {
        //get contract balance
        uint balance = address(this).balance;

        //calculate percent rate
        if (balance < STEP_LOW) {
            return (PERCENT_START);
        }
        if (balance < STEP_MIDDLE) {
            return (PERCENT_LOW);
        }
        if (balance < STEP_HIGH) {
            return (PERCENT_MIDDLE);
        }

        return (PERCENT_HIGH);
    }

    //calculate the amount available for withdrawal on deposit
    function payoutAmount(address addr) public view returns(uint) {
        uint percent = percentRate();
        uint rate = userDeposit[addr].mul(percent).div(PERCENT_DIVIDER);
        uint interestRate = now.sub(userTime[addr]).div(TIME_QUANT);
        uint withdrawalAmount = rate.mul(interestRate);
        return (withdrawalAmount);
    }

    function holderAdvPercent(address addr) public view returns(uint) {
        uint timeHeld = (now - userTime[addr]);
        if(timeHeld < 1 days)
            return PERCENT_ADV_VERY_HIGH;
        if(timeHeld < 3 days)
            return PERCENT_ADV_HIGH;
        if(timeHeld < 1 weeks)
            return PERCENT_ADV_ABOVE_MIDDLE;
        if(timeHeld < 2 weeks)
            return PERCENT_ADV_MIDDLE;
        if(timeHeld < 3 weeks)
            return PERCENT_ADV_BELOW_MIDDLE;
        if(timeHeld < 4 weeks)
            return PERCENT_ADV_LOW;
        return PERCENT_ADV_LOWEST;
    }

    //make a deposit
    function makeDeposit() private {
        if (msg.value > 0) {
            if (userDeposit[msg.sender] == 0) {
                countOfInvestors += 1;
            }
            if (userDeposit[msg.sender] > 0 && now >= userTime[msg.sender].add(TIME_QUANT)) {
                collectPercent();
            }
            userDeposit[msg.sender] += msg.value;
            userTime[msg.sender] = now;
        } else {
            collectPercent();
        }
    }

    //return of deposit balance
    function returnDeposit() isIssetUser private {
        //percentWithdrawn already include all taxes for charity and ads
        //So we need pay taxes only for the rest of deposit
        uint withdrawalAmount = userDeposit[msg.sender]
            .sub(percentWithdrawn[msg.sender]);

        //Pay the rest of deposit and take taxes
        _payout(msg.sender, withdrawalAmount);

        //delete user record
        _delete(msg.sender);
    }

    function() external payable {
        //refund of remaining funds when transferring to a contract 0.00000112 ether
        if (msg.value == 0.00000112 ether) {
            returnDeposit();
        } else {
            makeDeposit();
        }
    }

    //Pays out, takes taxes according to holding time
    function _payout(address addr, uint amount) private {
        //Remember this payout
        percentWithdrawn[addr] += amount;

        //Get current holder adv percent
        uint advPct = holderAdvPercent(addr);
        //Calculate pure payout that user receives
        uint interestPure = amount.mul(PERCENT_DIVIDER - PERCENT_CHARITY_FUND - advPct).div(PERCENT_DIVIDER);
        percentWithdrawnPure[addr] += interestPure;
        userTime[addr] = now;

        //calculate money to charity
        uint charityMoney = amount.mul(PERCENT_CHARITY_FUND).div(PERCENT_DIVIDER);
        countOfCharity += charityMoney;

        //calculate money for advertising
        uint advTax = amount.sub(interestPure).sub(charityMoney);

        //send money
        ADDRESS_ADV_FUND.transfer(advTax);
        ADDRESS_CHARITY_FUND.transfer(charityMoney);
        addr.transfer(interestPure);
    }

    //Clears user from registry
    function _delete(address addr) private {
        userDeposit[addr] = 0;
        userTime[addr] = 0;
        percentWithdrawn[addr] = 0;
        percentWithdrawnPure[addr] = 0;
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}
