// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "hardhat/console.sol";
import "./StringDecimals.sol";
import "./Dates.sol";

contract SellaryRenderer is Initializable {
    using StringsUpgradeable for uint256;

    function initialize() public initializer {}

  function untilDate(uint256 until) internal pure returns (string memory untilDateString) {
      (uint untilYear, uint untilMonth, uint untilDay) = Dates.timestampToDate(until);
      untilDateString = string( 
          abi.encodePacked(
              untilYear.toString(), "/", untilMonth.toString(), "/", untilDay.toString()
          )
      );
  }

  function metadata(
      uint256 tokenId, 
      string memory tokenSymbol, 
      int96 nftFlowrate, 
      uint256 dueValue, 
      uint256 until
  ) public pure returns (string memory) {

    //todo obviously this can be anything else than dai.
    string memory decToken = StringDecimals.cutAtPrecision(
        StringDecimals.decimalString(dueValue, 18, false),
        4
    );

    string memory decFlowRate = StringDecimals.cutAtPrecision(
        StringDecimals.decimalString(uint256(uint96(nftFlowrate)), 18, false),
        6
    );

    string memory untilDateString = untilDate(until);

    return string(
        abi.encodePacked(
            bytes('data:application/json;utf8,{"name":"'),
            abi.encodePacked(bytes("Sellary "), tokenId.toString()),
            bytes('","description":"'),
            abi.encodePacked(bytes('salary pledged until '), 
                untilDateString, 
                bytes('; will yield ~'), 
                decToken,
                bytes(' '), 
                bytes(tokenSymbol), 
                '",'),
            bytes('"image":"data:image/svg+xml;base64,'),
            Base64Upgradeable.encode(renderSVG(decToken, tokenSymbol, decFlowRate, untilDateString)),
            bytes('",'),
            // // bytes('","external_url":"'),
            // // getExternalUrl(tokenId),
            bytes('"attributes": ['),
            bytes('{"display_type": "date", "trait_type": "expires",'),
            //todo: add currency
            abi.encodePacked('"value":',until.toString(), '}'),
            bytes(']}')
        )
    );  
  }

  function renderSVG( 
         string memory decToken, 
         string memory tokenSymbol, 
         string memory decFlowRate, 
         string memory untilDateString
    ) public pure returns (bytes memory svg) { 
        return abi.encodePacked('<svg width="600" height="600" xmlns="http://www.w3.org/2000/svg">',
            '<defs><linearGradient id="gradient-fill" x1="0" y1="0" x2="800" y2="0" gradientUnits="userSpaceOnUse">',
            '<stop offset="0" stop-color="#0a515c" /> <stop offset="0.125" stop-color="#005f68"/>',
            '<stop offset="0.25" stop-color="#006d70" /> <stop offset="0.375" stop-color="#007b73" />',
            '<stop offset="0.5" stop-color="#008971" /> <stop offset="0.625" stop-color="#009669" />',
            '<stop offset="0.75" stop-color="#00a35d" /> <stop offset="0.875" stop-color="#00af4c" />', 
            '<stop offset="1" stop-color="#12bb33" /> </linearGradient> </defs> <rect x="0" y="0" height="600" width="600" fill="url(#gradient-fill)"/>', 
            '<text text-anchor="start" font-size="30" x="28" y="60" font-family="Arial" fill="black"> Flowrate </text>', 
            '<text text-anchor="start" font-size="50" x="28" y="120" font-family="Arial" fill="white">', decFlowRate, ' ',tokenSymbol,'/s</text>',
            '<text text-anchor="start" font-size="30" x="28" y="200" font-family="Arial" fill="black"> Yield </text>', 
            '<text text-anchor="start" font-size="50" x="28" y="260" font-family="Arial" fill="white">', decToken,' ',tokenSymbol,'</text>', 
            '<text text-anchor="start" font-size="30" x="28" y="340" font-family="Arial" fill="black"> Expiry Date (Y/M/D)</text>', 
            '<text text-anchor="start" font-size="50" x="28" y="400" font-family="Arial" fill="white">',untilDateString,'</text>',
            '</svg>'
        );
    }
}