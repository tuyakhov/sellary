import { Framework } from "@superfluid-finance/sdk-core";
import dotenv from "dotenv-flow";
import { ethers } from "hardhat";
import { Sellary__factory } from "../typechain/factories/Sellary__factory";

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

  const monthlySalary = ethers.utils.parseEther("2000");
  const flowrateWei = monthlySalary.div(30).div(24).div(60).div(60);
  console.log(
    "Streaming 2 Eth over the duration of 1 month with a flowrate of: ",
    ethers.utils.formatEther(flowrateWei.toString())
  );

  // const calculatedFlowRate = monthlyAmount * 3600 * 24 * 30;
  const daix = await sf.loadSuperToken("fDAIx");

  const createFlowOperation = sf.cfaV1.createFlow({
    flowRate: flowrateWei.toString(),
    receiver: process.env.SF_SELLARY as string,
    superToken: daix.address,
    // userData?: string
  });
  await createFlowOperation.exec(employer);

  const Sellary = Sellary__factory.connect(
    process.env.SF_SELLARY as string,
    employer
  );

  await Sellary.streamSalary(
    await employee.getAddress(),
    flowrateWei.toString()
  );

  const info = await sf.cfaV1.getFlow({
    superToken: daix.address,
    sender: process.env.SF_SELLARY as string,
    receiver: await employee.getAddress(),
    providerOrSigner: employee,
  });

  console.log("streaming salary to employee", info);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
