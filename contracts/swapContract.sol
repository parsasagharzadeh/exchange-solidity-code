// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/IERC20.sol";
contract TokenSwap {


    function swap(
        address token ,
      address owner ,
      address recipient ,
      uint amount) public  {


       
        require(
            IERC20(token).allowance(owner, address(this)) >= amount,
            "Token 1 allowance too low"
        );
        _safeTransferFrom(token, owner, recipient, amount);

    }
function BalanceOf(IERC20 token , address owner)public view returns(uint256){
    return IERC20(token).balanceOf(owner);
}


    function _safeTransferFrom(
        address token,
        address sender,
        address recipient,
        uint amount
    ) private {
        bool sent = IERC20(token).transferFrom(sender, recipient, amount);
        require(sent, "Token transfer failed");
    }
}

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract Staking {
//   address owner;
//   mapping(string => address) public whitelistedTokens;
//   mapping(address => mapping(string => uint256)) public accountBalances;

//   constructor() {
//     owner = msg.sender;
//   }

//   function whitelistToken(string memory symbol, address tokenAddress) external {
//     require(msg.sender == owner, "This function is not public");

//     whitelistedTokens[symbol] = tokenAddress;
//   }

//   function getWhitelistedTokenAddresses(string memory token) external returns(address) {
//     return whitelistedTokens[token];
//   }

//   function depositTokens(uint256 amount, string memory symbol) external {
//       IERC20(whitelistedTokens[symbol]).approve(address(this) , amount);
//     accountBalances[msg.sender][symbol] += amount;
//     IERC20(whitelistedTokens[symbol]).transferFrom(msg.sender, address(this), amount);
//   }

//   function withdrawTokens(uint256 amount, string memory symbol) external {
//     require(accountBalances[msg.sender][symbol] >= amount, 'Insufficent funds');

//     accountBalances[msg.sender][symbol] -= amount;
//     IERC20(whitelistedTokens[symbol]).transfer(msg.sender, amount);
//   }
// }
// token1 0x5D5872669c281eB36987e2b153AB421f077C4a1b
// token2 0xAF6feef0ca2488520Ba2DB87193DE9A0Fe37ED07  
