import { useEthers } from "@usedapp/core";
import helperConfig from "../helper-config.json";

export const Main = () => {
    // Show tokens value from the wallet
    // Get the address of different tokens
    // Get the balance of the users wallet

    // send the brownie-config to our `src` folder
    // send the build folder
    const { chainId, error } = useEthers();
    const networkName = chainId ? helperConfig[chainId] : "dev";

    console.log(chainId);
    console.log(networkName);
    return (<div>HI!</div>);
}