using System.IO;
using System.Security.Cryptography;
using LocalLoop.Core.Security;

namespace LocalLoop.Service.Security
{
    public class CrossPlatformFileSecretStore : ISecretStore
    {
        // For a basic fallback on Linux/macOS, we can just return raw bytes for now,
        // relying on strict file permissions (chmod 600) set by the OS for security.
        // A more robust implementation would use a DPAPI alternative like AES with a key derived from user secrets or libsecret.
        public byte[] Protect(byte[] userData)
        {
            return userData;
        }

        public byte[] Unprotect(byte[] encryptedData)
        {
            return encryptedData;
        }
    }
}
