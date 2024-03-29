# Define a function which given an OrderedHashtable and an address array returns the correspondent value
function GetValueInJsonAddress($json, $address) {
    $value = $json
    foreach ($item in $address) {
        $value = $value[$item]
    }
    $valueType = $value.GetType().FullName
    return $value, $valueType
}

# Flatten an json map to a string
function FlattenMap($map) {
    $flat = ""
    foreach ($address in $map) {
        foreach ($item in $address) {
            $flat += $item
        }
    }
    return $flat
}

# Compare two json maps
function MapsAreEq($map1, $map2) {
    $flat1 = FlattenMap $map1
    $flat2 = FlattenMap $map2
    return $flat1 -eq $flat2  
}

# Return an array of arrays. Each internal array contains a series of keys that leads to one leaf of the hashtable
function MapJson($json) {
    $lastMap = @()
    foreach ($key in $json.Keys) {
        $lastMap = $lastMap + , @($key)
    }
    while ($true) {
        $map = @()
        foreach ($address in $lastMap) {
            $value, $valueType = GetValueInJsonAddress $json $address
            switch ($valueType) {
                'System.Management.Automation.OrderedHashtable' {
                    foreach ($key in $value.Keys) {
                        $map = $map + , ($address + $key)
                    }
                }
                'System.Object[]' {
                    for ($i = 0; $i -lt ($value.Count); $i++) {
                        $map = $map + , ($address + $i)
                    }
                }
                default {
                    $map = $map + , $address
                }
            }
        }
        if (MapsAreEq $map $lastMap) {
            break
        }
        $lastMap = $map
    }
    return $lastMap 
}

# Define function to merge the .json files
function MergeJsonFiles($OldFile, $NewFile, $TargetPath) {
    # Parse the old and new .json files into OrderedHashtabl
    $oldJson = Get-Content -Path $OldFile -Raw | ConvertFrom-Json -AsHashtable
    $newJson = Get-Content -Path $NewFile -Raw | ConvertFrom-Json -AsHashtable

    # Iterate over each address in the map of newJson
    $map = MapJson $newJson
    $depth = -1
    foreach ($address in $map) {

        # Calculates the depth of newJson
        $addressDepth = $address.Count
        if ($addressDepth -gt $depth) {
            $depth = $addressDepth
        }

        # If current address has an equivalent in oldJson, its value is replaced with the correspondent of oldJson
        $value = $oldJson
        $isValue = $true
        foreach ($item in $address) {
            if (-not $value[$item]) {
                $isValue = $false
                break
            }
            $value = $value[$item]
        }
        if ($isValue) {
            $expression = '$newJson'
            foreach ($item in $address) {
                switch ($item.GetType().FullName) {
                    "System.String" {
                        $expression += "['$item']"
                    }
                    "System.Int32" {
                        $expression += "[$item]"
                    }
                    default {
                        Throw "$item is neither System.String nor System.Int32."
                    }
                }
            }
            switch ($value.GetType().FullName) {
                'System.String' {
                    $expression += " = '$value'"
                }
                'System.Boolean' {
                    $expression += " = '$($value.ToString().ToLower())'"
                }
                default {
                    $expression += " = $value"
                }
            }
            Invoke-Expression $expression
        }
    }

    # Write the merged json file to disk
    $json = $newJson | ConvertTo-Json -Depth $depth
    $json | Out-File -FilePath "$TargetPath"
}