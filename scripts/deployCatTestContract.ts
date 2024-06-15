import { toNano } from '@ton/core';
import { CatTestContract } from '../wrappers/CatTestContract';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    // Initialize and deploy the CatTestContract
    const catTestContract = provider.open(await CatTestContract.fromInit());

    await catTestContract.send(
        provider.sender(),
        {
            value: toNano('0.1'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        },
    );

    await provider.waitForDeploy(catTestContract.address);

    console.log('CatTestContract deployed at:', catTestContract.address.toString());

    // // Example of sending a ClaimProcessed message
    // const claimType = 'testClaimType';
    // const claimSender = provider.sender();

    // await catTestContract.send(
    //     claimSender,
    //     {
    //         value: toNano('0.05'),
    //     },
    //     {
    //         $$type: 'ClaimProcessed',
    //         claimType: claimType,
    //     },
    // );

    // // Example of sending a Payment message
    // const paymentAmount = 1000; // example amount in coins
    // const paymentMemo = 'Payment for services';

    // await catTestContract.send(
    //     claimSender,
    //     {
    //         value: toNano('0.05'),
    //     },
    //     {
    //         $$type: 'Payment',
    //         amount: paymentAmount,
    //         memo: paymentMemo,
    //     },
    // );

    // // Example of withdrawing all balance
    // await catTestContract.send(
    //     provider.sender(),
    //     {
    //         value: toNano('0.05'),
    //     },
    //     'withdraw all',
    // );

    // // Example of safe withdraw
    // await catTestContract.send(
    //     provider.sender(),
    //     {
    //         value: toNano('0.05'),
    //     },
    //     'withdraw safe',
    // );

    // // Example of withdrawing a specific amount
    // const withdrawAmount = 500; // example amount in coins

    // await catTestContract.send(
    //     provider.sender(),
    //     {
    //         value: toNano('0.05'),
    //     },
    //     {
    //         $$type: 'Withdraw',
    //         amount: withdrawAmount,
    //     },
    // );
}
