import React, { useEffect, useState } from 'react'
import {Framework, SuperToken, IStream} from "@superfluid-finance/sdk-core";
import { useWeb3 } from './Web3Context';
import { Flex } from '@chakra-ui/react';
import { ethers } from 'ethers';

export const SellaryStats = ({sf}: {sf: Framework}) => {

  const {provider,  account} = useWeb3();
  const [sellaryBalance, setSellaryBalance] = useState<string>();
  useEffect(() => {
    if (!sf || !provider) return;
    (async () => {
      const daix = await sf.loadSuperToken("0x745861AeD1EEe363b4AaA5F1994Be40b1e05Ff90");
      const _sellaryBalance = await daix.balanceOf({
        account: process.env.NEXT_PUBLIC_SF_SELLARY as string, 
        providerOrSigner: provider
      });
      setSellaryBalance(ethers.utils.formatEther(_sellaryBalance));
    })()
  }, [sf, provider])

  return <Flex >
     Sellary Contract Balance: {sellaryBalance} fDAIx
  </Flex>
} 