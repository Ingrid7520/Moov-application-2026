async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Déploiement avec le compte:", deployer.address);
  
  const AgriSmartTraceability = await ethers.getContractFactory("AgriSmartTraceability");
  const contract = await AgriSmartTraceability.deploy();
  
  await contract.waitForDeployment();
  
  console.log("Contrat déployé à l'adresse:", await contract.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });