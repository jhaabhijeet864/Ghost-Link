using LocalLoop.Service;
using LocalLoop.Service.Parsing;
using LocalLoop.Service.Policy;
using LocalLoop.Service.Audit;
using LocalLoop.Core.Security;
using LocalLoop.Service.Security;
using System.Runtime.InteropServices;

var builder = Host.CreateApplicationBuilder(args);

builder.Services.AddSingleton<IIntentParser, IntentParser>();
builder.Services.AddSingleton<IPolicyEngine, PolicyEngine>();
builder.Services.AddSingleton<IAuditLogger, AuditLogger>();

if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
{
    builder.Services.AddSingleton<ISecretStore, WindowsDpapiSecretStore>();
}
else
{
    builder.Services.AddSingleton<ISecretStore, CrossPlatformFileSecretStore>();
}

builder.Services.AddSingleton<PairingManager>();
builder.Services.AddSingleton<WebSocketServer>();

builder.Services.AddHostedService<mDNSAdvertiser>();
builder.Services.AddHostedService<Worker>();

var host = builder.Build();
host.Run();
