import { Framework } from "@superfluid-finance/sdk-core";
import dotenv from "dotenv-flow";
import { ethers } from "hardhat";

dotenv.config();

let employer;
let employee;

async function main() {
  const accounts = await ethers.getSigners();
  employer = accounts[17];
  employee = accounts[18];

  const sf = await Framework.create({
    networkName: "custom",
    provider: ethers.provider,
    dataMode: "WEB3_ONLY",
    resolverAddress: process.env.SF_RESOLVER,
    protocolReleaseVersion: "test",
  });
  // const calculatedFlowRate = monthlyAmount * 3600 * 24 * 30;
  const daix = await sf.loadSuperToken("fDAIx");

  const info = await sf.cfaV1.getFlow({
    superToken: daix.address,
    sender: await employer.getAddress(),
    receiver: await employee.getAddress(),
    providerOrSigner: employee,
  });

  console.log("info", info);

  // op must be requested by the employee:
  const updOperation = await sf.cfaV1.updateFlow({
    flowRate: info.flowRate,
    receiver: process.env.SF_SELLARY as string,
    superToken: daix.address,
  });
  const updResult = await updOperation.exec(employer);

  console.log("upd", updResult);

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
