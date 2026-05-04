Add-Type -AssemblyName System.Drawing

$outDir = Join-Path (Get-Location) "docs\screenshots"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$fontTitle = New-Object System.Drawing.Font("Malgun Gothic", 24, [System.Drawing.FontStyle]::Bold)
$fontH2 = New-Object System.Drawing.Font("Malgun Gothic", 16, [System.Drawing.FontStyle]::Bold)
$fontBody = New-Object System.Drawing.Font("Malgun Gothic", 12, [System.Drawing.FontStyle]::Regular)
$fontSmall = New-Object System.Drawing.Font("Malgun Gothic", 9, [System.Drawing.FontStyle]::Regular)
$fontNav = New-Object System.Drawing.Font("Malgun Gothic", 10, [System.Drawing.FontStyle]::Bold)

function Brush($hex) {
  return New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml($hex))
}

function PenColor($hex, $width = 1) {
  return New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml($hex)), $width
}

function NewPen($hex, $width = 2) {
  $pen = New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml($hex), $width)
  $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
  return $pen
}

function RoundRectPath($x, $y, $w, $h, $r) {
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = $r * 2
  $path.AddArc($x, $y, $d, $d, 180, 90)
  $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
  $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $path.CloseFigure()
  return $path
}

function FillRound($g, $x, $y, $w, $h, $r, $color) {
  if ($r -le 0) {
    $rect = New-Object System.Drawing.RectangleF($x, $y, $w, $h)
    $g.FillRectangle((Brush $color), $rect)
    return
  }
  $path = RoundRectPath $x $y $w $h $r
  $g.FillPath((Brush $color), $path)
  $g.DrawPath((New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml("#E1E7EA"), 1)), $path)
  $path.Dispose()
}

function Text($g, $text, $font, $color, $x, $y, $w = 330, $h = 80) {
  $rect = New-Object System.Drawing.RectangleF($x, $y, $w, $h)
  $format = New-Object System.Drawing.StringFormat
  $format.Trimming = [System.Drawing.StringTrimming]::EllipsisCharacter
  $g.DrawString($text, $font, (Brush $color), $rect, $format)
}

function Chip($g, $text, $x, $y, $color = "#EAF3EF") {
  FillRound $g $x $y 86 28 14 $color
  Text $g $text $fontSmall "#172026" ($x + 12) ($y + 6) 70 20
}

function DrawHomeIcon($g, $x, $y, $color) {
  $pen = NewPen $color 2
  $pts = @(
    [System.Drawing.PointF]::new($x - 10, $y + 8),
    [System.Drawing.PointF]::new($x, $y - 2),
    [System.Drawing.PointF]::new($x + 10, $y + 8)
  )
  $g.DrawLines($pen, $pts)
  $g.DrawRectangle($pen, $x - 7, $y + 8, 14, 12)
  $pen.Dispose()
}

function DrawAddIcon($g, $x, $y, $color) {
  $pen = NewPen $color 2
  $g.DrawEllipse($pen, $x - 10, $y - 2, 20, 20)
  $g.DrawLine($pen, $x, $y + 3, $x, $y + 13)
  $g.DrawLine($pen, $x - 5, $y + 8, $x + 5, $y + 8)
  $pen.Dispose()
}

function DrawRecordsIcon($g, $x, $y, $color) {
  $pen = NewPen $color 2
  $g.DrawRectangle($pen, $x - 9, $y, 18, 18)
  $g.DrawLine($pen, $x - 9, $y + 5, $x + 9, $y + 5)
  $g.DrawLine($pen, $x - 4, $y - 3, $x - 4, $y + 3)
  $g.DrawLine($pen, $x + 4, $y - 3, $x + 4, $y + 3)
  $pen.Dispose()
}

function DrawReportIcon($g, $x, $y, $color) {
  $pen = NewPen $color 2
  $g.DrawLine($pen, $x - 10, $y + 16, $x - 4, $y + 9)
  $g.DrawLine($pen, $x - 4, $y + 9, $x + 2, $y + 12)
  $g.DrawLine($pen, $x + 2, $y + 12, $x + 10, $y + 2)
  $g.DrawLine($pen, $x + 8, $y + 2, $x + 10, $y + 2)
  $g.DrawLine($pen, $x + 10, $y + 2, $x + 10, $y + 4)
  $pen.Dispose()
}

function DrawHealthIcon($g, $x, $y, $color) {
  $pen = NewPen $color 2
  $g.DrawEllipse($pen, $x - 5, $y - 2, 10, 10)
  $g.DrawArc($pen, $x - 12, $y + 8, 24, 16, 200, 140)
  $pen.Dispose()
}

function DrawSettingsIcon($g, $x, $y, $color) {
  $pen = NewPen $color 2
  $g.DrawEllipse($pen, $x - 7, $y + 1, 14, 14)
  $g.DrawEllipse($pen, $x - 2, $y + 6, 4, 4)
  $g.DrawLine($pen, $x, $y - 3, $x, $y)
  $g.DrawLine($pen, $x, $y + 16, $x, $y + 19)
  $g.DrawLine($pen, $x - 11, $y + 8, $x - 8, $y + 8)
  $g.DrawLine($pen, $x + 8, $y + 8, $x + 11, $y + 8)
  $pen.Dispose()
}

function DrawNavIcon($g, $key, $x, $color) {
  switch ($key) {
    "home" { DrawHomeIcon $g $x 784 $color }
    "add" { DrawAddIcon $g $x 784 $color }
    "records" { DrawRecordsIcon $g $x 784 $color }
    "report" { DrawReportIcon $g $x 784 $color }
    "health" { DrawHealthIcon $g $x 784 $color }
    "settings" { DrawSettingsIcon $g $x 784 $color }
  }
}

function Nav($g, $active) {
  FillRound $g 0 764 390 80 0 "#EAF3EF"
  $items = @(
    @("홈", 32, "home"),
    @("추가", 98, "add"),
    @("기록", 163, "records"),
    @("리포트", 228, "report"),
    @("몸상태", 293, "health"),
    @("설정", 358, "settings")
  )
  foreach ($item in $items) {
    $label = $item[0]; $x = [int]$item[1]; $key = $item[2]
    if ($key -eq $active) {
      FillRound $g ($x - 24) 774 48 34 17 "#CFEADF"
    }
    $color = if ($key -eq $active) { "#1F9D7A" } else { "#37413D" }
    DrawNavIcon $g $key $x $color
    Text $g $label $fontNav "#172026" ($x - 26) 812 58 22
  }
}

function NewScreen($file, $title, $active, $drawContent) {
  $bmp = New-Object System.Drawing.Bitmap 390, 844
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.Clear([System.Drawing.ColorTranslator]::FromHtml("#F6F8FA"))
  Text $g $title $fontTitle "#172026" 24 30 330 45
  & $drawContent $g
  Nav $g $active
  $bmp.Save((Join-Path $outDir $file), [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose()
  $bmp.Dispose()
}

NewScreen "home.png" "오늘의 식단" "home" {
  param($g)
  Text $g "5월 4일 월요일" $fontBody "#6B7780" 24 72 300 24
  FillRound $g 24 110 342 150 24 "#FFFFFF"
  Text $g "오늘 총 섭취" $fontSmall "#6B7780" 46 132 120 24
  Text $g "1,286 kcal" $fontTitle "#172026" 46 158 180 42
  $g.FillRectangle((Brush "#DDE5E8"), 46, 222, 280, 12)
  $g.FillRectangle((Brush "#1F9D7A"), 46, 222, 178, 12)
  Text $g "목표 2,034 kcal · 63%" $fontSmall "#6B7780" 46 238 220 20
  FillRound $g 24 280 342 88 18 "#FFFFFF"
  Text $g "탄수화물 64.5g" $fontBody "#3478F6" 42 304 120 25
  Text $g "단백질 47.2g" $fontBody "#1F9D7A" 42 332 120 25
  Text $g "지방 28.4g" $fontBody "#E98A15" 210 318 110 25
  FillRound $g 24 388 342 96 18 "#FFFFFF"
  Text $g "식사 시간 피드백" $fontH2 "#172026" 42 410 180 28
  Text $g "점심 식사 시간이 안정적으로 기록되었습니다." $fontBody "#6B7780" 42 444 280 30
  FillRound $g 24 506 342 170 18 "#FFFFFF"
  Text $g "오늘 식단" $fontH2 "#172026" 42 528 120 28
  Text $g "현미밥 · 아침 · 180g · 270kcal" $fontBody "#172026" 42 566 280 24
  Text $g "고등어구이 · 점심 · 180g · 369kcal" $fontBody "#172026" 42 598 290 24
  Text $g "김치 · 점심 · 40g · 9kcal" $fontBody "#172026" 42 630 260 24
}

NewScreen "add.png" "식단 추가" "add" {
  param($g)
  FillRound $g 24 92 342 186 20 "#FFFFFF"
  FillRound $g 42 112 306 106 16 "#EAF3EF"
  Text $g "음식 사진 미리보기" $fontH2 "#1F9D7A" 92 154 220 30
  FillRound $g 42 232 145 34 17 "#FFFFFF"
  FillRound $g 203 232 145 34 17 "#FFFFFF"
  Text $g "사진 업로드" $fontSmall "#1F9D7A" 82 242 80 18
  Text $g "카메라 촬영" $fontSmall "#1F9D7A" 243 242 80 18
  FillRound $g 24 304 342 54 16 "#FFFFFF"
  Text $g "AI로 사진 속 음식 찾기" $fontH2 "#1F9D7A" 72 318 240 30
  Text $g "AI가 찾은 음식 후보" $fontH2 "#172026" 24 384 260 28
  FillRound $g 24 422 342 188 18 "#FFFFFF"
  Text $g "✓ 고등어구이 · 신뢰도 높음 · 1인분" $fontBody "#172026" 42 444 290 24
  Text $g "✓ 잡곡밥 · 신뢰도 높음 · 1공기" $fontBody "#172026" 42 478 290 24
  Text $g "✓ 된장국 · 신뢰도 보통 · 1그릇" $fontBody "#172026" 42 512 290 24
  Chip $g "0.5인분" 42 552
  Chip $g "1인분" 138 552 "#CFEADF"
  Chip $g "직접 g" 234 552
  Text $g "음식 검색" $fontH2 "#172026" 24 636 160 28
  FillRound $g 24 674 342 48 16 "#FFFFFF"
  Text $g "예: 김치찌개, 닭가슴살, 바나나" $fontBody "#6B7780" 48 688 260 24
}

NewScreen "records.png" "식단 기록" "records" {
  param($g)
  FillRound $g 24 92 342 64 18 "#FFFFFF"
  Text $g "‹  5월 4일 월요일  ›" $fontH2 "#172026" 86 112 230 32
  FillRound $g 24 176 342 78 18 "#FFFFFF"
  Text $g "선택 날짜 총" $fontSmall "#6B7780" 42 196 120 20
  Text $g "1,286 kcal" $fontTitle "#172026" 42 216 180 35
  Text $g "아침" $fontH2 "#172026" 24 280 100 28
  FillRound $g 24 318 342 76 18 "#FFFFFF"
  Text $g "현미밥" $fontH2 "#172026" 42 334 120 26
  Text $g "180g · 270kcal · 탄 56.2g" $fontSmall "#6B7780" 42 362 230 20
  Text $g "점심" $fontH2 "#172026" 24 420 100 28
  FillRound $g 24 458 342 104 18 "#FFFFFF"
  Text $g "고등어구이" $fontH2 "#172026" 42 474 140 26
  Text $g "180g · 369kcal · 단백질 36.0g" $fontSmall "#6B7780" 42 502 250 20
  Text $g "김치 · 40g · 9kcal" $fontSmall "#6B7780" 42 530 180 20
}

NewScreen "report.png" "오늘 리포트" "report" {
  param($g)
  Text $g "규칙 기반 식단/생활 패턴 분석" $fontBody "#6B7780" 24 72 300 24
  FillRound $g 24 112 342 118 20 "#FFFFFF"
  Text $g "1,286 kcal" $fontTitle "#172026" 42 134 180 42
  Text $g "목표 대비 63% · 기록 3개" $fontBody "#6B7780" 42 178 220 25
  Text $g "탄 65g · 단 47g · 지 28g" $fontBody "#6B7780" 42 202 240 25
  Text $g "피드백" $fontH2 "#172026" 24 258 100 28
  FillRound $g 24 296 342 88 18 "#FFFFFF"
  Text $g "목표 칼로리보다 낮게 섭취했습니다." $fontBody "#172026" 42 318 285 24
  Text $g "다음 식사에서 영양을 보완해보세요." $fontSmall "#6B7780" 42 348 270 20
  FillRound $g 24 404 342 96 18 "#FFFFFF"
  Text $g "점심 식사의 칼로리 비중이 가장 높습니다." $fontBody "#172026" 42 426 290 24
  Text $g "식사 간격과 취침 시간을 함께 확인합니다." $fontSmall "#6B7780" 42 456 280 20
  FillRound $g 24 520 342 96 18 "#FFFFFF"
  Text $g "이 내용은 건강 진단이나 처방이 아닌" $fontSmall "#6B7780" 42 544 280 20
  Text $g "식단 기록 참고용 추정 결과입니다." $fontSmall "#6B7780" 42 568 280 20
}

NewScreen "health.png" "내 몸 상태" "health" {
  param($g)
  FillRound $g 24 92 342 92 18 "#FFFFFF"
  Text $g "키 170cm · 몸무게 70.0kg" $fontH2 "#172026" 42 114 260 28
  Text $g "목표 체중 68.0kg · 가벼운 활동" $fontBody "#6B7780" 42 146 270 24
  FillRound $g 24 210 156 112 18 "#FFFFFF"
  Text $g "BMI" $fontSmall "#6B7780" 42 232 80 20
  Text $g "24.2" $fontTitle "#172026" 42 254 100 36
  Text $g "과체중 전단계" $fontSmall "#6B7780" 42 292 100 20
  FillRound $g 204 210 162 112 18 "#FFFFFF"
  Text $g "목표 칼로리" $fontSmall "#6B7780" 222 232 100 20
  Text $g "2,034" $fontTitle "#172026" 222 254 120 36
  Text $g "kcal 추정" $fontSmall "#6B7780" 222 292 100 20
  FillRound $g 24 350 342 118 18 "#FFFFFF"
  Text $g "기초대사량 / 유지 칼로리" $fontH2 "#172026" 42 372 260 28
  Text $g "1,478 kcal / 2,291 kcal" $fontBody "#1F9D7A" 42 408 240 24
  Text $g "Mifflin-St Jeor 공식 기반 추정값" $fontSmall "#6B7780" 42 436 270 20
  FillRound $g 24 494 342 124 18 "#FFFFFF"
  Text $g "몸무게 변화 기록" $fontH2 "#172026" 42 516 220 28
  Text $g "70.0kg · BMI 24.2 · 5/4" $fontBody "#172026" 42 552 220 24
  Text $g "목표 체중까지 -2.0kg" $fontSmall "#6B7780" 42 584 180 20
}

