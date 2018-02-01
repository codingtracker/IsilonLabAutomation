
<#   
 ======================================= main.ps1 ======================================= 
================================================================================ 
 Name: main.ps1
 Purpose: Automated OneFS VM download, unzip and OVA to OVF conversion using PowerShell. 
 Description: Demonstrates downloading files from an Isilon  Website but same process works for any valid online URL. 
 Author: Chen Ye
 Email: chen.winfield.ye@gmail.com
 Syntax/Execution: Copy the scripts  and paste into your user profile Downloads folder and execute main.ps1
 Disclaimer: Use at your own Risk!
 Limitations:  
         * Must Run PowerShell (or ISE)  
 ================================================================================ 
#> 


. "$env:userprofile\Downloads\windows-operations.ps1"
. "$env:userprofile\Downloads\vm-operations.ps1"


$Date = Get-Date

Write-Host 'Hi Buddy, How are you today(' $Date ') ?'
Write-Host 'I am a downloader helping you retrieve the OneFS image from buildbox, all steps are automated, so cool right'
Write-Host 'Lets begin :-)'
Write-Host ''


$str = Read-Host -Prompt 'You want to download "OneFS" or "InsightIQ" or "Upload"(ovf files) ?'
if ( $str -eq 'Upload') {

Modulechecker

Pathfinder
	

    Cachechecker

    Getvcenterinfo
    VMdeployparaset

    VMdeploy $global:ovf_file_fullpath
    
}

$softver = Inputchecker $str
if ( $softver.count -gt 2) {

    $num = $softver.count
    $version= $softver[$num-2]
    $url= $softver[$num-1]
    #$version
    #$url
}
else {
    $version= $softver[0]
    $url= $softver[1]
    $path= $base_path + 'EMC_Isilon_OneFS_' + $version + '_Simulator.zip'
    #$version
    #$url

}


$client= New-Object system.net.webclient
echo "#Complete Downloader Initilization"
Write-Host ''


echo "##Accessing $str $version path###"
echo "The image you pretend to download is $version"
echo "You may also find the URL for this image for your reference $url"
Write-Host ''


$base_path= "$env:userprofile\Downloads\OneFS-image\"
echo "###Set local path to $base_path"
if (!(Test-Path $base_path)){ md $base_path | findstr OneFS }
Write-Host ''


echo "####Creating Directory"
if ($str -like "*insightiq*"){ 

    New-Item -Path $base_path -Name $version -ItemType Directory -force | Select -ExpandProperty Name 
    $output= 'Creating InsightIQ directory ' + $base_path + '' + $version
    $path= $base_path + '' + $version + '\' + 'InsightIQ_v' + $version + '.ova'
    $output

} 
#ni $base_path -Name $OneFS -ItemType directory
#$dirpath=$base_path+$OneFS



Write-Host ''


echo "#####Start downloading the file"
Write-Host ''

 try{
        $client.DownloadFile($url,$path)
 }

 catch  {
        $url='http://urlpath.isilon2.com/releases/release-' + $version + '/' + $version + '_Virtual_Isilon.zip'
        $client.DownloadFile($url,$path)
 }

Write-Host "######Downloading complete"
Write-Host ''


echo "#######Start Unzipping the file"
if ($str -like "*insightiq*"){ 

    Write-Host 'OVA file no need to unzip'
}

else{

    try{
        Unzip $path $base_path
        echo "########Complete Unzipping the file"
    }

    catch{
        Write-Host 'File already been unzipped'
        echo "########Complete Unzipping the file"      
    }
}


Write-Host ''


echo "#########Searching for OVA files"
$dirs= LocateRootDirectory $base_path 'ova'
$ova_files= Searchfile $base_path 'ova'
#$ovf_files=A2F $base_path 'ova'
Write-Host ''


echo "##########Dumping OVA files' location"
$dirs
Write-Host ''


echo "###########Exce conversion from OVA to OVF"
$ova_full_paths = Combine $dirs $ova_files
#$ovf_full_paths= Combine $dirs, $ovf_files

if ([System.IO.File]::Exists("C:\Program Files (x86)\VMware\Client Integration Plug-in 5.5\ovftool\ovftool.exe")){

    foreach ($ova_full_path in $ova_full_paths){
        $ovf_full_path= A2F($ova_full_path)
        OVA2OVF $ova_full_path $ovf_full_path
        #& "C:\Program Files (x86)\VMware\Client Integration Plug-in 5.5\ovftool\ovftool.exe" $ova_full_path $ovf_full_path
       
    }

    Write-Host "###########Exce conversion from OVA to OVF complete :-)" -foreground "green"
    Write-Host ''

}

elseif ([System.IO.File]::Exists("C:\Program Files\VMware\VMware OVF Tool\ovftool.exe")) {

    foreach ($ova_full_path in $ova_full_paths){
        $ovf_full_path= A2F($ova_full_path)
        OVA2OVF2 $ova_full_path $ovf_full_path
    }

    Write-Host "###########Exce conversion from OVA to OVF complete :-)" -foreground "green"
    Write-Host ''

}

else{

        Write-Host "There is no ova conversion tools in you machine, please download and install to the default path to use this feature." -foreground "magenta"
        Write-Host "Official Website to download is https://my.vmware.com/web/vmware/details?productId=352&downloadGroup=OVFTOOL350" -foreground "magenta"
}




Write-Host ''
Write-Host ''

#$Operation = Read-Host -Prompt "Please press Enter to Continue"
Write-Host ''

$choice=Read-Host "Do you want to upload this Image file $version to VCenter? [Y]"
if($choice -eq "Y" -or [string]::IsNullOrWhitespace($choice)) {$choice="Y"}

if ($choice -eq "Y") {
    
    if ((LocateRootDirectory $base_path 'ovf' | findstr $version).length -eq 0) {
    
        Write-Host ""
        Write-Host "It seems I could find ovf file for your version $version, please use following example format command to convert." -foreground "magenta"
        Write-Host ""
        Write-Host "ovftool.exe [original .vmx location and filename] [new .ova location and filename]" -foreground "magenta"
        Write-Host ""
        Write-Host 'Example: "C:\Program Files\VMware\VMware OVF Tool\ovftool.exe" "C:\Users\xxx\Downloads\OneFS-image\xxx\xxx.vmx" "C:\Users\xxx\Downloads\OneFS-image\xxx\xxx.ovf"' -foreground "magenta"
        Write-Host ""
        Read-Host "Presee another key to continue"
        & "$env:userprofile\Downloads\main.ps1"
    
    }
    
    Modulechecker
    Cachechecker

    Getvcenterinfo
    VMdeployparaset

    $dirs2= LocateRootDirectory $base_path 'ovf'
    $ovf_files= Searchfile $base_path 'ovf'
    $ovf_full_paths = Combine $dirs2 $ovf_files
    $global:ovf_file_fullpath=($ovf_full_paths | findstr $version).Trim()

    VMdeploy $global:ovf_file_fullpath

}

else { 
    $choice2=Read-Host "Do you want to upload other OVF file(s) to VCenter? [Y]"
    if($choice2 -eq "Y" -or [string]::IsNullOrWhitespace($choice2)) {$choice2="Y"}
    if ($choice2 -eq "Y") {

    Modulechecker
    

    $dirs2= LocateRootDirectory $base_path 'ovf'
    $ovf_files= Searchfile $base_path 'ovf'
    $ovf_full_paths = Combine $dirs2 $ovf_files
    
    Write-Host 'Those following files you may choose to upload:'
    Write-Host ''
    $ovf_files
    Write-Host ''
    Write-Host ''
    $choice3=Read-Host "Which OVF file you want to upload to VCenter?"

    if([string]::IsNullOrWhitespace(($ovf_files | findstr $choice3))){
    
        while([string]::IsNullOrWhitespace(($ovf_files | findstr $choice3))){
        
            Write-Host 'Input Strings can not be found or mistyping, do it again!'
            Write-Host ''
            Write-Host 'Avaiable OVF files to upload:'
            $ovf_files
            Write-Host ''
            Write-Host ''
            $choice3=Read-Host "Which OVF file(strictly match) you want to upload to VCenter?"        
        }
    }

    while ( !(($ovf_files | findstr $choice3).Trim() -eq $choice3 )) {
    
        Write-Host 'Input Strings can not be found or mistyping, do it again!'
        Write-Host ''
        Write-Host 'Avaiable OVF files to upload:'
        $ovf_files
        Write-Host ''
        Write-Host ''
        $choice3=Read-Host "Which OVF file(strictly match) you want to upload to VCenter?"
    
    }
    
    $global:ovf_file_fullpath=($ovf_full_paths | findstr $choice3).Trim()
    Write-Host ''
    Write-Host 'Start to connect to VCenter now:'
    
    Cachechecker

    Getvcenterinfo
    VMdeployparaset
    VMdeploy $global:ovf_file_fullpath

       
    }
    
    else{
            Read-Host "Please press Enter to Continue"
            Write-Host ''
            Write-Host ''
            Write-Host ''
            & "$env:userprofile\Downloads\main.ps1"
            
        }

}


#$VCenter = Read-Host "Please input the VCenter server name"
#$usr = Read-Host "Please input username"
#$passwd = Read-Host "Please input password"

#Connectvcenter $VCenter $usr $passwd




### 
### https://blogs.technet.microsoft.com/heyscriptingguy/2010/08/10/how-to-reuse-windows-powershell-functions-in-scripts/
### http://www.tomsitpro.com/articles/powershell-for-loop,2-845.html
### http://www.pstips.net/powershell-foreach-loop.html
### 

### 
### https://blogs.technet.microsoft.com/heyscriptingguy/2014/07/18/trim-your-strings-with-powershell/
### 
### PS C:\Users\wye\Desktop> $testa='8.1.0.1.ovf'
### PS C:\Users\wye\Desktop> "8.1.0.1.ovf" -eq $testa
### True
### PS C:\Users\wye\Desktop> $choice3
### 8.1.0.1.ovf
### PS C:\Users\wye\Desktop> $choice3 -eq $testa
### True
### PS C:\Users\wye\Desktop> ($ovf_files | findstr $choice3) -eq $testa
### False
### PS C:\Users\wye\Desktop> $ovf_files | findstr $choice3
### 8.1.0.1.ovf                                                
### PS C:\Users\wye\Desktop> ($ovf_files | findstr $choice3).Trim() -eq $choice3
### True
###
### 

############################Documents That I referred############################
#https://superuser.com/questions/362152/native-alternative-to-wget-in-windows-powershell
#https://kevinmarquette.github.io/2017-01-13-powershell-variable-substitution-in-strings
#http://windows-powershell-scripts.blogspot.com/2009/06/awk-equivalent-in-windows-powershell.html
#https://stackoverflow.com/questions/2022326/terminating-a-script-in-powershell
#https://stackoverflow.com/questions/27768303/how-to-unzip-a-file-in-powershell
#https://stackoverflow.com/questions/20706869/powershell-is-missing-the-terminator
#https://blogs.msdn.microsoft.com/zainnab/2007/07/08/grep-and-sed-with-powershell/
