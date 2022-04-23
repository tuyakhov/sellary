// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

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
        ISuperToken acceptedToken
    ) ERC721("Sellary", "SLRY") {
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


    // @dev owner can edit the NFT as long as it hasn't been issued (transferred out) yet
    // @dev set flowRate to 0 to remove the flow
    // function editNFT(uint256 tokenId, int96 flowRate) external onlyOwner exists(tokenId) {
    //     require(flowRate >= 0, "flowRate must be positive!");

    //     address receiver = ownerOf(tokenId);

    //     if (flowRate == 0) {
    //         _reduceFlow(receiver, flowRates[tokenId]);
    //     } else {
    //         _increaseFlow(receiver, flowRate - flowRates[tokenId]);
    //     }

    //     flowRates[tokenId] = flowRate;
    // }


// function burnNFT(uint256 tokenId) external onlyOwner exists(tokenId) {
//         address receiver = ownerOf(tokenId);

//         int96 rate = flowRates[tokenId];
//         delete flowRates[tokenId];
//         _burn(tokenId);
//         //deletes flow to previous holder of nft & receiver of stream after it is burned

//         //we will reduce flow of owner of NFT by total flow rate that was being sent to owner of this token
//         _reduceFlow(receiver, rate);
//     }

    // Add a function that allows a token owner to split their token into two streams
    // function splitStream(uint256 tokenId, int96 newTokenFlowRate) public {
    //     require(
    //         msg.sender == ownerOf(tokenId),
    //         "can't edit someone else's stream"
    //     );
    //     require(
    //         newTokenFlowRate < flowRates[tokenId],
    //         "new flow must be less than old flow"
    //     );

    //     //reduce the flow to the receiver by the 'flowRate' in storage
    //     flowRates[tokenId] -= newTokenFlowRate;
    //     _reduceFlow(msg.sender, newTokenFlowRate);
    //     // mint new token - will create new token's flow rate
    //     _issueNFT(msg.sender, newTokenFlowRate);
    //     // change old token's stored flowRate
    //     //decrease by the value of newToken flow rate (which must be less than the old flow so can't be negative)

    //     // create new token's stored flowRate
    // }

    // function mergeStreams(uint256 tokenId1, uint256 tokenId2) public {
    //     require(
    //         msg.sender == ownerOf(tokenId1),
    //         "Can't edit someone else's stream"
    //     );
    //     require(
    //         msg.sender == ownerOf(tokenId2),
    //         "Can't edit someone else's stream"
    //     );

    //     //merge token1 into token2
    //     //increase flowRate of token1
    //     flowRates[tokenId1] += flowRates[tokenId2];
    //     //delete flowRate of token 2 and burn NFT
    //     delete flowRates[tokenId2];
    //     _burn(tokenId2);
    // }

}
