# Pilot Spring MVC Sample

이 저장소에는 GitHub 기능 테스트용으로 간단한 Ant 기반 Spring MVC 웹 프로젝트가 추가되었습니다.

## 구성
- `build.xml` : Ant 빌드
- `src/main/java` : Java 소스
- `src/main/webapp` : JSP / WEB-INF 리소스
- `.tools/jdk8` : 로컬 JDK 8
- `.tools/ant` : 로컬 Ant

## 빌드
```bash
cd /home/signpen/myapps/pilot
JAVA_HOME="$PWD/.tools/jdk8" PATH="$PWD/.tools/ant/bin:$JAVA_HOME/bin:$PATH" ant war
```

## 결과물
- `dist/pilot.war`

## 화면
- `/home` 요청 시 샘플 JSP 화면 표시
