# Define helper function to parse a ini file into a list of block structs
function ParseIniFile($path, $bypassDoubleness) {

    # Initialize the parameters that will be used to run the merge
    $blocks = @()
    $currentBlock = $null
    $content = Get-Content $path
    $lastComments = @()

    foreach ($line in $content) {
        if ($line.StartsWith(";")) {
            # Add comments to the list that will be associated with the next parameter/block
            $lastComments += $line.TrimStart(";")
        }
        elseif ($line.StartsWith("[")) {
            # Start of new block
            $currentBlock = @{
                Name       = ""
                Comments   = @()
                Parameters = @()
            }
            $currentBlock.Name = $line.Trim("[", "]", " ")
            $currentBlock.Comments = $lastComments
            $lastComments = @()
            # Check for duplicate block names
            if (-not $null -eq ($blocks | Where-Object { $_.Name -eq $currentBlock.Name })) {
                Write-Host "Inconsistent '$path' file. There is more than one [$($currentBlock.Name)] block in the file."
                if ($bypassDoubleness) {
                    $blocks = $blocks | Where-Object { $_.Name -ne $currentBlock.Name }
                }
                else {
                    exit 1
                }
            }
            if ($currentBlock.Count -eq 3) {
                $blocks += $currentBlock
            }
        }
        elseif ($line.Contains("=")) {
            # Parameter line
            $paramParts = $line.Split("=", 2).Trim()
            $param = @{
                Name     = ""
                Value    = ""
                Comments = @()
            }
            $param.Name = $paramParts[0]
            $param.Value = $paramParts[1]
            $param.Comments = $lastComments
            $lastComments = @()
            # Check for duplicate parameter names within a block
            if (-not $null -eq ($currentBlock.Parameters | Where-Object { $_.Name -eq $param.Name })) {
                Write-Host "Inconsistent '$path' file. There is more than one '$($param.Name)' parameter in the block '[$($currentBlock.Name)]'."
                if ($bypassDoubleness) {
                    $currentBlock.Parameters = $currentBlock.Parameters | Where-Object { $_.Name -ne $param.Name }
                }
                else {
                    exit 1
                }
            }
            if ($param.Count -eq 3) {
                $currentBlock.Parameters += $param
            }
        }
    }
    # Return the list of block structs
    return $blocks
}

# Mount the Block object to a list of strings as it will be appended to the output file
function MountBlock($block) {
    $blockContent = @()
    foreach ($comment in $block.Comments) {
        $blockContent += ";$comment"
    }
    $blockContent += "[$($block.Name)]"
    foreach ($parameter in $block.Parameters) {
        foreach ($comment in $parameter.Comments) {
            $blockContent += ";$comment"
        }
        $blockContent += "$($parameter.Name)=$($parameter.Value)"
    }
    $blockContent += ""
    return $blockContent
}

# Define function to merge the ini files
function MergeIniFiles($OldFile, $NewFile, $TargetPath, $bypassDoubleness) {

    # Parse the old and new ini files into lists of block structs
    $oldBlocks = ParseIniFile $OldFile $bypassDoubleness
    $newBlocks = ParseIniFile $NewFile $bypassDoubleness

    # Loop through each block in the new ini comparing it with the old ini file and adds the merged blocks in the output
    $targetContent = @()
    foreach ($newBlock in $newBlocks) {

        # Skip block if it doesn't exist in old file
        $filteredOldBlocks = $oldBlocks | Where-Object { $_.Name -eq $newBlock.Name }
        if ($filteredOldBlocks.Count -ne 3) {
            $targetContent += MountBlock $newBlock
            continue
        }

        # Skip the parameter if it doesn't exist in the corresponding block of the old file
        foreach ($newParameter in $newBlock.Parameters) {
            $filteredOldParameters = $filteredOldBlocks.Parameters | Where-Object { $_.Name -eq $newParameter.Name }
            if ($filteredOldParameters.Count -ne 3) {
                continue
            }

            # Replace the new parameter value with the old parameter value
            $newParameter.Value = $filteredOldParameters.Value
        }
        $targetContent += MountBlock $newBlock
    }

    # Write the merged ini file to disk
    $targetContent | Out-File -FilePath $TargetPath -Encoding UTF8 -Force
}
