import React, {useEffect, useState} from "react";
import { Text, Box } from '@chakra-ui/react'
import { IStream } from "@superfluid-finance/sdk-core"

interface StreamFlowProps {
    stream: IStream,
}

const StreamFlow = ({ stream }: StreamFlowProps) => {
    const [flow, setFlow] = useState(0);
    useEffect(() => {
        let interval: NodeJS.Timeout;
            interval = setInterval(() => {
                setFlow(
                    (+stream.streamedUntilUpdatedAt + ((Math.floor(Date.now() / 1000)) - stream.updatedAtTimestamp)
                    * +stream.currentFlowRate)
                    / 1e18 
                );
            }, 10);
        return () => {
            clearInterval(interval)
        }
    }, [stream]);

    const flowRate = (+stream.currentFlowRate / 1e18) * 3600 * 24

    return (
        <Box color='white'>
            <Box>
                <Text fontSize='sm' textTransform='uppercase'>Stream inflow ⚡️</Text>
                <Box display='flex' alignItems='center'>
                    <Text fontSize='2xl'><b>{flow.toFixed(8)}</b></Text>
                    &nbsp;
                    <Text fontSize='xl' as='samp'>{stream.token.symbol}</Text>
                </Box>    
            </Box>
            <Box mt='4'>
                <Text fontSize='sm' textTransform='uppercase'>Flow rate 🌱</Text>
                <Box display='flex' alignItems='center'>
                    <Text fontSize='2xl'><b>{flowRate.toFixed(2)}</b></Text>
                    &nbsp;
                    <Text fontSize='xl' as='samp'>/day</Text>
                </Box>  
            </Box>
        </Box>
    )

}

export default StreamFlow