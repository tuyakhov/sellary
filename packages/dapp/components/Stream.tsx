import React from "react";
import { Box, Badge, Flex, Heading, Image } from "@chakra-ui/react";
import { IStream } from "@superfluid-finance/sdk-core"

interface StreamProps {
    stream: IStream
}

const Stream = ({ stream }: StreamProps) => {
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
                    {stream.currentFlowRate}
                </Box>

                <Box>
                {stream.token.name}
                <Box as='span' color='gray.600' fontSize='sm'>
                    / wk
                </Box>
                </Box>
            </Box>
        </Box>
    )
}

export default Stream