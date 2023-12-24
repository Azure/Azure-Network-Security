variable "resourceGroupName" {
    type = string
    description = "Name of Resource Group"
    default = "rgAzNetSecLab"  
}

variable "location" {
    type = string
    description = "Location of your Resource Group"
    default = "eastus"
}

variable "AzFrontDoor" {
    type = string
    description = "Name of Azure Front Door instance"
}

variable "WebAppName" {
    type = string
    description = "Azure Web App Name"
}

variable "Log_analytics_name" {
    type = string
    description = "Name of Log Analytics Workspace"
}

variable "App_Gateway" {
    type = string
    description = "Name of Application Gateway"
}

variable "vm_admin" {
    type = string
    description = "Username for Virtual Machine"
}

variable "vm_password" {
    type = string
    description = "Password for Virtual Machine Admin User"
    sensitive = true
}

variable "unique_name" {
    type = string
    description = "Unique Name"
}

variable "hostname" {
    type = string
    description = "Host Name"
    default = "demowasp"  
}
