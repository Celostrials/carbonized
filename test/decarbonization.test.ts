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

describe("Decarbonization Tests", function () {
  let collection: MockNFT
  let gEth: ERC20
  let carbonizedCollection: CarbonizedCollection
  let accountA: SignerWithAddress

  this.beforeEach(async function () {
    let accounts = await ethers.getSigners()
    let deployer = accounts[0]
    accountA = accounts[1]

    const gEthAddress = "0x06a0CCFb89E9B2814afCA6637C22ed83909739Ee"

    gEth = ERC20__factory.connect(gEthAddress, accountA)

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

  it("Starting decarbonization creates a withdraw", async function () {})

  it("Claiming before decarbonization has finished reverts", async function () {})

  it("Claiming after decarbonization has finished returns deposit", async function () {})

  it("Carbonizing a once carbonized tokenId reuses Carbonizer contract", async function () {})
})
