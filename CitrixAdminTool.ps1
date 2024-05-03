#####################################################################
#                       Citrix Admin Tool                           #
#                Developped by : Brian L. Kruse                     #
#                                                                   #
#                      Date: 24-11-2020                             #
#                   Last Update: 03-05-2024                         #
#                                                                   #
#                        Version: 2.0                               #
#                                                                   #
#  Purpose: A quick visual way to get Citrix related Information    #
#                                                                   #
#                                                                   #
#                                                                   #
#                                                                   #
#####################################################################

#region Debug variable
$debug = $false
#endregion Debug variable


#region SnapIns to be loaded

## Cloud sync on prem authentication

<#
$snapinLicV1 = "Citrix.Licensing.Admin.V1"
$snapinAddedLicV1 = Get-PSSnapin | Select-String $snapinLicV1
if (!$snapinAddedLicV1)
{
    Add-PSSnapin $snapinLicV1
}
#>

$snapinNameC = "citrix*"
$snapinAdded = Get-PSSnapin | Select-String $snapinNameC
if (!$snapinAdded)
{
    Add-PSSnapin $snapinNameC
}
$snapinNameA = "Citrix.*.Admin.V*"
$snapinAdded = Get-PSSnapin | Select-String $snapinNameA
if (!$snapinAdded)
{
    Add-PSSnapin $snapinNameA
}
$snapinNameAV3 = "Citrix.ADIdentity.Admin.V2"
$snapinAdded = Get-PSSnapin | Select-String $snapinNameAV3
if (!$snapinAdded)
{
    Add-PSSnapin $snapinNameAV3
}
$snapinNameAV = "Citrix.\*.Admin.V\*"
$snapinAdded = Get-PSSnapin | Select-String $snapinNameAV
if (!$snapinAdded)
{
    Add-PSSnapin $snapinNameAV
}
$snapinNameB = "Citrix.Broker.Admin.v2"
$snapinAdded = Get-PSSnapin | Select-String $snapinNameB
if (!$snapinAdded)
{
    Add-PSSnapin $snapinNameB
}

# Authentication OnPrem validation to avoid Cloud authentication - outline the "Set-XDCredentials -ProfileType onPrem" if connecting to Citrix Cloud
Set-XDCredentials -ProfileType onPrem
#Get-XDAuthentication 


#endregion SnapIns to be loaded


#################################################### Functions #######################################################


# Default Global Variables

#region Default variable settings

# Insert the Delivery Controller like - "DDC1.domain.ext","DDC2.domain.etx"
$DDC = "ddc1.contoso.net"

# Insert Domain like - "domain.ext"
$Domain = "contoso.net"

# Insert XenServer hostname for the Virtual Desktops like - "xenserver1.domain.ext"
$XenServerVDI = "xenserver1.contoso.net"

# Insert eihter all AD Groups like - "VirtualDesktop-Group1", " VirtualDesktop-Group2" or enter e prefix to import all AD Groups accessing Virtual Desktops like "*DesktopGroup*"
$groups = (Get-ADGroup -Filter {name -like "CVAD-AD-Group*"} -Properties Name | Select Name | Select-Object @{l="Name";e={$_.Name -join " "}}).Name | Sort 

# if more different prefix - Insert eihter all AD Groups like - "VirtualDesktop-Group1", " VirtualDesktop-Group2" or enter e prefix to import all AD Groups accessing Virtual Desktops like "*DesktopGroup*"
$groupsTIER2 = (Get-ADGroup -Filter {name -like "CVAD-AD-Group*"} -Properties Name | Select Name | Select-Object @{l="Name";e={$_.Name -join " "}}).Name | Sort 

# For trimming the domain name for some functions like "domain\\"
$DomainTrim = "CONTOSO\\"

# Virtual Machine prefix if needed like "*prefix*"
$VDIPrefix = "*CVADVDI*"

# Virtual Machine prefix if needed like "*prefix*"
$XenAppPrefix = "*CVADXA*"

# Domain PreFix without extension like - "Domain\"
$DomainPrefix = "CONTOSO\"

# Specific VDIUser for delete, maintenance etc
$specificUser = $DomainPrefix + "INITIALS"

#endregion Default variable settings



############################################## VDI Check user assignment Function ####################################
function VDIAssign{

    # For debugging purpose
    if ($debug -eq $True){
    write-host "In function VDIAssign - error found"
    }

    $outputBox.text = @()
    $outputBox.text =  "Gathering User assigned to VDI info - Please wait...."  | Out-String
    $VDIUser = $InputBox.text
    $user = $InputBox.text

    # Gets all Virtual Desktops
    $desktopsall = get-brokerdesktop -AdminAddress $DDC -MaxRecordCount 50000 | Select MachineName,AssociatedUserNames,LastConnectionTime,PowerState,SessionStateSessionUserName,PublishedName,DesktopGroupName,Tags
        $machine = ''
        $countvdi = 0

            ## User enabled/disabled validation
            $ADEnabled = (Get-ADUser $VDIUser -Properties * | Select-Object Enabled | FT -HideTableHeaders | Out-String).Trim()
            $outputBox.AppendText("`n")
            $outputBox.AppendText("`n")
            $outputBox.text += "------ Validate if User is enabled"
            $outputBox.AppendText("`n")
            $outputBox.AppendText("`n")
            $outputBox.text += "User: " + $VDIUser + " active status is: " + $ADEnabled | Out-String  
            $outputBox.AppendText("`n")

            $outputBox.AppendText("`n")
            $outputBox.Text += "----- The Following VDIs are assigned to user: $VDIUser"
            $outputBox.AppendText("`n")
                    
            # Gets extra information on Virtual Desktop usage            
            foreach ($desktops in $desktopsall) {
                $AssociatedUserNamesTrimmed = $desktops.AssociatedUserNames -replace "$DomainTrim", "" 
                                
               If ($AssociatedUserNamesTrimmed -eq $VDIUser) {
               $machine += $desktops.machinename 
               $ConTime += $desktops.LastConnectionTime | Out-String
               $VirApp += $desktops.PublishedName
                    
                $outputBox.AppendText("`n")
                $outputBox.AppendText("`n")
                $outputBox.Text += $desktops.machinename + " - tagged (" + $desktops.Tags + ")"  + " - DeliveryGroup: " + $desktops.DesktopGroupName + " - PowerState: " + $desktops.powerstate + " - SessionState: " + $desktops.SessionState  + " - Last logged on: " + $desktops.LastConnectionTime
                $outputBox.AppendText("`n")
                $countvdi += 1

                }
              
                            
              }              
            $outputBox.AppendText("`n")           
            $outputBox.AppendText("`n")
            $outputBox.Text += "----- $VDIUser is Assigned to the following AD Groups"
            $outputBox.AppendText("`n")           
            $outputBox.AppendText("`n")  
                                       
            #Checking of old AD groups
            foreach ($group in $groups) {
                $members = Get-ADGroupMember -Identity $group -Recursive | Select -ExpandProperty SamAccountName
                    
                If ($machine) {

                                                        
                    If ($members -contains $user) {
                            $outputBox.Text += $group
                            $outputBox.AppendText("`n")
                        } Else {
                            continue
                    }


                } 

        }

            #Checking AD groups that users needs to be in for getting a VDI assigned

            foreach ($groupTIER2 in $groupsTIER2) {
                $members = Get-ADGroupMember -Identity $groupTIER2 -Recursive | Select -ExpandProperty SamAccountName
                    
        If ($machine) {
                                                        
            If ($members -contains $user) {
                    $outputBox.Text += $groupTIER2
                    $outputBox.AppendText("`n")
                } Else {
                    continue
                }


                } 
            }

            $outputBox.AppendText("`n")
            $outputBox.AppendText("`n")
        $outputBoxCount.Text = $countvdi
}
############################################## VDI Check user assignment Function END  ###############################

############################################## VDI Check user assignment contains inputFunction ####################################
function VDIAssignUserNameContain{

                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function VDIAssignUserNameContain - error found"
                    }

                    $outputBox.text +=  "Gathering User assigned to VDI info - Please wait...."  | Out-String
                    $VDIUser = $InputBox.text
                    
                    # Gets all Virtual Desktops where the USERNAME is assigned a Virtual Desktops
                    $DesktopUsersVDIM = Get-BrokerMachine -AdminAddress $DDC -MaxRecordCount 5000 | Select-Object MachineName,Tags,DesktopGroupName, @{Name='AssociatedUserNames';Expression={[string]::join(“;”, ($_.AssociatedUserNames))}} | Where-Object {$_.AssociatedUserNames -like "*$VDIUser*"} | FT
                    

                    #Output on screen
                    $outputBox.Text = "VDIs containing Associated USERNAME with:  $VDIUser "
                    $outputBox.AppendText("`n")
                    $outputBox.Text += $DesktopUsersVDIM | Out-String

                    # Output the count
                    $outputBoxCount.Text = $DesktopUsersVDIM.Count

}
############################################## VDI Check user assignment contains input Function END  ###############################

############################################## Check user assignment to a specific VDI Function ####################################
function VDIUserAssign{

                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function VDIUserAssign - error found"
                    }
                    
                    $outputBox.text =  "Gathering User assigned to VDI - Please wait...."  | Out-String
                    $objStatusBar.Text = "Gathering User assigned to VDI - Please wait...."

                    # Input is the Virtual Desktop name
                    $VDIName = $InputBoxVDIName.text
                   
                    # Getting all Virtual Desktops
                    $desktops = get-brokerdesktop -AdminAddress $DDC -MaxRecordCount 5000 | Select MachineName,Tags,AssociatedUserNames,SessionUserName,PowerState

                        $AssociatedUser = ''

                        foreach ($desktop in $desktops) {

                            If ($desktop.MachineName -like "*$VDIName*") { 
                                $VDIUserName = $desktop.AssociatedUserNames
                                $Tag = $desktop.Tags
                                $outputBox.Text = $VDIName + " ($Tag) " + " is assigned to " + $VDIUserName +  " and active sessionUser is:  " + $desktop.SessionUserName
                                break
                            }
                        }
                        
                    $objStatusBar.Text = "Gathering User assigned to VDI - Please wait...."
}
############################################## Check user assignment to a specific VDI Function END  ###############################

############################################## Find Users assigned to VDIs from List Function ####################################
function FindUsersFromVDIList{

                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function VDIUserAssign - error found"
                    }
                    
                    $outputBox.text =  "Gathering Users assigned to VDIs from list - Please wait...."  | Out-String
                    $outputBox.AppendText("`n")
                    $outputBox.AppendText("`n")
                    $objStatusBar.Text = "Gathering Users assigned to VDIs from list - Please wait...."
                   
                    ## For importing a TXT file with only the Virtual Desktop Names without the DOMAIN extension
                    Add-Type -AssemblyName System.Windows.Forms
                    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
                    
                    ## If you want to redirect to specific folder
                    InitialDirectory = "c:\Temp"

                    ## If you want to user Environment Path like "Desktop/ My Documents"
                    ##InitialDirectory = [Environment]::GetFolderPath('Desktop') 

                    ## If you want to add any Title to your Dialog Box
                    Title = "Select the file to import - chose between xlsx,csv,txt"

                    ##If you want to add file filter to your File Browser windows
                    Filter = 'Select File |*.xlsx;*.txt;*.csv'
                    #Filter = 'Select File |*.mkv'
                    }

                    $FileBrowser.ShowDialog()
                    #$File = $FileBrowser.Filename
                    
                    $desktops = Get-Content $FileBrowser.Filename
                    $desktopsVDIs = get-brokerdesktop -AdminAddress $DDC -MaxRecordCount 5000 | Select MachineName,Tags,AssociatedUserNames

                        foreach ($desktopVDI in $desktopsVDIs) {

                            foreach ($desktop in $desktops) {
                                
                                If ($desktopVDI.MachineName -like "*$desktop*") { 
                                $VDIUserName = $desktopVDI.AssociatedUserNames
                                #$Tag = $desktop.Tags
                                $outputBox.Text += $desktop + " is assigned to " + $VDIUserName
                                #Write-Host = "$desktop is assigned to VDI: $VDIUserName"
                                $outputBox.AppendText("`n")
                        }
                        }
                        }
             
                    $objStatusBar.Text = "Gathering Users assigned to VDIs from list generated - Please wait...."
}
############################################## Find Users assigned to VDIs from List Function END  ###############################

############################################## VDI Standard Powered Off Function ####################################
function VDISTDPowerstate{

                         
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function VDISTDPowerstate - error found"
                    }
                    
                
                    $outputBox.text =  "Gathering Power State VDI info - Please wait...."  | Out-String
                    $vmcount = 0
                    $VMList = Get-BrokerDesktop -adminaddress $DDC -MaxRecordCount 50000 -PowerState Off | Select-Object MachineName,LastConnectionTime,AssociatedUserNames,InMaintenanceMode,PowerState,SessionUserName | Sort-Object MachineName
                    Foreach ($vm in $VMList) {

                        [PSCustomObject]@{    
                            Server = $vm.MachineName
                            "Last Connection time" = $vm.LastConnectionTime
                            "Maint Mode" = $vm.InMaintenanceMode
                            "Associated UserName" = $vm.AssociatedUserNames 
                          }
                          if ($vm.associatedusernames = {})

                            {

                                $vmcount +=1

                            }
                    }

                    $outputBox.Text = "Virtual Desktops Powerstate"
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "---------------------------------------------------------------------"
                    $outputBox.AppendText("`n")                    
                    $outputBox.Text += $VMList | FT | Out-String | Sort-Object MachineName
                    $outputBoxCount.Text = $vmcount
}
############################################## VDI Standard Powered Off Function END  ###############################

############################################## VDI Specis Information Function ####################################
function VDISpecInfo{

                            
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function VDISpecInfo - error found"
                    }


                    $VDIName = $InputBoxVDIName.text                    
                    $VDIFullName = $DomainPrefix + $VDIName                   
                
                    $outputBox.text =  "Gathering VDI info - Please wait...."  | Out-String
                   
                    # Gets information on the Virtual Desktop from Citrix Studio
                    $VDI = Get-BrokerMachine -MachineName $VDIFullName -adminaddress $DDC -ErrorAction SilentlyContinue
                 

                    IF ($VDI -eq $null){
                        $outputBox.Text = "VDI: " + $VDIName + " - does not exist"
                        }
                    Else{

                    $outputBox.Text = "Information for Virtual Desktop: " + $VDIName
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "---------------------------------------------------------------------"
                    $outputBox.AppendText("`n")
                    $outputBox.Text += $VDI | Out-String
                    }
}

############################################## VDI Specis Information Function END  ###############################


############################################## Delivery Groups Function ####################################
function DelGrp{

                             
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function DelGrp - error found"
                    }
                   
                
                    $outputBox.text =  "Gathering Citrix Delivery Groups info - Please wait...."  | Out-String
                    $Groups = Get-BrokerDesktopGroup -adminaddress $DDC -Filter {SessionSupport -eq 'SingleSession'} -MaxRecordCount 5000 | Select Name
                     Foreach ($group in $groups) {

                        [PSCustomObject]@{    
                            PublishedName = $group.PublishedName
                            
                          }
                        $vmcount +=1
                    }
                   
                    $outputBox.Text = $Groups | FT | Out-String
                    $outputBoxCount.Text = $vmcount
}

############################################## Delivery Groups Function END  ###############################

############################################## Machine Catalog Function ####################################
function MacCat{

                              
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function MacCat - error found"
                    }
                   
                
                    $outputBox.text =  "Gathering Citrix Machine Catalogs info - Please wait...."  | Out-String
                    $Groups = Get-BrokerCatalog  -adminaddress $DDC -MaxRecordCount 5000 | Select Name
                     Foreach ($group in $groups) {

                        [PSCustomObject]@{    
                            Name = $group.Name
                            
                          }
                        $vmcount +=1
                        
 
                    }
                   
                    $outputBox.Text = $Groups | FT | Out-String
                    $outputBoxCount.Text = $vmcount
}

############################################## Machine Catalog Function END  ###############################

############################################## VDI Active State function ###############################

function VDIW10WAS{

                                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function VDIW10WAS - error found"
                    }
                    
                
                    $outputBox.text =  "Gathering Virtual Desktops Active State info List - Please wait...."  | Out-String
                    $BrokerDesktops = Get-BrokerDesktop -adminaddress $DDC -MaxRecordCount 5000 -Filter {MachineName -like $VDIPrefix -and SessionState -eq $null -and PowerState -eq 'on'} | Select-Object -Property MachineName,Tags,LastDeregistrationTime,LastConnectionTime,LastConnectionUser,CatalogName,SessionState,SessionUserName,PowerState | Sort-Object LastDeregistrationTime,MachineName | FT -AutoSize


                    $vmcount = 0
                    $CountBrokerDesktops = Get-BrokerDesktop -adminaddress $DDC -MaxRecordCount 5000 -Filter {MachineName -like $VDIPrefix -and SessionState -eq $null -and PowerState -eq 'on'} | Select-Object -Property MachineName,Tags,LastConnectionTime,LastConnectionUser,DesktopGroupName,SessionState,SessionUserName,PowerState | Sort-Object MachineName
                     Foreach ($vm in $CountBrokerDesktops) {
                     #Count total number of VDI Standard
                        $vmcount +=1
                     }
                   

                    if ($CountBrokerDesktops -eq $NULL){
                        $outputBox.Text = "There are noVirtual Desktops without active User Session powered on"
                        }
                    Else{
                        $outputBox.Text = $BrokerDesktops | FT | Out-String
                        }
                    $outputBoxCount.Text = $CountBrokerDesktops.Count
}
              
############################################## VDI Active State END ###############################

############################################## VDI List VDI Names Only Function ###############################

function VDIListNameOnly{

                                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function VDIListNameOnly - error found"
                    }
                    
                
                    $outputBox.text =  "Gathering Virtual Desktop Names List - Please wait...."  | Out-String
                    $VMListTotal = Get-BrokerDesktop -adminaddress $DDC -MaxRecordCount 5000 -filter {DesktopGroupUid -ne $null} | where MachineName -like $VDIPrefix | Select-Object -Property MachineName,AgentVersion,CatalogName,SessionState, SessionUserName,PowerState,Tags,@{l="AssociatedUserNames";e={$_.AssociatedUserNames -join ","}} | Sort-Object CatalogName, MachineName, AgentVersion #| FT -AutoSize
                    

                 
                    $TableWidth = @{Expression={$_.Col1}; Label="MachineName"; Width=30}, 
                     @{Expression={$_.Col2}; Label="AgentVersion"; Width=30}, 
                     @{Expression={$_.Col3}; Label="Associated Usernames"; Width=30}
                    
                    $outputBox.Text = "This is the current total Virtual Desktop list for each Delivery Group / Machine Catalog"
                    $outputBox.AppendText("`n")
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "---------------------------------------------------------------------"
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "---------------------------------------------------------------------"
                    $outputBox.AppendText("`n")
                    $outputBox.Text += $VMListTotal | FT | Out-String
                    $outputBoxCount.Text = $VMListTotal.count
                    

                    $CountVDI = $VMListTotal.count
}
              
############################################## VDI List VDI Names Only Function END ###############################

############################################## Output all VDI information to Excel Function ###############################

function AllVDIandUsertoExcel{

                                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function AllVDIandUsertoExcel - error found"
                    }
                    
                    $outputBox.text =  "Gathering All VDI information List - Please wait...."  | Out-String
                    $AllVDI_User_VMListTotal = Get-BrokerDesktop -adminaddress $DDC -MaxRecordCount 5000 -filter {DesktopGroupUid -ne $null} | where MachineName -like $VDIPrefix | Select-Object -Property MachineName,CatalogName,@{l="AssociatedUserNames";e={$_.AssociatedUserNames -join ","}} | Sort-Object MachineName | Export-Excel -path ("c:\temp\All_VDI_List_Report.xlsx") -worksheetname "All_VDI_List" -TableStyle Medium16 -AutoSize
                    $outputBox.Text = "Excel sheet copied to c:\temp\All_VDI_List_Report.xlsx"

}
              
############################################## Output all VDI information to Excel Function END ###############################

############################################## Function List all disabled users that are in the Delivery Groups for VDIs #########################

Function DisabledUsersVDI {

                                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function DisabledUsersVDI - error found"
                    }

    # Clean Output Field
    $outputBox.Text = @()
    


            # Output file path
            $outputFile = "C:\Temp\Disabled_users.txt"
            #$outputFileCSV = "C:\Temp\Disabled_users.csv"

            # Initialize an empty array to store disabled users
            $disabledUsers = @()
            $ListDisUsersOnly = @()

            # Loop through each AD group
            foreach ($group in $groups) {
                # Get the members of the group
                $members = Get-ADGroupMember -Identity $group -Recursive |
                           Where-Object { $_.objectClass -eq "user" }

                # Loop through each member and check if they are disabled
                foreach ($member in $members) {
                    $user = Get-ADUser -Identity $member.SamAccountName -Properties Enabled |
                            Select-Object SamAccountName, Enabled


                   # Check if the user is disabled
                    if (-not $user.Enabled) {
                        $disabledUsers += $user
                        $ListDisUsersOnly += $user.SamAccountName + " and member of : " + $group
                    }
                }
            }

            $outputBox.Text = "---------------------------------------------------------------------"
            $outputBox.AppendText("`n")
            $outputBox.Text += "Listed below are the users currently disabled in the VDI Delivery Groups"
            $outputBox.AppendText("`n")
            $outputBox.Text += "---------------------------------------------------------------------"
            $outputBox.AppendText("`n")
            $outputBox.Text += $ListDisUsersOnly  | FT | Out-String 
            $outputBox.AppendText("`n")
            $outputBox.AppendText("`n")
            $outputBox.Text += "Total amount of Users       " + $ListDisUsersOnly.count
            $outputBox.AppendText("`n")
            $outputBox.Text += "---------------------------------------------------------------------"
            $outputBox.AppendText("`n")
            $outputBox.Text += "File copied to -> C:\Temp\Disabled_users.txt"

            # Export the disabled users to a text file
            #$ListDisUsersOnly | Export-Csv -Path $outputFileCSV -NoTypeInformation
            $ListDisUsersOnly | Out-File -FilePath $outputFile

            # Inform the user about the script completion
            #Write-Host "Disabled users have been exported to $outputFile."


}



############################################## Function List all disabled users that are in the Delivery Groups for VDIs End #########################################

################################### VDI Search by TAG Function Start ###################################

function VDITAG{

                                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function VDITAG - error found"
                    }

                    $vmcount = 0
                    
             

                    ### Out-gridview for user to select the citrix tag they want to find which members (Desktops) are tagged
                    $Tag_to_Search = $InputBox.text
                    $Members_of_Tag = Get-BrokerMachine -AdminAddress $DDC -Tag $Tag_to_Search -MaxRecordCount 100000 | Select HostedMachineName, Tags, DesktopGroupName, AssociatedUserNames                   

                    foreach ($Member in $Members_of_Tag) {


                            $vmcount +=1
                            }

                    ### Grabbing all the members (Desktops) that are tagged with the selected tag

                    ### If there are no members of the tag it will send output to console otherwise it will send an out-gridview
                    If ($null -eq $Members_of_Tag){
                        #Write-Host "No members of the selected TAG" -BackgroundColor Red -ForegroundColor White
                        
                        $outputBox.Text = "No members of the selected TAG: " + $Tag_to_Search
                        

                    }
                    Else{
                        $outputBox.Text = "---------------------------------------------------------------------"
                        $outputBox.AppendText("`n")
                        $outputBox.Text += "Listed below are the VDIs with the TAG: $Tag_to_Search"
                        $outputBox.AppendText("`n")
                        $outputBox.AppendText("`n")
                        $outputBox.Text += $Members_of_Tag | FT | Out-String
                    }
                    
                    $outputBoxCount.Text = $vmcount
}


################################### VDI Search by TAG Function End ###################################

################################### VDI TAG List Function Start ###################################

function VDITAGList{
                    
                                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function VDITAGList - error found"
                    }

                    $Tag_to_Search = Get-BrokerTag -AdminAddress $DDC | Select Name | FT #Description | Out-GridView -Title "Select the Citrix Tag you want to grab members for" -OutputMode Single

                        $outputBox.Text = $Tag_to_Search | FT | Out-String
}


################################### VDI TAG List  Function End ###################################

################################### ShutDown Single Virtual Desktop by Name Function ################################

function VDIShutDown{

                                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function VDIShutDown - error found"
                    }

                $VDIMachineName = $InputBoxVDIName.text 
                $VDI = $DomainPrefix + $VDIMachineName
                New-BrokerHostingPowerAction -Action Shutdown -MachineName $VDI -ActualPriority 1

                $outputBox.Text = "Shutting down VDI: " + $VDIMachineName
                $objStatusBar.Text =  "Shutting down VDI: " + $VDIMachineName

}
################################### ShutDown VDI by Name Function End##############################

############################################## Shut Down Virtual Desktop function ###############################

function VDIShutDownActiveNoSession{
  
                                  
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function VDIShutDownActiveNoSession - error found"
                    }
            
                    $outputBox.text =  "Shutting down Powered On Standard VDI without Active userSessions - Please wait...."  | Out-String
                    $vmcount =0
                    $objStatusBar.Text = @()

                    # Create c:\temp folder if it does not exist
                    $path = "C:\temp\"
    
                        If (!(test-path $path))
                        {
                            md $path
                        }


                    $VDIMachinesActive = Get-BrokerDesktop -adminaddress $DDC -MaxRecordCount 50000 -Filter {MachineName -like $VDIPrefix -and SessionState -eq $null -and PowerState -eq 'on'} | Select-Object MachineName | FT -HideTableHeaders | Out-File -FilePath c:\temp\VDIListAutoShutDown.txt

                    $VDIS = Get-Content c:\temp\VDIListAutoShutDown.txt
                    
                     foreach ($vdi in $VDIS) {
                     
                         New-BrokerHostingPowerAction -Action Shutdown -MachineName $vdi -Verbose

                         $outputBox.AppendText("`n")
                         $outputBox.Text += "Shutting down VDI: " + $vdi
                         $outputBox.AppendText("`n")
                         $outputBox.Text += "VDIs has now been signaled to ShutDown"
                         $objStatusBar.Text +=  "Shutting down VDI: " + $vdi
                         

                     }
                    
                    $outputBoxCount.Text = $VDIMachinesActive.Count
}
              
############################################## VDI Active State END ###############################

################################### VDI ShutDown from LIST Function ################################

function VDIShutDownList{
 
                                   
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function VDIShutDownList - error found"
                    }
               
                ## Import file using file explorer

                Add-Type -AssemblyName System.Windows.Forms
                $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
                    
                    ## File input is:   Domain\MACHINENAME
                    
                    ## If you want to redirect to specific folder
                    InitialDirectory = "c:\Temp"

                    ## If you want to user Environment Path like "Desktop/ My Documents"
                    #InitialDirectory = [Environment]::GetFolderPath('Desktop') 

                    ## If you want to add any Title to your Dialog Box
                    Title = "Select the file to import - chose between xlsx,csv,txt"

                    ##If you want to add file filter to your File Browser windows
                    Filter = 'Select File |*.xlsx;*.txt;*.csv'
                    #Filter = 'Select File |*.mkv'
                }
                $FileBrowser.ShowDialog()
                $File = $FileBrowser.Filename

                $outputBox.Text = @()

                If( !$File )
                {   $outputBox.Text += "File Import was cancelled ....." }

                Else {
                # Import the VDI list
                $VDIList = Get-Content -Path $File
                foreach ($VDI in $VDIList) {
                    
                    if (!$VDI){
                    continue
                    }

                    Else{
                    New-BrokerHostingPowerAction -AdminAddress $DDC -Action Shutdown -MachineName $VDI -ActualPriority 1

                    #Write-Host = "Rebooting VDI:  " + $VDI

                    $outputBox.Text += $VDI + " Has been signaled to shut down"
                    $outputBox.AppendText("`n")
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "Shutting Down VDI: " + $VDI
                    $outputBox.AppendText("`n")
                    $objStatusBar.Text =  "Shutting Down VDI: " + $VDI
                    }
                }
                }



                    $outputBox.AppendText("`n") 
                    $outputBox.Text += "All VDIs in the list has been signaled to SHut Down!!"
                   

}
################################### VDI ShutDown from LIST Function End##############################




################################### Start VDI by Name Function ################################

function VDIStart{
  
                                    
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function VDIStart - error found"
                    }
              
                
                $VDIMachineName = $DomainPrefix + $InputBoxVDIName.text 
                New-BrokerHostingPowerAction -Action TurnOn -MachineName $VDIMachineName

                $outputBox.Text = "Starting up VDI: " + $VDIMachineName
                $objStatusBar.Text =  "Starting up VDI: " + $VDIMachineName

}
################################### Start VDI by Name Function End##############################

################################### Add User to Specific VDI function ###############################

function VDIAddUser{

                                    
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function VDIAddUser - error found"
                    }

                    # Add the Users to the specific VDI

                    $Username = $InputBox.Text
                    $VDIName = $InputBoxVDIName.Text

                    $outputBox.text =  "Adding user: " + $Username + " to the VDI: " + $VDIName + "- Please wait...."  | Out-String
                    $objStatusBar.Text = "Adding user: " + $Username + " to the VDI: " + $VDIName + "- Please wait...."


                    #Add DomainPrefix to username
                    $FinalUserName = $DomainPrefix + $Username

                    #Add DomainPrefix to VDI name
                    $FinalVDIName = $DomainPrefix + $VDIName
                    
                    add-BrokerUser $FinalUserName -Machine $FinalVDIName

                    $outputBox.text =  "User: " + $FinalUserName + " added to: " + $FinalVDIName  | Out-String
                    $objStatusBar.Text = "User: " + $FinalUserName + " added to: " + $FinalVDIName
                   
                    
}
              
############################################## Add User to Specific VDI function END ###############################

################################### Remove User from Specific VDI function ###############################

function VDIRemoveUser{

                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function VDIRemoveUser - error found"
                    }


                    # Remove the User from the specific VDI

                    $outputBox.text =  "Removing user from the VDI - Please wait...."  | Out-String
                    $objStatusBar.Text = "Removing user from the VDI - Please wait...."

                    $Username = $InputBox.Text
                    $VDIName = $InputBoxVDIName.Text

                    #Add DomainPrefix to username
                    $FinalUserName = $DomainPrefix + $Username

                    #Add DomainPrefix to VDI name
                    $FinalVDIName = $DomainPrefix + $VDIName
                    
                    Remove-BrokerUser $FinalUserName -Machine $FinalVDIName

                    $outputBox.text =  "User: " + $FinalUserName + " removed from: " + $FinalVDIName  | Out-String
                    $objStatusBar.Text = "User: " + $FinalUserName + " removed from: " + $FinalVDIName
                   
                    
}
              
############################################## Remove User from Specific VDI Function END ###############################

################################### Remove OBSOLETE User from Specific VDI function ###############################

function VDIRemoveUserObsolete{

                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function VDIRemoveUserObsolete - error found"
                    }

                    # Remove the OBSOLETE Domain Users from the specific VDI - Account Like S-1-5-21-1659004503-2077806209-682003330-3711286 
        
                    $outputBox.text =  "Removing user from the VDI - Please wait...."  | Out-String
                    $objStatusBar.Text = "Removing user from the VDI - Please wait...."

                    $Username = $InputBox.Text
                    $VDIName = $InputBoxVDIName.Text


                    #Add Vetas to VDI name
                    $FinalVDIName = $DomainPrefix + $VDIName
                    
                    Remove-BrokerUser $Username -Machine $FinalVDIName

                    $outputBox.text =  "OBSOLETE User: " + $FinalUserName + " removed from: " + $FinalVDIName  | Out-String
                    $objStatusBar.Text = "OBSOLETE User: " + $FinalUserName + " removed from: " + $FinalVDIName                
}
              
############################################## Remove User from Specific VDI Function END ###############################

################################### Find Published Applications containing specific AD Groups function ###############################

function FindADGroupforApp{

            $ADGroup = $InputBox.Text
            
            $ApplicationList = @()

            #Find all information for all applications
            #Get-BrokerApplication -AdminAddress $DDC -AssociatedUserFullName "*$ADGroup*" | Select AdminFolderName,@{l="AdminFolderUid";e={$_.AdminFolderUid -join ","}},@{l="AllAssociatedDesktopGroupUUIDs";e={$_.AllAssociatedDesktopGroupUUIDs -join ","}},@{l="AllAssociatedDesktopGroupUids";e={$_.AllAssociatedDesktopGroupUids -join ","}},ApplicationName,ApplicationType,@{l="AssociatedApplicationGroupUUIDs";e={$_.AssociatedApplicationGroupUUIDs -join ","}},@{l="AssociatedApplicationGroupUids";e={$_.AssociatedApplicationGroupUids -join ","}},@{l="AssociatedDesktopGroupPriorities";e={$_.AssociatedDesktopGroupPriorities -join ","}},@{l="AssociatedDesktopGroupUUIDs";e={$_.AssociatedDesktopGroupUUIDs -join ","}},@{l="AssociatedDesktopGroupUids";e={$_.AssociatedDesktopGroupUids -join ","}},@{l="AssociatedUserFullNames";e={$_.AssociatedUserFullNames -join ","}},@{l="AssociatedUserNames";e={$_.AssociatedUserNames -join ","}},@{l="AssociatedUserSIDs";e={$_.AssociatedUserSIDs -join ","}},@{l="AssociatedUserUPNs";e={$_.AssociatedUserUPNs -join ","}},BrowserName,ClientFolder,CommandLineArguments,CommandLineExecutable,@{l="ConfigurationSlotUids";e={$_.ConfigurationSlotUids -join ","}},CpuPriorityLevel,Description,Enabled,HomeZoneName,HomeZoneOnly,HomeZoneUid,IconFromClient,IconUid,IgnoreUserHomeZone,LocalLaunchDisabled,@{l="MachineConfigurationNames";e={$_.MachineConfigurationNames -join ","}},@{l="MachineConfigurationUids";e={$_.MachineConfigurationUids -join ","}},MaxPerMachineInstances,MaxPerUserInstances,MaxTotalInstances,@{l="MetadataKeys";e={$_.MetadataKeys -join ","}},@{l="MetadataMap";e={$_.MetadataMap -join ","}},Name,PublishedName,SecureCmdLineArgumentsEnabled,ShortcutAddedToDesktop,ShortcutAddedToStartMenu,StartMenuFolder,@{l="Tags";e={$_.Tags -join ","}},UUID,Uid,UserFilterEnabled,Visible,WaitForPrinterCreation,WorkingDirectory

            #Find only Application Name for the assigned user/ADGroup
            $ApplicationList = Get-BrokerApplication -AdminAddress $DDC -MaxRecordCount 50000 -AssociatedUserFullName "*$ADGroup*" | Select Name   
            
                    $outputBox.text =  $ApplicationList | Out-String
                    $objStatusBar.Text = "Published Applications List generated"
                
                    
}
              
############################################## Find Published Applications containing specific AD Groups Function END ###############################

############################################## Published Application Report CSV/TXT/XLSX function ###############################

function PARepCSV{

#clear field
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function PARepCSV - error found"
                    }

$OutPath = $InputBox.Text

#### This function deliveres Published Applications with all information to CSV, XLSX and TXT files
### Enter FILENAME in the inputbox.text field


## Create total list incl all information to CSV
Get-BrokerApplication -AdminAddress $DDC -MaxRecordCount 100000 | Select AdminFolderName,@{l="AdminFolderUid";e={$_.AdminFolderUid -join ","}},@{l="AllAssociatedDesktopGroupUUIDs";e={$_.AllAssociatedDesktopGroupUUIDs -join ","}},@{l="AllAssociatedDesktopGroupUids";e={$_.AllAssociatedDesktopGroupUids -join ","}},ApplicationName,ApplicationType,@{l="AssociatedApplicationGroupUUIDs";e={$_.AssociatedApplicationGroupUUIDs -join ","}},@{l="AssociatedApplicationGroupUids";e={$_.AssociatedApplicationGroupUids -join ","}},@{l="AssociatedDesktopGroupPriorities";e={$_.AssociatedDesktopGroupPriorities -join ","}},@{l="AssociatedDesktopGroupUUIDs";e={$_.AssociatedDesktopGroupUUIDs -join ","}},@{l="AssociatedDesktopGroupUids";e={$_.AssociatedDesktopGroupUids -join ","}},@{l="AssociatedUserFullNames";e={$_.AssociatedUserFullNames -join ","}},@{l="AssociatedUserNames";e={$_.AssociatedUserNames -join ","}},@{l="AssociatedUserSIDs";e={$_.AssociatedUserSIDs -join ","}},@{l="AssociatedUserUPNs";e={$_.AssociatedUserUPNs -join ","}},BrowserName,ClientFolder,CommandLineArguments,CommandLineExecutable,@{l="ConfigurationSlotUids";e={$_.ConfigurationSlotUids -join ","}},CpuPriorityLevel,Description,Enabled,HomeZoneName,HomeZoneOnly,HomeZoneUid,IconFromClient,IconUid,IgnoreUserHomeZone,LocalLaunchDisabled,@{l="MachineConfigurationNames";e={$_.MachineConfigurationNames -join ","}},@{l="MachineConfigurationUids";e={$_.MachineConfigurationUids -join ","}},MaxPerMachineInstances,MaxPerUserInstances,MaxTotalInstances,@{l="MetadataKeys";e={$_.MetadataKeys -join ","}},@{l="MetadataMap";e={$_.MetadataMap -join ","}},Name,PublishedName,SecureCmdLineArgumentsEnabled,ShortcutAddedToDesktop,ShortcutAddedToStartMenu,StartMenuFolder,@{l="Tags";e={$_.Tags -join ","}},UUID,Uid,UserFilterEnabled,Visible,WaitForPrinterCreation,WorkingDirectory | Export-Csv -Path ("c:\temp\" + $OutPath + "_Report.csv")  -NoTypeInformation

## Create total list incl all information to TXT
Get-BrokerApplication -AdminAddress $DDC -MaxRecordCount 100000 | Select AdminFolderName,@{l="AdminFolderUid";e={$_.AdminFolderUid -join ","}},@{l="AllAssociatedDesktopGroupUUIDs";e={$_.AllAssociatedDesktopGroupUUIDs -join ","}},@{l="AllAssociatedDesktopGroupUids";e={$_.AllAssociatedDesktopGroupUids -join ","}},ApplicationName,ApplicationType,@{l="AssociatedApplicationGroupUUIDs";e={$_.AssociatedApplicationGroupUUIDs -join ","}},@{l="AssociatedApplicationGroupUids";e={$_.AssociatedApplicationGroupUids -join ","}},@{l="AssociatedDesktopGroupPriorities";e={$_.AssociatedDesktopGroupPriorities -join ","}},@{l="AssociatedDesktopGroupUUIDs";e={$_.AssociatedDesktopGroupUUIDs -join ","}},@{l="AssociatedDesktopGroupUids";e={$_.AssociatedDesktopGroupUids -join ","}},@{l="AssociatedUserFullNames";e={$_.AssociatedUserFullNames -join ","}},@{l="AssociatedUserNames";e={$_.AssociatedUserNames -join ","}},@{l="AssociatedUserSIDs";e={$_.AssociatedUserSIDs -join ","}},@{l="AssociatedUserUPNs";e={$_.AssociatedUserUPNs -join ","}},BrowserName,ClientFolder,CommandLineArguments,CommandLineExecutable,@{l="ConfigurationSlotUids";e={$_.ConfigurationSlotUids -join ","}},CpuPriorityLevel,Description,Enabled,HomeZoneName,HomeZoneOnly,HomeZoneUid,IconFromClient,IconUid,IgnoreUserHomeZone,LocalLaunchDisabled,@{l="MachineConfigurationNames";e={$_.MachineConfigurationNames -join ","}},@{l="MachineConfigurationUids";e={$_.MachineConfigurationUids -join ","}},MaxPerMachineInstances,MaxPerUserInstances,MaxTotalInstances,@{l="MetadataKeys";e={$_.MetadataKeys -join ","}},@{l="MetadataMap";e={$_.MetadataMap -join ","}},Name,PublishedName,SecureCmdLineArgumentsEnabled,ShortcutAddedToDesktop,ShortcutAddedToStartMenu,StartMenuFolder,@{l="Tags";e={$_.Tags -join ","}},UUID,Uid,UserFilterEnabled,Visible,WaitForPrinterCreation,WorkingDirectory | Out-file -FilePath ("c:\temp\" + $OutPath + "_Report.txt")

## Create total list incl all information to EXCEL
Get-BrokerApplication -AdminAddress $DDC -MaxRecordCount 100000 | Select AdminFolderName,@{l="AdminFolderUid";e={$_.AdminFolderUid -join ","}},@{l="AllAssociatedDesktopGroupUUIDs";e={$_.AllAssociatedDesktopGroupUUIDs -join ","}},@{l="AllAssociatedDesktopGroupUids";e={$_.AllAssociatedDesktopGroupUids -join ","}},ApplicationName,ApplicationType,@{l="AssociatedApplicationGroupUUIDs";e={$_.AssociatedApplicationGroupUUIDs -join ","}},@{l="AssociatedApplicationGroupUids";e={$_.AssociatedApplicationGroupUids -join ","}},@{l="AssociatedDesktopGroupPriorities";e={$_.AssociatedDesktopGroupPriorities -join ","}},@{l="AssociatedDesktopGroupUUIDs";e={$_.AssociatedDesktopGroupUUIDs -join ","}},@{l="AssociatedDesktopGroupUids";e={$_.AssociatedDesktopGroupUids -join ","}},@{l="AssociatedUserFullNames";e={$_.AssociatedUserFullNames -join ","}},@{l="AssociatedUserNames";e={$_.AssociatedUserNames -join ","}},@{l="AssociatedUserSIDs";e={$_.AssociatedUserSIDs -join ","}},@{l="AssociatedUserUPNs";e={$_.AssociatedUserUPNs -join ","}},BrowserName,ClientFolder,CommandLineArguments,CommandLineExecutable,@{l="ConfigurationSlotUids";e={$_.ConfigurationSlotUids -join ","}},CpuPriorityLevel,Description,Enabled,HomeZoneName,HomeZoneOnly,HomeZoneUid,IconFromClient,IconUid,IgnoreUserHomeZone,LocalLaunchDisabled,@{l="MachineConfigurationNames";e={$_.MachineConfigurationNames -join ","}},@{l="MachineConfigurationUids";e={$_.MachineConfigurationUids -join ","}},MaxPerMachineInstances,MaxPerUserInstances,MaxTotalInstances,@{l="MetadataKeys";e={$_.MetadataKeys -join ","}},@{l="MetadataMap";e={$_.MetadataMap -join ","}},Name,PublishedName,SecureCmdLineArgumentsEnabled,ShortcutAddedToDesktop,ShortcutAddedToStartMenu,StartMenuFolder,@{l="Tags";e={$_.Tags -join ","}},UUID,Uid,UserFilterEnabled,Visible,WaitForPrinterCreation,WorkingDirectory | Export-Excel -path ("c:\temp\" + $OutPath + "_Report.xlsx") -worksheetname "$OutPath" -TableStyle Medium16 -AutoSize

$outputBox.text = "Total Published Applications list with all information delivered to C:\temp folder on your C-drive"

}


############################################## Published Application Report CSV/TXT function END###############################

############################################## Export Output to TXT file function ###############################

function ExportOutPutBox{
              
              
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function ExportOutPutBox - error found"
                    }
#### This function deliveres content of the OUTPUTBOX to a TXT file
### Enter FILENAME in the inputbox.text field
              
              $FileName = $InputBox.Text

              $outputBox.text | Out-file -FilePath ("c:\temp\" + $FileName + "_Report.txt")
                
}
              
############################################## Export Output to TXT file END ###############################

############################################## Show all Published Applications without users function ###############################

function UnasssignedPubApps{

               
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function UnasssignedPubApps - error found"
                    }


                
                    $outputBox.text =  "Gathering Published Applications info - Please wait...."  | Out-String
                    $PACount = 0

                    # Get all apps without usersassociation
                    $PublishedApps = Get-Brokerapplication -adminaddress $DDC -MaxRecordCount 10000 | Where-Object {($_.UserFilterEnabled -eq $True) -and ( $_.AssociatedUserNames.Count -eq 0  )}| Select-Object PublishedName,AssociatedUserNames | Sort PublishedName | FT -AutoSize | Out-String

                    # Count all apps without usersassociation
                    $PublishedAppsCount = Get-Brokerapplication -adminaddress $DDC -MaxRecordCount 10000 | Where-Object {($_.UserFilterEnabled -eq $True) -and ( $_.AssociatedUserNames.Count -eq 0  )}| Select-Object PublishedName
                    $PACN = Get-Brokerapplication -MaxRecordCount 5000 | Select-Object Name

                    Foreach($PApp in $PublishedAppsCount){
                        $PACount += 1

                    }

                    
                    $outputBox.Text += " Total Apps without users assigned:     " +   $PACount
                    $outputBox.AppendText("`n")
                    $outputBox.AppendText("`n")
                    $outputBox.Text = $PublishedApps
                    $outputBoxCount.Text = $PublishedAppsCount.Count
                    
                  }                  
############################################## Show all Published Applications without users END ###############################

############################################## Show all Virtual Desktops with Obsolete users function ###############################

function VirtualDesktopObsoleteUsersList{

               
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function UnasssignedPubApps - error found"
                    }


                    $VDIGroupName = $listBoxVDIGroups.SelectedItem
                    $outputBox.text =  "Gathering Virtual Desktops info - Please wait...."  | Out-String
                    $VDICount = 0

                    #Get all virtual desktops with obsolete usersassociation
                    $VMList = Get-BrokerDesktop -adminaddress $DDC -MaxRecordCount 10000 -Filter {DesktopGroupName -eq $VDIGroupName -and AssociatedUserNames -contains "*S-1-5-21-*"} -IsAssigned $true | Select-Object MachineName,@{l="AssociatedUserNames";e={$_.AssociatedUserNames -join ","}}
                    
                    $VMListCount = Get-BrokerDesktop -adminaddress $DDC -MaxRecordCount 10000 -Filter {DesktopGroupName -eq $VDIGroupName -and AssociatedUserNames -contains "*S-1-5-21-*"} -IsAssigned $true | Select-Object MachineName,@{l="AssociatedUserNames";e={$_.AssociatedUserNames -join ","}}
                    

                    Foreach($VDI in $VMList){
                        $VDICount += 1

                    }

                    
                    $outputBox.Text += " Total Virtual Desktops with Obsolete users assigned:     " +   $VDICount
                    $outputBox.AppendText("`n")
                    $outputBox.AppendText("`n")
                    $outputBox.Text += $VMList
                    $outputBoxCount.Text = $VDICount
                    
                  }                  
############################################## Show all Virtual Desktops with Obsolete users END ###############################


############################################## Published Applications function ###############################

function VCPApps{

               
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function VCPApps - error found"
                    }

                    $outputBox.text =  "Gathering Published Applications info - Please wait...."  | Out-String

                    $PACount = 0
                    $PublishedApps = Get-Brokerapplication -adminaddress $DDC -MaxRecordCount 10000 | Select-Object Name | FT -AutoSize | Out-String

                    
                    $PACN = Get-Brokerapplication -MaxRecordCount 10000 | Select-Object Name

                    Foreach($PApp in $PACN){
                        $PACount += 1

                    }

                    $outputBox.Text = $PublishedApps
                    $outputBoxCount.Text = $PACount
                    
                  }                  
############################################## Published Applications END ###############################


############################################## Published Applications Usage ###############################

function AppUsage{

               
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function AppUsage - error found"
                    }

                    
                
                    $outputBox.text =  "Gathering Published Applications info - Please wait...."  | Out-String
                    $objStatusBar.Text = "Gathering Published Applications info - Please wait...."

                    
                    $PublishedApps = Get-BrokerApplicationInstance -adminaddress $DDC -MaxRecordCount 10000 | group-Object -Property ApplicationName | sort-object -property Count -Descending | Format-Table -AutoSize -Property Name,Count
                    $PublishedAppsSortName = Get-BrokerApplicationInstance -adminaddress $DDC -MaxRecordCount 10000 | group-Object -Property ApplicationName | sort-object -property Name | Format-Table -AutoSize -Property Name,Count
                                                         
                    #Count Applications In Usage
                    $PublishedAppsCount = Get-BrokerApplicationInstance -adminaddress $DDC -MaxRecordCount 10000 | group-Object -Property Count

                    $outputBox.Text = "Virtual Application Usage sort by Count"
                    $outputBox.AppendText("`n")
                    $outputBox.Text += $PublishedApps | FT | Out-String          
                    $outputBox.AppendText("`n")
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "------------------------------------------------------------------------"
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "Virtual Application Usage sort by Application Name"
                    $outputBox.AppendText("`n")
                    $outputBox.Text += $PublishedAppsSortName | FT | Out-String 
                    $outputBoxCount.Text = $PublishedAppsCount.Count
                    
                  }                  

############################################## Published Applications END ###############################


############################################## Get Scopes from Citrix Studio Function ###############################

function Scopes{
               
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function Scopes - error found"
                    }

                    $outputBox.text =  "Gathering SCOPES info - Please wait...."  | Out-String
                    $objStatusBar.Text = "Gathering SCOPES info - Please wait...."
                    
                    $AllScopes = Get-AdminScope -adminaddress $DDC | FT | Out-String
                    
                    $outputBox.AppendText("`n")
                    $outputBox.Text = "The following SCOPES are available in Citirx Studio" | Out-String
                    $outputBox.AppendText("`n")
                    $outputBox.Text += $AllScopes

                    $objStatusBar.Text = "SCOPES info presented - Please wait...."
                        
                }              

############################################## Get Scopes from Citrix Studio Function END ###############################

############################################## VDI Usage Info Function ####################################
function VDIUsage{

                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function VDIUsage - error found"
                    }
                   
                    $outputBox.text =  "Gathering User assigned to VDI info - Please wait...."  | Out-String

                    $VDIName = $InputBoxVDIName.text
                    $VDI = $DomainPrefix + $VDIName

                    $desktopsall = get-brokermachine -AdminAddress $DDC -MachineName $VDI | FL | Out-String

                    $VDITag = get-brokermachine -AdminAddress $DDC -MachineName $VDI | Select Tags | FL | Out-String

                    $outputBox.Text = "The following VDI: " + $VDIName + " has the following usage information"
                    $outputBox.Text += $VDITag
                    $outputBox.AppendText("`n") 
                    $outputBox.AppendText("`n") 
                    $outputBox.Text += "------------------------------------------------------------"                        
                    $outputBox.Text += $desktopsall

                    }
                          
############################################## VDI Usage Info Function END  ###############################

############################################## VDI Last Usage Count function ###############################

function LastUsageVDI{

                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function LastUsageVDI - error found"
                    }

                    
                    $outputBoxCount.Text = @()
                    $DaysSinceLastLogon = $InputBox.text
                    $outputBox.text =  "Gather Last VDI Connection Time for the last : $DaysSinceLastLogon Days info - Please wait...."  | Out-String

                    $d = (get-date).AddDays(-$DaysSinceLastLogon)
                    
                    $vmcount1 = 0

                    $VMList1 = Get-BrokerMachine -AdminAddress "$DDC"  -MaxRecordCount 10000 -Filter {LastConnectionTime -le $d -and PowerState -eq "Off" } | Select-Object MachineName,Tags,LastConnectionTime,AssociatedUserNames, PowerState | Sort-Object LastConnectionTime

                    $vmcount1 = $VMList1.Count
                    $outputBox.Text = "VDIs that has not been used for the last " + $DaysSinceLastLogon + " days"
                    $outputBox.AppendText("`n") 
                    $outputBox.Text += $VMList1 | FT | Out-String  
                    $outputBox.AppendText("`n") 
                    $outputBox.Text += "Total number of VDIs:  " + $vmcount1
                    $outputBox.AppendText("`n") 
                    $outputBox.Text += "------------------------------------------------------------"

                    
                  }                             
############################################## VDI Last Usage Count END ###############################


############################################## VDA Version function ###############################

function VDAver{

                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function VDAver - error found"
                    }

               $outputBox.text = @() 

        # Get all VDA versions and machines
        $VDAs = Get-BrokerDesktop -AdminAddress "$DDC" -MaxRecordCount 10000 | Select-Object MachineName, AgentVersion | Sort-Object MachineName
        $ToTalVDAs = Get-BrokerDesktop -AdminAddress "$DDC" -MaxRecordCount 10000 | Select-Object AgentVersion
        $VMList1 = Get-BrokerDesktop -AdminAddress "$DDC" -MaxRecordCount 10000 | Select-Object MachineName,AgentVersion | Sort-Object MachineName -Descending | FT | Out-String

        # Create an empty hash table to store the counts of each unique agent version
        $versionCounts = @{}
        $count = 0
        $versionCounts = @{}
        $ToTalVDAsCount = $ToTalVDAs.Count

        # Loop through each desktop in $desktops
        foreach ($VDA in $VDAs) {

            If ($VDA.AgentVersion -eq $Null){
            break
            }
            Else {
            $agentVersion = $VDA.AgentVersion
    

            # Check if the agent version is already in the hash table
            if ($versionCounts.ContainsKey($agentVersion)) {
                # If it exists, increment the count
                $versionCounts[$agentVersion]++
            } else {
                # If it doesn't exist, add it with a count of 1
                $versionCounts[$agentVersion] = 1
            }
            }
        }

            # Display the counts for each unique agent version
            #Write-Host "Total VDA Agent: $ToTalVDAsCount"
            $outputBox.AppendText("`n")
            $outputBox.Text += "Total VDA Agent: $ToTalVDAsCount"
            $outputBox.AppendText("`n")
            $outputBox.AppendText("`n")
            $outputBox.Text += "Count of different VDA Versions on the platform"
            $outputBox.AppendText("`n")
            $outputBox.Text += "--------------------------------------------------------------"
            $outputBox.AppendText("`n")

            foreach ($version in $versionCounts.Keys) {
                $count = $versionCounts[$version]
                #Write-Host "Agent Version: $version   - Count: $count"
   
                $outputBox.Text += "Agent Version: $version " + "- Count: $count"
                $outputBox.AppendText("`n")
                
            }
                    $outputBox.AppendText("`n")
                    $outputBox.Text += $VMList1 | FT | Out-String
                    $objStatusBar.Text = "VDA Versions presented"
                  }                  
############################################## VDA Version END ###############################


############################################## VDI Powered on/off function ###############################

function VDIStatus{
 
                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function VDIStatus - error found"
                    }
 
               
                    $outputBox.text =  "Gathering VDI Powerstate info - Please wait...."  | Out-String
                    $objStatusBar.Text = "Gathering VDI Powerstate info - Please wait...."
                    $DDC = "$DDC"
                    $vmcountList = 0

                    $VMList1 = Get-BrokerDesktop -AdminAddress $DDC -MaxRecordCount 10000 | where MachineName -like $VDIPrefix | Select-Object MachineName,powerstate,SessionState,SessionUserName | Sort-Object powerstate,MachineName | FT | Out-String
                    
                    $VMList1Count = Get-BrokerDesktop -AdminAddress $DDC -MaxRecordCount 10000 -Filter {MachineName -like $VDIPrefix}

                    Foreach ($vm in $VMList1) {
                     $expfile = $vm.MachineName +","+ $vm.powerstate +","+ $vm.AssociatedUserNames
                          [PSCustomObject]@{    
                            Server = $vm.MachineName
                            "Powerstate" = $vm.powerstate
                            User = $vm.AssociatedUserNames 
                            
                    }
                    
                    }
                    
                    $outputBoxCount.Text = $VMList1Count.Count
                       
                    $outputBox.Text = "Total VDI List sorted by PowerState and MachineName"
                    $outputBox.AppendText("`n")
                    $outputBox.Text += $VMList1 | FT | Out-String
                    

                    $objStatusBar.Text = "VDI Powerstate presented"
                    
                 }             
############################################## VDI Powered on/off END ###############################

############################################## Site Info function ###############################

function SiteInfo{

                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function SiteInfo - error found"
                    }

                    $outputBox.text =  "Gathering Site info - Please wait...."  | Out-String
                    $objStatusBar.Text = "Gathering Site info - Please wait...."
                    $DDC = "$DDC"
                    $vmcountList = 0

                    $SiteInfoTotal = Get-BrokerSite -AdminAddress "$DDC" | Out-String
                    $XenAppVer = Get-BrokerController | Select-Object DNSName,State,ControllerVersion
                    
                    
                    $outputBox.Text = "_____________Total XenDesktop Site Information_____________"
                    $outputBox.AppendText("`n")
                    $outputBox.Text += $SiteInfoTotal | Out-String
                    $outputBox.Text += "_____________XenApp Version___________________________"
                    $outputBox.AppendText("`n")
                    $outputBox.Text += $XenAppVer | Out-String

                    $objStatusBar.Text = "Site Info presented"
                  }                  
############################################## Site Info END ###############################

############################################## Site Active Sessions / Licenses function ###############################

function ActiveSes{

                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function ActiveSes - error found"
                    }


                    $outputBox.text =  "Gathering Active Licenses - Please wait...."  | Out-String
                    $objStatusBar.Text = "Gathering Active Licenses - Please wait...."
                    $DDC = "$DDC"
                    $vmcountList = 0

                    $ActiveSessions = Get-BrokerSite -AdminAddress "$DDC" | Select-Object LicensedSessionsActive | Out-String
                    
                    
                    $outputBox.Text = $ActiveSessions | Out-String

                    $objStatusBar.Text = "Active Licenses presented"
                  }                  
############################################## Site Active Sessions END ###############################


############################################## VDI ADM Pass function ###############################

function VDIAP{

                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function VDIAP - error found"
                    }


                    ## Get the local administrator password from the VDI
                    $VDI = $InputBoxVDIName.text
                    $outputBox.text =  "Gathering ADM Pass - Please wait...."  | Out-String
                    $objStatusBar.Text = "Gathering ADM Pass - Please wait...."
                    $vmcountList = 0

                    ## Prompts for credentials for the account that has admin rights on the VDIs
                    $cred = Get-Credential
                    $AP = get-adcomputer -Credential $cred $VDI -Properties ms-Mcs-AdmPwd | Select-Object ms-Mcs-AdmPwd | FT -HideTableHeaders

                    $outputBox.Text = "Local Admin password for " + $VDI + " is:  "
                    $outputBox.AppendText("`n")
                    $outputBox.Text += $AP | Out-String

                    $objStatusBar.Text = "ADM Pass presented"
                  }                  
############################################## VDI ADM Pass END ###############################

############################################## VDI running for 30 days Automated ShutDown function ###############################

function ShutDownVDIsRunning30days{

                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function ShutDownVDIsRunning30days - error found"
                    }

                    $outputBox.text =  "Shutting down Powered On Standard VDI that has not rebooted for 30 days without Active userSessions - Please wait...."  | Out-String
                    $DaysSinceLastLogon = '30'
                    $Today = Get-Date -Format "MM/dd/yyyy HH:mm"
                    $daysince = (get-date).AddDays(-$DaysSinceLastLogon) 
                    $VDIRunD = @()
                    
                    $vmcount =0
                    $objStatusBar.Text = @()                    
                    
                    $VDIMachinesActive = Get-BrokerDesktop -adminaddress $DDC -MaxRecordCount 10000 -Filter {StartTime -le $daysince -and MachineName -like $VDIPrefix -and SessionState -notlike "Active"}# | Select-Object -Property MachineName | Select-Object MachineName | Out-String 
                    
                     foreach ($vdi in $VDIMachinesActive) {
                     
                         New-BrokerHostingPowerAction -Action Shutdown -MachineName $vdi -ActualPriority 1

                         $outputBox.AppendText("`n")
                         $outputBox.Text += "Shutting down VDI: " + $vdi.MachineName
                         $outputBox.AppendText("`n")
                         $outputBox.Text += "VDIs has now been signaled to ShutDown"
                         $outputBox.AppendText("`n")
                         $objStatusBar.Text +=  "Shutting down VDI: " + $vdi.MachineName
                         $vmcount +=1
                     }
                    $outputBoxCount.Text = $VDIMachinesActiveCount.count
}
              
############################################## VDI running for 30 days Automated ShutDown function END ###############################


############################################## Remove TAG from Citrix Studio function ###############################

function VDIRemoveTag{

                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function VDIRemoveTag - error found"
                    }
                    
                    
                    $VDITag = $InputBox.text
                    
                    $outputBox.text =  "Removing TAG: " + $VDITag   | Out-String
                    $objStatusBar.Text = "Removing TAG: " + $VDITag 
                    $vmcountList = 0

                    Remove-BrokerTag -Name $VDITag
                    
                    
                    $outputBox.Text = "Tag : " + $VDITag + " has been removed from Citrix Studio" | Out-String

                    $objStatusBar.Text = "TAG removed from Citrix Studio"
                  }                  
############################################## Remove TAG from Citrix Studio END ###############################


############################################## Create TAG to VDI function ###############################

function VDICreateTag{
                    
                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function VDICreateTag - error found"
                    }
                    
                    $VDITag = $InputBox.text
                    
                    $outputBox.text =  "Creating New VDI TAG: " + $VDITag   | Out-String
                    $objStatusBar.Text = "Creating New VDI TAG: " + $VDITag 
                    $vmcountList = 0

                    New-BrokerTag -Name $VDITag
                    
                    
                    $outputBox.Text = "New Tag : " + $VDITag + " Created" | Out-String

                    $objStatusBar.Text = "New TAG created in Citrix Studio"
                  }                  
############################################## Add TAG to VDI END ###############################


############################################## User Sessions list function ###############################

function CitrixUserSessions {
                   
                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function CitrixUserSessions - error found"
                    }
                    
                    $User = $InputBox.text
                    
                    $UserName = $DomainPrefix + $User
                    $UserSessions = Get-BrokerSession -adminaddress $DDC -MaxRecordCount 10000 -UserName $UserName -Filter { SessionState -eq 'Active' } | Select LaunchedViaPublishedName, ApplicationsInUse, SessionState, AppState, EstablishmentTime | FT #  | Out-String 
                    Get-BrokerSession -adminaddress $DDC -UserName $UserName | FT

                    $outputBox.text = "The user: " + $user + " has the following Active sessions running"
                    $outputBox.AppendText("`n") 
                    $outputBox.text += "----------------------------------------------------------"
                    $outputBox.text += $UserSessions | Out-String
                    $outputBox.AppendText("`n") 
                    $outputBox.AppendText("`n") 
                    $outputBox.text += "----------------------------------------------------------"
                                        
                    $objStatusBar.Text = "Sessions for " + $User + " listed..."
                  }                  

############################################## User Sessions list END ###############################

############################################## User Disconnected Sessions list function ###############################

function CitrixUserSessionsDisc {
                   
                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function CitrixUserSessionsDisc - error found"
                    }
                    
                    $User = $InputBox.text
                    
                    $UserName = $DomainPrefix  + $User
                    $DisconnectedSessions = Get-BrokerSession -adminaddress $DDC -MaxRecordCount 10000 -UserName $UserName -Filter { SessionState -eq 'Disconnected' } | Select-Object Username, ApplicationsInUse, EstablishmentTime, SessionState

                    $outputBox.text = "The user: " + $user + " has the following Disconnected sessions running"
                    $outputBox.AppendText("`n") 
                    $outputBox.text += "----------------------------------------------------------"
                    $outputBox.text += $UserSessions   | Out-String
                    $outputBox.AppendText("`n") 
                    $outputBox.AppendText("`n") 
                    $outputBox.text += "----------------------------------------------------------"
                                 
                    $objStatusBar.Text = "Sessions for " + $User + " listed..."
                  }                  

############################################## User Disconnected Sessions list END ###############################


############################################## Show all session for a specific Publiahed Application list function ###############################

function ApplicationSessions {

                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function ApplicationSessions - error found"
                    }


                   $outputBox.text = @()
                     # Get Published Application sessions
                           
                    $PubAppName = $PubAppsDropDown.SelectedItem
                    

                    # Finds all sessions of the chosen Published Application in $listBoxPubApps.SelectedItem
                    $PublishedAppsInfoConnected = Get-BrokerSession -adminaddress $DDC -MaxRecordCount 10000 -Filter { SessionState -eq 'Active' } | Where-Object ApplicationsInUse -eq $PubAppName | Select-Object Username,SessionState,ApplicationsInUse | Sort-Object UserName
                    $PublishedAppsInfoDisConnected = Get-BrokerSession -adminaddress $DDC -MaxRecordCount 10000 -Filter { SessionState -eq 'Disconnected' } | Where-Object ApplicationsInUse -eq $PubAppName | Select-Object Username,SessionState,ApplicationsInUse | Sort-Object UserName
                    $PublishedAppsInfoTotal = Get-BrokerSession -adminaddress $DDC -MaxRecordCount 10000 -Filter { SessionState -eq 'Active' } | Where-Object ApplicationsInUse -eq $PubAppName

                    $TotalD = $PublishedAppsInfoDisConnected | Out-String
                    $TotalA = $PublishedAppsInfoConnected | Out-String


                    if ($PublishedAppsInfoDisConnected.count -eq 0){
                     $outputBox.AppendText("`n") 
                    $outputBox.text += "No Disconnected sessions for: " + $PubAppName
                     $outputBox.AppendText("`n") 
                     $outputBox.AppendText("`n") 
                     $outputBox.AppendText("`n") 
                    $outputBox.text += "----------------------------------------------------------"
                    $outputBox.AppendText("`n") 

                    }

                    Else {
                    $outputBox.AppendText("`n")
                    $outputBox.text += "Disconnected Sessions for $PubAppName - Total disconnected sessions: " + $PublishedAppsInfoDisConnected.count
                     $outputBox.AppendText("`n") 
                    $outputBox.text += $TotalD
                     $outputBox.AppendText("`n") 
                     $outputBox.AppendText("`n") 
                     $outputBox.AppendText("`n") 
                    $outputBox.text += "----------------------------------------------------------"
                    $outputBox.AppendText("`n") 

                    }

                    if ($PublishedAppsInfoConnected.Count -eq 0){
                    $outputBox.text += "No Active Sessions for: " + $PubAppName
                    $outputBox.AppendText("`n") 
                    }

                    Else {

                     $outputBox.AppendText("`n") 
                     $outputBox.text += "Active Sessions for $PubAppName - Total active sessioons: " + $PublishedAppsInfoConnected.count
                     $outputBox.AppendText("`n") 
                    
                    $outputBox.text += $TotalA

                    }
                    
                    $objStatusBar.Text = "Info about published app: " + $PubAppName + " shown"

                  }                  

############################################## Show all session for a specific Publiahed Application list END ###############################

############################################## Virtual / Published Application Enable function ###############################

function VirtAppEnable {

                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function VirtAppEnable - error found"
                    }
                   

                    $PubAppName = $PubAppsDropDown.SelectedItem
                    Set-BrokerApplication -Name $PubAppName -Enabled $true
                    

                    $outputBox.text = " Virtual / Published Application:  " + $PubAppName + "  - has now been ENABLED"
                    $objStatusBar.Text = " Virtual / Published Application:  " + $PubAppName + "  - has now been ENABLED"
                  }                  

############################################## Virtual / Published Application Enable END ###############################

############################################## Virtual / Published Application Disable function ###############################

function VirtAppDisable {

                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function VirtAppDisable - error found"
                    }
                   

                    $PubAppName = $PubAppsDropDown.SelectedItem
                    Set-BrokerApplication -Name $PubAppName -Enabled $false
                    

                    $outputBox.text = " Virtual / Published Application:  " + $PubAppName + "  - has now been DISABLED"
                    $objStatusBar.Text = " Virtual / Published Application:  " + $PubAppName + "  - has now been DISABLED"
                  }                  

############################################## Virtual / Published Application Disable END ###############################

############################################## Show Publiashed App Associated UserNames Info from listbox function ###############################

function ShowPubAppAssociatedUserNames {


                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function ShowPubAppAssociatedUserNames - error found"
                    }


                    $PubName = $listBoxPubApps.SelectedItem

                    $PublishedAppsInfo = Get-Brokerapplication -adminaddress $DDC -Name $PubName | Select AssociatedUserNames
                    
                    foreach ($user in $PublishedAppsInfo){

                            $userlist += $PublishedAppsInfo.AssociatedUserNames
                    }
                    #$comlist = $userlist -replace "$DomainPrefix","" | sort

                    $PublishedAppsInfo.Length
                    
                    $outputBox.text = "User list for Published Application: " + $PubName
                    $outputBox.AppendText("`n")
                    $outputBox.text += "--------------------------------------------------------------------------------------"
                    $outputBox.AppendText("`n")
                    $outputBox.text += $userlist | Out-String 

                    $outputBoxCount.Text = $userlist.count
                    $objStatusBar.Text = "Users who ha the app published: " + $PubName + " shown"
                  }                  

############################################## Show Publiashed App Associated UserNames Info from listbox END ###############################

############################################## Show Delivery Group Associated UserNames Info from listbox function ###############################

function ShowDeliveryGroupInfo {

                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function ShowDeliveryGroupInfo - error found"
                    }


                    
                    $outputBox.text = @()

                    $PubName = $listBoxPubApps.SelectedItem
                    
                    $DeliveryGroupsInfo = Get-BrokerDesktopGroup -MaxRecordCount 1000 -Name $PubName
              
                    $outputBox.text = "Information for Delivery Group: " + $PubName
                    $outputBox.AppendText("`n")
                    $outputBox.text += "--------------------------------------------------------------------------------------"
                    $outputBox.AppendText("`n")
                    $outputBox.text += $DeliveryGroupsInfo | Out-String 
  
                    $objStatusBar.Text = "Information about the Delivery Group: " + $PubName + " shown"
                  }                  

############################################## Show Delivery Group Associated UserNames Info from listbox END ###############################


############################################## List all XenApp Servers function ###############################

function ListXAServers {

                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function ListXAServers - error found"
                    }


                    $XenAppServers = Get-ADComputer -Filter 'Name -like $XenAppPrefix' | Select Name | sort Name


                    $outputBox.Text = "List of all Active XenApp Servers in the Citrix Farm -  total servers: " + $XenAppServers.Count
                    $outputBox.AppendText("`n")
                    $outputBox.text += "--------------------------------------------------------------------------------------"
                    $outputBox.AppendText("`n")
                    $outputBox.text += $XenAppServers  | Out-String
                    $outputBox.AppendText("`n")
                    $objStatusBar.Text = "Listed all XenApp Servers......"
                    $outputBoxCount.Text = $XenAppServers.Count
                  }                  

############################################## List all XenApp Servers END ###############################


############################################## Show Publiashed App Info from listbox function ###############################

function ShowPubApp {

                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function ShowPubApp - error found"
                    }

                    $PubName = $listBoxPubApps.SelectedItem

                    
                    $PublishedAppsInfo = Get-Brokerapplication -Name $PubName
                    $outputBox.text = $PublishedAppsInfo   | Out-String
                    $objStatusBar.Text = "Info about published app: " + $PubName + " shown"
                  }                  

############################################## Show Publiashed App Info from listbox END ###############################

############################################## Add USER to AD Group from Listbox Function ###############################

function AssignADGroupToUser {

                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function AssignADGroupToUser - error found"
                    }
                    $outputBox.text = @()
                    
                    $User = $InputBox.text
                   #Adding User to the correct AD Group
                   Add-ADGroupMember -Identity $listBoxVDIGroupsAD2.SelectedItem -Members $User
                   Add-ADGroupMember -Identity $listBoxVDIGroupsAD3.SelectedItem -Members $User
                   
                  $outputBox.text = "User : " + $User + " Is now added to AD Group: " + $listBoxVDIGroupsAD2.SelectedItem + " & " + $listBoxVDIGroupsAD3.SelectedItem  | Out-String
                  $objStatusBar.Text = "User : " + $User + " Is now added to AD Group: " + $listBoxVDIGroupsAD2.SelectedItem + " & " + $listBoxVDIGroupsAD3.SelectedItem  | Out-String
                  }                  

############################################## Add USER to AD Group from Listbox END ###############################

############################################## Remove USER from AD Group from Listbox Function ###############################

function RemoveADGroupToUser {

                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function RemoveADGroupToUser - error found"
                    }
                    $outputBox.text = @()
                    
                    $User = $InputBox.text
                   #Adding User to the correct AD Group
                   Remove-ADGroupMember -Identity $listBoxVDIGroupsAD2.SelectedItem -Members $User -Confirm:$false
                   Remove-ADGroupMember -Identity $listBoxVDIGroupsAD3.SelectedItem -Members $User -Confirm:$false
                   
                  $outputBox.text = "User : " + $User + " Is now removed from AD Group: " + $listBoxVDIGroupsAD2.SelectedItem + " & " + $listBoxVDIGroupsAD3.SelectedItem  | Out-String
                  $objStatusBar.Text = "User : " + $User + " Is now removed from AD Group: " + $listBoxVDIGroupsAD2.SelectedItem + " & " + $listBoxVDIGroupsAD3.SelectedItem  | Out-String
                  }                  

############################################## Remove USER from AD Group from Listbox END ###############################

############################################## Show Machine Catalog Information from listbox function ###############################

function ShowMachineCat {

                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function ShowMachineCat - error found"
                    }

                    $MachineCatName = $listBoxPubApps.SelectedItem

                    $MachineCat =Get-BrokerCatalog -adminaddress $DDC -Name $MachineCatName 
                    $outputBox.text = $MachineCat   | Out-String
                    $objStatusBar.Text = "Info about Machine Catalog: " + $MachineCatName + " shown"
                  }                  

############################################## Show Machine Catalog Information from listbox END ###############################

############################################## Show Assigned VDI Information from listbox function ###############################

function SHowAssignedVDIFromList {

                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function SHowAssignedVDIFromList - error found"
                    }

                    $VDIGroupName = $listBoxVDIGroups.SelectedItem

                    $outputBox.text =  "Gathering All assigned VDIs for Group:  " + $VDIGroupName + " - Please wait...."  | Out-String
                    $vmcount = 0
                    $VMList = Get-BrokerDesktop -adminaddress $DDC -MaxRecordCount 10000 -Filter {DesktopGroupName -eq $VDIGroupName} -IsAssigned $true | Select-Object MachineName,Agentversion,Tags,PowerState,SessionUserName,SessionState,LastConnectionTime,@{Name='AssociatedUserNames';Expression={[string]::join(“;”, ($_.AssociatedUserNames))}} | Sort MachineName
                    
                     Foreach ($vm in $VMList) {
                        $vmcount +=1
                        }
                    
                    
                    
                    $outputBox.Text = "All assigned VDIs in the : " + $VDIGroupName + " VDI POOL" + " - Total number of VDIs is: " + $vmcount
                    $outputBox.AppendText("`n")
                    $outputBox.Text += $VMList | FT | Out-String
                    Foreach ($vm in $VMList) {

                        [PSCustomObject]@{    
                            Server = $vm.MachineName
                            "Last Connection time" = $vm.LastConnectionTime
                            "Maint Mode" = $vm.InMaintenanceMode
                            "Associated UserName" = $vm.AssociatedUserNames 
                          }
                          if ($vm.AssociatedUserNames = {})

                            {


                            }
                       
 
                    }
                   

                    If (!$VMList){
                        $outputBox.Text = "There are no Unassigned VDIs in the : " + $VDIGroupName + " VDI POOL"

                    }
                    
                    $outputBoxCount.Text = $vmcount
                  }                  

############################################## Show Assigned VDI Information from listbox END ###############################

############################################## Show Unassigned VDI Information from listbox function ###############################

function SHowUnassignedVDIFromList {

                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function SHowUnassignedVDIFromList - error found"
                    }


                    $VDIGroupName = $listBoxVDIGroups.SelectedItem

                    $outputBox.text =  "Gathering All unassigned VDIs for Group:  " + $VDIGroupName + " - Please wait...."  | Out-String
                    $vmcount = 0
                    $VMList = Get-BrokerDesktop -adminaddress $DDC -MaxRecordCount 10000 -Filter {DesktopGroupName -eq $VDIGroupName} -IsAssigned $false | Select-Object MachineName,Tags,PowerState,@{Name='AssociatedUserNames';Expression={[string]::join(“;”, ($_.AssociatedUserNames))}}
                    $outputBox.Text = "All Unassigned VDIs in the : " + $VDIGroupName + " VDI POOL"
                    $outputBox.AppendText("`n")
                    $outputBox.Text += $VMList | FT | Out-String
                    Foreach ($vm in $VMList) {

                        [PSCustomObject]@{    
                            Server = $vm.MachineName
                            "Last Connection time" = $vm.LastConnectionTime
                            "Maint Mode" = $vm.InMaintenanceMode
                            "Associated UserName" = $vm.AssociatedUserNames 
                          }
                          if ($vm.AssociatedUserNames = {})

                            {


                            }
                       
 
                    }
                    Foreach ($vm in $VMList) {
                        $vmcount +=1
                        }

                    If (!$VMList){
                        $outputBox.Text = "There are no UnAassigned VDIs in the : " + $VDIGroupName + " VDI POOL"

                    }
                    
                    $outputBoxCount.Text = $vmcount
                  }                  

############################################## Show Unassigned VDI Information from listbox END ###############################

############################################## Find VDIs with Obsolete Users from listbox function ###############################

function VDIObsoleteUsersAssigned {

                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function VDIObsoleteUsersAssigned - error found"
                    }

                    $UserVDIUni = @()

                    $outputBox.text =  "Finding Virtual Desktops with Obsolete assigned Users - And removing them from the Virtual Desktop - Please wait...."  | Out-String
                    $vmcount = 0

                    $VMList = Get-BrokerDesktop -adminaddress $DDC -MaxRecordCount 10000 -Filter {MachineName -contains $VDIPrefix -and AssociatedUserNames -contains "*S-1-5-21-*"} -IsAssigned $true | Select-Object MachineName,@{l="AssociatedUserNames";e={$_.AssociatedUserNames -join ","}}

                    $outputBox.AppendText("`n")
                    
                    #Get obsolete unique users
                    Foreach ($VDI in $VMList){


                        $UserVDIUni += $VDI.AssociatedUserNames -split ","

                        }
                    $ObsoleteVDIUsers = $UserVDIUni -like "S-1-5-21-*" | Sort-Object | Get-Unique


                        # Run through the Virtual Desktop Applications and remove the Obsolete users from the Published Applications
    
                              Foreach ($VDI in $VMList){

                                   Foreach ($user in $ObsoleteVDIUsers){

                                    If ($VDI.AssociatedUserNames -notmatch $user){

                                   continue

                                     }
                              else {

                                    #Add DomainPrefix to username
                                    $FinalUserName = $user

                                    #Add DomainPrefix to VDI name
                                    $FinalVDIName = $VDI.MachineName
                                    
                                    $outputBox.AppendText("`n")
                                    $outputBox.Text += " Removing user: " + $FinalUserName + " from Virtual Desktop: " + $FinalVDIName
                                    Remove-BrokerUser $FinalUserName -Machine $FinalVDIName

                                    
                                }
                             }
                            }
                    
                    $outputBoxCount.Text = $vmcount
                  }                  

############################################## Find VDIs with Obsolete Users from listbox END ###############################

############################################## Find Published Applications with Obsolete Users from listbox function ###############################

function PubAppObsoleteUsers {

                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function PubAppObsoleteUsers - error found"
                    }

                    $UserUni = @()

                    # Get all published applications with "Obsolete users"
                    $publishedApps = Get-BrokerApplication -AdminAddress $DDC -MaxRecordCount 100000 -Filter {AssociatedUserNames -contains "*S-1-5-21-*"} | Sort-Object ApplicationName

                    #Get obsolete unique users
                    Foreach ($PubApp in $publishedApps){


                        $UserUni += $PubApp.AssociatedUserNames -split ","

                        }
                    $ObsoleteUsers = $UserUni -like "S-1-5-21-*" | Sort-Object | Get-Unique

                    # Run through the Published Applications and remove the Obsolete users from the Published Applications
    
                              Foreach ($PubApp in $publishedApps){

                                   Foreach ($user in $ObsoleteUsers){

                                    If ($PubApp.AssociatedUserNames -notmatch $user){

                                   continue

                                     }
                              else {
                                    Remove-BrokerUser $user -Application $PubApp.Name
                                }
                             }
                        }

                        $outputBox.Text = "Published Applications with Obsolete Users removed"
}           

############################################## Find Published Applications with Obsolete Users from listbox END ###############################

############################################## Show Publiashed App Usage from listbox function ###############################

function ShowUsagePubApp {


                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function ShowUsagePubApp - error found"
                    }

                    $PubName = $listBoxPubApps.SelectedItem
                    

                    # Finds all sessions of the chosen Published Application in $listBoxPubApps.SelectedItem
                    $PublishedAppsInfo = Get-BrokerSession -adminaddress $DDC -MaxRecordCount 100000 | Where-Object ApplicationsInUse -eq $PubName | Select-Object Username,SessionState,ApplicationsInUse | Sort-Object UserName

                    $PublishedAppsCount = Get-BrokerSession -adminaddress $DDC -MaxRecordCount 100000 | Where-Object ApplicationsInUse -eq $PubName
                    
                    if ($PublishedAppsInfo -eq $NULL){
                        $outputBox.text = "There are no running apps on:  " + $PubName
                        }
                    Else{

                    
                    $outputBox.text = $PublishedAppsInfo   | Out-String
                    }
                    
                    $objStatusBar.Text = "Info about published app: " + $PubName + " shown"

                    $outputBoxCount.Text = $PublishedAppsInfo.Count
                        
                      
                  }                

############################################## Show Publiashed App Usage from listbox END ###############################

############################################## Show XenApp Sessions listbox function ###############################

function ShowXenAppSessions {

                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function ShowXenAppSessions - error found"
                    }

                    $XenAppServer = $listBoxPubApps.SelectedItem
                    

                    # Finds all sessions of the chosen Published Application in $listBoxPubApps.SelectedItem
                    $XenAppServerSessions = Get-BrokerSession -adminaddress $DDC -MaxRecordCount 10000 -DNSName $XenAppServer| Select-Object UserName,DNSName,@{Name='ApplicationsInUse';Expression={[string]::join(“;”, ($_.ApplicationsInUse))}},SessionState,SessionType | FT 
                    
                    
                    
                    if ($XenAppServerSessions -eq $NULL){
                        $outputBox.text = "There are no running Sessions on:  " + $XenAppServer
                        }
                    Else{

                    
                    $outputBox.text = $XenAppServerSessions   | Out-String
                    }
                    
                    $objStatusBar.Text = "Sessions running on: " + $XenAppServer + " shown"

                    $outputBoxCount.Text = $XenAppServerSessions.Count
                        
                      
                  }                

############################################## Show XenApp Sessions listbox END ###############################

function ShowAllXenAppDisconnectedSessions {

                
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function ShowAllXenAppDisconnectedSessions - error found"
                    }

                    

                    # Finds all sessions of the chosen Published Application in $listBoxPubApps.SelectedItem
                    $XenAppServerDisconnectedSessions = Get-BrokerSession -adminaddress $DDC -MaxRecordCount 100000 | Where-Object SessionState -Like "Disconnected"|  Select-Object UserName,DNSName,@{Name='ApplicationsInUse';Expression={[string]::join(“;”, ($_.ApplicationsInUse))}},SessionState,SessionType | Sort-Object SessionType | FT
                    

                    
                    if ($XenAppServerDisconnectedSessions -eq $NULL){
                        $outputBox.text = "There are no Disconnected Sessions"
                        }
                    Else{

                    $outputBox.text = "Number of total disconnected sessions on the Citrix Platform: " + $XenAppServerDisconnectedSessions.count
                    $outputBox.AppendText("`n") 
                    $outputBox.AppendText("`n") 
                    $outputBox.text += "--------------------------------------------------------------------------------------"
                    $outputBox.AppendText("`n") 
                    $outputBox.AppendText("`n") 
                    $outputBox.text += $XenAppServerDisconnectedSessions   | Out-String
                    $outputBox.AppendText("`n") 
                    $outputBox.AppendText("`n") 
                    $outputBox.text += "--------------------------------------------------------------------------------------"
                    
                    
                    }
                    
                    
                    $objStatusBar.Text = "Disconnected Sessions: " + $XenAppServerDisconnectedSessions.Count + " shown"
                    $outputBoxCount.Text = $XenAppServerDisconnectedSessions.Count
                        
                      
                  }                

############################################## Show Publiashed App Usage from listbox END ###############################



############################################## Show XenApp Dashboard Function ###############################

function ShowDirectorDash{

            # For debugging purpose
            if ($debug -eq $True){
            write-host "Before ShowDirectorDash Function - error found"
            }

                
                    $outputBox.text =  "Gathering Citrix Director Dashboard Information - Please wait...."  | Out-String
                    #$DCSystem = @()

                    # Fet todays date
                    $Today = Get-Date -Format "MM/dd/yyyy HH:mm"

                    # Get VDIs
                    $VMListTotal = Get-BrokerDesktop -adminaddress $DDC -MaxRecordCount 10000 -filter {DesktopGroupUid -ne $null} | where MachineName -like $VDIPrefix | Select-Object -Property MachineName,AgentVersion,CatalogName,PowerState,Tags,AssociatedUserNames | Sort-Object CatalogName, MachineName, AgentVersion
                    
              
                    $TableWidth = @{Expression={$_.Col1}; Label="MachineName"; Width=30}, 
                     @{Expression={$_.Col2}; Label="AgentVersion"; Width=30}, 
                     @{Expression={$_.Col3}; Label="Associated Usernames"; Width=30}

                    # Count VDIs
                    $CountVDI = $VMListTotal.count

                    # List active license usage
                    $ActiveSessions = Get-BrokerSite -AdminAddress "$DDC" | Select-Object LicensedSessionsActive | Out-String
                   
                    # All XenApp Servers
                    $XenAppServersListCount = Get-BrokerSession -adminaddress $DDC -MaxRecordCount 10000 | where DNSName -Like $XenAppPrefix | Select-Object DNSName -Unique | sort DNSName

                    # List number of published apps
                    $PACN = @() 
                    $PACNUAT = @()
                    $filteredApps = @()                 
                    
                    
                    # Published Production APPS
                    $PACN = Get-Brokerapplication -MaxRecordCount 10000 | Select-Object ApplicationName, AdminFolderName | Select-Object ApplicationName, AdminFolderName

                    # List all Delivery Groups
                    $DeliveryGroups = Get-BrokerDesktopGroup -adminaddress $DDC -MaxRecordCount 10000 | Select Name

                    # List all Machine Catalogs
                    $MachineCatalogs = Get-BrokerCatalog -adminaddress $DDC -MaxRecordCount 10000 | Select Name

                    # Get registration status of the VDIs
                    $VMList1 = Get-BrokerDesktop -AdminAddress "$DDC" -MaxRecordCount 10000 | where MachineName -like $VDIPrefix  | Select-Object MachineName,powerstate,SessionState,SessionUserName,RegistrationState | Sort-Object powerstate | FT | Out-String
                    
                    Foreach ($vm in $VMList1) {
                     $expfile = $vm.MachineName +","+ $vm.powerstate +","+ $vm.AssociatedUserNames
                          [PSCustomObject]@{    
                            Server = $vm.MachineName
                            "Powerstate" = $vm.powerstate
                            User = $vm.AssociatedUserNames 
                            "RegistrationState" = $vm.RegistrationState
                            
                    }
                    
                    $off = Select-String -InputObject $VMList1 -Pattern "Off" -AllMatches
                    
                    $Unregistered  =Select-String -InputObject $VMList1 -Pattern "Unregistered" -AllMatches
                   
                    $vmcountList = $off.Matches.Count + $on.Matches.Count + $unmanaged.Matches.Count + $unknown.Matches.Count
                    
                    }
                    
                    # Output the information
                    $outputBox.Text = "This is the current total VDI list for each Delivery Group / Machine Catalog"
                    $outputBox.AppendText("`n")
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "---------------------------------------------------------------------"
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "VDI count for the different Delivery Groups / Machine Catalogs:"
                    $outputBox.AppendText("`n")
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "Total amount of VDIs on the platform       " + $VMListTotal.count
                    $outputBox.AppendText("`n")
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "---------------------------------------------------------------------"
                    $outputBox.AppendText("`n")
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "Total VDIs on the Platform:                " + $CountVDI
                    $outputBox.AppendText("`n")
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "Total VDA/VDIs Powered OFF:                " + $off.Matches.Count
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "VDIs Unregistered:                         " + $Unregistered.Matches.Count
                    $outputBox.AppendText("`n")
                    $outputBox.AppendText("`n")
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "---------------------------------------------------------------------"
                    $outputBox.AppendText("`n")
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "Active Citrix Licenses - and time looked up : " + $Today + $ActiveSessions
                    $outputBox.AppendText("`n")
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "XenApp Information ..........................................................."
                    $outputBox.AppendText("`n")
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "Number of XenApp Servers:                     " + $XenAppServersListCount.Count
                    $outputBox.AppendText("`n")                    
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "Number of Published Applications:             " + $PACN.Count
                    $outputBox.AppendText("`n")                    
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "Number of Delivery Groups:                    " + $DeliveryGroups.Count
                    $outputBox.AppendText("`n")                    
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "Number of Machine Catalogs:                   " + $MachineCatalogs.Count
                    $outputBox.AppendText("`n")                    
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "---------------------------------------------------------------------"
                    $outputBox.AppendText("`n")                

}

############################################## Show XenApp Dashboard Function END ###############################

############################################## Find Published Application by Search "word" function ###############################
Function FindPubAppByWord {

            # For debugging purpose
            if ($debug -eq $True){
            write-host "Before FindPubAppByWord Function - error found"
            }

            
            $outputBoxCount.Text = @()
            $PubAppSearchWord = $InputBoxVDIName.text
            $outputBox.Text = @()

            $PubAppName = Get-Brokerapplication -AdminAddress $DDC -MaxRecordCount 10000 | Select-Object ApplicationName, AdminFolderName,ClientFolder | Where-Object {$_.ApplicationName -match "$PubAppSearchWord"} | Select-Object ApplicationName, AdminFolderName, ClientFolder

            If ($PubAppName.Count -notlike "0"){
            $outputBox.Text += "The following Published Applications containing the search string - " + $PubAppSearchWord + " are listed below"
            $outputBox.AppendText("`n")    
            $outputBox.Text = $PubAppName | Out-String
            }

            Else{
            $outputBox.Text += "The are now applications containing the word: " + $PubAppSearchWord
            $outputBox.AppendText("`n")    
            }
}

############################################## Find Published Application by Search "word" function END ###############################
            # For debugging purpose
            if ($debug -eq $True){
            write-host "After FindPubAppByWord Function - Line 5150 - error found"
            }


############################################## Clear All Fields function   #####################################

function Clearfields{
 
                 
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "In function Clearfields - error found"
                    }
           
            $InputBox.text = @()
            $outputBox.text = @()
            $outputBoxCount.Text = @()
            $InputBoxVDIName.Text = @()
            $objStatusBar.Text = @()
                       
            }

        ############################################## Clear All Fields function END #######################



###################### CREATING PS GUI TOOL #############################

    #### Form settings #################################################################
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")  

    $Form = New-Object System.Windows.Forms.Form
    $Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle #modifies the window border
    $Form.Text = "Citrix Admin Tool"    
    $Form.Size = New-Object System.Drawing.Size(1620,950)  
    $Form.StartPosition = "CenterScreen" #loads the window in the center of the screen
    $Form.BackgroundImageLayout = "Zoom"
    $Form.MinimizeBox = $True
    $Form.MaximizeBox = $True
    $Form.ForeColor = "#104277"
    #$Form.BackColor = "#DarkGray"
    $Form.BackColor = "#9C9C9C"
    #$Form.BackColor = "LightGray"
    $Form.SizeGripStyle = "Hide"
    $Icon = [system.drawing.icon]::ExtractAssociatedIcon($PSHOME + "\powershell.exe")
    $Form.Icon = $Icon
    
    # form status bar  
    $objStatusBar = New-Object System.Windows.Forms.StatusBar
    $objStatusBar.Name = "statusBar"
    $objStatusBar.Text = "Ready"
    $Form.Controls.Add($objStatusBar)

    #### Title - Powershell GUI Tool ###################################################
    $LabelTitle = New-Object System.Windows.Forms.Label
    #$LabelFontTitle = New-Object System.Drawing.Font("Calibri",24,[System.Drawing.FontStyle]::Bold)
    #$LabelFontTitle = New-Object System.Drawing.Font("STXihei",24,[System.Drawing.FontStyle]::Bold)
    $LabelFontTitle = New-Object System.Drawing.Font("Papyrus",20,[System.Drawing.FontStyle]::Bold)
    $LabelTitle.Font = $LabelFontTitle
    $LabelTitle.ForeColor = "#092454"
    #$LabelTitle.ForeColor = "#104277"
    $LabelTitle.Text = "Citrix Admin Tool"
    $LabelTitle.AutoSize = $True
    $LabelTitle.Location = New-Object System.Drawing.Size(440,5) 
    $Form.Controls.Add($LabelTitle)

    #### Version - Powershell GUI Tool ###################################################
    $LabelVersion = New-Object System.Windows.Forms.Label
    $LabelFontVersion = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $LabelVersion.Font = $LabelFontVersion
    $LabelVersion.ForeColor = "#092454"
    #$LabelVersion.ForeColor = "#104277"
    $LabelVersion.Text = "Version: 2.0 - updated 29-04-2024"
    $LabelVersion.AutoSize = $True
    $LabelVersion.Location = New-Object System.Drawing.Size(440,50) 
    $Form.Controls.Add($LabelVersion)

    #### Creator - Powershell GUI Tool ###################################################
    $LabelCreator = New-Object System.Windows.Forms.Label
    $LabelFontCreator = New-Object System.Drawing.Font("Calibri",10,[System.Drawing.FontStyle]::Bold)
    $LabelCreator.Font = $LabelFontCreator
    $LabelCreator.ForeColor = "#092454"
    #$LabelCreator.ForeColor = "#104277"
    $LabelCreator.Text = "Created by: Brian Leffler Kruse"
    $LabelCreator.AutoSize = $True
    $LabelCreator.Location = New-Object System.Drawing.Size(440,70) 
    $Form.Controls.Add($LabelCreator)

    #### Label for Application start time ###################################################
    $LabelTimeStart = New-Object System.Windows.Forms.Label
    $LabelTimeStartFont = New-Object System.Drawing.Font("Calibri",8,[System.Drawing.FontStyle]::Bold)
    $LabelTimeStart.Font = $LabelTimeStartFont
    #$TimeSTartforLabel = Get-Date -Format "MM/dd/yyyy HH:mm"
    $TimeSTartforLabel = Get-Date -Format "HH:mm"
    $LabelTimeStart.ForeColor = "White"
    $LabelTimeStart.Text = "Application Start Time: $TimeSTartforLabel"
    $LabelTimeStart.AutoSize = $True
    $LabelTimeStart.Location = New-Object System.Drawing.Size(10,10)
    $Form.Controls.Add($LabelTimeStart)


    #### Title - Total Outbox ###################################################
    $Label = New-Object System.Windows.Forms.Label
    $LabelFont = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $Label.Font = $LabelFont
    $Label.ForeColor = "White"
    $Label.Text = "Information OutPut"
    $Label.AutoSize = $True
    $Label.Location = New-Object System.Drawing.Size(250,100)
    $Form.Controls.Add($Label)
 
    #### Title - Count Outbox ###################################################
    $Label = New-Object System.Windows.Forms.Label
    $LabelFont = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $Label.Font = $LabelFont
    $Label.ForeColor = "White"
    $Label.Text = "Count"
    $Label.AutoSize = $True
    $Label.Location = New-Object System.Drawing.Size(550,100)
    $Form.Controls.Add($Label)

    #### Title - Choose DelioveryGroup ###################################################
    $Label = New-Object System.Windows.Forms.Label
    $LabelFont = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $Label.Font = $LabelFont
    $Label.ForeColor = "White"
    $Label.Text = "Choose Delivery Group"
    $Label.AutoSize = $True
    $Label.Location = New-Object System.Drawing.Size(20,160)
    $Form.Controls.Add($Label)


                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "Before GroupBoxes - error found"
                    }


    #### Group boxes for buttons ########################################################
    $groupBox = New-Object System.Windows.Forms.GroupBox
    $groupBox.Location = New-Object System.Drawing.Size(10,90) 
    $groupBox.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $groupBox.size = New-Object System.Drawing.Size(230,620)
    $groupBox.ForeColor = "White"
    #$groupBox.ForeColor = "#104277"
    $groupBox.text = "VDI Menu" 
    $Form.Controls.Add($groupBox) 

    #### Group boxes for VDI Assignment ########################################################
    $groupBoxVDI = New-Object System.Windows.Forms.GroupBox
    $groupBoxVDI.Location = New-Object System.Drawing.Size(10,720) 
    $groupBoxVDI.Font = New-Object System.Drawing.Font("Calibri",10,[System.Drawing.FontStyle]::Bold)
    $groupBoxVDI.size = New-Object System.Drawing.Size(230,170)
    $groupBoxVDI.ForeColor = "White"
    #$groupBoxVDI.ForeColor = "#104277"
    $groupBoxVDI.text = "VDI Assignment" 
    $Form.Controls.Add($groupBoxVDI) 


    #### Group boxes for buttons on top of OutPutBox APPS related ########################################################
    $groupBoxTop = New-Object System.Windows.Forms.GroupBox
    $groupBoxTop.Location = New-Object System.Drawing.Size(720,15) 
    $groupBoxTop.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $groupBoxTop.size = New-Object System.Drawing.Size(640,110)
    $groupBoxTop.ForeColor = "White"
    #$groupBoxTop.ForeColor = "#104277"
    $groupBoxTop.text = "Apps / VDI - Usage Menu" 
    $Form.Controls.Add($groupBoxTop) 

    #### Group boxes for Clear and Exit buttons on top daof OutPutBox ########################################################
    $groupBoxTopCLEX = New-Object System.Windows.Forms.GroupBox
    $groupBoxTopCLEX.Location = New-Object System.Drawing.Size(1390,15) 
    $groupBoxTopCLEX.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $groupBoxTopCLEX.size = New-Object System.Drawing.Size(210,110)
    $groupBoxTopCLEX.ForeColor = "White"
    #$groupBoxTopCLEX.ForeColor = "#104277"
    $groupBoxTopCLEX.text = "Clear Fields / Exit" 
    $Form.Controls.Add($groupBoxTopCLEX) 

    #### Group boxes for VDI options ########################################################
    $groupBoxBottom = New-Object System.Windows.Forms.GroupBox
    $groupBoxBottom.Location = New-Object System.Drawing.Size(250,550) 
    $groupBoxBottom.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $groupBoxBottom.size = New-Object System.Drawing.Size(520,160)
    $groupBoxBottom.ForeColor = "White"
    #$groupBoxBottom.ForeColor = "#104277"
    $groupBoxBottom.text = "VDI Options" 
    $Form.Controls.Add($groupBoxBottom) 

    #### Group boxes for XenServer options ########################################################
    $groupBoxXenServer = New-Object System.Windows.Forms.GroupBox
    $groupBoxXenServer.Location = New-Object System.Drawing.Size(780,550) 
    $groupBoxXenServer.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $groupBoxXenServer.size = New-Object System.Drawing.Size(220,160)
    $groupBoxXenServer.ForeColor = "White"
    #$groupBoxXenServer.ForeColor = "#104277"
    $groupBoxXenServer.text = "XenServer Options" 
    $Form.Controls.Add($groupBoxXenServer) 

    #### Group boxes for Citrix Studio Buttons ########################################################
    $groupBoxCiStu = New-Object System.Windows.Forms.GroupBox
    $groupBoxCiStu.Location = New-Object System.Drawing.Size(250,720) 
    $groupBoxCiStu.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $groupBoxCiStu.size = New-Object System.Drawing.Size(620,170)
    $groupBoxCiStu.ForeColor = "White"
    #$groupBoxCiStu.ForeColor = "#104277"
    $groupBoxCiStu.text = "Citrix Studio" 
    $Form.Controls.Add($groupBoxCiStu) 

    #### Group boxes for Automation Tasks ########################################################
    $groupBoxAuto = New-Object System.Windows.Forms.GroupBox
    $groupBoxAuto.Location = New-Object System.Drawing.Size(880,720) 
    $groupBoxAuto.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $groupBoxAuto.size = New-Object System.Drawing.Size(280,170)
    $groupBoxAuto.ForeColor = "White"
    #$groupBoxAuto.ForeColor = "#104277"
    $groupBoxAuto.text = "Automation Tasks" 
    $Form.Controls.Add($groupBoxAuto) 


    #### Group boxes for Citrix Site related ########################################################
    $groupBoxSite = New-Object System.Windows.Forms.GroupBox
    $groupBoxSite.Location = New-Object System.Drawing.Size(1170,665) 
    $groupBoxSite.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $groupBoxSite.size = New-Object System.Drawing.Size(420,110)
    $groupBoxSite.ForeColor = "White"
    #$groupBoxSite.ForeColor = "#104277"
    $groupBoxSite.text = "Site Menu" 
    $Form.Controls.Add($groupBoxSite) 

    #### Group boxes for Sessions related ########################################################
    $groupBoxSessions = New-Object System.Windows.Forms.GroupBox
    $groupBoxSessions.Location = New-Object System.Drawing.Size(1010,550) 
    $groupBoxSessions.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $groupBoxSessions.size = New-Object System.Drawing.Size(580,110)
    $groupBoxSessions.ForeColor = "White"
    #$groupBoxSessions.ForeColor = "#104277"
    $groupBoxSessions.text = "Sessions Menu" 
    $Form.Controls.Add($groupBoxSessions) 

    #### Group boxes for Print / Out-File related ########################################################
    $groupBoxOutFile = New-Object System.Windows.Forms.GroupBox
    $groupBoxOutFile.Location = New-Object System.Drawing.Size(1170,780) 
    $groupBoxOutFile.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $groupBoxOutFile.size = New-Object System.Drawing.Size(320,110)
    $groupBoxOutFile.ForeColor = "White"
    #$groupBoxOutFile.ForeColor = "#104277"
    $groupBoxOutFile.text = "Report Options" 
    $Form.Controls.Add($groupBoxOutFile) 



                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "Before Labels - error found"
                    }


################# VDI Assignment tool #############

#Variables#
$CtxSrvtxtbx = "$DDC"
$DomainNametxtbx = "$Domain"



                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "Before Xenserver Listboxes - error found"
                    }


$listBoxXenServer = new-object System.Windows.Forms.ComboBox
$listBoxXenServer.Location = New-Object System.Drawing.Point(10, 90)
$listBoxXenServer.Font = New-Object System.Drawing.Font("Calibri",10,[System.Drawing.FontStyle]::Bold)
$listBoxXenServer.Size = New-Object System.Drawing.Size(00, 22)
$groupBoxXenServer.controls.Add($listBoxXenServer)

            $listBoxXenServer.Items.Clear()

            foreach ($XenServer in $XenServerlist) {
                #$listBoxXenServer.Items.Add($XenServer)
                }
$groupBoxXenServer.Controls.Add($listBoxXenServer)    
           

                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "Before Listboxes for DeliveryGroups - error found"
                    }
               

                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "Before Listboxes for assigned VDIs - error found"
                    }


#assignVDI button
$assignVDI = New-Object System.Windows.Forms.Button 
$assignVDI.Location = New-Object System.Drawing.Size(10, 120) 
$assignVDI.Size = New-Object System.Drawing.Size(100, 40) 
$assignVDI.Font = New-Object System.Drawing.Font("Calibri",10,[System.Drawing.FontStyle]::Bold)
$assignVDI.Text = "Assign VDI" 
$assignVDI.ForeColor = "Black"
$assignVDI.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$assignVDI.BackColor = "LightGray"
$assignVDI.Cursor = [System.Windows.Forms.Cursors]::Hand

$assignVDI.Add_Click( {

        $DomainNameValue = $DomainNametxtbx
        

        if ($DomainNameValue -like "*.*") {
            $DomainNameValue = $DomainNameValue.Split('.')[0]
        }

        $dgdisname = $listBoxVDIGroups.SelectedItem
        $User = $InputBox.text
        $ctxsrvnamevalue = $CtxSrvtxtbx


        #List all delivery groups.
        $dgname = Get-BrokerDesktopGroup -Name $dgdisname -AdminAddress $CtxSrvtxtbx
        $VDIname = (Get-BrokerDesktop -DesktopGroupName $dgname.Name -adminaddress $CtxSrvtxtbx -MaxRecordCount 2000000 | Where-Object { !($_.AssociatedUserNames) }).DNSName


        if (!$VDIname) {
            Add-Type -AssemblyName "System.Windows.Forms"
            [System.Windows.Forms.MessageBox]::Show('There are no Free VDIs in the pool', 'Free VDI issue', 'Ok', 'Hand')
        }
        else {
              $vdicount = Get-BrokerMachine -AssociatedUserName $DomainNameValue\$User -AdminAddress $ctxsrvnamevalue
              if (($vdicount)) {
              Add-Type -AssemblyName "System.Windows.Forms"
                $result = [System.Windows.Forms.MessageBox]::Show('User already has a VDI. Do you wish to proceed?', 'VDI already exists', 'YesNo', 'Question')
                  if ($result -ne "No") {
                   $hostname = $VDIname.Split('.')[0]
                   Add-BrokerUser "$DomainNameValue\$User" -PrivateDesktop "$DomainNameValue\$hostname" -AdminAddress $ctxsrvnamevalue
                   Add-Type -AssemblyName "System.Windows.Forms"
                   [System.Windows.Forms.MessageBox]::Show('VDI ' + "$hostname" + ' assigned successfully.', 'VDI assigned', 'Ok', 'Asterisk')

                   Add-ADGroupMember -Identity $listBoxVDIGroupsAD2.SelectedItem -Members $User
                   Add-ADGroupMember -Identity $listBoxVDIGroupsAD3.SelectedItem -Members $User
                  }
              }
              else {
                   $hostname = $VDIname.Split('.')[0]
                   Add-BrokerUser "$DomainNameValue\$User" -PrivateDesktop "$DomainNameValue\$hostname" -AdminAddress $ctxsrvnamevalue
                   Add-Type -AssemblyName "System.Windows.Forms"
                   [System.Windows.Forms.MessageBox]::Show('VDI ' + $hostname + ' for ' + $User + ' assigned successfully.', 'VDI assigned', 'Ok', 'Asterisk')
                   Add-ADGroupMember -Identity $listBoxVDIGroupsAD2.SelectedItem -Members $User
                   Add-ADGroupMember -Identity $listBoxVDIGroupsAD3.SelectedItem -Members $User

            }
        } 
        $outputBox.Text = $hostname + " is assigned to: " + $User | FT | Out-String
        $outputBox.AppendText("`n")
        $outputBox.Text += $User + " is now added to AD Group:  " + $listBoxVDIGroupsAD2.SelectedItem + " & " + $listBoxVDIGroupsAD3.SelectedItem| FT | Out-String
 
    }) 
$groupBoxVDI.Controls.Add($assignVDI)

                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "Before Listboxes for unassigned VDIs - error found"
                    }

#unassignVDI button
$unassignVDI = New-Object System.Windows.Forms.Button 
$unassignVDI.Location = New-Object System.Drawing.Size(110, 120) 
$unassignVDI.Size = New-Object System.Drawing.Size(100, 40) 
$unassignVDI.Text = "Unassign VDI" 
$unassignVDI.ForeColor = "Black"
$unassignVDI.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$unassignVDI.BackColor = "LightGray"
$unassignVDI.Cursor = [System.Windows.Forms.Cursors]::Hand
$unassignVDI.Add_Click( {

        $DomainNameValue = $DomainNametxtbx
        $userNameValue = $UserNameTxtBx.Text
        $ctxsrvnamevalue = $CtxSrvtxtbx
        

        if ($DomainNameValue -like "*.*") {
            $DomainNameValue = $DomainNameValue.Split('.')[0]
        }

        $vdiassignedtoUser = Get-BrokerMachine -AssociatedUserName $DomainNameValue\$userNameValue -AdminAddress $ctxsrvnamevalue
        foreach ($vdi in $vdiassignedtoUser) { 
            $hostname = $VDI.dnsname.Split('.')[0]
            Remove-BrokerUser "$DomainNameValue\$usernamevalue" -PrivateDesktop "$DomainNameValue\$hostname" -AdminAddress $ctxsrvnamevalue
            }
            Add-Type -AssemblyName "System.Windows.Forms"
        [System.Windows.Forms.MessageBox]::Show('VDI unassigned successfully.', 'VDI unassigned', 'Ok', 'Asterisk')
    }) 
   
    

$groupBoxVDI.Controls.Add($unassignVDI)


                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "After Listboxes for assigned and unassigned VDIs - error found"
                    }

###################### BUTTONS ##########################################################

    #### Line Break Vertical ###################################################################
    $LineBreak = New-Object System.Windows.Forms.Button
    $LineBreak.Location = New-Object System.Drawing.Size(15,130)
    $LineBreak.Size = New-Object System.Drawing.Size(200,5)
    $LineBreak.Font = New-Object System.Drawing.Font("Calibri",10,[System.Drawing.FontStyle]::Bold)
    $LineBreak.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $LineBreak.FlatAppearance.BorderSize = 3
    $LineBreak.FlatAppearance.BorderColor = [System.Drawing.Color]::"WHITE"
    $LineBreak.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($LineBreak)


    
                    # For debugging purpose
                    if ($debug -eq $True){
                    write-host "Before VDISTDPowerstate button - error found"
                    }


    #### List all Citrix Standard VDI Powered Off ###################################################################
    $VDISTDPowerstate = New-Object System.Windows.Forms.Button
    $VDISTDPowerstate.Location = New-Object System.Drawing.Size(15,400)
    $VDISTDPowerstate.Size = New-Object System.Drawing.Size(100,40)
    $VDISTDPowerstate.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDISTDPowerstate.Text = "Standard VDI Powered Off"
    $VDISTDPowerstate.ForeColor = "White"
    $VDISTDPowerstate.BackColor = "Green"
    $VDISTDPowerstate.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VDISTDPowerstate.Add_Click({VDISTDPowerstate})
    $VDISTDPowerstate.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($VDISTDPowerstate)
    
                        # For debugging purpose
                    if ($debug -eq $True){
                    write-host "after VDISTDPowerstate button - error found"
                    }

     #### List all Citrix VDI Usage ###################################################################
    $LastUsageVDI = New-Object System.Windows.Forms.Button
    $LastUsageVDI.Location = New-Object System.Drawing.Size(115,400)
    $LastUsageVDI.Size = New-Object System.Drawing.Size(100,40)
    $LastUsageVDI.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $LastUsageVDI.Text = "Last Usage VDI Enter days"
    $LastUsageVDI.ForeColor = "White"
    $LastUsageVDI.BackColor = "Green"
    $LastUsageVDI.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $LastUsageVDI.Add_Click({LastUsageVDI})
    $LastUsageVDI.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($LastUsageVDI)

                            # For debugging purpose
                    if ($debug -eq $True){
                    write-host "after LastUsageVDI button - error found"
                    }

    #### Line Break Vertical ###################################################################
    $LineBreak = New-Object System.Windows.Forms.Button
    $LineBreak.Location = New-Object System.Drawing.Size(15,445)
    $LineBreak.Size = New-Object System.Drawing.Size(200,5)
    $LineBreak.Font = New-Object System.Drawing.Font("Calibri",10,[System.Drawing.FontStyle]::Bold)
    $LineBreak.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $LineBreak.FlatAppearance.BorderSize = 3
    $LineBreak.FlatAppearance.BorderColor = [System.Drawing.Color]::"white"
    $LineBreak.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($LineBreak)

                            # For debugging purpose
                    if ($debug -eq $True){
                    write-host "after LineBreak button - error found"
                    }
   
    #### Output VDI assigned to Specific user ###################################################################
    $VDIAssign = New-Object System.Windows.Forms.Button
    $VDIAssign.Location = New-Object System.Drawing.Size(15,455)
    $VDIAssign.Size = New-Object System.Drawing.Size(100,40)
    $VDIAssign.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIAssign.Text = "VDI Assigned to specific User"
    $VDIAssign.ForeColor = "#104277"
    $VDIAssign.BackColor = "Orange"
    $VDIAssign.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VDIAssign.Add_Click({VDIAssign})
    $VDIAssign.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($VDIAssign)

    #### Output VDI assigned to Specific username containing ###################################################################
    $VDIAssignUserNameContain = New-Object System.Windows.Forms.Button
    $VDIAssignUserNameContain.Location = New-Object System.Drawing.Size(15,575)
    $VDIAssignUserNameContain.Size = New-Object System.Drawing.Size(100,40)
    $VDIAssignUserNameContain.Font = New-Object System.Drawing.Font("Calibri",7,[System.Drawing.FontStyle]::Bold)
    $VDIAssignUserNameContain.Text = "VDI Assigned Username Containing"
    $VDIAssignUserNameContain.ForeColor = "Yellow"
    $VDIAssignUserNameContain.BackColor = "#104277"
    $VDIAssignUserNameContain.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VDIAssignUserNameContain.Add_Click({VDIAssignUserNameContain})
    $VDIAssignUserNameContain.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($VDIAssignUserNameContain)


    #### Output VDI Tagget with "DO_NOT_TOUCH" ###################################################################
    $VDITAG = New-Object System.Windows.Forms.Button
    $VDITAG.Location = New-Object System.Drawing.Size(15,495)
    $VDITAG.Size = New-Object System.Drawing.Size(100,40)
    $VDITAG.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDITAG.Text = "VDI By TAG List"
    $VDITAG.ForeColor = "Yellow"
    $VDITAG.BackColor = "#104277"
    $VDITAG.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VDITAG.Add_Click({VDITAG})
    $VDITAG.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($VDITAG)

    #### Add User to Specific VDI ###################################################################
    $VDIAddUser = New-Object System.Windows.Forms.Button
    $VDIAddUser.Location = New-Object System.Drawing.Size(10,20)
    $VDIAddUser.Size = New-Object System.Drawing.Size(100,40)
    $VDIAddUser.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIAddUser.Text = "Add User to VDI"
    $VDIAddUser.ForeColor = "Yellow"
    $VDIAddUser.BackColor = "#104277"
    $VDIAddUser.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VDIAddUser.Add_Click({VDIAddUser})
    $VDIAddUser.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxBottom.Controls.Add($VDIAddUser)

    #### Remove User from Specific VDI ###################################################################
    $VDIRemoveUser = New-Object System.Windows.Forms.Button
    $VDIRemoveUser.Location = New-Object System.Drawing.Size(10,65)
    $VDIRemoveUser.Size = New-Object System.Drawing.Size(100,40)
    $VDIRemoveUser.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIRemoveUser.Text = "Remove User from VDI"
    $VDIRemoveUser.ForeColor = "Yellow"
    $VDIRemoveUser.BackColor = "#104277"
    $VDIRemoveUser.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VDIRemoveUser.Add_Click({VDIRemoveUser})
    $VDIRemoveUser.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxBottom.Controls.Add($VDIRemoveUser)
    
    #### Remove User OBSOLETE from Specific VDI ###################################################################
    $VDIRemoveUserObsolete = New-Object System.Windows.Forms.Button
    $VDIRemoveUserObsolete.Location = New-Object System.Drawing.Size(110,20)
    $VDIRemoveUserObsolete.Size = New-Object System.Drawing.Size(100,40)
    $VDIRemoveUserObsolete.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIRemoveUserObsolete.Text = "Remove OBSOLETE USER from VDI"
    $VDIRemoveUserObsolete.ForeColor = "Yellow"
    $VDIRemoveUserObsolete.BackColor = "#104277"
    $VDIRemoveUserObsolete.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VDIRemoveUserObsolete.Add_Click({VDIRemoveUserObsolete})
    $VDIRemoveUserObsolete.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxBottom.Controls.Add($VDIRemoveUserObsolete)

    #### Create VDI Tag ###################################################################
    $VDICreateTag = New-Object System.Windows.Forms.Button
    $VDICreateTag.Location = New-Object System.Drawing.Size(210,20)
    $VDICreateTag.Size = New-Object System.Drawing.Size(100,40)
    $VDICreateTag.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDICreateTag.Text = "Create TAG Citrix Studio"
    $VDICreateTag.ForeColor = "Yellow"
    $VDICreateTag.BackColor = "#104277"
    $VDICreateTag.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VDICreateTag.Add_Click({VDICreateTag})
    $VDICreateTag.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxBottom.Controls.Add($VDICreateTag)

    #### Create VDI Tag ###################################################################
    $VDIRemoveTag = New-Object System.Windows.Forms.Button
    $VDIRemoveTag.Location = New-Object System.Drawing.Size(210,65)
    $VDIRemoveTag.Size = New-Object System.Drawing.Size(100,40)
    $VDIRemoveTag.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIRemoveTag.Text = "Remove TAG Citrix Studio"
    $VDIRemoveTag.ForeColor = "Yellow"
    $VDIRemoveTag.BackColor = "#104277"
    $VDIRemoveTag.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VDIRemoveTag.Add_Click({VDIRemoveTag})
    $VDIRemoveTag.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxBottom.Controls.Add($VDIRemoveTag)

    #### VDI Admin Password ###################################################################
    $VDIAP = New-Object System.Windows.Forms.Button
    $VDIAP.Location = New-Object System.Drawing.Size(10,110)
    $VDIAP.Size = New-Object System.Drawing.Size(100,40)
    $VDIAP.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIAP.Text = "VDI Pass"
    $VDIAP.ForeColor = "Yellow"
    $VDIAP.BackColor = "#104277"
    $VDIAP.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VDIAP.Add_Click({VDIAP})
    $VDIAP.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxBottom.Controls.Add($VDIAP)

    #### VDI Info all output to excel ###################################################################
    $AllVDIandUsertoExcel = New-Object System.Windows.Forms.Button
    $AllVDIandUsertoExcel.Location = New-Object System.Drawing.Size(410,110)
    $AllVDIandUsertoExcel.Size = New-Object System.Drawing.Size(100,40)
    $AllVDIandUsertoExcel.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $AllVDIandUsertoExcel.Text = "All VDI info to Excel"
    $AllVDIandUsertoExcel.ForeColor = "Yellow"
    $AllVDIandUsertoExcel.BackColor = "#104277"
    $AllVDIandUsertoExcel.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $AllVDIandUsertoExcel.Add_Click({AllVDIandUsertoExcel})
    $AllVDIandUsertoExcel.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxBottom.Controls.Add($AllVDIandUsertoExcel)

    
    ###### Group Box Citrix Studio ############################################


    #### Get Scopes in Citrix Studio ###################################################################
    $Scopes = New-Object System.Windows.Forms.Button
    $Scopes.Location = New-Object System.Drawing.Size(10,20)
    $Scopes.Size = New-Object System.Drawing.Size(100,40)
    $Scopes.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $Scopes.Text = "Get Scopes"
    $Scopes.ForeColor = "white"
    $Scopes.BackColor = "#63C132"
    $Scopes.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $Scopes.Add_Click({Scopes})
    $Scopes.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxCiStu.Controls.Add($Scopes)

                            # For debugging purpose
                    if ($debug -eq $True){
                    write-host "before listBoxVDIGroups button - error found"
                    }

    #list VDI Groups Menu
    $VDIGroups = (Get-BrokerDesktopGroup -adminaddress $DDC -Filter {SessionSupport -eq 'SingleSession'} -MaxRecordCount 10000 | Where {($_.DesktopKind -eq 'Private' )} | Select Name | Select-Object @{l="Name";e={$_.Name -join " "}}).Name | Sort 
    $listBoxVDIGroups = new-object System.Windows.Forms.ComboBox
    $listBoxVDIGroups.Location = New-Object System.Drawing.Point(15, 100)
    $listBoxVDIGroups.Font = New-Object System.Drawing.Font("Calibri",10,[System.Drawing.FontStyle]::Bold)
    $listBoxVDIGroups.Size = New-Object System.Drawing.Size(200, 22)
    $listBoxVDIGroups.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $listBoxVDIGroups.Add_Click( {
            $listBoxVDIGroups.Items.Clear()
            foreach ($Group in $VDIGroups) {
                $listBoxVDIGroups.Items.Add($Group)
                 }
                })
    $groupBox.Controls.Add($listBoxVDIGroups)    

### VDI groups for VDI and AD Group assignment
    $VDIGroupsAD = (Get-BrokerDesktopGroup -adminaddress $DDC -Filter {SessionSupport -eq 'SingleSession'} -MaxRecordCount 5000 | Where {($_.DesktopKind -eq 'Private' )} | Select Name | Select-Object @{l="Name";e={$_.Name -join " "}}).Name | Sort 
    $listBoxVDIGroupsAD = new-object System.Windows.Forms.ComboBox
    $listBoxVDIGroupsAD.Location = New-Object System.Drawing.Point(10, 50)
    $listBoxVDIGroupsAD.Font = New-Object System.Drawing.Font("Calibri",10,[System.Drawing.FontStyle]::Bold)
    $listBoxVDIGroupsAD.Size = New-Object System.Drawing.Size(200, 22)
    $listBoxVDIGroupsAD.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $listBoxVDIGroupsAD.Add_Click( {
            $listBoxVDIGroupsAD.Items.Clear()
            foreach ($GroupAD in $VDIGroupsAD) {
                $listBoxVDIGroupsAD.Items.Add($GroupAD)
                 }
                })
    $groupBoxVDI.Controls.Add($listBoxVDIGroupsAD)    


### AD Groups for VDI delivery Groups List
    
    # $groups from toplist variables in the beginning of the script code
    $listBoxVDIGroupsAD2 = new-object System.Windows.Forms.ComboBox
    $listBoxVDIGroupsAD2.Location = New-Object System.Drawing.Point(10, 80)
    $listBoxVDIGroupsAD2.Font = New-Object System.Drawing.Font("Calibri",10,[System.Drawing.FontStyle]::Bold)
    $listBoxVDIGroupsAD2.Size = New-Object System.Drawing.Size(200, 22)
    $listBoxVDIGroupsAD2.Add_Click( {
            $listBoxVDIGroupsAD2.Items.Clear()
            foreach ($GroupAD2 in $groups) {
                $listBoxVDIGroupsAD2.Items.Add($GroupAD2)
                 }
                })
    $groupBoxVDI.Controls.Add($listBoxVDIGroupsAD2)    


    # $groupsTIER2 from toplist variables in the beginning of the script code
    $listBoxVDIGroupsAD3 = new-object System.Windows.Forms.ComboBox
    $listBoxVDIGroupsAD3.Location = New-Object System.Drawing.Point(10, 320)
    $listBoxVDIGroupsAD3.Font = New-Object System.Drawing.Font("Calibri",10,[System.Drawing.FontStyle]::Bold)
    $listBoxVDIGroupsAD3.Size = New-Object System.Drawing.Size(200, 22)
    $listBoxVDIGroupsAD3.Add_Click( {
            $listBoxVDIGroupsAD3.Items.Clear()
            foreach ($GroupAD3 in $groupsTIER2) {
                $listBoxVDIGroupsAD3.Items.Add($GroupAD3)
                 }
                })
    $groupBox.Controls.Add($listBoxVDIGroupsAD3)    
    

    #list delivery group published names
    $listBoxPubApps = new-object System.Windows.Forms.ComboBox
    $listBoxPubApps.Location = New-Object System.Drawing.Point(250, 55)
    $listBoxPubApps.Size = New-Object System.Drawing.Size(250, 20)
    $listBoxPubApps.Font = New-Object System.Drawing.Font("Calibri",8,[System.Drawing.FontStyle]::Bold)
    $groupBoxCiStu.controls.Add($listBoxPubApps)

    #List Published Applications
    $GetPubApps = New-Object System.Windows.Forms.Button 
    $GetPubApps.Location = New-Object System.Drawing.Size(250, 20) 
    $GetPubApps.Size = New-Object System.Drawing.Size(120, 30) 
    $GetPubApps.Font = New-Object System.Drawing.Font("Calibri",11,[System.Drawing.FontStyle]::Bold)
    $GetPubApps.Text = "Published Apps" 
    $GetPubApps.ForeColor = "White"
    $GetPubApps.BackColor = "#104277"
    $GetPubApps.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $GetPubApps.Cursor = [System.Windows.Forms.Cursors]::Hand
    $GetPubApps.Add_Click( {
            
                $listBoxPubApps.Items.Clear()
                $citrixServer = $CtxSrvtxtbx
                $PubAppsList = (Get-BrokerApplication -AdminAddress $DDC -MaxRecordCount 100000 | Select-Object @{l="Name";e={$_.Name -join " "}}).Name | Sort 
                foreach ($dgpubName in $PubAppsList) {

                    $listBoxPubApps.Items.Add($dgpubName)
                }
            
        }) 
    $groupBoxCiStu.Controls.Add($GetPubApps)

    #List Machine Catalogs
    $GetMacCat = New-Object System.Windows.Forms.Button 
    $GetMacCat.Location = New-Object System.Drawing.Size(380, 20) 
    $GetMacCat.Size = New-Object System.Drawing.Size(120, 30) 
    $GetMacCat.Font = New-Object System.Drawing.Font("Calibri",11,[System.Drawing.FontStyle]::Bold)
    $GetMacCat.Text = "Machine Catalogs" 
    $GetMacCat.ForeColor = "White"
    $GetMacCat.BackColor = "#104277"
    $GetMacCat.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $GetMacCat.Cursor = [System.Windows.Forms.Cursors]::Hand
    $GetMacCat.Add_Click( {
            
                $listBoxPubApps.Items.Clear()
                $citrixServer = $CtxSrvtxtbx
                $MachineCat = (Get-BrokerCatalog  -adminaddress $DDC -MaxRecordCount 10000 | Select Name | Select-Object @{l="Name";e={$_.Name -join " "}}).Name | Sort 
                foreach ($dgpubName in $MachineCat) {

                    $listBoxPubApps.Items.Add($dgpubName)
                }
            
        }) 
    $groupBoxCiStu.Controls.Add($GetMacCat)

    #List Delivery Groups
    $GetDelGrp = New-Object System.Windows.Forms.Button 
    $GetDelGrp.Location = New-Object System.Drawing.Size(250, 80) 
    $GetDelGrp.Size = New-Object System.Drawing.Size(120, 30) 
    $GetDelGrp.Font = New-Object System.Drawing.Font("Calibri",11,[System.Drawing.FontStyle]::Bold)
    $GetDelGrp.Text = "Delivery Groups" 
    $GetDelGrp.ForeColor = "White"
    $GetDelGrp.BackColor = "#104277"
    $GetDelGrp.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $GetDelGrp.Cursor = [System.Windows.Forms.Cursors]::Hand
    $GetDelGrp.Add_Click( {
            
                $listBoxPubApps.Items.Clear()
                $citrixServer = $CtxSrvtxtbx
                $DelGroups = (Get-BrokerDesktopGroup -adminaddress $DDC -MaxRecordCount 10000 | Select Name | Select-Object @{l="Name";e={$_.Name -join " "}}).Name | Sort 
                foreach ($dgName in $DelGroups) {

                    $listBoxPubApps.Items.Add($dgName)
                }
            
        }) 
    $groupBoxCiStu.Controls.Add($GetDelGrp)

    #List XenApp Servers
    $GetXenAppServers = New-Object System.Windows.Forms.Button 
    $GetXenAppServers.Location = New-Object System.Drawing.Size(380, 80) 
    $GetXenAppServers.Size = New-Object System.Drawing.Size(120, 30) 
    $GetXenAppServers.Font = New-Object System.Drawing.Font("Calibri",11,[System.Drawing.FontStyle]::Bold)
    $GetXenAppServers.Text = "XenApp Servers" 
    $GetXenAppServers.ForeColor = "White"
    $GetXenAppServers.BackColor = "#104277"
    $GetXenAppServers.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $GetXenAppServers.Cursor = [System.Windows.Forms.Cursors]::Hand
    $GetXenAppServers.Add_Click( {
            
                $listBoxPubApps.Items.Clear()
                $citrixServer = $CtxSrvtxtbx
                $XenAppServersList = (Get-BrokerSession -adminaddress $DDC -MaxRecordCount 10000 | where DNSName -Like $XenAppPrefix | Select-Object @{l="DNSName";e={$_.DNSName -join " "}}).DNSName | Sort-Object @{l="DNSName";e={$_.DNSName -join " "}}.DNSName -Unique
                foreach ($ServerName in $XenAppServersList) {

                    $listBoxPubApps.Items.Add($ServerName)
                }
            $objStatusBar.Text = "Total XenApp Servers: " + $XenAppServersList.Count
        }) 
        
    $groupBoxCiStu.Controls.Add($GetXenAppServers)

                                # For debugging purpose
                    if ($debug -eq $True){
                    write-host "After listBoxes - error found"
                    }

    #list All Published Applications
    $PubAppsList = (Get-BrokerApplication -AdminAddress $DDC -MaxRecordCount 100000 | Select-Object @{l="Name";e={$_.Name -join " "}}).Name | Sort     
    $PubAppsDropDown = new-object System.Windows.Forms.ComboBox
    $PubAppsDropDown.Location = New-Object System.Drawing.Point(220, 20)
    $PubAppsDropDown.Size = New-Object System.Drawing.Size(350, 20)
    $PubAppsDropDown.Font = New-Object System.Drawing.Font("Calibri",8,[System.Drawing.FontStyle]::Bold)
    $groupBoxSessions.controls.Add($PubAppsDropDown)
    $PubAppsDropDown.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $PubAppsDropDown.Cursor = [System.Windows.Forms.Cursors]::Hand
    $PubAppsDropDown.Add_Click( {
            
                $PubAppsDropDown.Items.Clear()
                $PubAppsList = (Get-BrokerApplication -AdminAddress $DDC -MaxRecordCount 100000 | Select-Object @{l="Name";e={$_.Name -join " "}}).Name | Sort 
                foreach ($dgpubName in $PubAppsList) {

                    $PubAppsDropDown.Items.Add($dgpubName)
                }
            
        }) 
    $groupBoxSessions.Controls.Add($PubAppsDropDown)






    #### Show all details of selected published app from listbox ###################################################################
    $ShowPubApp = New-Object System.Windows.Forms.Button
    $ShowPubApp.Location = New-Object System.Drawing.Size(10,65)
    $ShowPubApp.Size = New-Object System.Drawing.Size(100,40)
    $ShowPubApp.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $ShowPubApp.Text = "Show PubApp Info"
    $ShowPubApp.ForeColor = "white"
    $ShowPubApp.BackColor = "#63C132"
    $ShowPubApp.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $ShowPubApp.Add_Click({ShowPubApp})
    $ShowPubApp.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxCiStu.Controls.Add($ShowPubApp)

    #### Show all associated UserNames of selected published app from listbox ###################################################################
    $ShowPubAppAssociatedUserNames = New-Object System.Windows.Forms.Button
    $ShowPubAppAssociatedUserNames.Location = New-Object System.Drawing.Size(10,110)
    $ShowPubAppAssociatedUserNames.Size = New-Object System.Drawing.Size(100,40)
    $ShowPubAppAssociatedUserNames.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $ShowPubAppAssociatedUserNames.Text = "Show PubApp Users"
    $ShowPubAppAssociatedUserNames.ForeColor = "white"
    $ShowPubAppAssociatedUserNames.BackColor = "#63C132"
    $ShowPubAppAssociatedUserNames.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $ShowPubAppAssociatedUserNames.Add_Click({ShowPubAppAssociatedUserNames})
    $ShowPubAppAssociatedUserNames.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxCiStu.Controls.Add($ShowPubAppAssociatedUserNames)

    #### Show all associated UserNames of selected Delivery Group app from listbox ###################################################################
    $ShowDeliveryGroupInfo = New-Object System.Windows.Forms.Button
    $ShowDeliveryGroupInfo.Location = New-Object System.Drawing.Size(110,110)
    $ShowDeliveryGroupInfo.Size = New-Object System.Drawing.Size(100,40)
    $ShowDeliveryGroupInfo.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $ShowDeliveryGroupInfo.Text = "Show Delivery Group Info"
    $ShowDeliveryGroupInfo.ForeColor = "white"
    $ShowDeliveryGroupInfo.BackColor = "#63C132"
    $ShowDeliveryGroupInfo.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $ShowDeliveryGroupInfo.Add_Click({ShowDeliveryGroupInfo})
    $ShowDeliveryGroupInfo.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxCiStu.Controls.Add($ShowDeliveryGroupInfo)


    #### Show all details of selected Machine catalog from listbox ###################################################################
    $ShowMachineCat = New-Object System.Windows.Forms.Button
    $ShowMachineCat.Location = New-Object System.Drawing.Size(110,20)
    $ShowMachineCat.Size = New-Object System.Drawing.Size(100,40)
    $ShowMachineCat.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $ShowMachineCat.Text = "Show Machine Catalog"
    $ShowMachineCat.ForeColor = "white"
    $ShowMachineCat.BackColor = "#63C132"
    $ShowMachineCat.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $ShowMachineCat.Add_Click({ShowMachineCat})
    $ShowMachineCat.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxCiStu.Controls.Add($ShowMachineCat)


     #### Show Usage of selected published app from listbox ###################################################################
    $ShowUsagePubApp = New-Object System.Windows.Forms.Button
    $ShowUsagePubApp.Location = New-Object System.Drawing.Size(110,65)
    $ShowUsagePubApp.Size = New-Object System.Drawing.Size(100,40)
    $ShowUsagePubApp.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $ShowUsagePubApp.Text = "Show PubApp Usage"
    $ShowUsagePubApp.ForeColor = "white"
    $ShowUsagePubApp.BackColor = "#63C132"
    $ShowUsagePubApp.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $ShowUsagePubApp.Add_Click({ShowUsagePubApp})
    $ShowUsagePubApp.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxCiStu.Controls.Add($ShowUsagePubApp)


    #### Show Specific XenApp Server User sessions listbox ###################################################################
    $ShowXenAppSessions = New-Object System.Windows.Forms.Button
    $ShowXenAppSessions.Location = New-Object System.Drawing.Size(510,20)
    $ShowXenAppSessions.Size = New-Object System.Drawing.Size(100,40)
    $ShowXenAppSessions.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $ShowXenAppSessions.Text = "Show XenApp User Sessions"
    $ShowXenAppSessions.ForeColor = "white"
    $ShowXenAppSessions.BackColor = "#63C132"
    $ShowXenAppSessions.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $ShowXenAppSessions.Add_Click({ShowXenAppSessions})
    $ShowXenAppSessions.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxCiStu.Controls.Add($ShowXenAppSessions)

    #### Show Specific XenApp Server User sessions listbox ###################################################################
    $ShowAllXenAppDisconnectedSessions = New-Object System.Windows.Forms.Button
    $ShowAllXenAppDisconnectedSessions.Location = New-Object System.Drawing.Size(510,65)
    $ShowAllXenAppDisconnectedSessions.Size = New-Object System.Drawing.Size(100,50)
    $ShowAllXenAppDisconnectedSessions.Font = New-Object System.Drawing.Font("Calibri",8,[System.Drawing.FontStyle]::Bold)
    $ShowAllXenAppDisconnectedSessions.Text = "Show All Disconnected Sessions"
    $ShowAllXenAppDisconnectedSessions.ForeColor = "white"
    $ShowAllXenAppDisconnectedSessions.BackColor = "#63C132"
    $ShowAllXenAppDisconnectedSessions.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $ShowAllXenAppDisconnectedSessions.Add_Click({ShowAllXenAppDisconnectedSessions})
    $ShowAllXenAppDisconnectedSessions.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxCiStu.Controls.Add($ShowAllXenAppDisconnectedSessions)

    #### Show Citrix Director Dashboard information ###################################################################
    $ShowDirectorDash = New-Object System.Windows.Forms.Button
    $ShowDirectorDash.Location = New-Object System.Drawing.Size(510,120)
    $ShowDirectorDash.Size = New-Object System.Drawing.Size(100,40)
    $ShowDirectorDash.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $ShowDirectorDash.Text = "DASHBOARD"
    $ShowDirectorDash.ForeColor = "black"
    $ShowDirectorDash.BackColor = "yellow"    
    $ShowDirectorDash.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $ShowDirectorDash.Add_Click({ShowDirectorDash})
    $ShowDirectorDash.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxCiStu.Controls.Add($ShowDirectorDash)

    #### Output VDI IN/OFF status ###################################################################
    $VDIStatus = New-Object System.Windows.Forms.Button
    $VDIStatus.Location = New-Object System.Drawing.Size(115,495)
    $VDIStatus.Size = New-Object System.Drawing.Size(100,40)
    $VDIStatus.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIStatus.Text = "VDI Powered on/off"
    $VDIStatus.ForeColor = "Yellow"
    $VDIStatus.BackColor = "#104277"
    $VDIStatus.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VDIStatus.Add_Click({VDIStatus})
    $VDIStatus.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($VDIStatus)
    
    #### List VDI VDI Names only ###################################################################
    $VDIListNameOnly = New-Object System.Windows.Forms.Button
    $VDIListNameOnly.Location = New-Object System.Drawing.Size(115,535)
    $VDIListNameOnly.Size = New-Object System.Drawing.Size(100,40)
    $VDIListNameOnly.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIListNameOnly.Text = "List All VDIs"
    $VDIListNameOnly.ForeColor = "Yellow"
    $VDIListNameOnly.BackColor = "#104277"
    $VDIListNameOnly.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VDIListNameOnly.Add_Click({VDIListNameOnly})
    $VDIListNameOnly.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($VDIListNameOnly)

    #### List All disabled users assigned VDIs and the Delivery Group ###################################################################
    $DisabledUsersVDI = New-Object System.Windows.Forms.Button
    $DisabledUsersVDI.Location = New-Object System.Drawing.Size(115,575)
    $DisabledUsersVDI.Size = New-Object System.Drawing.Size(100,40)
    $DisabledUsersVDI.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $DisabledUsersVDI.Text = "List all disabled users VDIs"
    $DisabledUsersVDI.ForeColor = "WHITE"
    $DisabledUsersVDI.BackColor = "RED"
    $DisabledUsersVDI.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $DisabledUsersVDI.Add_Click({DisabledUsersVDI})
    $DisabledUsersVDI.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($DisabledUsersVDI)

    #### List Specific VDI information only ###################################################################
    $VDISpecInfo = New-Object System.Windows.Forms.Button
    $VDISpecInfo.Location = New-Object System.Drawing.Size(15,535)
    $VDISpecInfo.Size = New-Object System.Drawing.Size(100,40)
    $VDISpecInfo.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDISpecInfo.Text = "VDI Specs"
    $VDISpecInfo.ForeColor = "Yellow"
    $VDISpecInfo.BackColor = "#104277"
    $VDISpecInfo.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VDISpecInfo.Add_Click({VDISpecInfo})
    $VDISpecInfo.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($VDISpecInfo)

    #### Output User assigned to specific VDI ###################################################################
    $VDIUserAssign = New-Object System.Windows.Forms.Button
    $VDIUserAssign.Location = New-Object System.Drawing.Size(115,455)
    $VDIUserAssign.Size = New-Object System.Drawing.Size(100,40)
    $VDIUserAssign.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIUserAssign.Text = "User Assigned to specific VDI"
    $VDIUserAssign.ForeColor = "#104277"
    $VDIUserAssign.BackColor = "Orange"
    $VDIUserAssign.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VDIUserAssign.Add_Click({VDIUserAssign})
    $VDIUserAssign.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($VDIUserAssign)

    #### Output Assigned VDIs ###################################################################
    $SHowAssignedVDIFromList = New-Object System.Windows.Forms.Button
    $SHowAssignedVDIFromList.Location = New-Object System.Drawing.Size(115,25)
    $SHowAssignedVDIFromList.Size = New-Object System.Drawing.Size(100,40)
    $SHowAssignedVDIFromList.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $SHowAssignedVDIFromList.Text = "Get Assigned VDIs"
    $SHowAssignedVDIFromList.ForeColor = "#104277"
    $SHowAssignedVDIFromList.BackColor = "White"
    $SHowAssignedVDIFromList.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $SHowAssignedVDIFromList.Add_Click({SHowAssignedVDIFromList})
    $SHowAssignedVDIFromList.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($SHowAssignedVDIFromList)

    #### Output Unassigned VDIs ###################################################################
    $SHowUnassignedVDIFromList = New-Object System.Windows.Forms.Button
    $SHowUnassignedVDIFromList.Location = New-Object System.Drawing.Size(15,25)
    $SHowUnassignedVDIFromList.Size = New-Object System.Drawing.Size(100,40)
    $SHowUnassignedVDIFromList.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $SHowUnassignedVDIFromList.Text = "Get Unassigned VDIs"
    $SHowUnassignedVDIFromList.ForeColor = "#104277"
    $SHowUnassignedVDIFromList.BackColor = "White"
    $SHowUnassignedVDIFromList.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $SHowUnassignedVDIFromList.Add_Click({SHowUnassignedVDIFromList})
    $SHowUnassignedVDIFromList.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($SHowUnassignedVDIFromList)

    #### Citrix Published Applications Without user assignment ###################################################################
    $UnasssignedPubApps = New-Object System.Windows.Forms.Button
    $UnasssignedPubApps.Location = New-Object System.Drawing.Size(10,150)
    $UnasssignedPubApps.Size = New-Object System.Drawing.Size(100,40)
    $UnasssignedPubApps.Font = New-Object System.Drawing.Font("Calibri",8,[System.Drawing.FontStyle]::Bold)
    $UnasssignedPubApps.Text = "Show Unassigned Published Apps"
    $UnasssignedPubApps.ForeColor = "#104277"
    $UnasssignedPubApps.BackColor = "White"
    $UnasssignedPubApps.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $UnasssignedPubApps.Add_Click({UnasssignedPubApps})
    $UnasssignedPubApps.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($UnasssignedPubApps)


    
    #### Citrix Virtual Desktops with Obsolete user assignment ###################################################################
    $VirtualDesktopObsoleteUsersList = New-Object System.Windows.Forms.Button
    $VirtualDesktopObsoleteUsersList.Location = New-Object System.Drawing.Size(110,150)
    $VirtualDesktopObsoleteUsersList.Size = New-Object System.Drawing.Size(100,40)
    $VirtualDesktopObsoleteUsersList.Font = New-Object System.Drawing.Font("Calibri",7,[System.Drawing.FontStyle]::Bold)
    $VirtualDesktopObsoleteUsersList.Text = "Virtual Desktops With Obsoleet Users Assigned"
    $VirtualDesktopObsoleteUsersList.ForeColor = "#104277"
    $VirtualDesktopObsoleteUsersList.BackColor = "White"
    $VirtualDesktopObsoleteUsersList.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VirtualDesktopObsoleteUsersList.Add_Click({VirtualDesktopObsoleteUsersList})
    $VirtualDesktopObsoleteUsersList.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($VirtualDesktopObsoleteUsersList)


    #### Find VDIs with Obsolete Users ###################################################################
    $VDIObsoleteUsersAssigned = New-Object System.Windows.Forms.Button
    $VDIObsoleteUsersAssigned.Location = New-Object System.Drawing.Size(110,20)
    $VDIObsoleteUsersAssigned.Size = New-Object System.Drawing.Size(100,40)
    $VDIObsoleteUsersAssigned.Font = New-Object System.Drawing.Font("Calibri",7,[System.Drawing.FontStyle]::Bold)
    $VDIObsoleteUsersAssigned.Text = "Remove Obsolete Users from Virtual Desktops"
    $VDIObsoleteUsersAssigned.ForeColor = "black"
    $VDIObsoleteUsersAssigned.BackColor = "yellow"
    $VDIObsoleteUsersAssigned.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VDIObsoleteUsersAssigned.Add_Click({VDIObsoleteUsersAssigned})
    $VDIObsoleteUsersAssigned.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxAuto.Controls.Add($VDIObsoleteUsersAssigned)

    #### Find Published Applications with Obsolete Users ###################################################################
    $PubAppObsoleteUsers = New-Object System.Windows.Forms.Button
    $PubAppObsoleteUsers.Location = New-Object System.Drawing.Size(10,20)
    $PubAppObsoleteUsers.Size = New-Object System.Drawing.Size(100,40)
    $PubAppObsoleteUsers.Font = New-Object System.Drawing.Font("Calibri",7,[System.Drawing.FontStyle]::Bold)
    $PubAppObsoleteUsers.Text = "Remove Obsolete Users from Virtual Apps"
    $PubAppObsoleteUsers.ForeColor = "black"
    $PubAppObsoleteUsers.BackColor = "yellow"
    $PubAppObsoleteUsers.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $PubAppObsoleteUsers.Add_Click({PubAppObsoleteUsers})
    $PubAppObsoleteUsers.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxAuto.Controls.Add($PubAppObsoleteUsers)

    #### Import VDI list and find users ###################################################################
    $FindUsersFromVDIList = New-Object System.Windows.Forms.Button
    $FindUsersFromVDIList.Location = New-Object System.Drawing.Size(10,230)
    $FindUsersFromVDIList.Size = New-Object System.Drawing.Size(100,40)
    $FindUsersFromVDIList.Font = New-Object System.Drawing.Font("Calibri",8,[System.Drawing.FontStyle]::Bold)
    $FindUsersFromVDIList.Text = "Find Users from VDI List"
    $FindUsersFromVDIList.ForeColor = "#104277"
    $FindUsersFromVDIList.BackColor = "Orange"
    $FindUsersFromVDIList.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $FindUsersFromVDIList.Add_Click({FindUsersFromVDIList})
    $FindUsersFromVDIList.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($FindUsersFromVDIList)

    #### Add user to AD group from listbox ###################################################################
    $AssignADGroupToUser = New-Object System.Windows.Forms.Button
    $AssignADGroupToUser.Location = New-Object System.Drawing.Size(10,275)
    $AssignADGroupToUser.Size = New-Object System.Drawing.Size(100,40)
    $AssignADGroupToUser.Font = New-Object System.Drawing.Font("Calibri",8,[System.Drawing.FontStyle]::Bold)
    $AssignADGroupToUser.Text = "Add USER to AD Group"
    $AssignADGroupToUser.ForeColor = "#104277"
    $AssignADGroupToUser.BackColor = "White"
    $AssignADGroupToUser.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $AssignADGroupToUser.Add_Click({AssignADGroupToUser})
    $AssignADGroupToUser.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($AssignADGroupToUser)

    #### Remove user to AD group from listbox ###################################################################
    $RemoveADGroupToUser = New-Object System.Windows.Forms.Button
    $RemoveADGroupToUser.Location = New-Object System.Drawing.Size(110,275)
    $RemoveADGroupToUser.Size = New-Object System.Drawing.Size(100,40)
    $RemoveADGroupToUser.Font = New-Object System.Drawing.Font("Calibri",8,[System.Drawing.FontStyle]::Bold)
    $RemoveADGroupToUser.Text = "Remove USER from AD Group"
    $RemoveADGroupToUser.ForeColor = "#104277"
    $RemoveADGroupToUser.BackColor = "White"
    $RemoveADGroupToUser.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $RemoveADGroupToUser.Add_Click({RemoveADGroupToUser})
    $RemoveADGroupToUser.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($RemoveADGroupToUser)

    
    

    
                                # For debugging purpose
                    if ($debug -eq $True){
                    write-host "After Boxes - error found"
                    }


############################### groupBoxTop #################################################
   
    #### Citrix Published Applications ###################################################################
    $VCPApps = New-Object System.Windows.Forms.Button
    $VCPApps.Location = New-Object System.Drawing.Size(10,20)
    $VCPApps.Size = New-Object System.Drawing.Size(100,40)
    $VCPApps.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VCPApps.Text = "Show All Published Apps"
    $VCPApps.ForeColor = "White"
    $VCPApps.BackColor = "#104277"
    $VCPApps.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VCPApps.Add_Click({VCPApps})
    $VCPApps.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxTop.Controls.Add($VCPApps)

            
                                # For debugging purpose
                    if ($debug -eq $True){
                    write-host "After Show All Published Apps - error found"
                    }

    #### VDI Software ###################################################################
    
    #### Citrix VDI usage ###################################################################
    $VDIUsage = New-Object System.Windows.Forms.Button
    $VDIUsage.Location = New-Object System.Drawing.Size(110,65)
    $VDIUsage.Size = New-Object System.Drawing.Size(100,40)
    $VDIUsage.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIUsage.Text = "VDI Usage Info"
    $VDIUsage.ForeColor = "#104277"
    $VDIUsage.BackColor = "White"
    $VDIUsage.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VDIUsage.Add_Click({VDIUsage})
    $VDIUsage.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxBottom.Controls.Add($VDIUsage)
         
                                # For debugging purpose
                    if ($debug -eq $True){
                    write-host "After VDI Usage Info - error found"
                    }
   
    #### Application Usage ###################################################################
    $AppUsage = New-Object System.Windows.Forms.Button
    $AppUsage.Location = New-Object System.Drawing.Size(115,20)
    $AppUsage.Size = New-Object System.Drawing.Size(100,40)
    $AppUsage.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $AppUsage.Text = "App Usage"
    $AppUsage.ForeColor = "White"
    $AppUsage.BackColor = "#104277"
    $AppUsage.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $AppUsage.Add_Click({AppUsage})
    $AppUsage.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxTop.Controls.Add($AppUsage)
        
                                # For debugging purpose
                    if ($debug -eq $True){
                    write-host "After App Usage - error found"
                    }

    #### Find all Applications that have a specific AD Group associated ###################################################################
    $FindADGroupforApp = New-Object System.Windows.Forms.Button
    $FindADGroupforApp.Location = New-Object System.Drawing.Size(220,20)
    $FindADGroupforApp.Size = New-Object System.Drawing.Size(100,40)
    $FindADGroupforApp.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $FindADGroupforApp.Text = "Find PubApp Assigned Groups"
    $FindADGroupforApp.ForeColor = "White"
    $FindADGroupforApp.BackColor = "#104277"
    $FindADGroupforApp.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $FindADGroupforApp.Add_Click({FindADGroupforApp})
    $FindADGroupforApp.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxTop.Controls.Add($FindADGroupforApp)
        
                                # For debugging purpose
                    if ($debug -eq $True){
                    write-host "After Add User to Application - error found"
                    }

    #### VDA Versions ###################################################################
    $VDAver = New-Object System.Windows.Forms.Button
    $VDAver.Location = New-Object System.Drawing.Size(115,65)
    $VDAver.Size = New-Object System.Drawing.Size(100,40)
    $VDAver.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDAver.Text = "VDA Versions"
    $VDAver.ForeColor = "White"
    $VDAver.BackColor = "#104277"
    $VDAver.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VDAver.Add_Click({VDAver})
    $VDAver.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxTop.Controls.Add($VDAver)
        
                                # For debugging purpose
                    if ($debug -eq $True){
                    write-host "After VDA Versions - error found"
                    }

    #### Delivery Groups ###################################################################
    $DelGrp = New-Object System.Windows.Forms.Button
    $DelGrp.Location = New-Object System.Drawing.Size(325,20)
    $DelGrp.Size = New-Object System.Drawing.Size(100,40)
    $DelGrp.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $DelGrp.Text = "List all VDI Delivery Groups"
    $DelGrp.ForeColor = "White"
    $DelGrp.BackColor = "#104277"
    $DelGrp.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $DelGrp.Add_Click({DelGrp})
    $DelGrp.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxTop.Controls.Add($DelGrp)
        
                                # For debugging purpose
                    if ($debug -eq $True){
                    write-host "After List all VDI Delivery Groups - error found"
                    }
   
    #### List XenApp Servers Groups ###################################################################
    $ListXAServers = New-Object System.Windows.Forms.Button
    $ListXAServers.Location = New-Object System.Drawing.Size(430,65)
    $ListXAServers.Size = New-Object System.Drawing.Size(100,40)
    $ListXAServers.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $ListXAServers.Text = "List all XenApp servers"
    $ListXAServers.ForeColor = "White"
    $ListXAServers.BackColor = "#104277"
    $ListXAServers.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $ListXAServers.Add_Click({ListXAServers})
    $ListXAServers.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxTop.Controls.Add($ListXAServers)
        
                                # For debugging purpose
                    if ($debug -eq $True){
                    write-host "After List all XenApp servers - error found"
                    }
    
    #### Machine Catalogs ###################################################################
    $MacCat = New-Object System.Windows.Forms.Button
    $MacCat.Location = New-Object System.Drawing.Size(325,65)
    $MacCat.Size = New-Object System.Drawing.Size(100,40)
    $MacCat.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $MacCat.Text = "List all Machine Catalogs"
    $MacCat.ForeColor = "White"
    $MacCat.BackColor = "#104277"
    $MacCat.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $MacCat.Add_Click({MacCat})
    $MacCat.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxTop.Controls.Add($MacCat)
        
                                # For debugging purpose
                    if ($debug -eq $True){
                    write-host "After List all Machine Catalogs - error found"
                    }

    #### List Published Application filtered by search word ###################################################################
    $FindPubAppByWord = New-Object System.Windows.Forms.Button
    $FindPubAppByWord.Location = New-Object System.Drawing.Size(535,20)
    $FindPubAppByWord.Size = New-Object System.Drawing.Size(100,40)
    $FindPubAppByWord.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $FindPubAppByWord.Text = "Find Published App by Word"
    $FindPubAppByWord.ForeColor = "White"
    $FindPubAppByWord.BackColor = "#104277"
    $FindPubAppByWord.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $FindPubAppByWord.Add_Click({FindPubAppByWord})
    $FindPubAppByWord.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxTop.Controls.Add($FindPubAppByWord)
        
                                # For debugging purpose
                    if ($debug -eq $True){
                    write-host "After Find Published App by Word - error found"
                    }
       
  
    #### OutPutBox Export TXT ###################################################################
    $ExportOutPutBox = New-Object System.Windows.Forms.Button
    $ExportOutPutBox.Location = New-Object System.Drawing.Size(10,65)
    $ExportOutPutBox.Size = New-Object System.Drawing.Size(100,40)
    $ExportOutPutBox.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $ExportOutPutBox.Text = "OutPut Box to TXT File"
    $ExportOutPutBox.ForeColor = "White"
    $ExportOutPutBox.BackColor = "#104277"
    $ExportOutPutBox.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $ExportOutPutBox.Add_Click({ExportOutPutBox})
    $ExportOutPutBox.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxOutFile.Controls.Add($ExportOutPutBox)
        
                                # For debugging purpose
                    if ($debug -eq $True){
                    write-host "After OutPut Box to TXT File - error found"
                    }

    #### Published Application Total Information from Studio List Out to  CSV/TXT ###################################################################
    $PARepCSV = New-Object System.Windows.Forms.Button
    $PARepCSV.Location = New-Object System.Drawing.Size(10,20)
    $PARepCSV.Size = New-Object System.Drawing.Size(100,40)
    $PARepCSV.Font = New-Object System.Drawing.Font("Calibri",7,[System.Drawing.FontStyle]::Bold)
    $PARepCSV.Text = "Published Application Report CSV/TXT"
    $PARepCSV.ForeColor = "White"
    $PARepCSV.BackColor = "#104277"
    $PARepCSV.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $PARepCSV.Add_Click({PARepCSV})
    $PARepCSV.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxOutFile.Controls.Add($PARepCSV)

    
        
                                # For debugging purpose
                    if ($debug -eq $True){
                    write-host "After Published Application Report CSV/TXT - error found"
                    }


    #### Citrix TAG List ###################################################################
    $VDITAGList = New-Object System.Windows.Forms.Button
    $VDITAGList.Location = New-Object System.Drawing.Size(220,65)
    $VDITAGList.Size = New-Object System.Drawing.Size(100,40)
    $VDITAGList.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDITAGList.Text = "TAG List"
    $VDITAGList.ForeColor = "White"
    $VDITAGList.BackColor = "#104277"
    $VDITAGList.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VDITAGList.Add_Click({VDITAGList})
    $VDITAGList.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxTop.Controls.Add($VDITAGList)


        
                                # For debugging purpose
                    if ($debug -eq $True){
                    write-host "After TAG List - error found"
                    }




    #### GroupBox Site #############################################################################



    #### Output Site Information ###################################################################
    $SiteInfo = New-Object System.Windows.Forms.Button
    $SiteInfo.Location = New-Object System.Drawing.Size(10,20)
    $SiteInfo.Size = New-Object System.Drawing.Size(100,40)
    $SiteInfo.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $SiteInfo.Text = "Site Info"
    $SiteInfo.ForeColor = "Red"
    $SiteInfo.BackColor = "White"
    $SiteInfo.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $SiteInfo.Add_Click({SiteInfo})
    $SiteInfo.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxSite.Controls.Add($SiteInfo)

    #### Output Site Information ###################################################################
    $ActiveSes = New-Object System.Windows.Forms.Button
    $ActiveSes.Location = New-Object System.Drawing.Size(10,65)
    $ActiveSes.Size = New-Object System.Drawing.Size(100,40)
    $ActiveSes.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $ActiveSes.Text = "Active Licenses"
    $ActiveSes.ForeColor = "Red"
    $ActiveSes.BackColor = "White"
    $ActiveSes.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $ActiveSes.Add_Click({ActiveSes})
    $ActiveSes.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxSite.Controls.Add($ActiveSes)

    #### ShutDown VDI By Name ###################################################################
    $VDIShutDown = New-Object System.Windows.Forms.Button
    $VDIShutDown.Location = New-Object System.Drawing.Size(110,20)
    $VDIShutDown.Size = New-Object System.Drawing.Size(100,40)
    $VDIShutDown.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIShutDown.Text = "ShutDown VDI"
    $VDIShutDown.ForeColor = "Red"
    $VDIShutDown.BackColor = "White"
    $VDIShutDown.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VDIShutDown.Add_Click({VDIShutDown})
    $VDIShutDown.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxSite.Controls.Add($VDIShutDown)

    #### ShutDown VDI By Name Automated ###################################################################
    $VDIShutDownActiveNoSession = New-Object System.Windows.Forms.Button
    $VDIShutDownActiveNoSession.Location = New-Object System.Drawing.Size(210,65)
    $VDIShutDownActiveNoSession.Size = New-Object System.Drawing.Size(100,40)
    $VDIShutDownActiveNoSession.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIShutDownActiveNoSession.Text = "ShutDown VDI Automated"
    $VDIShutDownActiveNoSession.ForeColor = "Red"
    $VDIShutDownActiveNoSession.BackColor = "White"
    $VDIShutDownActiveNoSession.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VDIShutDownActiveNoSession.Add_Click({VDIShutDownActiveNoSession})
    $VDIShutDownActiveNoSession.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxSite.Controls.Add($VDIShutDownActiveNoSession)
    
    #### Active Session VDI ###################################################################
    $VDIW10WAS = New-Object System.Windows.Forms.Button
    $VDIW10WAS.Location = New-Object System.Drawing.Size(110,65)
    $VDIW10WAS.Size = New-Object System.Drawing.Size(100,40)
    $VDIW10WAS.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIW10WAS.Text = "Virtual Desktop no Active Users"
    $VDIW10WAS.ForeColor = "Red"
    $VDIW10WAS.BackColor = "White"
    $VDIW10WAS.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VDIW10WAS.Add_Click({VDIW10WAS})
    $VDIW10WAS.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxSite.Controls.Add($VDIW10WAS)

    #### ShutDown VDI not rebooted for more than 30 days Automated ###################################################################
    $ShutDownVDIsRunning30days = New-Object System.Windows.Forms.Button
    $ShutDownVDIsRunning30days.Location = New-Object System.Drawing.Size(310,65)
    $ShutDownVDIsRunning30days.Size = New-Object System.Drawing.Size(100,40)
    $ShutDownVDIsRunning30days.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $ShutDownVDIsRunning30days.Text = "ShutDown VDI 30 Running days Automated"
    $ShutDownVDIsRunning30days.ForeColor = "Red"
    $ShutDownVDIsRunning30days.BackColor = "White"
    $ShutDownVDIsRunning30days.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $ShutDownVDIsRunning30days.Add_Click({ShutDownVDIsRunning30days})
    $ShutDownVDIsRunning30days.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxSite.Controls.Add($ShutDownVDIsRunning30days)

    #### Start VDI By Name ###################################################################
    $VDIStart = New-Object System.Windows.Forms.Button
    $VDIStart.Location = New-Object System.Drawing.Size(210,20)
    $VDIStart.Size = New-Object System.Drawing.Size(100,40)
    $VDIStart.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIStart.Text = "Start VDI"
    $VDIStart.ForeColor = "Red"
    $VDIStart.BackColor = "White"
    $VDIStart.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VDIStart.Add_Click({VDIStart})
    $VDIStart.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxSite.Controls.Add($VDIStart)

    #### Shutdown VDI from list ###################################################################
    $VDIShutDownList = New-Object System.Windows.Forms.Button
    $VDIShutDownList.Location = New-Object System.Drawing.Size(310,20)
    $VDIShutDownList.Size = New-Object System.Drawing.Size(100,40)
    $VDIShutDownList.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIShutDownList.Text = "Shutdown VDI from LIST"
    $VDIShutDownList.ForeColor = "Red"
    $VDIShutDownList.BackColor = "White"
    $VDIShutDownList.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VDIShutDownList.Add_Click({VDIShutDownList})
    $VDIShutDownList.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxSite.Controls.Add($VDIShutDownList)


    ### Group Box Sessions ##########################################################################

    #### UserSessions Information ###################################################################
    $CitrixUserSessions = New-Object System.Windows.Forms.Button
    $CitrixUserSessions.Location = New-Object System.Drawing.Size(10,20)
    $CitrixUserSessions.Size = New-Object System.Drawing.Size(100,40)
    $CitrixUserSessions.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $CitrixUserSessions.Text = "Users Sessions"
    $CitrixUserSessions.ForeColor = "Red"
    $CitrixUserSessions.BackColor = "White"
    $CitrixUserSessions.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $CitrixUserSessions.Add_Click({CitrixUserSessions})
    $CitrixUserSessions.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxSessions.Controls.Add($CitrixUserSessions)

    #### UserSessions Disconnected Information ###################################################################
    $CitrixUserSessionsDisc = New-Object System.Windows.Forms.Button
    $CitrixUserSessionsDisc.Location = New-Object System.Drawing.Size(10,65)
    $CitrixUserSessionsDisc.Size = New-Object System.Drawing.Size(100,40)
    $CitrixUserSessionsDisc.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $CitrixUserSessionsDisc.Text = "Users Sessions Disconnected"
    $CitrixUserSessionsDisc.ForeColor = "Red"
    $CitrixUserSessionsDisc.BackColor = "White"
    $CitrixUserSessionsDisc.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $CitrixUserSessionsDisc.Add_Click({CitrixUserSessionsDisc})
    $CitrixUserSessionsDisc.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxSessions.Controls.Add($CitrixUserSessionsDisc)

    #### ApplicationSessionsLgOff Sessions Log Off Information ###################################################################
    $ApplicationSessionsLgOff = New-Object System.Windows.Forms.Button
    $ApplicationSessionsLgOff.Location = New-Object System.Drawing.Size(110,20)
    $ApplicationSessionsLgOff.Size = New-Object System.Drawing.Size(100,40)
    $ApplicationSessionsLgOff.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $ApplicationSessionsLgOff.Text = "Applications Sessions LogOff"
    $ApplicationSessionsLgOff.ForeColor = "White"
    $ApplicationSessionsLgOff.BackColor = "#104277"
    $ApplicationSessionsLgOff.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $ApplicationSessionsLgOff.Add_Click({ApplicationSessionsLgOff})
    $ApplicationSessionsLgOff.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxSessions.Controls.Add($ApplicationSessionsLgOff)

    #### Application Sessions Log Off Information ###################################################################
    $ApplicationSessions = New-Object System.Windows.Forms.Button
    $ApplicationSessions.Location = New-Object System.Drawing.Size(110,65)
    $ApplicationSessions.Size = New-Object System.Drawing.Size(100,40)
    $ApplicationSessions.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $ApplicationSessions.Text = "Applications Sessions"
    $ApplicationSessions.ForeColor = "White"
    $ApplicationSessions.BackColor = "#104277"
    $ApplicationSessions.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $ApplicationSessions.Add_Click({ApplicationSessions})
    $ApplicationSessions.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxSessions.Controls.Add($ApplicationSessions)

    #### Virtual / Publioshed Application Enable button ###################################################################
    $VirtAppEnable = New-Object System.Windows.Forms.Button
    $VirtAppEnable.Location = New-Object System.Drawing.Size(370,65)
    $VirtAppEnable.Size = New-Object System.Drawing.Size(100,40)
    $VirtAppEnable.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VirtAppEnable.Text = "Enable Virtual Application"
    $VirtAppEnable.ForeColor = "White"
    $VirtAppEnable.BackColor = "#104277"
    $VirtAppEnable.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VirtAppEnable.Add_Click({VirtAppEnable})
    $VirtAppEnable.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxSessions.Controls.Add($VirtAppEnable)
 
    #### Virtual / Publioshed Application Disable button ###################################################################
    $VirtAppDisable = New-Object System.Windows.Forms.Button
    $VirtAppDisable.Location = New-Object System.Drawing.Size(470,65)
    $VirtAppDisable.Size = New-Object System.Drawing.Size(100,40)
    $VirtAppDisable.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VirtAppDisable.Text = "Disable Virtual Application"
    $VirtAppDisable.ForeColor = "White"
    $VirtAppDisable.BackColor = "#104277"
    $VirtAppDisable.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $VirtAppDisable.Add_Click({VirtAppDisable})
    $VirtAppDisable.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxSessions.Controls.Add($VirtAppDisable)
  
    #### Clear all fields #################################################################
    $ClearFields = New-Object System.Windows.Forms.Button
    $ClearFields.Location = New-Object System.Drawing.Size(10,20)
    $ClearFields.Size = New-Object System.Drawing.Size(115,40)
    $ClearFields.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $ClearFields.Text = "Clear All Fields"
    $ClearFields.ForeColor = "Black"
    $ClearFields.BackColor = "orange"
    $ClearFields.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $ClearFields.Add_Click({ClearFields})
    $ClearFields.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxTopCLEX.Controls.Add($ClearFields)
    
    #### Exit Button ###################################################################
    $exitButton = New-Object System.Windows.Forms.Button
    $exitButton.Location = New-Object System.Drawing.Size(130,20)
    $exitButton.Size = New-Object System.Drawing.Size(70,40)
    $exitButton.ForeColor = "White"
    $exitButton.BackColor = "red"
    $exitButton.Text = "Exit"
    $exitButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $exitButton.Cursor = [System.Windows.Forms.Cursors]::Hand
    $exitButton.add_Click({$Form.close()})
    $groupBoxTopCLEX.Controls.Add($exitButton)


    ######### GroupBoxXenServer ################################


    ######### END GroupBoxXenServer ################################



###################### END BUTTONS ######################################################



###################### INPUT BOX ########################################################
  #### Input window with "Input Value" Label ##########################################
    $InputBox = New-Object System.Windows.Forms.TextBox 
    $InputBox.Location = New-Object System.Drawing.Size(10,50) 
    $InputBox.Size = New-Object System.Drawing.Size(250,20) 
    $Form.Controls.Add($InputBox)
    $Label2InputBox = New-Object System.Windows.Forms.Label
    $Label2InputBox.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $Label2InputBox.ForeColor = "WHITE"
    $Label2InputBox.Text = "Initials | Days Running | Days Last Usage | TAG"
    $Label2InputBox.AutoSize = $True
    $Label2InputBox.Location = New-Object System.Drawing.Size(10,35) 
    $Form.Controls.Add($Label2InputBox)

  #### Input window with "SVDI Name" label ##########################################
    $InputBoxVDIName = New-Object System.Windows.Forms.TextBox 
    $InputBoxVDIName.Location = New-Object System.Drawing.Size(270,50) 
    $InputBoxVDIName.Size = New-Object System.Drawing.Size(150,20) 
    $Form.Controls.Add($InputBoxVDIName)
    $Label2InputBoxVDIName = New-Object System.Windows.Forms.Label
    $Label2InputBoxVDIName.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $Label2InputBoxVDIName.ForeColor = "WHITE"
    $Label2InputBoxVDIName.Text = "VDI | Published App"
    $Label2InputBoxVDIName.AutoSize = $True
    $Label2InputBoxVDIName.Location = New-Object System.Drawing.Size(270,35) 
    $Form.Controls.Add($Label2InputBoxVDIName)


###################### INPUT BOX END ########################################################

######################## OutPut Boxes ###################################################

    #### Output Box Field ###############################################################
    $outputBox = New-Object System.Windows.Forms.RichTextBox
    $outputBox.Location = New-Object System.Drawing.Size(250,130)
    $outputBox.Size = New-Object System.Drawing.Size(1345,420)
    $outputBox.Font = New-Object System.Drawing.Font("Consolas", 8 ,[System.Drawing.FontStyle]::Regular)
    $outputBox.MultiLine = $True
    $outputBox.ForeColor = "DarkBlue"
    $outputBox.BackColor = "White"
    $outputBox.ScrollBars = "Vertical"
    $outputBox.Text = " .........................."
    $Form.Controls.Add($outputBox)

    ##################################################
    

    #### Output Count Field ###############################################################
    $outputBoxCount = New-Object System.Windows.Forms.RichTextBox
    $outputBoxCount.Location = New-Object System.Drawing.Size(600,100)
    $outputBoxCount.Size = New-Object System.Drawing.Size(100,20)
    $outputBoxCount.Font = New-Object System.Drawing.Font("Consolas", 8 ,[System.Drawing.FontStyle]::Regular)
    $outputBoxCount.MultiLine = $True
    $outputBoxCount.ForeColor = "DarkBlue"
    $outputBoxCount.BackColor = "White"
    $outputBoxCount.ScrollBars = "Vertical"
    $outputBoxCount.Text = ""
    $Form.Controls.Add($outputBoxCount)

    ##############################################
    
######################## OutPut Boxes END #######################################################

    $Form.Add_Shown({$Form.Activate()})
    [void] $Form.ShowDialog()

