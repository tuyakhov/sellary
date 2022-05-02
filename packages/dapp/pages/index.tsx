import { Container, Divider, Flex, Heading, SimpleGrid, Spacer } from "@chakra-ui/react";
import { Framework, IStream, SuperToken } from "@superfluid-finance/sdk-core";
import type { NextPage } from "next";
import Head from "next/head";
import React, { useEffect, useState } from "react";
import { Account } from "../components/Account";
import { AddEmployee } from "../components/AddEmployee";
import ContentBox from "../components/ContentBox";
import { SellaryStats } from "../components/SellaryStats";
import Stream from "../components/Stream";
import { useWeb3 } from "../components/Web3Context";

const Home: NextPage = () => {
    const [sf, setFramework] = useState<Framework>();
    const [streams, setStreams] = useState<IStream[]>([]);
    const {provider, signer, account, chainId} = useWeb3();

    useEffect(() => {
        if (!provider || !chainId) return;

        (async () => {
            const _sf = await Framework.create({
                chainId,
                provider
            });
            setFramework(_sf);
        })();
    }, [provider, chainId]);

    useEffect(() => {
        if (!sf || !account) return;
        (async () => {
          const _streams = await sf.query
            .listStreams({receiver: account, sender: process.env.NEXT_PUBLIC_SF_SELLARY});
        
            console.log(_streams);
            setStreams(_streams.data);

        const _outStreams = await sf.query.listStreams({
            sender: process.env.NEXT_PUBLIC_SF_SELLARY,
            token: process.env.NEXT_PUBLIC_DAIX
        });
        console.log("outgoing streams: ", _outStreams);

        })();
    }, [sf, account]);


    return (
        <Container maxW="container.xl" p="2" h="100vh">
            <Head>
                <title>Sell your salary!</title>
            </Head>
            <Flex justify="space-between" align="center" mb={12} mt={4}>
                <Heading textDecoration="underline" fontWeight={900}>sellary</Heading>
                <Account/>
            </Flex>
            {streams.length === 0 ?
                <ContentBox streams={streams}/>
                :
                (<>
                <Heading size="md" mb={3}>Your streams</Heading>
                  <SimpleGrid columns={[1, 2, 3]} spacing={10}>
                      {streams.map((t) => (
                          <Stream key={t.id} stream={t} />
                          ))}
                  </SimpleGrid>
                </>
                )
            }
            {sf && 
                <Flex direction="column" justify="space-between" mt={6} gridGap={3} align="flex-start">
                    <SellaryStats sf={sf} />
                    <Spacer />
                    <Heading size="sm">add an employee</Heading>
                    <AddEmployee />
                </Flex>
            }
        </Container>
    );
};

export default Home;
