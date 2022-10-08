    <#
.SYNOPSIS
    Generates the self-extracting ADMXExtractor exe

.DESCRIPTION
    Zips up the admx and adml files, ADMXExtractor.exe using the box tool to create the self-extracting admin update exe.

.PARAMETER $ArtifactsDir
    The root artifact directory where the ADMXExtractor build was generated.
    e.g. $ArtifactsDir = $(Build.StagingDirectory)\$(projectName)\ 


#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ArtifactsDir
)

# Map the Microbuild Language outputs to the OS CultureInfo codes.
$languageTable = [ordered]@{
    CHS="zh-hans";
    CHT="zh-hant";
    CSY="cs-cz";
    DEU="de-de";
    ENU="en-us";
    ESN="es-es";
    FRA="fr-fr";
    ITA="it-it";
    JPN="ja-jp";
    KOR="ko-kr";
    PLK="pl-pl";
    PTB="pt-pt";
    RUS="ru-ru";
    TRK="tr-tr";
}

$ArtifactsDir = "C:\Users\edskrod\OneDrive - Microsoft\Desktop\ADMXExtractor" 
$exeFilesToCopy = @( "ADMXExtractor.exe", "ADMXExtractor.exe.config" )
$visualStudioAdmx = "VisualStudio.admx"
$visualStudioAdml = "VisualStudio.adml"
$ADMXExtractorResourcesFile = "ADMXExtractor.resources.dll"
$intermediateDropPath = Join-Path -Path $ArtifactsDir -ChildPath "Intermediate"

foreach ($key in $languageTable.Keys)
{
    $value = $languageTable[$key]
    
    # Create each of the language folders in the IntermediateDrop folder.
    # $(IntermediateDrop)\{LanguageTable.Value}
    $path = [System.IO.Path]::Combine($intermediateDropPath, $value)
    New-Item -Path $path -ItemType Directory -Force
    Write-Output "Created path: $path"

    # Copy the resource files from each of the build language folders to the intermediate drop
    # $source: $(Build.StagingDirectory)\AdmxExtractor\localize\{LanguageTable.Key}\ADMXExtractor.resources.dll
    # $destination: $(IntermediateDrop)\{LanguageTable.Value}\ADMXExtractor.resources.dll
    $source = [System.IO.Path]::Combine($ArtifactsDir, "localize", $key, $ADMXExtractorResourcesFile)
    $destination = [System.IO.Path]::Combine($path, $ADMXExtractorResourcesFile)
    Write-Output "Copying $ADMXExtractorResourcesFile from $source to $destination."
    Copy-Item -Path $source -Destination $destination


    # Create each of the ADMX template language folders in Intermediate\admx to copy the .adml files.
    # $(IntermediateDrop)\admx\{LanguageTable.Value}
    $path = [System.IO.Path]::Combine($intermediateDropPath, "admx", $value)
    New-Item -Path $path -ItemType Directory -Force
    Write-Output "Created path: $path"

    # Copy the .adml files
    # $(Build.StagingDirectory)\AdmxExtractor\localize\{LanguageTable.Key}\admx\en-US\VisualStudio.adml
    # To$(IntermediateDrop)\admx\{LanguageTable.Value}\VisualSTudio.adml
    $source = [System.IO.Path]::Combine($ArtifactsDir, "localize", $key, "admx", "en-us", $visualStudioAdml)
    $destination = [System.IO.Path]::Combine($intermediateDropPath, "admx", $value, $visualStudioAdml)
    Write-Output "Copying $visualStudioAdml from $source to $destination."
    Copy-Item -Path $source -Destination $destination

}

# Copy the exe and config file to the intermediate drop to be staged for consumption by the boxtool.
foreach ($file in $exeFilesToCopy)
{
    $source = [System.IO.Path]::Combine($ArtifactsDir, $file)
    $destination = [System.IO.Path]::Combine($intermediateDropPath, $file)
    Write-Output "Copying $file from $source to $destination."
    Copy-Item -Path $source -Destination $destination
}

# Special handling to copy the en-us admx and adml files because they are not localized.
$source = [System.IO.Path]::Combine($ArtifactsDir, "admx", $visualStudioAdmx)
$destination = [System.IO.Path]::Combine($intermediateDropPath, "admx", $visualStudioAdmx)
Write-Output "Copying $file from $source to $destination."
Copy-Item -Path $source -Destination $destination

$source = [System.IO.Path]::Combine($ArtifactsDir, "admx", "en-us", $visualStudioAdml)
$destination = [System.IO.Path]::Combine($intermediateDropPath, "admx", "en-us", $visualStudioAdml)
Write-Output "Copying $file from $source to $destination."
Copy-Item -Path $source -Destination $destination