const Web3 = require("web3");
const assert = require('assert')
const ganache = require('ganache-cli')
const Tuniver = artifacts.require("Tuniver");
const web3 = new Web3(ganache.provider)


contract("TuniverToken", (accounts) => {
    
    it("Tuniver deployed", async() => {
        const instance = await Tuniver.deployed()
        const name = await instance.name.call()
        const balance = await instance.balanceOf.call(accounts[0])
        console.log(balance)
        const symbol = await instance.symbol.call()
        await instance.transfer(accounts[1], 10000, {from: accounts[0]})
        const balanceAfter = await instance.balanceOf.call(accounts[0])
        assert.notEqual(name, balance.toString(), "It shouldn't be equal")
        assert.notEqual(name, symbol, "It shouldn't be equal")
        assert.equal(parseInt(balance.toString()) - 10000, parseInt(balanceAfter.toString()))
    })
})

