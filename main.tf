locals {
  tags = merge(var.tags, { ManagedByTerraform = "True" })
}

/*
Soft delete is enabled by default with option to make it always-on (irreversible). 
Soft deleted backup data is retained at no additional cost for 14 days, with option to extend the duration. 
Enabling immutability on vaults can protect backup data by blocking any operations that could lead to loss of recovery points. 
You can configure Multi-user authorization (MUA) for Azure Backup as an additional layer of protection to critical operations on your Recovery Services vaults
*/

resource "azurerm_recovery_services_vault" "default" {
  name                          = "${var.vault.name}-rsv"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.vault.sku
  soft_delete_enabled           = var.vault.soft_delete_enabled
  public_network_access_enabled = var.vault.public_network_access_enabled
  storage_mode_type             = var.vault.storage_mode_type
  cross_region_restore_enabled  = var.vault.cross_region_restore_enabled
  immutability                  = var.vault.immutability
  tags                          = local.tags

  dynamic "monitoring" {
    for_each = var.vault.monitoring == null ? [] : [var.vault.monitoring]
    content {
      alerts_for_all_job_failures_enabled            = monitoring.value.alerts_for_all_job_failures_enabled
      alerts_for_critical_operation_failures_enabled = monitoring.value.alerts_for_critical_operation_failures_enabled
    }
  }

  dynamic "identity" {
    for_each = var.vault.identity == null ? [] : [var.vault.identity]
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "encryption" {
    for_each = var.vault.encryption == null ? [] : [var.vault.encryption]
    content {
      key_id                            = encryption.value.key_id
      infrastructure_encryption_enabled = encryption.value.infrastructure_encryption_enabled
      user_assigned_identity_id         = encryption.value.user_assigned_identity_id
      use_system_assigned_identity      = encryption.value.use_system_assigned_identity
    }
  }
}

#Resource Guard association
resource "azurerm_recovery_services_vault_resource_guard_association" "default" {
  count             = var.resource_guard_id == null ? 0 : 1
  name              = "VaultProxy"
  vault_id          = azurerm_recovery_services_vault.default.id
  resource_guard_id = var.resource_guard_id[0]
}

resource "azurerm_backup_policy_vm" "default" {
  for_each                       = var.vm_policy == null ? {} : { for key, value in var.vm_policy : key => value }
  name                           = "${each.key}-bkpol"
  resource_group_name            = var.resource_group_name
  recovery_vault_name            = azurerm_recovery_services_vault.default.name
  instant_restore_retention_days = each.value.instant_restore_retention_days
  policy_type                    = each.value.policy_type
  timezone                       = each.value.timezone

  dynamic "instant_restore_resource_group" {
    for_each = each.value.instant_restore_resource_group == null ? [] : [each.value.instant_restore_resource_group]
    content {
      prefix = instant_restore_resource_group.value.prefix
      suffix = instant_restore_resource_group.value.suffix
    }
  }

  backup {
    frequency     = each.value.frequency
    time          = each.value.time
    hour_interval = each.value.frequency == "Hourly" ? each.value.hour_interval : null
    hour_duration = each.value.frequency == "Hourly" ? each.value.hour_duration : null
    weekdays      = each.value.weekdays
  }

  dynamic "retention_daily" {
    for_each = each.value.frequency == "Weekly" ? [] : [each.value.daily_retention]
    content {
      count = each.value.daily_retention
    }
  }

  dynamic "retention_weekly" {
    for_each = each.value.retention_weekly == null ? [] : [each.value.retention_weekly]
    content {
      count    = retention_weekly.value.count
      weekdays = retention_weekly.value.weekdays
    }
  }

  dynamic "retention_monthly" {
    for_each = each.value.retention_monthly == null ? [] : [each.value.retention_monthly]
    content {
      count             = retention_monthly.value.count
      weekdays          = retention_monthly.value.weekdays
      weeks             = retention_monthly.value.weeks
      days              = retention_monthly.value.days
      include_last_days = retention_monthly.value.include_last_days
    }
  }

  dynamic "retention_yearly" {
    for_each = each.value.retention_yearly == null ? [] : [each.value.retention_yearly]
    content {
      count             = retention_yearly.value.count
      months            = retention_yearly.value.months
      weekdays          = retention_yearly.value.weekdays
      weeks             = retention_yearly.value.weeks
      days              = retention_yearly.value.days
      include_last_days = retention_yearly.value.include_last_days
    }
  }
}

resource "azurerm_backup_policy_file_share" "default" {
  for_each            = var.fileshare_policy == null ? {} : { for key, value in var.fileshare_policy : key => value }
  name                = "${each.key}-bkpol"
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.default.name
  timezone            = each.value.timezone

  backup {
    frequency = each.value.frequency
    time      = each.value.hourly == null ? each.value.time : null

    dynamic "hourly" {
      for_each = each.value.hourly == null ? [] : [each.value.hourly]
      content {
        interval        = hourly.value.interval
        start_time      = hourly.value.start_time
        window_duration = hourly.value.window_duration
      }
    }
  }

  dynamic "retention_daily" {
    for_each = each.value.daily_retention == null ? [] : [each.value.daily_retention]
    content {
      count = each.value.daily_retention
    }
  }

  dynamic "retention_weekly" {
    for_each = each.value.retention_weekly == null ? [] : [each.value.retention_weekly]
    content {
      count    = retention_weekly.value.count
      weekdays = retention_weekly.value.weekdays
    }
  }

  dynamic "retention_monthly" {
    for_each = each.value.retention_monthly == null ? [] : [each.value.retention_monthly]
    content {
      count             = retention_monthly.value.count
      weekdays          = retention_monthly.value.weekdays
      weeks             = retention_monthly.value.weeks
      days              = retention_monthly.value.days
      include_last_days = retention_monthly.value.include_last_days
    }
  }

  dynamic "retention_yearly" {
    for_each = each.value.retention_yearly == null ? [] : [each.value.retention_yearly]
    content {
      count             = retention_yearly.value.count
      months            = retention_yearly.value.months
      weekdays          = retention_yearly.value.weekdays
      weeks             = retention_yearly.value.weeks
      days              = retention_yearly.value.days
      include_last_days = retention_yearly.value.include_last_days
    }
  }
}


resource "azurerm_backup_policy_vm_workload" "default" {
  for_each            = var.workload_policy == null ? {} : { for key, value in var.workload_policy : key => value }
  name                = "${each.key}-bkpol"
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.default.name

  workload_type = each.value.workload_type

  settings {
    time_zone           = each.value.timezone
    compression_enabled = each.value.compression_enabled
  }

  protection_policy {
    policy_type = "Full"

    backup {
      frequency = each.value.frequency
      weekdays  = each.value.frequency == "Weekly" ? each.value.weekdays : null
      time      = each.value.time
    }

    dynamic "retention_daily" {
      for_each = each.value.daily_retention != null && each.value.frequency == "Daily" ? [each.value.daily_retention] : []
      content {
        count = each.value.daily_retention
      }
    }

    dynamic "retention_weekly" {
      for_each = each.value.retention_weekly == null ? [] : [each.value.retention_weekly]
      content {
        count    = retention_weekly.value.count
        weekdays = retention_weekly.value.weekdays
      }
    }

    dynamic "retention_monthly" {
      for_each = each.value.retention_monthly == null ? [] : [each.value.retention_monthly]
      content {
        count       = retention_monthly.value.count
        format_type = retention_monthly.value.monthdays == null ? "Weekly" : "Daily"
        weekdays    = retention_monthly.value.weekdays
        weeks       = retention_monthly.value.weeks
        monthdays   = retention_monthly.value.monthdays
      }
    }

    dynamic "retention_yearly" {
      for_each = each.value.retention_yearly == null ? [] : [each.value.retention_yearly]
      content {
        count       = retention_yearly.value.count
        format_type = retention_yearly.value.monthdays == null ? "Weekly" : "Daily"
        months      = retention_yearly.value.months
        weekdays    = retention_yearly.value.weekdays
        weeks       = retention_yearly.value.weeks
        monthdays   = retention_yearly.value.monthdays
      }
    }
  }

  dynamic "protection_policy" {
    for_each = each.value.differential != null ? [each.value.differential] : []
    content {
      policy_type = "Differential"

      backup {
        frequency = each.value.frequency
        weekdays  = protection_policy.value.weekdays
        time      = protection_policy.value.time
      }

      simple_retention {
        count = protection_policy.value.count
      }
    }
  }

  dynamic "protection_policy" {
    for_each = each.value.incremental != null && each.value.workload_type == "SAPHanaDatabase" ? [each.value.incremental] : []
    content {
      policy_type = "Incremental"

      backup {
        frequency = each.value.frequency
        weekdays  = protection_policy.value.weekdays
        time      = protection_policy.value.time
      }

      simple_retention {
        count = protection_policy.value.count
      }
    }
  }

  dynamic "protection_policy" {
    for_each = each.value.log != null ? [each.value.log] : []
    content {
      policy_type = "Log"

      backup {
        frequency_in_minutes = protection_policy.value.frequency_in_minutes
      }

      simple_retention {
        count = protection_policy.value.count
      }
    }
  }
}
