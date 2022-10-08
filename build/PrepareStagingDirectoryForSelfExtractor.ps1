﻿    <#
.SYNOPSIS
    Generates the self-extracting ADMXExtractor exe

.DESCRIPTION
    Zips up the admx and adml files, ADMXExtractor.exe using the box tool to create the self-extracting admin update exe.

.PARAMETER $ArtifactsDir
    The root artifact directory where the ADMXExtractor build was generated.
    e.g. $ArtifactsDir = $(Build.StagingDirectory)\$(projectName)\

.PARAMETER $IntermediateDropPath
    The artifact directory where the ADMXExtractor build with localized files should be generated.
    e.g. $ArtifactsDir = $(Build.StagingDirectory)\$(projectName)\intermediate
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ArtifactsDir,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$IntermediateDropPath
)

# Map the Microbuild Language outputs to the OS CultureInfo codes.
$languageTable = [ordered]@{
    CHS="cn";
    CHT="zh";
    CSY="cs";
    DEU="de";
    ENU="en";
    ESN="es";
    FRA="fr";
    ITA="it";
    JPN="ja";
    KOR="ko";
    PLK="pl";
    PTB="pt";
    RUS="ru";
    TRK="tr";
}

$exeFilesToCopy = @( "ADMXExtractor.exe", "ADMXExtractor.exe.config" )
$visualStudioAdmx = "VisualStudio.admx"
$visualStudioAdml = "VisualStudio.adml"
$ADMXExtractorResourcesFile = "ADMXExtractor.resources.dll"

foreach ($key in $languageTable.Keys)
{
    $value = $languageTable[$key]
    
    # Create each of the language folders in the IntermediateDrop folder.
    # $(IntermediateDrop)\{LanguageTable.Value}
    $path = [System.IO.Path]::Combine($IntermediateDropPath, $value)
    New-Item -Path $path -ItemType Directory -Force
    Write-Verbose "Created path: $path"

    # Copy the resource files from each of the build language folders to the intermediate drop except ENU which is handled below.
    # $source: $(Build.StagingDirectory)\AdmxExtractor\localize\{LanguageTable.Key}\ADMXExtractor.resources.dll
    # $destination: $(IntermediateDrop)\{LanguageTable.Value}\ADMXExtractor.resources.dll
    if ($key -ne "ENU") 
    {    
        $source = [System.IO.Path]::Combine($ArtifactsDir, "localize", $key, $ADMXExtractorResourcesFile)
        $destination = [System.IO.Path]::Combine($path, $ADMXExtractorResourcesFile)
        Write-Verbose "Copying $ADMXExtractorResourcesFile from $source to $destination."
        Copy-Item -Path $source -Destination $destination
    }

    # Create each of the ADMX template language folders in Intermediate\admx to copy the .adml files.
    # $(IntermediateDrop)\admx\{LanguageTable.Value}
    $path = [System.IO.Path]::Combine($IntermediateDropPath, "admx", $value)
    New-Item -Path $path -ItemType Directory -Force
    Write-Verbose "Created path: $path"

    # Copy the .adml files for all languages except ENU which is handled separately below.
    # $(Build.StagingDirectory)\AdmxExtractor\localize\{LanguageTable.Key}\admx\VisualStudio.adml
    # To$(IntermediateDrop)\admx\{LanguageTable.Value}\VisualSTudio.adml
    if ($key -ne "ENU") 
    {
        $source = [System.IO.Path]::Combine($ArtifactsDir, "localize", $key, "admx", $visualStudioAdml)
        $destination = [System.IO.Path]::Combine($IntermediateDropPath, "admx", $value, $visualStudioAdml)
        Write-Verbose "Copying $visualStudioAdml from $source to $destination."
        Copy-Item -Path $source -Destination $destination
    }
}

# Copy the exe and config file to the intermediate drop to be staged for consumption by the boxtool.
foreach ($file in $exeFilesToCopy)
{
    $source = [System.IO.Path]::Combine($ArtifactsDir, $file)
    $destination = [System.IO.Path]::Combine($IntermediateDropPath, $file)
    Write-Verbose "Copying $file from $source to $destination."
    Copy-Item -Path $source -Destination $destination
}

# Special handling to copy the en-us admx and adml files because they are not localized.
$source = [System.IO.Path]::Combine($ArtifactsDir, "admx", $visualStudioAdmx)
$destination = [System.IO.Path]::Combine($IntermediateDropPath, "admx", $visualStudioAdmx)
Write-Verbose "Copying $file from $source to $destination."
Copy-Item -Path $source -Destination $destination

$source = [System.IO.Path]::Combine($ArtifactsDir, "admx", $visualStudioAdml)
$destination = [System.IO.Path]::Combine($IntermediateDropPath, "admx", "en", $visualStudioAdml)
Write-Verbose "Copying $file from $source to $destination."
Copy-Item -Path $source -Destination $destination