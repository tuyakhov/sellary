import React, {useEffect, useState} from "react";
import {Box, Badge, Flex, Heading, Image, Button, Container} from "@chakra-ui/react";
import { IStream } from "@superfluid-finance/sdk-core"

interface StreamProps {
    stream: IStream,
    nextTokenId: string | undefined
}

const Stream = ({ stream, nextTokenId }: StreamProps) => {
    const [seconds, setSeconds] = useState(0);
    const [isActive, setIsActive] = useState(false);

    useEffect(() => {
        let interval: number | NodeJS.Timeout | null = null;
            interval = setInterval(() => {
                setSeconds(seconds => seconds + 1);
            }, 1000);

    }, [isActive, seconds]);

    return (
        <Box maxW='sm' borderWidth='1px' borderRadius='lg' overflow='hidden'>
            <Image src="https://picsum.photos/200" alt={stream.token} />

            <Box p='6'>
                <Box display='flex' alignItems='baseline'>
                <Badge borderRadius='full' px='2' colorScheme='teal'>
                    {stream.receiver}
                </Badge>
                <Box
                    color='gray.500'
                    fontWeight='semibold'
                    letterSpacing='wide'
                    fontSize='xs'
                    textTransform='uppercase'
                    ml='2'
                >
                    {stream.id}
                </Box>
                </Box>

                <Box
                mt='1'
                fontWeight='semibold'
                as='h4'
                lineHeight='tight'
                isTruncated
                >
                    {/*TODO refactor this with a bit more sleep*/}
                    {(stream.streamedUntilUpdatedAt + ((Math.floor(Date.now() / 1000)) - stream.updatedAtTimestamp)
                    * stream.currentFlowRate)
                    / 1000000000000000000}
                </Box>

                <Box>
                {stream.token.name}
                <Box as='span' color='gray.600' fontSize='sm'>
                    / wk
                </Box>
                </Box>
                <Button onClick={() => {}} disabled={!nextTokenId}>mint {nextTokenId}</Button>
            </Box>
        </Box>
    )
}

export default Stream