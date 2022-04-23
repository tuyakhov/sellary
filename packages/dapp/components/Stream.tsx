import React, {useEffect, useState} from "react"
import {Box, Badge, Text, Progress, InputGroup, Button, InputLeftElement, Input, InputRightAddon} from "@chakra-ui/react"
import { ExternalLinkIcon } from '@chakra-ui/icons'
import { IStream } from "@superfluid-finance/sdk-core"
import { Sellary__factory as SellaryFactory } from '@token/contracts'

import StreamFlow from './StreamFlow'
import { useWeb3 } from "./Web3Context"

interface StreamProps {
    stream: IStream,
}

const streamUrl = (tnxHash: string): string => (
    `https://app.superfluid.finance/streams/kovan/${tnxHash}/3/v1`
)

const shortenAdress = (str: string, len: number = 4): string => (
    `${str.slice(0, len)}...${str.slice(len * -1)}`
)

const Stream = ({ stream }: StreamProps) => {
    const [amount, setAmount] = useState(0)
    const tnxHash = stream.flowUpdatedEvents && stream.flowUpdatedEvents[0].transactionHash
    const daysRemaining = (amount / (+stream.currentFlowRate / 1e18)) / (3600 * 24)
    const { provider, account, signer } = useWeb3();

    useEffect(() => {
        (async () => {
            const sellary = SellaryFactory.connect(process.env.NEXT_PUBLIC_SF_SELLARY as string, provider)
            const balance = await sellary.balanceOf(account)
            console.log(balance.toString())
        })()
    })

    const sell = async () => {
        console.log(1)
        const sellary = SellaryFactory.connect(process.env.NEXT_PUBLIC_SF_SELLARY as string, signer)
        const tx = await sellary.issueSalaryNFT(account, Math.floor(Date.now() / 1000) + 60 * 60)
        console.log(tx)
        console.log(await tx.wait())
    }

    return (
        <Box maxW='sm' borderWidth='1px' borderRadius='lg' overflow='hidden'>
            <Box w='100%' bgGradient='linear(to-r, teal.500, green.500)'>
                <Box p='6'>
                    <StreamFlow stream={stream} />
                </Box>
            </Box>
            <Progress colorScheme='teal' size='xs' isIndeterminate />

            <Box p='6' bg='RGBA(255, 255, 255, 0.78)'>
                <Box
                    color='gray.500'
                    fontWeight='semibold'
                    letterSpacing='wide'
                    fontSize='xs'
                    mb='4'
                >
                    <a target='_blank' href={streamUrl(tnxHash)} rel="noreferrer">
                        ID: {shortenAdress(tnxHash, 8)}&nbsp;<ExternalLinkIcon />
                    </a>
                </Box>
                <Box display='flex' alignItems='baseline'>
                    <Text color='gray.600' fontSize='sm' mr='3'>From:</Text>
                    <Badge borderRadius='full' px='2' colorScheme='teal'>
                        {shortenAdress(stream.sender)}
                    </Badge>
                </Box>

                <Box display='flex' alignItems='baseline' isTruncated>
                    <Text color='gray.600' fontSize='sm' mr='3'>
                        Token:
                    </Text>
                    <Text fontSize='sm'>{stream.token.name}</Text>
                </Box>

                <Box mb='4' display='flex' isTruncated>
                    <Text color='gray.600' fontSize='sm' mr='3'>
                        Started at:
                    </Text>
                    <Text fontSize='sm'>{(new Date(stream.createdAtTimestamp * 1000)).toLocaleString()}</Text>
                </Box>
                <Box mb='4'>
                    <InputGroup>
                        <Input placeholder='Amount to sell' type='number' onChange={e => setAmount(+e.target.value)} />
                        <InputRightAddon>{stream.token.symbol}</InputRightAddon>
                    </InputGroup>
                    {daysRemaining ? (
                        <Text fontSize='sm' color='gray.800' as='i'>
                            Inflow of {daysRemaining.toFixed(0)} days
                        </Text>
                    ) : ''}
                </Box>
                <Button colorScheme='teal' width='100%' onClick={sell}>Sell</Button>
            </Box>
        </Box>
    )
}

export default Stream