// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./swapContract.sol";
import"./or.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
 contract liquidityPool is TokenSwap , ReentrancyGuard , TokenPriceOracle   {
   using SafeMath for uint256;
     bool internal locked ;
    address private ProjectToken ;
address private ProjectOwner ;
address private swapContract ;
TokenSwap _swap ;
 TokenPriceOracle private tokenPriceOracle;
 address oracleAddress ;
uint private LpPledge;
uint LPReward;
constructor(
    address _token ,
  address _oracleAddress ,
    address _swapContract ,
    uint _LpPledge ,
    uint _LPReward
    ){
      tokenPriceOracle = TokenPriceOracle(_oracleAddress);
      oracleAddress = _oracleAddress;
      swapContract = _swapContract;
     ProjectToken = _token ;
     ProjectOwner = msg.sender ;
      _swap = TokenSwap(_swapContract);
      LpPledge=_LpPledge;
      LPReward = _LPReward;
}
 event CreatePair(address recipient , string  tokenName1 , string  tokenName2 , uint256 amount1 , uint256 amount2 );
  event Withdraw(address recipient , string  tokenName1 , string  tokenName2 , uint256 amount1 , uint256 amount2 );
   event Swap(address recipient , string  tokenName1 , string  tokenName2 , uint256 amount1 , uint256 amount2 );
    event AddToken(address recipient , string  tokenName1 , address  tokenAddress  );

 
  mapping(string => address) private whitelistedTokens;
  mapping (address => uint256) private rewardTime;
  //token address 1
  //token address 1
  //owner address 
  //amount pair tokens
  mapping(address => mapping(address => mapping(address => uint256))) private accountBalances;

  mapping(address => mapping(address => mapping(address => uint256))) private accountBalancesHistory;

  mapping(address => mapping(address => mapping(address => uint256))) private LpPledgeRecieved;
/////// show functions ///////

function TokenList(
    string memory token
    ) public view 
    returns
    (address)
    {
return whitelistedTokens[token];
}

function AccountsBalance(
     string memory token1 ,
     string memory token2
       ) public view 
       returns(uint256){
return accountBalances[whitelistedTokens[token1]][whitelistedTokens[token2]][msg.sender];
}

function getRewardsLP(address user) public view returns(uint256){
  require(rewardTime[user] != 0 , "This address has been rewarded");
  uint256 userRewardTime = block.timestamp.sub(rewardTime[user]) ;
  return  (userRewardTime.div(86400)).mul(LPReward) ;
}
  
  function getTokenPrices(string memory tokenName)public view returns(uint256){
    return tokenPriceOracle.getTokenPrice(tokenName);
  }
function showAmount2(string memory tokenName1 , string memory tokenName2 , uint256 amount1) public view returns(uint256){
 return (tokenPriceOracle.getTokenPrice(tokenName1).mul(amount1).div(tokenPriceOracle.getTokenPrice(tokenName2))) ;
}
//---------------------------------------------------------------------------------------------------------------

  //////change functions //////
function changeProjectToken(address token) public onlyOwner {
ProjectToken = token ;
}
function changeOwner(address owner) public onlyOwner {
ProjectOwner = owner ;
}
function changeSwapContract(address _swapContract) public onlyOwner {
swapContract =_swapContract ;
}

function changeLPledge(uint256 _LpPledge) public onlyOwner {
LpPledge = _LpPledge ;
}
function changeLpReward(uint256 _LPReward) public onlyOwner {
LPReward = _LPReward ;
}

function addToken(
 string memory tokenName,
 address tokenAddress
 )
  public
  onlyOwner
  returns(bool){
    require(msg.sender == ProjectOwner, "only owner can call this function");
    require(whitelistedTokens[tokenName] != tokenAddress , "this token has been added");
    whitelistedTokens[tokenName] = tokenAddress ;
    return true ;
     emit AddToken(msg.sender, tokenName,tokenAddress);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function createPair(
  string memory tokenName1,
   string memory tokenName2,
    uint256 amount1
 )public 
  returns(bool){
require(msg.sender != address(0),"owner cant be contract");
uint256 amount2 = showAmount2(tokenName1,tokenName2,amount1) ;
require(amount2 > 0 ,"amount2 cant be zero");
_swap.swap(whitelistedTokens[tokenName1] , msg.sender,address(this) , amount1);
_swap.swap(whitelistedTokens[tokenName2] , msg.sender,address(this) , amount2);
accountBalances[whitelistedTokens[tokenName1]][whitelistedTokens[tokenName2]][msg.sender]+= (amount1.add(amount2));
accountBalancesHistory[whitelistedTokens[tokenName1]][whitelistedTokens[tokenName2]][msg.sender]+=( amount1.add(amount2));
rewardTime[msg.sender] =block.timestamp ;
LpPledgeRecieved[whitelistedTokens[tokenName1]][whitelistedTokens[tokenName2]][msg.sender] += LpPledge;
IERC20(ProjectToken).transfer(msg.sender , LpPledge);
     emit CreatePair(msg.sender, tokenName1,tokenName2,amount1,amount2);


return true;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
function sendFoundsProxy(string memory tokenName ,address recipient, uint256 amount)public onlyOwner {
  require(IERC20(whitelistedTokens[tokenName]).balanceOf(address(this))>= amount ,"this contract dont has this token");
  IERC20(whitelistedTokens[tokenName]).transfer(recipient,amount);
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function withdrawTokens(
     string memory tokenName1,
   string memory tokenName2,
    uint256 amount1
) public 
nonReentrant 

{
  if(accountBalances[whitelistedTokens[tokenName1]][whitelistedTokens[tokenName2]][msg.sender]<=0){
    accountBalancesHistory[whitelistedTokens[tokenName1]][whitelistedTokens[tokenName2]][msg.sender] = 0;
  }
   uint256 Amount1;
   uint256 Amount2;
require(msg.sender != address(0),"owner cant be contract");
uint256 amount2 = showAmount2(tokenName1,tokenName2,amount1) ;
require(amount2 > 0 ,"amount2 cant be zero");
require(accountBalances[whitelistedTokens[tokenName1]][whitelistedTokens[tokenName2]][msg.sender]>=(amount1.add(amount2)) , "Insufficient funds");
require(
  IERC20(whitelistedTokens[tokenName1]).balanceOf(address(this)) >= amount1 && 
  IERC20(whitelistedTokens[tokenName2]).balanceOf(address(this)) >= amount2,
"the liquidity pool doesn`t have token please be Patience"
);
require(accountBalancesHistory[whitelistedTokens[tokenName1]][whitelistedTokens[tokenName2]][msg.sender] > 0,"you dont have any staked token");
IERC20(whitelistedTokens[tokenName1]).balanceOf(address(this)) < amount1 ? 
  Amount1 = amount1.sub( IERC20(whitelistedTokens[tokenName1]).balanceOf(address(this)) )
  : 
    Amount1 = 0
    ;
IERC20(whitelistedTokens[tokenName2]).balanceOf(address(this)) < amount2 ? 
  Amount2 = amount2.sub( IERC20(whitelistedTokens[tokenName2]).balanceOf(address(this)) )
  : 
    Amount2 = 0;
if(Amount1 > 0){
  _swap.swap(ProjectToken ,msg.sender , address(this),  LpPledgeBack(tokenName1,tokenName2,amount1,amount2));
  accountBalances[whitelistedTokens[tokenName1]][whitelistedTokens[tokenName2]][msg.sender]-=(amount1.add(amount2)) ;
   accountBalancesHistory[whitelistedTokens[tokenName1]][whitelistedTokens[tokenName2]][msg.sender]-=(amount1.add(amount2)) ;
IERC20(whitelistedTokens[tokenName1]).transfer(msg.sender , amount1.sub(Amount1));
IERC20(whitelistedTokens[tokenName2]).transfer(msg.sender , amount2.add(((Amount1.mul(tokenPriceOracle.getTokenPrice(tokenName1))).div (tokenPriceOracle.getTokenPrice(tokenName2)))));

IERC20(ProjectToken).transfer(msg.sender , getRewardsLP(msg.sender));

}else if(Amount2 > 0){
   _swap.swap(ProjectToken ,msg.sender , address(this),  LpPledgeBack(tokenName1,tokenName2,amount1,amount2) );
   accountBalances[whitelistedTokens[tokenName1]][whitelistedTokens[tokenName2]][msg.sender]-=(amount1.add(amount2)) ;
     accountBalancesHistory[whitelistedTokens[tokenName1]][whitelistedTokens[tokenName2]][msg.sender]-=(amount1.add(amount2)) ;
  IERC20(whitelistedTokens[tokenName1]).transfer(msg.sender , amount2.sub(Amount2));
IERC20(whitelistedTokens[tokenName2]).transfer(msg.sender , amount1.add(((Amount2.mul( tokenPriceOracle.getTokenPrice(tokenName2)) ).div(tokenPriceOracle.getTokenPrice(tokenName1)))));

IERC20(ProjectToken).transfer(msg.sender , getRewardsLP(msg.sender));
}else{
  _swap.swap(ProjectToken ,msg.sender , address(this),   LpPledgeBack(tokenName1,tokenName2,amount1,amount2));
  accountBalances[whitelistedTokens[tokenName1]][whitelistedTokens[tokenName2]][msg.sender]-=(amount1.add(amount2)) ;
    accountBalancesHistory[whitelistedTokens[tokenName1]][whitelistedTokens[tokenName2]][msg.sender]-=(amount1.add(amount2)) ;
IERC20(whitelistedTokens[tokenName1]).transfer(msg.sender , amount1);
IERC20(whitelistedTokens[tokenName2]).transfer(msg.sender , amount2);

IERC20(ProjectToken).transfer(msg.sender , getRewardsLP(msg.sender));
}
 emit Withdraw(msg.sender, tokenName1,tokenName2,amount1,amount2);
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////
function swapTokens(
  string memory tokenName1,
   string memory tokenName2,
    uint256 amount1


) public 
nonReentrant 
{
  require(IERC20(whitelistedTokens[tokenName1]).balanceOf(msg.sender)>= amount1 , "user address Insufficent funds");
 require(IERC20(whitelistedTokens[tokenName2]).balanceOf(address(this))>= showAmount2(tokenName1,tokenName2,amount1) , "pool Insufficent funds");
 _swap.swap(whitelistedTokens[tokenName1] ,msg.sender , address(this), amount1);
  IERC20(whitelistedTokens[tokenName2]).transfer(msg.sender, showAmount2(tokenName1,tokenName2,amount1));
   emit Swap(msg.sender, tokenName1,tokenName2,amount1,showAmount2(tokenName1,tokenName2,amount1));

}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
function returnLpPledge(uint256 accountBalance , uint256 amount1 , uint256 amount2)private pure returns(uint256){
  require(accountBalance > 0 ,"accountBalance cant be zero or less");
  require(amount1 > 0 ,"amount1 cant be zero or less");
  require(amount2 > 0 ,"amount2 cant be zero or less");
  return 100-(accountBalance.sub(amount1.add(amount2)).div(accountBalance).mul(100));
}
function LpPledgeBack(string memory tokenName1 , string memory tokenName2 , uint256 amount1 , uint256 amount2)public view returns(uint256){
return(LpPledgeRecieved[whitelistedTokens[tokenName1]][whitelistedTokens[tokenName2]][msg.sender]).div(returnLpPledge(accountBalances[whitelistedTokens[tokenName1]][whitelistedTokens[tokenName2]][msg.sender],amount1,amount2))/LpPledge ;
}

   modifier onlyOwner() {
        require(msg.sender == ProjectOwner, "Only the owner can access this function");
        _;
    }

 }