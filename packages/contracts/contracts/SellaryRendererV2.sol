// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./StringDecimals.sol";
import "./Dates.sol";

contract SellaryRendererV2 is Initializable {
    using StringsUpgradeable for uint256;

    struct RenderVars {
        string decFlowRate;
        string tokenSymbol;
        string decYield;
        string untilDateString;
    }

    function initialize() public initializer {}

    function untilDate(uint256 until)
        internal
        pure
        returns (string memory untilDateString)
    {
        (uint256 untilYear, uint256 untilMonth, uint256 untilDay) = Dates
            .timestampToDate(until);
        untilDateString = string(
            abi.encodePacked(
                untilYear.toString(),
                "/",
                untilMonth.toString(),
                "/",
                untilDay.toString()
            )
        );
    }

    function metadata(
        uint256 tokenId,
        string memory tokenSymbol_,
        int96 nftFlowrate,
        uint256 dueValue,
        uint256 until
    ) public pure returns (string memory) {
        RenderVars memory renderVars = RenderVars({
            decFlowRate: StringDecimals.cutAtPrecision(
                StringDecimals.decimalString(
                    uint256(uint96(nftFlowrate)),
                    18,
                    false
                ),
                6
            ),
            tokenSymbol: tokenSymbol_,
            decYield: StringDecimals.cutAtPrecision(
                StringDecimals.decimalString(dueValue, 18, false),
                4
            ),
            untilDateString: untilDate(until)
        });

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64Upgradeable.encode(
                        abi.encodePacked(
                            bytes('{"name":"'),
                            abi.encodePacked(
                                bytes("Sellary "),
                                tokenId.toString()
                            ),
                            bytes('","description":"'),
                            abi.encodePacked(
                                bytes("salary pledged until "),
                                renderVars.untilDateString,
                                "; will yield ~",
                                renderVars.decYield,
                                " ",
                                renderVars.tokenSymbol,
                                '",'
                            ),
                            bytes('"image":"data:image/svg+xml;base64,'),
                            Base64Upgradeable.encode(renderSVG(renderVars)),
                            bytes(
                                '","attributes": [{"display_type": "date", "trait_type": "expires","value":'
                            ),
                            abi.encodePacked(until.toString(), "}]}")
                        )
                    )
                )
            );
    }

    function renderBG() internal pure returns (bytes memory bg) {
        return
            abi.encodePacked(
                "<defs>"
                '<linearGradient id="gradient-fill" x1="0" y1="0" x2="0" y2="800" gradientUnits="userSpaceOnUse">'
                '<stop offset="0" stop-color="#12bb33" />'
                '<stop offset="1" stop-color="#0a515c" />'
                "</linearGradient>"
                "</defs>"
                '<rect x="0" y="0" height="600" width="600" fill="url(#gradient-fill)"/>'
            );
    }

    function renderSVG(RenderVars memory renderVars)
        public
        pure
        returns (bytes memory svg)
    {
        return
            abi.encodePacked(
                '<svg width="600" height="600" xmlns="http://www.w3.org/2000/svg">',
                renderBG(),
                '<text text-anchor="start" font-size="30" x="28" y="60" font-family="Arial" fill="black">Flowrate</text>',
                '<text text-anchor="start" font-size="50" x="28" y="120" font-family="Arial" fill="white">',
                bytes(renderVars.decFlowRate),
                bytes(" "),
                bytes(renderVars.tokenSymbol),
                "/s</text>",
                '<text text-anchor="start" font-size="30" x="28" y="200" font-family="Arial" fill="black">Yield</text>',
                '<text text-anchor="start" font-size="50" x="28" y="260" font-family="Arial" fill="white">',
                renderVars.decYield,
                bytes(" "),
                renderVars.tokenSymbol,
                "</text>",
                '<text text-anchor="start" font-size="30" x="28" y="340" font-family="Arial" fill="black">Expiry Date (Y/M/D)</text>',
                '<text text-anchor="start" font-size="50" x="28" y="400" font-family="Arial" fill="white">',
                bytes(renderVars.untilDateString),
                "</text>",
                "</svg>"
            );
    }
}
