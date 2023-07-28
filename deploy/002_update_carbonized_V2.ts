import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import { deployProxyAndSave } from "../utils/utils"
import { deployments, upgrades, ethers } from "hardhat"
import { CarbonizedCollectionV2__factory } from "../types/factories/CarbonizedCollectionV2__factory"

const func: DeployFunction = async function (hardhat: HardhatRuntimeEnvironment) {
  const CarbonizedCollectionV2 = await ethers.getContractFactory("CarbonizedCollectionV2")
  const CarbonizedCollectionV2Abi = CarbonizedCollectionV2__factory.abi

  const proxy = await deployments.get("CarbonizedCollection")
  let carbonizedCollectionV2

  try {
    carbonizedCollectionV2 = await upgrades.upgradeProxy(proxy.address, CarbonizedCollectionV2)
  } catch (e) {
    console.log(e)
  }

  const contractDeployment = {
    address: carbonizedCollectionV2.address,
    abi: CarbonizedCollectionV2Abi,
    receipt: await carbonizedCollectionV2.deployTransaction.wait(),
  }

  hardhat.deployments.save("CarbonizedCollectionV2", contractDeployment)
  console.log("🚀  Carbonized Collection Upgraded to V2")
}

export default func

func.tags = ["CARBONIZED-upgrade-2"]
