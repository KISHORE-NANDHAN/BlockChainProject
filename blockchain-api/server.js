const express = require("express");
const cors = require("cors");
const landRoutes = require("./routes/landRoutes");

const app = express();
app.use(cors());
app.use(express.json());

app.use("/api", landRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Blockchain API Server running on port ${PORT}`);
});
