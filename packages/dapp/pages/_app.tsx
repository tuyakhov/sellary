import "./app.css";
import type { AppProps } from "next/app";
import { ChakraProvider, extendTheme } from "@chakra-ui/react";
import { Web3Provider } from "../components/Web3Context";

const theme = extendTheme({
  config: {
    initialColorMode: "light",
    useSystemColorMode: false,
  },
  fonts: {
    heading: "Moderna Sans Medium Ext",
    body: "Roboto Regular",
    // textTransform: "uppercase",
  },
  styles: {
    global: {
      'html, body': {
        // background: "radial-gradient(105.56% 267.03% at -5.56% 130.2%, rgba(18, 187, 51, 0.4) 0%, rgba(194, 234, 187, 0.4) 23.8%, rgba(67, 160, 65, 0.4) 47.37%, rgba(186, 237, 146, 0.4) 69.37%, rgba(18, 187, 51, 0.4) 100%)"
      }
    },
  },
  colors: {},
  components: {},
});


function MyApp({ Component, pageProps }: AppProps) {
  return (
    <ChakraProvider theme={theme}>
      <Web3Provider>
        <Component {...pageProps} />
      </Web3Provider>
    </ChakraProvider>
  );
}

export default MyApp;
