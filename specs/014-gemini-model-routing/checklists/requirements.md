# Quality Checklist: Gemini Multi-Model Routing Requirements

- [ ] **Slash Command Support**: Telegram bot parses `/model`, `/model flash`, `/model pro`, and `/model status` commands cleanly.
- [ ] **Session Model Persistence**: Active model choice per chat session persists across prompt turns.
- [ ] **Automatic Fallback Handler**: Rate-limiting (HTTP 429) or quota errors on primary model trigger seamless fallback execution to `gemini-2.5-flash`.
- [ ] **User Feedback**: User is informed when a fallback model was utilized for their query response.
- [ ] **Verification Script (`scripts/test_model_routing.sh`)**: Executable script validating model selection dispatch and fallback trigger handling.
