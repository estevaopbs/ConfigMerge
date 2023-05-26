param (
    [Parameter(Mandatory = $false, HelpMessage = 'The type of the files that will be merged. In case it is not provided, as long old and new files has the same extension, this extension will be taken as FileType. Valid values: ini; json; xml.')]
    [ValidateScript({ @('ini', 'json', 'xml') -contains $_ })]
    [string]$FileType,

    [Parameter(Mandatory = $true, HelpMessage = 'Path to the old file.')]
    [ValidateScript({ Test-Path $_ -PathType 'Leaf' })]
    [string]$OldFile,

    [Parameter(Mandatory = $true, HelpMessage = 'Path to the new file.')]
    [ValidateScript({ Test-Path $_ -PathType 'Leaf' })]
    [string]$NewFile,

    [Parameter(Mandatory = $false, HelpMessage = 'Path to the target file. If PathType is container, works only if the filename of NewFile and OldFile are the same. In case TargetPath is not provided, the value of NewFile will be taken as TagetPath.')]
    [ValidateScript({ Test-Path -Path (Split-Path -Path $_ -Parent) -PathType 'Container' })]
    [string]$TargetPath
)

# Case where the FileType is not specified. It will be taken from the extension of the old and new files as long their extensions are equal.
if (-not $FileType -and ((Test-Path -Path $OldFile -PathType Leaf) -eq (Test-Path -Path $NewFile -PathType Leaf)) -and ([System.IO.Path]::GetExtension($OldFile) -eq [System.IO.Path]::GetExtension($NewFile))) {
    $FileType = [System.IO.Path]::GetExtension($OldFile) -replace "\."
}

# Case where the target filename is not explicit and the "old" and "new" filenames are the same. In this case the name of the target file will be the same as the others
if (((Split-Path $OldFile -Leaf) -eq (Split-Path $NewFile -Leaf)) -and (Test-Path -Path $TargetPath -PathType Container)) {
    $TargetPath = Join-Path -Path $TargetPath -ChildPath (Split-Path $OldFile -Leaf)
}

# Case where only the OldFile and NewFile paths are passed in the input. The target file path will be considered the same as the NewFile.
if (-not $TargetPath) {
    $TargetPath = $NewFile
}

Write-Host $FileType
Write-Host $OldFile
Write-Host $NewFile
Write-Host $TargetPath

# Call the function that performs the merge operation on the files
switch ($FileType) {
    "ini" {
        Import-Module "./IniMerge/IniMerge.psm1"
        MergeIniFiles $OldFile $NewFile $TargetPath
    }
    "json" {
        Import-Module "./JsonMerge/JsonMerge.psm1"
        MergeJsonFiles $OldFile $NewFile $TargetPath
    }
    "xml" {
        Import-Module "./XmlMerge/XmlMerge.psm1"
        MergeXmlFiles $OldFile $NewFile $TargetPath
    }
    default {
        Write-Host "Invalid Input"
    }
}