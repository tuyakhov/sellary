import { Button, Container, Flex, Heading, Image, SimpleGrid, Text } from "@chakra-ui/react";
import type { NextPage } from "next";
import Head from "next/head";
import { useCallback, useEffect, useMemo, useState } from "react";
import { Account } from "../components/Account";
import Stream from "../components/Stream";
import { useWeb3 } from "../components/Web3Context";
import { Token as TokenContract, Token__factory as TokenFactory}  from '@token/contracts';
import {BigNumberish} from 'ethers'
import { Framework, SuperToken, IStream } from "@superfluid-finance/sdk-core";

const Home: NextPage = () => {
  const [nextTokenId, setNextTokenId] = useState<string>();
  const [sf, setFramework] = useState<Framework>();
  const [daiXContract, setDaiXContract] = useState<SuperToken>();
  const [streams, setStreams] = useState<IStream[]>([]);
  const { provider, signer, account, chainId } = useWeb3();
  
  useEffect(() => {
    if (!provider || !chainId) return;

    (async () => {
      const _sf = await Framework.create({
        chainId,
        provider,
      });
      const _daiXContract = await _sf.loadSuperToken("fDAIx");
      setDaiXContract(_daiXContract);
      setFramework(_sf);
    })();
  }, [provider, chainId]);

  useEffect(() => {
    if (!sf || !account) return;
    (async() => {
      const _streams = await sf.query.listStreams({receiver: account });
      setStreams(_streams.data);
    })();
  }, [sf, account]);

  return (
    <Container maxW="container.xl" p="2" h="100vh">
      <Head>
        <title>Your Superfluidstreams</title>
      </Head>
      <Flex justify="space-between" align="center" my={12}>
        <Heading>tokens</Heading>
        <Account />
      </Flex>
      <SimpleGrid columns={[1, 2, 3, 4]} spacing={10}>
        {streams.map((t) => (
          <Stream key={t.id} stream={t} nextTokenId={nextTokenId}/>
        ))}
      </SimpleGrid>
    </Container>
  );
};

export default Home;
