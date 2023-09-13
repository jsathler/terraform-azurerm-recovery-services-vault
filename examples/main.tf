provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "default" {
  name     = "rsv-example-rg"
  location = "northeurope"
}

# Create a recover service vault with ZoneRedundant storage mode and immutability disabled
module "devtest-rsv" {
  source              = "../"
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location

  # If your devtest subscription is different from prd, you can create a new provider and replace the alias bellow
  # providers = {
  #   azurerm = azurerm.<alias>
  # }

  vault = {
    name         = "devtest"
    immutability = "Disabled"
  }

  vm_policy = {
    "default-vm" = { retention_weekly = { count = 2 }, retention_monthly = { count = 2 }, retention_yearly = { count = 1 } }
    "weekly-vm" = { frequency = "Weekly", instant_restore_retention_days = 5, weekdays = ["Saturday"]
      retention_weekly  = { count = 2, weekdays = ["Saturday"] }
      retention_monthly = { count = 6, weekdays = ["Saturday"] }
    }
  }
  fileshare_policy = {
    "default-fs" = { retention_weekly = { count = 2 }, retention_monthly = { count = 2 }, retention_yearly = { count = 1 } }
  }

  workload_policy = {
    # MSSQL doesn't support Incremental backups
    default-mssql       = { retention_weekly = { count = 2 }, retention_monthly = { count = 2 }, retention_yearly = { count = 1 } }
    full-log-mssql      = { compression_enabled = true, retention_weekly = { count = 2 }, retention_monthly = { count = 2 }, retention_yearly = { count = 1 } }
    full-diff-log-mssql = { frequency = "Weekly", retention_weekly = { count = 2 }, retention_monthly = { count = 2 }, retention_yearly = { count = 1 }, differential = { time = "01:00" }, log = {} }

    # SAP for HANA requires Log backup
    default-saphana       = { workload_type = "SAPHanaDatabase", retention_weekly = { count = 2 }, retention_monthly = { count = 2 }, retention_yearly = { count = 1 }, log = {} }
    full-inc-log-saphana  = { workload_type = "SAPHanaDatabase", frequency = "Weekly", retention_weekly = { count = 2 }, retention_monthly = { count = 2 }, retention_yearly = { count = 1 }, incremental = { time = "01:00" }, log = {} }
    full-diff-log-saphana = { workload_type = "SAPHanaDatabase", frequency = "Weekly", retention_weekly = { count = 2 }, retention_monthly = { count = 2 }, retention_yearly = { count = 1 }, differential = { time = "01:00" }, log = {} }
  }
}

# Create a recover service vault with GeoRedundant storage mode and immutability Unlocked
module "prd-rsv" {
  source              = "../"
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
    # MSSQL doesn't support Incremental backups
    default-mssql       = { retention_weekly = {}, retention_monthly = {}, retention_yearly = {} }
    full-log-mssql      = { compression_enabled = true, retention_weekly = {}, retention_monthly = {}, retention_yearly = {}, log = {} }
    full-diff-log-mssql = { frequency = "Weekly", retention_weekly = {}, retention_monthly = {}, retention_yearly = {}, differential = { time = "01:00" }, log = {} }

    # SAP for HANA requires Log backup
    default-saphana       = { workload_type = "SAPHanaDatabase", retention_weekly = {}, retention_monthly = {}, retention_yearly = {}, log = {} }
    full-inc-log-saphana  = { workload_type = "SAPHanaDatabase", frequency = "Weekly", retention_weekly = {}, retention_monthly = {}, retention_yearly = {}, incremental = { time = "01:00" }, log = {} }
    full-diff-log-saphana = { workload_type = "SAPHanaDatabase", frequency = "Weekly", retention_weekly = {}, retention_monthly = {}, retention_yearly = {}, differential = { time = "01:00" }, log = {} }
  }
}

output "devtest-rsv" {
  value = module.devtest-rsv
}

output "prd-rsv" {
  value = module.prd-rsv
}
