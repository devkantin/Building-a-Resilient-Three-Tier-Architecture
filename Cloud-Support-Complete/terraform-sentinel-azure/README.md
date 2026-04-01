# Azure Terraform Sentinel Policies

This directory contains a comprehensive collection of Terraform Sentinel policies for enforcing infrastructure as code best practices across Azure resources.

## Overview

Sentinel is a policy-as-code framework used by Terraform Cloud and Terraform Enterprise to enforce policies on Terraform configurations before they are applied.

## Policies Included (21 Total)

### Core Infrastructure Security

1. **azure_vm_security.sentinel** - VM security, managed disks, encryption, tagging
2. **azure_sql_database_security.sentinel** - SQL/PostgreSQL/MySQL TLS, Azure AD auth, backup
3. **azure_storage_encryption.sentinel** - Storage HTTPS, encryption, access tiers, network rules
4. **azure_app_service_security.sentinel** - App Service HTTPS, TLS, auth, VPC integration

### Container & Orchestration

5. **azure_aks_security.sentinel** - AKS RBAC, network policies, logging, pod security
6. **azure_container_registry.sentinel** - Registry encryption, admin disabled, image scanning

### Identity & Access

7. **azure_keyvault_security.sentinel** - Key Vault purge protection, RBAC, network ACLs
8. **azure_rbac_access_control.sentinel** - RBAC enforcement, managed identities, custom roles

### Data Protection & Compliance

9. **azure_database_backup.sentinel** - Database backup retention, geo-redundancy
10. **azure_data_protection.sentinel** - Encryption, data classification, TDE
11. **azure_backup_recovery.sentinel** - Backup vaults, retention policies, disaster recovery

### Network Security

12. **azure_network_security.sentinel** - NSG rules, SSH/RDP restrictions, VPC DDoS
13. **azure_private_endpoints.sentinel** - Private endpoints, Private Link, network isolation
14. **azure_firewall_ddos.sentinel** - Azure Firewall, DDoS protection, WAF configuration

### Monitoring & Compliance

15. **azure_monitoring_logging.sentinel** - Log Analytics, diagnostic settings, alerts
16. **azure_compliance_cis.sentinel** - CIS benchmarks, threat detection, auditing

### Governance

17. **azure_resource_tagging.sentinel** - Required tags, naming conventions, classifications
18. **azure_cost_control.sentinel** - VM SKUs, App Service tiers, spot instances

### Configuration Files

- **sentinel.hcl** - Policy configuration with enforcement levels (21 policies, mostly mandatory)
- **README.md** - Comprehensive documentation

## Policy Categories by Enforcement Level

### Mandatory Policies (19)
These policies must pass; apply cannot proceed without compliance:
- All security policies (VM, SQL, Storage, App Service, AKS, Key Vault)
- All network policies (NSG, firewall, private endpoints)
- All compliance policies (CIS, monitoring, data protection)
- All backup and disaster recovery policies
- All RBAC and access control policies
- Resource tagging enforcement

### Soft-Mandatory Policies (2)
These policies show violations but can be overridden:
- Cost control policies (VM SKUs, database tiers)

## Implementation Guide

### 1. Setup in Terraform Cloud/Enterprise

Add to your Terraform configuration:

```hcl
terraform {
  cloud {
    organization = "your-org"
    
    workspaces {
      name = "your-workspace"
    }
  }
}
```

### 2. Configure Policy Set

1. Navigate to Settings > Policy Sets in Terraform Cloud/Enterprise
2. Create a new policy set: `azure-best-practices`
3. Point to this repository
4. Set policy VCS path: `terraform-sentinel-azure/`
5. Connect to appropriate workspaces

### 3. Apply Policies

Policies automatically run on:
- **Plan**: Shows violations before apply
- **Apply**: Enforces mandatory policies
- **Override**: Available for soft-mandatory policies

## Usage Examples

### Example: Azure VM with Security Best Practices

```hcl
resource "azurerm_linux_virtual_machine" "example" {
  name                = "myvm"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  
  size = "Standard_D2s_v3"
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = {
    Environment = "production"
    Owner       = "devops-team"
    CostCenter  = "engineering"
    Application = "web-server"
  }
}
```

### Example: Secure Azure SQL Database

```hcl
resource "azurerm_mssql_server" "example" {
  name                         = "myserver"
  location                     = azurerm_resource_group.example.location
  resource_group_name          = azurerm_resource_group.example.name
  administrator_login          = "sqladmin"
  administrator_login_password = var.sql_password
  
  minimum_tls_version = "1.2"
  
  azuread_administrator {
    login_username              = "AzureAD Admin"
    object_id                   = data.azuread_client_config.current.object_id
    azuread_authentication_only = true
  }
  
  tags = {
    Environment = "production"
  }
}

resource "azurerm_mssql_database" "example" {
  name           = "mydb"
  server_id      = azurerm_mssql_server.example.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 250
  sku_name       = "S1"
  
  short_term_retention_policy {
    retention_days = 35
  }
}
```

### Example: Secure Storage Account

```hcl
resource "azurerm_storage_account" "example" {
  name                     = "mystorageaccount"
  location                 = azurerm_resource_group.example.location
  resource_group_name      = azurerm_resource_group.example.name
  account_tier             = "Standard"
  account_replication_type = "GRS"
  
  https_traffic_only_enabled       = true
  infrastructure_encryption_enabled = true
  minimum_tls_version              = "TLS1_2"
  
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
  
  tags = {
    Environment        = "production"
    DataClassification = "Confidential"
  }
}
```

### Example: Secure AKS Cluster

```hcl
resource "azurerm_kubernetes_cluster" "example" {
  name                = "myaks"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  dns_prefix          = "myaks"
  
  default_node_pool {
    name            = "default"
    node_count      = 3
    vm_size         = "Standard_D2s_v3"
    os_disk_size_gb = 30
  }
  
  identity {
    type = "SystemAssigned"
  }
  
  network_profile {
    network_policy = "azure"
  }
  
  role_based_access_control_enabled = true
  
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id
  }
  
  tags = {
    Environment = "production"
  }
}
```

## Required Tags

All resources should have:
- `Environment` (dev, staging, production)
- `Owner` (team or person responsible)
- `CostCenter` (cost allocation code)

Application/compute resources also require:
- `Application` (application name)

Optional but recommended:
- `DataClassification` (Public, Internal, Confidential, PII, Secret)
- `BackupPolicy` (for production resources)
- `MaintenanceWindow` (for production resources)

## Customization

To customize policies:

1. Edit specific policy files
2. Update enforcement levels in `sentinel.hcl`
3. Modify required tags in `azure_resource_tagging.sentinel`
4. Push changes to your VCS
5. Policies update automatically in Terraform Cloud/Enterprise

## Cost Optimization

The cost control policies help reduce expenses by:
- Restricting expensive VM SKUs
- Preventing unnecessary database tier upgrades
- Recommending spot instances for non-production
- Enforcing auto-scaling for AKS clusters

## Compliance Standards Covered

- **CIS Azure Foundations Benchmark**
- **HIPAA** (via encryption and audit logging)
- **PCI-DSS** (via network isolation and monitoring)
- **SOC2** (via logging and access controls)
- **GDPR** (via data protection and retention)

## Support and Best Practices

1. **Start Advisory**: Begin with advisory policies
2. **Graduate Gradually**: Move to soft-mandatory then mandatory
3. **Monitor Violations**: Regular review of policy results
4. **Update Regularly**: Keep policies current with security standards
5. **Document Changes**: Track all policy modifications

## References

- [Terraform Sentinel Documentation](https://www.terraform.io/cloud-docs/sentinel)
- [Azure Security Best Practices](https://docs.microsoft.com/en-us/azure/security/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [CIS Azure Benchmarks](https://www.cisecurity.org/cis-benchmarks/)
