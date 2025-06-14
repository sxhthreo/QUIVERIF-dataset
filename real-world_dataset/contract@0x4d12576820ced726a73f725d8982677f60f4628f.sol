pragma solidity 0.4.24;


contract ERC20Interface {
    //function totalSupply() public view returns (uint);
    //function balanceOf(address tokenOwner) public view returns (uint balance);
    //function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    //function transfer(address to, uint tokens) public returns (bool success);
    //function approve(address spender, uint tokens) public returns (bool success);
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    //event Transfer(address indexed from, address indexed to, uint tokens);
    //event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract NvestDex1{
    
    function info ( address _srctoken ,address _desttoken, uint256 src_amt, uint256 dest_amt , address _buyeraddress , address _destsddress) public {
        ERC20Interface baseToken =  ERC20Interface(_srctoken);
           baseToken.transferFrom( _buyeraddress, _destsddress, src_amt);
           
           
           ERC20Interface quoteToken =  ERC20Interface(_desttoken);
           quoteToken.transferFrom(_destsddress,_buyeraddress, dest_amt);
    }
}
