namespace LocalLoop.Core.Security
{
    public interface ISecretStore
    {
        byte[] Protect(byte[] userData);
        byte[] Unprotect(byte[] encryptedData);
    }
}
