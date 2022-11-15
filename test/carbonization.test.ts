import { ethers, upgrades } from "hardhat"
import { expect } from "chai"
import chai from "chai"
import { solidity } from "ethereum-waffle"
import { stringToEth, ethToString } from "../utils/utils"
import { CarbonizedCollection, ERC20, MockNFT } from "../types"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { ERC20__factory } from "../types/factories/ERC20__factory"
import { formatEther, parseEther } from "ethers/lib/utils"

chai.use(solidity)

describe("Collection Carbonization Tests", function () {
  let collection: MockNFT
  let carbonizedCollection: CarbonizedCollection
  let eth: ERC20
  let accounts: SignerWithAddress[]

  this.beforeEach(async function () {
    accounts = await ethers.getSigners()

    const gTokenVaultAddress = "0x06a0CCFb89E9B2814afCA6637C22ed83909739Ee"

    // Deploy original collection
    const nftFactory = await ethers.getContractFactory("MockNFT")
    collection = (await nftFactory.deploy("mock", "mock", "https://ipfs")) as MockNFT

    // Deploy carbonizerDeployer
    const carbonizerDeployerFactory = await ethers.getContractFactory("CarbonizerDeployer")
    const carbonizerDeployer = await carbonizerDeployerFactory.deploy(gTokenVaultAddress)

    // Deploy CarbonizedCollection Contract
    const carbonizedCollectionFactory = await ethers.getContractFactory("CarbonizedCollection")
    let args = [
      collection.address,
      gTokenVaultAddress,
      carbonizerDeployer.address,
      "Carbonized Mock",
      "NFT02",
      "https://ipfs",
    ]
    carbonizedCollection = (await upgrades.deployProxy(
      carbonizedCollectionFactory,
      args
    )) as CarbonizedCollection
    // set approval for carbonizedContract to transfer original collection
    await expect(
      collection.setApprovalForAll(carbonizedCollection.address, true)
    ).to.not.be.reverted
  })

  it("Carbonize original collection", async function () {
    console.log(formatEther(await accounts[0].getBalance()))
    await (await carbonizedCollection.carbonize(1, { value: parseEther("10") })).wait()
  })
})
