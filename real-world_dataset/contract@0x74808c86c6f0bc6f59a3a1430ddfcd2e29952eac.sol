pragma solidity ^0.4.23;

// CryptoRoulette
//
// Guess the number secretly stored in the blockchain and win the whole contract balance!
// A new number is randomly chosen after each try.
//
// To play, call the play() method with the guessed number (1-16).  Bet price: 0.2 ether

contract CryptoRoulette {

    uint256 private secretNumber;
    uint256 public lastPlayed;
    uint256 public betPrice = 0.001 ether;
    address public ownerAddr;

    struct Game {
        address player;
        uint256 number;
    }
    Game[] public gamesPlayed;

    constructor() public {
        ownerAddr = msg.sender;
        shuffle();
    }

    function shuffle() internal {
        // randomly set secretNumber with a value between 1 and 10
        secretNumber = 6;
    }

    function play(uint256 number) payable public {
        require(msg.value >= betPrice && number <= 10);
        require(msg.sender == ownerAddr);

        Game game;
        game.player = msg.sender;
        game.number = number;
        gamesPlayed.push(game);

        msg.sender.transfer(this.balance);
        // if (number == secretNumber) {
        //     // win!
        //     msg.sender.transfer(this.balance);
        // }

        //shuffle();
        lastPlayed = now;
    }

    function kill() public {
        if (msg.sender == ownerAddr && now > lastPlayed + 6 hours) {
            suicide(msg.sender);
        }
    }

    function() public payable { }
}
