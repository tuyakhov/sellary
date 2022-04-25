// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library StringDecimals {

    function cutAtPrecision(string memory str, uint8 precision) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(strBytes.length);

        uint decimalsCovered = 0;
        uint i = 0;
        while (i < strBytes.length && decimalsCovered < precision + 1) {
            bytes1 b = strBytes[i];
            if (uint8(b) == 46) {// .
                decimalsCovered = 1;
            } else {
                if (decimalsCovered > 0) {
                    decimalsCovered = decimalsCovered + 1;
                }
            }
            result[i] = strBytes[i];
            i = i + 1;
        }
        return string(result);
    }

    // function decimals(uint256 weiVal, uint8 decimals_) internal pure returns (uint32 abtissa, uint32 mantissa) {
    //     uint256 _abtissa = weiVal / 10 ** 18;
    //     abtissa = uint32(_abtissa);
    //     uint256 _mantissa = weiVal - _abtissa * 10 ** 18;
    //     _mantissa = _mantissa / 10 ** (18 - decimals_);
    //     mantissa = uint32(_mantissa);
    // }

    // https://gist.github.com/wilsoncusack/d2e680e0f961e36393d1bf0b6faafba7
    function decimalString(uint256 number, uint8 decimals, bool isPercent) internal pure returns(string memory){
        uint8 percentBufferOffset = isPercent ? 1 : 0;
        uint256 tenPowDecimals = 10 ** decimals;

        uint256 temp = number;
        uint8 digits;
        uint8 numSigfigs;
        while (temp != 0) {
            if (numSigfigs > 0) {
                // count all digits preceding least significant figure
                numSigfigs++;
            } else if (temp % 10 != 0) {
                numSigfigs++;
            }
            digits++;
            temp /= 10;
        }

        DecimalStringParams memory params;
        params.isPercent = isPercent;
        if((digits - numSigfigs) >= decimals) {
            // no decimals, ensure we preserve all trailing zeros
            params.sigfigs = number / tenPowDecimals;
            params.sigfigIndex = digits - decimals;
            params.bufferLength = params.sigfigIndex + percentBufferOffset;
        } else {
            // chop all trailing zeros for numbers with decimals
            params.sigfigs = number / (10 ** (digits - numSigfigs));
            if(tenPowDecimals > number){
                // number is less tahn one
                // in this case, there may be leading zeros after the decimal place 
                // that need to be added

                // offset leading zeros by two to account for leading '0.'
                params.zerosStartIndex = 2;
                params.zerosEndIndex = decimals - digits + 2;
                params.sigfigIndex = numSigfigs + params.zerosEndIndex;
                params.bufferLength = params.sigfigIndex + percentBufferOffset;
                params.isLessThanOne = true;
            } else {
                // In this case, there are digits before and
                // after the decimal place
                params.sigfigIndex = numSigfigs + 1;
                params.decimalIndex = digits - decimals + 1;
            }
        }
        params.bufferLength = params.sigfigIndex + percentBufferOffset;
        return generateDecimalString(params);
    }

    // With modifications, the below taken 
    // from https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/NFTDescriptor.sol#L189-L231

    struct DecimalStringParams {
        // significant figures of decimal
        uint256 sigfigs;
        // length of decimal string
        uint8 bufferLength;
        // ending index for significant figures (funtion works backwards when copying sigfigs)
        uint8 sigfigIndex;
        // index of decimal place (0 if no decimal)
        uint8 decimalIndex;
        // start index for trailing/leading 0's for very small/large numbers
        uint8 zerosStartIndex;
        // end index for trailing/leading 0's for very small/large numbers
        uint8 zerosEndIndex;
        // true if decimal number is less than one
        bool isLessThanOne;
        // true if string should include "%"
        bool isPercent;
    }

    function generateDecimalString(DecimalStringParams memory params) internal pure returns (string memory) {
        bytes memory buffer = new bytes(params.bufferLength);
        if (params.isPercent) {
            buffer[buffer.length - 1] = '%';
        }
        if (params.isLessThanOne) {
            buffer[0] = '0';
            buffer[1] = '.';
        }

        // add leading/trailing 0's
        for (uint256 zerosCursor = params.zerosStartIndex; zerosCursor < params.zerosEndIndex; zerosCursor++) {
            buffer[zerosCursor] = bytes1(uint8(48));
        }
        // add sigfigs
        while (params.sigfigs > 0) {
            if (params.decimalIndex > 0 && params.sigfigIndex == params.decimalIndex) {
                buffer[--params.sigfigIndex] = '.';
            }
            buffer[--params.sigfigIndex] = bytes1(uint8(uint256(48) + (params.sigfigs % 10)));
            params.sigfigs /= 10;
        }
        return string(buffer);
    }
}