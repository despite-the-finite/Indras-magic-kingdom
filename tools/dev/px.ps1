param([string]$f,[int]$x,[int]$y)
Add-Type -AssemblyName System.Drawing
$b=[System.Drawing.Bitmap]::FromFile($f); $c=$b.GetPixel($x,$y); "{0} ({1},{2}) = #{3:x2}{4:x2}{5:x2}" -f (Split-Path $f -Leaf),$x,$y,$c.R,$c.G,$c.B; $b.Dispose()
