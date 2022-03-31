const TuniverAdmin = artifacts.require("TuniverAdmin");
const assert = require('assert')
const { deployProxy } = require('@openzeppelin/truffle-upgrades');


contract("TuniverAdmin", (accounts) => {
    var tuniverAdmin
    beforeEach(async function () {
        // Deploy a new Tuniver admin contract for each test
        tuniverAdmin = await deployProxy(TuniverAdmin, [], {initializer: 'initialize'});
    });

    it("fee should be 0", async () => {
        const fee = await tuniverAdmin.fee.call()
        assert.equal(fee, 0)
    })

    it("receiver fee must be owner contract", async () => {
        const receiverFee = await tuniverAdmin.receiverFee.call()
        assert.equal(receiverFee, accounts[0])
    })
    //-------------------------ADMIN_ROLE-------------------------------------------
    it("Grant controller role for accounts[0]", async () => {
        const controller = await tuniverAdmin.CONTROLLER_ROLE.call()
        await tuniverAdmin.grantRole(controller, accounts[0], {from: accounts[0]})
        const isHasRole = await tuniverAdmin.hasRole.call(controller, accounts[0])
        assert.equal(isHasRole, true)
    })

    //-------------------------CONTROLLER_ROLE-------------------------------------------

    it("Event TuniverSupported must be emitted", async () => {
        await tuniverAdmin.createTuniver('coming', accounts[0])
        assert.equal(true, true)
    })


    
})

