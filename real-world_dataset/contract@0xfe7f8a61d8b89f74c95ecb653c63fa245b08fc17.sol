pragma solidity ^0.4.23;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }

}

contract Token {
 
  function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

  function transfer(address to, uint256 tokens) public returns (bool success);
     
}

contract BancorKillerContract { 

  using SafeMath for uint256;


  address public admin;

  address public traded_token;

  
  uint256 public eth_seed_amount;

  uint256 public traded_token_seed_amount;
  
  uint256 public commission_ratio;

  uint256 eth_balance;

  uint256 traded_token_balance;


  bool public eth_is_seeded;

  bool public traded_token_is_seeded;
  
  bool public trading_deactivated;
  

  modifier onlyAdmin() {
      require(msg.sender == admin);
      _;
  }
  
  modifier tradingActivated() {
      require(trading_deactivated == false);
      _;
  }
  
  constructor(address _traded_token,uint256 _eth_seed_amount, uint256 _traded_token_seed_amount, uint256 _commission_ratio) public {
      
    admin = tx.origin;  
    
    traded_token = _traded_token;
    
    eth_seed_amount = _eth_seed_amount;
    
    traded_token_seed_amount = _traded_token_seed_amount;

    commission_ratio = _commission_ratio;
    
  }
  
  function transferTokensThroughProxyToContract(address _from, address _to, uint256 _amount) private {

    traded_token_balance = traded_token_balance.add(_amount);

    require(Token(traded_token).transferFrom(_from,_to,_amount));
     
  }  

  function transferTokensFromContract(address _to, uint256 _amount) private {

    traded_token_balance = traded_token_balance.sub(_amount);

    require(Token(traded_token).transfer(_to,_amount));
     
  }

  function transferETHToContract() private {

    eth_balance = eth_balance.add(msg.value);
      
  }
  
  function transferETHFromContract(address _to, uint256 _amount) private {

    eth_balance = eth_balance.sub(_amount);
      
    _to.transfer(_amount);
      
  }
  
  function deposit_token(uint256 _amount) private { 

    transferTokensThroughProxyToContract(msg.sender, this, _amount);

  }  

  function deposit_eth() private { 

    transferETHToContract();

  }  
  
  function withdraw_token(uint256 _amount) public onlyAdmin {

    transferTokensFromContract(admin, _amount);
      
  }
  
  function withdraw_eth(uint256 _amount) public onlyAdmin {
      
    transferETHFromContract(admin, _amount);
      
  }

  function set_traded_token_as_seeded() private {
   
    traded_token_is_seeded = true;
 
  }

  function set_eth_as_seeded() private {

    eth_is_seeded = true;

  }

  function seed_traded_token() public onlyAdmin {

    require(!traded_token_is_seeded);
  
    set_traded_token_as_seeded();

    deposit_token(traded_token_seed_amount); 

  }
  
  function seed_eth() public payable onlyAdmin {

    require(!eth_is_seeded);

    require(msg.value == eth_seed_amount);
 
    set_eth_as_seeded();

    deposit_eth(); 

  }

  function seed_additional_token(uint256 _amount) public onlyAdmin {

    require(market_is_open());
    
    deposit_token(_amount);

  }

  function seed_additional_eth() public payable onlyAdmin {
  
    require(market_is_open());
    
    deposit_eth();

  }

  function market_is_open() private view returns(bool) {
  
    return (eth_is_seeded && traded_token_is_seeded);

  }

  function deactivate_trading() public onlyAdmin {
  
    require(!trading_deactivated);
    
    trading_deactivated = true;

  }
  
  function reactivate_trading() public onlyAdmin {
      
    require(trading_deactivated);
    
    trading_deactivated = false;
    
  }

  function get_amount_sell(uint256 _amount) public view returns(uint256) {
 
    uint256 eth_balance_ = eth_balance; 

    uint256 traded_token_balance_ = traded_token_balance;

    uint256 traded_token_balance_plus_amount_ = traded_token_balance_ + _amount;
    
    return (2*eth_balance_*_amount)/(traded_token_balance_ + traded_token_balance_plus_amount_);
    
  }

  function get_amount_buy(uint256 _amount) public view returns(uint256) {
 
    uint256 eth_balance_ = eth_balance; 

    uint256 traded_token_balance_ = traded_token_balance;

    uint256 eth_balance_plus_amount_ = eth_balance_ + _amount;
    
    return (_amount*traded_token_balance_*(eth_balance_plus_amount_ + eth_balance_))/(2*eth_balance_plus_amount_*eth_balance_);
   
  }
  
  function get_amount_minus_commission(uint256 _amount) private view returns(uint256) {
      
    return (_amount*(1 ether - commission_ratio))/(1 ether);  
    
  }

  function complete_sell_exchange(uint256 _amount_give) private {

    uint256 amount_get_ = get_amount_sell(_amount_give);

    uint256 amount_get_minus_commission_ = get_amount_minus_commission(amount_get_);

    uint256 admin_commission = amount_get_ - amount_get_minus_commission_;
    
    transferTokensThroughProxyToContract(msg.sender,this,_amount_give);

    transferETHFromContract(msg.sender,amount_get_minus_commission_);  

    transferETHFromContract(admin, admin_commission);     
    
  }
  
  function complete_buy_exchange() private {

    uint256 amount_give_ = msg.value;

    uint256 amount_get_ = get_amount_buy(amount_give_);

    uint256 amount_get_minus_commission_ = get_amount_minus_commission(amount_get_);

    uint256 admin_commission = amount_get_ - amount_get_minus_commission_;

    transferETHToContract();

    transferTokensFromContract(msg.sender, amount_get_minus_commission_);

    transferTokensFromContract(admin, admin_commission);
    
  }
  
  function sell_tokens(uint256 _amount_give) public tradingActivated {

    require(market_is_open());

    complete_sell_exchange(_amount_give);

  }
  
  function buy_tokens() private tradingActivated {

    require(market_is_open());

    complete_buy_exchange();

  }


  function() public payable {

    buy_tokens();

  }

}

contract BancorKiller { 

  function create_a_new_market(address _traded_token, uint256 _base_token_seed_amount, uint256 _traded_token_seed_amount, uint256 _commission_ratio) public {

    new BancorKillerContract(_traded_token, _base_token_seed_amount, _traded_token_seed_amount, _commission_ratio);

  }
  
  function() public payable {

    revert();

  }

}
