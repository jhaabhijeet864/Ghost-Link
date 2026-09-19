using System;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Makaretu.Dns;

namespace LocalLoop.Service
{
    public class mDNSAdvertiser : BackgroundService
    {
        private readonly ILogger<mDNSAdvertiser> _logger;
        private MulticastService _mdns;
        private ServiceDiscovery _serviceDiscovery;
        private ServiceProfile _profile;

        public mDNSAdvertiser(ILogger<mDNSAdvertiser> logger)
        {
            _logger = logger;
        }

        protected override Task ExecuteAsync(CancellationToken stoppingToken)
        {
            try
            {
                _mdns = new MulticastService();
                _serviceDiscovery = new ServiceDiscovery(_mdns);

                // Use the hostname or a unique identifier
                var instanceName = $"{Environment.MachineName}-LocalLoop";
                _profile = new ServiceProfile(instanceName, "_localloop._tcp", 8080);
                
                // Add IP addresses (optional, Makaretu usually figures this out, but good to be explicit)
                var ips = Dns.GetHostAddresses(Dns.GetHostName())
                    .Where(a => a.AddressFamily == AddressFamily.InterNetwork);
                
                foreach (var ip in ips)
                {
                    _profile.Resources.Add(new ARecord { Name = _profile.FullyQualifiedName, Address = ip });
                }

                _profile.AddProperty("machine", Environment.MachineName);
                _profile.AddProperty("v", "1");

                _serviceDiscovery.Advertise(_profile);
                _mdns.Start();

                _logger.LogInformation("mDNS Advertiser started for {InstanceName} on _localloop._tcp", instanceName);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to start mDNS Advertiser");
            }

            return Task.CompletedTask;
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _serviceDiscovery?.Unadvertise(_profile);
            _mdns?.Stop();
            await base.StopAsync(cancellationToken);
        }
    }
}
