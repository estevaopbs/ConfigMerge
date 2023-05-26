# Define function to merge the xml files
function MergeXmlFiles($OldFile, $NewFile, $TargetPath) {

    # Parse the old and new xml files into System.Xml
    $oldXml = [xml](Get-Content $OldFile)
    $newXml = [xml](Get-Content $NewFile)

    # Iterate over each node of newXml
    $xPaths = @()
    foreach ($node in $newXml.SelectNodes('//*')) {
        $branch = @($node)
        $xPath = "/$($node.LocalName)"

        # Generate an univoque XPath to the current node
        while ($true) {
            $nextParent = $branch[-1].ParentNode
            if ($nextParent.LocalName -eq "#document") {
                break
            }
            $branch += $nextParent
            $xPath = "/$($nextParent.LocalName)$xPath"
        }
        $count = 0
        foreach ($path in $xPaths) {
            if ($path -match "$xPath\[[0-9]+\]") {
                $count++
            }
        }
        $xPath = "$xPath[$($count+1)]"

        # If the current node has an equivalent in oldXml, its attribute values are replaced with those of oldNode 
        $oldNode = $oldXml.SelectSingleNode($xPath)
        if ($oldNode) {
            $oldNodeAttributes = @()
            foreach ($attribute in $oldNode.Attributes) {
                $oldNodeAttributes += $attribute.ToString()
            }
            foreach ($attribute in $node.Attributes) {
                if ($oldNodeAttributes -contains $attribute.ToString()) {
                    $newXml.SelectSingleNode($xPath).$($attribute.ToString()) = $oldNode.$($attribute.ToString())
                }
            }
        }
        $xPaths += $xPath
    }
    # Save the resultant xml on disk
    $newXml.Save($TargetPath)
}
