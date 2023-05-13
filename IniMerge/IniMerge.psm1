# Define helper function to parse a .ini file into a list of block structs
function ParseIniFile($path) {

    # Define the structs for parameters and blocks
    $parameterStruct = @{
        Name     = ""
        Value    = ""
        Comments = @()
    }

    $blockStruct = @{
        Name       = ""
        Comments   = @()
        Parameters = @()
    }

    # Initialize the parameters that will be used to run the merge
    $blocks = @()
    $currentBlock = $null
    $content = Get-Content $path
    $lastComments = @()

    foreach ($line in $content) {
        if ($line.StartsWith(";")) {
            # Add comments to the list that will be associated with the next parameter/block
            $lastComments += $line.TrimStart(";").Trim()
        }
        elseif ($line.StartsWith("[")) {
            # Start of new block
            $currentBlock = $blockStruct.Clone()
            $currentBlock.Name = $line.Trim("[", "]", " ")
            $currentBlock.Comments = $lastComments
            $lastComments = @()
            # Check for duplicate block names
            if (-not $null -eq ($blocks | Where-Object { $_.Name -eq $currentBlock.Name })) {
                Write-Output "Inconsistent '$path' file. There is more than one [$($currentBlock.Name)] block in the file."
                exit 1
            }
            $blocks += $currentBlock
        }
        elseif ($line.Contains("=")) {
            # Parameter line
            $paramParts = $line.Split("=", 2).Trim()
            $param = $parameterStruct.Clone()
            $param.Name = $paramParts[0]
            $param.Value = $paramParts[1]
            $param.Comments = $lastComments
            $lastComments = @()
            # Check for duplicate parameter names within a block
            if (-not $null -eq ($currentBlock.Parameters | Where-Object { $_.Name -eq $param.Name })) {
                Write-Output "Inconsistent '$path' file. There is more than one '$($param.Name)' parameter in the block '[$($currentBlock.Name)]'."
                exit 1
            }
            $currentBlock.Parameters += $param
        }
    }
    # Return the list of block structs
    return $blocks
}

# Mount the Block object to a list of strings as it will be appended to the output file
function MountBlock($block) {
    $blockContent = @()
    foreach ($comment in $block.Comments) {
        $blockContent += "; $comment"
    }
    $blockContent += "[$($block.Name)]"
    foreach ($parameter in $block.Parameters) {
        foreach ($comment in $parameter.Comments) {
            $blockContent += "; $comment"
        }
        $blockContent += "$($parameter.Name)=$($parameter.Value)"
    }
    $blockContent += ""
    return $blockContent
}

# Define function to merge the .ini files
function MergeIniFiles($oldCfgPath, $newCfgPath, $targetCfgPath) {

    # Parse the old and new .ini files into lists of block structs
    $oldBlocks = ParseIniFile $oldCfgPath
    $newBlocks = ParseIniFile $newCfgPath

    # Loop through each block in the new .ini comparing it with the old .ini file and adds the merged blocks in the output
    $targetContent = @()
    $blockIndex = 0
    foreach ($newBlock in $newBlocks) {

        # Skip block if it doesn't exist in old file
        $filteredOldBlocks = $oldBlocks | Where-Object { $_.Name -eq $newBlock.Name }
        if ($filteredOldBlocks.Count -ne 3) {
            $targetContent += MountBlock $newBlock
            $blockIndex += 1
            continue
        }
        
        # Skip the parameter if it doesn't exist in the corresponding block of the old file
        $parameterIndex = 0
        foreach ($newParameter in $newBlock.Parameters) {
            $filteredOldParameters = $filteredOldBlocks.Parameters | Where-Object { $_.Name -eq $newParameter.Name }
            if ($filteredOldParameters.Count -ne 3) {
                $parameterIndex += 1
                continue
            }
            
            # Replace the new parameter value with the old parameter value
            $newParameter.Value = $filteredOldParameters.Value
            $parameterIndex += 1
        }
        $targetContent += MountBlock $newBlock
        $blockIndex += 1
    }

    # Write the merged .ini file to disk
    $targetContent | Out-File -FilePath $targetCfgPath -Encoding UTF8 -Force
}
