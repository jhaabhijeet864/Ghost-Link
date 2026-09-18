using System;
using System.Drawing;
using QRCoder;

namespace LocalLoop.Bridge
{
    public class PairingWindow
    {
        public void ShowQrCode(string token, string ip, int port)
        {
            string uri = $"localloop://pair?token={token}&ip={ip}&port={port}";
            using (QRCodeGenerator qrGenerator = new QRCodeGenerator())
            using (QRCodeData qrCodeData = qrGenerator.CreateQrCode(uri, QRCodeGenerator.ECCLevel.Q))
            using (QRCode qrCode = new QRCode(qrCodeData))
            {
                Bitmap qrCodeImage = qrCode.GetGraphic(20);
                // We'd render this in a UI window here (WinForms or WPF)
                Console.WriteLine("QR Code generated for URI: " + uri);
                Console.WriteLine("Allow pairing?");
            }
        }
    }
}
