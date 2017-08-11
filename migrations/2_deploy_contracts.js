const MultiSigWallet = artifacts.require("MultiSigWallet");
const MiniMeTokenFactory = artifacts.require("MiniMeTokenFactory");
const ATT = artifacts.require("ATT");
const ATTContribution = artifacts.require("ATTContribution");
const ContributionWallet = artifacts.require("ContributionWallet");
const AngelTokensHolder = artifacts.require("AngelTokensHolder");
const ATTPlaceHolder = artifacts.require("ATTPlaceHolder");

// All of these constants need to be configured before deploy
/*
const addressesEthFoundation = [
    "0xF67ab97Ec3927a2F5D07129630C9A0f36d2738D0",
    "0xcbBD91Ed3377b61a5167C30C256429B2fD33d42f",
    "0x009514B270457718478Ab860B41A3c1ed290a2b0",
    "0x69A009FFb0627d60Ae9D253346d25B86A6731069",
    "0xFAEB4e78e9F9a3d9eFE38d26011bd4F4E6f70014"
];
const multisigEthReqs = 3;
*/
const addressEthFoundationMultisig = "0xe11bd1032fe0d7343e8de21f92f050ae8462a7d7";

const addressesAttAngel = [
    "0x34B0b1e9E42721E9E4a3D38A558EB0155a588340",
];
const multisigAttAngelReqs = 1;

const startTime = 0;
const endTime = 0;

module.exports = async function(deployer, network, accounts) {
    if (network === "development") {    // Don't deploy on tests
        return;
    };  

    // MultiSigWallet send
    let multisigAttAngelFuture = MultiSigWallet.new(addressesAttAngel, multisigAttAngelReqs);
    // MiniMeTokenFactory send
    let miniMeTokenFactoryFuture = MiniMeTokenFactory.new();

    // MultiSigWallet wait
    let multisigAttAngel = await multisigAttAngelFuture;
    console.log("MultiSigWallet ATT Angel: " + multisigAttAngel.address);
    // MiniMeTokenFactory wait
    let miniMeTokenFactory = await miniMeTokenFactoryFuture;
    console.log("MiniMeTokenFactory: " + miniMeTokenFactory.address);
    console.log();

    // ATT send
    let attFuture = ATT.new(miniMeTokenFactory.address);
    // ATTContribution send
    let attContributionFuture = ATTContribution.new();

    // ATT wait
    let att = await attFuture;
    console.log("ATT: " + att.address);
    // ATTContribution wait
    let attContribution = await attContributionFuture;
    console.log("ATTContribution: " + attContribution.address);
    console.log();

    // ATT changeController send
    let attChangeControllerFuture = att.changeController(attContribution.address);
    // ContributionWallet send
    let contributionWalletFuture = ContributionWallet.new(
        addressEthFoundationMultisig,
        endTime,
        attContribution.address);
    // AngelTokensHolder send
    let angelTokensHolderFuture = AngelTokensHolder.new(
            multisigAttAngel.address,
            attContribution.address,
            att.address);

    // ATT changeController wait
    await attChangeControllerFuture;
    console.log("ATT changed controller!");
    // ContributionWallet wait
    let contributionWallet = await contributionWalletFuture;
    console.log("ContributionWallet: " + contributionWallet.address);
    // AngelTokensHolder wait
    let angelTokensHolder = await angelTokensHolderFuture;
    console.log("AngelTokensHolder: " + angelTokensHolder.address);

    // ATTPlaceHolder send
    let attPlaceHolderFuture = ATTPlaceHolder.new(
        addressEthFoundationMultisig,
        att.address,
        attContribution.address);

    // ATTPlaceHolder wait
    let attPlaceHolder = await attPlaceHolderFuture;
    console.log("ATTPlaceHolder: " + attPlaceHolder.address);
    console.log();

    // ATTContribution initialize send/wait
    await attContribution.initialize(
        att.address,
        attPlaceHolder.address,
        startTime,
        endTime,
        contributionWallet.address,
        angelTokensHolder.address);
    console.log("ATTContribution initialized!");
};
