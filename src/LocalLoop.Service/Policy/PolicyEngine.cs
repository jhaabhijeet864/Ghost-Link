using LocalLoop.Core;

namespace LocalLoop.Service.Policy
{
    public interface IPolicyEngine
    {
        PolicyDecision Evaluate(CommandIntent intent);
        bool IsActionAllowed(string action, string target);
    }

    public class PolicyEngine : IPolicyEngine
    {
        private readonly Dictionary<string, PolicyDecision> _actionRiskMap;
        private readonly HashSet<string> _alwaysAllowActions;
        private readonly HashSet<string> _alwaysBlockActions;

        public PolicyEngine()
        {
            _actionRiskMap = new Dictionary<string, PolicyDecision>(StringComparer.OrdinalIgnoreCase)
            {
                // Low risk - Allow
                ["read"] = PolicyDecision.Allow,
                ["view"] = PolicyDecision.Allow,
                ["show"] = PolicyDecision.Allow,
                ["get"] = PolicyDecision.Allow,
                ["list"] = PolicyDecision.Allow,
                ["tail"] = PolicyDecision.Allow,
                ["watch"] = PolicyDecision.Allow,
                ["cat"] = PolicyDecision.Allow,
                ["less"] = PolicyDecision.Allow,
                ["more"] = PolicyDecision.Allow,
                ["status"] = PolicyDecision.Allow,
                ["check"] = PolicyDecision.Allow,
                ["monitor"] = PolicyDecision.Allow,
                ["inspect"] = PolicyDecision.Allow,
                ["search"] = PolicyDecision.Allow,
                ["find"] = PolicyDecision.Allow,
                ["grep"] = PolicyDecision.Allow,
                ["locate"] = PolicyDecision.Allow,

                // Medium risk - Ask
                ["write"] = PolicyDecision.Ask,
                ["create"] = PolicyDecision.Ask,
                ["edit"] = PolicyDecision.Ask,
                ["modify"] = PolicyDecision.Ask,
                ["update"] = PolicyDecision.Ask,
                ["append"] = PolicyDecision.Ask,
                ["replace"] = PolicyDecision.Ask,
                ["copy"] = PolicyDecision.Ask,
                ["move"] = PolicyDecision.Ask,
                ["rename"] = PolicyDecision.Ask,
                ["install"] = PolicyDecision.Ask,
                ["add"] = PolicyDecision.Ask,
                ["download"] = PolicyDecision.Ask,
                ["pull"] = PolicyDecision.Ask,
                ["restart"] = PolicyDecision.Ask,
                ["reboot"] = PolicyDecision.Ask,
                ["reload"] = PolicyDecision.Ask,
                ["compress"] = PolicyDecision.Ask,
                ["extract"] = PolicyDecision.Ask,
                ["zip"] = PolicyDecision.Ask,
                ["unzip"] = PolicyDecision.Ask,
                ["tar"] = PolicyDecision.Ask,
                ["backup"] = PolicyDecision.Ask,
                ["restore"] = PolicyDecision.Ask,

                // High risk - Block (require explicit approval)
                ["execute"] = PolicyDecision.Block,
                ["run"] = PolicyDecision.Block,
                ["start"] = PolicyDecision.Block,
                ["launch"] = PolicyDecision.Block,
                ["invoke"] = PolicyDecision.Block,
                ["call"] = PolicyDecision.Block,
                ["stop"] = PolicyDecision.Block,
                ["kill"] = PolicyDecision.Block,
                ["terminate"] = PolicyDecision.Block,
                ["end"] = PolicyDecision.Block,
                ["cancel"] = PolicyDecision.Block,
                ["uninstall"] = PolicyDecision.Block,
                ["remove"] = PolicyDecision.Block,
                ["delete"] = PolicyDecision.Block,
                ["purge"] = PolicyDecision.Block,
            };

            _alwaysAllowActions = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                "read", "view", "show", "get", "list", "tail", "watch", "status", "check", "monitor", "inspect"
            };

            _alwaysBlockActions = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                "format", "wipe", "destroy", "encrypt", "decrypt"
            };
        }

        public PolicyDecision Evaluate(CommandIntent intent)
        {
            if (string.IsNullOrWhiteSpace(intent.Action))
            {
                return PolicyDecision.Block;
            }

            // Check always-block list first
            if (_alwaysBlockActions.Contains(intent.Action))
            {
                return PolicyDecision.Block;
            }

            // Check explicit action risk map
            if (_actionRiskMap.TryGetValue(intent.Action, out var decision))
            {
                return decision;
            }

            // Unknown action - default to Block for safety
            return PolicyDecision.Block;
        }

        public bool IsActionAllowed(string action, string target)
        {
            if (string.IsNullOrWhiteSpace(action))
                return false;

            if (_alwaysBlockActions.Contains(action))
                return false;

            if (_alwaysAllowActions.Contains(action))
                return true;

            return _actionRiskMap.TryGetValue(action, out var decision) && decision == PolicyDecision.Allow;
        }

        public PolicyDecision GetDecisionForRiskLevel(string riskLevel)
        {
            return riskLevel?.ToLowerInvariant() switch
            {
                "low" => PolicyDecision.Allow,
                "medium" => PolicyDecision.Ask,
                "high" => PolicyDecision.Block,
                _ => PolicyDecision.Block
            };
        }
    }
}