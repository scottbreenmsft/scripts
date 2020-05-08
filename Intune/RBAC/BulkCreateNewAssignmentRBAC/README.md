# Bulk Create New Assignment RBAC
This script creates scope tags and role assignments based on a CSV file.

## CSV File Format
<Table>
<tr><th>Scope Tag</th><th>Scope Tag Description</th><th>Role</th><th>Admin Group</th><th>Scope Group</th><th>Assignment Name</th><tr>
<tr><td>name of scope tag</td><td>a description for the scope tag</td><td>the name of an existing RBAC role</td><td>Azure AD group name for admins/members</td><td>Azure AD group name for scope groups</td><td>The name of the assignment</td><tr>
</table>

eg.  

<Table>
<tr><th>Scope Tag</th><th>Scope Tag Description</th><th>Role</th><th>Admin Group</th><th>Scope Group</th><th>Assignment Name</th><tr>
<tr><td>School 1 Scope Tag</td><td>Scope tag for School 1</td><td>School Administrator</td><td>School 1 Admins</td>
<td>School 1 Devices and Users</td><td>School Administrator - School 1</td><tr>
</table>
