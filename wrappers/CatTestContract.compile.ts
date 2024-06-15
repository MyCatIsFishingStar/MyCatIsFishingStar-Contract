import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/cat_test_contract.tact',
    options: {
        debug: true,
    },
};
