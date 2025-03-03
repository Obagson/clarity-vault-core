import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

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
    
    block.receipts[0].result.expectErr(102); // err-invalid-vault
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

Clarinet.test({
  name: "Successfully retrieve key history for existing vault",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    const testKeyId = "test-key-1";
    
    // First initialize vault
    let block = chain.mineBlock([
      Tx.contractCall('vault-core', 'initialize-vault', [
        types.bool(true),
        types.uint(24)
      ], wallet1.address)
    ]);
    
    // Then get history
    block = chain.mineBlock([
      Tx.contractCall('vault-core', 'get-key-history', [
        types.ascii(testKeyId)
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk();
  },
});
