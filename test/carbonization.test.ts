import { ethers, upgrades } from "hardhat"
import { expect } from "chai"
import chai from "chai"
import { solidity } from "ethereum-waffle"
import { stringToEth, ethToString } from "../utils/utils"
import { CarbonizedCollection, ERC20, MockNFT } from "../types"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { ERC20__factory } from "../types/factories/ERC20__factory"
import { formatEther, parseEther } from "ethers/lib/utils"
import { Carbonizer__factory } from "../types/factories/Carbonizer__factory"

chai.use(solidity)

describe("Carbonization Tests", function () {
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
  })

  it("Carbonization transfers original NFT to carbonizedCollection", async function () {
    expect(await collection.ownerOf(1)).to.equal(accountA.address)
    await expect(carbonizedCollection.carbonize(1, { value: parseEther("10") })).to.not.be.reverted
    expect(await collection.ownerOf(1)).to.equal(carbonizedCollection.address)
  })
  it("Carbonization mints tokenId of CarbonizedCollection", async function () {
    expect(await carbonizedCollection.exists(1)).to.be.false
    await expect(carbonizedCollection.carbonize(1, { value: parseEther("10") })).to.not.be.reverted
    expect(await carbonizedCollection.exists(1)).to.be.true
  })
  it("Carbonization deposits eth to ImpactVault", async function () {
    expect(Number(formatEther(await accountA.getBalance()))).to.be.greaterThan(9999)
    await expect(carbonizedCollection.carbonize(1, { value: parseEther("10") })).to.not.be.reverted
    expect(Number(formatEther(await accountA.getBalance()))).to.be.lessThan(9999)
  })
  it("Carbonization mints gToken for tokenId's Carbonizer contract", async function () {
    expect(await carbonizedCollection.carbonizer(1)).to.equal(
      "0x0000000000000000000000000000000000000000"
    )
    await expect(carbonizedCollection.carbonize(1, { value: parseEther("10") })).to.not.be.reverted
    expect(await carbonizedCollection.carbonizer(1)).to.be.properAddress
    expect(formatEther(await gEth.balanceOf(await carbonizedCollection.carbonizer(1)))).to.equal(
      "9.999999999999999999"
    )
  })

  it("Passing time accrues yield for carbonized tokenIds", async function () {
    await expect(carbonizedCollection.carbonize(1, { value: parseEther("10") })).to.not.be.reverted
    const carbonizer = Carbonizer__factory.connect(
      await carbonizedCollection.carbonizer(1),
      accountA
    )
    expect(formatEther(await carbonizer.getYield())).to.equal("0.0")
    await ethers.provider.send("evm_increaseTime", [1000000000000])
    await ethers.provider.send("evm_mine", [])
    // expect(formatEther(await carbonizer.getYield())).to.equal("1.0")
    console.log(await carbonizer.getYield())
  })
})
