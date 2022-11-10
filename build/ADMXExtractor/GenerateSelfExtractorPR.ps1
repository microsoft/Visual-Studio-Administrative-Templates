<#
.SYNOPSIS
    Generates the self-extracting ADMXExtractor exe

.DESCRIPTION
    Zips up the admx and adml files, ADMXExtractor.exe using the box tool to create the self-extracting admin update exe.

.PARAMETER $ArtifactsDir
    The root artifact directory where the ADMXExtractor build was generated.
    e.g. $ArtifactsDir = $(Build.StagingDirectory)\$(projectName)\ 

.PARAMETER $RootDir
    The repo root directory.
    e.g. $RootDir = D:\Visual-Studio-Administrative-Templates

.PARAMETER $ArtifactFinalDropTarget
    The target path for where to output the finished ADMX Self-extracting exe.
    e.g. $ArtifactFinalDropTarget = D:\Visual-Studio-Administrative-Templates\artifacts\finaldrop

.PARAMETER $OutputNameWithExtension
    The final ADMX Self-extracting exe.
    e.g. $OutputNameWithExtension = VisualStudioAdministrativeTemplates.exe


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
    [string]$ArtifactsDropTarget,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputNameWithExtension
)

# helper functions
Function Set-RootForExecuteFile ($xml, $outputName)
{
    $executeFile = $xml.SelectNodes("/BoxCreate/ExecuteFile") | Select-Object -Index 0
    $executeFile.InnerText = $executeFile.InnerText.Replace("%root%", "$outputName")
}

Function Get-ZipArgs ($zipTarget) {
    $zipArgs = @()
    $zipArgs += "a"
    $zipArgs += "$zipTarget"
    # recursivly search the target folder
    $zipArgs += "-r"

    # no compression, extremely fast extract speed.
    $zipArgs += "-mx=0 -mmt=4"

    return $zipArgs
}

Function Get-BoxToolArgs ($boxManifestFilePath, $outputExeTarget, $boxstubTarget) {
    $boxtoolArgs = @()
    $boxtoolArgs += "-i"
    $boxtoolArgs += "$boxManifestFilePath"
    $boxtoolArgs += "-o"
    $boxtoolArgs += "$outputExeTarget"
    $boxtoolArgs += "-s"
    $boxtoolArgs += "$boxstubTarget"

    return $boxtoolArgs
}

Function Get-Id ($packageId, $xml) {
    $p = $xml.SelectNodes("/packages/package") | Where-Object { $_.id -eq "$packageId"} | Select-Object -Index 0
    return "$packageId" + "\" + $p.version.ToString()
}
# end helper functions

# RootDir: D:\Visual-Studio-Administrative-Templates\   
# ArtifactsDir: $(Build.StagingDirectory)\ADMXExtractor
# RootTarget: $(Build.StagingDirectory)\drop
$admxPath = [System.IO.Path]::Combine($ArtifactsDir, "admx")
$testResult = Test-Path $admxPath
Write-Verbose "admx path exists: $testResult"

# At this point in the script, ArtifactsDir has:
# admx\
# ADMXExtractor.exe
# ADMXExtractor.exe.config

Write-Verbose "ArtifactsDir: $ArtifactsDir"
Write-Verbose "RootDir: $RootDir"
Write-Verbose "ArtifactsDropTarget: $ArtifactsDropTarget"
Write-Verbose "OutputNameWithExtension: $OutputNameWithExtension"

# get tool root locations
$nugetPkgsConfig = [System.IO.Path]::Combine($RootDir, "packages.config")
$nugetPkgsConfigXml = [xml](Get-Content $nugetPkgsConfig)
$bootstrapperToolId = Get-Id "VS.Setup.BootstrapperExternals" $nugetPkgsConfigXml
$bootstrapperToolRoot = [System.IO.Path]::Combine($RootDir, "packages", $bootstrapperToolId, "externals")
Write-Verbose "Bootstrapper externals tool root: $bootstrapperToolRoot"

# zip up contents of $ArtifactsDir to D:\Visual-Studio-Administrative-Templates\artifacts\admx.7z
$zipToolRoot = [System.IO.Path]::Combine($bootstrapperToolRoot, "7z")
Write-Verbose "7z tool root: $zipToolRoot"

$zipTool = [System.IO.Path]::Combine($zipToolRoot, "7z.exe")
$zipFileToDropInArtifactsDirectory = [System.IO.Path]::Combine($ArtifactsDir, "admx.7z")
$ArtifactsDirFullPath = [System.IO.Path]::Combine($RootDir, $ArtifactsDir)
$zipArgs = Get-ZipArgs $zipFileToDropInArtifactsDirectory

Write-Verbose "Calling Zip tool: $zipTool"
Write-Verbose "Argument List: $zipArgs"

Write-Verbose "Directory of files to zip:  $ArtifactsDirFullPath"
Write-Verbose "Zip file to drop in artifact directory: $zipFileToDropInArtifactsDirectory"

# To prevent 7-Zip from adding the directory structure $ArtifactsDirFullPath, cd to the location

$currentDirectory = Get-Location
Write-Verbose "cd to $ArtifactsDirFullPath"
Set-Location -Path $ArtifactsDirFullPath
$zipRun = Start-Process -FilePath $zipTool -ArgumentList $zipArgs -PassThru -Wait
if ($zipRun.ExitCode -ne 0)
{
    Write-Verbose "Failed to zip the directory of admx files: $ArtifactsDirFullPath."
    Remove-Item -Recurse -Force $ArtifactsDir
    exit 1
}

# cd back to root dir
Write-Verbose "cd to $currentDirectory"
Set-Location -Path $currentDirectory

# At this point in the script, ArtifactsDir has:
# admx\
# ADMXExtractor.exe
# ADMXExtractor.exe.config
# admx.7z

# Replace the %root% token with the location of the ADMXInstaller.exe in box_manifest.xml
$boxManifestSource = [System.IO.Path]::Combine($RootDir, "build", "ADMXExtractor", "box_manifest.xml")
$manifestContentXml = [xml](Get-Content $boxManifestSource)
# Set-RootForExecuteFile $manifestContentXml $ArtifactsDir

# copy the box_manifest.xml to $ArtifactsDir
$boxManifestTarget = [System.IO.Path]::Combine($ArtifactsDir, "box_manifest.xml")
$manifestContentXml.Save("$boxManifestTarget")

# At this point in the script, ArtifactsDir has:
# admx\
# ADMXExtractor.exe
# ADMXExtractor.exe.config
# admx.7z
# box_manifest.xml

# Copy the BoxStub.exe to the ArtifactFinalDropTarget

$boxstubSource = [System.IO.Path]::Combine($bootstrapperToolRoot, "box", "boxstub.exe")
$boxstubTarget = [System.IO.Path]::Combine($ArtifactsDir, "boxstub.exe")
Copy-Item $boxstubSource -Destination $boxstubTarget

# boxManifestTarget = $ArtifactsDir\box_manifest.xml
# outputExeTarget = $ArtifactsDropTarget\VisualStudioAdminTemplates.exe
$outputExeTarget = [System.IO.Path]::Combine($ArtifactsDropTarget, $OutputNameWithExtension)
$boxToolPath = [System.IO.Path]::Combine($bootstrapperToolRoot, "box", "boxtool.exe")
$boxtoolArgs = Get-BoxToolArgs $boxManifestTarget $outputExeTarget $boxstubTarget

Write-Verbose "Calling BoxTool: $boxToolPath"
Write-Verbose "Argument List: $boxtoolArgs"

$boxtoolRun = Start-Process -FilePath $boxToolPath -ArgumentList $boxtoolArgs -PassThru -Wait
if ($boxtoolRun.ExitCode -ne 0)
{
    Write-Verbose 'BoxTool failed.'
    Remove-Item -Recurse -Force $TempDirectory
    exit 1
}
