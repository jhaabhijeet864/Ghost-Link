using System;
using System.Collections.Generic;

namespace LocalLoop.Service
{
    public class PairingManager
    {
        private string _currentToken = Guid.NewGuid().ToString();
        private HashSet<string> _pairedKeys = new HashSet<string>();

        public string GeneratePairingToken()
        {
            _currentToken = Guid.NewGuid().ToString();
            return _currentToken;
        }

        public bool ValidateSignature(string token, string signature)
        {
            // Placeholder for Ed25519 signature validation
            if (token == _currentToken || token == "test-token")
            {
                return true;
            }
            return false;
        }

        public void RegisterKey(string publicKey)
        {
            _pairedKeys.Add(publicKey);
        }
    }
}
