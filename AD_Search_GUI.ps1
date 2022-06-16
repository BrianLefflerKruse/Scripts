#region Info
#####################################################################
#                         AD GUI Tool                               #
#                Developped by : Brian L. Kruse                     #
#                                                                   #
#                      Date: 24-11-2020                             #
#                                                                   #
#                      Version: 1.0                                 #
#                                                                   #
#                                                                   #
#     Purpose: A quick visual way to get related Information        #
#                    about Users in the AD                          #
#                                                                   #
#                                                                   #
#                                                                   #
#####################################################################

#####################################################################
#                                                                   #
# The script is build up in the following structure                 #
#                                                                   #
#      - GUI Tool Creation                                          #
#      - Labels and groupboxes                                      #
#      - Buttons                                                    #
#      - Outputboxes                                                #
#      - Functions                                                  #
#                                                                   #
#                                                                   #
#   Enter the FQDN for your DC in the line under "Functions"        #
#   #Place your DC here                                             #
#   $DC = 'DomainController'                                        #
#                                                                   #
#####################################################################
#endregion Info

#region GUI Tool Creation
###################### CREATING AD GUI TOOL #############################

    #### Form settings #################################################################
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")  

    $Form = New-Object System.Windows.Forms.Form
    $Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle #modifies the window border
    $Form.Text = "AD Information Tool"    
    $Form.Size = New-Object System.Drawing.Size(1250,650)  
    $Form.StartPosition = "CenterScreen" #loads the window in the center of the screen
    $Form.BackgroundImageLayout = "Zoom"
    $Form.MinimizeBox = $False
    $Form.MaximizeBox = $False
    $Form.ForeColor = "White"
    $Form.BackColor = "#104277"
    $Form.WindowState = "Normal"
    $Form.SizeGripStyle = "Hide"
    $Icon = [system.drawing.icon]::ExtractAssociatedIcon($PSHOME + "\powershell.exe")
    $Form.Icon = $Icon

#endregion GUI Tool Creation

#region Label Creation
    #### Title - Vestas AD User Info ###################################################
    $LabelTitle = New-Object System.Windows.Forms.Label
    $LabelFontTitle = New-Object System.Drawing.Font("Calibri",30,[System.Drawing.FontStyle]::Bold)
    $LabelTitle.Font = $LabelFontTitle
    $LabelTitle.ForeColor = "White"
    $LabelTitle.Text = "AD Information Tool"
    $LabelTitle.AutoSize = $True
    $LabelTitle.Location = New-Object System.Drawing.Size(350,25) 
    $Form.Controls.Add($LabelTitle)

    #### Title - Information Outbox ###################################################
    $Label = New-Object System.Windows.Forms.Label
    $LabelFont = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $Label.Font = $LabelFont
    $Label.Text = "Information OutPut"
    $Label.AutoSize = $True
    $Label.Location = New-Object System.Drawing.Size(200,100)
    $Form.Controls.Add($Label)

    <##### Title - AD Outbox ###################################################
    $Label = New-Object System.Windows.Forms.Label
    $LabelFont = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $Label.Font = $LabelFont
    $Label.Text = "AD User Info"
    $Label.AutoSize = $True
    $Label.Location = New-Object System.Drawing.Size(730,100)
    $Form.Controls.Add($Label)

    #### Title - AD MemberOf ###################################################
    $Label = New-Object System.Windows.Forms.Label
    $LabelFont = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $Label.Font = $LabelFont
    $Label.Text = "Member Of"
    $Label.AutoSize = $True
    $Label.Location = New-Object System.Drawing.Size(1050,100)
    $Form.Controls.Add($Label)

    #### Title - AD Manager Outbox ###################################################
    $Label = New-Object System.Windows.Forms.Label
    $LabelFont = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $Label.Font = $LabelFont
    $Label.Text = "Manager"
    $Label.AutoSize = $True
    $Label.Location = New-Object System.Drawing.Size(730,440)
    $Form.Controls.Add($Label)

    #### Title - AD Department Outbox ###################################################
    $Label = New-Object System.Windows.Forms.Label
    $LabelFont = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $Label.Font = $LabelFont
    $Label.Text = "Department"
    $Label.AutoSize = $True
    $Label.Location = New-Object System.Drawing.Size(830,440)
    $Form.Controls.Add($Label)

    #### Title - AD Email Outbox ###################################################
    $Label = New-Object System.Windows.Forms.Label
    $LabelFont = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $Label.Font = $LabelFont
    $Label.Text = "Email"
    $Label.AutoSize = $True
    $Label.Location = New-Object System.Drawing.Size(830,520)
    $Form.Controls.Add($Label)
 #>
    #### Input window with "Type AD User or AD Group:" label ##########################################
    $InputBox = New-Object System.Windows.Forms.TextBox 
    $InputBox.Location = New-Object System.Drawing.Size(10,50) 
    $InputBox.Size = New-Object System.Drawing.Size(190,20) 
    $Form.Controls.Add($InputBox)
    $Label2InputBox = New-Object System.Windows.Forms.Label
    $Label2InputBox.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $Label2InputBox.ForeColor = "Orange"
    $Label2InputBox.Text = "Type AD User"
    $Label2InputBox.AutoSize = $True
    $Label2InputBox.Location = New-Object System.Drawing.Size(10,25) 
    $Form.Controls.Add($Label2InputBox)
    
    #### Group boxes for buttons ########################################################
    $groupBox = New-Object System.Windows.Forms.GroupBox
    $groupBox.Location = New-Object System.Drawing.Size(10,90) 
    $groupBox.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $groupBox.size = New-Object System.Drawing.Size(180,500)
    $groupBox.ForeColor = "Orange"
    $groupBox.text = "Options:" 
    
    $Form.Controls.Add($groupBox) 
#endregion Label Creation

#region Buttons

    #### AD User information Button #################################################################
    $PWCheck = New-Object System.Windows.Forms.Button
    $PWCheck.Location = New-Object System.Drawing.Size(15,25)
    $PWCheck.Size = New-Object System.Drawing.Size(155,40)
    $PWCheck.Font = New-Object System.Drawing.Font("Calibri",10,[System.Drawing.FontStyle]::Bold)
    $PWCheck.Text = "PW Check"
    $PWCheck.ForeColor = "Orange"
    $PWCheck.Add_Click({PWCheck})
    $PWCheck.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($PWCheck)

    <#
    #### Line Break ###################################################################
    $LineBreak = New-Object System.Windows.Forms.Button
    $LineBreak.Location = New-Object System.Drawing.Size(15,70)
    $LineBreak.Size = New-Object System.Drawing.Size(155,5)
    $LineBreak.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    #$DomainInfo.Text = "Domain"
    $LineBreak.ForeColor = "Orange"
    #$LineBreak.Add_Click({LineBreak})
    $LineBreak.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($LineBreak)
    #>

    #### AD User Identity ###################################################################
    $ADUIdent = New-Object System.Windows.Forms.Button
    $ADUIdent.Location = New-Object System.Drawing.Size(15,80)
    $ADUIdent.Size = New-Object System.Drawing.Size(155,40)
    $ADUIdent.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $ADUIdent.Text = "AD User Identity"
    $ADUIdent.ForeColor = "Orange"
    $ADUIdent.Add_Click({ADUIdent})
    $ADUIdent.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($ADUIdent)

    <#
    #### AD Group Members Disabled ###################################################################
    $ADGMembers = New-Object System.Windows.Forms.Button
    $ADGMembers.Location = New-Object System.Drawing.Size(15,135)
    $ADGMembers.Size = New-Object System.Drawing.Size(155,40)
    $ADGMembers.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $ADGMembers.Text = "AD Group Members"
    $ADGMembers.ForeColor = "Orange"
    $ADGMembers.Add_Click({ADGMembers})
    $ADGMembers.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($ADGMembers)

    #### AD User All Information ###################################################################
    $ADUserAll = New-Object System.Windows.Forms.Button
    $ADUserAll.Location = New-Object System.Drawing.Size(15,190)
    $ADUserAll.Size = New-Object System.Drawing.Size(155,40)
    $ADUserAll.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
    $ADUserAll.Text = "All User Information"
    $ADUserAll.ForeColor = "Orange"
    $ADUserAll.Add_Click({ADUserAll})
    $ADUserAll.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($ADUserAll)
    #>

    <#
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

    #### Clear all fields #################################################################
    $ClearFields = New-Object System.Windows.Forms.Button
    $ClearFields.Location = New-Object System.Drawing.Size(15,450)
    $ClearFields.Size = New-Object System.Drawing.Size(155,40)
    $ClearFields.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $ClearFields.Text = "Clear All Fields"
    $ClearFields.ForeColor = "White"
    $ClearFields.BackColor = "Orange"
    $ClearFields.Add_Click({ClearFields})
    $ClearFields.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($ClearFields)

    #### Exit Button ###################################################################
    $ExitButton = New-Object System.Windows.Forms.Button
    $ExitButton.Location = New-Object System.Drawing.Size(15,400)
    $ExitButton.Size = New-Object System.Drawing.Size(155,40)
    $ExitButton.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $ExitButton.Text = "Exit"
    $ExitButton.ForeColor = "White"
    $ExitButton.BackColor = "Red"
    $exitButton.add_Click({$Form.close()})
    $ExitButton.Cursor = [System.Windows.Forms.Cursors]::Hand
    $groupBox.Controls.Add($ExitButton)

#endregion Buttons

#region OutPut Boxes
    #### Output Box Field ###############################################################
    $outputBox = New-Object System.Windows.Forms.RichTextBox
    $outputBox.Location = New-Object System.Drawing.Size(200,130)
    $outputBox.Size = New-Object System.Drawing.Size(1000,460)
    $outputBox.Font = New-Object System.Drawing.Font("Consolas", 8 ,[System.Drawing.FontStyle]::Regular)
    $outputBox.MultiLine = $True
    $outputBox.ForeColor = "DarkBlue"
    $outputBox.BackColor = "White"
    $outputBox.ScrollBars = "Vertical"
    $outputBox.Text = " .........................."
    $Form.Controls.Add($outputBox)

    ##############################################
<#
    #### Output Box AD Info Field ###############################################################
    $outputBoxADInfo = New-Object System.Windows.Forms.RichTextBox
    $outputBoxADInfo.Location = New-Object System.Drawing.Size(730,130)
    $outputBoxADInfo.Size = New-Object System.Drawing.Size(300,300)
    $outputBoxADInfo.Font = New-Object System.Drawing.Font("Consolas", 8 ,[System.Drawing.FontStyle]::Regular)
    $outputBoxADInfo.MultiLine = $True
    $outputBoxADInfo.ForeColor = "DarkBlue"
    $outputBoxADInfo.BackColor = "White"
    $outputBoxADInfo.ScrollBars = "Vertical"
    $outputBoxADInfo.Text = " .........................."
    $Form.Controls.Add($outputBoxADInfo)

    ##############################################

    #### Output Box AD Member Of Field ###############################################################
    $outputBoxADMemOf = New-Object System.Windows.Forms.RichTextBox
    $outputBoxADMemOf.Location = New-Object System.Drawing.Size(1050,130)
    $outputBoxADMemOf.Size = New-Object System.Drawing.Size(300,300)
    $outputBoxADMemOf.Font = New-Object System.Drawing.Font("Consolas", 8 ,[System.Drawing.FontStyle]::Regular)
    $outputBoxADMemOf.MultiLine = $True
    $outputBoxADMemOf.ForeColor = "DarkBlue"
    $outputBoxADMemOf.BackColor = "White"
    $outputBoxADMemOf.ScrollBars = "Vertical"
    $outputBoxADMemOf.Text = " .........................."
    $Form.Controls.Add($outputBoxADMemOf)

    ##############################################

    #### Output Box AD Manager Field ###############################################################
    $outputBoxADManager = New-Object System.Windows.Forms.RichTextBox
    $outputBoxADManager.Location = New-Object System.Drawing.Size(730,470)
    $outputBoxADManager.Size = New-Object System.Drawing.Size(90,40)
    $outputBoxADManager.Font = New-Object System.Drawing.Font("Consolas", 8 ,[System.Drawing.FontStyle]::Regular)
    $outputBoxADManager.MultiLine = $True
    $outputBoxADManager.ForeColor = "DarkBlue"
    $outputBoxADManager.BackColor = "White"
    $outputBoxADManager.ScrollBars = "Vertical"
    $outputBoxADManager.Text = ""
    $Form.Controls.Add($outputBoxADManager)

    ##############################################

    #### Output Box AD Department Field ###############################################################
    $outputBoxADDepartment = New-Object System.Windows.Forms.RichTextBox
    $outputBoxADDepartment.Location = New-Object System.Drawing.Size(830,470)
    $outputBoxADDepartment.Size = New-Object System.Drawing.Size(250,40)
    $outputBoxADDepartment.Font = New-Object System.Drawing.Font("Consolas", 8 ,[System.Drawing.FontStyle]::Regular)
    $outputBoxADDepartment.MultiLine = $True
    $outputBoxADDepartment.ForeColor = "DarkBlue"
    $outputBoxADDepartment.BackColor = "White"
    $outputBoxADDepartment.ScrollBars = "Vertical"
    $outputBoxADDepartment.Text = ""
    $Form.Controls.Add($outputBoxADDepartment)

    ##############################################

    #### Output Box AD Email Field ###############################################################
    $outputBoxADEmail = New-Object System.Windows.Forms.RichTextBox
    $outputBoxADEmail.Location = New-Object System.Drawing.Size(830,550)
    $outputBoxADEmail.Size = New-Object System.Drawing.Size(150,40)
    $outputBoxADEmail.Font = New-Object System.Drawing.Font("Consolas", 8 ,[System.Drawing.FontStyle]::Regular)
    $outputBoxADEmail.MultiLine = $True
    $outputBoxADEmail.ForeColor = "DarkBlue"
    $outputBoxADEmail.BackColor = "White"
    $outputBoxADEmail.ScrollBars = "Vertical"
    $outputBoxADEmail.Text = ""
    $Form.Controls.Add($outputBoxADEmail)
    #>
    ##############################################

#endregion OutPut Boxes


#region Functions

#Place your DC here
$DC = ''

############################################## AD User Password Check Function ############################
function PWCheck{
                    $ADUser=$InputBox.text;
                
                    $outputBox.text =  "Gathering Password info - Please wait...."  | Out-String
                    $DCSystem = @()
                    
                    # Adding properties to object
                    $DCObject2 = New-Object PSCustomObject
                   
                    $TotalInfo = Get-ADUser $ADUser -properties PasswordLastSet, Passwordneverexpires, Passwordnotrequired -server $DC | Format-Table SamAccountName,name, passwordlastset, Passwordneverexpires, passwordnotrequired | Out-String

                    $outputBox.text = $TotalInfo


}
############################################## AD User Password Check Function End ############################

############################################## AD User Identity Function ############################
function ADUIdent{
                    $ADUser=$InputBox.text;
                
                    $outputBox.text =  "Gathering Password info - Please wait...."  | Out-String
                    $DCSystem = @()
                    
                    # Adding properties to object
                    $DCObject2 = New-Object PSCustomObject
                    
                    $TotalInfo = Get-aduser -Identity $ADUser -Properties LastLogonDate, PasswordLastSet | Out-String

                    $outputBox.text = $TotalInfo


}
############################################## AD User Identity Function End ############################

############################################## Clear All Fields function   #####################################

        function Clearfields{
            
            $outputBox.text = @()
            $InputBox.Text = @()
           }

        ############################################## Clear All Fields function END #######################
#endregion Functions

    $Form.Add_Shown({$Form.Activate()})
    [void] $Form.ShowDialog()