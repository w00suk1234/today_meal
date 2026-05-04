# GitHub 업로드 가이드

추천 저장소 이름:

```text
today-meal
```

추천 설명:

```text
Flutter portfolio app for AI-assisted meal logging, health metrics, and meal timing feedback.
```

## 1. Git 설치 확인

VSCode 터미널에서:

```powershell
git --version
```

안 되면 Git for Windows를 설치한 뒤 VSCode를 완전히 다시 열어야 합니다.

## 2. GitHub에서 새 저장소 생성

GitHub에서 `today-meal` 이름으로 새 repository를 만듭니다.

- Public 추천
- README 생성 체크 해제
- .gitignore 생성 체크 해제
- License 생성 체크 해제

## 3. 로컬 프로젝트 업로드

프로젝트 루트에서:

```powershell
git init
git add .
git commit -m "Initial commit: 오늘의 식단 Flutter MVP"
git branch -M main
git remote add origin https://github.com/YOUR_ID/today-meal.git
git push -u origin main
```

`YOUR_ID`는 본인 GitHub 아이디로 바꿉니다.

## 4. 이후 수정 업로드

```powershell
git add .
git commit -m "Update meal AI and health profile features"
git push
```
