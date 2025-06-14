pragma solidity ^0.4.19;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract StinkyLinky {
  //ETHEREUM SOLIDITY VERSION 4.19
  //CRYPTOCOLLECTED LTD
  
  //INITIALIZATION VALUES
  address ceoAddress = 0xC0c8Dc6C1485060a72FCb629560371fE09666500;
  struct Sergey {
    address currentStinkyLinky;
    uint256 currentValue;
   
  }
  Sergey[32] data;
  
  //No-Arg Constructor initializes basic low-end values.
  function StinkyLinky() public {
    for (uint i = 0; i < 32; i++) {
     
      data[i].currentValue = 15000000000000000;
      data[i].currentStinkyLinky = msg.sender;
    }
  }

  // Function to pay the previous owner.
  //     Neccesary for contract integrity
  function payPreviousOwner(address previousHeroOwner, uint256 currentValue) private {
    previousHeroOwner.transfer(currentValue);
  }
  //Sister function to payPreviousOwner():
  //   Addresses wallet-to-wallet payment totality
  function transactionFee(address, uint256 currentValue) private {
    ceoAddress.transfer(currentValue);
  }
  // Function that handles logic for setting prices and assigning collectibles to addresses.
  // Doubles instance value  on purchase.
  // Verify  correct amount of ethereum has been received
  function purchaseCollectible(uint uniqueCollectibleID) public payable returns (uint, uint) {
    require(uniqueCollectibleID >= 0 && uniqueCollectibleID <= 31);
    // Set initial price to .02 (ETH)
    if ( data[uniqueCollectibleID].currentValue == 15000000000000000 ) {
      data[uniqueCollectibleID].currentValue = 30000000000000000;
    } else {
      // Double price
      data[uniqueCollectibleID].currentValue = data[uniqueCollectibleID].currentValue * 2;
    }
    
    require(msg.value >= data[uniqueCollectibleID].currentValue * uint256(1));
    // Call payPreviousOwner() after purchase.
    payPreviousOwner(data[uniqueCollectibleID].currentStinkyLinky,  (data[uniqueCollectibleID].currentValue / 10) * (9)); 
    transactionFee(ceoAddress, (data[uniqueCollectibleID].currentValue / 10) * (1));
    // Assign owner.
    data[uniqueCollectibleID].currentStinkyLinky = msg.sender;
    // Return values for web3js display.
    return (uniqueCollectibleID, data[uniqueCollectibleID].currentValue);

  }
  // Gets the current list of heroes, their owners, and prices. 
  function getCurrentStinkyLinkys() external view returns (address[], uint256[]) {
    address[] memory currentStinkyLinkys = new address[](32);
    uint256[] memory currentValues =  new uint256[](32);
    for (uint i=0; i<32; i++) {
      currentStinkyLinkys[i] = (data[i].currentStinkyLinky);
      currentValues[i] = (data[i].currentValue);
    }
    return (currentStinkyLinkys,currentValues);
  }
  
}
