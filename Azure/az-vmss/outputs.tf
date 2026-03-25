output "scale_sets" {
  description = "Map of all scale sets with their id, name, and unique_id"
  value = merge(
    {
      for k, v in azurerm_linux_virtual_machine_scale_set.this : k => {
        id        = v.id
        name      = v.name
        unique_id = v.unique_id
      }
    },
    {
      for k, v in azurerm_windows_virtual_machine_scale_set.this : k => {
        id        = v.id
        name      = v.name
        unique_id = v.unique_id
      }
    }
  )
}
