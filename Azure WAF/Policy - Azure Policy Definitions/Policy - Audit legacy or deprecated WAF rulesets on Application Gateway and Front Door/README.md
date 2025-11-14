# Audit Legacy and Deprecated WAF Rulesets
This Azure Policy definition audits Web Application Firewall policies that use legacy or deprecated OWASP Core Rule Set (CRS) or Microsoft Default Rule Set (DRS) rulesets across Application Gateway and Azure Front Door.
It is important to use the latest rulesets instead of deprecated ones to benefit from improved security coverage and reduced false positives that come with newer rule versions.
Azure Front Door Standard WAF policies will show as **Compliant** since they do not support managed rulesets by design. This is expected behavior as Standard tier policies cannot use deprecated rulesets (or any managed rulesets).
