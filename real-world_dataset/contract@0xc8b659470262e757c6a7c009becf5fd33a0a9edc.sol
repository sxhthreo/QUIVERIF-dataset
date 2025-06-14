pragma solidity ^0.4.23;

contract Ownable {
  address owner;
  constructor() public {
  owner = msg.sender;
  }

  modifier onlyOwner {
  require(msg.sender == owner);
  _;
  }
}

  contract Mortal is Ownable {
  function kill() public onlyOwner {
  selfdestruct(owner);
  }
}

  contract FIREDICE is Mortal{
  uint minBet = 1000000000;

  event Roll(bool _won, uint256 _dice1, uint256 _dice2, uint _amount);

  constructor() payable public {}

  function() public { //fallback
    revert();
  }

  function bet(uint _diceOne, uint _diceTwo) payable public {
    require(_diceOne > 0 && _diceOne <= 6);
    require(_diceTwo > 0 && _diceTwo <= 6);
    require(msg.value >= minBet);
    uint256 rollone = block.number % 6 + 1;
    uint256 rolltwo = (block.timestamp + block.difficulty + _diceOne + _diceTwo) % 6 + 1;
    uint256 totalroll = rollone + rolltwo;
    uint256 totaldice = _diceOne + _diceTwo;
    if (totaldice == totalroll) {
      uint amountWon = msg.value;
      if(rollone==rolltwo) amountWon = msg.value*2;
      if(totalroll==2) amountWon = msg.value*8;
      if(totalroll==12) amountWon = msg.value*8;
      if(!msg.sender.send(amountWon)) revert();
      emit Roll(true, rollone, rolltwo, amountWon);
    }
    else {
      emit Roll(false, rollone, rolltwo, 0);
    }
  }

  function checkContractBalance() public view returns(uint) {
    return address(this).balance;
  }

  //Withdrawal function
  function collect(uint _amount) public onlyOwner {
    require(address(this).balance > _amount);
    owner.transfer(_amount);
  }
}
