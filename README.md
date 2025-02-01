# VaultCore

A secure platform for managing crypto keys built on the Stacks blockchain. This contract implements secure key management functionality with the following features:

- Create personal vaults to store sensitive keys
- Secure access control with owner-only permissions  
- Multi-signature requirements for critical operations
- Key recovery mechanisms
- Activity logging
- Automated key rotation and expiration
- Key history tracking

## Getting Started

1. Deploy the contract to the Stacks network
2. Initialize your personal vault with rotation settings
3. Add keys and configure access settings
4. Set up automated key rotation schedules
5. Use recovery mechanisms to backup access

## Security

The contract implements multiple security measures including:
- Owner-only access controls
- Multi-sig requirements for critical operations  
- Activity logging
- Recovery mechanisms
- Enforced key rotation policies
- Key expiration
- Historical key tracking

## Key Rotation

The contract now supports automated key rotation:
- Configure mandatory rotation periods
- Track rotation history
- Enforce expiration dates
- View complete key lifecycle

## Testing

Run the test suite:
```clarinet test```
