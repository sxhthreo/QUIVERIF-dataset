pragma solidity ^0.4.9;
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

}
 contract ContractReceiver {

    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }


    function tokenFallback(address _from, uint _value, bytes _data) public pure {
      TKN memory tkn;
      tkn.sender = _from;
      tkn.value = _value;
      tkn.data = _data;
      uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
      tkn.sig = bytes4(u);

      /* tkn variable is analogue of msg variable of Ether transaction
      *  tkn.sender is person who initiated this token transaction   (analogue of msg.sender)
      *  tkn.value the number of tokens that were sent   (analogue of msg.value)
      *  tkn.data is data of token transaction   (analogue of msg.data)
      *  tkn.sig is 4 bytes signature of function
      *  if data of token transaction is a function execution
      */
    }
}
contract ERC223 {
  uint public totalSupply;
  function getbalance(address who) public view returns (uint);
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function decimals() public view returns (uint8 _decimals);
  function totalSupply() public view returns (uint256 _supply);
  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);

  event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

contract SafeMath {
	 uint256 constant public MAX_UINT256 =
	 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

	 function safeAdd(uint256 x, uint256 y) pure internal returns (uint256 z) {
			 if (x > MAX_UINT256 - y) revert();
			 return x + y;
	 }

	 function safeSub(uint256 x, uint256 y) pure internal returns (uint256 z) {
			 if (x < y) revert();
			 return x - y;
	 }

	 function safeMul(uint256 x, uint256 y) pure internal returns (uint256 z) {
			 if (y == 0) return 0;
			 if (x > MAX_UINT256 / y) revert();
			 return x * y;
	 }
}

contract ERC223Token is ERC223, SafeMath , Ownable{

 mapping(address => uint) balances;
 mapping(address => bool) whitelist;

 string public name;
 string public symbol;
 uint8 public decimals = 8;
 uint256 public totalSupply;

 function ERC223Token() public {
        totalSupply = 1200000000 * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balances[msg.sender] = 120000000000000000;                // Give the creator all initial tokens
        name = "Ethereum Lendo Token";                                   // Set the name for display purposes
        symbol = "ELT";                               // Set the symbol for display purposes
        whitelist[owner] = true;
    }

 // Function to access name of token .
 function name() public view returns (string _name) {
		 return name;
 }
 // Function to access symbol of token .
 function symbol() public view returns (string _symbol) {
		 return symbol;
 }
 // Function to access decimals of token .
 function decimals() public view returns (uint8 _decimals) {
		 return decimals;
 }
 // Function to access total supply of tokens .
 function totalSupply() public view returns (uint256 _totalSupply) {
		 return totalSupply;
 }


 // Function that is called when a user or another contract wants to transfer funds .
 function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {

	 if(isContract(_to)) {
			 if (getbalance(msg.sender) < _value) revert();
			 balances[msg.sender] = safeSub(getbalance(msg.sender), _value);
			 balances[_to] = safeAdd(getbalance(_to), _value);
			 assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
			 Transfer(msg.sender, _to, _value, _data);
			 return true;
	 }
	 else {
			 return transferToAddress(_to, _value, _data);
	 }
}


 // Function that is called when a user or another contract wants to transfer funds .
 function transfer(address _to, uint _value, bytes _data) public returns (bool success) {

	 if(isContract(_to)) {
			 return transferToContract(_to, _value, _data);
	 }
	 else {
			 return transferToAddress(_to, _value, _data);
	 }
}

 // Standard function transfer similar to ERC20 transfer with no _data .
 // Added due to backwards compatibility reasons .
 function transfer(address _to, uint _value) public returns (bool success) {

	 //standard function transfer similar to ERC20 transfer with no _data
	 //added due to backwards compatibility reasons
	 bytes memory empty;
	 if(isContract(_to))
	 {
			 return transferToContract(_to, _value, empty);
	 }
	 else
	 {
			 return transferToAddress(_to, _value, empty);
	 }
}

 //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
 function isContract(address _addr) private view returns (bool is_contract) {
		 uint length;
		 assembly {
					 //retrieve the size of the code on target address, this needs assembly
					 length := extcodesize(_addr)
		 }
		 return (length>0);
	 }

 //function that is called when transaction target is an address
 function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
	 if (getbalance(msg.sender) < _value) revert();
	 balances[msg.sender] = safeSub(getbalance(msg.sender), _value);
	 balances[_to] = safeAdd(getbalance(_to), _value);
	 Transfer(msg.sender, _to, _value, _data);
	 return true;
 }

 //function that is called when transaction target is a contract
 function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
	 if (getbalance(msg.sender) < _value) revert();
	 balances[msg.sender] = safeSub(getbalance(msg.sender), _value);
	 balances[_to] = safeAdd(getbalance(_to), _value);
	 ContractReceiver receiver = ContractReceiver(_to);
	 receiver.tokenFallback(msg.sender, _value, _data);
	 Transfer(msg.sender, _to, _value, _data);
	 return true;
}
 function getbalance(address _ethaddress) public view returns (uint balance) {
	 return balances[_ethaddress];
 }
 function isWhiteList(address _ethaddress) public view returns (bool iswhitelist) {
	 return whitelist[_ethaddress];
 }
}
