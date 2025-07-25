pragma solidity 0.4.25;
// ----------------------------------------------------------------------------
// 'PAYTOKEN' contract with following features
//      => In-built ICO functionality - Infinite duration
//      => ERC20 Compliance
//      => Higher control of ICO by admin/owner
//      => selfdestruct functionality
//      => SafeMath implementation 
//
// Deployed to : 0x6A51a1415ED5e6156D4A6046C890e2f2a4Cfd0B9
// Symbol      : PAYTK
// Name        : PAYTOKEN
// Total supply: 1,000,000,000  (1 Billion)
// Decimals    : 18
//
// Copyright (c) 2018 Payou Ltd, Malta (https://paytoken.co)
// ----------------------------------------------------------------------------
   
    /**
     * @title SafeMath
     * @dev Math operations with safety checks that throw on error
     */
    library SafeMath {
      function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
          return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
      }
    
      function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
      }
    
      function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
      }
    
      function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
      }
    }
    
    contract owned {
        address public owner;
    	using SafeMath for uint256;
    	
         constructor () public {
            owner = msg.sender;
        }
    
        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }
    
        function transferOwnership(address newOwner) onlyOwner public {
            owner = newOwner;
        }
    }
    
    interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }
    
    contract TokenERC20 {
        // Public variables of the token
        using SafeMath for uint256;
    	string public name;
        string public symbol;
        uint8 public decimals = 18; // 18 decimals is the strongly suggested default, avoid changing it
        uint256 public totalSupply;
        bool public safeguard = false;  //putting safeguard on will halt all non-owner functions
    
        // This creates an array with all balances
        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;
    
        // This generates a public event on the blockchain that will notify clients
        event Transfer(address indexed from, address indexed to, uint256 value);
    
        // This notifies clients about the amount burnt
        event Burn(address indexed from, uint256 value);
    
        /**
         * Constrctor function
         *
         * Initializes contract with initial supply tokens to the creator of the contract
         */
        constructor (
            uint256 initialSupply,
            string tokenName,
            string tokenSymbol
        ) public {
            totalSupply = initialSupply.mul(1 ether);           // Update total supply with the decimal amount
            balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
            name = tokenName;                                   // Set the name for display purposes
            symbol = tokenSymbol;                               // Set the symbol for display purposes
        }
    
        /**
         * Internal transfer, only can be called by this contract
         */
        function _transfer(address _from, address _to, uint _value) internal {
            require(!safeguard);
            // Prevent transfer to 0x0 address. Use burn() instead
            require(_to != 0x0);
            // Check if the sender has enough
            require(balanceOf[_from] >= _value);
            // Check for overflows
            require(balanceOf[_to].add(_value) > balanceOf[_to]);
            // Save this for an assertion in the future
            uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
            // Subtract from the sender
            balanceOf[_from] = balanceOf[_from].sub(_value);
            // Add the same to the recipient
            balanceOf[_to] = balanceOf[_to].add(_value);
            emit Transfer(_from, _to, _value);
            // Asserts are used to use static analysis to find bugs in your code. They should never fail
            assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
        }
    
        /**
         * Transfer tokens
         *
         * Send `_value` tokens to `_to` from your account
         *
         * @param _to The address of the recipient
         * @param _value the amount to send
         */
        function transfer(address _to, uint256 _value) public {
            _transfer(msg.sender, _to, _value);
        }
    
        /**
         * Transfer tokens from other address
         *
         * Send `_value` tokens to `_to` in behalf of `_from`
         *
         * @param _from The address of the sender
         * @param _to The address of the recipient
         * @param _value the amount to send
         */
        function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
            require(!safeguard);
            require(_value <= allowance[_from][msg.sender]);     // Check allowance
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
            _transfer(_from, _to, _value);
            return true;
        }
    
        /**
         * Set allowance for other address
         *
         * Allows `_spender` to spend no more than `_value` tokens in your behalf
         *
         * @param _spender The address authorized to spend
         * @param _value the max amount they can spend
         */
        function approve(address _spender, uint256 _value) public
            returns (bool success) {
            require(!safeguard);
            allowance[msg.sender][_spender] = _value;
            return true;
        }
    
        /**
         * Set allowance for other address and notify
         *
         * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
         *
         * @param _spender The address authorized to spend
         * @param _value the max amount they can spend
         * @param _extraData some extra information to send to the approved contract
         */
        function approveAndCall(address _spender, uint256 _value, bytes _extraData)
            public
            returns (bool success) {
            require(!safeguard);
            tokenRecipient spender = tokenRecipient(_spender);
            if (approve(_spender, _value)) {
                spender.receiveApproval(msg.sender, _value, this, _extraData);
                return true;
            }
        }
    
        /**
         * Destroy tokens
         *
         * Remove `_value` tokens from the system irreversibly
         *
         * @param _value the amount of money to burn
         */
        function burn(uint256 _value) public returns (bool success) {
            require(!safeguard);
            require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);            // Subtract from the sender
            totalSupply = totalSupply.sub(_value);                      // Updates totalSupply
           	emit Burn(msg.sender, _value);
            return true;
        }
    
        /**
         * Destroy tokens from other account
         *
         * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
         *
         * @param _from the address of the sender
         * @param _value the amount of money to burn
         */
        function burnFrom(address _from, uint256 _value) public returns (bool success) {
            require(!safeguard);
            require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
            require(_value <= allowance[_from][msg.sender]);    // Check allowance
            balanceOf[_from] = balanceOf[_from].sub(_value);                         // Subtract from the targeted balance
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);             // Subtract from the sender's allowance
            totalSupply = totalSupply.sub(_value);                              // Update totalSupply
          	emit  Burn(_from, _value);
            return true;
        }
        
    }
    
    //*******************************************************//
    //-------------  ADVANCED TOKEN STARTS HERE -------------//
    //*******************************************************//
    
    contract PAYTOKEN is owned, TokenERC20 {
    	using SafeMath for uint256;
    	
    	/**********************************/
        /* Code for the ERC20 PAYTOKEN */
        /**********************************/
    
    	// Public variables of the token
    	string private tokenName = "PAYTOKEN";
        string private tokenSymbol = "PAYTK";
        uint256 private initialSupply = 1000000000; 	// Initial supply of the tokens   

		// Records for the fronzen accounts 
        mapping (address => bool) public frozenAccount;
        
        /* This generates a public event on the blockchain that will notify clients */
        event FrozenFunds(address target, bool frozen);
    
        /* Initializes contract with initial supply tokens to the creator of the contract */
        constructor () TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

        /* Internal transfer, only can be called by this contract */
        function _transfer(address _from, address _to, uint _value) internal {
            require(!safeguard);
			require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
			require (balanceOf[_from] >= _value);               // Check if the sender has enough
			require (balanceOf[_to].add(_value) >= balanceOf[_to]); // Check for overflows
			require(!frozenAccount[_from]);                     // Check if sender is frozen
			require(!frozenAccount[_to]);                       // Check if recipient is frozen
			balanceOf[_from] = balanceOf[_from].sub(_value);                         // Subtract from the sender
			balanceOf[_to] = balanceOf[_to].add(_value);                           // Add the same to the recipient
			emit Transfer(_from, _to, _value);
        }
        
		/// @notice Create `mintedAmount` tokens and send it to `target`
		/// @param target Address to receive the tokens
		/// @param mintedAmount the amount of tokens it will receive
		function mintToken(address target, uint256 mintedAmount) onlyOwner public {
			balanceOf[target] = balanceOf[target].add(mintedAmount);
			totalSupply = totalSupply.add(mintedAmount);
		 	emit Transfer(0, this, mintedAmount);
		 	emit Transfer(this, target, mintedAmount);
		}

		/// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
		/// @param target Address to be frozen
		/// @param freeze either to freeze it or not
		function freezeAccount(address target, bool freeze) onlyOwner public {
				frozenAccount[target] = freeze;
			emit  FrozenFunds(target, freeze);
		}

		/**************************/
		/* Code for the Crowdsale */
		/**************************/

		//public variables for the Crowdsale
		uint256 public icoStartDate = 999 ;  // Any past timestamp
		uint256 public icoEndDate = 9999999999999999 ;    // Infinite end date.
		uint256 public exchangeRate = 10000;         // 1 ETH = 10000 Tokens 
		uint256 public tokensSold = 0;              // how many tokens sold through crowdsale

		//@dev fallback function, only accepts ether if ICO is running or Reject
		function () payable public {
			require(icoEndDate > now);
			require(icoStartDate < now);
            require(!safeguard);
			uint ethervalueWEI=msg.value;
			// calculate token amount to be sent
			uint256 token = ethervalueWEI.mul(exchangeRate); //weiamount * price
			tokensSold = tokensSold.add(token);
			_transfer(this, msg.sender, token);              // makes the transfers
			forwardEherToOwner();
		}

		//Automatocally forwards ether from smart contract to owner address
		function forwardEherToOwner() internal {
			owner.transfer(msg.value); 
		}

		//function to start an ICO.
		//It requires: timestamp of start and end date, exchange rate (1 ETH = ? Tokens), and token amounts to allocate for the ICO
		//It will transfer allocated amount to the smart contract from Owner
		function startIco(uint256 start,uint256 end, uint256 exchangeRateNew, uint256 TokensAllocationForICO) onlyOwner public {
			require(start < end);
			uint256 tokenAmount = TokensAllocationForICO.mul(1 ether);
			require(balanceOf[msg.sender] > tokenAmount);
			icoStartDate=start;
			icoEndDate=end;
			exchangeRate = exchangeRateNew;
			approve(this,tokenAmount);
			transfer(this,tokenAmount);
        }
        
        //Stops an ICO.
        //It will also transfer remaining tokens to owner
		function stopICO() onlyOwner public{
            icoEndDate = 0;
            uint256 tokenAmount=balanceOf[this];
            _transfer(this, msg.sender, tokenAmount);
        }
        
        //function to check wheter ICO is running or not.
        function isICORunning() public view returns(bool){
            if(icoEndDate > now && icoStartDate < now){
                return true;                
            }else{
                return false;
            }
        }
        
        //Function to set ICO Exchange rate. 
    	function setICOExchangeRate(uint256 newExchangeRate) onlyOwner public {
			exchangeRate=newExchangeRate;
        }
        
        //Just in case, owner wants to transfer Tokens from contract to owner address
        function manualWithdrawToken(uint256 _amount) onlyOwner public {
      		uint256 tokenAmount = _amount.mul(1 ether);
            _transfer(this, msg.sender, tokenAmount);
        }
          
        //Just in case, owner wants to transfer Ether from contract to owner address
        function manualWithdrawEther()onlyOwner public{
			uint256 amount=address(this).balance;
			owner.transfer(amount);
		}
		
		//selfdestruct function. just in case owner decided to destruct this contract.
		function destructContract()onlyOwner public{
			selfdestruct(owner);
		}
		
		/**
         * Change safeguard status on or off
         *
         * When safeguard is true, then all the non-owner functions will stop working.
         */
        function changeSafeguardStatus() onlyOwner public{
            if (safeguard == false){
			    safeguard = true;
            }
            else{
                safeguard = false;    
            }
		}
}
