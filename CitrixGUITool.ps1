#####################################################################
#                   Citrix Information Tool                         #
#                Developped by : Brian L. Kruse                     #
#                  Contact: brian@leffler.dk                        #
#                                                                   #
#                                                                   #
#                  Creation Date: 24-11-2020                        #
#                   Last Update: 08-11-2023                         #
#                  Minor change to a variable                       #
#                                                                   #
#                                                                   #
#                                                                   #
#                        Version: 1                                 #
#                                                                   #
#  Purpose: A quick visual way to get Citrix related Information    #
#                                                                   #
#                                                                   #
#                                                                   #
#                                                                   #
#####################################################################

#region Default settings 

# Here to set the following information

$DomainName = "" # Example "domainName.com"
$DomainShort = "" # Example "domainName"
$DDC = "" # Name of one of the DeliverControllers "SERVDCP01"
$XenAppServerNameLike = "XenAppSilo" # You can type in part of the XenApp servername - example "XenAppSilo"
$VDINameLike = "*CitrixVDI*"# You can type in part of the VDI name - example "CitrixVDI"

#copy DesktopGroupName and match the DeliveryGroups you have in Citrix Studio
$DesktopGroupNameVDI = "VDIDesktopGroup01" # Example "VDIDesktopGroup01"

#AD Groups for getting access to VDI - write the AD Groupnames in " " and devided by , - Example 'XenAppVDI-Group01', 'XenAppVDI-Group02'
$AdGroups = 'XenAppVDI-Group01', 'XenAppVDI-Group02'

# Cloud sync on prem authentication
# Setting On-Prem validation - if these are marked with "#" you will need to validat using your Citrix Cloud account
Set-XDCredentials -ProfileTyp onPrem
Get-XDAuthentication

#endregion Default settings

#region SnapIns to be loaded

$snapinLicV1 = "Citrix.Licensing.Admin.V1"
$snapinAddedLicV1 = Get-PSSnapin | Select-String $snapinLicV1
if (!$snapinLicV1)
{
    Add-PSSnapin $snapinLicV1
}

$snapinNameC = "citrix*"
$snapinAdded = Get-PSSnapin | Select-String $snapinNameC
if (!$snapinNameC)
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

#endregion SnapIns to be loaded

#region functions
#################################################### Functions #######################################################

function VDIAssign{

#Function to find VDIs assigned to a specific user
                    
                    $outputBox.text = @()
                    $outputBox.text =  "Gathering User assigned to VDI info - Please wait...."  | Out-String
                    $VDIUser = $InputBox.text
                    $user = $InputBox.text
                    
                    #will gather all VDIs on the platform
                    $desktopsall = get-brokerdesktop -AdminAddress $DDC -MaxRecordCount 5000 | Select MachineName,AssociatedUserNames,LastConnectionTime,PowerState,SessionUserName,PublishedName,DesktopGroupName,Tags
                    
                        $machine = ''
                        $countvdi = 0

                        foreach ($desktops in $desktopsall) {
                                $AssociatedUserNamesTrimmed = $desktops.AssociatedUserNames -replace "$DomainShort\\", ""
                                
                                If ($AssociatedUserNamesTrimmed -eq $VDIUser) {
                                $machine += $desktops.machinename 
                                $ConTime = $desktops.LastConnectionTime | Out-String
                                
                                If ($desktops.machinename -like '*$XenAppServerNameLike*') {
                                    
                                $outputBox.AppendText("`n")
                                $outputBox.AppendText("`n")
                                $outputBox.Text += $VDIUser + " is assigned to Published Application on Silo " + $desktops.DesktopGroupName
                                $outputBox.AppendText("`n")
                                
                                }
                                Else {
                                $outputBox.AppendText("`n")
                                $outputBox.AppendText("`n")
                                $outputBox.Text += $VDIUser + " is assigned to " + $desktops.machinename + " with TAG (" + $desktops.Tags + ")"  + " VDI " + " - The VDI is Powered: " + $desktops.powerstate + "     -    " + "The VDI was last logged on: " + $desktops.LastConnectionTime
                                $outputBox.AppendText("`n")
                                $outputBox.AppendText("`n")
                                $countvdi += 1
                                
                                }
                           }
                           } 
                           
                            foreach ($group in $AdGroups) {
                                $members = Get-ADGroupMember -Identity $group -Recursive | Select -ExpandProperty SamAccountName
                    
                        If ($machine) {
                            $outputBox.AppendText("`n")
                                                        
                            If ($members -contains $user) {
                                  $outputBox.Text += "$user is member of AD Group:  $group "
                                  $outputBox.AppendText("`n")
                             } Else {
                                    $outputBox.AppendText("`n")
                                    $outputBox.Text += "$user is NOT member of AD Group:  $group "
                            }


                        } Else {
                            $outputBox.AppendText("`n")
                            $outputBox.Text += $VDIUser + " is not assigned to a desktop "
                            $countvdi = 0
                            $outputBox.AppendText("`n")
                                                        
                            If ($members -contains $user) {
                                  $outputBox.AppendText("`n")
                                  $outputBox.Text += "$user is member of AD Group:  $group "
                                  $outputBox.AppendText("`n")
                                  $outputBox.AppendText("`n")
                                  $outputBox.AppendText("-----------000-------------")
                                  $outputBox.AppendText("`n")
                                  $outputBox.AppendText("`n")
                             } Else {
                                  $outputBox.AppendText("`n")
                                  $outputBox.Text += "$user is NOT member of AD Group :  $group "
                            }

                             }

                        }
                            $outputBox.AppendText("`n")
                            $outputBox.AppendText("`n")
                            $outputBox.AppendText("-----------000-------------")
                            $outputBoxCount.Text = $countvdi
}

function VDIUserAssign{

# Find users assigned to a specific VDI                    
                    
                    $outputBox.text =  "Gathering User assigned to VDI - Please wait...."  | Out-String
                    $objStatusBar.Text = "Gathering User assigned to VDI - Please wait...."
                    $VDIName = $InputBox.text
                   
                    
                    $desktops = get-brokerdesktop -AdminAddress $DDC -MaxRecordCount 5000 | Select MachineName,AssociatedUserNames, SessionUserName, PowerState

                        $AssociatedUser = ''

                        

                        
                        foreach ($desktop in $desktops) {

                            If ($desktop.MachineName -like "*$VDIName*") { 
                                
                                If ($desktop.SessionUserName -eq $false){
                                    $SessionUserName = " No Active User "
                                    }

                                    Else{
                                    $SessionUserName = $desktop.SessionUserName
                                    }
                        
                                    $VDIUserName = $desktop.AssociatedUserNames
                                $outputBox.Text = $VDIName + " is assigned to " + $SessionUserName +  " and active sessionUser is:  " + $SessionUserName + " And the VDI is currently is powered: " + $desktop.PowerState
                                break
                            }
                        }
                        
                    $objStatusBar.Text = "Gathering User assigned to VDI - Please wait...."
}

function VDISTDUnassigned{

# VDIs unassigned on the platform                   
                
                    $outputBox.text =  "Gathering List of unassigned VDI's on the platform - Please wait...."  | Out-String
                    $vmcount = 0
                    $VMList = Get-BrokerDesktop -adminaddress $DDC -MaxRecordCount 5000 -Filter {DesktopGroupName -eq $DesktopGroupNameVDI} -IsAssigned $false | Select-Object MachineName,Tags,AssociatedUserNames,PowerState                  
                    $outputBox.Text = "Unassigned VDIs in DeliveryGroup: " + $DesktopGroupNameVDI
                    $outputBox.AppendText("`n")
                    $outputBox.Text += $VMList | FT | Out-String

                    Foreach ($vm in $VMList) {
                        $vmcount +=1
                        }

                    If (!$VMList){
                        $outputBox.Text = "There are no Unassigned VDIs in the Windows 10 Workspace VDI POOL"

                    }
                    $objStatusBar.Text = "Unassigned VDI list presented ...."
                    $outputBoxCount.Text = $vmcount
}

function VDISpecInfo{

# Getting specifications and informations about a specific VDI

                    $VDIName = $InputBox.text 
                    $Dom = "$DomainShort\"                    
                    $VDIFullName = $Dom + $VDIName                   
                
                    $outputBox.text =  "Gathering VDI info - Please wait...."  | Out-String
                   

                    $VDI = Get-BrokerMachine -MachineName $VDIFullName -adminaddress $ddc

                     Foreach ($vm in $VMList) {
                        [PSCustomObject]@{    
                            Server = $vm.MachineName
                            "Last Connection time" = $vm.LastConnectionTime
                            "Maint Mode" = $vm.InMaintenanceMode
                            User = $vm.AssociatedUserNames
                          "PowerState" = $vm.PowerState
                          }
                        $vmcount +=1
                        
 
                    }
                    $outputBox.Text = "Specifications and Information for VDI: " + $VDIName
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "---------------------------------------------------------------------"
                    $outputBox.AppendText("`n")
                    $outputBox.Text += $VDI | Out-String
                    $outputBoxCount.Text = $vmcount
}

function DelGrp{

# Listing all avaiable Delivery Groups from Citrix Studio                    
                
                    $outputBox.text =  "Gathering Citrix Delivery Groups info - Please wait...."  | Out-String
                    $Groups = Get-BrokerDesktopGroup -adminaddress $DDC -MaxRecordCount 5000 | Select Name
                     Foreach ($group in $groups) {

                        [PSCustomObject]@{    
                            PublishedName = $group.PublishedName
                            
                          }
                        $vmcount +=1
                        
 
                    }
                    $outputBox.Text = "Listing all Delivery Groups on the platform"
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "---------------------------------------------------------------------"
                    $outputBox.AppendText("`n")                  
                    $outputBox.Text += $Groups | FT | Out-String
                    $outputBoxCount.Text = $vmcount
}

function MacCat{

# Listing all Machine Catalogs from Citrix Studio
                    
                
                    $outputBox.text =  "Gathering Citrix Machine Catalogs info - Please wait...."  | Out-String
                    $Groups = Get-BrokerCatalog -adminaddress $DDC -MaxRecordCount 5000 | Select Name
                    
                    Foreach ($group in $groups) {
                    
                    $vmcount +=1
                      
                    }
                    $outputBox.Text = "Listing all Machine Catalogss on the platform"
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "---------------------------------------------------------------------"
                    $outputBox.AppendText("`n")                     
                    $outputBox.Text += $Groups | FT | Out-String
                    $outputBoxCount.Text = $vmcount
}

function VDIListTotal{

# List total list of VDIs for the DekstopGroupName $DesktopGroupNameVDI                     
                
                    $outputBox.text =  "Gathering All VDI list - Please wait...."  | Out-String

                    $BrokerDesktops = Get-BrokerDesktop -adminaddress $DDC -MaxRecordCount 10000 -Filter {MachineName -like $VDINameLike} | Select-Object -Property MachineName,SessionState,SessionUserName,DesktopGroupName,PowerState,AssociatedUserNames,LastConnectionTime | sort MachineName | FT -AutoSize 

                    Foreach ($vm in $BrokerDesktops) {

                            [PSCustomObject]@{    
                                Server = $vm.MachineName
                                "Last Connection time" = $vm.LastConnectionTime
                                "Maint Mode" = $vm.InMaintenanceMode
                                User = $vm.AssociatedUserNames 
                                "PowerState" = $vm.PowerState
                              }
                        }

                    $CountBrokerDesktops = Get-BrokerDesktop -adminaddress $DDC -MaxRecordCount 10000 
                     Foreach ($vm in $CountBrokerDesktops) {
                     
                    #Count total number of VDI Standard
                        $vmcount +=1
                     }
                   
                    #$outputBox.Text = $VMList | FT | Out-String
                     $outputBox.Text = "Listing all VDIs with AssociatedUSer, SessionState, DesktopGroupName, SessionUserName, Powerstate, AssociatedUserName and LastConnectionTime"
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "---------------------------------------------------------------------"
                    $outputBox.AppendText("`n")   
                    $outputBox.Text += $BrokerDesktops | FT | Out-String
                    $outputBoxCount.Text = $vmcount
}
              
function VDIAS{

# List total list of VDIs and show the active state                       
                
                    $outputBox.text =  "Gathering VDI Active State info List - without UserSessions - Please wait...."  | Out-String
                    $BrokerDesktops = Get-BrokerDesktop -adminaddress $DDC -MaxRecordCount 10000 -Filter {MachineName -like $VDINameLike -and SessionState -eq $null -and PowerState -eq 'on'} | Select-Object -Property MachineName,StartTime,LastConnectionTime,LastConnectionUser,DesktopGroupName,SessionState,SessionUserName,PowerState | Sort-Object DesktopGroupName,MachineName | FT -AutoSize

                    $vmcount = 0
                    
                    $CountBrokerDesktops = Get-BrokerDesktop -adminaddress $DDC -MaxRecordCount 10000 -Filter {MachineName -like $VDINameLike -and SessionState -eq $null -and PowerState -eq 'on'} | Select-Object -Property MachineName,StartTime,LastConnectionTime,LastConnectionUser,DesktopGroupName,SessionState,SessionUserName,PowerState | Sort-Object MachineName | FT -AutoSize

                     Foreach ($vm in $CountBrokerDesktops) {
                     
                     #Count total number of VDI Standard
                        $vmcount +=1
                     }
                   

                    if ($CountBrokerDesktops -eq $NULL){
                        $outputBox.Text += "There are no VDIs without active User Session powered on"
                        }
                    Else{
                        $outputBox.Text += $CountBrokerDesktops | FT | Out-String
                        }
                    $outputBoxCount.Text = $CountBrokerDesktops.Count
}

function VDIListNameOnly{

                    
# Lists all VDI names on the platform
                
                    $outputBox.text =  "Gathering VDI Names List - Please wait...."  | Out-String

                    $VMListTotal = Get-BrokerDesktop -adminaddress $DDC -MaxRecordCount 5000 -filter {DesktopGroupUid -ne $null} | where MachineName -like $VDINameLike | Select-Object -Property MachineName,CatalogName,PowerState,Tags,AssociatedUserNames | Sort-Object CatalogName, MachineName
                    
                    #Count of VDIs for each Machine Catalog/Delivery Group - copy line and change the "catalog name" and the variable you need to save it under
                    $VDI = Get-BrokerMachine -adminaddress $DDC -MaxRecordCount 5000 -Filter {CatalogName -eq $DesktopGroupNameVDI} | Select-Object -Property MachineName,AssociatedUserNames

                 
                    
                    
                    $outputBox.Text = "This is the current total VDI list for each Delivery Group / Machine Catalog"
                    $outputBox.AppendText("`n")
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "---------------------------------------------------------------------"
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "VDI count for the different Delivery Groups / Machine Catalogs:"
                    $outputBox.AppendText("`n")
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "Total amount of VDIs on the platform       " + $VDI.count
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "---------------------------------------------------------------------"
                    $outputBox.AppendText("`n")
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "Below are the VDIs listed"
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "---------------------------------------------------------------------"
                    $outputBox.AppendText("`n")
                    $outputBox.Text += $VMListTotal | FT | Out-String
                    $outputBoxCount.Text = $VMListTotal.count
                    

                    $CountVDI = $VMListTotal.count
}
              
function VDITAG{

# Find VDIs by specific TAG - and output to GRID-VIEW also

                    $vmcount = 0

                    # Input the TAG name you know
                    $Tag_to_Search = $InputBox.text

                    
                    $Members_of_Tag = Get-BrokerDesktop -AdminAddress $DDC -Tag $Tag_to_Search -MaxRecordCount 100000 | Select HostedMachineName, Tags

                    foreach ($Member in $Members_of_Tag) {

                            $vmcount +=1
                            }

                    # If there are no members of the tag it will send output to console otherwise it will send an out-gridview
                    If ($null -eq $Members_of_Tag){
                        
                        $outputBox.Text = "No members of the selected TAG: " + $Tag_to_Search
                        
                    }
                    Else{
                        $outputBox.Text = $Members_of_Tag | FT | Out-String
                        $Members_of_Tag | Out-GridView -Title "Members of selected Tag"
                    }
                    
                    $outputBoxCount.Text = $vmcount
}

function VDITAGList{
                    
# Lists all TAGs added in Citrix Studio

                    $TagList = Get-BrokerTag -AdminAddress $DDC | Select Name | FT 

                    $outputBox.Text = $TagList | FT | Out-String
}

function VDIShutDown{

# Shuts down a specific VDI by name

                $VDIMachineName = $InputBox.text 
                
                $VDIName = "$DomainShort\" + $VDIMachineName

                New-BrokerHostingPowerAction -adminaddress $DDC -Action Shutdown -MachineName $VDIName -ActualPriority 1

                $outputBox.Text = "Shutting down VDI: " + $VDIMachineName
                $objStatusBar.Text =  "Shutting down VDI: " + $VDIMachineName
}

function VDIShutDownActiveNoSession{

# Shuts down all running VDIs that have no running or disconnected sessions

                    $outputBox.text =  "Shutting down Powered On VDI without Active userSessions - Please wait...."  | Out-String
                    $vmcount =0
                    $objStatusBar.Text = @()

                    # Create c:\temp folder if it does not exist
                    $path = "C:\temp\"
    
                        If (!(test-path $path))
                        {
                            md $path
                        }
                    
                    
                    $VDIMachinesActiveCount = Get-BrokerDesktop -adminaddress $DDC -MaxRecordCount 5000 -Filter {MachineName -like $VDINameLike -and SessionState -eq $null -and PowerState -eq 'on'} | Select-Object -Property MachineName,LastConnectionTime,LastConnectionUser,DesktopGroupName,SessionState,SessionUserName,PowerState | Select-Object MachineName | ft -AutoSize
                    $VDIMachinesActive = Get-BrokerDesktop -adminaddress $DDC -MaxRecordCount 5000 -Filter {MachineName -like $VDINameLike -and SessionState -eq $null -and PowerState -eq 'on'} | Select-Object -Property MachineName,LastConnectionTime,LastConnectionUser,DesktopGroupName,SessionState,SessionUserName,PowerState | Select-Object MachineName | Out-String 


                    #List VDIs that are shutdown into TXT file
                    $VDIMachines = ($VDIMachinesActive -replace('.$DomainName','') -replace('DNSName','') -replace('------- ','') | Out-String).Trim() | Out-File -FilePath c:\temp\VDIListAutoShutDown.txt
                    
                    

                    $Content = Get-Content c:\temp\VDIListAutoShutDown.txt
                    $content[2..($content.length-1)]|Out-File c:\temp\VDIListAutoShutDown.txt -Force
                    
                    $VDIS = Get-Content c:\temp\VDIListAutoShutDown.txt
                    
                     foreach ($vdi in $VDIS) {
                     
                         New-BrokerHostingPowerAction -Action Shutdown -MachineName $vdi

                         $outputBox.AppendText("`n")
                         $outputBox.Text += "Shutting down VDI: " + $vdi
                         $outputBox.AppendText("`n")
                         $outputBox.Text += "VDIs has now been signaled to ShutDown"
                         #$outputBox.AppendText("`n")
                         $objStatusBar.Text +=  "Shutting down VDI: " + $vdi
                         $vmcount +=1
                         

                     }
                   
                    $outputBoxCount.Text = $VDIMachinesActiveCount.count
}

function VDIStart{

# Start a specific VDI

                $VDIMachineName = $InputBox.text 
                
                $VDIName = "$DomainShort\" + $VDIMachineName
                                              
                New-BrokerHostingPowerAction -adminaddress $DDC -Action TurnOn -MachineName $VDIName

                $outputBox.Text = "Starting up VDI: " + $VDIMachineName
                $objStatusBar.Text =  "Starting up VDI: " + $VDIMachineName

}

function VDIShutDownTXTList{

# Shutdown VDI from TXT file list

                $VDIName = @()
                $FilePath = $InputBox.text 

                $VDIMachines = Get-Content $FilePath

                foreach ($machine in $VDIMachines) {
                     
                     $VDIName = "$DomainShort\" + $machine 

                     New-BrokerHostingPowerAction -adminaddress $DDC -Action Shutdown -MachineName $VDIName -ActualPriority 1


                     $outputBox.AppendText("`n")
                     $outputBox.Text += "Shutting down VDI: " + $machine
                     $outputBox.AppendText("`n")
                     $outputBox.AppendText("`n")
                     $objStatusBar.Text +=  "Shutting down VDI: " + $machine + " --- "

                     }
}

function VDIAddUser{

# Add a specific User to the specific VDI

                    $Username = $InputBox.Text
                    $VDIName = $InputBoxVDIName.Text

                    $outputBox.text =  "Adding user: " + $Username + " to the VDI: " + $VDIName + "- Please wait...."  | Out-String
                    $objStatusBar.Text = "Adding user: " + $Username + " to the VDI: " + $VDIName + "- Please wait...."


                    #Add Domain to username
                    $FinalUserName = "$DomainShort\" + $Username

                    #Add Domain to VDI name
                    $FinalVDIName = "$DomainShort\" + $VDIName
                    
                    add-BrokerUser $FinalUserName -Machine $FinalVDIName

                    $outputBox.text =  "User: " + $FinalUserName + " added to: " + $FinalVDIName  | Out-String
                    $objStatusBar.Text = "User: " + $FinalUserName + " added to: " + $FinalVDIName
                   
                    
}

function VDIRemoveUser{

# Remove a specific User from the specific VDI

                    
                
                    $outputBox.text =  "Removing user from the VDI - Please wait...."  | Out-String
                    $objStatusBar.Text = "Removing user from the VDI - Please wait...."

                    $Username = $InputBox.Text
                    $VDIName = $InputBoxVDIName.Text

                    #Add Domain to username
                    $FinalUserName = "$DomainShort\" + $Username

                    #Add Domain to VDI name
                    $FinalVDIName = "$DomainShort\" + $VDIName
                    
                    Remove-BrokerUser $FinalUserName -Machine $FinalVDIName

                    $outputBox.text =  "User: " + $FinalUserName + " removed from: " + $FinalVDIName  | Out-String
                    $objStatusBar.Text = "User: " + $FinalUserName + " removed from: " + $FinalVDIName
                   
                    
}

function AddUserPA{

# Add a specific User to a Published Application

                    
                
                    $outputBox.text =  "Adding USER to a specific Published Application - Please wait...."  | Out-String
                    $objStatusBar.Text = "Adding USER to a specific Published Application - Please wait...."

                    $Username = $InputBox.Text
                    $PublishedApplication = $InputBoxVDIName.Text

                    #Add Domain to username
                    $FinalUserName = "$DomainShort\" + $Username

                    Add-BrokerUser $FinalUserName -Application $PublishedApplication

                    $outputBox.text =  "User: " + $FinalUserName + " is added to application: " + $PublishedApplication  | Out-String
                    $objStatusBar.Text = "User: " + $FinalUserName + " is added to application: " + $PublishedApplication
                   
                    
}

function PARepCSV{

# This function deliveres Published Applications with all information to CSV and TXT files


# Input only the filename without extension
$FileName = $InputBox.Text

## Create total list incl all information to CSV
Get-BrokerApplication -AdminAddress DKCDCCTXDCP01.vestas.net -MaxRecordCount 100000 | Select AdminFolderName,@{l="AdminFolderUid";e={$_.AdminFolderUid -join ","}},@{l="AllAssociatedDesktopGroupUUIDs";e={$_.AllAssociatedDesktopGroupUUIDs -join ","}},@{l="AllAssociatedDesktopGroupUids";e={$_.AllAssociatedDesktopGroupUids -join ","}},ApplicationName,ApplicationType,@{l="AssociatedApplicationGroupUUIDs";e={$_.AssociatedApplicationGroupUUIDs -join ","}},@{l="AssociatedApplicationGroupUids";e={$_.AssociatedApplicationGroupUids -join ","}},@{l="AssociatedDesktopGroupPriorities";e={$_.AssociatedDesktopGroupPriorities -join ","}},@{l="AssociatedDesktopGroupUUIDs";e={$_.AssociatedDesktopGroupUUIDs -join ","}},@{l="AssociatedDesktopGroupUids";e={$_.AssociatedDesktopGroupUids -join ","}},@{l="AssociatedUserFullNames";e={$_.AssociatedUserFullNames -join ","}},@{l="AssociatedUserNames";e={$_.AssociatedUserNames -join ","}},@{l="AssociatedUserSIDs";e={$_.AssociatedUserSIDs -join ","}},@{l="AssociatedUserUPNs";e={$_.AssociatedUserUPNs -join ","}},BrowserName,ClientFolder,CommandLineArguments,CommandLineExecutable,@{l="ConfigurationSlotUids";e={$_.ConfigurationSlotUids -join ","}},CpuPriorityLevel,Description,Enabled,HomeZoneName,HomeZoneOnly,HomeZoneUid,IconFromClient,IconUid,IgnoreUserHomeZone,LocalLaunchDisabled,@{l="MachineConfigurationNames";e={$_.MachineConfigurationNames -join ","}},@{l="MachineConfigurationUids";e={$_.MachineConfigurationUids -join ","}},MaxPerMachineInstances,MaxPerUserInstances,MaxTotalInstances,@{l="MetadataKeys";e={$_.MetadataKeys -join ","}},@{l="MetadataMap";e={$_.MetadataMap -join ","}},Name,PublishedName,SecureCmdLineArgumentsEnabled,ShortcutAddedToDesktop,ShortcutAddedToStartMenu,StartMenuFolder,@{l="Tags";e={$_.Tags -join ","}},UUID,Uid,UserFilterEnabled,Visible,WaitForPrinterCreation,WorkingDirectory | Export-Csv -Path ("c:\temp\" + $FileName + "_Report.csv")  -NoTypeInformation

## Create total list incl all information to TXT
Get-BrokerApplication -AdminAddress DKCDCCTXDCP01.vestas.net -MaxRecordCount 100000 | Select AdminFolderName,@{l="AdminFolderUid";e={$_.AdminFolderUid -join ","}},@{l="AllAssociatedDesktopGroupUUIDs";e={$_.AllAssociatedDesktopGroupUUIDs -join ","}},@{l="AllAssociatedDesktopGroupUids";e={$_.AllAssociatedDesktopGroupUids -join ","}},ApplicationName,ApplicationType,@{l="AssociatedApplicationGroupUUIDs";e={$_.AssociatedApplicationGroupUUIDs -join ","}},@{l="AssociatedApplicationGroupUids";e={$_.AssociatedApplicationGroupUids -join ","}},@{l="AssociatedDesktopGroupPriorities";e={$_.AssociatedDesktopGroupPriorities -join ","}},@{l="AssociatedDesktopGroupUUIDs";e={$_.AssociatedDesktopGroupUUIDs -join ","}},@{l="AssociatedDesktopGroupUids";e={$_.AssociatedDesktopGroupUids -join ","}},@{l="AssociatedUserFullNames";e={$_.AssociatedUserFullNames -join ","}},@{l="AssociatedUserNames";e={$_.AssociatedUserNames -join ","}},@{l="AssociatedUserSIDs";e={$_.AssociatedUserSIDs -join ","}},@{l="AssociatedUserUPNs";e={$_.AssociatedUserUPNs -join ","}},BrowserName,ClientFolder,CommandLineArguments,CommandLineExecutable,@{l="ConfigurationSlotUids";e={$_.ConfigurationSlotUids -join ","}},CpuPriorityLevel,Description,Enabled,HomeZoneName,HomeZoneOnly,HomeZoneUid,IconFromClient,IconUid,IgnoreUserHomeZone,LocalLaunchDisabled,@{l="MachineConfigurationNames";e={$_.MachineConfigurationNames -join ","}},@{l="MachineConfigurationUids";e={$_.MachineConfigurationUids -join ","}},MaxPerMachineInstances,MaxPerUserInstances,MaxTotalInstances,@{l="MetadataKeys";e={$_.MetadataKeys -join ","}},@{l="MetadataMap";e={$_.MetadataMap -join ","}},Name,PublishedName,SecureCmdLineArgumentsEnabled,ShortcutAddedToDesktop,ShortcutAddedToStartMenu,StartMenuFolder,@{l="Tags";e={$_.Tags -join ","}},UUID,Uid,UserFilterEnabled,Visible,WaitForPrinterCreation,WorkingDirectory | Out-file -FilePath ("c:\temp\" + $FileName + "_Report.txt")

## Create total list incl all information to EXCEL
Get-BrokerApplication -AdminAddress DKCDCCTXDCP01.vestas.net -MaxRecordCount 100000 | Select AdminFolderName,@{l="AdminFolderUid";e={$_.AdminFolderUid -join ","}},@{l="AllAssociatedDesktopGroupUUIDs";e={$_.AllAssociatedDesktopGroupUUIDs -join ","}},@{l="AllAssociatedDesktopGroupUids";e={$_.AllAssociatedDesktopGroupUids -join ","}},ApplicationName,ApplicationType,@{l="AssociatedApplicationGroupUUIDs";e={$_.AssociatedApplicationGroupUUIDs -join ","}},@{l="AssociatedApplicationGroupUids";e={$_.AssociatedApplicationGroupUids -join ","}},@{l="AssociatedDesktopGroupPriorities";e={$_.AssociatedDesktopGroupPriorities -join ","}},@{l="AssociatedDesktopGroupUUIDs";e={$_.AssociatedDesktopGroupUUIDs -join ","}},@{l="AssociatedDesktopGroupUids";e={$_.AssociatedDesktopGroupUids -join ","}},@{l="AssociatedUserFullNames";e={$_.AssociatedUserFullNames -join ","}},@{l="AssociatedUserNames";e={$_.AssociatedUserNames -join ","}},@{l="AssociatedUserSIDs";e={$_.AssociatedUserSIDs -join ","}},@{l="AssociatedUserUPNs";e={$_.AssociatedUserUPNs -join ","}},BrowserName,ClientFolder,CommandLineArguments,CommandLineExecutable,@{l="ConfigurationSlotUids";e={$_.ConfigurationSlotUids -join ","}},CpuPriorityLevel,Description,Enabled,HomeZoneName,HomeZoneOnly,HomeZoneUid,IconFromClient,IconUid,IgnoreUserHomeZone,LocalLaunchDisabled,@{l="MachineConfigurationNames";e={$_.MachineConfigurationNames -join ","}},@{l="MachineConfigurationUids";e={$_.MachineConfigurationUids -join ","}},MaxPerMachineInstances,MaxPerUserInstances,MaxTotalInstances,@{l="MetadataKeys";e={$_.MetadataKeys -join ","}},@{l="MetadataMap";e={$_.MetadataMap -join ","}},Name,PublishedName,SecureCmdLineArgumentsEnabled,ShortcutAddedToDesktop,ShortcutAddedToStartMenu,StartMenuFolder,@{l="Tags";e={$_.Tags -join ","}},UUID,Uid,UserFilterEnabled,Visible,WaitForPrinterCreation,WorkingDirectory | Export-Excel -path ("c:\temp\" + $FileName + "_Report.xlsx") -worksheetname "$FileName" -TableStyle Medium16 -AutoSize

$outputBox.text = "Total Published Applications list with all information delivered to C:\temp folder on your C-drive"

}

function ExportOutPutBox{
              
# Grabs the current information in the "OutPutBoxt.text" windows an laces it into a TXT file
# Input only the filename without extension              
              
              $FileName = $InputBox.Text
                
              $outputBox.text | Out-file -FilePath ("c:\temp\" + $FileName + "_Report.txt")
                
}

function ExportOutPutBoxToXLSX{
              
# Grabs the current information in the "OutPutBoxt.text" windows an laces it into a XLSX file
# Input only the filename without extension              
                                       
              $FileName = $InputBox.Text

              $ToExcel = $outputBox.txt
              
              $ToExcel | ConvertFrom-String
              $ToExcel | Export-Excel -path ("c:\temp\" + $FileName + "_Report.xlsx") -worksheetname "$FileName" -TableStyle Medium16
                
}
              
function VCPApps{

# This just list all Published applications by name and also make count to present how many Publiahed Applications the Platform has published                   
                
                    $outputBox.text =  "Gathering Published Applications info - Please wait...."  | Out-String

                    $PACount = 0

                    $PublishedApps = Get-Brokerapplication -adminaddress $DDC -MaxRecordCount 10000 | Select-Object ApplicationName,AdminFolderName | FT -AutoSize  | Out-String
                                        
                    $PACN = Get-Brokerapplication -adminaddress $DDC -MaxRecordCount 10000 | Select-Object Name

                    Foreach($PApp in $PACN){
                        $PACount += 1
                    }

                    $outputBox.Text = $PublishedApps
                    $outputBoxCount.Text = $PACount
                    
                  }                  

function CitrixPubAppsFindContain{

# Find specific Citrix Published Application containing a specific word

                    $Contain = $InputBox.Text

                    $Contain2 = "*" + $contain + "*" #| Out-String
                
                    $outputBox.text =  "Gathering Published Applications containing" +  $Contain + "  - Please wait...."  | Out-String

                    $PACount = 0

                    $PublishedApps = Get-Brokerapplication -adminaddress $DDC -MaxRecordCount 10000 -name $Contain2 | Select-Object ApplicationName,AdminFolderName  | FT -AutoSize | Out-String 

                    #counting the numbers of Published Applications found
                    $PACount = Get-Brokerapplication -adminaddress $DDC -MaxRecordCount 10000 -name $Contain2
  
                    $outputBox.Text += $PublishedApps
                    $outputBoxCount.Text = $PACount.count      
                  }                  

function AppUsage{

# Show the current access Published Applications and how many instances currently running                   
                
                    $outputBox.text =  "Gathering Published Applications info - Please wait...."  | Out-String
                    $objStatusBar.Text = "Gathering Published Applications info - Please wait...."
                    
                    $PublishedApps = Get-BrokerApplicationInstance -adminaddress $DDC -MaxRecordCount 10000 | group-Object -Property ApplicationName | sort-object -property Count -Descending | Format-Table -AutoSize -Property Name,Count
                    
                    $outputBox.Text = $PublishedApps | FT | Out-String          
                                        
                  }                  

function Scopes{

# Show scopes in Citrix Studio                    
                
                    $outputBox.text =  "Gathering SCOPES info - Please wait...."  | Out-String
                    $objStatusBar.Text = "Gathering SCOPES info - Please wait...."
                    
                    $AllScopes = Get-AdminScope -adminaddress $DDC | FT | Out-String
                    
                    $outputBox.AppendText("`n")
                    $outputBox.Text = "The following SCOPES are available in Citirx Studio" | Out-String
                    $outputBox.AppendText("`n")
                    $outputBox.Text += $AllScopes

                    $objStatusBar.Text = "SCOPES info presented - Please wait...."
                        
                }
                       
function LastUsageVDI{

# Check for last login to the VDI - enter number of days in the "inputbox"
                    
                    $outputBoxCount.Text = @()
                    $outputBox.text =  "Gathering information on last usage of VDIs - Please wait...."  | Out-String
                    
                    # Grabs the number of days entered for when it should check for the last login
                    $DaysSinceLastLogon = $InputBox.text
                    $d = (get-date).AddDays(-$DaysSinceLastLogon)
                    $DesktopGroupwrk = $DesktopGroupNameVDI
                    $PowerMgmgtTag = "NoPowerMgmt"
                    $vmcount = 0


                    # VDI Delivery Group
                    $VMList1 = Get-BrokerDesktop -AdminAddress "$DDC" -DesktopGroupName "$DesktopGroupwrk" -MaxRecordCount 10000 -Filter {LastConnectionTime -le $d } | Select-Object MachineName,Tags,LastConnectionTime,AssociatedUserNames | Sort-Object LastConnectionTime

                    # Count the number of VDIs in that Delivery Group
                    $VMListCount = Get-BrokerDesktop -AdminAddress "$DDC" -DesktopGroupName "$DesktopGroupwrk" -MaxRecordCount 10000 -Filter {LastConnectionTime -le $d } 




                    $STDVDICount = "Number of VDIs not logged into for the last " + $DaysSinceLastLogon + " days is:  ",$VMListCount.count 

                    $outputBox.Text = "VDI that has not been used for the last " + $DaysSinceLastLogon + " days"
                    $outputBox.AppendText("`n") 
                    $outputBox.Text += $VMList1 | FT | Out-String  
                    $outputBox.AppendText("`n") 
                    $outputBox.Text += $STDVDICount
                    $outputBox.AppendText("`n") 
                    $outputBox.AppendText("`n") 
                    $outputBox.Text += "------------------------------------------------------------"
                    $outputBox.AppendText("`n") 

                  $outputBoxCount.Text = $VMListCount.count 
                  }   

function VDAver{

# Getting VDA version of all VDIs, Remote PC, XenApp servers
                
                    $outputBox.text =  "Gathering VDA Versions info - Please wait...."  | Out-String
                    $objStatusBar.Text = "Gathering VDA Versions info - Please wait...."
                    $vmcountList = 0

                    $VMList1 = Get-BrokerDesktop -AdminAddress "$DDC" -MaxRecordCount 10000 | Select-Object MachineName,AgentVersion,AssociatedUserNames | Sort-Object MachineName | FT | Out-String
                    
                    $VMListCount = Get-BrokerDesktop -AdminAddress "$DDC" -MaxRecordCount 10000

                    Foreach ($vm in $VMList1) {
                     $expfile = $vm.MachineName +","+ $vm.AgentVersion +","+ $vm.AssociatedUserNames
                          [PSCustomObject]@{    
                            Server = $vm.MachineName
                            "AgentVersion" = $vm.AgentVersion
                            User = $vm.AssociatedUserNames 
                           
                          } 
                          $vmcountList +=1
                        
                        }

                    $outputBoxCount.Text = $VMListCount.count

                    $outputBox.AppendText("`n")
                    $outputBox.Text = "These are the VDA versions running in the farm" | Out-String
                    $outputBox.AppendText("`n")
                    $outputBox.Text += $VMList1 | FT | Out-String

                    $objStatusBar.Text = "VDA Versions presented"
                  }                  

function VDIStatus{

# To provide power status of all VDIs
                
                    $outputBox.text =  "Gathering VDI Powerstate info - Please wait...."  | Out-String
                    $objStatusBar.Text = "Gathering VDI Powerstate info - Please wait...."
                    $vmcountList = 0

                    $VMList1 = Get-BrokerDesktop -AdminAddress "$DDC" -MaxRecordCount 10000 | Select-Object MachineName,powerstate,SessionState,SessionUserName | Sort-Object powerstate | FT | Out-String
                    
                    Foreach ($vm in $VMList1) {
                     $expfile = $vm.MachineName +","+ $vm.powerstate +","+ $vm.AssociatedUserNames
                          [PSCustomObject]@{    
                            Server = $vm.MachineName
                            "Powerstate" = $vm.powerstate
                            User = $vm.AssociatedUserNames 
                            
                    }
                    
                    $off = Select-String -InputObject $VMList1 -Pattern "Off" -AllMatches
                    
                    $on = Select-String -InputObject $VMList1 -Pattern "On" -AllMatches
                    
                    $unmanaged  = Select-String -InputObject $VMList1 -Pattern "Unmanaged" -AllMatches
                    
                    $unknown  = Select-String -InputObject $VMList1 -Pattern "Unknown" -AllMatches
                   
                    $vmcountList += $off.Matches.Count + $on.Matches.Count + $unmanaged.Matches.Count + $unknown.Matches.Count
                    
                    }
                    
                    
                    $outputBoxCount.Text = $vmcountList

                       
                    $outputBox.Text = " Total Powered OFF:    ", $off.Matches.Count
                    $outputBox.AppendText("`n")
                    $outputBox.Text += " Total Powered ON:     ", $on.Matches.Count
                    $outputBox.AppendText("`n")
                    $outputBox.Text += " Total Unmanaged:      ", $unmanaged.Matches.Count
                    $outputBox.AppendText("`n")
                    $outputBox.Text += " Total Unknown:        ", $unknown.Matches.Count
                    $outputBox.AppendText("`n")
                    $outputBox.Text += $VMList1 | FT | Out-String

                    $objStatusBar.Text = "VDI Powerstate presented"
                    
                 }             

function SiteInfo{

# Overall Site information from Citrix Studio

                    $outputBox.text =  "Gathering Site info from Citrix Studio - Please wait...."  | Out-String
                    $objStatusBar.Text = "Gathering Site info from Citrix Studio - Please wait...."
                    $vmcountList = 0

                    $SiteInfoTotal = Get-BrokerSite -AdminAddress "$DDC" | Out-String
                    $XenAppVer = Get-BrokerController | Select-Object DNSName,State,ControllerVersion
                    
                    
                    $outputBox.Text = "_____________Total XenDesktop Site Information_____________"
                    $outputBox.AppendText("`n")
                    $outputBox.Text += $SiteInfoTotal | Out-String
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "_____________Citrix Delivery Controller Version___________________________"
                    $outputBox.AppendText("`n")
                    $outputBox.Text += $XenAppVer | Out-String

                    $objStatusBar.Text = "Site Info presented"
                  }                  

function ActiveSes{

# Show active licenses currently in use and the total licenses

                    $outputBox.text =  "Gathering Active Licenses - Please wait...."  | Out-String
                    $objStatusBar.Text = "Gathering Active Licenses - Please wait...."
                    $vmcountList = 0

                    $ActiveSessions = Get-BrokerSite -AdminAddress "$DDC"
                    
                    $outputBox.Text = "This show the different licens information for the site " + $ActiveSessions.Name | Out-String
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "Total active license usage          :  " + $ActiveSessions.LicensedSessionsActive | Out-String
                    $outputBox.AppendText("`n")
                    #$outputBox.AppendText("`n")
                    $outputBox.Text += "Total number of unique licenses     :  " + $ActiveSessions.TotalUniqueLicenseUsers
                    $outputBox.AppendText("`n")
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "Licensemodel                        :  " + $ActiveSessions.LicenseModel
                    $outputBox.AppendText("`n")
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "License Server                      :  " + $ActiveSessions.LicenseServerName
                    $outputBox.AppendText("`n")
                    $outputBox.AppendText("`n")
                    $outputBox.Text += "Peak Concurrent Licenses            :  " + $ActiveSessions.PeakConcurrentLicenseUsers
                    $outputBox.AppendText("`n")
                    $outputBox.AppendText("`n")
                    $objStatusBar.Text = "Active Licenses presented"
                  }                  

function VDIAP{

# Shows the local admin password of a specific VDI
                    
                    $VDIMachineName = $InputBox.text 
                
                    $VDIName = "$DomainShort\" + $VDIMachineName
                    $outputBox.text =  "Gathering ADM Pass - Please wait...."  | Out-String
                    $objStatusBar.Text = "Gathering ADM Pass - Please wait...."
                    $vmcountList = 0

                    $AP = get-adcomputer $VDI -Properties ms-Mcs-AdmPwd | Select-Object ms-Mcs-AdmPwd
                    
                    $outputBox.Text = $AP | Out-String

                    $objStatusBar.Text = "ADM Pass presented"
                  }                  

function VDIRunningDays{

# Check for VDI that has not been rebooted and enter the number of days since you want to check from

                    $DaysSinceLastLogon = $InputBox.text
                    $Today = Get-Date -Format "MM/dd/yyyy HH:mm"
                    $daysince = (get-date).AddDays(-$DaysSinceLastLogon) 
                    $VDIRunD = @()
                    $outputBox.Text = @()

                    #Getting the VDIs
                    $Desktops = Get-BrokerDesktop -AdminAddress "$DDC" -DesktopGroupName "$DesktopGroupNameVDI" -MaxRecordCount 5000 -Filter {PowerState -eq 'On' -and StartTime -le $daysince} | Select-Object MachineName,SessionState,PowerState,LastConnectionTime,StartTime,@{Label='Duration'; Expression={(Get-Date) - $_.StartTime}}, AssociatedUserNames | Sort-Object StartTime
                    
                    $outputBox.AppendText("`n")
                    $outputBox.Text = "The following VDIs has been running for more than " + $DaysSinceLastLogon + " days"
                    $outputBox.AppendText("`n")

                    foreach($Desktop in $Desktops) {

                                $Today = Get-Date
                                $d = $Desktop.StartTime
                                $x = New-TimeSpan -Start $d -End $Today

                                $outputBox.MultiLine = $True  
                                $outputBox.AppendText("`n")            
                                $outputBox.Text += $Desktop.MachineName + " has been running for : " + $x.Days + " days" + " - The VDI is powered: " + $Desktop.PowerState + " and State is: " + $Desktop.SessionState + " and last connected: " + $Desktop.LastConnectionTime + " - and assigned User is: " + $Desktop.AssociatedUserNames
                                $outputBox.SelectionColor = 'red'
                                $outputBox.AppendText("`n") 

                    } 
                    
                    $outputBoxCount.Text = $Desktops.count
                    
}

function VDIAddTag{

# Add a TAG to a VDI - use the TAG LIST function to get the list with TAG names
# TAG name in the InputBox and the VDI name in the VDINameBox

                    $VDIname = $InputBoxVDIName.Text
                    $VDI = "$DomainShort\" + $VDIname
                    $VDITag = $InputBox.text

                    $outputBox.text =  "Adding TAG: " + $VDITag + " to VDI: " + $VDI  | Out-String
                    $objStatusBar.Text = "Adding TAG: " + $VDITag + " to VDI: " + $VDI 
                    $vmcountList = 0

                    Add-BrokerTag -AdminAddress $DDC -Name $VDITag -Machine $VDI
                    
                    
                    $outputBox.Text = "VDI " + $VDI + " Tagged with :" + $VDITag | Out-String

                    $objStatusBar.Text = "VDI Tagged"
                  }                  

function VDIRemoveTagFromVDI{

# Removes TAG from a specific VDI

                    $VDI = $InputBoxVDIName.Text
                    $domain = "$DomainShort\"
                    $VDITag = $InputBox.text
                                      
                    $outputBox.text =  "Removing TAG: " + $VDITag + " to VDI: " + $VDI  | Out-String
                    $objStatusBar.Text = "Removing TAG: " + $VDITag + " to VDI: " + $VDI 
                    $vmcountList = 0

                    Remove-BrokerTag -Name $VDITag -Machine $domain\$VDI
                    
                    
                    $outputBox.Text = "VDI " + $VDI + " Removed Tag:" + $VDITag | Out-String

                    $objStatusBar.Text = "VDI Tag Removed"
                  }                  

function VDIRemoveTag{
                    
# Removes/deletews a TAG in Citrix Studio
                    
                    $VDITag = $InputBox.text
                    
                    $outputBox.text =  "Removing TAG: " + $VDITag   | Out-String
                    $objStatusBar.Text = "Removing TAG: " + $VDITag 
                    $vmcountList = 0

                    Remove-BrokerTag -Name $VDITag
                    
                    
                    $outputBox.Text = "Tag : " + $VDITag + " has been removed from Citrix Studio" | Out-String

                    $objStatusBar.Text = "TAG removed from Citrix Studio"
                  }                  

function VDICreateTag{

# Creates a TAG in Citrix Studio                    
                    
                    $VDITag = $InputBox.text
                    
                    $outputBox.text =  "Creating New VDI TAG: " + $VDITag   | Out-String
                    $objStatusBar.Text = "Creating New VDI TAG: " + $VDITag 
                    $vmcountList = 0

                    New-BrokerTag -Name $VDITag
                    
                    
                    $outputBox.Text = "New Tag : " + $VDITag + " Created" | Out-String

                    $objStatusBar.Text = "New TAG created in Citrix Studio"
                  }                  

function CitrixUserSessions {
           
# Show a USERS active sessions                   
                    
                    $User = $InputBox.text
                    
                    $UserName = "$DomainShort\" + $User
                    $UserSessions = Get-BrokerSession -adminaddress $DDC -UserName $UserName -Filter { SessionState -eq 'Active' }| Select LaunchedViaPublishedName, ApplicationsInUse, SessionState, AppState, EstablishmentTime | FT

                    $outputBox.text = "The user: " + $user + " has the following sessions running"
                    $outputBox.AppendText("`n") 
                    $outputBox.AppendText("`n") 
                    $outputBox.text += "----------------------------------------------------------"
                    $outputBox.AppendText("`n") 
                    $outputBox.text += $UserSessions | Out-String
                    $outputBox.AppendText("`n") 
                    $outputBox.AppendText("`n") 
                    $outputBox.text += "-------------------END OF LIST---------------------------------------"
                    
                    $objStatusBar.Text = "Sessions for " + $User + " listed..."
                  }                  

function CitrixUserSessionsDisc {
                   
# Shows a USERS diesconencted sessions
                    
                    $User = $InputBox.text
                    $UserName = "$DomainShort\" + $User
                    $DisconnectedSessions = Get-BrokerSession -adminaddress $DDC -MaxRecordCount 5000 -UserName $UserName -Filter { SessionState -eq 'Disconnected' } | Select-Object LaunchedViaPublishedName, ApplicationsInUse, SessionState, AppState, EstablishmentTime | FT

                    $outputBox.text = "The user: " + $user + " has the following disconnected sessions running"
                    $outputBox.AppendText("`n") 
                    $outputBox.AppendText("`n") 
                    $outputBox.text += "----------------------------------------------------------"
                    $outputBox.AppendText("`n") 
                    $outputBox.text += $DisconnectedSessions   | Out-String
                    $outputBox.AppendText("`n") 
                    $outputBox.AppendText("`n") 
                    $outputBox.text += "-------------------END OF LIST---------------------------------------"
                                 
                    $objStatusBar.Text = "Sessions for " + $User + " listed..."
                  }                  

function ShowPubAppAssociatedUserNames {

# Shows associated users and AD groups for a specific Published Application selected from the DropDown list

                    $PubName = $listBoxPubApps.SelectedItem

                    $PublishedAppsInfo = Get-Brokerapplication -MaxRecordCount 10000 -Name $PubName | Select AssociatedUserNames

                    foreach ($user in $PublishedAppsInfo){

                            $userlist += $PublishedAppsInfo.AssociatedUserNames
                    }
                    # removes the domain name from the username
                    $comlist = $userlist -replace "$DomainShort\","" | sort



                    $PublishedAppsInfo.Length
                    
                    $outputBox.text = "User list for Published Application: " + $PubName
                    $outputBox.AppendText("`n")
                    $outputBox.text += "--------------------------------------------------------------------------------------"
                    $outputBox.AppendText("`n")
                    $outputBox.text += $comlist | Out-String 
                    
                    
                   
                    #$outputBox.text += $runtime
                  
                      

                      $outputBoxCount.Text = $comlist.count
                    $objStatusBar.Text = "Users who ha the app published: " + $PubName + " shown"
                  }                  

function ShowDeliveryGroupInfo {

# Shows DeliveryGroup information selected from the DropDown list
                    
                    $outputBox.text = @()

                    $PubName = $listBoxPubApps.SelectedItem
                    
                    $DeliveryGroupsInfo = Get-BrokerDesktopGroup -MaxRecordCount 10000 -Name $PubName
              
                    $outputBox.text = "Information for Delivery Group: " + $PubName
                    $outputBox.AppendText("`n")
                    $outputBox.text += "--------------------------------------------------------------------------------------"
                    $outputBox.AppendText("`n")
                    $outputBox.text += $DeliveryGroupsInfo | Out-String 
  
                    $objStatusBar.Text = "Information about the Delivery Group: " + $PubName + " shown"
                  }                  

function ShowPubApp {

# Show information on Published Application selected from the DropDown list

                    $PubName = $listBoxPubApps.SelectedItem
                   
                    $PublishedAppsInfo = Get-Brokerapplication -MaxRecordCount 10000 -Name $PubName
                    $outputBox.text = $PublishedAppsInfo   | Out-String
                    $objStatusBar.Text = "Info about published app: " + $PubName + " shown"
                  }                  

function ShowMachineCat {

# Show information on Machine Catalog selected from the DropDown list

                    $MachineCatName = $listBoxPubApps.SelectedItem

                    $MachineCat =Get-BrokerCatalog -adminaddress $DDC -Name $MachineCatName 
                    $outputBox.text = "Information for Machine Catalog: " + $MachineCatName
                    $outputBox.AppendText("`n")
                    $outputBox.text += "--------------------------------------------------------------------------------------"
                    $outputBox.AppendText("`n")
                    $outputBox.text += $MachineCat   | Out-String
                    $objStatusBar.Text = "Info about Machine Catalog: " + $MachineCatName + " shown"
                  }                  

function ShowUsagePubApp {

# Show the usage of the selected Published Application

                    $PubName = $listBoxPubApps.SelectedItem
                    

                    # Finds all sessions of the chosen Published Application in $listBoxPubApps.SelectedItem
                    $PublishedAppsInfo = Get-BrokerSession -adminaddress $DDC -MaxRecordCount 50000 | Where-Object ApplicationsInUse -eq $PubName | Select-Object Username,SessionState,ApplicationsInUse
                    
                    
                    if ($PublishedAppsInfo -eq $NULL){
                        $outputBox.text = "There are no running apps on:  " + $PubName
                        }
                    Else{

                    
                    $outputBox.text = $PublishedAppsInfo   | Out-String
                    }
                    
                    $objStatusBar.Text = "Info about published app: " + $PubName + " shown"

                    $outputBoxCount.Text = $PublishedAppsInfo.Count
                        
                      
                  }                

function ShowXenAppSessions {

# Show XenApp session for a specific XenApp Server

                    $XenAppServer = $listBoxPubApps.SelectedItem
                    

                    # Finds all sessions of the chosen Published Application in $listBoxPubApps.SelectedItem
                    $XenAppServerSessions = Get-BrokerSession -adminaddress $DDC -MaxRecordCount 5000 -DNSName $XenAppServer| Select-Object UserName,DNSName,@{Name='ApplicationsInUse';Expression={[string]::join(“;”, ($_.ApplicationsInUse))}},SessionState,SessionType | FT 
                    
                    if ($XenAppServerSessions -eq $NULL){
                        $outputBox.text = "There are no running Sessions on:  " + $XenAppServer
                        }
                    Else{

                    $outputBox.text = $XenAppServerSessions   | Out-String
                    }
                    
                    $objStatusBar.Text = "Sessions running on: " + $XenAppServer + " shown"

                    $outputBoxCount.Text = $XenAppServerSessions.Count
                        
                  }                

function ShowAllXenAppDisconnectedSessions {

# Show all Disconnected XenApp sessions for a specific XenApp server for all Published Applications

                    # Finds all sessions of the chosen Published Application in $listBoxPubApps.SelectedItem
                    $XenAppServerDisconnectedSessions = Get-BrokerSession -adminaddress $DDC -MaxRecordCount 50000 | Where-Object SessionState -Like "Disconnected"|  Select-Object UserName,DNSName,@{Name='ApplicationsInUse';Expression={[string]::join(“;”, ($_.ApplicationsInUse))}},SessionState,SessionType | Sort-Object SessionType | FT
                    
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


function Clearfields{
  
 # Clears all fileds for text
           
            $InputBox.text = @()
            $outputBox.text = @()
            $outputBoxCount.Text = @()
            $UserNameTxtBx.Text = @()
            $InputBoxVDIName.Text = @()
            $objStatusBar.Text = @()
                       
            }

        #endregion Functions

#region GUI creation

    #### Form settings #################################################################
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")  

    # GUI size creation
    $Form = New-Object System.Windows.Forms.Form
    $Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle #modifies the window border
    $Form.Text = "....."    
    $Form.Size = New-Object System.Drawing.Size(1620,950)  
    $Form.StartPosition = "CenterScreen" #loads the window in the center of the screen
    $Form.BackgroundImageLayout = "Zoom"
    $Form.MinimizeBox = $True
    $Form.MaximizeBox = $True
    $Form.ForeColor = "#104277"
    $Form.BackColor = "DARKGRAY"
    $Form.SizeGripStyle = "Hide"
    $Icon = [system.drawing.icon]::ExtractAssociatedIcon($PSHOME + "\powershell.exe")
    $Form.Icon = $Icon
    
    # form status bar  
    $objStatusBar = New-Object System.Windows.Forms.StatusBar
    $objStatusBar.Name = "statusBar"
    $objStatusBar.Text = "Ready"
    $Form.Controls.Add($objStatusBar)

    # Title - Powershell GUI Tool
    $LabelTitle = New-Object System.Windows.Forms.Label
    $LabelFontTitle = New-Object System.Drawing.Font("Calibri",24,[System.Drawing.FontStyle]::Bold)
    $LabelTitle.Font = $LabelFontTitle
    $LabelTitle.ForeColor = "White"
    $LabelTitle.Text = "Citrix GUI Tool"
    $LabelTitle.AutoSize = $True
    $LabelTitle.Location = New-Object System.Drawing.Size(520,5) 
    $Form.Controls.Add($LabelTitle)

    # Version - Powershell GUI Tool
    $LabelVersion = New-Object System.Windows.Forms.Label
    $LabelFontVersion = New-Object System.Drawing.Font("Calibri",14,[System.Drawing.FontStyle]::Bold)
    $LabelVersion.Font = $LabelFontVersion
    $LabelVersion.ForeColor = "White"
    $LabelVersion.Text = "Version: 1 - updated 06-06-2023"
    $LabelVersion.AutoSize = $True
    $LabelVersion.Location = New-Object System.Drawing.Size(520,45) 
    $Form.Controls.Add($LabelVersion)

    # Creator - Powershell GUI Tool
    $LabelCreator = New-Object System.Windows.Forms.Label
    $LabelFontCreator = New-Object System.Drawing.Font("Calibri",10,[System.Drawing.FontStyle]::Bold)
    $LabelCreator.Font = $LabelFontCreator
    $LabelCreator.ForeColor = "White"
    #$LabelCreator.ForeColor = "#104277"
    $LabelCreator.Text = "Created by: Brian Leffler Kruse - brian@leffler.dk"
    $LabelCreator.AutoSize = $True
    $LabelCreator.Location = New-Object System.Drawing.Size(520,70) 
    $Form.Controls.Add($LabelCreator)


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

#endregion GUI creation

#region Group Boxes

    # Group boxes for buttons
    $groupBox = New-Object System.Windows.Forms.GroupBox
    $groupBox.Location = New-Object System.Drawing.Size(10,90) 
    $groupBox.Font = New-Object System.Drawing.Font("Calibri",10,[System.Drawing.FontStyle]::Bold)
    $groupBox.size = New-Object System.Drawing.Size(230,620)
    $groupBox.ForeColor = "white"
    $groupBox.text = "VDI Information" 
    $Form.Controls.Add($groupBox) 

    # Group boxes for VDI Assignment
    $groupBoxVDI = New-Object System.Windows.Forms.GroupBox
    $groupBoxVDI.Location = New-Object System.Drawing.Size(10,720) 
    $groupBoxVDI.Font = New-Object System.Drawing.Font("Calibri",10,[System.Drawing.FontStyle]::Bold)
    $groupBoxVDI.size = New-Object System.Drawing.Size(230,170)
    $groupBoxVDI.ForeColor = "white"
    $groupBoxVDI.text = "VDI Assignment" 
    $Form.Controls.Add($groupBoxVDI) 


    # Group boxes for buttons on top of OutPutBox APPS related
    $groupBoxTop = New-Object System.Windows.Forms.GroupBox
    $groupBoxTop.Location = New-Object System.Drawing.Size(1020,15) 
    $groupBoxTop.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $groupBoxTop.size = New-Object System.Drawing.Size(430,110)
    $groupBoxTop.ForeColor = "white"
    $groupBoxTop.text = "Apps / VDI - Usage Menu" 
    $Form.Controls.Add($groupBoxTop) 

    # Group boxes for Clear and Exit buttons on top of OutPutBox
    $groupBoxTopCLEX = New-Object System.Windows.Forms.GroupBox
    $groupBoxTopCLEX.Location = New-Object System.Drawing.Size(1460,15) 
    $groupBoxTopCLEX.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $groupBoxTopCLEX.size = New-Object System.Drawing.Size(150,110)
    $groupBoxTopCLEX.ForeColor = "white"
    $groupBoxTopCLEX.text = "Clear Fields / Exit" 
    $Form.Controls.Add($groupBoxTopCLEX) 

    # Group boxes for buttons on top of OutPutBox XenServer related
    $groupBoxBottom = New-Object System.Windows.Forms.GroupBox
    $groupBoxBottom.Location = New-Object System.Drawing.Size(250,550) 
    $groupBoxBottom.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $groupBoxBottom.size = New-Object System.Drawing.Size(800,160)
    $groupBoxBottom.ForeColor = "white"
    $groupBoxBottom.text = "VDI Options" 
    $Form.Controls.Add($groupBoxBottom) 

    # Group boxes for Citrix Studio Buttons
    $groupBoxCiStu = New-Object System.Windows.Forms.GroupBox
    $groupBoxCiStu.Location = New-Object System.Drawing.Size(250,720) 
    $groupBoxCiStu.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $groupBoxCiStu.size = New-Object System.Drawing.Size(800,170)
    $groupBoxCiStu.ForeColor = "white"
    $groupBoxCiStu.text = "Citrix Studio" 
    $Form.Controls.Add($groupBoxCiStu) 

    # Group boxes for Citrix Site related
    $groupBoxSite = New-Object System.Windows.Forms.GroupBox
    $groupBoxSite.Location = New-Object System.Drawing.Size(1060,550) 
    $groupBoxSite.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $groupBoxSite.size = New-Object System.Drawing.Size(430,110)
    $groupBoxSite.ForeColor = "white"
    $groupBoxSite.text = "Site Menu" 
    $Form.Controls.Add($groupBoxSite) 

    # Group boxes for Sessions related
    $groupBoxSessions = New-Object System.Windows.Forms.GroupBox
    $groupBoxSessions.Location = New-Object System.Drawing.Size(1060,665) 
    $groupBoxSessions.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $groupBoxSessions.size = New-Object System.Drawing.Size(430,110)
    $groupBoxSessions.ForeColor = "white"
    $groupBoxSessions.text = "Sessions Menu" 
    $Form.Controls.Add($groupBoxSessions) 

    # Group boxes for Print / Out-File related
    $groupBoxOutFile = New-Object System.Windows.Forms.GroupBox
    $groupBoxOutFile.Location = New-Object System.Drawing.Size(1060,780) 
    $groupBoxOutFile.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $groupBoxOutFile.size = New-Object System.Drawing.Size(200,110)
    $groupBoxOutFile.ForeColor = "white"
    $groupBoxOutFile.text = "Report Options" 
    $Form.Controls.Add($groupBoxOutFile) 

#endregion Group Boxes

#region VDI assignment 
################# VDI Assignment tool #############

#username label
$Label = New-Object System.Windows.Forms.Label 
$Label.Text = "Users Initials:" 
$Label.AutoSize = $true 
$Label.Location = New-Object System.Drawing.Size(10, 25) 
$Font = New-Object System.Drawing.Font("Calibri", 8, [System.Drawing.FontStyle]::Bold) 
$groupBoxVDI.Controls.Add($Label)

#Variables#
$CtxSrvtxtbx = $DDC
$DomainNametxtbx = $DomainName

#username text box
$UserNameTxtBx = New-Object System.Windows.Forms.TextBox
$UserNameTxtBx.Location = New-Object System.Drawing.Point(110, 25)
$UserNameTxtBx.Size = New-Object System.Drawing.Size(100, 50)
$groupBoxVDI.Controls.Add($UserNameTxtBx)

#list delivery group published names
$listBox = new-object System.Windows.Forms.ComboBox
$listBox.Location = New-Object System.Drawing.Point(10, 90)
$listBox.Size = New-Object System.Drawing.Size(200, 22)
$groupBoxVDI.controls.Add($listBox)

#List Delivery group
$GetVDIGrps = New-Object System.Windows.Forms.Button 
$GetVDIGrps.Location = New-Object System.Drawing.Size(10, 55) 
$GetVDIGrps.Size = New-Object System.Drawing.Size(130, 30) 
$GetVDIGrps.Text = "Get VDI Groups" 
$GetVDIGrps.ForeColor = "White"
$GetVDIGrps.BackColor = "#104277"
$GetVDIGrps.Cursor = [System.Windows.Forms.Cursors]::Hand
$GetVDIGrps.Add_Click( {
        if (!($CtxSrvtxtbx)) {
            Add-Type -AssemblyName "System.Windows.Forms"
            [System.Windows.Forms.MessageBox]::Show('Please enter citrix delivery controller name and try again', 'Empty Value', 'Ok', 'Hand')
        }
        else {
            $listbox.Items.Clear()
            $citrixServer = $CtxSrvtxtbx
            $VDIlist = (Get-BrokerDesktopGroup -adminaddress $citrixServer).Name
            foreach ($dgpubName in $VDIlist) {
                $listbox.Items.Add($dgpubName)
            }
        }
    }) 
$groupBoxVDI.Controls.Add($GetVDIGrps)

#assignVDI button
$assignVDI = New-Object System.Windows.Forms.Button 
$assignVDI.Location = New-Object System.Drawing.Size(10, 120) 
$assignVDI.Size = New-Object System.Drawing.Size(100, 40) 
$assignVDI.Font = New-Object System.Drawing.Font("Calibri",10,[System.Drawing.FontStyle]::Bold)
$assignVDI.Text = "Assign VDI" 
$assignVDI.ForeColor = "White"
$assignVDI.BackColor = "#104277"
$assignVDI.Cursor = [System.Windows.Forms.Cursors]::Hand
$assignVDI.Add_Click( {

        $DomainNameValue = $DomainNametxtbx
        $userNameValue = $UserNameTxtBx.Text
        $ctxsrvnamevalue = $CtxSrvtxtbx

        if ($DomainNameValue -like "*.*") {
            $DomainNameValue = $DomainNameValue.Split('.')[0]
        }

        $dgdisname = $listbox.SelectedItem

        #List all delivery groups.
        $dgname = Get-BrokerDesktopGroup -Name $dgdisname -AdminAddress $ctxsrvnamevalue
        $VDIname = (Get-BrokerDesktop -DesktopGroupName $dgname.Name -adminaddress $ctxsrvnamevalue -MaxRecordCount 2000000 | Where-Object { !($_.AssociatedUserNames) }).DNSName
        if (!$VDIname) {
            #Add-Type -AssemblyName PresentationFramework
            Add-Type -AssemblyName "System.Windows.Forms"
            [System.Windows.Forms.MessageBox]::Show('There are no Free VDIs in the pool', 'Free VDI issue', 'Ok', 'Hand')
        }
        else {
              $vdicount = Get-BrokerMachine -AssociatedUserName $DomainNameValue\$userNameValue -AdminAddress $ctxsrvnamevalue
              if (($vdicount)) {
              Add-Type -AssemblyName "System.Windows.Forms"
                $result = [System.Windows.Forms.MessageBox]::Show('User already has a VDI. Do you wish to proceed?', 'VDI already exists', 'YesNo', 'Question')
                  if ($result -ne "No") {
                   $hostname = $VDIname.Split('.')[0]
                   Add-BrokerUser "$DomainNameValue\$usernamevalue" -PrivateDesktop "$DomainNameValue\$hostname" -AdminAddress $ctxsrvnamevalue
                   #Add-Type -AssemblyName PresentationFramework
                   Add-Type -AssemblyName "System.Windows.Forms"
                   [System.Windows.Forms.MessageBox]::Show('VDI ' + "$hostname" + ' assigned successfully.', 'VDI assigned', 'Ok', 'Asterisk')
                  }
              }
              else {
                   $hostname = $VDIname.Split('.')[0]
                   Add-BrokerUser "$DomainNameValue\$usernamevalue" -PrivateDesktop "$DomainNameValue\$hostname" -AdminAddress $ctxsrvnamevalue
                   #Add-Type -AssemblyName PresentationFramework
                   Add-Type -AssemblyName "System.Windows.Forms"
                   [System.Windows.Forms.MessageBox]::Show('VDI ' + $hostname + ' for ' + $userNameValue + ' assigned successfully.', 'VDI assigned', 'Ok', 'Asterisk')
            }
        } $outputBox.Text = $hostname + " is assigned to: " + $userNameValue | FT | Out-String
 
    }) 
$groupBoxVDI.Controls.Add($assignVDI)

#unassignVDI button
$unassignVDI = New-Object System.Windows.Forms.Button 
$unassignVDI.Location = New-Object System.Drawing.Size(110, 120) 
$unassignVDI.Size = New-Object System.Drawing.Size(100, 40) 
$unassignVDI.Text = "Unassign VDI" 
$unassignVDI.ForeColor = "White"
$unassignVDI.BackColor = "#104277"
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
            #Add-Type -AssemblyName PresentationFramework
            Add-Type -AssemblyName "System.Windows.Forms"
        [System.Windows.Forms.MessageBox]::Show('VDI unassigned successfully.', 'VDI unassigned', 'Ok', 'Asterisk')
    }) 
   
    

$groupBoxVDI.Controls.Add($unassignVDI)

#endregion VDI assignment 

#region Buttons

    # List all assigned Windows 10 Workspace
    $VDIListTotal = New-Object System.Windows.Forms.Button
    $VDIListTotal.Location = New-Object System.Drawing.Size(15,25)
    $VDIListTotal.Size = New-Object System.Drawing.Size(100,40)
    $VDIListTotal.Font = New-Object System.Drawing.Font("Calibri",10,[System.Drawing.FontStyle]::Bold)
    $VDIListTotal.Text = "Total VDI List"
    $VDIListTotal.ForeColor = "White"
    $VDIListTotal.BackColor = "#104277"
    $VDIListTotal.Add_Click({VDIListTotal})
    $VDIListTotal.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($VDIListTotal)

    # Template for button
    $ButtonTemplate = New-Object System.Windows.Forms.Button
    $ButtonTemplate.Location = New-Object System.Drawing.Size(115,25)
    $ButtonTemplate.Size = New-Object System.Drawing.Size(100,40)
    $ButtonTemplate.Font = New-Object System.Drawing.Font("Calibri",10,[System.Drawing.FontStyle]::Bold)
    $ButtonTemplate.Text = "Button Template"
    $ButtonTemplate.ForeColor = "White"
    $ButtonTemplate.BackColor = "#104277"
    $ButtonTemplate.Add_Click({ButtonTemplate})
    $ButtonTemplate.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($ButtonTemplate)

    # Line Break Vertical
    $LineBreak = New-Object System.Windows.Forms.Button
    $LineBreak.Location = New-Object System.Drawing.Size(15,207)
    $LineBreak.Size = New-Object System.Drawing.Size(200,5)
    $LineBreak.Font = New-Object System.Drawing.Font("Calibri",10,[System.Drawing.FontStyle]::Bold)
    $LineBreak.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $LineBreak.FlatAppearance.BorderSize = 3
    $LineBreak.FlatAppearance.BorderColor = [System.Drawing.Color]::"WHITE"
    $LineBreak.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($LineBreak)

    # List all Citrix VDI Unassigned
    $VDISTDUnassigned = New-Object System.Windows.Forms.Button
    $VDISTDUnassigned.Location = New-Object System.Drawing.Size(15,220)
    $VDISTDUnassigned.Size = New-Object System.Drawing.Size(100,40)
    $VDISTDUnassigned.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDISTDUnassigned.Text = "VDI Unassigned"
    $VDISTDUnassigned.ForeColor = "#104277"
    $VDISTDUnassigned.BackColor = "White"
    $VDISTDUnassigned.Add_Click({VDISTDUnassigned})
    $VDISTDUnassigned.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($VDISTDUnassigned)

    # Button Template 2
    $ButtonTemplate2 = New-Object System.Windows.Forms.Button
    $ButtonTemplate2.Location = New-Object System.Drawing.Size(115,220)
    $ButtonTemplate2.Size = New-Object System.Drawing.Size(100,40)
    $ButtonTemplate2.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $ButtonTemplate2.Text = "Button Template 2"
    $ButtonTemplate2.ForeColor = "#104277"
    $ButtonTemplate2.BackColor = "White"
    $ButtonTemplate2.Add_Click({ButtonTemplate2})
    $ButtonTemplate2.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($ButtonTemplate2)
    
    # List all Citrix VDI Usage - logged on since XX days
    $LastUsageVDI = New-Object System.Windows.Forms.Button
    $LastUsageVDI.Location = New-Object System.Drawing.Size(115,400)
    $LastUsageVDI.Size = New-Object System.Drawing.Size(100,40)
    $LastUsageVDI.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $LastUsageVDI.Text = "Last Usage VDI Enter days in inputbox"
    $LastUsageVDI.ForeColor = "White"
    $LastUsageVDI.BackColor = "Green"
    $LastUsageVDI.Add_Click({LastUsageVDI})
    $LastUsageVDI.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($LastUsageVDI)

    # Line Break Vertical
    $LineBreak = New-Object System.Windows.Forms.Button
    $LineBreak.Location = New-Object System.Drawing.Size(15,445)
    $LineBreak.Size = New-Object System.Drawing.Size(200,5)
    $LineBreak.Font = New-Object System.Drawing.Font("Calibri",10,[System.Drawing.FontStyle]::Bold)
    $LineBreak.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $LineBreak.FlatAppearance.BorderSize = 3
    $LineBreak.FlatAppearance.BorderColor = [System.Drawing.Color]::"white"
    $LineBreak.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($LineBreak)

    # Output VDI assigned to Specific user
    $VDIAssign = New-Object System.Windows.Forms.Button
    $VDIAssign.Location = New-Object System.Drawing.Size(15,455)
    $VDIAssign.Size = New-Object System.Drawing.Size(100,40)
    $VDIAssign.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIAssign.Text = "VDI Assigned to specific User"
    $VDIAssign.ForeColor = "#104277"
    $VDIAssign.BackColor = "Orange"
    $VDIAssign.Add_Click({VDIAssign})
    $VDIAssign.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($VDIAssign)

    # Output VDI Tags
    $VDITAG = New-Object System.Windows.Forms.Button
    $VDITAG.Location = New-Object System.Drawing.Size(15,495)
    $VDITAG.Size = New-Object System.Drawing.Size(100,40)
    $VDITAG.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDITAG.Text = "VDI By TAG List"
    $VDITAG.ForeColor = "Yellow"
    $VDITAG.BackColor = "#104277"
    $VDITAG.Add_Click({VDITAG})
    $VDITAG.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($VDITAG)

    # Add User to Specific VDI 
    $VDIAddUser = New-Object System.Windows.Forms.Button
    $VDIAddUser.Location = New-Object System.Drawing.Size(10,20)
    $VDIAddUser.Size = New-Object System.Drawing.Size(100,40)
    $VDIAddUser.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIAddUser.Text = "Add User to VDI"
    $VDIAddUser.ForeColor = "Yellow"
    $VDIAddUser.BackColor = "#104277"
    $VDIAddUser.Add_Click({VDIAddUser})
    $VDIAddUser.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxBottom.Controls.Add($VDIAddUser)

    # Remove User from Specific VDI
    $VDIRemoveUser = New-Object System.Windows.Forms.Button
    $VDIRemoveUser.Location = New-Object System.Drawing.Size(10,65)
    $VDIRemoveUser.Size = New-Object System.Drawing.Size(100,40)
    $VDIRemoveUser.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIRemoveUser.Text = "Remove User from VDI"
    $VDIRemoveUser.ForeColor = "Yellow"
    $VDIRemoveUser.BackColor = "#104277"
    $VDIRemoveUser.Add_Click({VDIRemoveUser})
    $VDIRemoveUser.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxBottom.Controls.Add($VDIRemoveUser)

    # Active Session VDI - VDI powered on but no logged in user
    $VDIAS = New-Object System.Windows.Forms.Button
    $VDIAS.Location = New-Object System.Drawing.Size(110,20)
    $VDIAS.Size = New-Object System.Drawing.Size(100,40)
    $VDIAS.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIAS.Text = "VDI Active State"
    $VDIAS.ForeColor = "Yellow"
    $VDIAS.BackColor = "#104277"
    $VDIAS.Add_Click({VDIAS})
    $VDIAS.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxBottom.Controls.Add($VDIAS)
    
    # Create VDI Tag 
    $VDICreateTag = New-Object System.Windows.Forms.Button
    $VDICreateTag.Location = New-Object System.Drawing.Size(210,20)
    $VDICreateTag.Size = New-Object System.Drawing.Size(100,40)
    $VDICreateTag.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDICreateTag.Text = "Create TAG Citrix Studio"
    $VDICreateTag.ForeColor = "Yellow"
    $VDICreateTag.BackColor = "#104277"
    $VDICreateTag.Add_Click({VDICreateTag})
    $VDICreateTag.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxBottom.Controls.Add($VDICreateTag)

    # Remove VDI Tag
    $VDIRemoveTag = New-Object System.Windows.Forms.Button
    $VDIRemoveTag.Location = New-Object System.Drawing.Size(210,65)
    $VDIRemoveTag.Size = New-Object System.Drawing.Size(100,40)
    $VDIRemoveTag.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIRemoveTag.Text = "Remove TAG Citrix Studio"
    $VDIRemoveTag.ForeColor = "Yellow"
    $VDIRemoveTag.BackColor = "#104277"
    $VDIRemoveTag.Add_Click({VDIRemoveTag})
    $VDIRemoveTag.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxBottom.Controls.Add($VDIRemoveTag)

    # Add VDI Tag
    $VDIAddTag = New-Object System.Windows.Forms.Button
    $VDIAddTag.Location = New-Object System.Drawing.Size(310,20)
    $VDIAddTag.Size = New-Object System.Drawing.Size(100,40)
    $VDIAddTag.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIAddTag.Text = "Add VDI TAG"
    $VDIAddTag.ForeColor = "Yellow"
    $VDIAddTag.BackColor = "#104277"
    $VDIAddTag.Add_Click({VDIAddTag})
    $VDIAddTag.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxBottom.Controls.Add($VDIAddTag)

    # Remove TAG from VDI
    $VDIRemoveTagFromVDI = New-Object System.Windows.Forms.Button
    $VDIRemoveTagFromVDI.Location = New-Object System.Drawing.Size(310,65)
    $VDIRemoveTagFromVDI.Size = New-Object System.Drawing.Size(100,40)
    $VDIRemoveTagFromVDI.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIRemoveTagFromVDI.Text = "Remove TAG from VDI"
    $VDIRemoveTagFromVDI.ForeColor = "Yellow"
    $VDIRemoveTagFromVDI.BackColor = "#104277"
    $VDIRemoveTagFromVDI.Add_Click({VDIRemoveTagFromVDI})
    $VDIRemoveTagFromVDI.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxBottom.Controls.Add($VDIRemoveTagFromVDI)

    # VDI Local Administrator Password
    $VDIAP = New-Object System.Windows.Forms.Button
    $VDIAP.Location = New-Object System.Drawing.Size(10,110)
    $VDIAP.Size = New-Object System.Drawing.Size(100,40)
    $VDIAP.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIAP.Text = "VDI Pass"
    $VDIAP.ForeColor = "Yellow"
    $VDIAP.BackColor = "#104277"
    $VDIAP.Add_Click({VDIAP})
    $VDIAP.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxBottom.Controls.Add($VDIAP)

    # VDI Running Days
    $VDIRunningDays = New-Object System.Windows.Forms.Button
    $VDIRunningDays.Location = New-Object System.Drawing.Size(410,65)
    $VDIRunningDays.Size = New-Object System.Drawing.Size(100,40)
    $VDIRunningDays.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIRunningDays.Text = "VDI Running Days"
    $VDIRunningDays.ForeColor = "Yellow"
    $VDIRunningDays.BackColor = "#104277"
    $VDIRunningDays.Add_Click({VDIRunningDays})
    $VDIRunningDays.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxBottom.Controls.Add($VDIRunningDays)

    # Line Break Vertical Citrix Studio GroupBox
    $LineBreakCiSt = New-Object System.Windows.Forms.Button
    $LineBreakCiSt.Location = New-Object System.Drawing.Size(430,10)
    $LineBreakCiSt.Size = New-Object System.Drawing.Size(1,160)
    $LineBreakCiSt.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $LineBreakCiSt.ForeColor = "White"
    $LineBreakCiSt.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxCiStu.Controls.Add($LineBreakCiSt)

    # DropDown for Published Apps, Machine Cat, Delivery Grp and XenApp Servers
    $listBoxPubApps = new-object System.Windows.Forms.ComboBox
    $listBoxPubApps.Location = New-Object System.Drawing.Point(440, 20)
    $listBoxPubApps.Size = New-Object System.Drawing.Size(220, 20)
    $listBoxPubApps.Font = New-Object System.Drawing.Font("Calibri",8,[System.Drawing.FontStyle]::Bold)
    $groupBoxCiStu.controls.Add($listBoxPubApps)

    # List Published Applications
    $GetPubApps = New-Object System.Windows.Forms.Button 
    $GetPubApps.Location = New-Object System.Drawing.Size(670, 20) 
    $GetPubApps.Size = New-Object System.Drawing.Size(120, 30) 
    $GetPubApps.Font = New-Object System.Drawing.Font("Calibri",11,[System.Drawing.FontStyle]::Bold)
    $GetPubApps.Text = "Published Apps" 
    $GetPubApps.ForeColor = "White"
    $GetPubApps.BackColor = "#104277"
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
    $GetMacCat.Location = New-Object System.Drawing.Size(670, 50) 
    $GetMacCat.Size = New-Object System.Drawing.Size(120, 30) 
    $GetMacCat.Font = New-Object System.Drawing.Font("Calibri",11,[System.Drawing.FontStyle]::Bold)
    $GetMacCat.Text = "Machine Catalogs" 
    $GetMacCat.ForeColor = "White"
    $GetMacCat.BackColor = "#104277"
    $GetMacCat.Cursor = [System.Windows.Forms.Cursors]::Hand
    $GetMacCat.Add_Click( {
            
                $listBoxPubApps.Items.Clear()
                $citrixServer = $CtxSrvtxtbx
                $MachineCat = (Get-BrokerCatalog  -adminaddress $DDC -MaxRecordCount 5000 | Select Name | Select-Object @{l="Name";e={$_.Name -join " "}}).Name | Sort 
                foreach ($dgpubName in $MachineCat) {

                    $listBoxPubApps.Items.Add($dgpubName)
                }
            
        }) 
    $groupBoxCiStu.Controls.Add($GetMacCat)

    # List Delivery Groups
    $GetDelGrp = New-Object System.Windows.Forms.Button 
    $GetDelGrp.Location = New-Object System.Drawing.Size(670, 80) 
    $GetDelGrp.Size = New-Object System.Drawing.Size(120, 30) 
    $GetDelGrp.Font = New-Object System.Drawing.Font("Calibri",11,[System.Drawing.FontStyle]::Bold)
    $GetDelGrp.Text = "Delivery Groups" 
    $GetDelGrp.ForeColor = "White"
    $GetDelGrp.BackColor = "#104277"
    $GetDelGrp.Cursor = [System.Windows.Forms.Cursors]::Hand
    $GetDelGrp.Add_Click( {
            
                $listBoxPubApps.Items.Clear()
                $citrixServer = $CtxSrvtxtbx
                $DelGroups = (Get-BrokerDesktopGroup -adminaddress $DDC -MaxRecordCount 5000 | Select Name | Select-Object @{l="Name";e={$_.Name -join " "}}).Name | Sort 
                foreach ($dgName in $DelGroups) {

                    $listBoxPubApps.Items.Add($dgName)
                }
            
        }) 
    $groupBoxCiStu.Controls.Add($GetDelGrp)

    # List XenApp Servers
    $GetXenAppServers = New-Object System.Windows.Forms.Button 
    $GetXenAppServers.Location = New-Object System.Drawing.Size(670, 110) 
    $GetXenAppServers.Size = New-Object System.Drawing.Size(120, 30) 
    $GetXenAppServers.Font = New-Object System.Drawing.Font("Calibri",11,[System.Drawing.FontStyle]::Bold)
    $GetXenAppServers.Text = "XenApp Servers" 
    $GetXenAppServers.ForeColor = "White"
    $GetXenAppServers.BackColor = "#104277"
    $GetXenAppServers.Cursor = [System.Windows.Forms.Cursors]::Hand
    $GetXenAppServers.Add_Click( {
            
                $listBoxPubApps.Items.Clear()
                $citrixServer = $CtxSrvtxtbx
                $XenAppServersList = (Get-BrokerSession -adminaddress $DDC -MaxRecordCount 5000 | where DNSName -Like "*$XenAppServerNameLike*" | Select-Object @{l="DNSName";e={$_.DNSName -join " "}}).DNSName | Sort-Object @{l="DNSName";e={$_.DNSName -join " "}}.DNSName -Unique
                foreach ($ServerName in $XenAppServersList) {

                    $listBoxPubApps.Items.Add($ServerName)
                }
            $objStatusBar.Text = "Total XenApp Servers: " + $XenAppServersList.Count
        }) 
        
    $groupBoxCiStu.Controls.Add($GetXenAppServers)



    # Show all details of selected published app from listbox
    $ShowPubApp = New-Object System.Windows.Forms.Button
    $ShowPubApp.Location = New-Object System.Drawing.Size(10,20)
    $ShowPubApp.Size = New-Object System.Drawing.Size(100,40)
    $ShowPubApp.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $ShowPubApp.Text = "Show PubApp Info"
    $ShowPubApp.ForeColor = "white"
    $ShowPubApp.BackColor = "#63C132"
    $ShowPubApp.Add_Click({ShowPubApp})
    $ShowPubApp.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxCiStu.Controls.Add($ShowPubApp)

    # Show all associated UserNames of selected published app from listbox
    $ShowPubAppAssociatedUserNames = New-Object System.Windows.Forms.Button
    $ShowPubAppAssociatedUserNames.Location = New-Object System.Drawing.Size(10,110)
    $ShowPubAppAssociatedUserNames.Size = New-Object System.Drawing.Size(100,40)
    $ShowPubAppAssociatedUserNames.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $ShowPubAppAssociatedUserNames.Text = "Show PubApp Users"
    $ShowPubAppAssociatedUserNames.ForeColor = "white"
    $ShowPubAppAssociatedUserNames.BackColor = "#63C132"
    $ShowPubAppAssociatedUserNames.Add_Click({ShowPubAppAssociatedUserNames})
    $ShowPubAppAssociatedUserNames.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxCiStu.Controls.Add($ShowPubAppAssociatedUserNames)

    # Show all associated UserNames of selected Delivery Group app from listbox
    $ShowDeliveryGroupInfo = New-Object System.Windows.Forms.Button
    $ShowDeliveryGroupInfo.Location = New-Object System.Drawing.Size(110,65)
    $ShowDeliveryGroupInfo.Size = New-Object System.Drawing.Size(100,40)
    $ShowDeliveryGroupInfo.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $ShowDeliveryGroupInfo.Text = "Show Delivery Group Info"
    $ShowDeliveryGroupInfo.ForeColor = "white"
    $ShowDeliveryGroupInfo.BackColor = "#63C132"
    $ShowDeliveryGroupInfo.Add_Click({ShowDeliveryGroupInfo})
    $ShowDeliveryGroupInfo.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxCiStu.Controls.Add($ShowDeliveryGroupInfo)

    # Show all details of selected Machine catalog from listbox
    $ShowMachineCat = New-Object System.Windows.Forms.Button
    $ShowMachineCat.Location = New-Object System.Drawing.Size(110,20)
    $ShowMachineCat.Size = New-Object System.Drawing.Size(100,40)
    $ShowMachineCat.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $ShowMachineCat.Text = "Show Machine Catalog"
    $ShowMachineCat.ForeColor = "white"
    $ShowMachineCat.BackColor = "#63C132"
    $ShowMachineCat.Add_Click({ShowMachineCat})
    $ShowMachineCat.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxCiStu.Controls.Add($ShowMachineCat)

    # Show Usage of selected published app from listbox
    $ShowUsagePubApp = New-Object System.Windows.Forms.Button
    $ShowUsagePubApp.Location = New-Object System.Drawing.Size(10,65)
    $ShowUsagePubApp.Size = New-Object System.Drawing.Size(100,40)
    $ShowUsagePubApp.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $ShowUsagePubApp.Text = "Show PubApp Usage"
    $ShowUsagePubApp.ForeColor = "white"
    $ShowUsagePubApp.BackColor = "#63C132"
    $ShowUsagePubApp.Add_Click({ShowUsagePubApp})
    $ShowUsagePubApp.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxCiStu.Controls.Add($ShowUsagePubApp)

    # Show Specific XenApp Server User sessions listbox
    $ShowXenAppSessions = New-Object System.Windows.Forms.Button
    $ShowXenAppSessions.Location = New-Object System.Drawing.Size(110,110)
    $ShowXenAppSessions.Size = New-Object System.Drawing.Size(100,40)
    $ShowXenAppSessions.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $ShowXenAppSessions.Text = "Show XenApp User Sessions"
    $ShowXenAppSessions.ForeColor = "white"
    $ShowXenAppSessions.BackColor = "#63C132"
    $ShowXenAppSessions.Add_Click({ShowXenAppSessions})
    $ShowXenAppSessions.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxCiStu.Controls.Add($ShowXenAppSessions)

    # Show Specific XenApp Server User sessions listbox ###################################################################
    $ShowAllXenAppDisconnectedSessions = New-Object System.Windows.Forms.Button
    $ShowAllXenAppDisconnectedSessions.Location = New-Object System.Drawing.Size(210,110)
    $ShowAllXenAppDisconnectedSessions.Size = New-Object System.Drawing.Size(100,40)
    $ShowAllXenAppDisconnectedSessions.Font = New-Object System.Drawing.Font("Calibri",8,[System.Drawing.FontStyle]::Bold)
    $ShowAllXenAppDisconnectedSessions.Text = "All Disconnected Sessions"
    $ShowAllXenAppDisconnectedSessions.ForeColor = "white"
    $ShowAllXenAppDisconnectedSessions.BackColor = "#63C132"
    $ShowAllXenAppDisconnectedSessions.Add_Click({ShowAllXenAppDisconnectedSessions})
    $ShowAllXenAppDisconnectedSessions.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxCiStu.Controls.Add($ShowAllXenAppDisconnectedSessions)

    # Output VDI IN/OFF status
    $VDIStatus = New-Object System.Windows.Forms.Button
    $VDIStatus.Location = New-Object System.Drawing.Size(115,495)
    $VDIStatus.Size = New-Object System.Drawing.Size(100,40)
    $VDIStatus.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIStatus.Text = "VDI Powered on/off"
    $VDIStatus.ForeColor = "Yellow"
    $VDIStatus.BackColor = "#104277"
    $VDIStatus.Add_Click({VDIStatus})
    $VDIStatus.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($VDIStatus)
    
    # List VDI Names only
    $VDIListNameOnly = New-Object System.Windows.Forms.Button
    $VDIListNameOnly.Location = New-Object System.Drawing.Size(115,535)
    $VDIListNameOnly.Size = New-Object System.Drawing.Size(100,40)
    $VDIListNameOnly.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIListNameOnly.Text = "List All VDIs"
    $VDIListNameOnly.ForeColor = "Yellow"
    $VDIListNameOnly.BackColor = "#104277"
    $VDIListNameOnly.Add_Click({VDIListNameOnly})
    $VDIListNameOnly.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($VDIListNameOnly)

    # List Specific VDI information only
    $VDISpecInfo = New-Object System.Windows.Forms.Button
    $VDISpecInfo.Location = New-Object System.Drawing.Size(15,535)
    $VDISpecInfo.Size = New-Object System.Drawing.Size(100,40)
    $VDISpecInfo.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDISpecInfo.Text = "VDI Specs"
    $VDISpecInfo.ForeColor = "Yellow"
    $VDISpecInfo.BackColor = "#104277"
    $VDISpecInfo.Add_Click({VDISpecInfo})
    $VDISpecInfo.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($VDISpecInfo)

    # Output User assigned to specific VDI
    $VDIUserAssign = New-Object System.Windows.Forms.Button
    $VDIUserAssign.Location = New-Object System.Drawing.Size(115,455)
    $VDIUserAssign.Size = New-Object System.Drawing.Size(100,40)
    $VDIUserAssign.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIUserAssign.Text = "User Assigned to specific VDI"
    $VDIUserAssign.ForeColor = "#104277"
    $VDIUserAssign.BackColor = "Orange"
    $VDIUserAssign.Add_Click({VDIUserAssign})
    $VDIUserAssign.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($VDIUserAssign)

    
<# Extra Line Breaks to add
    #### Line Break Horizontal ###################################################################
    $LineBreak = New-Object System.Windows.Forms.Button
    $LineBreak.Location = New-Object System.Drawing.Size(90,70)
    $LineBreak.Size = New-Object System.Drawing.Size(5,720)
    $LineBreak.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    #$DomainInfo.Text = "Domain"
    $LineBreak.ForeColor = "Orange"
    #$LineBreak.Add_Click({LineBreak})
    $LineBreak.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($LineBreak)

    #### Line Break Vertical ###################################################################
    $LineBreak = New-Object System.Windows.Forms.Button
    $LineBreak.Location = New-Object System.Drawing.Size(15,790)
    $LineBreak.Size = New-Object System.Drawing.Size(155,5)
    $LineBreak.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    #$DomainInfo.Text = "Domain"
    $LineBreak.ForeColor = "Orange"
    #$LineBreak.Add_Click({LineBreak})
    $LineBreak.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($LineBreak)
    #>
    

#endregion Buttons

#region GroupBoxTop

    # Citrix Published Applications 
    $VCPApps = New-Object System.Windows.Forms.Button
    $VCPApps.Location = New-Object System.Drawing.Size(10,20)
    $VCPApps.Size = New-Object System.Drawing.Size(100,40)
    $VCPApps.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VCPApps.Text = "Published Apps"
    $VCPApps.ForeColor = "White"
    $VCPApps.BackColor = "#104277"
    $VCPApps.Add_Click({VCPApps})
    $VCPApps.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxTop.Controls.Add($VCPApps)   
    
    # Application Usage 
    $AppUsage = New-Object System.Windows.Forms.Button
    $AppUsage.Location = New-Object System.Drawing.Size(115,20)
    $AppUsage.Size = New-Object System.Drawing.Size(100,40)
    $AppUsage.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $AppUsage.Text = "App Usage"
    $AppUsage.ForeColor = "White"
    $AppUsage.BackColor = "#104277"
    $AppUsage.Add_Click({AppUsage})
    $AppUsage.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxTop.Controls.Add($AppUsage)

    # Add User to Specific Published Application 
    $AddUserPA = New-Object System.Windows.Forms.Button
    $AddUserPA.Location = New-Object System.Drawing.Size(220,20)
    $AddUserPA.Size = New-Object System.Drawing.Size(100,40)
    $AddUserPA.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $AddUserPA.Text = "Add User to Application"
    $AddUserPA.ForeColor = "White"
    $AddUserPA.BackColor = "#104277"
    $AddUserPA.Add_Click({AddUserPA})
    $AddUserPA.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxTop.Controls.Add($AddUserPA)

    # VDA Versions 
    $VDAver = New-Object System.Windows.Forms.Button
    $VDAver.Location = New-Object System.Drawing.Size(115,65)
    $VDAver.Size = New-Object System.Drawing.Size(100,40)
    $VDAver.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDAver.Text = "VDA Version"
    $VDAver.ForeColor = "White"
    $VDAver.BackColor = "#104277"
    $VDAver.Add_Click({VDAver})
    $VDAver.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxTop.Controls.Add($VDAver)

    # Delivery Groups 
    $DelGrp = New-Object System.Windows.Forms.Button
    $DelGrp.Location = New-Object System.Drawing.Size(325,20)
    $DelGrp.Size = New-Object System.Drawing.Size(100,40)
    $DelGrp.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $DelGrp.Text = "Delivery Groups"
    $DelGrp.ForeColor = "White"
    $DelGrp.BackColor = "#104277"
    $DelGrp.Add_Click({DelGrp})
    $DelGrp.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxTop.Controls.Add($DelGrp)

    # Machine Catalogs
    $MacCat = New-Object System.Windows.Forms.Button
    $MacCat.Location = New-Object System.Drawing.Size(325,65)
    $MacCat.Size = New-Object System.Drawing.Size(100,40)
    $MacCat.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $MacCat.Text = "Machine Catalogs"
    $MacCat.ForeColor = "White"
    $MacCat.BackColor = "#104277"
    $MacCat.Add_Click({MacCat})
    $MacCat.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxTop.Controls.Add($MacCat)

    # Citrix TAG List
    $VDITAGList = New-Object System.Windows.Forms.Button
    $VDITAGList.Location = New-Object System.Drawing.Size(220,65)
    $VDITAGList.Size = New-Object System.Drawing.Size(100,40)
    $VDITAGList.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDITAGList.Text = "TAG List"
    $VDITAGList.ForeColor = "White"
    $VDITAGList.BackColor = "#104277"
    $VDITAGList.Add_Click({VDITAGList})
    $VDITAGList.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxTop.Controls.Add($VDITAGList)


    #endregion GroupBoxTop

#region groupBoxOutFile

    # OutPutBox Export TXT
    $ExportOutPutBox = New-Object System.Windows.Forms.Button
    $ExportOutPutBox.Location = New-Object System.Drawing.Size(10,65)
    $ExportOutPutBox.Size = New-Object System.Drawing.Size(100,40)
    $ExportOutPutBox.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $ExportOutPutBox.Text = "OutPut Box to TXT File"
    $ExportOutPutBox.ForeColor = "White"
    $ExportOutPutBox.BackColor = "#104277"
    $ExportOutPutBox.Add_Click({ExportOutPutBox})
    $ExportOutPutBox.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxOutFile.Controls.Add($ExportOutPutBox)

    # OutPutBox Export XLSX StyleShhet Medium16
    $ExportOutPutBoxToXLSX = New-Object System.Windows.Forms.Button
    $ExportOutPutBoxToXLSX.Location = New-Object System.Drawing.Size(110,20)
    $ExportOutPutBoxToXLSX.Size = New-Object System.Drawing.Size(80,40)
    $ExportOutPutBoxToXLSX.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $ExportOutPutBoxToXLSX.Text = "XLSX File"
    $ExportOutPutBoxToXLSX.ForeColor = "White"
    $ExportOutPutBoxToXLSX.BackColor = "#104277"
    $ExportOutPutBoxToXLSX.Add_Click({ExportOutPutBoxToXLSX})
    $ExportOutPutBoxToXLSX.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxOutFile.Controls.Add($ExportOutPutBoxToXLSX)


    # Published Application Total Information from Studio List Out to  CSV/TXT/XLSX
    $PARepCSV = New-Object System.Windows.Forms.Button
    $PARepCSV.Location = New-Object System.Drawing.Size(10,20)
    $PARepCSV.Size = New-Object System.Drawing.Size(100,40)
    $PARepCSV.Font = New-Object System.Drawing.Font("Calibri",7,[System.Drawing.FontStyle]::Bold)
    $PARepCSV.Text = "Published Application Report XLSX/CSV/TXT"
    $PARepCSV.ForeColor = "White"
    $PARepCSV.BackColor = "#104277"
    $PARepCSV.Add_Click({PARepCSV})
    $PARepCSV.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxOutFile.Controls.Add($PARepCSV)


    #endregion groupBoxOutFile

#region groupBoxSite


    # Output Site Information
    $SiteInfo = New-Object System.Windows.Forms.Button
    $SiteInfo.Location = New-Object System.Drawing.Size(10,20)
    $SiteInfo.Size = New-Object System.Drawing.Size(100,40)
    $SiteInfo.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $SiteInfo.Text = "Site Info"
    $SiteInfo.ForeColor = "Red"
    $SiteInfo.BackColor = "White"
    $SiteInfo.Add_Click({SiteInfo})
    $SiteInfo.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxSite.Controls.Add($SiteInfo)

    # Output All Active Sessions Information
    $ActiveSes = New-Object System.Windows.Forms.Button
    $ActiveSes.Location = New-Object System.Drawing.Size(10,65)
    $ActiveSes.Size = New-Object System.Drawing.Size(100,40)
    $ActiveSes.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $ActiveSes.Text = "Active Licenses"
    $ActiveSes.ForeColor = "Red"
    $ActiveSes.BackColor = "White"
    $ActiveSes.Add_Click({ActiveSes})
    $ActiveSes.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxSite.Controls.Add($ActiveSes)

    # ShutDown VDI By Name
    $VDIShutDown = New-Object System.Windows.Forms.Button
    $VDIShutDown.Location = New-Object System.Drawing.Size(110,20)
    $VDIShutDown.Size = New-Object System.Drawing.Size(100,40)
    $VDIShutDown.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIShutDown.Text = "ShutDown VDI by Name"
    $VDIShutDown.ForeColor = "Red"
    $VDIShutDown.BackColor = "White"
    $VDIShutDown.Add_Click({VDIShutDown})
    $VDIShutDown.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxSite.Controls.Add($VDIShutDown)

    # ShutDown VDI - All VDIs powered on with no User Sessions
    $VDIShutDownActiveNoSession = New-Object System.Windows.Forms.Button
    $VDIShutDownActiveNoSession.Location = New-Object System.Drawing.Size(210,65)
    $VDIShutDownActiveNoSession.Size = New-Object System.Drawing.Size(100,40)
    $VDIShutDownActiveNoSession.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIShutDownActiveNoSession.Text = "ShutDown VDI Automated"
    $VDIShutDownActiveNoSession.ForeColor = "Red"
    $VDIShutDownActiveNoSession.BackColor = "White"
    $VDIShutDownActiveNoSession.Add_Click({VDIShutDownActiveNoSession})
    $VDIShutDownActiveNoSession.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxSite.Controls.Add($VDIShutDownActiveNoSession)
    
    # Start VDI By Name
    $VDIStart = New-Object System.Windows.Forms.Button
    $VDIStart.Location = New-Object System.Drawing.Size(210,20)
    $VDIStart.Size = New-Object System.Drawing.Size(100,40)
    $VDIStart.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIStart.Text = "Start VDI           by Name"
    $VDIStart.ForeColor = "Red"
    $VDIStart.BackColor = "White"
    $VDIStart.Add_Click({VDIStart})
    $VDIStart.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxSite.Controls.Add($VDIStart)

    # ShutDown VDI from TXT file
    $VDIShutDownTXTList = New-Object System.Windows.Forms.Button
    $VDIShutDownTXTList.Location = New-Object System.Drawing.Size(110,65)
    $VDIShutDownTXTList.Size = New-Object System.Drawing.Size(100,40)
    $VDIShutDownTXTList.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $VDIShutDownTXTList.Text = "ShutDown VDI from TXT file"
    $VDIShutDownTXTList.ForeColor = "Red"
    $VDIShutDownTXTList.BackColor = "White"
    $VDIShutDownTXTList.Add_Click({VDIShutDownTXTList})
    $VDIShutDownTXTList.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxSite.Controls.Add($VDIShutDownTXTList)

    #endregion groupBoxSite

#region groupBoxSessions

    # UserSessions Information for specific User
    $CitrixUserSessions = New-Object System.Windows.Forms.Button
    $CitrixUserSessions.Location = New-Object System.Drawing.Size(10,20)
    $CitrixUserSessions.Size = New-Object System.Drawing.Size(100,40)
    $CitrixUserSessions.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $CitrixUserSessions.Text = "Users Sessions"
    $CitrixUserSessions.ForeColor = "Red"
    $CitrixUserSessions.BackColor = "White"
    $CitrixUserSessions.Add_Click({CitrixUserSessions})
    $CitrixUserSessions.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxSessions.Controls.Add($CitrixUserSessions)

    # UserSessions Disconnected Information for specific User
    $CitrixUserSessionsDisc = New-Object System.Windows.Forms.Button
    $CitrixUserSessionsDisc.Location = New-Object System.Drawing.Size(10,65)
    $CitrixUserSessionsDisc.Size = New-Object System.Drawing.Size(100,40)
    $CitrixUserSessionsDisc.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $CitrixUserSessionsDisc.Text = "Users Sessions Disconnected"
    $CitrixUserSessionsDisc.ForeColor = "Red"
    $CitrixUserSessionsDisc.BackColor = "White"
    $CitrixUserSessionsDisc.Add_Click({CitrixUserSessionsDisc})
    $CitrixUserSessionsDisc.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxSessions.Controls.Add($CitrixUserSessionsDisc)


    #endregion groupBoxSessions

#region clearfield and exit buttons

    #### Clear all fields #################################################################
    $ClearFields = New-Object System.Windows.Forms.Button
    $ClearFields.Location = New-Object System.Drawing.Size(15,20)
    $ClearFields.Size = New-Object System.Drawing.Size(115,40)
    $ClearFields.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $ClearFields.Text = "Clear All Fields"
    $ClearFields.ForeColor = "#104277"
    $ClearFields.BackColor = "orange"
    $ClearFields.Add_Click({ClearFields})
    $ClearFields.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBoxTopCLEX.Controls.Add($ClearFields)
    
    #### Exit Button ###################################################################
    $exitButton = New-Object System.Windows.Forms.Button
    $exitButton.Location = New-Object System.Drawing.Size(15,60)
    $exitButton.Size = New-Object System.Drawing.Size(70,40)
    $exitButton.ForeColor = "White"
    $exitButton.BackColor = "red"
    $exitButton.Text = "Exit"
    $exitButton.Cursor = [System.Windows.Forms.Cursors]::Hand
    $exitButton.add_Click({$Form.close()})
    $groupBoxTopCLEX.Controls.Add($exitButton)


    #endregion clearfield and exit buttons

#region groupBoxBottom


    #endregion groupBoxBottom

#region Input Boxes

    # Input window with "INITIALS/VDI" Label
    $InputBox = New-Object System.Windows.Forms.TextBox 
    $InputBox.Location = New-Object System.Drawing.Size(10,50) 
    $InputBox.Size = New-Object System.Drawing.Size(250,20) 
    $Form.Controls.Add($InputBox)
    $Label2InputBox = New-Object System.Windows.Forms.Label
    $Label2InputBox.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $Label2InputBox.ForeColor = "White"
    $Label2InputBox.Text = "INITIALS/VDI"
    $Label2InputBox.AutoSize = $True
    $Label2InputBox.Location = New-Object System.Drawing.Size(10,25) 
    $Form.Controls.Add($Label2InputBox)

    # Input window with "SVDI Name" label
    $InputBoxVDIName = New-Object System.Windows.Forms.TextBox 
    $InputBoxVDIName.Location = New-Object System.Drawing.Size(270,50) 
    $InputBoxVDIName.Size = New-Object System.Drawing.Size(150,20) 
    $Form.Controls.Add($InputBoxVDIName)
    $Label2InputBoxVDIName = New-Object System.Windows.Forms.Label
    $Label2InputBoxVDIName.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $Label2InputBoxVDIName.ForeColor = "White"
    $Label2InputBoxVDIName.Text = "VDI/Published App"
    $Label2InputBoxVDIName.AutoSize = $True
    $Label2InputBoxVDIName.Location = New-Object System.Drawing.Size(270,25) 
    $Form.Controls.Add($Label2InputBoxVDIName)

#endregion Input Boxes

#region OutPut Boxes
######################## OutPut Boxes ###################################################

    #### Output Box Field ###############################################################
    $outputBox = New-Object System.Windows.Forms.RichTextBox
    $outputBox.Location = New-Object System.Drawing.Size(250,130)
    $outputBox.Size = New-Object System.Drawing.Size(1360,420)
    $outputBox.Font = New-Object System.Drawing.Font("Consolas", 10 ,[System.Drawing.FontStyle]::BOLD)
    $outputBox.MultiLine = $True
    $outputBox.ForeColor = "White"
    $outputBox.BackColor = "#104277"
    $outputBox.ScrollBars = "Vertical"
    $outputBox.Text = " .........................."
    $Form.Controls.Add($outputBox)

    ##############################################

    #### Output Count Field ###############################################################
    $outputBoxCount = New-Object System.Windows.Forms.RichTextBox
    $outputBoxCount.Location = New-Object System.Drawing.Size(600,100)
    $outputBoxCount.Size = New-Object System.Drawing.Size(100,20)
    $outputBoxCount.Font = New-Object System.Drawing.Font("Consolas", 9 ,[System.Drawing.FontStyle]::BOLD)
    $outputBoxCount.MultiLine = $True
    $outputBoxCount.ForeColor = "DarkBlue"
    $outputBoxCount.BackColor = "White"
    $outputBoxCount.ScrollBars = "Vertical"
    $outputBoxCount.Text = ""
    $Form.Controls.Add($outputBoxCount)

    ##############################################
    
######################## OutPut Boxes END #######################################################
#endregion OutPut Boxes

#region form end

    $Form.Add_Shown({$Form.Activate()})
    [void] $Form.ShowDialog()

#endregion form end
