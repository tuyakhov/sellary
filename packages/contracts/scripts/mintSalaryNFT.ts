import { Framework } from "@superfluid-finance/sdk-core";
import dotenv from "dotenv-flow";
import { ethers } from "hardhat";
import { Sellary__factory } from "../typechain/factories/Sellary__factory";
import { TransferEvent } from "../typechain/Sellary";

dotenv.config();

let employee;

async function main() {
  const accounts = await ethers.getSigners();
  employee = accounts[18];
  buyer = accounts[19];

  const sf = await Framework.create({
    networkName: "custom",
    provider: ethers.provider,
    dataMode: "WEB3_ONLY",
    resolverAddress: process.env.SF_RESOLVER,
    protocolReleaseVersion: "test",
  });
  // const calculatedFlowRate = monthlyAmount * 3600 * 24 * 30;
  const daix = await sf.loadSuperToken("fDAIx");

  const Sellary = Sellary__factory.connect(
    process.env.SF_SELLARY as string,
    employee
  );

  const nowPlusOneHour = Math.floor(Date.now() / 1000) + 60 * 60;

  // issue to ourselves
  const tx = await Sellary.issueSalaryNFT(
    await employee.getAddress(),
    nowPlusOneHour
  );
  const res = await tx.wait();

  console.log(res);
  const transferEvent: TransferEvent =
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    res.events?.find((evt) => evt.event === "Transfer") as TransferEvent;
  if (!transferEvent) {
    throw new Error("no Mint event captured in minting transaction");
  }

  const tokenId = await transferEvent.args.tokenId;
  console.log(`minted ${tokenId}`);
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
