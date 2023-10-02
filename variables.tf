variable "location" {
  description = "The region where the VM will be created. This parameter is required"
  type        = string
  default     = "northeurope"
}

variable "resource_group_name" {
  description = "The name of the resource group in which the resources will be created. This parameter is required"
  type        = string
}

variable "tags" {
  description = "Tags to be applied to resources."
  type        = map(string)
  default     = null
}

variable "vault" {
  description = <<DESCRIPTION
  Recovery Services Vault properties
  - name:                                               (required) Specifies the name of the Recovery Services Vault. Recovery Service Vault name must be 2 - 50 characters long
  - sku:                                                (optional) Sets the vault's SKU. Possible values include: Standard, RS0. Defaults to 'Standard'
  - soft_delete_enabled:                                (optional) Is soft delete enable for this Vault? Defaults to 'true'
  - public_network_access_enabled:                      (optional) Is it enabled to access the vault from public networks. Defaults to 'true'
  - storage_mode_type:                                  (optional) The storage type of the Recovery Services Vault. Possible values are GeoRedundant, LocallyRedundant and ZoneRedundant. Defaults to 'ZoneRedundant'
  - cross_region_restore_enabled:                       (optional) Is cross region restore enabled for this Vault? Only can be true, when storage_mode_type is GeoRedundant. Defaults to 'false'
  - immutability:                                       (optional) Immutability Settings of vault, possible values include: Locked, Unlocked and Disabled. Defaults to 'Unlocked'
  - identity:                                           (optional) A block as defined bellow 
     - type:                                            (required) Specifies the type of Managed Service Identity that should be configured on this Recovery Services Vault. Possible values are 'SystemAssigned', 'UserAssigned', 'SystemAssigned, UserAssigned'
     - identity_ids:                                    (optional) A list of User Assigned Managed Identity IDs to be assigned to this RSV
  - encryption:                                         (optional) A block as defined bellow 
     - key_id:                                          (required) The Key Vault key id used to encrypt this vault
     - infrastructure_encryption_enabled:               (required) Enabling/Disabling the Double Encryption state. Defaults to 'false'
     - user_assigned_identity_id:                       (optional) Specifies the user assigned identity ID to be used
     - use_system_assigned_identity:                    (optional) Indicate that system assigned identity should be used or not. If you want to enable encryption during RSV creation, you should use User assigned Managed Identity. Defaults to 'false'
  - monitoring:                                         (optional) A block as defined bellow 
     - alerts_for_all_job_failures_enabled:             (optional) Enabling/Disabling built-in Azure Monitor alerts for security scenarios and job failure scenarios. Defaults to 'false'
     - alerts_for_critical_operation_failures_enabled:  (optional) Enabling/Disabling alerts from the older (classic alerts) solution. Defaults to 'true'
  DESCRIPTION

  type = object({
    name                          = string
    sku                           = optional(string, "Standard")
    soft_delete_enabled           = optional(bool, true)
    public_network_access_enabled = optional(bool, true)
    storage_mode_type             = optional(string, "ZoneRedundant")
    cross_region_restore_enabled  = optional(bool, false)
    immutability                  = optional(string, "Unlocked")

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), null)
    }), null)

    encryption = optional(object({
      key_id                            = string
      infrastructure_encryption_enabled = optional(bool, false)
      user_assigned_identity_id         = optional(string, null)
      use_system_assigned_identity      = optional(bool, false)
    }), null)

    monitoring = optional(object({
      alerts_for_all_job_failures_enabled            = optional(bool, false)
      alerts_for_critical_operation_failures_enabled = optional(bool, true)
    }), null)
  })
  default = null
}

/*
This variable is suposed to be of type string, but because terraform doesn't allow to use count or for_each with 'attributes that cannot be determined until apply' 
to create resources, I used a list of only one element to bypass this limitation.

In this case both the vault and resource guard association can be created without needing to use the "terraform apply -targert" workarround
*/
variable "resource_guard_id" {
  description = "A list with ONLY one Resource Guard ID to be associated to this RSV. This parameter is optional"
  type        = list(string)
  default     = null

  validation {
    condition     = var.resource_guard_id == null ? true : length(var.resource_guard_id) == 1
    error_message = "This list should have only one element."
  }
}

variable "vm_policy" {
  description = <<DESCRIPTION
  A MAP of policies for virtual machines, the key is the policy name and the value are the properties.
  - frequency:                      (Required) Sets the backup frequency. Possible values are Hourly, Daily and Weekly. Defaults to 'Daily'
  - time:                           (Required) The time of day to perform the backup in 24hour format. Defaults to '22:00'
  - timezone:                       (Optional) Specifies the timezone. the possible values are defined here. Defaults to 'UTC'
  - policy_type:                    (Optional) Type of the Backup Policy. Possible values are V1 and V2 where V2 stands for the Enhanced Policy. Defaults to 'V2'
  - instant_restore_retention_days: (Optional) Specifies the instant restore retention range in days. Possible values are between 1 and 5 when policy_type is V1, and 1 to 30 when policy_type is V2. Defaults to '3'
  - hour_interval:                  (Optional) Interval in hour at which backup is triggered. Possible values are 4, 6, 8 and 12. This is used when frequency is Hourly. Defaults to 8
  - hour_duration:                  (Optional) Duration of the backup window in hours. Possible values are between 4 and 24 This is used when frequency is Hourly. Defaults to 16
  - weekdays:                       (Optional) The days of the week to perform backups on. Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday. This is used when frequency is Weekly
  - daily_retention:                (optional) The number of daily backups to keep. Must be between 7 and 9999. It is required if frequency is 'Daily' or 'Hourly'. Defaults to 7
  - instant_restore_resource_group: (optional) Specifies the instant restore resource group name. A block as defined bellow 
    - prefix:                       (Required) The prefix for the instant_restore_resource_group name.
    - suffix:                       (Optional) The suffix for the instant_restore_resource_group name.
  - retention_weekly:               (optional) A block as defined bellow
    - count:                        (Required) The number of weekly backups to keep. Must be between 1 and 9999. Defaults to 5
    - weekdays:                     (Required) The weekday backups to retain. Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday. Defaults to 'Saturday'
  - retention_monthly:              (optional) A block as defined bellow
    - count:                        (Required) The number of monthly backups to keep. Must be between 1 and 9999. Defaults to 12
    - weekdays:                     (Optional) The weekday backups to retain . Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday. Defaults to 'Saturday'
    - weeks:                        (Optional) The weeks of the month to retain backups of. Must be one of First, Second, Third, Fourth, Last. Defaults to 'First'
    - days:                         (Optional) The days of the month to retain backups of. Must be between 1 and 31.
    - include_last_days:            (Optional) Including the last day of the month, default to false
  - retention_yearly:               (optional) A block as defined bellow
    - count:                        (Required) The number of yearly backups to keep. Must be between 1 and 9999. Defaults to 5
    - months:                       (Required) The months of the year to retain backups of. Must be one of January, February, March, April, May, June, July, August, September, October, November and December. Defaults to 'January'
    - weekdays:                     (Optional) The weekday backups to retain . Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday. Defaults to 'Saturday'
    - weeks:                        (Optional) The weeks of the month to retain backups of. Must be one of First, Second, Third, Fourth, Last. Defaults to 'First'
    - days:                         (Optional) The days of the month to retain backups of. Must be between 1 and 31.
    - include_last_days:            (Optional) Including the last day of the month, default to 'null'
  DESCRIPTION

  type = map(object({
    frequency                      = optional(string, "Daily")
    time                           = optional(string, "22:00")
    timezone                       = optional(string, "UTC")
    policy_type                    = optional(string, "V2")
    instant_restore_retention_days = optional(number, 3)
    hour_interval                  = optional(number, 8)
    hour_duration                  = optional(number, 16)
    weekdays                       = optional(list(string), null)
    daily_retention                = optional(number, 7)

    instant_restore_resource_group = optional(object({
      prefix = optional(string, null)
      suffix = optional(string, null)
    }), null)

    retention_weekly = optional(object({
      count    = optional(number, 5)
      weekdays = optional(list(string), ["Saturday"])
    }), null)

    retention_monthly = optional(object({
      count             = optional(number, 12)
      weekdays          = optional(list(string), ["Saturday"])
      weeks             = optional(list(string), ["First"])
      days              = optional(list(number), null)
      include_last_days = optional(bool, null)
    }), null)

    retention_yearly = optional(object({
      count             = optional(number, 5)
      months            = optional(list(string), ["January"])
      weekdays          = optional(list(string), ["Saturday"])
      weeks             = optional(list(string), ["First"])
      days              = optional(list(number), null)
      include_last_days = optional(bool, null)
    }), null)
  }))

  default = null
}

variable "fileshare_policy" {
  description = <<DESCRIPTION
  A MAP of policies for file shares, the key is the policy name and the value are the properties.
  - frequency:                      (required) Sets the backup frequency. Possible values are Daily and Hourly. Defaults to 'Daily'
  - time:                           (required) The time of day to perform the backup in 24hour format. Defaults to '22:00'
  - timezone:                       (optional) Specifies the timezone. the possible values are defined here. Defaults to 'UTC'
  - daily_retention:                (required) The number of daily backups to keep. Must be between 7 and 9999. Defaults to 7
  - hourly:                         (optional) A hourly block defined as below. This is required when frequency is set to Hourly
    - interval:                     (optional) Specifies the interval at which backup needs to be triggered. Possible values are 4, 6, 8 and 12. Defaults to 4
    - start_time:                   (optional) Specifies the start time of the hourly backup. The time format should be in 24-hour format. Defaults to "00:00"
    - window_duration:              (optional) Species the duration of the backup window in hours. Defaults to '8'
  - retention_weekly:               (optional) A block as defined bellow
    - count:                        (required) The number of weekly backups to keep. Must be between 1 and 9999. Defaults to 5
    - weekdays:                     (required) The weekday backups to retain. Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday. Defaults to 'Saturday'
  - retention_monthly:              (optional) A block as defined bellow
    - count:                        (required) The number of monthly backups to keep. Must be between 1 and 9999. Defaults to 12
    - weekdays:                     (optional) The weekday backups to retain . Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday. Defaults to 'Saturday'
    - weeks:                        (optional) The weeks of the month to retain backups of. Must be one of First, Second, Third, Fourth, Last. Defaults to 'First'
    - days:                         (optional) The days of the month to retain backups of. Must be between 1 and 31.
    - include_last_days:            (optional) Including the last day of the month, default to false
  - retention_yearly:               (optional) A block as defined bellow
    - count:                        (required) The number of yearly backups to keep. Must be between 1 and 9999. Defaults to 5
    - months:                       (required) The months of the year to retain backups of. Must be one of January, February, March, April, May, June, July, August, September, October, November and December. Defaults to 'January'
    - weekdays:                     (optional) The weekday backups to retain . Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday. Defaults to 'Saturday'
    - weeks:                        (optional) The weeks of the month to retain backups of. Must be one of First, Second, Third, Fourth, Last. Defaults to 'First'
    - days:                         (optional) The days of the month to retain backups of. Must be between 1 and 31.
    - include_last_days:            (optional) Including the last day of the month, default to 'null'
  DESCRIPTION

  type = map(object({
    frequency       = optional(string, "Daily")
    time            = optional(string, "22:00")
    timezone        = optional(string, "UTC")
    daily_retention = optional(number, 7)

    hourly = optional(object({
      interval        = optional(number, 4)
      start_time      = optional(string, "00:00")
      window_duration = optional(number, 8)
    }), null)

    retention_weekly = optional(object({
      count    = optional(number, 5)
      weekdays = optional(list(string), ["Saturday"])
    }), null)

    retention_monthly = optional(object({
      count             = optional(number, 12)
      weekdays          = optional(list(string), ["Saturday"])
      weeks             = optional(list(string), ["First"])
      days              = optional(list(number), null)
      include_last_days = optional(bool, null)
    }), null)

    retention_yearly = optional(object({
      count             = optional(number, 5)
      months            = optional(list(string), ["January"])
      weekdays          = optional(list(string), ["Saturday"])
      weeks             = optional(list(string), ["First"])
      days              = optional(list(number), null)
      include_last_days = optional(bool, null)
    }), null)
  }))

  default = null
}

variable "workload_policy" {
  description = <<DESCRIPTION
  A MAP of policies for SAP for Hana and MSSQL, the key is the policy name and the value are the properties.
  - frequency:                      (optional) Sets the backup frequency. Possible values are Daily and Hourly. Defaults to 'Daily'
  - time:                           (optional) The time of day to perform the backup in 24hour format. Defaults to '22:00'
  - timezone:                       (optional) Specifies the timezone. the possible values are defined here. Defaults to 'UTC'
  - daily_retention:                (optional) The number of daily backups to keep. Must be between 7 and 9999. Defaults to 7
  - log:                            (optional) A block as defined bellow. On SAP for HANA policies, this parameter is required
    - frequency_in_minutes:         (optional) The backup frequency in minutes for the VM Workload Backup Policy. Possible values are 15, 30, 60, 120, 240, 480, 720 and 1440. Defaults to 60
    - count:                        (optional) The count that is used to count retention duration with duration type Days. Possible values are between 7 and 35. Defaults to 7
  - incremental:                    (optional) A block as defined bellow. This options is only supported on SAP for HANA policies
    - weekdays:                     (optional) The days of the week to perform backups on. Possible values are Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday. This is used when frequency is Weekly. Defaults to '["Sunday","Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]'
    - time:                         (optional) The time of day to perform the backup in 24hour format. Defaults to '22:00'
    - count:                        (optional) The count that is used to count retention duration with duration type Days. Possible values are between 7 and 35. Defaults to 7
  - differential:                   (optional) A block as defined bellow
    - weekdays:                     (optional) The days of the week to perform backups on. Possible values are Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday. This is used when frequency is Weekly. Defaults to '["Sunday","Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]'
    - time:                         (optional) The time of day to perform the backup in 24hour format. Defaults to '22:00'
    - count:                        (optional) The count that is used to count retention duration with duration type Days. Possible values are between 7 and 35. Defaults to 7
  - retention_weekly:               (optional) A block as defined bellow
    - count:                        (required) The number of weekly backups to keep. Must be between 1 and 9999. Defaults to 5
    - weekdays:                     (required) The weekday backups to retain. Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday. Defaults to 'Saturday'
  - retention_monthly:              (optional) A block as defined bellow
    - count:                        (required) The number of monthly backups to keep. Must be between 1 and 9999. Defaults to 12
    - weekdays:                     (optional) The weekday backups to retain . Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday. Defaults to 'Saturday'
    - weeks:                        (optional) The weeks of the month to retain backups of. Must be one of First, Second, Third, Fourth, Last. Defaults to 'First'
    - days:                         (optional) The days of the month to retain backups of. Must be between 1 and 31.
    - include_last_days:            (optional) Including the last day of the month, default to false
  - retention_yearly:               (optional) A block as defined bellow
    - count:                        (required) The number of yearly backups to keep. Must be between 1 and 9999. Defaults to 5
    - months:                       (required) The months of the year to retain backups of. Must be one of January, February, March, April, May, June, July, August, September, October, November and December. Defaults to 'January'
    - weekdays:                     (optional) The weekday backups to retain . Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday. Defaults to 'Saturday'
    - weeks:                        (optional) The weeks of the month to retain backups of. Must be one of First, Second, Third, Fourth, Last. Defaults to 'First'
    - days:                         (optional) The days of the month to retain backups of. Must be between 1 and 31.
    - include_last_days:            (optional) Including the last day of the month, default to 'null'  
  DESCRIPTION

  type = map(object({
    frequency           = optional(string, "Daily")
    time                = optional(string, "22:00")
    timezone            = optional(string, "UTC")
    daily_retention     = optional(number, 7)
    compression_enabled = optional(bool, false)
    workload_type       = optional(string, "SQLDataBase")
    weekdays            = optional(list(string), ["Saturday"])

    log = optional(object({
      frequency_in_minutes = optional(number, 60)
      count                = optional(number, 7)
    }), null)

    incremental = optional(object({
      weekdays = optional(list(string), ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday"])
      time     = optional(string, "22:00")
      count    = optional(number, 7)
    }), null)

    differential = optional(object({
      weekdays = optional(list(string), ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday"])
      time     = optional(string, "22:00")
      count    = optional(number, 7)
    }), null)

    retention_weekly = optional(object({
      count    = optional(number, 5)
      weekdays = optional(list(string), ["Saturday"])
    }), null)

    retention_monthly = optional(object({
      count     = optional(number, 12)
      weekdays  = optional(list(string), ["Saturday"])
      weeks     = optional(list(string), ["First"])
      monthdays = optional(list(number), null)
    }), null)

    retention_yearly = optional(object({
      count     = optional(number, 5)
      months    = optional(list(string), ["January"])
      weekdays  = optional(list(string), ["Saturday"])
      weeks     = optional(list(string), ["First"])
      monthdays = optional(list(number), null)
    }), null)
  }))

  default = null
}
