// @ts-ignore
import deployFramework from "@superfluid-finance/ethereum-contracts/scripts/deploy-framework";
// @ts-ignore
import deploySuperToken from "@superfluid-finance/ethereum-contracts/scripts/deploy-super-token";
// @ts-ignore
import deployTestToken from "@superfluid-finance/ethereum-contracts/scripts/deploy-test-token";
import { Framework } from "@superfluid-finance/sdk-core";
import { ethers, web3 } from "hardhat";
import { abi as daiABI } from "../abis/fDAIABI.json";

const errorHandler = (err: any) => {
  if (err) throw err;
};

async function main() {
  const accounts = await ethers.getSigners();
  const provider = ethers.provider;

  const bn = await provider.getBlockNumber();
  console.log(bn);

  // deploy the framework
  await deployFramework(errorHandler, {
    web3,
    from: accounts[0].address,
  });

  // deploy a fake erc20 token
  const fDAIAddress = await deployTestToken(errorHandler, [":", "fDAI"], {
    web3,
    from: accounts[0].address,
  });
  // deploy a fake erc20 wrapper super token around the fDAI token
  const fDAIxAddress = await deploySuperToken(errorHandler, [":", "fDAI"], {
    web3,
    from: accounts[0].address,
  });

  // initialize the superfluid framework...put custom and web3 only bc we are using hardhat locally
  const sf = await Framework.create({
    networkName: "custom",
    provider,
    dataMode: "WEB3_ONLY",
    resolverAddress: process.env.RESOLVER_ADDRESS, // this is how you get the resolver address
    protocolReleaseVersion: "test",
  });

  const superSigner = await sf.createSigner({
    signer: accounts[0],
    provider,
  });
  // use the framework to get the super toen
  const daix = await sf.loadSuperToken("fDAIx");
  const daiAddress = daix.underlyingToken.address;
  const dai = new ethers.Contract(daiAddress, daiABI, accounts[0]);

  const addrs = {
    dai: daiAddress,
    daix: daix.address,
    superSigner: await superSigner.getAddress(),
    host: sf.host.hostContract.address,
    cfa: sf.cfaV1.options.config.cfaV1Address,
    resolver: process.env.RESOLVER_ADDRESS,
  };

  console.log("deployed", addrs);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
