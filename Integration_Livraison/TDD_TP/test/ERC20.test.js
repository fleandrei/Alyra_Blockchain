// erc20.test.js
const { BN, ether } = require('@openzeppelin/test-helpers'); // BN: Big Number
const { expect } = require('chai');
const ERC20 = artifacts.require('ERC20Token');



contract('ERC20', function (accounts) { //contract renvoie un tableau des accounts disponibles renvoyé par le client
	const _name = 'ALYRA';
	const _symbol = 'ALY';
	const _initialsupply = new BN(1000);
	const _decimals = new BN(18);
	const owner = accounts[0];
	const recipient = accounts[1];
	const recipient_bis = accounts[2];
 
	 beforeEach(async function () {
	 this.ERC20Instance = await ERC20.new(_initialsupply,{from: owner});
	 });

	it('a un nom', async function () {
	 expect(await this.ERC20Instance.name()).to.equal(_name);
	});
	it('a un symbole', async function () {
	 expect(await this.ERC20Instance.symbol()).to.equal(_symbol);
	});
	it('a une valeur décimal', async function () {
	 expect(await this.ERC20Instance.decimals()).to.be.bignumber.equal(_decimals);
	});
	it('vérifie la balance du propriétaire du contrat', async function (){
	 let balanceOwner = await this.ERC20Instance.balanceOf(owner);
	 let totalSupply = await this.ERC20Instance.totalSupply();
	expect(balanceOwner).to.be.bignumber.equal(totalSupply);
	});
	it('vérifie si un transfer est bien effectué', async function (){
	 let balanceOwnerBeforeTransfer = await this.ERC20Instance.balanceOf(owner);
	 let balanceRecipientBeforeTransfer = await this.ERC20Instance.balanceOf(recipient);
	 let amount = new BN(10);
	 await this.ERC20Instance.transfer(recipient, amount, {from: owner});
	 let balanceOwnerAfterTransfer = await this.ERC20Instance.balanceOf(owner);
	 let balanceRecipientAfterTransfer = await this.ERC20Instance.balanceOf(recipient);
	 
	 expect(balanceOwnerAfterTransfer).to.be.bignumber.equal(balanceOwnerBeforeTransfer.sub(amount));
	 expect(balanceRecipientAfterTransfer).to.be.bignumber.equal(balanceRecipientBeforeTransfer.add(amount));
	});


	it("Vérifie fonction approve", async function (){
		const amount = new BN(10);
		await this.ERC20Instance.approve(recipient, amount, {from:owner});

		const allowance = await this.ERC20Instance.allowance(owner, recipient);

		expect(allowance).to.be.bignumber.equal(amount);
	});
	it("Vérifie fonction transferFrom", async function (){
		const AllowanceAmount = new BN(10);
		const TransferAmount = new BN(10);
		await this.ERC20Instance.approve(recipient, AllowanceAmount, {from:owner});

		const balanceOwnerBeforeTransfer = await this.ERC20Instance.balanceOf(owner);
		const balanceRecientBisBeforeTransfer = await this.ERC20Instance.balanceOf(recipient_bis);


		await this.ERC20Instance.transferFrom(owner, recipient_bis, TransferAmount, {from:recipient});
		
		const balanceRecipientBisAfterTransfer = await this.ERC20Instance.balanceOf(recipient_bis);
		const balanceOwnerAfterTransfer = await this.ERC20Instance.balanceOf(owner);
		const allowanceRecipient= await this.ERC20Instance.allowance(owner, recipient);

		expect(balanceRecipientBisAfterTransfer).to.be.bignumber.equal(balanceRecientBisBeforeTransfer.add(TransferAmount));
		expect(balanceOwnerAfterTransfer).to.be.bignumber.equal(balanceOwnerBeforeTransfer.sub(TransferAmount));
		expect(allowanceRecipient).to.be.bignumber.equal(AllowanceAmount.sub(TransferAmount));
	});
});