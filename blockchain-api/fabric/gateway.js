const { Gateway, Wallets } = require("fabric-network");
const path = require("path");
const fs = require("fs");

const connectToGateway = async () => {
  const ccpPath = path.resolve(__dirname, "../config/connection-org1.json");
  const ccp = JSON.parse(fs.readFileSync(ccpPath, "utf8"));

  const walletPath = path.join(__dirname, "../wallet");
  const wallet = await Wallets.newFileSystemWallet(walletPath);

  const identity = await wallet.get("appUser");
  if (!identity) throw new Error("appUser identity not found in wallet");

  const gateway = new Gateway();
  await gateway.connect(ccp, {
    wallet,
    identity: "appUser",
    discovery: { enabled: true, asLocalhost: true },
  });

  const network = await gateway.getNetwork("mychannel");
  const contract = network.getContract("landrequest");
  return contract;
};

module.exports = connectToGateway;
