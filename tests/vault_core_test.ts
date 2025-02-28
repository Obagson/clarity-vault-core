import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

[previous tests remain unchanged...]

Clarinet.test({
  name: "Ensure unauthorized users cannot access key history",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    const testKeyId = "test-key-1";
    
    let block = chain.mineBlock([
      Tx.contractCall('vault-core', 'get-key-history', [
        types.ascii(testKeyId)
      ], wallet2.address)
    ]);
    
    block.receipts[0].result.expectErr(101); // err-unauthorized
  },
});

Clarinet.test({
  name: "Test rotation period validation",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('vault-core', 'initialize-vault', [
        types.bool(true),
        types.uint(10) // Too short rotation period
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectErr(106); // err-invalid-period
  },
});
