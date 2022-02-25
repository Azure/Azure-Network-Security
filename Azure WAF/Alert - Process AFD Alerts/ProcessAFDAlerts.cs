// //////////////////////////////////////////////////////////////////////////////
// 
//  Copyright (C) Microsoft Corporation. All rights reserved.
// 
// //////////////////////////////////////////////////////////////////////////////

namespace processAfdAlerts
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using Azure.Identity;
    using Azure.Monitor.Query;
    using Microsoft.AspNetCore.Http;
    using Microsoft.AspNetCore.Mvc;
    using Microsoft.Azure.Management.FrontDoor;
    using Microsoft.Azure.Management.FrontDoor.Models;
    using Microsoft.Azure.Management.ResourceManager.Fluent;
    using Microsoft.Azure.WebJobs;
    using Microsoft.Azure.WebJobs.Extensions.Http;
    using Microsoft.Extensions.Logging;
    using Newtonsoft.Json;

    /// <summary>
    /// Azure function to process alerts from Azure front door
    /// </summary>
    public static class ProcessAfdAlerts
    {
        // consts
        private const string MitigateDDOSRateLimitCountryRuleNamePostfix = "MitigateDDOSRateLimitCountryRule";
        private const string MitigateDDOSRateLimitTopRequestIPsRuleNamePostfix = "MitigateDDOSRateLimitTopRequestIPsRule";

        // Info to get logs from Log analytics
        private static readonly string ClientId = "";
        private static readonly string ClientSecret = "";
        private static string TenantId = "";

        // Linked WAF Policy Info
        private static readonly string WafPolicyName = "";
        private static readonly string WafPolicyResourceGroupName = "";
        private static readonly string WafPolicySubscriptionId = "";

        // Frontdoor resourceId
        private static readonly string FrontdoorResourceId = "";

        [FunctionName("ProcessAfdAlerts")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)]
            HttpRequest req,
            ILogger log)
        {
            // 1. Parse the alert message from the incoming request's body
            var requestBody = await new StreamReader(req.Body).ReadToEndAsync();

            AlertBody alertBody;
            try
            {
                alertBody = JsonConvert.DeserializeObject<AlertBody>(requestBody);
            }
            catch (Exception e)
            {
                return new BadRequestObjectResult("Failed to deserialize the request body");
            }

            if (alertBody == null)
            {
                return new BadRequestObjectResult("AlertBody is null");
            }

            // 2. Extract info from the alert
            var alertInfo = new AlertInfo()
            {
                Country = alertBody.data.alertContext.condition.allOf[0].dimensions[0].value
            };

            // 3. Check if the alert was fired/activated or resolved/deactivated
            if (alertBody.data.essentials.monitorCondition == "Fired")
            {
                alertInfo.baselineThreshold = Convert.ToInt32(Convert.ToDouble(alertBody.data.alertContext.condition.allOf[0].threshold)) + 1;
                await HandleAlertFired(log, alertInfo);
            }
            else
            {
                await HandleAlertResolved(log, alertInfo);
            }

            return new OkObjectResult("All done ... ");
        }

        private static async Task HandleAlertResolved(ILogger log, AlertInfo alertInfo)
        {
            // 1. Delete/disable the country specific rules from the WAF policy
            await UpdateLinkedWafPolicy(alertInfo, log, null, true).ConfigureAwait(false);
        }

        private static async Task HandleAlertFired(ILogger log, AlertInfo alertInfo)
        {
            // 1. Query the logs for the past 10 minutes
            var logs = await GetLogs(log, alertInfo);

            if (logs == null)
            {
                // nothing to do
                return;
            }

            // 2. update the linked waf policy with new rules to mitigate the attack
            await UpdateLinkedWafPolicy(alertInfo, log, logs).ConfigureAwait(false);
        }

        private static async Task UpdateLinkedWafPolicy(AlertInfo alertInfo, ILogger log, IEnumerable<Row> logs = null, bool deleteRules = false)
        {
            // 1. Create an instance of FrontdoorManagementClient
            var frontdoorClient =
                new FrontDoorManagementClient(
                    SdkContext.AzureCredentialsFactory.FromServicePrincipal(ClientId, ClientSecret, TenantId, AzureEnvironment.AzureGlobalCloud));
            
            frontdoorClient.SubscriptionId = WafPolicySubscriptionId;

            // 2. Use it to get the WAF Policy
            WebApplicationFirewallPolicy wafPolicy;
            try
            {
                wafPolicy = await frontdoorClient.Policies.GetAsync(WafPolicyResourceGroupName, WafPolicyName);

                if (wafPolicy == null)
                {
                    Console.WriteLine("Does not exist");
                    throw new Exception("Waf policy does not exist");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                throw;
            }

            // 3. Add or remove the rate limit rules from the WAF policy
            if (deleteRules)
            {
                DeleteRulesFromWafPolicy(wafPolicy, alertInfo);
            }
            else
            {
                UpdateWafWithRulesToStopAttack(wafPolicy, alertInfo, logs);
            }

            // 4. Update/Deploy the WAF policy
            try
            {
                await frontdoorClient.Policies.CreateOrUpdateAsync(WafPolicyResourceGroupName, WafPolicyName,
                    wafPolicy);
            }
            catch (Exception e)
            {
                log.LogError("Failed to update waf policy", e);
                throw;
            }
            
        }

        private static void DeleteRulesFromWafPolicy(WebApplicationFirewallPolicy wafPolicy, AlertInfo alertInfo)
        {
            DeleteRateLimitCountryRule(wafPolicy, alertInfo);
            DeleteRateLimitIPRule(wafPolicy, alertInfo);
        }

        private static void DeleteRateLimitCountryRule(WebApplicationFirewallPolicy wafPolicy, AlertInfo alertInfo)
        {
            // 1. Check if the rule already exists
            var countryRateLimitRule = GetCountryRateLimitRule(wafPolicy, alertInfo.Country);

            // 2 If not, create it
            if (countryRateLimitRule != null)
            {
                wafPolicy.CustomRules.Rules.Remove(countryRateLimitRule);
            }
        }

        private static void DeleteRateLimitIPRule(WebApplicationFirewallPolicy wafPolicy, AlertInfo alertInfo)
        {
            // 1. Check if rule already exists
            var rateLimitIpsRule = GetRateLimitIPRuleByCountry(wafPolicy, alertInfo.Country);

            // 2. If yes, delete it
            if (rateLimitIpsRule != null)
            {
                wafPolicy.CustomRules.Rules.Remove(rateLimitIpsRule);
            }
        }

        private static void UpdateWafWithRulesToStopAttack(
            WebApplicationFirewallPolicy wafPolicy, 
            AlertInfo alertInfo, 
            IEnumerable<Row> logs)
        {
            // 1. Create or update a rule to rate limit country traffic
            CreateOrUpdateRateLimitCountryRule(wafPolicy, alertInfo);

            // 2. Create or update a rule to rate limit the IPs sending requests over dynamically detected baseline
            CreateOrUpdateRateLimitIpsRule(wafPolicy, alertInfo, logs);
        }

        private static void CreateOrUpdateRateLimitIpsRule(
            WebApplicationFirewallPolicy wafPolicy,
            AlertInfo alertInfo,
            IEnumerable<Row> logs)
        {
            if (logs == null || !logs.Any())
            {
                return;
            }

            // 1. Check if rule already exists
            var rateLimitIpsRule = GetRateLimitIPRuleByCountry(wafPolicy, alertInfo.Country);

            // 2. If not, create it
            if (rateLimitIpsRule == null)
            {
                // rule does not exist, create it
                rateLimitIpsRule = new CustomRule(
                    GetIpRateLimitPriorityByCountry(alertInfo.Country),
                    RuleType.RateLimitRule,
                    new List<MatchCondition>
                    {
                        new MatchCondition("RemoteAddr", "IPMatch", new List<string>())
                    },
                    "Block");

                rateLimitIpsRule.Name = $"{GetCountryCode(alertInfo.Country)}{MitigateDDOSRateLimitTopRequestIPsRuleNamePostfix}";
                rateLimitIpsRule.RateLimitDurationInMinutes = 5;

                wafPolicy.CustomRules.Rules.Add(rateLimitIpsRule);
            }

            // 3. Update the list of IPs to be blocked based on the most recent data
            var listOfIPsToRateLimit = logs.Select(r => r.clientIp_s).ToList();
            rateLimitIpsRule.MatchConditions[0].MatchValue = listOfIPsToRateLimit;
            rateLimitIpsRule.RateLimitThreshold = alertInfo.baselineThreshold < 100 ? 100 : alertInfo.baselineThreshold;
            rateLimitIpsRule.EnabledState = "Enabled";
        }

        private static void CreateOrUpdateRateLimitCountryRule(WebApplicationFirewallPolicy wafPolicy, AlertInfo alertInfo)
        {
            // 1. Check if the rule already exists
            var countryRateLimitRule = GetCountryRateLimitRule(wafPolicy, alertInfo.Country);

            // 2 If not, create it
            if (countryRateLimitRule == null)
            {
                countryRateLimitRule = CreateCountryRateLimitRule(alertInfo);
                wafPolicy.CustomRules.Rules.Add(countryRateLimitRule);
            }

            // 3. Update the rule with the new dynamic threshold baseline and enable it
            countryRateLimitRule.EnabledState = "Enabled";
            countryRateLimitRule.RateLimitThreshold =
                10 * alertInfo.baselineThreshold < 1000 ? 1000 : 10 * alertInfo.baselineThreshold;
        }

        private static CustomRule GetRateLimitIPRuleByCountry(WebApplicationFirewallPolicy wafPolicy, string alertInfoCountry)
        {
            return wafPolicy.CustomRules.Rules?.FirstOrDefault(rule =>
                rule.Name == $"{GetCountryCode(alertInfoCountry)}{MitigateDDOSRateLimitTopRequestIPsRuleNamePostfix}");
        }

        private static CustomRule CreateCountryRateLimitRule(AlertInfo alertInfo)
        {
            var alertCountryCode = GetCountryCode(alertInfo.Country);

            return new CustomRule(
                GetCountryRateLimitPriority(alertCountryCode),
                RuleType.RateLimitRule,
                new List<MatchCondition>
                {
                    new MatchCondition("RemoteAddr", "GeoMatch", new List<string> { alertCountryCode })
                },
                "Block")
            {
                Name = $"{alertCountryCode}{MitigateDDOSRateLimitCountryRuleNamePostfix}",
                RateLimitDurationInMinutes = 5
            };
        }

        private static CustomRule GetCountryRateLimitRule(
            WebApplicationFirewallPolicy webApplicationFirewallPolicy,
            string alertCountry)
        {
            return webApplicationFirewallPolicy.CustomRules.Rules.FirstOrDefault(rule =>
                rule.Name == $"{GetCountryCode(alertCountry)}{MitigateDDOSRateLimitCountryRuleNamePostfix}");
        }

        /// <summary>
        /// Convert this and priority switch to a dict and enum
        /// </summary>
        /// <param name="country"></param>
        /// <returns></returns>
        private static string GetCountryCode(string country)
        {
            return country.ToLower() switch
            {
                "united states" => "US",
                "unitedstates" => "US",
                "canada" => "CA",
                "brazil" => "BR",
                "ireland" => "IE",
                "australia" => "AU",
                "singapore" => "SG",
                "japan" => "JP",
                "france" => "FR",
                "india" => "IN",
                _ => country
            };
        }

        private static int GetCountryRateLimitPriority(string countryCode)
        {
            return countryCode switch
            {
                "US" => 1,
                "CA" => 2,
                "BR" => 3,
                "IE" => 4,
                "AU" => 5,
                "SG" => 6,
                "JP" => 7,
                "FR" => 8,
                "IN" => 9,
                _ => new Random().Next(10, 1000)
            };
        }

        private static int GetIpRateLimitPriorityByCountry(string country)
        {
            return country.ToLower() switch
            {
                "united states" => 1001,
                "unitedStates" => 1001,
                "canada" => 1002,
                "brazil" => 1003,
                "ireland" => 1004,
                "australia" => 1005,
                "singapore" => 1006,
                "japan" => 1007,
                "france" => 1008,
                "india" => 1009,
                _ => new Random().Next(1100, 2000)
            };
        }

        private static async Task<IEnumerable<Row>> GetLogs(ILogger log, AlertInfo alertInfo)
        {
            // 1. Prepare the credentials to get logs, we need a aad app which has permissions to view the log
            string workspaceId = "";
            var credential = new ClientSecretCredential(TenantId, ClientId, ClientSecret);
            var logsClient = new LogsQueryClient(credential);

            var topIPs =
                "AzureDiagnostics " +
                "| where Category == \"FrontDoorAccessLog\" " +
                $"| where _ResourceId == \"{FrontdoorResourceId}\"" +
                $"| where clientCountry_s == \"{alertInfo.Country}\"" +
                "| summarize requestCount = count() by clientIp_s" +
                $"| where requestCount > {alertInfo.baselineThreshold}" +
                "| order by requestCount desc";

            try
            {
                var response = await logsClient.QueryWorkspaceAsync<Row>(
                    workspaceId,
                    topIPs,
                    new QueryTimeRange(TimeSpan.FromMinutes(20)));

                return response.Value;
            }
            catch (Exception ex)
            {
                log.LogError($"Exception while querying log analytics workspace", ex);
                throw;
            }
        }
    }
}
