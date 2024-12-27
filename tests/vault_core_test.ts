import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test vault initialization",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('vault-core', 'initialize-vault', [], wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk();
    
    // Verify vault info
    let infoBlock = chain.mineBlock([
      Tx.contractCall('vault-core', 'get-vault-info', [
        types.principal(wallet1.address)
      ], wallet1.address)
    ]);
    
    let vaultInfo = infoBlock.receipts[0].result.expectOk().expectSome();
    assertEquals(vaultInfo.active, true);
  },
});

Clarinet.test({
  name: "Test key management",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    const testKeyId = "test-key-1";
    const testEncryptedKey = "encrypted-key-data";
    
    let block = chain.mineBlock([
      Tx.contractCall('vault-core', 'initialize-vault', [], wallet1.address),
      Tx.contractCall('vault-core', 'add-key', [
        types.ascii(testKeyId),
        types.ascii(testEncryptedKey)
      ], wallet1.address)
    ]);
    
    block.receipts.map(receipt => receipt.result.expectOk());
    
    // Test key retrieval
    let getBlock = chain.mineBlock([
      Tx.contractCall('vault-core', 'get-key', [
        types.ascii(testKeyId)
      ], wallet1.address)
    ]);
    
    assertEquals(
      getBlock.receipts[0].result.expectOk(),
      testEncryptedKey
    );
  },
});

Clarinet.test({
  name: "Test recovery process",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('vault-core', 'initialize-vault', [], wallet1.address),
      Tx.contractCall('vault-core', 'initiate-recovery', [
        types.principal(wallet2.address)
      ], wallet1.address)
    ]);
    
    block.receipts.map(receipt => receipt.result.expectOk());
    
    // Mine blocks to pass recovery delay
    chain.mineEmptyBlockUntil(chain.blockHeight + 145);
    
    let recoveryBlock = chain.mineBlock([
      Tx.contractCall('vault-core', 'complete-recovery', [
        types.principal(wallet1.address)
      ], wallet2.address)
    ]);
    
    recoveryBlock.receipts[0].result.expectOk();
  },
});