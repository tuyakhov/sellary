import {Box, Button, Center, Container, Flex, Heading, Image, Link, SimpleGrid, Text} from "@chakra-ui/react";
import type {NextPage} from "next";
import Head from "next/head";
import React, {useEffect, useState} from "react";
import {Account} from "../components/Account";
import Stream from "../components/Stream";
import {useWeb3} from "../components/Web3Context";
import {Framework, SuperToken, IStream} from "@superfluid-finance/sdk-core";
import ContentBox from "../components/ContentBox";

const Home: NextPage = () => {
    const [nextTokenId, setNextTokenId] = useState<string>();
    const [sf, setFramework] = useState<Framework>();
    const [daiXContract, setDaiXContract] = useState<SuperToken>();
    const [streams, setStreams] = useState<IStream[]>([]);
    const {provider, signer, account, chainId, connect} = useWeb3();

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
        (async () => {
          const _streams = await sf.query.listStreams({receiver: account});
            setStreams(_streams.data);
        })();
    }, [sf, account]);

    return (
        <Container maxW="container.xl" p="2" h="100vh">
            <Head>
                <title>Sell your salary!</title>
            </Head>
            <Flex justify="space-between" align="center" mb={12} mt={4}>
                <Heading textDecoration="underline">Sellary</Heading>
                <Account/>
            </Flex>
            {!sf || streams.length === 0 ?
                    <ContentBox streams={streams} sf={sf}/>
                :
                (
                  <SimpleGrid columns={[1, 2, 3]} spacing={10}>
                      {streams.map((t) => (
                          <Stream key={t.id} stream={t} />
                      ))}
                  </SimpleGrid>
                )
            }
        </Container>
    );
};

export default Home;
