import { Blockchain, SandboxContract, TreasuryContract, Event } from '@ton/sandbox';
import { toNano } from '@ton/core';
import { CatTestContract } from '../wrappers/CatTestContract';
import '@ton/test-utils';

describe('CatTestContract', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let catTestContract: SandboxContract<CatTestContract>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        catTestContract = blockchain.openContract(await CatTestContract.fromInit());

        deployer = await blockchain.treasury('deployer');

        const deployResult = await catTestContract.send(
            deployer.getSender(),
            {
                value: toNano('0.1'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            },
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: catTestContract.address,
            deploy: true,
            success: true,
        });

        // Log deploy transaction details
        console.log('Deploy Transaction:', deployResult.transactions);
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and catTestContract are ready to use
    });

    it('should process claims and log the event', async () => {
        const claimTypes = ['claimType1', 'claimType2', 'claimType3'];

        for (const claimType of claimTypes) {
            const claimer = await blockchain.treasury('claimer-' + claimType);

            const claimResult = await catTestContract.send(
                claimer.getSender(),
                {
                    value: toNano('0.05'),
                },
                {
                    $$type: 'ClaimProcessed',
                    claimType: claimType,
                },
            );

            expect(claimResult.transactions).toHaveTransaction({
                from: claimer.address,
                to: catTestContract.address,
                success: true,
            });

            // Log claim transaction details
            console.log(`Claim Transaction for ${claimType}:`, claimResult.transactions);

            // const events = claimResult.events.filter(
            //     (e: Event) => (e as EventAccountCreated).name === 'ClaimProcessedEvent',
            // );
            // expect(events.length).toBe(1);
            // expect(events[0].data.claimType).toBe(claimType);
        }
    });

    it('should process payments and log the event', async () => {
        const payments = [
            { amount: toNano('1'), memo: 'Payment 1' },
            { amount: toNano('2'), memo: 'Payment 2' },
            { amount: toNano('3'), memo: 'Payment 3' },
        ];

        for (const payment of payments) {
            const payer = await blockchain.treasury('payer-' + payment.memo);

            const paymentResult = await catTestContract.send(
                payer.getSender(),
                {
                    value: payment.amount,
                },
                {
                    $$type: 'Payment',
                    amount: payment.amount,
                    memo: payment.memo,
                },
            );

            expect(paymentResult.transactions).toHaveTransaction({
                from: payer.address,
                to: catTestContract.address,
                success: true,
            });

            // Log payment transaction details
            console.log(`Payment Transaction for ${payment.memo}:`, paymentResult.transactions);

            // const events = paymentResult.events.filter((e: EventAccountCreated) => e.name === 'PaymentReceivedEvent');
            // expect(events.length).toBe(1);
            // expect(events[0].data.amount).toBe(payment.amount);
            // expect(events[0].data.memo).toBe(payment.memo);
        }
    });

    it('should withdraw a specific amount', async () => {
        const amountToWithdraw = toNano('0.02');

        const specificWithdrawResult = await catTestContract.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Withdraw',
                amount: amountToWithdraw,
            },
        );

        expect(specificWithdrawResult.transactions).toHaveTransaction({
            from: catTestContract.address,
            to: deployer.address,
            success: true,
        });

        // Log withdraw transaction details
        console.log('Withdraw Transaction:', specificWithdrawResult.transactions);
    });
});
