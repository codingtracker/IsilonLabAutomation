
<#   
 ======================================= vm-operations.ps1 ======================================= 
================================================================================ 
 Name: vm-operations.ps1
 Purpose: Steamline the steps of uploading files to VCenter.  
 Description: Steamline the steps of uploading files to VCenter. 
 Author: Chen Ye
 Email: chen.winfield.ye@gmail.com
 Syntax/Execution: Copy the scripts  and paste into your user profile Downloads folder and execute main.ps1
 Disclaimer: Use at your own Risk!
 Limitations:  
         * Must Run PowerShell (or ISE)  
 ================================================================================ 
#> 





function Modulechecker{

    if (Get-Module -ListAvailable -Name VMware.VimAutomation.Core) {
                 Write-Host "#VMware Module Already Loaded"
                 Write-Host ""
     } 

    else {
          
            
            if ( !(Test-Path "C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1") )
            #-or !(Test-Path "C:\Program Files\VMware\Infrastructure\PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1")
            {
                Write-Host "There is no PowerCLI tools in you machine, please download and install it to the default path to use this feature." -foreground "magenta"
                Write-Host ""
                Write-Host "Official Website to download is https://my.vmware.com/web/vmware/details?downloadGroup=PCLI650R1&productId=614" -foreground "magenta"
                Write-Host ""
                Write-Host "Introduction document for PowerCLI https://blogs.vmware.com/PowerCLI/2017/04/powercli-install-process-powershell-gallery.html" -foreground "magenta"
                Read-Host "Presee another key to continue"
                & "$env:userprofile\Downloads\main.ps1"
             }

             else {

                if ( Test-Path "C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1") {
                . "C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1"}
                if ( Test-Path "C:\Program Files\VMware\Infrastructure\PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1") {
                . "C:\Program Files\VMware\Infrastructure\PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1"}

                if (Get-Module -ListAvailable -Name VMware.VimAutomation.Core) {
                    
                     Write-Host "#VMWare Modules already loaded to your Powershell"
                
                }
                else {
                     Write-Host ""
                     Write-Host "It seems I could find your software path, however PowerCLI realted module could not be successfully loaded, please download and reinstall it to the default path to use this feature." -foreground "magenta"
                     Write-Host ""
                     Write-Host "Official Website to download is https://my.vmware.com/web/vmware/details?downloadGroup=PCLI650R1&productId=614" -foreground "magenta"
                     Write-Host ""
                     Read-Host "Presee another key to continue"
                     & "$env:userprofile\Downloads\main.ps1"

                }


             }

     }

}


function Pathfinder{

    $base_path= "$env:userprofile\Downloads\OneFS-image\"
    $dirs2= LocateRootDirectory $base_path 'ovf'
    $ovf_files= Searchfile $base_path 'ovf'
    $ovf_full_paths = Combine $dirs2 $ovf_files
    

    Write-Host 'Those following files you may choose to upload:'
    Write-Host ''
    $ovf_files
    Write-Host ''
    $choiceupload=Read-Host "Which OVF file you want to upload to VCenter"

    if([string]::IsNullOrWhitespace(($ovf_files | findstr $choiceupload))){
    
        while([string]::IsNullOrWhitespace(($ovf_files | findstr $choiceupload))){
        
            Write-Host 'Input Strings can not be found or mistyping, do it again!'
            Write-Host ''
            Write-Host 'Avaiable OVF files to upload:'
            $ovf_files
            Write-Host ''
            $choiceupload=Read-Host "Which OVF file(strictly match) you want to upload to VCenter?"        
        }
    }

    while ( !(($ovf_files | findstr $choiceupload).Trim() -eq $choiceupload )) {
    
        Write-Host 'Input Strings can not be found or mistyping, do it again!'
        Write-Host ''
        Write-Host 'Avaiable OVF files to upload:'
        $ovf_files
        Write-Host ''
        $choiceupload=Read-Host "Which OVF file(strictly match) you want to upload to VCenter?"
    
    }
    
    $global:ovf_file_fullpath=($ovf_full_paths | findstr $choiceupload).Trim()
    Write-Host ''

}



function Cachechecker{

    if  ( $global:VCenter -and $global:usr -and $global:passwd -and $global:VMHostIP -and $global:Location -and $global:Datastore ) { 

            Write-Host "##Escaping Already Configured Settings"
            Write-Host ""
            
    }
    
    else {

            Write-Host ""
            Connectvcenter
            Write-Host ""
            
    }
}


function IPInputchecker{

        Do{
		Write-Host 'Please ensure yourself put the right digits VCenter IP address!!!'
		$VCenter = Read-Host -Prompt "Input the VCenter Server IP [E for exit]"
		if ($VCenter -eq 'E') {exit}
		Write-Host ''
		} until( $VCenter -match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}" )

}


function Getinput($str){

    $str | Out-String
}


function Connectvcenter{

           Write-Host "###Connecting to VCenter Server"
           Write-Host "###You need to input some basic info before uploading VM"
           Write-Host ""  
           $global:VCenter = Read-Host "Please input the VCenter server name"
           $global:usr = Read-Host "Please input username"
           #$global:passwd = Read-Host "Please input password"
           $passwdtmp = Read-Host "Please input password" -AsSecureString
           $global:passwd = (New-Object PSCredential "user",$passwdtmp).GetNetworkCredential().Password

           try {
           Connect-VIServer $global:VCenter -User $global:usr -Password $global:passwd
           }
           catch { 
           Write-Host 'Connection issue. Please ensure you input the right username and passowd'
           $global:VCenter = Read-Host "Please input the VCenter server name"
           $global:usr = Read-Host "Please input username"
           #$global:passwd = Read-Host "Please input password"
           $passwdtmp = Read-Host "Please input password" -AsSecureString
           $global:passwd = (New-Object PSCredential "user",$passwdtmp).GetNetworkCredential().Password
           Connect-VIServer $global:VCenter -User $global:usr -Password $global:passwd
           }

           
}


function Getvcenterinfo{
            
           Write-Host ""
           #Get-VMHost | Select-Object Id,Name,PowerState,NumCpu,CpuUsageMhz,CpuTotalMhz,MemoryUsageGB,MemoryTotalGB | format-table -wrap -AutoSize
           Get-VMHost | Select-Object Name,CpuUsageMhz,CpuTotalMhz,MemoryUsageGB,MemoryTotalGB | format-table -wrap
           Write-Host ""
           Get-Datastore | format-table
           Write-Host ""
           Write-Host ""

}


function VMdeployparaset{
    
           if ( $global:VMHostIP ) {
           $tmp=$global:VMHostIP
           $global:VMHostIP = Read-Host "####Which Server you want to input your OVF to? [by default $global:VMHostIP ]"
           if($global:VMHostIP -eq $tmp -or [string]::IsNullOrWhitespace($global:VMHostIP)) {$global:VMHostIP=$tmp}
           }
           else {$global:VMHostIP = Read-Host "####Which Server you want to input your OVF to? [IP address please]"}
           
           $global:Location = Read-Host "#####Which Resource pool you want to put the file? [by default(My Repo) - YEW]"
           if($global:Location -eq "YEW" -or [string]::IsNullOrWhitespace($global:Location)) {$global:Location="YEW"} 

           $global:Datastore = Read-Host "######Which datastore you want to put the file? [by default - vmstore]"
           if($global:Datastore -eq "durvmstore" -or [string]::IsNullOrWhitespace($global:Datastore)) {$global:Datastore="vmstore"} 

}


function VMdeploy($ovf_full_path){

        #$ovf_dirs=Get-ChildItem -Path $base_path -recurse -filter *ovf | Select-Object Directory | findstr ':\' | findstr $OneFS ### duplicate function
        #$ovf_files=Get-ChildItem -Path $base_path -recurse -filter *ovf | Select-Object Name | findstr ovf | findstr $OneFS ### duplicate function
        #$prefix=$ovf_dirs.Trim()
        #$suffix_ovf=$ovf_files.Trim()

        #$ovf_full_path='{0}\{1}' -f ($prefix,$suffix_ovf)
        $global:Name=Read-Host "#######Please name your VM"
        Write-Host ''
        Write-Host ''
        try{
        Write-Host 'Uploading Now, please Wait...'
        Import-VApp -Name $global:Name -Datastore $global:Datastore -VMHost $global:VMHostIP -Source $global:ovf_file_fullpath -Location $global:Location
        } catch {
        Write-Host 'VM Name seems not correct, please retry.'
        $global:Name=Read-Host "#######Please name your VM"
        Import-VApp -Name $global:Name -Datastore $global:Datastore -VMHost $global:VMHostIP -Source $global:ovf_file_fullpath -Location $global:Location
        }

        Write-Host ''
        Write-Host ''
        if ($error.Count -eq 0){
        Write-Host 'All done buddy how happy you are :-)'  -foreground "green"}
        Write-Host ''
        Write-Host ''
        

        Read-Host "Please press Enter to Continue your download or upload"
        Write-Host ''
        Write-Host ''
        
        
        & "$env:userprofile\Downloads\main.ps1"

}


#################### The Web link that I referred ####################
###https://blah.cloud/virtualisation/deploying-ovaovf-remote-vcenter-using-ovftool (failed)
###https://blogs.vmware.com/vapp/2009/07/commandline-ovf-deployments.html (failed also)
###https://www.virtuallyghetto.com/2013/08/quick-tip-useful-ovftool-debugging.html 
###https://github.com/vmware/pyvmomi-community-samples/blob/master/samples/deploy_ova.py (will research on it)
###https://stackoverflow.com/questions/14406315/how-to-get-an-objects-propertys-value-by-property-name-in-powershell
###https://docs.microsoft.com/en-us/powershell/scripting/getting-started/cookbooks/using-format-commands-to-change-output-view?view=powershell-5.1
###https://technet.microsoft.com/es-es/library/dd347677.aspx
###http://www.virtu-al.net/2011/09/14/powershell-automated-install-of-vshield-5/
###http://www.neolisk.com/techblog/powershell-specialcharactersandtokens
###https://stackoverflow.com/questions/13738634/how-can-i-check-if-a-string-is-null-or-empty-in-powershell
###https://www.thomasmaurer.ch/2010/07/powershell-check-variable-for-null/
###