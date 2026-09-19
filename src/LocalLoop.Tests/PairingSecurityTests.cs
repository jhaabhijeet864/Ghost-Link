using System;
using System.Text;
using LocalLoop.Service;
using Microsoft.Extensions.Logging.Abstractions;
using NSec.Cryptography;
using Xunit;

namespace LocalLoop.Tests
{
    public class PairingSecurityTests
    {
        [Fact]
        public void PairingToken_DoesNotAcceptHardcodedTestToken()
        {
            var manager = new PairingManager(NullLogger<PairingManager>.Instance);
            manager.SetPairingToken("valid-secret-123");

            Assert.True(manager.ValidatePairingSecret("valid-secret-123"));
            Assert.False(manager.ValidatePairingSecret("test-token"));
        }

        [Fact]
        public void PairingToken_InvalidateBurnsSecret()
        {
            var manager = new PairingManager(NullLogger<PairingManager>.Instance);
            manager.SetPairingToken("one-time-secret");

            Assert.True(manager.ValidatePairingSecret("one-time-secret"));
            manager.InvalidatePairingSecret();
            Assert.False(manager.ValidatePairingSecret("one-time-secret"));
        }

        [Fact]
        public void Challenge_ReplayProtectionRejectsReusedChallenge()
        {
            var manager = new PairingManager(NullLogger<PairingManager>.Instance);
            
            // Generate Ed25519 keypair
            var algorithm = SignatureAlgorithm.Ed25519;
            using var key = Key.Create(algorithm, new KeyCreationParameters { ExportPolicy = KeyExportPolicies.AllowPlaintextExport });
            var publicKeyBytes = key.Export(KeyBlobFormat.RawPublicKey);
            var publicKeyBase64 = Convert.ToBase64String(publicKeyBytes);

            manager.RegisterKey(publicKeyBase64);

            var challenge = manager.GenerateChallenge();
            var challengeBytes = Encoding.UTF8.GetBytes(challenge);
            var signature = algorithm.Sign(key, challengeBytes);
            var signatureBase64 = Convert.ToBase64String(signature);

            // First validation succeeds
            Assert.True(manager.ValidateSignature(challenge, signatureBase64, publicKeyBase64));

            // Immediate replay of the same challenge must fail (single-use anti-replay)
            Assert.False(manager.ValidateSignature(challenge, signatureBase64, publicKeyBase64));
        }

        [Fact]
        public void ValidateSignatureRaw_VerifiesAuthenticPayloadAndRejectsTampered()
        {
            var manager = new PairingManager(NullLogger<PairingManager>.Instance);

            var algorithm = SignatureAlgorithm.Ed25519;
            using var key = Key.Create(algorithm, new KeyCreationParameters { ExportPolicy = KeyExportPolicies.AllowPlaintextExport });
            var publicKeyBytes = key.Export(KeyBlobFormat.RawPublicKey);
            var publicKeyBase64 = Convert.ToBase64String(publicKeyBytes);

            manager.RegisterKey(publicKeyBase64);

            var originalPayload = "{\"action\":\"write_file\",\"target\":\"app.py\"}";
            var tamperedPayload = "{\"action\":\"delete_file\",\"target\":\"app.py\"}";

            var signature = algorithm.Sign(key, Encoding.UTF8.GetBytes(originalPayload));
            var signatureBase64 = Convert.ToBase64String(signature);

            // Valid payload succeeds
            Assert.True(manager.ValidateSignatureRaw(originalPayload, signatureBase64, publicKeyBase64));

            // Tampered payload fails
            Assert.False(manager.ValidateSignatureRaw(tamperedPayload, signatureBase64, publicKeyBase64));
        }
    }
}
