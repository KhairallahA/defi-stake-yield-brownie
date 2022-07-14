import React from 'react';
import { DAppProvider, ChainId } from '@usedapp/core';
import { Header } from "./components/Header";
import { Main } from "./components/Main";
import { Container } from "@material-ui/core";

function App() {
  return (
    <DAppProvider config={{
      supportedChains: [ChainId.Kovan, ChainId.Rinkeby]
    }}>
      <div className="App">
        <Header />
        <Container maxWidth="md">
          <Main />
        </Container>
      </div>
    </DAppProvider>
    
  );
}

export default App;
