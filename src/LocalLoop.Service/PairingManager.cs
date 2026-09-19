using System;
using System.Collections.Generic;
using System.IO;
using System.Security.Cryptography;
using System.Text.Json;
using NSec.Cryptography;
using Microsoft.Extensions.Logging;

namespace LocalLoop.Service
{
    public class PairingManager
    {
        private string _currentToken = Guid.NewGuid().ToString();
        private readonly HashSet<string> _pairedKeys = new HashSet<string>();
        private readonly string _storagePath;
        private readonly ILogger<PairingManager> _logger;

        public PairingManager(ILogger<PairingManager> logger)
        {
            _logger = logger;
            var appData = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
            var dir = Path.Combine(appData, "LocalLoop");
            Directory.CreateDirectory(dir);
            _storagePath = Path.Combine(dir, "paired_devices.dat");

            LoadKeys();
        }

        private readonly System.Collections.Concurrent.ConcurrentDictionary<string, long> _activeChallenges = new();

        public string GeneratePairingToken()
        {
            _currentToken = Guid.NewGuid().ToString();
            return _currentToken;
        }

        public void SetPairingToken(string token)
        {
            _currentToken = token;
        }

        public bool ValidatePairingSecret(string secret)
        {
            return !string.IsNullOrEmpty(_currentToken) && secret == _currentToken;
        }

        public void InvalidatePairingSecret()
        {
            _currentToken = string.Empty;
        }

        public string GenerateChallenge()
        {
            var nonce = Guid.NewGuid().ToString("N");
            var timestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
            var challenge = $"{nonce}:{timestamp}";
            _activeChallenges[challenge] = timestamp;
            return challenge;
        }

        public bool ValidateSignature(string challenge, string signatureBase64, string publicKeyBase64)
        {
            try
            {
                if (!_pairedKeys.Contains(publicKeyBase64))
                {
                    _logger.LogWarning("Public key not registered.");
                    return false;
                }

                // Verify challenge exists and is within 60 seconds
                if (!_activeChallenges.TryRemove(challenge, out var challengeTime))
                {
                    _logger.LogWarning("Challenge was invalid or already consumed.");
                    return false;
                }

                var now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
                if (now - challengeTime > 60)
                {
                    _logger.LogWarning("Challenge expired.");
                    return false;
                }

                var publicKeyBytes = Convert.FromBase64String(publicKeyBase64);
                var signatureBytes = Convert.FromBase64String(signatureBase64);
                var challengeBytes = System.Text.Encoding.UTF8.GetBytes(challenge);

                var algorithm = SignatureAlgorithm.Ed25519;
                var publicKey = PublicKey.Import(algorithm, publicKeyBytes, KeyBlobFormat.RawPublicKey);
                
                return algorithm.Verify(publicKey, challengeBytes, signatureBytes);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Signature validation failed.");
                return false;
            }
        }

        public bool ValidateSignatureRaw(string payload, string signatureBase64, string publicKeyBase64)
        {
            try
            {
                if (!_pairedKeys.Contains(publicKeyBase64))
                {
                    _logger.LogWarning("Public key not registered for action verification.");
                    return false;
                }

                var publicKeyBytes = Convert.FromBase64String(publicKeyBase64);
                var signatureBytes = Convert.FromBase64String(signatureBase64);
                var payloadBytes = System.Text.Encoding.UTF8.GetBytes(payload);

                var algorithm = SignatureAlgorithm.Ed25519;
                var publicKey = PublicKey.Import(algorithm, publicKeyBytes, KeyBlobFormat.RawPublicKey);
                
                return algorithm.Verify(publicKey, payloadBytes, signatureBytes);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Raw payload signature validation failed.");
                return false;
            }
        }

        public void RegisterKey(string publicKeyBase64)
        {
            if (_pairedKeys.Add(publicKeyBase64))
            {
                SaveKeys();
                _logger.LogInformation("New Mobile Public Key registered.");
            }
        }

        public bool IsKeyRegistered(string publicKeyBase64)
        {
            return _pairedKeys.Contains(publicKeyBase64);
        }

        private void SaveKeys()
        {
            try
            {
                var json = JsonSerializer.Serialize(_pairedKeys);
                var jsonBytes = System.Text.Encoding.UTF8.GetBytes(json);
                var encryptedBytes = ProtectedData.Protect(jsonBytes, null, DataProtectionScope.CurrentUser);
                File.WriteAllBytes(_storagePath, encryptedBytes);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to save keys securely.");
            }
        }

        private void LoadKeys()
        {
            try
            {
                if (File.Exists(_storagePath))
                {
                    var encryptedBytes = File.ReadAllBytes(_storagePath);
                    var jsonBytes = ProtectedData.Unprotect(encryptedBytes, null, DataProtectionScope.CurrentUser);
                    var json = System.Text.Encoding.UTF8.GetString(jsonBytes);
                    var keys = JsonSerializer.Deserialize<HashSet<string>>(json);
                    
                    if (keys != null)
                    {
                        foreach (var k in keys) _pairedKeys.Add(k);
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to load keys securely.");
            }
        }
    }
}
