# Azure WAF Attack Testing Lab Environment Terraform Deployment Template
This Terraform deployment includes everything needed to test Azure WAF Security components.  Below are the differences from the default Azure Network Security deployment template.

- A custom Docker image with a modified version of the OWASP Juice Shop application
- Built-in Azure Firewall rules to allow inbound and outbound connectivity for the Kali VM

This [blogpost](https://techcommunity.microsoft.com/t5/azure-network-security-blog/part-1-lab-setup-azure-waf-security-protection-and-detection-lab/ba-p/2030469) provides additional guidance into how this lab works and testing out WAF attack scenarios.  

Update your variables.tf and terraform.tfvars
* vm_admin
* vm_password
* unique_name

**Example Terraform command:**
>terraform plan
>terraform apply


## What is included with the AzNetSec Terraform Deployment Template

| Resource |  Purpose |
|----------|---------|
| Virtual Network-1 |  VN1(Hub) has 2 Subnets 10.0.25.0/26 & 10.0.25.64/26 peered to VN1 and VN2 (Enabled with DDoSProtection)|
| Virtual Network-2 |  VN2(Spoke1) has 2 Subnets 10.0.27.0/26 & 10.0.27.64/26 peered to VN2 |
| Virtual Network-3 |  VN3(Spoke2) has 2 Subnets 10.0.28.0/26 & 10.0.28.64/26 peered to VN1 |
| PublicIPAddress-1 |  Static Public IP address for Application gateway |
| PublicIPAddress-2 |  Static Public IP address for Azure firewall |
| Virtual Machine-1 | Windows 10 Machine connected to VN2(subnet1) |
| Virtual Machine-2 | Kali Linux Box connected to VN2(subnet2) |
| Virtual Machine-3 | Server 2019 Machine connected to VN3(subnet1) |
| Network Security Group-1 | Pre-configured NSG to Virtual Networks associated to VN2 subnets |
| Network Security Group-2 | Pre-configured NSG to Virtual Networks associated to VN3 subnets |
| Route Table | Pre-configured RT Associated to VN2 and VN3 subnets with default route pointing to Azure firewall private IP address |
| Application Gateway v2 (WAF) | Pre-configured to publish webapp on HTTP on Public Interface|
| Azure Firewall with Firewall Manager | Pre-configured with RDP(DNAT) rules to 3 VM's and allow search engine access(application rules) from VM's. Network rule configured to allow SMB, RDP and SSH access between VM's. Azure firewall is deployed in Hub Virtual Network managed by Firewall manager |
| Premium Frontdoor | Pre-configured designer with Backend pool as Applicaion gateway public interface  |
| WebApp(PaaS) | Pre-configured app for Frontdoor and Application Gateway WAF testing |

![WAF Attack Lab Architecture](https://github.com/dannytumsft/OWASPDemoIaC/raw/main/images/wafattacklabarch.png "WAF Attack Lab Architecture")
