

Submission to ETH Global NFT Hackathon 03/2021

---

# 🏃‍♀️ Quick Start

required: [Node](https://nodejs.org/dist/latest-v12.x/) plus [Yarn](https://classic.yarnpkg.com/en/docs/install/) and [Git](https://git-scm.com/downloads)


```bash
git clone https://github.com/austintgriffith/scaffold-eth.git

cd scaffold-eth
```

```bash

yarn install

```

```bash

yarn start

```

> in a second terminal window:

```bash
cd scaffold-eth
yarn chain

```

> in a third terminal window:

```bash
cd scaffold-eth
yarn deploy

```
## Onchain Community Management via ENS Domain NFTs
### Motivation
ENS NFTs for semantic onchain community directories and token permissioned functionality. Each community member gets an NFT that represents their domain and membership within the community like normal .eth domains.

Can be used with multiple subdomains for different groups e.g. multisig.mydao.eth and members.mydao.eth


The UI is intended as a simple interface for admins and operations people to manage community members. This contract is intended for more backend integrations with other smart contracts and applications:
 - Dynamic white list for smart contract integrations - For example only letting community members add liquidity to a Balancer Smart Pool with a single 1 line integration and no hardcoded addresses.
 - Supercharge core community votes - Next I'll create a Snapshot strategy that gives a 2x voting bonus to addresses that are registered as members on a DAOs onchain directory.
 - Social networks - Assuming someone uses the same name/address across multiple communities you can use The Graph to construct a social graph of people that share communities. This can be used for friend recommendations, web of trust (posts/messages only show if you share enough communities together), etc. all using onchain data (very cool and very dangerous)
## Example Usage
In smart contracts
```sol
import {ICommunityManager} from '../interfaces/ICommunityManager';

contract MyContract {
  ICommunityManager manager
  constructor(ICommunityManager _manager) public {
    manager = _manager;
  }

  function doCommunityThing() external {
    require(manager.isMember(msg.sender), 'This function is only for our community :P');
  }

  function doAdminThing() external {
    require(manager.isAdmin(msg.sender), 'This function is only for admins');
  }
}
```
In webapps

```js
import  ethers from 'ethers';
import  { labelhash } from '@ensdomain/ens';
import  { CommunityManager } from '../abis/CommunityManager.json';

const manager = (await new ethers.ContractFactory(
  CommunityManager.abi ,
  CommunityManager.byteCode
)).attach(CommunityManagerAddress);

const amIAnAdmin = await manager.isAdmin(provider.adress);
if(amIAnAdmin) {
  await manager.addMember(myFriendsAddress, labelhash('newmember'))
}
```

### Creating/Getting Roles
In V2 roles will be namespaced with you community's domain so you call `setRole(memberAddress, abi.encodePacked(node, keccack256(roleName)))`


