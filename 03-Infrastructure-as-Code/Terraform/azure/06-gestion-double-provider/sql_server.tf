# SQL Server avec Azure AD Admin
resource "azurerm_mssql_server" "sqlserver" {
  name                         = "mssqlserver-${random_string.suffix.result}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "P@ssw0rd123!"

  minimum_tls_version = "1.2"

}

# Base de données SQL
resource "azurerm_mssql_database" "sqldb" {
  name      = "mydb${random_string.suffix.result}"
  server_id = azurerm_mssql_server.sqlserver.id
  sku_name  = "Basic"

  max_size_gb = 2
}

# Règle de firewall
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
