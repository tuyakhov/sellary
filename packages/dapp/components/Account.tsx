import {Badge, Box, Button, Text } from "@chakra-ui/react";
import React from "react";
import { useWeb3 } from "./Web3Context";

const Account = () => {
  const { account, connect, disconnect } = useWeb3();

  return account ? (
              <Box bg='RGBA(255, 255, 255, 0.48)' borderWidth='1px' p={2} borderRadius='lg' overflow='hidden'>
                <Badge fontSize='1.2em'>{account.slice(0, 5) + "..." + account.slice(-4)}</Badge>
                {disconnect && <Button onClick={() => disconnect()} size='sm' ml={2}>Disconnect</Button>}
              </Box>)
          :
          <Button onClick={() => connect ? connect() : false}>Connect Wallet</Button>
  
};

export { Account };
