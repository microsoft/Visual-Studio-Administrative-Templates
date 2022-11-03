    <#
.SYNOPSIS
    Prepares a staging directory for consumption by the BoxStub tool.

.DESCRIPTION
    Prepares a staging directory with the appropriate language directories, ADMX and ADML files 
    for consumption by the BoxStub tool that creates the self-extracting VisualStudioAdminTemplates.exe.

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

# Two dictionaries are used to map the Microbuild language outputs (CHS, CHT, etc.) with both the
# folder names used to store the resource files consumed by the ADMXExtractor.exe and also
# the folder names used by the Group Policy editor in c:\Windows\GroupPolicy
# Map the Microbuild Language outputs to the OS codes to store the resource files.
$admxExtractorlanguageTable = [ordered]@{
    ENU="en";
}

#  Map the Microbuild Language outputs to the admx template group policy language codes for adml files.
$admxTemplateLanguageTable = [ordered]@{
    ENU="en-US";
}

$admx = "admx"
$exeFilesToCopy = @( "ADMXExtractor.exe", "ADMXExtractor.exe.config" )
$visualStudioAdmx = "VisualStudio.admx"
$visualStudioAdml = "VisualStudio.adml"

foreach ($key in $admxExtractorlanguageTable.Keys)
{
    $value = $admxExtractorlanguageTable[$key]
    
    Write-Verbose "Key: $key, Value: $value"

    # ADMXExtractor.exe localization
    # Create each of the ADMXExtractor.exe application language folders in the IntermediateDrop folder.
    # These localized folders will be used to save ADMXExtractor.resources.dll files.
    # $(IntermediateDrop)\{admxExtractorlanguageTable.Value}
    $path = [System.IO.Path]::Combine($IntermediateDropPath, $value)
    New-Item -Path $path -ItemType Directory -Force
    Write-Verbose "Created path: $path"

    $value = $admxTemplateLanguageTable[$key]
    Write-Verbose "Key: $key, Value: $value"

    # ADMX Template group policy localization
    # Create each of the ADMX template language folders in Intermediate\admx for .adml files.
    # $(IntermediateDrop)\admx\{admxTemplateLanguageTable.Value}
    $path = [System.IO.Path]::Combine($IntermediateDropPath, $admx, $value)
    New-Item -Path $path -ItemType Directory -Force
    Write-Verbose "Created path: $path"
}

# Copy the exe and config file to the intermediate drop to be staged for consumption by the boxtool.
foreach ($file in $exeFilesToCopy)
{
    $source = [System.IO.Path]::Combine($ArtifactsDir, $file)
    $destination = [System.IO.Path]::Combine($IntermediateDropPath, $file)
    Write-Verbose "Copying $file from $source to $destination."
    Copy-Item -Path $source -Destination $destination
}

# Special handling to copy the en-US admx and adml files because they are not localized.
$source = [System.IO.Path]::Combine($ArtifactsDir, $admx, $visualStudioAdmx)
$destination = [System.IO.Path]::Combine($IntermediateDropPath, $admx, $visualStudioAdmx)
Write-Verbose "Copying $file from $source to $destination."
Copy-Item -Path $source -Destination $destination

$source = [System.IO.Path]::Combine($ArtifactsDir, $admx, $visualStudioAdml)
$destination = [System.IO.Path]::Combine($IntermediateDropPath, $admx, $admxTemplateLanguageTable["ENU"], $visualStudioAdml)
Write-Verbose "Copying $file from $source to $destination."
Copy-Item -Path $source -Destination $destination