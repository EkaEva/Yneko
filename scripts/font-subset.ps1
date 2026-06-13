param(
  [string]$SourceDir = (Join-Path (Split-Path -Parent $PSScriptRoot) 'tools/fonts/source/misans'),
  [string]$OutputDir = (Join-Path (Split-Path -Parent $PSScriptRoot) 'app/assets/fonts/misans')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$charsetPath = Join-Path $OutputDir 'charset.txt'

$fontMap = @(
  @{ Source = 'MiSans-Regular.ttf'; Output = 'MiSansYneko-Regular.ttf' },
  @{ Source = 'MiSans-Semibold.ttf'; Output = 'MiSansYneko-Semibold.ttf' },
  @{ Source = 'MiSans-Bold.ttf'; Output = 'MiSansYneko-Bold.ttf' }
)

foreach ($font in $fontMap) {
  $source = Join-Path $SourceDir $font.Source
  if (-not (Test-Path -LiteralPath $source)) {
    throw "Missing source font: $source"
  }
}

$fonttools = Get-Command pyftsubset -ErrorAction SilentlyContinue
if (-not $fonttools) {
  $python = Get-Command python -ErrorAction SilentlyContinue
  if (-not $python) {
    throw 'pyftsubset or python with fontTools is required.'
  }
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$scanRoots = @(
  (Join-Path $root 'app/lib'),
  (Join-Path $root 'app/test'),
  (Join-Path $root 'README.md')
)

$extensions = @('.dart', '.md', '.yaml', '.yml')
$text = New-Object System.Text.StringBuilder
foreach ($scanRoot in $scanRoots) {
  if (Test-Path -LiteralPath $scanRoot -PathType Leaf) {
    [void]$text.Append((Get-Content -Raw -LiteralPath $scanRoot))
    continue
  }

  Get-ChildItem -Path $scanRoot -Recurse -File |
    Where-Object { $extensions -contains $_.Extension } |
    ForEach-Object {
      [void]$text.Append((Get-Content -Raw -LiteralPath $_.FullName))
    }
}

$common = @'
abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789
`~!@#$%^&*()-_=+[]{}\|;:'",.<>/? 
，。！？、；：“”‘’（）【】《》〈〉「」『』·…—-～￥
的一是在不了有和人这中大为上个国我以要他时来用们生到作地于出就分对成会可主发年动同工也能下过子说产种面而方后多定行学法所民得经十三之进着等部度家电力里如水化高自二理起小物现实加量都两体制机当使点从业本去把性好应开它合还因由其些然前外天政四日那社义事平形相全表间样与关各重新线内数正心反你明看原又么利比或但质气第向道命此变条只没结解问意建月公无系军很情者最立代想已通并提直题党程展五果料象员革位入常文总次品式活设及管特件长求老头基资边流路级少图山统接知较将组见计别她手角期根论运农指几九区强放决西被干做必战先回则任取据处队南给色光门即保治北造百规热领七海口东导器压志世金增争济阶油思术极交受联什认六共权收证改清己美再采转更单风切打白教速花带安场身车例真务具万每目至达走积示议声报斗完类八离华名确才科张信马节话米整空元况今集温传土许步群广石记需段研界拉林律叫且究观越织装影算低持音众书布复容儿须际商非验连断深难近矿千周委素技备半办青省列习响约支般史感劳便团往酸历市克何除消构府称太准精值号率族维划选标写存候毛亲快效斯院查江型眼王按格养易置派层片始却专状育厂京识适属圆包火住调满县局照参红细引听该铁价严龙飞
ぁあぃいぅうぇえぉおかがきぎくぐけげこごさざしじすずせぜそぞただちぢっつづてでとどなにぬねのはばぱひびぴふぶぷへべぺほぼぽまみむめもゃやゅゆょよらりるれろゎわゐゑをん
ァアィイゥウェエォオカガキギクグケゲコゴサザシジスズセゼソゾタダチヂッツヅテデトドナニヌネノハバパヒビピフブプヘベペホボポマミムメモャヤュユョヨラリルレロヮワヰヱヲンヴー
☆★♡♥♪♫♬◎○●△▲▽▼◇◆□■※→←↑↓↗↘
'@
[void]$text.Append($common)

$chars = [System.Collections.Generic.SortedSet[int]]::new()
foreach ($rune in $text.ToString().EnumerateRunes()) {
  $value = $rune.Value
  if ($value -ge 0x20 -and $value -ne 0x7f) {
    [void]$chars.Add($value)
  }
}

$charset = -join ($chars | ForEach-Object { [char]::ConvertFromUtf32($_) })
[System.IO.File]::WriteAllText($charsetPath, $charset, [System.Text.UTF8Encoding]::new($false))
Write-Host "Charset glyph candidates: $($chars.Count)"
Write-Host "Charset written: $charsetPath"

foreach ($font in $fontMap) {
  $source = Join-Path $SourceDir $font.Source
  $output = Join-Path $OutputDir $font.Output
  Write-Host "Subsetting $($font.Source) -> $($font.Output)"

  if ($fonttools) {
    & $fonttools.Source $source `
      --text-file=$charsetPath `
      --output-file=$output `
      --layout-features='*' `
      --name-IDs='*' `
      --name-legacy `
      --name-languages='*' `
      --notdef-glyph `
      --notdef-outline `
      --recommended-glyphs `
      --no-hinting
  } else {
    & python -m fontTools.subset $source `
      --text-file=$charsetPath `
      --output-file=$output `
      --layout-features='*' `
      --name-IDs='*' `
      --name-legacy `
      --name-languages='*' `
      --notdef-glyph `
      --notdef-outline `
      --recommended-glyphs `
      --no-hinting
  }

  if ($LASTEXITCODE -ne 0) {
    throw "fonttools failed for $($font.Source)"
  }
}

Get-ChildItem -LiteralPath $OutputDir -File |
  Select-Object Name, Length |
  Format-Table -AutoSize
