pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;

contract SelectorProvider {
    bytes4 constant getAmountToGive = bytes4(keccak256("getAmountToGive(bytes)"));
    bytes4 constant staticExchangeChecks = bytes4(keccak256("staticExchangeChecks(bytes)"));
    bytes4 constant dynamicExchangeChecks = bytes4(keccak256("dynamicExchangeChecks(bytes,uint256)"));
    bytes4 constant performBuyOrder = bytes4(keccak256("performBuyOrder(bytes,uint256)"));
    bytes4 constant performSellOrder = bytes4(keccak256("performSellOrder(bytes,uint256)"));

    function getSelector(bytes4 genericSelector) public pure returns (bytes4);
}

/// @title KyberSelectorProvider
/// @notice Provides this exchange implementation with correctly formatted function selectors
contract KyberSelectorProvider is SelectorProvider {
    function getSelector(bytes4 genericSelector) public pure returns (bytes4) {
        if (genericSelector == getAmountToGive) {
            return bytes4(keccak256("getAmountToGive((address,address,uint256,uint256,address))"));
        } else if (genericSelector == staticExchangeChecks) {
            return bytes4(keccak256("staticExchangeChecks((address,address,uint256,uint256,address))"));
        } else if (genericSelector == dynamicExchangeChecks) {
            return bytes4(keccak256("dynamicExchangeChecks((address,address,uint256,uint256,address),uint256)"));
        } else if (genericSelector == performBuyOrder) {
            return bytes4(keccak256("performBuyOrder((address,address,uint256,uint256,address),uint256)"));
        } else if (genericSelector == performSellOrder) {
            return bytes4(keccak256("performSellOrder((address,address,uint256,uint256,address),uint256)"));
        } else {
            return bytes4(0x0);
        }
    }
}
