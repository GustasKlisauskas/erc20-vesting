const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ERC20", () => {
  let deployer;
  let contract;
  beforeEach(async () => {
    accounts = await ethers.getSigners();
    deployer = accounts[0];
    const Contract = await ethers.getContractFactory("FutugoToken");
    contract = await Contract.deploy(150000000);
  });
  it("Should deploy correct amount of tokens", async () => {
    const balance = await contract.balanceOf(deployer.address);
    expect(balance).to.equal(150000000);
  });
});

describe("Lock", () => {
  let contract, contract2;
  let deployer;
  beforeEach(async () => {
    accounts = await ethers.getSigners();
    deployer = accounts[0];
    const Contract2 = await ethers.getContractFactory("FutugoToken");
    contract2 = await Contract2.deploy(150000000);
    const Contract = await ethers.getContractFactory("Lock");
    contract = await Contract.deploy(
      accounts[1].address,
      accounts[1].address,
      accounts[1].address,
      accounts[1].address,
      accounts[1].address,
      accounts[1].address,
      accounts[1].address,
      accounts[1].address,
      contract2.address
    );
    await contract2.transfer(contract.address, 150000000);
  });

  it("Should receive erc20 tokens", async () => {
    const tokens = await contract2.balanceOf(contract.address);
    expect(tokens).to.equal(150000000);
  });

  it("Correct public buy TGE", async () => {
    await contract.publicBuy(100, {
      value: ethers.utils.parseEther("45"),
    });
    const quantity = await contract2.balanceOf(deployer.address);
    expect(quantity).to.equal(25);
  });
  it("Correct private buy TGE", async () => {
    await contract.privateBuy(100, {
      value: ethers.utils.parseEther("20"),
    });
    const quantity = await contract2.balanceOf(deployer.address);
    expect(quantity).to.equal(5);
  });
  it("Correct seed buy TGE", async () => {
    await contract.seedBuy(100, {
      value: ethers.utils.parseEther("25"),
    });
    const quantity = await contract2.balanceOf(deployer.address);
    expect(quantity).to.equal(5);
  });
  it("Should fail - not enough ether", async () => {
    await expect(
      contract.publicBuy(100, {
        value: ethers.utils.parseEther("2"),
      })
    ).to.be.revertedWith("Not enough ether");
  });
  it("Should be locked by Cliff", async () => {
    await contract.publicBuy(100, {
      value: ethers.utils.parseEther("45"),
    });
    await network.provider.send("evm_increaseTime", [5000000]);
    await network.provider.send("evm_mine");
    const amount = await contract._withdrawableAmount(deployer.address);
    expect(amount).to.equal(0);
  });
  it("Should unlock cliff", async () => {
    await contract.publicBuy(100, {
      value: ethers.utils.parseEther("45"),
    });
    await network.provider.send("evm_increaseTime", [5590000]);
    await network.provider.send("evm_mine");
    const quantity = await contract2.balanceOf(deployer.address);
    const amount = await contract._withdrawableAmount(deployer.address);
    expect(quantity).to.equal(25);
    expect(amount).to.equal(1);
  });
  it("Should unlock no more than limit", async () => {
    await contract.publicBuy(100, {
      value: ethers.utils.parseEther("45"),
    });
    await network.provider.send("evm_increaseTime", [21040000]);
    await network.provider.send("evm_mine");
    const amount = await contract._withdrawableAmount(deployer.address);
    expect(amount).to.equal(75);
  });
  it("Should double amount - 2nd purchase", async () => {
    await contract.publicBuy(100, {
      value: ethers.utils.parseEther("45"),
    });
    await contract.publicBuy(100, {
      value: ethers.utils.parseEther("45"),
    });
    await network.provider.send("evm_increaseTime", [21040000]);
    await network.provider.send("evm_mine");
    const amount = await contract._withdrawableAmount(deployer.address);
    expect(amount).to.equal(100);
  });
  it("Should subtract withdrawal", async () => {
    await contract.publicBuy(100, {
      value: ethers.utils.parseEther("45"),
    });
    await network.provider.send("evm_increaseTime", [21040000]);
    await network.provider.send("evm_mine");
    await contract.withdraw(65);
    const amount = await contract._withdrawableAmount(deployer.address);
    expect(amount).to.equal(10);
  });
  it("Shouldn't let user withdraw without subtracting withdrawn", async () => {
    await contract.publicBuy(100, {
      value: ethers.utils.parseEther("45"),
    });
    await network.provider.send("evm_increaseTime", [21040000]);
    await network.provider.send("evm_mine");
    await contract.withdraw(65);
    await expect(contract.withdraw(20)).to.be.revertedWith(
      "Not enough balance"
    );
  });
  it("Should send correct erc20 amount", async () => {
    await contract.publicBuy(100, {
      value: ethers.utils.parseEther("45"),
    });
    await network.provider.send("evm_increaseTime", [21040000]);
    await network.provider.send("evm_mine");
    await contract.withdraw(65);
    const balance = await contract2.balanceOf(deployer.address);
    expect(balance).to.equal(90);
    const balance2 = await contract2.balanceOf(contract.address);
    expect(balance2).to.equal(150000000 - 90);
    await contract.withdraw(10);
    const balance3 = await contract2.balanceOf(deployer.address);
    expect(balance3).to.equal(100);
    const balance4 = await contract2.balanceOf(contract.address);
    expect(balance4).to.equal(150000000 - 100);
  });
});
