# Azure Recovery Services Vault Terraform module

Terraform module which creates Azure Recovery Services Vault resources on Azure.

These types of resources are supported:

* [Azure Recovery Services vaults](https://learn.microsoft.com/en-us/azure/backup/backup-azure-recovery-services-vault-overview)
* [Azure VM backups](https://learn.microsoft.com/en-us/azure/backup/backup-support-matrix-iaas)
* [SQL Server Backup in Azure VMs](https://learn.microsoft.com/en-us/azure/backup/sql-support-matrix)
* [SAP HANA databases on Azure VMs](https://learn.microsoft.com/en-us/azure/backup/sap-hana-backup-support-matrix)
* [Azure file share backup](https://learn.microsoft.com/en-us/azure/backup/azure-file-share-support-matrix)

## Terraform versions

Terraform 1.5.6 and newer.

## Usage

```hcl
module "prd-rsv" {
  source              = "jsathler/recovery-services-vault/azurerm"
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location

  vault = {
    name              = "prd"
    storage_mode_type = "GeoRedundant"
  }

  vm_policy = {
    "default-vm" = { retention_weekly = {}, retention_monthly = {}, retention_yearly = {} }
    "hourly-vm"  = { frequency = "Hourly", retention_weekly = {}, retention_monthly = {}, retention_yearly = {} }
  }
  fileshare_policy = {
    "default-fs" = { retention_weekly = {}, retention_monthly = {}, retention_yearly = {} }
    "hourly-fs"  = { frequency = "Hourly", hourly = {}, retention_weekly = {}, retention_monthly = {}, retention_yearly = { count = 5 } }
  }

  workload_policy = {
    default-mssql       = { retention_weekly = {}, retention_monthly = {}, retention_yearly = {} }
    full-log-mssql      = { compression_enabled = true, retention_weekly = {}, retention_monthly = {}, retention_yearly = {}, log = {} }
    full-diff-log-mssql = { frequency = "Weekly", retention_weekly = {}, retention_monthly = {}, retention_yearly = {}, differential = { time = "01:00" }, log = {} }

    # SAP for HANA requires Log backup
    default-saphana       = { workload_type = "SAPHanaDatabase", retention_weekly = {}, retention_monthly = {}, retention_yearly = {}, log = {} }
    full-inc-log-saphana  = { workload_type = "SAPHanaDatabase", frequency = "Weekly", retention_weekly = {}, retention_monthly = {}, retention_yearly = {}, incremental = { time = "01:00" }, log = {} }
    full-diff-log-saphana = { workload_type = "SAPHanaDatabase", frequency = "Weekly", retention_weekly = {}, retention_monthly = {}, retention_yearly = {}, differential = { time = "01:00" }, log = {} }
  }
}
```

More samples in examples folder