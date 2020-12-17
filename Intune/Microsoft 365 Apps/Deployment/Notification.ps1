    
<#
.COPYRIGHT
Licensed under the MIT license.
See LICENSE in the project root for license information.
.DESCRIPTION
For info, see https://github.com/scottbreenmsft/scripts/tree/master/Intune/Microsoft%20365%20Apps/Deployment
Version History
0.1    20/11/2020    Initial version
#>

#The list of apps to check for an close
$listOfApps=@("Excel","Groove","OneNote","Infopath","Outlook","Mspub","PowerPnt","Winword","Lync","Msaccess","Communicator","Winproj","Visio")

  
  <#
    .SYNOPSIS 
      Displays a MessageBox using Windows WinForms
	  
	.Description
	  	This function helps display a custom Message box with the options to set
	  	what Icons and buttons to use. By Default without using any of the optional
	  	parameters you will get a generic message box with the OK button.
	  
	.Parameter Msg
		Mandatory: This item is the message that will be displayed in the body
		of the message box form.
		Alias: M

	.Parameter Title
		Optional: This item is the message that will be displayed in the title
		field. By default this field is blank unless other text is specified.
		Alias: T

	.Parameter OkCancel
		Optional:This switch will display the Ok and Cancel buttons.
		Alias: OC

	.Parameter AbortRetryIgnore
		Optional:This switch will display the Abort Retry and Ignore buttons.
		Alias: ARI

	.Parameter YesNoCancel
		Optional: This switch will display the Yes No and Cancel buttons.
		Alias: YNC

	.Parameter YesNo
		Optional: This switch will display the Yes and No buttons.
		Alias: YN

	.Parameter RetryCancel
		Optional: This switch will display the Retry and Cancel buttons.
		Alias: RC

	.Parameter Critical
		Optional: This switch will display Windows Critical Icon.
		Alias: C

	.Parameter Question
		Optional: This switch will display Windows Question Icon.
		Alias: Q

	.Parameter Warning
		Optional: This switch will display Windows Warning Icon.
		Alias: W

	.Parameter Informational
		Optional: This switch will display Windows Informational Icon.
		Alias: I

	.Parameter TopMost
		Optional: This switch will make the form stay on top until the user answers it.
		Alias: TM	
		
	.Example
		Show-MessageBox -Msg "This is the default message box"
		
		This example creates a generic message box with no title and just the 
		OK button.
	
	.Example
		$A = Show-MessageBox -Msg "This is the default message box" -YN -Q
		
		if ($A -eq "YES" ) 
		{
			..do something 
		} 
		else 
		{ 
		 ..do something else 
		} 

		This example creates a msgbox with the Yes and No button and the
		Question Icon. Once the message box is displayed it creates the A varible
		with the message box selection choosen.Once the message box is done you 
		can use an if statement to finish the script.
		
	.Notes
		Created By Zachary Shupp
		Email zach.shupp@hp.com		

		Version: 1.0
		Date: 9/23/2013
		Purpose/Change:	Initial function development

		Version 1.1
		Date: 12/13/2013
		Purpose/Change: Added Switches for the form Type and Icon to make it easier to use.

		Version 1.2
		Date: 3/4/2015
		Purpose/Change: Added Switches to make the message box the top most form.
						Corrected Examples
		
	.Link
		http://msdn.microsoft.com/en-us/library/system.windows.forms.messagebox.aspx
		
  #>
Function Show-MessageBox{

	Param(
	[Parameter(Mandatory=$True)][Alias('M')][String]$Msg,
	[Parameter(Mandatory=$False)][Alias('T')][String]$Title = "",
	[Parameter(Mandatory=$False)][Alias('OC')][Switch]$OkCancel,
	[Parameter(Mandatory=$False)][Alias('OCI')][Switch]$AbortRetryIgnore,
	[Parameter(Mandatory=$False)][Alias('YNC')][Switch]$YesNoCancel,
	[Parameter(Mandatory=$False)][Alias('YN')][Switch]$YesNo,
	[Parameter(Mandatory=$False)][Alias('RC')][Switch]$RetryCancel,
	[Parameter(Mandatory=$False)][Alias('C')][Switch]$Critical,
	[Parameter(Mandatory=$False)][Alias('Q')][Switch]$Question,
	[Parameter(Mandatory=$False)][Alias('W')][Switch]$Warning,
	[Parameter(Mandatory=$False)][Alias('I')][Switch]$Informational,
    [Parameter(Mandatory=$False)][Alias('TM')][Switch]$TopMost)

	#Set Message Box Style
	IF($OkCancel){$Type = 1}
	Elseif($AbortRetryIgnore){$Type = 2}
	Elseif($YesNoCancel){$Type = 3}
	Elseif($YesNo){$Type = 4}
	Elseif($RetryCancel){$Type = 5}
	Else{$Type = 0}
	
	#Set Message box Icon
	If($Critical){$Icon = 16}
	ElseIf($Question){$Icon = 32}
	Elseif($Warning){$Icon = 48}
	Elseif($Informational){$Icon = 64}
	Else { $Icon = 0 }
	
	#Loads the WinForm Assembly, Out-Null hides the message while loading.
	[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
	
	If ($TopMost)
	{
		#Creates a Form to use as a parent
		$FrmMain = New-Object 'System.Windows.Forms.Form'
		$FrmMain.TopMost = $true
		
		#Display the message with input
		$Answer = [System.Windows.Forms.MessageBox]::Show($FrmMain, $MSG, $TITLE, $Type, $Icon)
		
		#Dispose of parent form
		$FrmMain.Close()
		$FrmMain.Dispose()
	}
	Else
	{
		#Display the message with input
		$Answer = [System.Windows.Forms.MessageBox]::Show($MSG , $TITLE, $Type, $Icon)			
	}
	
	#Return Answer
	Return $Answer
}



$noAppsRunning=$true
$Processes=Get-Process
$noAppsRunning=$true
$runningApps=@()
foreach ($process in $processes) {
    If ($listOfApps -contains $process.ProcessName) {
        IF ($runningApps.ProcessName -notcontains $process.ProcessName) {
            $runningApps+= New-Object PSObject -Property @{
	            ProcessName= $process.ProcessName
                DisplayName=$process.Description
                Exe=$process.path
            }
        }
    }
}
IF ($runningApps) {
    $Message="An application install requires the following applications to be closed:`n`t$($runningapps.DisplayName -join "`n`t")`n`nPlease close them to continue then click 'Retry'."
    $result=Show-MessageBox -RetryCancel -Critical -Msg $Message -TopMost -Title "App Install - Running apps"
    If ($result -eq "Retry") {
        $Message="An application install requires the following applications to be closed:`n`t$($runningapps.DisplayName -join "`n`t")`n`nClick 'Yes' to force close them now."
        $result=Show-MessageBox -OkCancel -Question -Msg $Message -TopMost -Title "Close apps?"
        If ($result -eq "Ok") {
            foreach ($app in $runningApps) {
                Stop-Process -name $app.ProcessName -Force
            }
        } else {
            $noAppsRunning=$true
        }
    }
    write-host $result
    $noAppsRunning=$false
}


write-host "we can continue"