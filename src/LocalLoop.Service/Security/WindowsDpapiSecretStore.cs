using System.Security.Cryptography;
using System.Runtime.Versioning;
using LocalLoop.Core.Security;

namespace LocalLoop.Service.Security
{
    [SupportedOSPlatform("windows")]
    public class WindowsDpapiSecretStore : ISecretStore
    {
        public byte[] Protect(byte[] userData)
        {
            return ProtectedData.Protect(userData, null, DataProtectionScope.CurrentUser);
        }

        public byte[] Unprotect(byte[] encryptedData)
        {
            return ProtectedData.Unprotect(encryptedData, null, DataProtectionScope.CurrentUser);
        }
    }
}
