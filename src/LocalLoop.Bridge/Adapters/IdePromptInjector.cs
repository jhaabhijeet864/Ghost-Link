using System;
using System.Diagnostics;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using LocalLoop.Core;

namespace LocalLoop.Bridge.Adapters
{
    public class IdePromptInjector
    {
        [DllImport("user32.dll")]
        private static extern bool SetForegroundWindow(IntPtr hWnd);

        [DllImport("user32.dll")]
        private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

        [DllImport("user32.dll")]
        private static extern bool IsIconic(IntPtr hWnd);

        private const int SW_RESTORE = 9;

        public static Task<bool> InjectPromptAsync(string prompt, string? targetWindowName = null)
        {
            var tcs = new TaskCompletionSource<bool>();

            // Must run on STA thread for Clipboard operations
            var thread = new Thread(() =>
            {
                try
                {
                    var processes = Process.GetProcessesByName("Code");
                    Process? targetProcess = null;

                    if (!string.IsNullOrEmpty(targetWindowName))
                    {
                        targetProcess = processes.FirstOrDefault(p => p.MainWindowTitle.IndexOf(targetWindowName, StringComparison.OrdinalIgnoreCase) >= 0);
                    }

                    if (targetProcess == null)
                    {
                        // Match Antigravity IDE first
                        targetProcess = processes.FirstOrDefault(p => p.MainWindowTitle.IndexOf("Antigravity", StringComparison.OrdinalIgnoreCase) >= 0)
                                     ?? processes.FirstOrDefault(p => !string.IsNullOrWhiteSpace(p.MainWindowTitle));
                    }

                    if (targetProcess == null || targetProcess.MainWindowHandle == IntPtr.Zero)
                    {
                        Console.WriteLine("[IdePromptInjector] Could not find running Antigravity IDE process window.");
                        tcs.SetResult(false);
                        return;
                    }

                    IntPtr hWnd = targetProcess.MainWindowHandle;

                    if (IsIconic(hWnd))
                    {
                        ShowWindow(hWnd, SW_RESTORE);
                    }

                    SetForegroundWindow(hWnd);
                    Thread.Sleep(200);

                    // Preserve existing clipboard content
                    IDataObject? oldClipboard = null;
                    try
                    {
                        oldClipboard = Clipboard.GetDataObject();
                    }
                    catch { }

                    // Copy prompt to clipboard and paste
                    Clipboard.SetText(prompt);
                    Thread.Sleep(100);

                    // Send Paste (Ctrl+V) and Enter
                    SendKeys.SendWait("^v");
                    Thread.Sleep(150);
                    SendKeys.SendWait("{ENTER}");

                    Console.WriteLine($"[IdePromptInjector] Successfully injected prompt into {targetProcess.MainWindowTitle}");
                    tcs.SetResult(true);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[IdePromptInjector] Error injecting prompt: {ex.Message}");
                    tcs.SetResult(false);
                }
            });

            thread.SetApartmentState(ApartmentState.STA);
            thread.Start();

            return tcs.Task;
        }
    }
}
