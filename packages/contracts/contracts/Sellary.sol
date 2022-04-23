// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {ISuperfluid, ISuperToken, ISuperApp} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";

import {CFAv1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/CFAv1Library.sol";
import "hardhat/console.sol";

// receives salaries by DAO

struct SalaryPledge {
    address employee;
    uint256 untilTs; 
}

contract Sellary is ERC721, Ownable {
    using Strings for uint256;
    using CFAv1Library for CFAv1Library.InitData;
    
    ISuperfluid private _host;
    ISuperToken public _acceptedToken; // accepted token
    IConstantFlowAgreementV1 private _cfa; // the stored constant flow agreement class address
    
    CFAv1Library.InitData public cfaV1; //initialize cfaV1 variable

    event NFTIssued(uint256 tokenId, address receiver, int96 flowRate);

    mapping(address => int96) public salaryFlowrates;
    mapping(uint256 => SalaryPledge) public salaryPledges;

    uint256 public nextId; 

    constructor(
        ISuperfluid host,
        IConstantFlowAgreementV1 cfa,
        ISuperToken acceptedToken,
        string memory name_
    ) ERC721(name_, "SLRY") {
        _host = host;
        _cfa = cfa;
        _acceptedToken = acceptedToken;

        nextId = 1;

        assert(address(_host) != address(0));
        assert(address(_cfa) != address(0));
        assert(address(_acceptedToken) != address(0));

        //initialize InitData struct, and set equal to cfaV1
        cfaV1 = CFAv1Library.InitData(
        host,
        //here, we are deriving the address of the CFA using the host contract
        IConstantFlowAgreementV1(
            address(host.getAgreementClass(
                    keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1")
                ))
            )
        );
    }

    modifier exists(uint256 tokenId) {
        require(_exists(tokenId), "token doesn't exist or has been burnt");
        _;
    }

    function streamSalary(address receiver, int96 flowRate_) public /*onlyEmployer*/ {
        //check that stream doesnt exist
        //check that no NFT is out there.
        cfaV1.createFlow(receiver, _acceptedToken, flowRate_);
        salaryFlowrates[receiver] = flowRate_;
    } 

    // @dev todo only callable by employees
    function issueSalaryNFT(address receiver, uint256 until) external {
        (, int96 oldOutFlowRate, , ) = _cfa.getFlow(
            _acceptedToken,
            address(this),
            msg.sender
        );
        //todo: ensure that the outflow is not part of an active pledge

        //there's an active stream to this recipient
        if (oldOutFlowRate > 0) {
            console.logInt(oldOutFlowRate);
            //cancel our current salary stream
            cfaV1.deleteFlow(address(this), msg.sender, _acceptedToken);
            _issueNFT(msg.sender, receiver, oldOutFlowRate, until);
        } else {
            revert("not getting a salary");
        }
    }

            
    //use the common or predefined flow rate _acceptedToken
    function _issueNFT(address employee_, address receiver, int96 flowRate, uint256 untilTs_) internal {
        require(flowRate > 0, "flowRate must be positive!");
        salaryPledges[nextId] = SalaryPledge({
            employee: employee_,
            untilTs: untilTs_
        });
        //emit NFTIssued(nextId, receiver, flowRates[nextId]);
        _mint(receiver, nextId);
        nextId += 1;
    }

    function metadata(uint256 tokenId) 
        public view 
        exists(tokenId) 
        returns (int96 nftFlowrate, uint256 dueValue, uint256 until) {
        (, nftFlowrate, , ) = _cfa.getFlow(
            _acceptedToken,
            address(this),
            ownerOf(tokenId)
        );
        
        uint256 secondsToGo = salaryPledges[tokenId].untilTs - block.timestamp;
        dueValue = uint256(int256(nftFlowrate)) * secondsToGo;
        until = salaryPledges[tokenId].untilTs;
    }

    function tokenURI(uint256 tokenId) public override view exists(tokenId) returns (string memory) {
        (int96 nftFlowrate, uint256 dueValue, uint256 until) = metadata(tokenId);

        uint256 decimalVal = dueValue / 10**18;

        return string(
            abi.encodePacked(
                bytes('data:application/json;utf8,{"name":"'),
                abi.encodePacked("Sellary #", tokenId.toString()),
                bytes('","description":"'),
                abi.encodePacked('salary pledge running until ', 
                    until.toString(), 
                    '; will yield ~', 
                    decimalVal.toString(),
                    bytes(' '), 
                    bytes(_acceptedToken.symbol()), 
                    '",'),
                // // bytes('","external_url":"'),
                // // getExternalUrl(tokenId),
                bytes('"attributes": ['),
                bytes('{"display_type": "date", "trait_type": "expires",'),
                abi.encodePacked('"value":',until.toString(), '}]'),
                // bytes('","image":"data:image/svg+xml;base64,'),
                // Base64.encode(renderSVG(tokenId)),
                bytes('"}')
            )
        ); 
    }

    function renderSVG(uint256 tokenId) public pure returns (bytes memory svg) {
        (int96 nftFlowrate, uint256 dueValue, uint256 until) = metadata(tokenId);

        return abi.encodePacked('<svg width="600" height="600" xmlns="http://www.w3.org/2000/svg">',
            '<defs><linearGradient id="gradient-fill" x1="0" y1="0" x2="800" y2="0" gradientUnits="userSpaceOnUse">',
            '<stop offset="0" stop-color="#0a515c" /> <stop offset="0.125" stop-color="#005f68"/>',
            '<stop offset="0.25" stop-color="#006d70" /> <stop offset="0.375" stop-color="#007b73" />',
            '<stop offset="0.5" stop-color="#008971" /> <stop offset="0.625" stop-color="#009669" /> ',
            '<stop offset="0.75" stop-color="#00a35d" /> <stop offset="0.875" stop-color="#00af4c" /> ',
            '<stop offset="1" stop-color="#12bb33" /> </linearGradient> </defs> <rect x="0" y="0" height="600" ',
            'width="600" fill="url(#gradient-fill)"/> <text text-anchor="start" font-size="30" x="28" y="60" ',
            'font-family="Arial" text-anchor="middle" fill="black"> Flowrate </text> <text text-anchor="start" ',
            'font-size="50" x="28" y="120" font-family="Arial" text-anchor="middle" fill="white"> ',
            '',nftFlowrate.toString(),' DAIx/s </text> <text text-anchor="start" font-size="30" x="28" y="200" font-family="Arial" ',
            'text-anchor="middle" fill="black"> Yield </text> <text text-anchor="start" font-size="50" x="28" y="260" ',
            'font-family="Arial" text-anchor="middle" fill="white"> ',dueValue.toString(),' DAI </text> <text text-anchor="start" ',
            'font-size="30" x="28" y="340" font-family="Arial" text-anchor="middle" fill="black"> Expiry Date </text> ',
            '<text text-anchor="start" font-size="50" x="28" y="400" font-family="Arial" text-anchor="middle" ',
            'fill="white"> ',until.toString(),' </text> </svg>');

    }

    function isSalaryClaimable(uint256 tokenId) public view returns (bool) {
        return salaryPledges[tokenId].untilTs - block.timestamp < 0;
    }

    function claimBackSalary(uint256 tokenId) public exists(tokenId) {
        if (!isSalaryClaimable(tokenId)) {
            revert ("Salary not claimable yet");
        }

        if (salaryPledges[tokenId].employee != msg.sender) {
            revert ("youre not the employee that receives this salary");
        }

        //todo might likely fail when owner hasn't approved the collection.
        _burn(tokenId);
    }

    function _beforeTokenTransfer(
        address oldReceiver,
        address newReceiver,
        uint256 tokenId
    ) internal override {
        //blocks transfers to superApps - done for simplicity, but you could support super apps in a new version!
        require(
            !_host.isApp(ISuperApp(newReceiver)) ||
                newReceiver == address(this),
            "New receiver can not be a superApp"
        );

        (, int96 oldOutFlowRate, , ) = _cfa.getFlow(
            _acceptedToken,
            address(this),
            oldReceiver
        );

        if (oldOutFlowRate > 0) {
            cfaV1.deleteFlow(address(this),oldReceiver, _acceptedToken);
        }
        if (newReceiver == address(0)) {
            //burnt
            //setup old stream flow
            streamSalary(salaryPledges[tokenId].employee,oldOutFlowRate);
        } else {
            if (oldOutFlowRate == 0) {
                oldOutFlowRate = salaryFlowrates[newReceiver]; 
            }
            cfaV1.createFlow(newReceiver, _acceptedToken, oldOutFlowRate);
        }
    }   


    /**************************************************************************
     * Library
     *************************************************************************/
    //this will reduce the flow or delete it
    function _reduceFlow(address to, int96 flowRate) internal {
        if (to == address(this)) return;

        (, int96 outFlowRate, , ) = _cfa.getFlow(
            _acceptedToken,
            address(this),
            to
        );

        if (outFlowRate == flowRate) {
            cfaV1.deleteFlow(address(this), to, _acceptedToken);
        } else if (outFlowRate > flowRate) {
            // reduce the outflow by flowRate;
            // shouldn't overflow, because we just checked that it was bigger.
            cfaV1.updateFlow(to, _acceptedToken, outFlowRate - flowRate);
        }
        // won't do anything if outFlowRate < flowRate
    }

    //this will increase the flow or create it
    function _increaseFlow(address to, int96 flowRate) internal {
        if (to == address(0)) return;

        (, int96 outFlowRate, , ) = _cfa.getFlow(
            _acceptedToken,
            address(this),
            to
        ); //returns 0 if stream doesn't exist
        if (outFlowRate == 0) {
            cfaV1.createFlow(to, _acceptedToken, flowRate);
        } else {
            // increase the outflow by flowRates[tokenId]
            cfaV1.updateFlow(to, _acceptedToken, outFlowRate + flowRate);
        }
    }

}
