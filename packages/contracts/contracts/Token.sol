// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {ISuperfluid, ISuperToken, ISuperApp, ISuperAgreement, SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {CFAv1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/CFAv1Library.sol";
import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import {SuperAppBase} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";

contract SellaryToken is ERC721, Pausable, Ownable, SuperAppBase {
    using Strings for uint256;
    using CFAv1Library for CFAv1Library.InitData;

    ISuperfluid private _host; 
    ISuperToken private _acceptedToken; // accepted token
    IConstantFlowAgreementV1 private _cfa; // the stored constant flow agreement class address

    CFAv1Library.InitData public cfaV1;

    //mapping (uint256 => address) public _receivers;
    mapping(uint256 => int96) public flowRates;

    uint256 public nextTokenId = 1;

    event ReceiverChanged(address receiver);

    modifier onlyHost() {
        require(
            msg.sender == address(_host),
            "RedirectAll: support only one host"
        );
        _;
    }

    constructor(
        ISuperfluid host,
        ISuperToken acceptedToken
    ) ERC721("SellaryToken", "SELLARY") {
        _host = host;
        _acceptedToken = acceptedToken;
        _cfa = IConstantFlowAgreementV1(
            address(
                host.getAgreementClass(
                    keccak256(
                        "org.superfluid-finance.agreements.ConstantFlowAgreement.v1"
                    )
                )
            )
        );
        cfaV1 = CFAv1Library.InitData(_host, _cfa);

        //https://docs.superfluid.finance/superfluid/protocol-developers/guides/super-app
        uint256 configWord = SuperAppDefinitions.APP_LEVEL_FINAL |
            SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP;

        _host.registerApp(configWord);
    }

    function safeMint(address to)
        public
    {
        uint256 curTokenId = nextTokenId;
        nextTokenId = nextTokenId + 1;
        _safeMint(to, curTokenId);
    }

    //now I will insert a hook in the _transfer, executing every time the token is moved
    //When the token is first "issued", i.e. moved from the first contract, it will start the stream
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(to != address(0x0), "New receiver mustnt be 0x0");
        require(
            !_host.isApp(ISuperApp(to)),
            "New receiver can not be a superApp"
        );

        (uint256 timestamp,
            int96 outFlowRate,
            uint256 deposit,
            uint256 owedDeposit) = _cfa.getFlow(
            _acceptedToken,
            address(this),
            to
        ); // unclear what happens if flow doesn't exist.

        if (outFlowRate > 0) {
            cfaV1.deleteFlow(address(this), to, _acceptedToken);
            cfaV1.createFlow(
                to,
                _acceptedToken,
                _cfa.getNetFlow(_acceptedToken, address(this))
            );
        }

        emit ReceiverChanged(to);

        //blocks transfers to superApps - done for simplicity, but you could support super apps in a new version!
        // require(
        //     !_host.isApp(ISuperApp(to)) || to == address(this), "New receiver can not be a SuperApp"
        // );

        // (, int96 outFlowRate, , ) = _cfa.getFlow(
        //     _acceptedToken,
        //     address(this),
        //     to
        // );

        // if (outFlowRate == flowRate) {
        //     cfaV1.deleteFlow(address(this), to, _acceptedToken);
        // } else if (outFlowRate > flowRate) {
        //     // reduce the outflow by flowRate;
        //     // shouldn't overflow, because we just checked that it was bigger.
        //     cfaV1.updateFlow(to, _acceptedToken, outFlowRate - flowRate);
        // }

        // // @dev delete flowRate of this token from old receiver
        // // ignores minting case
        // _reduceFlow(oldReceiver, flowRates[tokenId]);
        // // @dev create flowRate of this token to new receiver
        // // ignores return-to-issuer case
        // _increaseFlow(newReceiver, flowRates[tokenId]);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override {
        super._burn(tokenId);
    }
    
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {      
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        return string(
            abi.encodePacked(
                bytes('data:application/json;utf8,{"name":"'),
                abi.encodePacked("Sellary #", tokenId.toString()),
                bytes('","description":"'),
                abi.encodePacked("Sellary #", tokenId.toString()),
                // // bytes('","external_url":"'),
                // // getExternalUrl(tokenId),
                bytes('}"')
            )
        );
    }

        function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
