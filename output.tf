output "rsv_name" {
  description = "Recovery Services Vault name"
  value       = azurerm_recovery_services_vault.default.name
}

output "rsv_id" {
  description = "Recovery Services Vault ID"
  value       = azurerm_recovery_services_vault.default.id
}

output "vm_policy_ids" {
  description = "VM backup policy IDs"
  value       = { for key, value in azurerm_backup_policy_vm.default : value.name => value.id }
}


output "fs_policy_ids" {
  description = "File Share backup policy IDs"
  value       = { for key, value in azurerm_backup_policy_file_share.default : value.name => value.id }
}

output "workload_policy_ids" {
  description = "MSSQL/SAPHANA backup policy IDs"
  value       = { for key, value in azurerm_backup_policy_vm_workload.default : value.name => value.id }
}
