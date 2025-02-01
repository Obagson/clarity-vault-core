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
  name: "Test key rotation functionality",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    const testKeyId = "test-key-1";
    const initialKey = "initial-encrypted-key";
    const rotatedKey = "rotated-encrypted-key";
    
    let block = chain.mineBlock([
      Tx.contractCall('vault-core', 'initialize-vault', [
        types.bool(true),
        types.uint(100)
      ], wallet1.address),
      Tx.contractCall('vault-core', 'add-key', [
        types.ascii(testKeyId),
        types.ascii(initialKey)
      ], wallet1.address)
    ]);
    
    block.receipts.map(receipt => receipt.result.expectOk());
    
    // Test key rotation
    let rotateBlock = chain.mineBlock([
      Tx.contractCall('vault-core', 'rotate-key', [
        types.ascii(testKeyId),
        types.ascii(rotatedKey)
      ], wallet1.address)
    ]);
    
    rotateBlock.receipts[0].result.expectOk();
    
    // Verify rotation history
    let historyBlock = chain.mineBlock([
      Tx.contractCall('vault-core', 'get-key-history', [
        types.ascii(testKeyId)
      ], wallet1.address)
    ]);
    
    let history = historyBlock.receipts[0].result.expectOk().expectSome();
    assertEquals(history['previous-keys'].length, 1);
    assertEquals(history['previous-keys'][0], initialKey);
  },
});
