# Super Socks

> This is in development

## Onchain SVG Socks

- Create custom socks!
- Base sock with ability to add flexible designs

TODO:
- Robustness - DONE
- More designs! Maybe make the socks look nicer? - DONE
- Move to 1155 - DONE
- Clean "studio" page - FIRSTPASS
- Explore page - DONE
- Profile page - DONE
- Give "creators" a share of the minting proceeds for socks they create - DONE
- Add Uniswap swapping for USDC - DONE
- Add Ponder indexer - DONE
- Add "Basket" flow - DONE
- Enable withdraw creator balance
- Add meaning to the attributes on the sock pages
- Allow users to transfer their socks
- Allow users to buy socks for other people

MINTING FLOWS:
- Basic (approve then swap) - DONE
- 5792 (approve + swap in one tx) - DONE
- From ETH
    - Swap from ETH then buy
    - Intermediary contract - DONE
    - Swap from ETH then buy in one tx via 5792
- From other chains
    - Send to bridge
    - Approve then bridge then buy
    - Approve then bridge + call to buy
- Daimo pay
- Biconomy

## Running locally
```
yarn install

# Run the chain
yarn fork

# Deploy the contracts
yarn compile
yarn deploy

# Run the Ponder indexer
cd packages/supersocks-api
yarn dev

# Start the app
yarn start
```