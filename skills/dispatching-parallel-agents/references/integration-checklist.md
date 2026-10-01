# Integration Checklist

Use this reference when aggregating worker results and validating combined changes.

## Verification

After agents return:
1. **Review each summary** - Understand what changed
2. **Check for conflicts** - Did agents edit same code?
3. **Check coverage** - Did every required slice return PASS, ISSUES, or BLOCKED?
4. **Report gaps** - Name dropouts and blockers instead of treating them as success
5. **Validate integration** - Run the smallest command covering the combined
   changes; escalate to the full suite when risk or repository policy warrants
6. **Spot check** - Agents can make systematic errors
