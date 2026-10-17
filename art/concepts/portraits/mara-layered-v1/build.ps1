Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression
$assetDir = $PSScriptRoot
function Export-Scaled($inputPath, $outputName) {
    $source = [System.Drawing.Image]::FromFile($inputPath)
    $bitmap = New-Object System.Drawing.Bitmap 192,192
    $canvas = [System.Drawing.Graphics]::FromImage($bitmap)
    $canvas.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $canvas.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $canvas.DrawImage($source, (New-Object System.Drawing.Rectangle 0,0,192,192))
    $bitmap.Save((Join-Path $assetDir $outputName), [System.Drawing.Imaging.ImageFormat]::Png)
    $canvas.Dispose(); $bitmap.Dispose(); $source.Dispose()
}
Export-Scaled 'C:\Users\jonat\.codex\generated_images\01a13d8e-bdf4-73d2-a4fe-fefbeb405315\exec-e8c71b5d-20ae-4272-b758-ab959c36ef3a.png' 'base.png'
Export-Scaled 'C:\Users\jonat\.codex\generated_images\01a13d8e-bdf4-73d2-a4fe-fefbeb405315\exec-519a2d7e-a055-494a-9466-f4618168593c.png' 'tunic.png'
$base = [System.Drawing.Bitmap]::FromFile((Join-Path $assetDir 'base.png'))
# Full-canvas replacement patches preserve registration; include surrounding skin.
foreach ($patch in @(@('eyes-neutral.png',83,60,54,19), @('mouth-neutral.png',94,94,31,14))) {
    $bitmap = New-Object System.Drawing.Bitmap 192,192
    for ($py = [int]$patch[2]; $py -lt ([int]$patch[2]+[int]$patch[4]); $py++) {
        for ($px = [int]$patch[1]; $px -lt ([int]$patch[1]+[int]$patch[3]); $px++) {
            $bitmap.SetPixel($px,$py,$base.GetPixel($px,$py))
        }
    }
    $bitmap.Save((Join-Path $assetDir $patch[0]),[System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
}
$base.Dispose()
$background = New-Object System.Drawing.Bitmap 192,192
$canvas = [System.Drawing.Graphics]::FromImage($background)
$canvas.Clear([System.Drawing.Color]::FromArgb(255,12,13,15))
$background.Save((Join-Path $assetDir 'background.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$canvas.Dispose(); $background.Dispose()
$preview = New-Object System.Drawing.Bitmap 192,192
$canvas = [System.Drawing.Graphics]::FromImage($preview)
foreach ($name in @('background.png','base.png','tunic.png','eyes-neutral.png','mouth-neutral.png')) {
    $layerImage = [System.Drawing.Image]::FromFile((Join-Path $assetDir $name))
    $canvas.DrawImageUnscaled($layerImage,0,0)
    $layerImage.Dispose()
}
$preview.Save((Join-Path $assetDir 'preview.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$canvas.Dispose(); $preview.Dispose()
$stackXml = @'
<?xml version="1.0" encoding="UTF-8"?>
<image version="0.0.3" w="192" h="192" name="Mara - wardrobe prototype">
  <stack>
    <layer name="Mouth - neutral replacement patch" src="data/mouth-neutral.png" opacity="1.0" visibility="visible" composite-op="svg:src-over" x="0" y="0"/>
    <layer name="Eyes - neutral replacement patch" src="data/eyes-neutral.png" opacity="1.0" visibility="visible" composite-op="svg:src-over" x="0" y="0"/>
    <layer name="Outfit - brown tunic (toggle)" src="data/tunic.png" opacity="1.0" visibility="visible" composite-op="svg:src-over" x="0" y="0"/>
    <layer name="Base - body face and hair combined" src="data/base.png" opacity="1.0" visibility="visible" composite-op="svg:src-over" x="0" y="0"/>
    <layer name="Background" src="data/background.png" opacity="1.0" visibility="visible" composite-op="svg:src-over" x="0" y="0"/>
  </stack>
</image>
'@
[System.IO.File]::WriteAllText((Join-Path $assetDir 'stack.xml'),$stackXml)
$archive = [System.IO.Compression.ZipFile]::Open((Join-Path $assetDir 'mara-layered-192.ora'),[System.IO.Compression.ZipArchiveMode]::Create)
$entry = $archive.CreateEntry('mimetype',[System.IO.Compression.CompressionLevel]::NoCompression)
$writer = New-Object System.IO.StreamWriter($entry.Open())
$writer.Write('image/openraster'); $writer.Dispose()
[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,(Join-Path $assetDir 'stack.xml'),'stack.xml') | Out-Null
[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,(Join-Path $assetDir 'preview.png'),'mergedimage.png') | Out-Null
foreach ($name in @('background.png','base.png','tunic.png','eyes-neutral.png','mouth-neutral.png')) {
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,(Join-Path $assetDir $name),('data/'+$name)) | Out-Null
}
$archive.Dispose()
