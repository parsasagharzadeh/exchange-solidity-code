// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TokenPriceOracle {
    mapping(string => AggregatorV3Interface) private priceFeeds;

    constructor() {
        // Set the price feed addresses for the tokens
        priceFeeds["ETH"] = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        priceFeeds["LINKETH"] = AggregatorV3Interface(0xb4c4a493AB6356497713A78FFA6c60FB53517c63);
        priceFeeds["USDC"] = AggregatorV3Interface(0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7);
        priceFeeds["DAI"] = AggregatorV3Interface(0x0d79df66BE487753B02D015Fb622DED7f0E9798d);
        priceFeeds["LINK"] = AggregatorV3Interface(0x48731cF7e84dc94C5f84577882c14Be11a5B7456);
        priceFeeds["SNX"] = AggregatorV3Interface(0xdC5f59e61e51b90264b38F0202156F07956E2577);
        priceFeeds["BTC"] = AggregatorV3Interface(0xA39434A63A52E749F02807ae27335515BA4b07F7);
        // Add more tokens and their corresponding price feed addresses here
    }

    function getTokenPrice(string memory symbol) public view returns (uint256) {
        AggregatorV3Interface priceFeed = priceFeeds[symbol];
        require(address(priceFeed) != address(0), "Invalid token symbol");

        (, int256 price, , , ) = priceFeed.latestRoundData();

        // Return the price with 18 decimal places of precision
        return uint256(price) * 1e10;
    }
}
