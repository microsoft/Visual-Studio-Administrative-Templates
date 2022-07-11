<#
.SYNOPSIS
    Generates the self-extracting ADMXExtractor exe

.DESCRIPTION
    Zips up the admx and adml files, ADMXExtractor.exe using the box tool to create the self-extracting admin update exe.

.PARAMETER $ArtifactsDir
    The root artifact directory where the ADMXExtractor build is located.
    e.g. $ArtifactsDir = D:\Visual-Studio-Administrative-Templates\src\ADMXExtractor

.PARAMETER $RootDir
    The repo root directory.
    e.g. $RootDir = D:\Visual-Studio-Administrative-Templates

.PARAMETER $RootTarget
    The target path for where to output the finished ADMX Self-extracting exe.
    e.g. $RootTarget


Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "a", "D:\Visual-Studio-Administrative-Templates\artifacts\admx.7z", "-r", "D:\Visual-Studio-Administrative-Templates\artifacts\ADMXExtractor", "-mx=0 -mmt=4" 

# Calling BoxTool 
$boxtoolRun = Start-Process -FilePath "D:\Visual-Studio-Administrative-Templates\artifacts\boxtool.exe" -ArgumentList "-i", "D:\Visual-Studio-Administrative-Templates\artifacts\box_manifest.xml", "-o", "D:\Visual-Studio-Administrative-Templates\artifacts\VisualStudioTemplates.exe", "-s", "D:\Visual-Studio-Administrative-Templates\artifacts\boxstub.exe" -PassThru -Wait
if ($boxtoolRun.ExitCode -ne 0)
{
    Write-Verbose 'BoxTool failed with exit code $boxtoolRun.ExitCode.'
    exit 1
}

#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ArtifactsDir,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$RootDir,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$RootTarget,
)

# helper functions
Function Set-RootForExecuteFile ($xml, $outputName)
{
    $executeFile = $xml.SelectNodes("/BoxCreate/ExecuteFile") | Select-Object -Index 0
    $executeFile.InnerText = $executeFile.InnerText.Replace("%root%", "$outputName")
}

Function Get-ZipArgs ($directoryOfFilesToZip, $zipTarget) {
    $zipArgs = @()
    $zipArgs += "a"
    $zipArgs += "$zipTarget"
    # recursivly search the target folder
    $zipArgs += "-r $directoryOfFilesToZip"

    # no compression, extremely fast extract speed.
    $zipArgs += "-mx=0 -mmt=4"

    return $zipArgs
}

Function Get-BoxToolArgs ($boxManifestTarget, $outputExeTarget, $boxstubTarget) {
    $boxtoolArgs = @()
    $boxtoolArgs += "-i"
    $boxtoolArgs += "$boxManifestTarget"
    $boxtoolArgs += "-o"
    $boxtoolArgs += "$outputExeTarget"
    $boxtoolArgs += "-s"
    $boxtoolArgs += "$boxstubTarget"

    return $boxtoolArgs
}

Function Get-Id ($packageId, $xml) {
    $p = $xml.SelectNodes("/packages/package") | Where-Object { $_.id -eq "$packageId"} | Select-Object -Index 0
    return "$packageId" + "." + $p.version.ToString()
}
# end helper functions


# RootDir: D:\Visual-Studio-Administrative-Templates\   
# ArtifactsDir: $(Build.StagingDirectory)\ADMXExtractor
# RootTarget: $(Build.StagingDirectory)\drop


$outputName = "VisualStudioAdminTemplates"
$outputNameWithExtension = $outputName + ".exe"

# get tool root locations
$scriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition  # The root directory of this script
$nugetPkgsConfig = [System.IO.Path]::Combine($scriptRoot, "packages.config")
$nugetPkgsConfigXml = [xml](Get-Content $nugetPkgsConfig)
$bootstrapperToolId = Get-Id "VS.Setup.BootstrapperExternals" $nugetPkgsConfigXml
$bootstrapperToolRoot = [System.IO.Path]::Combine($RootDir, "packages", $bootstrapperToolId, "externals")

Write-Verbose "Bootstrapper externals tool root: $bootstrapperToolRoot"

# zip up admx contents to D:\Visual-Studio-Administrative-Templates\artifacts\admx.7z
$zipTool = [System.IO.Path]::Combine($bootstrapperToolRoot, "7z", "7z.exe")
$directoryOfFilesToZip = [System.IO.Path]::Combine($ArtifactsDir, "admx", "*.*")
$zipDropDirectory = [System.IO.Path]::Combine($ArtifactsDir, "admx.7z")
$zipArgs = Get-ZipArgs $directoryOfFilesToZip $zipDropDirectory

Write-Verbose "Calling Zip tool: $zipTool"
Write-Verbose "Directory of files to zip:  $directoryOfFilesToZip"
Write-Verbose "Drop directory: $zipDropDirectory"
Write-Verbose "Argument List: $zipArgs"

$zipRun = Start-Process -FilePath $zipTool -ArgumentList $zipArgs -PassThru -Wait
if ($zipRun.ExitCode -ne 0)
{
    Write-Verbose 'Failed to zip the directory of admx files: $directoryOfFilesToZip.'
    Remove-Item -Recurse -Force $TempDirectory
    exit 1
}

# prepare and copy box_manifest.xml
$boxManifestSource = [System.IO.Path]::Combine($RootDir, "build", "ADMXExtractor", "box_manifest.xml")
$boxManifestTarget = [System.IO.Path]::Combine($artifacts, "box_manifest.xml")
$manifestContentXml = [xml](Get-Content $boxManifestSource)
Set-RootForExecuteFile $manifestContentXml $outputName
$manifestContentXml.Save("$boxManifestTarget")

# box zipped item
$admxExtractorTargetRoot = $RootTarget
$outputExeTarget = [System.IO.Path]::Combine($admxExtractorTargetRoot, $outputNameWithExtension)
$boxstubSource = [System.IO.Path]::Combine($bootstrapperToolRoot, "box", "boxstub.exe")
$boxstubTarget = [System.IO.Path]::Combine($admxExtractorTargetRoot, "boxstub.exe")
Copy-Item $boxstubSource -Destination $boxstubTarget

$boxtoolTool = [System.IO.Path]::Combine($bootstrapperToolRoot, "box", "boxtool.exe")
$boxtoolArgs = Get-BoxToolArgs $boxManifestTarget $outputExeTarget $boxstubTarget

Write-Verbose "Calling BoxTool: $boxtoolTool"
Write-Verbose "Argument List: $boxtoolArgs"

$boxtoolRun = Start-Process -FilePath $boxtoolTool -ArgumentList $boxtoolArgs -PassThru -Wait
if ($boxtoolRun.ExitCode -ne 0)
{
    Write-Verbose 'BoxTool failed.'
    Remove-Item -Recurse -Force $TempDirectory
    exit 1
}
