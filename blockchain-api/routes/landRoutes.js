const express = require("express");
const router = express.Router();
const { createLandRequest, getLandRequest } = require("../controller/landController");

router.post("/create", createLandRequest);
router.get("/get/:id", getLandRequest);

module.exports = router;
