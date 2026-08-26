# First prompt to send in ChatGPT Work

Use the repository connected through GitHub.

Paste this as the first development instruction:

---

먼저 이 GitHub repository의 `AGENTS.md`, `GAME_DESIGN.md`, `PROTOTYPE_HISTORY.md`, `AUDIO_RULES.md`, `ART_DIRECTION.md`, `VIRAL_DESIGN.md`, `CLOUD_DEV_WORKFLOW.md`를 전부 읽어.

`reference/web-prototypes/` 안의 HTML은 지금까지 플레이 감각을 검증한 참고 구현이다. 특히 최신 프로토타입을 기준으로 동작과 연출을 파악하되, HTML 구조를 그대로 옮기려고 하지 말고 Godot에 맞게 설계해.

그 다음 HALF STEP을 Godot 4.x + GDScript 프로젝트로 구현해.

중요:
- 코어 조작 규칙은 `AGENTS.md`가 절대 우선이다.
- 탭 입력을 절대 씹지 마.
- 플레이 중 속도가 느려지는 연출을 만들지 마.
- 좌/우 같은 자리 반복 성공도 정상 동작해야 한다.
- PERFECT 시스템은 만들지 마.
- 죽을 때 실패 위치에서 깊이 방향으로 작아지며 사라져야 한다.
- 게임 규칙을 임의로 더 복잡하게 만들지 마.

우선 작업:
1. 최소 Godot 프로젝트 구조 생성
2. 순수 gameplay state / presentation 분리
3. 두 lane + 자동 cadence + safe platform + score + death + retry 구현
4. 상승 success melody 구현
5. 속도 곡선 구현
6. high-score zone 데이터를 구조화
7. headless gameplay tests 작성
8. cloud 환경에서 가능한 테스트를 모두 실행
9. 가능하면 portrait visual snapshot 테스트 구성
10. Android CI/export 골격 구성

변경 후 어떤 테스트를 실제로 실행했고 무엇은 아직 실기기에서 확인해야 하는지 구분해서 보고해.

---

## Follow-up development prompt example

`VOID CURRENT` 이후 비주얼을 강화해. 코어 조작/속도 공식/플랫폼 판정은 변경하지 마. score 400을 강제로 재현하는 visual test mode를 사용해서 스크린샷을 생성하고, 가능한 경우 직접 확인한 뒤 수정해. 테스트 후 PR 변경사항을 정리해.
