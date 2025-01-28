//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { ConfigHelper } from "script/ConfigHelper.s.sol";
import { Engine } from "src/Engine.sol";


contract OracleLib {
    AggregatorV3Interface internal btcDataFeed;
    AggregatorV3Interface internal ethDataFeed;

    /**
     * Network: Sepolia
     * Aggregator: BTC/USD
     * Address: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
     */
    constructor(ConfigHelper.NetConfig memory config) {
        btcDataFeed = AggregatorV3Interface(
            config.BTCUSDFeed
        );
        ethDataFeed = AggregatorV3Interface(
            config.ETHUSDFeed
        );
    }

    /**
     * Returns the latest answer.
     */
    function getChainlinkDataFeedLatestAnswer(Engine.TypeOfCollateral typeOfCollateral) public view returns (int) {
        // prettier-ignore
        AggregatorV3Interface dataFeed;
        if(typeOfCollateral == Engine.TypeOfCollateral.wBTC) {
            dataFeed = btcDataFeed;
        } else {
            dataFeed = ethDataFeed;
        }
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();

        return answer;
    }
}