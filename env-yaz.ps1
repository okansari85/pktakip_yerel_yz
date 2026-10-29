# kur.bat çağırır: PKTakip backend .env dosyasına yerel yapay zeka adreslerini yazar (anahtar varsa değeri değişir, yoksa eklenir).
param([Parameter(Mandatory)][string]$EnvFile)

$values = [ordered]@{
    PKTAKIP_LOCAL_MODEL        = 'nuextract3'
    PKTAKIP_LOCAL_TIMEOUT      = '900'
    PKTAKIP_LOCAL_READER_URL   = 'http://127.0.0.1:8091/v1'
    PKTAKIP_LOCAL_READER_MODEL = 'qwen3.5-4b'
    PKTAKIP_DOCLING_URL        = 'http://127.0.0.1:8092/'
}

Copy-Item $EnvFile "$EnvFile.yedek" -Force
$lines = [System.Collections.Generic.List[string]](Get-Content $EnvFile -Encoding UTF8)
foreach ($key in $values.Keys) {
    $line = "$key=$($values[$key])"
    $index = $lines.FindIndex({ param($l) $l -match "^\s*$key=" })
    if ($index -ge 0) { $lines[$index] = $line } else { $lines.Add($line) }
}
# BOM'suz UTF-8: Laravel .env'i BOM'la okuyunca ilk satırın anahtarı bozulur.
[System.IO.File]::WriteAllLines($EnvFile, $lines, (New-Object System.Text.UTF8Encoding $false))
Write-Host "  .env guncellendi (eskisi: $EnvFile.yedek)"
