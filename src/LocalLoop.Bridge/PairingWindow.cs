using System;
using System.Drawing;
using System.Windows.Forms;
using QRCoder;

namespace LocalLoop.Bridge
{
    public class PairingWindow : Form
    {
        private PictureBox qrPictureBox;
        private Label infoLabel;

        public PairingWindow(string token, string ip, int port)
        {
            string pairingUri = $"localloop://pair?token={token}&ip={ip}&port={port}";
            
            this.Text = "LocalLoop - Pair Device";
            this.Size = new Size(360, 420);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.BackColor = Color.FromArgb(18, 20, 24); // #121418 Gunmetal Dark
            this.Icon = SystemIcons.Shield;

            infoLabel = new Label
            {
                Text = "Scan this QR code using the LocalLoop mobile app.",
                TextAlign = ContentAlignment.MiddleCenter,
                Dock = DockStyle.Top,
                Height = 50,
                ForeColor = Color.White,
                BackColor = Color.FromArgb(18, 20, 24),
                Font = new Font("Segoe UI", 10, FontStyle.Bold)
            };
            
            qrPictureBox = new PictureBox
            {
                Dock = DockStyle.Fill,
                SizeMode = PictureBoxSizeMode.CenterImage,
                BackColor = Color.FromArgb(18, 20, 24),
                Padding = new Padding(16)
            };

            this.Controls.Add(qrPictureBox);
            this.Controls.Add(infoLabel);

            GenerateQRCode(pairingUri);
        }

        private void GenerateQRCode(string data)
        {
            using (QRCodeGenerator qrGenerator = new QRCodeGenerator())
            using (QRCodeData qrCodeData = qrGenerator.CreateQrCode(data, QRCodeGenerator.ECCLevel.Q))
            using (QRCode qrCode = new QRCode(qrCodeData))
            {
                // Black QR modules with white background for high camera contrast
                Bitmap qrCodeImage = qrCode.GetGraphic(5, Color.Black, Color.White, true);
                qrPictureBox.Image = qrCodeImage;
            }
        }
    }
}
