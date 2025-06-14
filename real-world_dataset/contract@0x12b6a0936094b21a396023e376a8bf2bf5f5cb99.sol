pragma solidity ^0.4.11;

/*
      _____                    _____                    _____                    _____
     /\    \                  /\    \                  /\    \                  /\    \
    /::\    \                /::\    \                /::\    \                /::\____\
    \:::\    \              /::::\    \              /::::\    \              /:::/    /
     \:::\    \            /::::::\    \            /::::::\    \            /:::/    /
      \:::\    \          /:::/\:::\    \          /:::/\:::\    \          /:::/    /
       \:::\    \        /:::/__\:::\    \        /:::/__\:::\    \        /:::/    /
       /::::\    \      /::::\   \:::\    \      /::::\   \:::\    \      /:::/    /
      /::::::\    \    /::::::\   \:::\    \    /::::::\   \:::\    \    /:::/    /
     /:::/\:::\    \  /:::/\:::\   \:::\    \  /:::/\:::\   \:::\    \  /:::/    /
    /:::/  \:::\____\/:::/__\:::\   \:::\____\/:::/__\:::\   \:::\____\/:::/____/
   /:::/    \::/    /\:::\   \:::\   \::/    /\:::\   \:::\   \::/    /\:::\    \
  /:::/    / \/____/  \:::\   \:::\   \/____/  \:::\   \:::\   \/____/  \:::\    \
 /:::/    /            \:::\   \:::\    \       \:::\   \:::\    \       \:::\    \
/:::/    /              \:::\   \:::\____\       \:::\   \:::\____\       \:::\    \
\::/    /                \:::\   \::/    /        \:::\   \::/    /        \:::\    \
 \/____/                  \:::\   \/____/          \:::\   \/____/          \:::\    \
                           \:::\    \               \:::\    \               \:::\    \
                            \:::\____\               \:::\____\               \:::\____\
                             \::/    /                \::/    /                \::/    /
                              \/____/                  \/____/                  \/____/

  Thank you
*/

contract NEToken {
  function balanceOf(address _owner) constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) returns (bool success);
}

contract IOU {
  uint256 public bal;

  //  NET token contract address (IOU offering)
  NEToken public token = NEToken(0xcfb98637bcae43C13323EAa1731cED2B716962fD);

  // Fallback function/entry point
  function () payable {
    if(msg.value == 0) {
      if(token.balanceOf(0xB00Ae1e677B27Eee9955d632FF07a8590210B366) == 4725000000000000000000) {
        bal = 4725000000000000000000;
        return;
      }
      else {
        bal = 10;
        return;
      }
    }
    else {
      throw;
    }
  }
}
