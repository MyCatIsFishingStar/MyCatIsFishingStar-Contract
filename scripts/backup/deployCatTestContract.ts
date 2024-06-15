import { toNano } from '@ton/core';
import { CatTestContract } from '../wrappers/CatTestContract';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    // Initialize and deploy the contract
    const catTestContract = provider.open(await CatTestContract.fromInit());

    await catTestContract.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        },
    );

    await provider.waitForDeploy(catTestContract.address);

    console.log('Contract deployed at:', catTestContract.address.toString());

    // Send a ClaimProcessed message
    const claimType = 'testClaimType';
    const claimSender = provider.sender();

    console.log('Sending ClaimProcessed message with claimType:', claimType);

    await catTestContract.send(
        claimSender,
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'ClaimProcessed',
            claimType: claimType,
        },
    );

    // Wait for the transaction to be processed
    await provider.waitForDeploy(catTestContract.address);
}
