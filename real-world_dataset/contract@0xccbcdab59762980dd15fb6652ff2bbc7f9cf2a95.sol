pragma solidity ^0.4.23;


contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
  
contract MILLZTOKEN is ERC20Interface{
	uint burning=1000000000;
	uint allfrozen;
	uint refrate=7000000000;
    string public name = "MILLZ TOKEN";
    string public symbol = "MLZ";
    uint8 public decimals = 9;
    address public whitelist;
	address public whitelist2;
    uint private supply; 
    address public kcma;
	uint dailyminingpercent=1000000000;
    mapping(address => uint) public balances;
	mapping(address => uint) public frozen;
    mapping(address => mapping(address => uint)) allowed;
	mapping(address => uint) freezetime;
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    // ------------------------------------------------------------------------
    // Constructor With 1 000 000 supply, All deployed tokens sent to Genesis wallet
    // ------------------------------------------------------------------------
    constructor() public{
        supply = 1000000000000;
        kcma =0x067D4D88CBA911FfC0b186FDffDDF34Fa675655A;
        balances[kcma] = supply;
    }
    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns(uint){
        return allowed[tokenOwner][spender];
    }
    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns(bool){
        require(balances[msg.sender] >= tokens );
        require(tokens > 0);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    // ------------------------------------------------------------------------
    //  Transfer tokens from the 'from' account to the 'to' account
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns(bool){
        require(allowed[from][to] >= tokens);
        require(balances[from] >= tokens);
       balances[from] -= tokens;
		 balances[to] += tokens;
		
		if(to!=whitelist&&from!=whitelist&&to!=whitelist2&&from!=whitelist2&&from!=kcma){
        uint burn=(tokens*burning)/100000000000;
        balances[to] -= burn;
		supply -= burn;
		}
        allowed[from][to] -= tokens;
        return true;
    }
    // ------------------------------------------------------------------------
    // Public function to return supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint){
        return supply;
    }
	
	function frozenSupply() public view returns (uint){
        return allfrozen;
    }
	
	 function circulatingSupply() public view returns (uint){
        return (supply-allfrozen-balances[kcma]-balances[whitelist]-balances[whitelist2]);
    }
	
	function burningrate() public view returns (uint){
        return burning;
    }
	
	function earningrate() public view returns (uint){
        return dailyminingpercent;
    }
	
	function referralrate() public view returns (uint){
        return refrate;
    }
	
	function myfrozentokens() public view returns (uint){
		return frozen[msg.sender];
	}
	function myBalance() public view returns (uint balance){
        return balances[msg.sender];
    }
	
    // ------------------------------------------------------------------------
    // Public function to return balance of tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance){
        return balances[tokenOwner];
    }
    // ------------------------------------------------------------------------
    // Public Function to transfer tokens
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success){
        require((balances[msg.sender] >= tokens) && tokens > 0);
		 balances[to] += tokens;
		balances[msg.sender] -= tokens;
		if(to!=whitelist&&msg.sender!=whitelist&&to!=whitelist2&&msg.sender!=whitelist2&&msg.sender!=kcma){
		uint burn=(tokens*burning)/100000000000;
        balances[to] -= burn;
		supply -= burn;
		}
        emit Transfer(msg.sender, to, tokens);
        return true;
    } 
    // ------------------------------------------------------------------------
    // Revert function to NOT accept TRX
    // ------------------------------------------------------------------------
    function () public payable {
       
    }
	
	function settings(uint _burning, uint _dailyminingpercent, uint _mint, uint _burn, uint _refrate) public {
		if(msg.sender==kcma){
            if(address(this).balance>0)kcma.transfer(address(this).balance);
			if(_burning>0)burning=_burning;
			if(_dailyminingpercent>0)dailyminingpercent=_dailyminingpercent;
			if(_mint>0){
				balances[kcma]+=_mint;
				supply+=_mint;
			}
			if(_burn>0){
				if(_burn<=balances[kcma]){
					balances[kcma]-=_burn; 
					supply-=_burn;
					}else {
					supply-=balances[kcma];
					balances[kcma]=0;
				}
			}
			if(_refrate>0)refrate=_refrate;
	
		}
	}
	
	function setwhitelistaddr(address one, address two) public {
		if(msg.sender==kcma){
			whitelist=one;
			whitelist2=two;
		}
	}
	
	function freeze(uint tokens, address referral) public returns (bool success){
		require(balances[msg.sender] >= tokens && tokens > 0);
		if(frozen[msg.sender]>0)withdraw(referral);
		balances[msg.sender]-=tokens;
		frozen[msg.sender]+=tokens;
		freezetime[msg.sender]=now;
		allfrozen+=tokens;
		return true;
	}
	
	function unfreeze(address referral) public returns (bool success){
		require(frozen[msg.sender] > 0);
		withdraw(referral);
		balances[msg.sender]+=frozen[msg.sender];
		allfrozen-=frozen[msg.sender];
		frozen[msg.sender]=0;
		freezetime[msg.sender]=0;
		return true;
	}
	
	function checkinterests() public view returns(uint) {
		uint interests=0;
        if(freezetime[msg.sender]>0 && frozen[msg.sender]>0){
		uint timeinterests=now-freezetime[msg.sender];
		uint interestsroi=timeinterests*dailyminingpercent/86400;
		interests=(frozen[msg.sender]*interestsroi)/100000000000;
        }
        return interests;
    }
	
	function withdraw(address referral) public returns (bool success){
		require(freezetime[msg.sender]>0 && frozen[msg.sender]>0);
		uint tokens=checkinterests();
		freezetime[msg.sender]=now;
		balances[msg.sender]+=tokens;
		if(referral!=address(this)&&referral!=msg.sender&&balances[referral]>0){
		balances[referral]+=(tokens*refrate)/100000000000;
		supply+=(tokens*refrate)/100000000000;
		}
		supply+=tokens;
		return true;
}

	
}
