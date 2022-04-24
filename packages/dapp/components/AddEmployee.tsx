import { Button, Flex, Input } from '@chakra-ui/react';
import { Sellary__factory as SellaryFactory} from '@token/contracts';
import { ethers } from 'ethers';
import React, { useState } from 'react'
import { useWeb3 } from './Web3Context';

export const AddEmployee = () => {

  const [eplAddress, setEplAddress] = useState<string>("");
  const [eplSalary, setEplSalary] = useState<string>("");

  const {signer} = useWeb3();

  const addEmployee = async (addr: string, salaryUSD: string) => {
    if(!signer) return;

    const sellary = SellaryFactory.connect(process.env.NEXT_PUBLIC_SF_SELLARY as string, signer)
    
    const monthlySalary = ethers.utils.parseEther(salaryUSD);
    const flowrateWei = monthlySalary.div(30).div(24).div(60).div(60);

    await sellary.streamSalary(
      addr, flowrateWei.toString()
    );
  }

  return (
    <form>
      <Flex direction="row" gridGap={2}>
      <Input type="text" bg="white" placeholder="0x" value={eplAddress}
         onChange={e => setEplAddress(e.target.value)}
      />
      <Flex align="center">
      <Input type="text" bg="white" placeholder="1000" value={eplSalary}
        onChange={e => setEplSalary(e.target.value)}
      />
      <Flex mx={2}>fDAIx/m</Flex>
      </Flex>

      <Button onClick={() => addEmployee(eplAddress, eplSalary)} px={12}>Employ</Button>
      </Flex>
    </form>
  )


}