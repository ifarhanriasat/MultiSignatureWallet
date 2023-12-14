const MultiSigWallet = artifacts.require("MultiSigWallet");

contract("MultiSigWallet", (accounts) => {
    let wallet;
    const [owner, signer1, signer2, nonSigner] = accounts;
    
    beforeEach(async () => {
        wallet = await MultiSigWallet.new([signer1, signer2], 2);
    });

    it("should initialize with correct signers and quorum", async () => {
        assert.equal(await wallet.isSigner(signer1), true, "Signer1 should be a signer");
        assert.equal(await wallet.isSigner(signer2), true, "Signer2 should be a signer");
        assert.equal(await wallet.quorum(), 2, "Quorum should be 2");
    });

    it("should allow to propose a transaction", async () => {
        await wallet.proposeTransaction(nonSigner, 1000, "0x00", { from: nonSigner });
        const tx = await wallet.transactions(0);
        assert.equal(tx.destination, nonSigner, "Destination address should match");
        assert.equal(tx.value, 1000, "Value should match");
    });

    it("should allow signers to approve transaction", async () => {
        await wallet.proposeTransaction(nonSigner, 1000, "0x00", { from: nonSigner });
        await wallet.approveTransaction(0, { from: signer1 });
        const tx = await wallet.transactions(0);
        assert.equal(tx.signatureCount, 1, "Signature count should be 1");
    });

    it("should not allow non-signers to approve transaction", async () => {
        await wallet.proposeTransaction(nonSigner, 1000, "0x00", { from: nonSigner });
        try {
            await wallet.approveTransaction(0, { from: nonSigner });
            assert.fail("Non-signer should not be able to approve");
        } catch (error) {
            assert.include(error.message, "revert", "Error message should contain 'revert'");
        }
    });

    it("should execute a transaction when quorum is met", async () => {
        await wallet.proposeTransaction(nonSigner, 1000, "0x00", { from: nonSigner });
        await wallet.approveTransaction(0, { from: signer1 });
        await wallet.approveTransaction(0, { from: signer2 });
        await wallet.executeTransaction(0, { from: signer1 });

        const tx = await wallet.transactions(0);
        assert.equal(tx.executed, true, "Transaction should be executed");
    });

    it("should not execute a transaction when quorum is not met", async () => {
        await wallet.proposeTransaction(nonSigner, 1000, "0x00", { from: nonSigner });
        await wallet.approveTransaction(0, { from: signer1 });

        try {
            await wallet.executeTransaction(0, { from: signer1 });
            assert.fail("Should not execute without quorum");
        } catch (error) {
            assert.include(error.message, "revert", "Error message should contain 'revert'");
        }
    });

    // Additional test cases can include testing for re-approvals, invalid transactions, etc.
});

