<#   
 ======================================= windows-operations.ps1 ======================================= 
================================================================================ 
 Name: windows-operations.ps1
 Purpose: Automated OneFS VM download, unzip and OVA to OVF conversion using PowerShell. 
 Description: Demonstrates downloading files from an Isilon  Website but same process works for any valid online URL. 
 Author: Chen Ye
 Email: chen.winfield.ye@gmail.com
 Syntax/Execution: Copy the scripts and paste into your user profile Downloads folder and execute main.ps1
 Disclaimer: Use at your own Risk!
 Limitations:  
         * Must Run PowerShell (or ISE)  
 ================================================================================ 
#> 


function Inputchecker($str)
{
	if ($str -like '*onefs*') {
		Do{
		Write-Host 'Please ensure yourself put the right digits of OneFS version!!!'
		$OneFS = Read-Host -Prompt "Input the OneFS version want to download [format x.x.x.x E for exit]"
		if ($OneFS -eq 'E') {exit}
		Write-Host ''
		} until( $OneFS -match "\d{1,1}\.\d{1,1}\.\d{1,1}\.\d{1,1}" )
		$OneFS
		$url='http://urlpath.isilon2.com/releases/release-' + $OneFS + '/EMC_Isilon_OneFS_' + $OneFS + '_Simulator.zip'
		$url
	}

	elseif ($str -like '*insightiq*') {
		Do{
		Write-Host ''
		Write-Host 'Current Avaiable InsightIQ version to download:'
		$web=Invoke-WebRequest http://urlpath.isilon2.com/releases/insightiq/
		$output=$web.ToString() -split "[`r`n]" | findstr /v beta | findstr /v /I preview | findstr InsightIQ | %{ $_.Split('"')[5]; } | %{$_ -replace "/",""}
        Write-Host $output -Separator "`n"
        Write-Host ''

        Write-Host 'Please ensure yourself put the right digits of InsightIQ version!!!'		
        $InsightIQ = Read-Host -Prompt "Input the InsightIQ version want to download [format x.x.x.xxxx E for exit]"
		
		if ($InsightIQ -eq 'E') {exit}
		Write-Host ''
		} until( $InsightIQ -match "\d{1,1}\.\d{1,1}\.\d{1,1}\.\d{4,4}" )
		
        $url= 'http://urlpath.isilon2.com/releases/insightiq/InsightIQ_v' + $InsightIQ + '/'
        $webnew= Invoke-WebRequest $url
        $outputfile= $webnew.ToString() -split "[`r`n]" | findstr /v beta | findstr /v /I preview | findstr InsightIQ | %{ $_.Split('"')[5]; } | %{$_ -replace "/",""} | findstr -v md5 | findstr ova 

        $urlfull= 'http://urlpath.isilon2.com/releases/insightiq/InsightIQ_v' + $InsightIQ + '/' + $outputfile
        $InsightIQ		
        $urlfull
	}

	else {
		Write-Host 'You input a string was neither "onefs" or "insightiq", although this checker ignore case sensitive and it tried best, pls input again!!!'
		Do{
		$str = Read-Host -Prompt 'Make Sure you input "InsightIQ" or "OneFS" string'
		}
		until( $str -like '*insightiq*' -or  $str -like '*onefs*' )
		Inputchecker $str											
	} 

}


Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}


function LocateRootDirectory($base_path, $extension)
{
    $dirs = Get-ChildItem -Path $base_path -recurse -filter *$extension | Select-Object Directory | findstr ':\'

    return $dirs
}


function Searchfile($base_path, $extension)
{
    
    if ($extension -eq 'ova' ){
    $files= Get-ChildItem -Path $base_path -recurse -filter *$extension | Select-Object Name | findstr $extension
    }

    elseif ($extension -eq 'ovf' ) {
    $files= Get-ChildItem -Path $base_path -recurse -filter *$extension | Select-Object Name | findstr $extension | %{$_ -replace "ova","ovf"}
    }

    elseif ($extension -eq 'vmx' ) {
    $files= Get-ChildItem -Path $base_path -recurse -filter *$extension | Select-Object Name | findstr $extension
    }

    return $files
}


function A2F($files)
{
    $ovffiles= $files | %{$_ -replace "ova","ovf"}

    return $ovffiles
}


function Combine($dirs, $files)
{
    $fcount=$dirs.Count
    #$fcount

    if ($fcount -eq 1){

     $prefix=$dirs.Trim()
     $suffix_file=$files.Trim()
     $file_full_path='{0}\{1}' -f ($prefix,$suffix_file)
     $file_full_path
          
     $fcount--;
         
    }

  
    while ($fcount -ge 1){
       
       $fcount--;
                
       $prefixes=$dirs.Item($fcount).Trim()
       $suffix_files=$files.Item($fcount).Trim()
       $files_full_path='{0}\{1}' -f ($prefixes,$suffix_files)
       $files_full_path
    }

}


function OVA2OVF ($ova_full_path,$ovf_full_path){

    & "C:\Program Files (x86)\VMware\Client Integration Plug-in 5.5\ovftool\ovftool.exe" $ova_full_path $ovf_full_path;

}

function OVA2OVF2 ($ova_full_path,$ovf_full_path){

    & "C:\Program Files\VMware\VMware OVF Tool\ovftool.exe" $ova_full_path $ovf_full_path;

}


###
### https://stackoverflow.com/questions/9420983/powershell-argument-passing-to-function-seemingly-not-working
### 
### In powershell realm, if you want to call a function with special character, instead of function($a,$b..)
### need to call like this "function $a $b"
### 
### 
### 
