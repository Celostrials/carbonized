import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import { deployProxyAndSave } from "../utils/utils"
import { deployments, upgrades, ethers } from "hardhat"
import { CarbonizedCollectionV3__factory } from "../types/factories/CarbonizedCollectionV3__factory"

const func: DeployFunction = async function (hardhat: HardhatRuntimeEnvironment) {
  const CarbonizedCollectionV3 = await ethers.getContractFactory("CarbonizedCollectionV3")
  const CarbonizedCollectionV3Abi = CarbonizedCollectionV3__factory.abi

  const proxy = await deployments.get("CarbonizedCollectionV2")
  let carbonizedCollectionV3

  try {
    carbonizedCollectionV3 = await upgrades.upgradeProxy(proxy.address, CarbonizedCollectionV3)
  } catch (e) {
    console.log(e)
  }

  const contractDeployment = {
    address: carbonizedCollectionV3.address,
    abi: CarbonizedCollectionV3Abi,
    receipt: await carbonizedCollectionV3.deployTransaction.wait(),
  }

  hardhat.deployments.save("CarbonizedCollectionV3", contractDeployment)
  console.log("🚀  Carbonized Collection Upgraded to V3")
}

export default func

func.tags = ["CARBONIZED-upgrade-3"]
