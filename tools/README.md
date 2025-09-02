# HakPak Tools Directory (Open Source Edition)

This directory previously contained enterprise licensing utilities. HakPak is now fully open source (MIT) and licensing has been deprecated. Remaining scripts are legacy artifacts and will be removed ≥2.0.

## User Types

### For Maintainers
Historical scripts (`generate_keys.sh`, `generate_license.sh`, `validate_license.sh`) are no longer required for normal operation.

### For Users
You do **not** need anything in this directory to use HakPak.

### For Contributors
If removing these scripts, ensure any CI or docs references are scrubbed.

---

## Deprecated Scripts

### Key Management

#### generate_keys.sh (Deprecated)
Formerly generated RSA keypair. Not needed.

### License Generation

#### generate_license.sh (Deprecated)
Previously emitted license payload + signature. No longer used.

Obsolete generation examples removed.

### License Validation

#### validate_license.sh (Deprecated)

Previously validated license signature. No runtime integration now.

Validation examples removed.

## Security Considerations (Historical)

### Key Security

- Private keys must be stored securely
- Use hardware security modules (HSM) for production environments
- Regularly rotate keys according to security policy
- Maintain secure backup of private keys

### License Security

- Licenses contain customer information and should be treated as confidential
- Use encrypted communication channels for license delivery
- Maintain audit trail of license generation and distribution
- Implement license revocation procedures if needed

### Access Control

- Restrict access to license generation tools to authorized personnel only
- Use role-based access control for different license operations
- Log all license generation activities for audit purposes

## Historical Enterprise Workflow (Removed)

Historical generation workflow removed.

## Development Notes

Legacy test script examples removed.

Integration hooks have been removed; status now always reflects open source mode.

## Support and Troubleshooting

### Common Issues

### Missing Dependencies

```bash
sudo apt-get install openssl jq
```

### Key Generation Failures (Legacy)

- Ensure sufficient entropy for key generation
- Check file system permissions
- Verify OpenSSL installation

### Legacy License Validation

No longer applicable; remove old automation referencing these scripts.

### Contact Information

- **Technical Support**: [owner@phanesguild.llc](mailto:owner@phanesguild.llc)
- **Enterprise Sales**: [owner@phanesguild.llc](mailto:owner@phanesguild.llc)
- **Security Issues**: [owner@phanesguild.llc](mailto:owner@phanesguild.llc)
- **Discord**: PhanesGuildSoftware
- **GitHub**: [PhanesGuildSoftware](https://github.com/PhanesGuildSoftware)

## License

MIT. Prior commercial licensing terms are sunset.

---

Last Updated: 2025-09-01 (Open Source Transition)
