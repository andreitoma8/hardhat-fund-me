// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error FundMe__NotOwner();

/** @title A  contract for crownd funding
 *   @author andreitoma8
 *   @notice This contract is to demo a simple crowd funding contract
 *   @dev This implements price feeds as our library
 */
contract FundMe {
    using PriceConverter for uint256;

    address[] public s_funders;

    AggregatorV3Interface public immutable i_priceFeed;

    mapping(address => uint256) public s_addressToAmountFunded;

    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 50 * 10**18;

    constructor(AggregatorV3Interface _priceFeed) {
        i_owner = msg.sender;
        i_priceFeed = _priceFeed;
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    /**  @notice This function funds this contract
     *   @dev Yep
     */
    function fund() public payable {
        require(
            msg.value.getConversionRate(i_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return i_priceFeed.version();
    }

    function withdraw() public payable onlyOwner {
        address[] memory m_funders = s_funders;
        uint256 fundersLength = m_funders.length;
        for (uint256 funderIndex; funderIndex < fundersLength; ++funderIndex) {
            s_addressToAmountFunded[m_funders[funderIndex]] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }
}
