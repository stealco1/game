param(
    [Parameter(Mandatory = $true)]
    [string]$PlacePath
)

$ErrorActionPreference = "Stop"

$resolvedPlace = Resolve-Path $PlacePath
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$starterGuiOut = Join-Path $repoRoot "src\\StarterGui"
$mapsOut = Join-Path $repoRoot "src\\ServerStorage\\Maps"

New-Item -ItemType Directory -Force -Path $starterGuiOut | Out-Null
New-Item -ItemType Directory -Force -Path $mapsOut | Out-Null

$guiNames = @(
    "MainUI",
    "HUD",
    "LoadingScreen",
    "MobileControls",
    "RotateDeviceOverlay",
    "TeamSelectMenu",
    "RoundCountdown",
    "RespawnUI",
    "MapVoteMenu"
)

$mapNames = @(
    "StarterMapWild",
    "RosewoodGalleria",
    "LilacManorEstate"
)

$workspaceModelNames = @(
    "Baseplate",
    "LobbySpawn"
)

$doc = New-Object System.Xml.XmlDocument
$doc.PreserveWhitespace = $true
$doc.Load($resolvedPlace)
$root = $doc.DocumentElement

function Get-ItemName {
    param([System.Xml.XmlNode]$ItemNode)

    $nameNode = $ItemNode.SelectSingleNode("Properties/*[@name='Name']")
    if ($null -eq $nameNode) {
        return $null
    }

    return $nameNode.InnerText
}

function New-ExportDocument {
    param([System.Xml.XmlNode]$ItemNode)

    $newDoc = New-Object System.Xml.XmlDocument
    $newDoc.PreserveWhitespace = $true

    $declaration = $newDoc.CreateXmlDeclaration("1.0", "utf-8", $null)
    $newDoc.AppendChild($declaration) | Out-Null

    $newRoot = $newDoc.CreateElement($root.Prefix, $root.LocalName, $root.NamespaceURI)
    foreach ($attribute in $root.Attributes) {
        $newAttr = $newDoc.CreateAttribute($attribute.Prefix, $attribute.LocalName, $attribute.NamespaceURI)
        $newAttr.Value = $attribute.Value
        $null = $newRoot.Attributes.Append($newAttr)
    }
    $newDoc.AppendChild($newRoot) | Out-Null

    foreach ($child in $root.ChildNodes) {
        if ($child.NodeType -ne [System.Xml.XmlNodeType]::Element) {
            continue
        }

        if ($child.Name -eq "Item" -or $child.Name -eq "SharedStrings") {
            continue
        }

        $imported = $newDoc.ImportNode($child, $true)
        $newRoot.AppendChild($imported) | Out-Null
    }

    $importedItem = $newDoc.ImportNode($ItemNode, $true)
    $newRoot.AppendChild($importedItem) | Out-Null

    $sharedStrings = $root.SelectSingleNode("SharedStrings")
    if ($null -ne $sharedStrings) {
        $importedSharedStrings = $newDoc.ImportNode($sharedStrings, $true)
        $newRoot.AppendChild($importedSharedStrings) | Out-Null
    }

    return $newDoc
}

function Save-Export {
    param(
        [System.Xml.XmlNode]$ItemNode,
        [string]$OutputPath
    )

    $exportDoc = New-ExportDocument -ItemNode $ItemNode
    $settings = New-Object System.Xml.XmlWriterSettings
    $settings.Indent = $true
    $settings.Encoding = New-Object System.Text.UTF8Encoding($false)

    $writer = [System.Xml.XmlWriter]::Create($OutputPath, $settings)
    try {
        $exportDoc.Save($writer)
    }
    finally {
        $writer.Dispose()
    }
}

function Find-ChildItemByName {
    param(
        [System.Xml.XmlNode]$ParentNode,
        [string]$ChildName
    )

    foreach ($child in $ParentNode.SelectNodes("Item")) {
        if ((Get-ItemName $child) -eq $ChildName) {
            return $child
        }
    }

    return $null
}

$starterGuiService = $root.SelectSingleNode("Item[@class='StarterGui']")
if ($null -eq $starterGuiService) {
    throw "StarterGui service was not found in $resolvedPlace"
}

$serverStorageService = $root.SelectSingleNode("Item[@class='ServerStorage']")
if ($null -eq $serverStorageService) {
    throw "ServerStorage service was not found in $resolvedPlace"
}

$workspaceService = $root.SelectSingleNode("Item[@class='Workspace']")
if ($null -eq $workspaceService) {
    throw "Workspace service was not found in $resolvedPlace"
}

$mapsFolder = Find-ChildItemByName -ParentNode $serverStorageService -ChildName "Maps"

if ($null -eq $mapsFolder) {
    throw "ServerStorage.Maps was not found in $resolvedPlace"
}

$exported = New-Object System.Collections.Generic.List[string]

foreach ($guiName in $guiNames) {
    $match = Find-ChildItemByName -ParentNode $starterGuiService -ChildName $guiName

    if ($null -eq $match) {
        throw "StarterGui.$guiName was not found in $resolvedPlace"
    }

    $outPath = Join-Path $starterGuiOut ($guiName + ".rbxmx")
    Save-Export -ItemNode $match -OutputPath $outPath
    $exported.Add($outPath)
}

foreach ($mapName in $mapNames) {
    $match = Find-ChildItemByName -ParentNode $mapsFolder -ChildName $mapName

    if ($null -eq $match) {
        throw "ServerStorage.Maps.$mapName was not found in $resolvedPlace"
    }

    $outPath = Join-Path $mapsOut ($mapName + ".rbxmx")
    Save-Export -ItemNode $match -OutputPath $outPath
    $exported.Add($outPath)
}

foreach ($workspaceName in $workspaceModelNames) {
    $match = Find-ChildItemByName -ParentNode $workspaceService -ChildName $workspaceName

    if ($null -eq $match) {
        throw "Workspace.$workspaceName was not found in $resolvedPlace"
    }

    $outPath = Join-Path $repoRoot ("src\\Workspace\\" + $workspaceName + ".rbxmx")
    Save-Export -ItemNode $match -OutputPath $outPath
    $exported.Add($outPath)
}

$exported | ForEach-Object { Write-Output $_ }
