import {Box, Button, Center, Container, Flex, Heading, Image, Link, SimpleGrid, Text} from "@chakra-ui/react";
import type {NextPage} from "next";
import Head from "next/head";
import React, {useCallback, useEffect, useMemo, useState} from "react";
import {Account} from "../components/Account";
import Stream from "../components/Stream";
import {useWeb3} from "../components/Web3Context";
import {BigNumberish} from 'ethers'
import {Framework, SuperToken, IStream} from "@superfluid-finance/sdk-core";
import {DragHandleIcon} from "@chakra-ui/icons";

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
        <Box p="5">
            <Head>
                <title>Your Superfluidstreams</title>
            </Head>
            <Flex justify="space-between" align="center" mb={12}>
                <Heading>Sellary</Heading>
                <Account/>
            </Flex>
            {!account || streams.length === 0 ?
                (
                    <Center display='flex' flexDirection={"column"} bg='RGBA(255, 255, 255, 0.48)' borderWidth='1px'
                            p={20}
                            borderRadius='lg' overflow='hidden'>
                        <DragHandleIcon w={8} h={8}/>
                        <Text m={10} fontSize='2xl'>
                            Your active streams will appear here.
                        </Text>
                        {!account ?
                            <Button onClick={() => connect()}>Connect Wallet</Button>
                            :
                            streams.length === 0 ?
                                <Button>
                                    <Link href="https://app.superfluid.finance/" isExternal>
                                        Check out Superfluid!
                                    </Link>
                                </Button>
                                : ""}
                    </Center>
                )
                :
                (
                  <SimpleGrid columns={[1, 2]} spacing={10}>
                      {streams.map((t) => (
                          <Stream key={t.id} stream={t} nextTokenId={nextTokenId}/>
                      ))}
                  </SimpleGrid>
                )
            }
        </Box>
    );
};

export default Home;
