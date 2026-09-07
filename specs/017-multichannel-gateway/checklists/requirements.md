# Quality Checklist: Multi-Channel Transport Gateway Requirements

- [ ] **Channel Adapter Abstraction**: Abstract `ChannelAdapter` class/interface defined with standard `initialize()`, `poll()`, and `send_message()` contracts.
- [ ] **Telegram Adapter Refactoring**: Telegram gateway refactored to conform to `ChannelAdapter` interface without regressions.
- [ ] **Discord Adapter Integration**: Discord gateway adapter built supporting user whitelist verification via ADC secret fetching.
- [ ] **GCP Secret Manager Parity**: `discord-bot-token` and `discord-allowed-user-ids` definitions and IAM permissions added to `modules/secrets`.
- [ ] **Verification Script (`scripts/test_channel_adapters.sh`)**: Executable validation script verifying channel event normalization, access control enforcement, and multi-channel dispatch.
