/**
*	This investment contract accepts investments, which will be sent to the Edgeless ICO contract as soon as it starts buy calling buyTokens().
*   This way investors do not have to buy tokens in time theirselves and still do profit from the power hour offer.
*	Investors may withdraw their funds anytime if they change their mind as long as the tokens have not yet been purchased.
*	Author: Julia Altenried
**/

pragma solidity ^0.4.8;

contract Crowdsale {
	function invest(address receiver) payable{}
}

contract SafeMath {
  //internals
  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
  function assert(bool assertion) internal {
    if (!assertion) throw;
  }
}

contract Investment is SafeMath{
	Crowdsale public ico;
	address[] public investors;
	mapping(address => uint) public balanceOf;


	/** constructs an investment contract for an ICO contract **/
	function Investment(){
		ico = Crowdsale(0xf66ca56fc0cf7b5d9918349150026be80b327892);
	}

	/** make an investment **/
	function() payable{
		if(!isInvestor(msg.sender)){
			investors.push(msg.sender);
		}
		balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], msg.value);
	}

	/** checks if the address already invested **/
	function isInvestor(address who) returns (bool){
		for(uint i = 0; i< investors.length; i++)
			if(investors[i] == who)
				return true;
		return false;
	}

	/** buys tokens in behalf of the investors by calling the ico contract
	*   starting with the investor at index from and ending with investor at index to.
	*   This function will be called as soon as the ICO starts and as often as necessary, until all investments were made. **/
	function buyTokens(uint from, uint to){
		uint amount;
		if(to>investors.length)
			to = investors.length;
		for(uint i = from; i < to; i++){
			if(balanceOf[investors[i]]>0){
				amount = balanceOf[investors[i]];
				delete balanceOf[investors[i]];
				ico.invest.value(amount)(investors[i]);
			}
		}
	}

	/** In case an investor wants to retrieve his or her funds he or she can call this function.
	*   (only possible before tokens are bought) **/
	function withdraw(){
		uint amount = balanceOf[msg.sender];
		balanceOf[msg.sender] = 0;
		if(!msg.sender.send(amount))
			balanceOf[msg.sender] = amount;
	}

	/** returns the number of investors **/
	function getNumInvestors() constant returns(uint){
		return investors.length;
	}

}
