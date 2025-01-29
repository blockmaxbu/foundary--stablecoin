//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";



library OracleLib {
    

    /**
     * Returns the latest answer.
     */
    function getChainlinkDataFeedLatestAnswer(AggregatorV3Interface dataFeed) public view returns (int) {
        // prettier-ignore
       
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