// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {ISuperfluid, ISuperToken, ISuperApp} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import {CFAv1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/CFAv1Library.sol";
import "./SellaryRenderer.sol";
import "hardhat/console.sol";

struct SalaryPledge {
    address employee;
    uint256 untilTs; 
}

// receives salaries by DAO
contract Sellary is ERC721Upgradeable, OwnableUpgradeable {
    using CFAv1Library for CFAv1Library.InitData;

    ISuperfluid private _host;
    ISuperToken public _acceptedToken; // accepted token
    IConstantFlowAgreementV1 private _cfa; // the stored constant flow agreement class address
    SellaryRenderer private _sellaryRenderer;

    CFAv1Library.InitData public cfaV1; //initialize cfaV1 variable

    event NFTIssued(uint256 tokenId, address receiver, int96 flowRate);

    mapping(address => int96) public salaryFlowrates;
    mapping(address => uint256) public salaryToToken;
    mapping(uint256 => SalaryPledge) public salaryPledges;

    uint256 public nextId; 

    function initialize(
        ISuperfluid host,
        IConstantFlowAgreementV1 cfa,
        ISuperToken acceptedToken,
        SellaryRenderer sellaryRenderer,
        string memory name_
    ) initializer public {
        __Ownable_init();
        __ERC721_init(name_, "SLRY");

        _host = host;
        _cfa = cfa;
        _acceptedToken = acceptedToken;
        _sellaryRenderer = sellaryRenderer;

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
        (, int96 nftFlowrate, , ) = _cfa.getFlow(
            _acceptedToken,
            address(this),
            receiver
        );
        if(nftFlowrate > 0) revert ("this receiver already receives a salary");

        //check that no NFT is out there.
        if(salaryToToken[receiver] != 0) {
            revert ("there is an NFT capturing this salary stream");
        }

        cfaV1.createFlow(receiver, _acceptedToken, flowRate_);
        salaryFlowrates[receiver] = flowRate_;
    } 

    function issueSalaryNFT(address receiver, uint256 until) external {
        
        if (salaryFlowrates[msg.sender] == 0) {
            revert("you must receive a salary to mint an NFT");
        }
        (, int96 flowRate, , ) = _cfa.getFlow(
            _acceptedToken,
            address(this),
            msg.sender
        );
        if (flowRate == 0) {
            revert("you must receive a salary to mint an NFT");
        }

        console.logInt(flowRate);
        //cancel our current salary stream
        cfaV1.deleteFlow(address(this), msg.sender, _acceptedToken);
        _issueNFT(msg.sender, receiver, flowRate, until);
        
    }
            
    //use the common or predefined flow rate _acceptedToken
    function _issueNFT(address employee_, address receiver, int96 flowRate, uint256 untilTs_) internal {
        require(flowRate > 0, "flowRate must be positive!");
        salaryPledges[nextId] = SalaryPledge({
            employee: employee_,
            untilTs: untilTs_
        });
        _mint(receiver, nextId);
        salaryToToken[employee_] = nextId;
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

        (, int96 flowRate, , ) = _cfa.getFlow(
            _acceptedToken,
            address(this),
            oldReceiver
        );

        if (flowRate > 0) {
            cfaV1.deleteFlow(address(this),oldReceiver, _acceptedToken);
        }
        if (newReceiver == address(0)) {
            //burnt
            address employee = salaryPledges[tokenId].employee;
            delete salaryPledges[tokenId];
            delete salaryToToken[employee];

            //setup old stream flow
            streamSalary(employee,flowRate);
        } else {
            if (flowRate == 0) {
                flowRate = salaryFlowrates[salaryPledges[tokenId].employee]; 
            }
            cfaV1.createFlow(newReceiver, _acceptedToken, flowRate);
        }
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

        //todo might  fail when owner hasn't approved the collection.
        _burn(tokenId);
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
        return _sellaryRenderer.metadata(
            tokenId,
            _acceptedToken.symbol(),
            nftFlowrate,
            dueValue,
            until
        );
    }    
}
