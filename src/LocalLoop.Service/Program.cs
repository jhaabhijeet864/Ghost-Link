using LocalLoop.Service;
using LocalLoop.Service.Parsing;
using LocalLoop.Service.Policy;
using LocalLoop.Service.Audit;

var builder = Host.CreateApplicationBuilder(args);

builder.Services.AddSingleton<IIntentParser, IntentParser>();
builder.Services.AddSingleton<IPolicyEngine, PolicyEngine>();
builder.Services.AddSingleton<IAuditLogger, AuditLogger>();
builder.Services.AddSingleton<PairingManager>();
builder.Services.AddSingleton<WebSocketServer>();

builder.Services.AddHostedService<mDNSAdvertiser>();
builder.Services.AddHostedService<Worker>();

var host = builder.Build();
host.Run();
