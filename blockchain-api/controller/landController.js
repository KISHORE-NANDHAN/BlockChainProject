const connectToGateway = require("../fabric/gateway");

exports.createLandRequest = async (req, res) => {
  try {
    const { id, name, village, status } = req.body;
    const contract = await connectToGateway();
    await contract.submitTransaction("createRequest", id, name, village, status);
    res.status(200).json({ message: "Land Request created on blockchain" });
  } catch (error) {
    console.error("Create Error:", error);
    res.status(500).json({ error: "Failed to create request" });
  }
};

exports.getLandRequest = async (req, res) => {
  try {
    const contract = await connectToGateway();
    const data = await contract.evaluateTransaction("getRequest", req.params.id);
    res.status(200).json(JSON.parse(data.toString()));
  } catch (error) {
    console.error("Get Error:", error);
    res.status(500).json({ error: "Failed to fetch request" });
  }
};
