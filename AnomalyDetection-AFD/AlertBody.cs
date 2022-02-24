// //////////////////////////////////////////////////////////////////////////////
// 
//  Copyright (C) Microsoft Corporation. All rights reserved.
// 
// //////////////////////////////////////////////////////////////////////////////

namespace processAfdAlerts
{
    using System;

    public class AlertBody
    {
        public string schemaId { get; set; }
        public Data data { get; set; }
    }

    public class Data
    {
        public Essentials essentials { get; set; }
        public Alertcontext alertContext { get; set; }
    }

    public class Essentials
    {
        public string alertId { get; set; }
        public string alertRule { get; set; }
        public string severity { get; set; }
        public string signalType { get; set; }
        public string monitorCondition { get; set; }
        public string monitoringService { get; set; }
        public string[] alertTargetIDs { get; set; }
        public string[] configurationItems { get; set; }
        public string originAlertId { get; set; }
        public DateTime firedDateTime { get; set; }
        public string description { get; set; }
        public string essentialsVersion { get; set; }
        public string alertContextVersion { get; set; }
    }

    public class Alertcontext
    {
        public object properties { get; set; }
        public string conditionType { get; set; }
        public Condition condition { get; set; }
    }

    public class Condition
    {
        public string windowSize { get; set; }
        public Allof[] allOf { get; set; }
        public DateTime windowStartTime { get; set; }
        public DateTime windowEndTime { get; set; }
    }

    public class Allof
    {
        public string alertSensitivity { get; set; }
        public Failingperiods failingPeriods { get; set; }
        public object ignoreDataBefore { get; set; }
        public string metricName { get; set; }
        public string metricNamespace { get; set; }
        public string _operator { get; set; }
        public string threshold { get; set; }
        public string timeAggregation { get; set; }
        public Dimension[] dimensions { get; set; }
        public float? metricValue { get; set; }
        public object webTestName { get; set; }
    }

    public class Failingperiods
    {
        public int numberOfEvaluationPeriods { get; set; }
        public int minFailingPeriodsToAlert { get; set; }
    }

    public class Dimension
    {
        public string name { get; set; }
        public string value { get; set; }
    }

    public class AlertInfo
    {
        public string Country { get; set; }
        public int baselineThreshold { get; set; }
    }
}
