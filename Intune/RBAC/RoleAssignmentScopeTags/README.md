These scripts add or remove scope tags from Role Assignments on bulk.

The script will:  
+ prompt you to select the scope tag to add
+ then prompt for the role definition;
+ and finally the role assignment.  

It will then enumerate each role assignment and add the scope tags.  This script uses the out-gridview -passthru method to allow objects to be selected. You can select multiple objects by using the Ctrl key and select each object or using filtering and using Ctrl+A to select all.
