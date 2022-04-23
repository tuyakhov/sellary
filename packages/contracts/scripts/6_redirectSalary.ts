import { Framework } from "@superfluid-finance/sdk-core";
import dotenv from "dotenv-flow";
import { ethers } from "hardhat";
import { Sellary__factory } from "../typechain/factories/Sellary__factory";

dotenv.config();

let employee;
let buyer;

async function main() {
  const accounts = await ethers.getSigners();
  employee = accounts[18];
  buyer = accounts[19];

  const sf = await Framework.create({
    networkName: "custom",
    provider: ethers.provider,
    dataMode: "WEB3_ONLY",
    resolverAddress: process.env.SF_RESOLVER as string,
    protocolReleaseVersion: "test",
  });
  // const calculatedFlowRate = monthlyAmount * 3600 * 24 * 30;
  const daix = await sf.loadSuperToken("fDAIx");

  const info = await sf.cfaV1.getFlow({
    superToken: daix.address,
    sender: process.env.SF_SELLARY as string,
    receiver: await employee.getAddress(),
    providerOrSigner: employee,
  });

  console.log("theres a flow for employee (due to nft):", info);

  const Sellary = Sellary__factory.connect(
    process.env.SF_SELLARY as string,
    employee
  );

  const tx = await Sellary.transferFrom(
    await employee.getAddress(),
    await buyer.getAddress(),
    1
  );

  await tx.wait();

  const infoB = await sf.cfaV1.getFlow({
    superToken: daix.address,
    sender: process.env.SF_SELLARY as string,
    receiver: await buyer.getAddress(),
    providerOrSigner: buyer,
  });

  console.log("there SOHULD be a flow for buyer (he has the nft now):", infoB);

  // const createFlowOperation = sf.cfaV1.createFlow({
  //   flowRate: flowrateWei.toString(),
  //   receiver: await employee.getAddress(),
  //   superToken: daix.address,
  //   // userData?: string
  // });

  // const result = await createFlowOperation.exec(employer);
  // console.log(
  //   `started streaming to employee: `,
  //   await employee.getAddress(),
  //   result
  // );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
