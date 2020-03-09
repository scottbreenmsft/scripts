# Summary
This sample script enumerates devices, determines the primary owner and adds the device to a specified group based on the primary owners group membership. The purpose of this is to allow the feature in Intune that applies scope tags to devices to apply scope tags to devices based on user group membership. The current feature in Intune only applies to devices and cannot target user objects. The current version of the script requires a mapping hash table to be created which maps user group membership to device group membership.

See https://github.com/scottbreenmsft/scripts/blob/master/Intune/RBAC/DeviceScopeTags/Apply%20Device%20Scope%20Tag%20Script.pdf for more information.
