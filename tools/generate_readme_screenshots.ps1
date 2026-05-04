Add-Type -AssemblyName System.Drawing

$outDir = Join-Path (Get-Location) "docs\screenshots"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$fontTitle = New-Object System.Drawing.Font("Malgun Gothic", 24, [System.Drawing.FontStyle]::Bold)
$fontSection = New-Object System.Drawing.Font("Malgun Gothic", 18, [System.Drawing.FontStyle]::Bold)
$fontCardTitle = New-Object System.Drawing.Font("Malgun Gothic", 16, [System.Drawing.FontStyle]::Bold)
$fontBody = New-Object System.Drawing.Font("Malgun Gothic", 13, [System.Drawing.FontStyle]::Regular)
$fontMuted = New-Object System.Drawing.Font("Malgun Gothic", 11, [System.Drawing.FontStyle]::Regular)
$fontSmall = New-Object System.Drawing.Font("Malgun Gothic", 9, [System.Drawing.FontStyle]::Regular)
$fontNav = New-Object System.Drawing.Font("Malgun Gothic", 10, [System.Drawing.FontStyle]::Regular)

function Brush($hex) {
  return New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml($hex))
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

function FillRound($g, $x, $y, $w, $h, $r, $color, $border = "#DDE5E8") {
  if ($r -le 0) {
    $g.FillRectangle((Brush $color), (New-Object System.Drawing.RectangleF($x, $y, $w, $h)))
    return
  }
  $path = RoundRectPath $x $y $w $h $r
  $g.FillPath((Brush $color), $path)
  if ($border -ne "") {
    $g.DrawPath((New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml($border), 1)), $path)
  }
  $path.Dispose()
}

function Text($g, $text, $font, $color, $x, $y, $w = 860, $h = 80) {
  $rect = New-Object System.Drawing.RectangleF($x, $y, $w, $h)
  $format = New-Object System.Drawing.StringFormat
  $format.Trimming = [System.Drawing.StringTrimming]::EllipsisCharacter
  $g.DrawString($text, $font, (Brush $color), $rect, $format)
}

function CenterText($g, $text, $font, $color, $x, $y, $w, $h) {
  $rect = New-Object System.Drawing.RectangleF($x, $y, $w, $h)
  $format = New-Object System.Drawing.StringFormat
  $format.Alignment = [System.Drawing.StringAlignment]::Center
  $format.LineAlignment = [System.Drawing.StringAlignment]::Center
  $format.Trimming = [System.Drawing.StringTrimming]::EllipsisCharacter
  $g.DrawString($text, $font, (Brush $color), $rect, $format)
}

function DrawHomeIcon($g, $x, $y, $color) {
  $pen = NewPen $color 2
  $g.DrawLines($pen, @([System.Drawing.PointF]::new($x - 9, $y + 8), [System.Drawing.PointF]::new($x, $y - 1), [System.Drawing.PointF]::new($x + 9, $y + 8)))
  $g.DrawRectangle($pen, $x - 6, $y + 8, 12, 11)
  $pen.Dispose()
}

function DrawAddIcon($g, $x, $y, $color) {
  $pen = NewPen $color 2
  $g.DrawEllipse($pen, $x - 9, $y, 18, 18)
  $g.DrawLine($pen, $x, $y + 4, $x, $y + 14)
  $g.DrawLine($pen, $x - 5, $y + 9, $x + 5, $y + 9)
  $pen.Dispose()
}

function DrawRecordsIcon($g, $x, $y, $color) {
  $pen = NewPen $color 2
  $g.DrawRectangle($pen, $x - 8, $y + 1, 16, 17)
  $g.DrawLine($pen, $x - 8, $y + 6, $x + 8, $y + 6)
  $g.DrawLine($pen, $x - 4, $y - 2, $x - 4, $y + 4)
  $g.DrawLine($pen, $x + 4, $y - 2, $x + 4, $y + 4)
  $pen.Dispose()
}

function DrawReportIcon($g, $x, $y, $color) {
  $pen = NewPen $color 2
  $g.DrawLine($pen, $x - 10, $y + 16, $x - 4, $y + 9)
  $g.DrawLine($pen, $x - 4, $y + 9, $x + 2, $y + 12)
  $g.DrawLine($pen, $x + 2, $y + 12, $x + 10, $y + 3)
  $pen.Dispose()
}

function DrawHealthIcon($g, $x, $y, $color) {
  $pen = NewPen $color 2
  $g.DrawRectangle($pen, $x - 10, $y + 4, 20, 12)
  $g.DrawLine($pen, $x - 7, $y + 10, $x - 2, $y + 10)
  $g.DrawLine($pen, $x - 2, $y + 10, $x + 1, $y + 6)
  $g.DrawLine($pen, $x + 1, $y + 6, $x + 4, $y + 14)
  $g.DrawLine($pen, $x + 4, $y + 14, $x + 8, $y + 10)
  $pen.Dispose()
}

function DrawSettingsIcon($g, $x, $y, $color) {
  $pen = NewPen $color 2
  $g.DrawEllipse($pen, $x - 7, $y + 2, 14, 14)
  $g.DrawEllipse($pen, $x - 2, $y + 7, 4, 4)
  $g.DrawLine($pen, $x, $y - 2, $x, $y + 1)
  $g.DrawLine($pen, $x, $y + 17, $x, $y + 20)
  $g.DrawLine($pen, $x - 11, $y + 9, $x - 8, $y + 9)
  $g.DrawLine($pen, $x + 8, $y + 9, $x + 11, $y + 9)
  $pen.Dispose()
}

function DrawNavIcon($g, $key, $x, $color) {
  switch ($key) {
    "home" { DrawHomeIcon $g $x 852 $color }
    "add" { DrawAddIcon $g $x 852 $color }
    "records" { DrawRecordsIcon $g $x 852 $color }
    "report" { DrawReportIcon $g $x 852 $color }
    "health" { DrawHealthIcon $g $x 852 $color }
    "settings" { DrawSettingsIcon $g $x 852 $color }
  }
}

function Nav($g, $active) {
  FillRound $g 0 842 923 58 0 "#EAF3EF" ""
  $items = @(
    @("홈", 76, "home"),
    @("추가", 230, "add"),
    @("기록", 384, "records"),
    @("리포트", 538, "report"),
    @("몸상태", 692, "health"),
    @("설정", 850, "settings")
  )
  foreach ($item in $items) {
    $label = $item[0]; $x = [int]$item[1]; $key = $item[2]
    if ($key -eq $active) {
      FillRound $g ($x - 33) 850 66 32 16 "#CFEADF" ""
    }
    $color = if ($key -eq $active) { "#284A40" } else { "#34413C" }
    DrawNavIcon $g $key $x $color
    CenterText $g $label $fontNav "#34413C" ($x - 34) 878 68 18
  }
}

function Chip($g, $text, $x, $y, $w = 80, $selected = $false) {
  $bg = if ($selected) { "#CFEADF" } else { "#FFFFFF" }
  FillRound $g $x $y $w 34 9 $bg "#B7C2C6"
  CenterText $g $text $fontBody "#34413C" $x $y $w 34
}

function InputBox($g, $label, $value, $x, $y, $w, $suffix = "") {
  Text $g $label $fontSmall "#6B7780" ($x + 16) ($y - 10) 150 20
  FillRound $g $x $y $w 48 14 "#FFFFFF" "#9DA9AE"
  Text $g $value $fontBody "#34413C" ($x + 16) ($y + 12) ($w - 80) 24
  if ($suffix -ne "") { Text $g $suffix $fontBody "#34413C" ($x + $w - 48) ($y + 12) 40 24 }
}

function FoodPhoto($g, $x, $y, $w, $h) {
  FillRound $g $x $y $w $h 16 "#D9B27C" ""
  $g.FillRectangle((Brush "#C9965E"), $x, $y + 5, $w, $h - 10)
  $plate = Brush "#FFFFFF"
  $shadow = Brush "#E8E4DD"
  $accent = Brush "#1F9D7A"
  $orange = Brush "#D96A2B"
  $dark = Brush "#6D4C3D"
  $g.FillEllipse($shadow, $x + 245, $y + 165, 360, 105)
  $g.FillEllipse($plate, $x + 250, $y + 158, 350, 92)
  $g.FillEllipse($dark, $x + 310, $y + 178, 230, 38)
  $g.FillEllipse((Brush "#D8B57B"), $x + 330, $y + 166, 190, 52)
  $g.FillEllipse($orange, $x + 410, $y + 158, 14, 14)
  $g.FillEllipse($orange, $x + 448, $y + 164, 14, 14)
  $g.FillEllipse($accent, $x + 388, $y + 170, 18, 8)
  $g.FillEllipse($plate, $x + 165, $y + 340, 190, 92)
  $g.FillEllipse((Brush "#4C2D24"), $x + 190, $y + 358, 120, 48)
  $g.FillEllipse($plate, $x + 430, $y + 328, 245, 110)
  $g.FillEllipse((Brush "#DDB96A"), $x + 455, $y + 350, 190, 62)
  $g.FillEllipse($accent, $x + 530, $y + 360, 22, 14)
  $g.FillEllipse($orange, $x + 555, $y + 365, 20, 12)
  $g.FillEllipse($plate, $x + 135, $y + 100, 160, 58)
  $g.FillEllipse($orange, $x + 170, $y + 116, 80, 25)
  $g.FillEllipse($plate, $x + 338, $y + 60, 150, 58)
  $g.FillRectangle((Brush "#E59B44"), $x + 378, $y + 78, 58, 34)
  $g.FillEllipse($plate, $x + 550, $y + 92, 160, 58)
  $g.FillEllipse((Brush "#74A860"), $x + 590, $y + 108, 70, 25)
  $g.FillEllipse($plate, $x + 110, $y + 220, 160, 70)
  $g.FillRectangle((Brush "#9B6A4F"), $x + 150, $y + 238, 70, 28)
}

function NewScreen($file, $title, $active, $drawContent, $subtitle = "") {
  $bmp = New-Object System.Drawing.Bitmap 923, 900
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
  $g.Clear([System.Drawing.ColorTranslator]::FromHtml("#F6F8FA"))
  Text $g $title $fontTitle "#172026" 18 20 860 42
  if ($subtitle -ne "") { Text $g $subtitle $fontMuted "#6B7780" 18 60 860 24 }
  & $drawContent $g
  Nav $g $active
  $bmp.Save((Join-Path $outDir $file), [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose()
  $bmp.Dispose()
}

NewScreen "add-photo.png" "식단 추가" "add" {
  param($g)
  Text $g "사진" $fontSection "#172026" 18 100 120 28
  FillRound $g 20 137 883 594 18 "#FFFFFF" "#DDE5E8"
  FoodPhoto $g 36 151 851 478
  FillRound $g 37 643 849 30 16 "#FFFFFF" "#9DA9AE"
  CenterText $g "▣  사진 업로드" $fontBody "#1F9D7A" 37 643 849 30
  FillRound $g 37 684 849 30 16 "#FFFFFF" "#9DA9AE"
  CenterText $g "▣  카메라 촬영" $fontBody "#1F9D7A" 37 684 849 30
  FillRound $g 17 747 890 52 26 "#23A27F" ""
  CenterText $g "✦  AI로 사진 속 음식 찾기" $fontCardTitle "#FFFFFF" 17 747 890 52
  Text $g "식사 시간" $fontSection "#172026" 18 825 160 26
} "사진 기반 AI 후보는 참고용이며 최종 영양 계산은 로컬 음식 DB로 처리합니다."

NewScreen "add-save.png" "식단 추가" "add" {
  param($g)
  FillRound $g 14 12 889 52 26 "#23A27F" ""
  CenterText $g "✦  AI로 사진 속 음식 찾기" $fontCardTitle "#FFFFFF" 14 12 889 52
  Text $g "식사 시간" $fontSection "#172026" 18 90 160 26
  FillRound $g 18 124 881 191 18 "#FFFFFF" "#DDE5E8"
  Text $g "먹은 날짜/시간" $fontBody "#34413C" 32 152 180 28
  Text $g "◷  5/5 0:03" $fontBody "#1F9D7A" 790 152 100 28
  $g.DrawLine((NewPen "#DDE5E8" 1), 32, 190, 884, 190)
  Text $g "식사 시작" $fontBody "#34413C" 32 214 180 28
  Text $g "◷  5/5 0:03" $fontBody "#1F9D7A" 790 214 100 28
  $g.DrawLine((NewPen "#DDE5E8" 1), 32, 250, 884, 250)
  Text $g "식사 종료" $fontBody "#34413C" 32 276 180 28
  Text $g "◷  5/5 0:18" $fontBody "#1F9D7A" 790 276 100 28
  Text $g "음식 검색" $fontSection "#172026" 18 346 180 28
  FillRound $g 18 377 885 50 14 "#FFFFFF" "#172026"
  Text $g "⌕  고등어" $fontBody "#34413C" 28 392 300 24
  FillRound $g 18 444 881 60 16 "#FFFFFF" "#DDE5E8"
  FillRound $g 40 457 38 38 19 "#EAF3EF" ""
  CenterText $g "🍴" $fontBody "#1F9D7A" 40 457 38 38
  Text $g "고등어구이" $fontCardTitle "#172026" 88 456 160 24
  Text $g "생선 · 1인분 180g" $fontMuted "#6B7780" 88 482 220 20
  Text $g "205kcal/100g" $fontSmall "#6B7780" 805 464 90 20
  FillRound $g 17 533 887 52 26 "#23A27F" ""
  CenterText $g "✓  저장" $fontCardTitle "#FFFFFF" 17 533 887 52
} ""

NewScreen "home.png" "오늘식단 AI" "home" {
  param($g)
  Text $g "5월 5일 화요일" $fontMuted "#6B7780" 18 60 220 22
  FillRound $g 20 95 881 188 18 "#FFFFFF" "#DDE5E8"
  Text $g "오늘 총 섭취" $fontMuted "#6B7780" 40 119 160 22
  Text $g "369kcal" $fontTitle "#172026" 40 149 220 44
  $g.FillRectangle((Brush "#DDE5E8"), 40, 198, 840, 10)
  $g.FillRectangle((Brush "#23A27F"), 40, 198, 155, 10)
  Text $g "목표" $fontMuted "#6B7780" 40 226 100 20
  Text $g "2000kcal" $fontBody "#172026" 40 248 140 24
  Text $g "진행률" $fontMuted "#6B7780" 320 226 100 20
  Text $g "18%" $fontBody "#172026" 320 248 80 24
  Text $g "남은 칼로리" $fontMuted "#6B7780" 600 226 130 20
  Text $g "1631kcal" $fontBody "#172026" 600 248 130 24
  FillRound $g 20 308 881 94 18 "#FFFFFF" "#DDE5E8"
  CenterText $g "●`n탄수화물`n0.0g" $fontBody "#3478F6" 105 322 160 70
  CenterText $g "●`n단백질`n36.0g" $fontBody "#1F9D7A" 380 322 160 70
  CenterText $g "●`n지방`n24.3g" $fontBody "#E98A15" 660 322 160 70
  Text $g "건강 지표" $fontSection "#172026" 18 434 180 28
  FillRound $g 20 468 431 104 16 "#FFFFFF" "#DDE5E8"
  Text $g "BMI" $fontMuted "#6B7780" 36 490 80 20
  Text $g "27.8" $fontCardTitle "#172026" 36 514 100 24
  Text $g "높은 편" $fontMuted "#6B7780" 36 544 100 18
  FillRound $g 470 468 431 104 16 "#FFFFFF" "#DDE5E8"
  Text $g "BMR / 목표" $fontMuted "#6B7780" 486 490 120 20
  Text $g "0 / 2000" $fontCardTitle "#172026" 486 514 140 24
  Text $g "kcal 추정" $fontMuted "#6B7780" 486 544 100 18
  Text $g "식사 기록 상태" $fontSection "#172026" 18 604 200 28
  FillRound $g 20 640 881 76 16 "#FFFFFF" "#DDE5E8"
  CenterText $g "○`n아침" $fontBody "#6B7780" 75 655 120 50
  CenterText $g "●`n점심" $fontBody "#1F9D7A" 290 655 120 50
  CenterText $g "○`n저녁" $fontBody "#6B7780" 505 655 120 50
  CenterText $g "○`n간식" $fontBody "#6B7780" 720 655 120 50
  Text $g "식사 시간 피드백" $fontSection "#172026" 18 750 230 28
  FillRound $g 20 782 881 56 16 "#FFFFFF" "#DDE5E8"
  Text $g "오늘은 아침 기록이 없습니다. 규칙적인 식사 패턴을 유지해보세요." $fontBody "#34413C" 38 802 760 24
} ""

NewScreen "records.png" "식단 기록" "records" {
  param($g)
  FillRound $g 21 72 881 58 18 "#FFFFFF" "#DDE5E8"
  Text $g "‹" $fontTitle "#34413C" 44 86 30 36
  CenterText $g "5월 5일 화요일" $fontBody "#1F9D7A" 300 84 320 32
  Text $g "›" $fontTitle "#34413C" 866 86 30 36
  FillRound $g 21 154 881 61 18 "#FFFFFF" "#DDE5E8"
  Text $g "선택 날짜 총 369kcal" $fontCardTitle "#172026" 38 177 260 28
  Text $g "아침" $fontSection "#172026" 18 246 120 28
  Text $g "기록 없음" $fontMuted "#6B7780" 18 280 120 22
  Text $g "점심" $fontSection "#172026" 18 323 120 28
  FillRound $g 21 357 881 89 16 "#FFFFFF" "#DDE5E8"
  FoodPhoto $g 33 370 64 64
  Text $g "고등어구이" $fontCardTitle "#172026" 110 372 160 24
  Text $g "180g · 369kcal · 0:03" $fontBody "#34413C" 110 398 220 24
  Text $g "탄 0.0g · 단 36.0g · 지 24.3g" $fontMuted "#6B7780" 110 424 260 20
  Text $g "□" $fontSection "#34413C" 862 390 26 30
  Text $g "저녁" $fontSection "#172026" 18 488 120 28
  Text $g "기록 없음" $fontMuted "#6B7780" 18 522 120 22
  Text $g "간식" $fontSection "#172026" 18 566 120 28
  Text $g "기록 없음" $fontMuted "#6B7780" 18 600 120 22
} ""

NewScreen "report.png" "오늘 리포트" "report" {
  param($g)
  FillRound $g 22 98 881 138 18 "#FFFFFF" "#DDE5E8"
  Text $g "369kcal" $fontTitle "#172026" 40 123 180 44
  Text $g "목표 대비 18% · 기록 1개" $fontBody "#34413C" 40 171 260 26
  Text $g "탄 0.0g · 단 36.0g · 지 24.3g" $fontBody "#34413C" 40 203 320 26
  Text $g "피드백" $fontSection "#172026" 18 266 120 28
  $messages = @(
    "오늘 총 섭취 칼로리는 369kcal입니다.",
    "목표 칼로리보다 낮게 섭취했습니다. 활동량이 많았다면 균형 잡힌 식사를 보완해보세요.",
    "지방 섭취 비중이 높은 편입니다. 기름진 음식의 양을 조절해보세요.",
    "탄단지 기록은 탄수화물 0.0g, 단백질 36.0g, 지방 24.3g입니다.",
    "점심 식사의 칼로리 비중이 가장 높습니다.",
    "현재 BMI는 27.8로 높은 편입니다.",
    "추정 기초대사량은 0kcal, 유지 칼로리는 0kcal입니다."
  )
  $y = 301
  foreach ($message in $messages) {
    FillRound $g 22 $y 881 55 16 "#FFFFFF" "#DDE5E8"
    CenterText $g "✓" $fontCardTitle "#1F9D7A" 38 ($y + 13) 24 24
    Text $g $message $fontBody "#34413C" 72 ($y + 17) 780 24
    $y += 74
  }
} "외부 AI 없이 규칙 기반 템플릿으로 생성됩니다."

NewScreen "health.png" "내 몸 상태" "health" {
  param($g)
  Text $g "기본 정보" $fontSection "#172026" 18 104 160 28
  InputBox $g "닉네임" "이우석" 18 136 890
  Chip $g "✓  남성" 18 196 82 $true
  Chip $g "여성" 108 196 60 $false
  Chip $g "기타" 176 196 60 $false
  FillRound $g 18 242 890 30 15 "#FFFFFF" "#9DA9AE"
  CenterText $g "♧  생년월일 선택" $fontBody "#1F9D7A" 18 242 890 30
  InputBox $g "키" "180" 18 286 440 "cm"
  InputBox $g "몸무게" "90" 468 286 440 "kg"
  InputBox $g "목표 체중" "80" 18 346 890 "kg"
  Text $g "활동과 목표" $fontSection "#172026" 18 418 180 28
  InputBox $g "활동량" "가벼운 활동" 18 452 890
  Chip $g "✓  감량" 18 511 82 $true
  Chip $g "유지" 108 511 60 $false
  Chip $g "증량" 176 511 60 $false
  FillRound $g 18 557 890 30 15 "#FFFFFF" "#9DA9AE"
  CenterText $g "☾  평소 취침 시간 11:30 PM" $fontBody "#1F9D7A" 18 557 890 30
  Text $g "추정 건강 지표" $fontSection "#172026" 18 616 200 28
  FillRound $g 23 650 878 106 16 "#FFFFFF" "#DDE5E8"
  Text $g "BMI" $fontMuted "#6B7780" 39 670 80 20
  Text $g "27.8" $fontCardTitle "#172026" 39 694 100 24
  Text $g "높은 편" $fontMuted "#6B7780" 39 724 100 18
  FillRound $g 23 775 878 84 16 "#FFFFFF" "#DDE5E8"
  Text $g "기초대사량 / 유지 칼로리" $fontMuted "#6B7780" 39 796 200 20
  Text $g "0 / 0kcal" $fontCardTitle "#172026" 39 820 140 24
} "영양 정보는 데모용 추정값이며 건강 진단 또는 처방이 아닙니다."

NewScreen "settings.png" "설정" "settings" {
  param($g)
  Text $g "프로필" $fontSection "#172026" 18 92 120 28
  InputBox $g "이름 또는 닉네임" "이우석" 18 124 890
  InputBox $g "목표 칼로리" "2000" 18 184 890 "kcal"
  InputBox $g "키" "180" 18 244 440 "cm"
  InputBox $g "몸무게" "90" 468 244 440 "kg"
  Text $g "목표" $fontSection "#172026" 18 316 120 28
  FillRound $g 18 346 890 32 16 "#F6F8FA" "#9DA9AE"
  FillRound $g 18 346 297 32 16 "#CFEADF" "#9DA9AE"
  CenterText $g "✓  감량" $fontBody "#34413C" 18 346 297 32
  CenterText $g "유지" $fontBody "#34413C" 315 346 297 32
  CenterText $g "증량" $fontBody "#34413C" 612 346 296 32
  FillRound $g 18 402 890 52 26 "#23A27F" ""
  CenterText $g "▣  설정 저장" $fontCardTitle "#FFFFFF" 18 402 890 52
  FillRound $g 0 787 923 48 0 "#24302B" ""
  Text $g "설정이 저장되었습니다." $fontBody "#FFFFFF" 22 805 260 24
} "목표 칼로리는 직접 입력합니다. BMR 계산은 추후 확장 범위입니다."

