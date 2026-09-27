# chili-dks SDDM 테마 Qt5 → Qt6 포팅

상태: 구현·검증 완료 (2026-09-27). 이 문서는 계획과 실제 구현 결과를 함께 기록한다.

## Context
chili-dks는 Qt5 시절 Chili 테마 기반이라 `QtQuick.Controls 1.4`, `QtGraphicalEffects`, `onFoo:` 형태의 Connections 등 Qt6에서 사라지거나 deprecated된 API를 쓴다. 시스템에는 Qt 6.11.2(qtdeclarative, qt5compat, qtsvg)와 SDDM `0.21.0_p20251101`(Qt6 빌드, `/usr/bin/sddm-greeter-qt6`)이 설치되어 있다. 포팅 전 테마는 `module "QtQuick.Controls" version 1.4 is not installed` 오류 후 `Fallback to embedded theme`으로 내장 테마로 대체되었다. 목표는 Qt6 SDDM greeter에서 기존과 같은 모양·동작으로 이 테마가 로드되게 하는 것이다. Qt5 병행 지원은 하지 않는다(이전 버전은 git 히스토리에 남는다).

결정 사항(사용자 확인): 효과는 `Qt5Compat.GraphicalEffects`로 대체한다(MultiEffect 아님).

SDDM 확인 결과: `QtVersion` 메타데이터는 검사하지 않고 `QQuickStyle`도 지정하지 않는다. 따라서 Controls 2 기본(Basic) 스타일 위에서 동작하도록 `background`/`contentItem`을 직접 지정했다. `SddmComponents 2.0`(Clock, TextConstants)은 그대로 쓴다.

## 변경 내용 (모두 chili-dks/ 아래)

### 계획대로 한 것
1. **import** — `QtQuick 2.x`/`Layouts 1.1`/`Controls 1.4` → 버전 없는 import. `QtQuick.Controls.Styles`는 삭제. `QtGraphicalEffects` → `Qt5Compat.GraphicalEffects`(UserDelegate, Wallpaper). `Instantiator`를 쓰는 SessionMenu, KeyboardLayoutButton에 `import QtQml` 추가.
2. **Connections** — `onLoginFailed:` → `function onLoginFailed()` (Main.qml, LoginForm.qml).
3. **LoginForm.qml TextField** — `style: TextFieldStyle`을 `color`/`placeholderTextColor`/`background`로 옮김.
4. **KeyboardLayoutButton.qml** — `style`/`menu:`를 `contentItem`/`background` + 자식 `Menu`(`onClicked: open()`, 버튼 아래 `y: height`)로 교체. Instantiator 핸들러는 `(index, object) =>` 인자를 명시.
5. **SessionMenu.qml** — 같은 방식으로 교체. 푸터가 화면 하단이므로 메뉴는 `y: -height`로 버튼 위에 열림. `menu.items.length` → `menu.count`, 초기 `currentIndex = -1`에서 null 접근이 나지 않도록 label 텍스트를 가드.
6. **VirtualKeyboard.qml** — `import QtQuick.VirtualKeyboard`(버전 제거). qtvirtualkeyboard가 없으면 Loader만 오류를 내고 나머지 UI는 정상이다.
7. **metadata.desktop** — `QtVersion=6`. README.org와 chili-dks/README.md의 의존성 목록을 Qt6 기준으로 갱신.

### 테스트가 잡아내 추가로 고친 Qt6 회귀 (계획에 없던 것)
8. **초기 포커스** ([LoginForm.qml](chili-dks/components/LoginForm.qml)) — Qt Quick Controls 2의 StackView는 push한 아이템(LoginForm)에 직접 focus를 주어 이미 `focus: true`였던 passwordField의 포커스를 빼앗는다. 그 결과 로그인 화면에서 바로 타이핑해도 입력이 안 됐다. `StackView.onActivated: passwordField.forceActiveFocus()`로 해결. `FocusScope` 방식은 Escape 동작(`loginFormStack.currentItem.forceActiveFocus()`으로 포커스를 빼는 것)을 바꾸므로 쓰지 않았다.
9. **마지막 로그인 사용자 선택** ([UserList.qml](chili-dks/components/UserList.qml)) — `userListCurrentIndex: 1`이어도 항상 첫 사용자가 선택됐다. StackView가 생성 후에 크기를 주면 `highlightRangeMode: StrictlyEnforceRange`의 하이라이트 범위가 바뀌고, Qt6가 스크롤 위치로부터 currentIndex를 다시 계산해 0으로 되돌리기 때문이다(변인 격리로 확인). 크기 변경 동안 범위 강제를 잠시 끄고, 안정된 뒤에 index를 저장했다가 복원한다. `ApplyRange`나 범위 제거는 현재 사용자가 중앙에 오지 않아 채택하지 않았다.
10. **레이아웃 진동** ([LoginFormLayout.qml](chili-dks/components/LoginFormLayout.qml)) — `Layout.bottomMargin: actionItemsLayout.height * 4`가 자기 자신의 높이에 의존해 Qt6에서 `possible QQuickItem::polish() loop` 경고와 함께 레이아웃이 진동했다. 같은 값을 주는 `implicitHeight`로 교체.
11. **에셋 경로** ([Main.qml](chili-dks/Main.qml)) — Qt6는 alias 대상(Image)이 속한 파일 기준으로 상대경로를 해석해서 전원 아이콘 3개와 배경 이미지가 `components/assets/…`에서 열리지 못했다. `Qt.resolvedUrl(...)`로 Main.qml 기준 경로를 명시.
12. **`Keys.onPressed`** ([LoginForm.qml](chili-dks/components/LoginForm.qml)) — 암묵 `event` 주입은 Qt6에서 deprecated이므로 `(event) =>`로 명시.
13. **qtvirtualkeyboard 설치 후 greeter 무한 루프** ([Main.qml](chili-dks/Main.qml)) — qtvirtualkeyboard가 없을 땐 가상 키보드 `Loader`가 비어 있어 드러나지 않았다. 모듈이 설치되면 `InputPanel`이 로드되고, ColumnLayout이 관리하는 Loader에 준 `anchors { left; right }`와 `InputPanel`의 `width: parent.width`가 서로 물려 `possible QQuickItem::polish() loop`가 끝없이 반복됐다. greeter 메인 스레드가 CPU 100%로 멈추고 SIGTERM에도 반응하지 않았다(실제 로그인 화면이었다면 멈춘 화면). `anchors`를 `Layout.fillWidth: true`로 교체해 해결. 스모크 테스트에 `timeout -k`를 넣어 이런 hang을 실패로 잡게 했다.

### 추가 요청: 자체 Clock 컴포넌트
14. [components/Clock.qml](chili-dks/components/Clock.qml) 추가. SDDM `SddmComponents/Clock.qml`(MIT, 헤더에 저작권·라이선스 고지 유지)과 같은 API(`dateTime`, `color`, `timeFont`, `dateFont`)이고, 날짜만 `toLocaleDateString(Qt.locale(), Locale.LongFormat)`로 표시한다. SDDM의 Clock은 Qt6에서 사라진 `Qt.DefaultLocaleLongDate`를 써서 짧은 숫자 날짜(`9/27/26`)로 떨어진다. Main.qml은 이름 충돌을 피하려고 `import SddmComponents 2.0 as Sddm`(`Sddm.TextConstants`)로 바꿔 `components/Clock.qml`이 확실히 선택되게 했다.

## 가상 키보드 (참고)
qtvirtualkeyboard(6.11.2)가 설치된 지금, `components/VirtualKeyboard.qml`(`InputPanel`)은 오류 없이 로드된다. 그러나 **이 테마에서 가상 키보드는 화면에 나타나지 않는다.** 이는 원래 chili 테마 구조에서 온 것이며 이번 포팅으로 생긴 문제가 아니다.

### 나타나지 않는 이유
1. **켜는 진입점이 없다** (grep으로 확인): Main.qml의 `inputPanel.showHide()`는 정의만 있고 호출하는 곳이 테마 어디에도 없다. 또 `VirtualKeyboard.qml`의 `active: activated && Qt.inputMethod.visible`에서 `activated`는 처음 false이고 Main.qml의 숨김→표시 전환 스크립트(`inputPanel.item.activated = true`)에서만 true가 된다. 그 전환은 `keyboardActive`(= `item.active`, 곧 `activated`에 의존)나 `showHide()`로만 시작되므로, `showHide()` 없이는 시작될 수 없다. (마지막 부분은 코드를 읽고 추론한 것이며 실행으로 확인하지는 않았다.)
2. **입력 모듈이 꺼져 있다** (확인): 시스템의 `/etc/sddm.conf.d/01gentoo.conf`가 `InputMethod=`를 비워 두었다.

### 이번에 한 것
13번 하나뿐이다. 모듈이 설치되어도 greeter가 멈추지 않게 했고, 이는 스모크 테스트가 검증한다. 키보드가 실제로 뜨고 사라지는 동작은 검증하지 않았다.

### 실제로 쓰려면 필요한 작업 (이번에 하지 않음)
1. 키보드를 여는 진입점을 추가한다(예: `inputPanel.showHide()`를 부르는 버튼).
2. `sddm.conf`(또는 `/etc/sddm.conf.d/`)에 `InputMethod=qtvirtualkeyboard`를 설정한다. 현재 값을 비워 둔 것은 시스템 설정이라 임의로 바꾸지 않았다.
3. Main.qml의 표시/숨김 전환이 참조하는 두 가지를 고친다.
   - `units.longDuration`: Plasma 전용이라 SDDM greeter에는 없다. greeter에서 `typeof units`가 `undefined`이고 접근하면 `ReferenceError: units is not defined`가 나는 것을 확인했다(`config`, `keyboard`, `sessionModel`은 정상). 고정 duration으로 바꿔야 한다.
   - `userListComponent.visibleBoundary`(`Main.qml:193`): 어디에도 정의되지 않은 속성이라 `undefined`다. 코드상 `y` 계산이 NaN이 되므로 정의하거나 제거해야 한다(실행으로 확인하지는 않았다).

## 손대지 않은 것 (발견했지만 이번 범위 밖)
- 레이아웃 안에서 `anchors`를 쓰는 곳(ActionButton): Qt가 경고를 내지만 Qt5 시절부터의 설계다. 스모크 테스트는 이 경고만 허용 목록에 둔다.
- 가상 키보드가 나타나지 않는 것, `units.longDuration`, `userListComponent.visibleBoundary`: 위의 "가상 키보드 (참고)" 절 참고.
- 시작 시 `QFont::setPointSizeF: Point size <= 0` 출력(레이아웃 확정 전 크기 0).
- Main.qml의 `color: "light grey"`(유효하지 않은 색 이름), metadata.desktop의 `Screenshot=preview.jpg`(실제 파일은 preview.png), UserList.qml의 `"...", "Unused"` 콤마 표현식, assets의 `.bak`/`.orig` 파일.

## 검증 — TDD 결과
테스트는 테마 배포물에 섞이지 않도록 저장소 루트의 [tests/](tests/)에 둔다. `tests/run.sh` 하나로 돌리며, 기본은 `QT_QPA_PLATFORM=offscreen`이다.

1. **greeter 스모크** — [tests/smoke_greeter.sh](tests/smoke_greeter.sh). 실제 `sddm-greeter-qt6 --test-mode`로 테마를 8초간 띄워 내장 테마 fallback과 QML 오류·경고(`\.qml:NNN`)를 실패로 취급한다. 허용하는 것은 VirtualKeyboard 모듈 부재와 위의 anchors 경고뿐이다. greeter가 SIGTERM에 반응하지 않으면(무한 루프) 실패로 처리한다.
2. **컴포넌트 동작 테스트** — QtQuickTest `tests/tst_*.qml` (ActionButton, Clock, KeyboardLayoutButton, LoginForm, SessionMenu, UserDelegate, Wallpaper). 클릭·키 입력·포커스·메뉴·신호 같은 동작을 검증하고, deprecated 경고(`failOnWarning`)도 실패로 취급한다.
3. **RED → GREEN**: 포팅 전 스모크가 `Controls 1.4` 오류로 실패하는 것을 확인했고, 컴포넌트마다 테스트를 먼저 작성해 실패를 본 뒤 고쳤다. 8~13번 회귀는 모두 테스트가 먼저 발견했다. Clock(14번)은 테스트를 먼저 쓰고 `Clock is not a type`으로 실패하는 것을 확인한 뒤 구현했다.
4. **뮤테이션 점검**: 결함 22종(메뉴 선택 미반영, 메뉴가 버튼을 가림, 포커스 미부여, 인덱스 리셋, 중앙 정렬 상실, polish loop, 경로 미해석, Qt5 import 복귀, Loader anchors 복귀로 인한 hang, Clock의 짧은 날짜·틱 없음·색상 무시 등)을 복사본에 주입해 모두 테스트가 실패함을 확인했다(기준선 통과를 먼저 확인). 처음에 살아남은 2종(메뉴가 버튼을 덮는 경우, 텍스트가 있을 때의 Left 키)은 테스트를 강화했다.
5. **결과**: `tests/run.sh` → 스모크 통과 + 컴포넌트 40건 통과·1건 skip(오프스크린의 소프트웨어 렌더러는 ShaderEffect를 그리지 못해 아바타 마스크 픽셀 테스트를 skip). `QT_QPA_PLATFORM=xcb tests/run.sh` → 41건 전부 통과. Clock 테스트는 en_US와 ko_KR 로케일 모두 통과한다.
6. **시각 확인**: X 세션에서 `sddm-greeter-qt6 --test-mode`를 GPU 렌더링으로 띄워 캡처한 화면이 기존 `Screenshot.png`와 동일한 구성(배경, 원형 아바타, 비밀번호 필드, 전원 아이콘, 시계, 세션 메뉴)임을 확인했다. Clock 추가 후 날짜도 `Sunday, September 27, 2026` 형식으로 기존과 같다.

### 이 환경에서 확인하지 못한 것
실제 로그인 화면(display manager 시작, PAM 인증, 실제 사용자 아바타)은 테스트 모드의 mock 모델로만 확인했다. SDDM 설정에서 `Current=chili-dks`로 지정해 실제 부팅에서 한 번 확인하는 것을 권한다.
