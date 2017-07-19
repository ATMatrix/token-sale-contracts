const MultiSigWallet = artifacts.require("MultiSigWallet");
const MiniMeTokenFactory = artifacts.require("MiniMeTokenFactory");
const ATT = artifacts.require("ATT");
const ATTContribution = artifacts.require("ATTContribution");
const ContributionWallet = artifacts.require("ContributionWallet");
const AngelTokensHolder = artifacts.require("AngelTokensHolder");
const ATTPlaceHolder = artifacts.require("ATTPlaceHolder");

// All of these constants need to be configured before deploy
const addressOwner = "0x34B0b1e9E42721E9E4a3D38A558EB0155a588340";


const addressesEthFoundation = [
    "0x34B0b1e9E42721E9E4a3D38A558EB0155a588340",
];
const multisigEthReqs = 1;

const addressesCommunity = [
    "0x34B0b1e9E42721E9E4a3D38A558EB0155a588340",
];
const multisigCommunityReqs = 1

const addressesAttAngel = [
    "0x34B0b1e9E42721E9E4a3D38A558EB0155a588340",
];
const multisigAttAngelReqs = 1;

const startBlock = 9800000;
const endBlock = 9900000;

const startTime = 0;
const endTime = 0;

module.exports = async function(deployer, network, accounts) {
    if (network === "development") return;  // Don't deploy on tests

    // MultiSigWallet send
    let multisigEthFoundationFuture = MultiSigWallet.new(addressesEthFoundation, multisigEthReqs);
    let multisigCommunityFuture = MultiSigWallet.new(addressesCommunity, multisigCommunityReqs);
    let multisigAttAngelFuture = MultiSigWallet.new(addressesAttAngel, multisigAttAngelReqs);
    // MiniMeTokenFactory send
    let miniMeTokenFactoryFuture = MiniMeTokenFactory.new();

    // MultiSigWallet wait
    let multisigEthFoundation = await multisigEthFoundationFuture;
    console.log("\nMultiSigWallet ETH Foundation: " + multisigEthFoundation.address);
    let multisigCommunity = await multisigCommunityFuture;
    console.log("MultiSigWallet Community: " + multisigCommunity.address);
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
        multisigEthFoundation.address,
        endBlock,
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
        multisigCommunity.address,
        att.address,
        attContribution.address);

    // ATTPlaceHolder wait
    let attPlaceHolder = await attPlaceHolderFuture;
    console.log("ATTPlaceHolder: " + attPlaceHolder.address);
    console.log();

    // ATTContribution initialize send/wait
    await attContribution.initialize(
        att.address,
        sntPlaceHolder.address,
        startTime,
        endTime,
        contributionWallet.address,
        angelTokensHolder.address);
    console.log("ATTContribution initialized!");
};
