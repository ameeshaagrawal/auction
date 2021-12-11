// node/no-unpublished-require
const { ethers } = require("hardhat");

async function main() {
  const bettingPeriod = 2 * 24 * 60 * 60;
  const taskSettlementPeriod = 2 * 24 * 60 * 60;

  const Auction = await ethers.getContractFactory("Auction");
  const auction = await Auction.deploy(bettingPeriod, taskSettlementPeriod);

  await auction.deployed();

  console.log("Auction contract deployed to:", auction.address);
}

module.exports = main;
