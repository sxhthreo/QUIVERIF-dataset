/**
 *Submitted for verification at Etherscan.io on 2020-xx-xx
 *rusal2020001: TCI BIMI account
 *ex_^0.4.8
 *ex_^0.4.25
*/

/**
 *cours ref TESLA USD 854.93 le 20200204 1423 BUCURESTI
*/

pragma solidity 		^0.4.25	;						
									
contract	CDS_TESLA_MMXXIV_20230116				{				
									
	mapping (address => uint256) public balanceOf;								
									
	string	public		name =	"	CDS_TESLA_MMXXIV_20230116		"	;
	string	public		symbol =	"	TESLA_MMXXIV		"	;
	uint8	public		decimals =		18			;
									
	uint256 public totalSupply =		10239418550661078100886177					;	
									
	event Transfer(address indexed from, address indexed to, uint256 value);								
									
	function SimpleERC20Token() public {								
		balanceOf[msg.sender] = totalSupply;							
		emit Transfer(address(0), msg.sender, totalSupply);							
	}								
									
	function transfer(address to, uint256 value) public returns (bool success) {								
		require(balanceOf[msg.sender] >= value);							
									
		balanceOf[msg.sender] -= value;  // deduct from sender's balance							
		balanceOf[to] += value;          // add to recipient's balance							
		emit Transfer(msg.sender, to, value);							
		return true;							
	}								
									
	event Approval(address indexed owner, address indexed spender, uint256 value);								
									
	mapping(address => mapping(address => uint256)) public allowance;								
									
	function approve(address spender, uint256 value)								
		public							
		returns (bool success)							
	{								
		allowance[msg.sender][spender] = value;							
		emit Approval(msg.sender, spender, value);							
		return true;							
	}								
									
	function transferFrom(address from, address to, uint256 value)								
		public							
		returns (bool success)							
	{								
		require(value <= balanceOf[from]);							
		require(value <= allowance[from][msg.sender]);							
									
		balanceOf[from] -= value;							
		balanceOf[to] += value;							
		allowance[from][msg.sender] -= value;							
		emit Transfer(from, to, value);							
		return true;							
	}								
}
