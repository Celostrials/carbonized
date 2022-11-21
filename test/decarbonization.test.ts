import { ethers, upgrades, network } from "hardhat"
import { expect } from "chai"
import chai from "chai"
import { solidity } from "ethereum-waffle"
import { stringToEth, ethToString } from "../utils/utils"
import { CarbonizedCollection, Carbonizer__factory, MockNFT } from "../types"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { formatEther, parseEther } from "ethers/lib/utils"

chai.use(solidity)

describe("Decarbonization Tests", function () {
  let collection: MockNFT
  let carbonizedCollection: CarbonizedCollection
  let accountA: SignerWithAddress

  this.beforeEach(async function () {
    let accounts = await ethers.getSigners()
    let deployer = accounts[0]
    accountA = accounts[1]

    const gEthAddress = "0x06a0CCFb89E9B2814afCA6637C22ed83909739Ee"

    // Deploy original collection
    const nftFactory = await ethers.getContractFactory("MockNFT")
    collection = (await nftFactory.deploy("mock", "mock", "https://ipfs")) as MockNFT

    // Deploy carbonizerDeployer
    const carbonizerDeployerFactory = await ethers.getContractFactory("CarbonizerDeployer")
    const carbonizerDeployer = await carbonizerDeployerFactory.deploy(gEthAddress)

    // Deploy CarbonizedCollection Contract
    const carbonizedCollectionFactory = await ethers.getContractFactory("CarbonizedCollection")
    let args = [
      collection.address,
      carbonizerDeployer.address,
      "Carbonized Mock",
      "NFT02",
      "https://ipfs",
    ]
    carbonizedCollection = (await upgrades.deployProxy(
      carbonizedCollectionFactory,
      args
    )) as CarbonizedCollection
    carbonizedCollection = carbonizedCollection.connect(accountA)

    // transfer tokenId 1 to account A
    await expect(collection.transferFrom(deployer.address, accountA.address, 1)).to.not.be.reverted
    // accountA set approval for carbonizedContract to transfer original collection
    await expect(
      collection.connect(accountA).setApprovalForAll(carbonizedCollection.address, true)
    ).to.not.be.reverted

    // carboinze tokenId 1
    await expect(carbonizedCollection.carbonize(1, { value: parseEther("10") })).to.not.be.reverted
  })

  it("Starting decarbonization creates a withdrawal", async function () {
    // await expect(carbonizedCollection.startDecarbonize(1)).to.not.be.reverted
    // await (await carbonizedCollection.startDecarbonize(1)).wait()

    const carbonizer = Carbonizer__factory.connect(
      await carbonizedCollection.carbonizer(1),
      accountA
    )
    console.log(ethers.provider.blockNumber)
    await ethers.provider.send("hardhat_mine", ["0x3e8"])
    await ethers.provider.send("evm_mine", [])

    console.log(ethers.provider.blockNumber)
    console.log(await carbonizer.getYield())
    console.log(await carbonizer.withdrawls())
  })

  // it("Claiming before decarbonization has finished reverts", async function () {})

  // it("Claiming after decarbonization has finished returns deposit", async function () {})

  // it("Carbonizing a once carbonized tokenId reuses Carbonizer contract", async function () {})
})
