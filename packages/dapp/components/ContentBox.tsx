import React from "react";
import {Text, Button, Link, Center} from '@chakra-ui/react'
import {DragHandleIcon} from "@chakra-ui/icons";
import {useWeb3} from "./Web3Context";
import {IStream} from "@superfluid-finance/sdk-core";


interface ContainerBoxProps {
    streams: IStream[],
}

const ContainerBox = ({streams}: ContainerBoxProps) => {
    const {account, connect} = useWeb3();

    return (
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
                streams && streams.length === 0 ?
                    <Button>
                        <Link href="https://app.superfluid.finance/" isExternal>
                            Check out Superfluid!
                        </Link>
                    </Button>
                    : ""}
        </Center>
    )
}
export default ContainerBox;