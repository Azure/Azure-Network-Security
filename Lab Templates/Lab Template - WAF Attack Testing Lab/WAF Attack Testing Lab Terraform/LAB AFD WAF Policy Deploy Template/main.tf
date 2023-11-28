resource "azurerm_resource_group" "azurg" {
  name     = var.azurgname
  location = "East US"
}

resource "azurerm_cdn_frontdoor_firewall_policy" "azafdwafpolicy" {
  custom_block_response_body        = "QmxvY2tlZCBieSBmcm9udCBkb29yIFdBRg=="
  custom_block_response_status_code = 403
  mode                              = "Prevention"
  name                              = var.afdwafpolicyname
  resource_group_name               = azurerm_resource_group.azurg.name
  redirect_url                      = "https://www.microsoft.com/en-us/edge"
  sku_name                          = "Premium_AzureFrontDoor"
  custom_rule {
    action               = "Block"
    name                 = "BlockGeoLocationChina"
    priority             = 10
    rate_limit_threshold = 100
    type                 = "MatchRule"
    match_condition {
      match_values   = ["CN"]
      match_variable = "RemoteAddr"
      operator       = "GeoMatch"
    }
  }
  custom_rule {
    action               = "Redirect"
    name                 = "RedirectInternetExplorerUserAgent"
    priority             = 20
    rate_limit_threshold = 100
    type                 = "MatchRule"
    match_condition {
      match_values   = ["rv:11.0"]
      match_variable = "RequestHeader"
      operator       = "Contains"
      selector       = "User-Agent"
    }
  }
  custom_rule {
    action               = "Block"
    name                 = "RateLimitRequest"
    priority             = 30
    rate_limit_threshold = 1
    type                 = "RateLimitRule"
    match_condition {
      match_values   = ["search"]
      match_variable = "RequestUri"
      operator       = "Contains"
    }
  }
  managed_rule {
    action  = "Block"
    type    = "DefaultRuleSet"
    version = "1.0"
  }
  managed_rule {
    action  = "Block"
    type    = "BotProtection"
    version = "preview-0.1"
  }
}