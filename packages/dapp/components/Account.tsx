import {Badge, Box, Button, Flex, Text } from "@chakra-ui/react";
import { ethers } from "ethers";
import React, { useEffect, useMemo, useState } from "react";
import { useWeb3 } from "./Web3Context";


const Account = () => {
  const { account, connect, provider, signer } = useWeb3();
  const [balance, setBalance] = useState<{
    eth: string,
  }>();

  useEffect(
    () => {
      if (!account || !provider) return;
      
      (async () => {
        const [eth] = [
          await provider.getBalance(account),
        ];        
        setBalance({
          eth: parseFloat(ethers.utils.formatEther(eth)).toFixed(4),
        })
      })();
    }, [account, provider]);

    return account ? (
      <Flex bg="rgba(255, 255, 255, 0.48)" rounded="sm" p={2} >
        <Flex  bg="gray.100" px={3} width={48} direction="column">
          <Text fontSize="lg" isTruncated>{account}</Text>
          <Text fontSize="md" textAlign="right">E {balance?.eth}</Text>
        </Flex>
      </Flex>)
      :
      <Button onClick={() => connect ? connect() : false}>Connect Wallet</Button>
  
};

export { Account };
