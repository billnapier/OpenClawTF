# Product Requirements Document (PRD): OpenClaw / NanoGemClaw on GCP

This document defines the product vision, user personas, Critical User Journeys (CUJs), access control experience, and error-handling requirements for **OpenClaw / NanoGemClaw**.

---

## 1. Product Vision & Success Metrics

### Vision
OpenClaw is a private, cloud-native AI assistant running on Google Cloud Platform (GCP). It connects the Google Gemini API to end-users via Telegram, providing persistent conversation memory, automated tool execution, and zero-trust security without exposing inbound public network ports.

### Target Success Metrics
* **Admin Onboarding Time**: Infrastructure setup and initial deployment completed in under 15 minutes.
* **User Onboarding Friction**: Zero third-party tools required for users to discover their numeric Telegram User ID.
* **Response Feedback Latency**: `< 1.0s` from user message to Telegram `typing...` status indicator.
* **Service Reliability**: Transparent error UX during Gemini API rate limits or transient cloud restarts.

---

## 2. User Personas

### Persona A: Administrator (Cloud Owner)
* **Profile**: Technical user or DevOps engineer managing GCP resources.
* **Goals**: Deploy OpenClaw securely, manage user whitelists, keep operational costs low, and maintain zero inbound attack surface.
* **Key Tasks**: Provisioning Terraform, adding user IDs to GCP Secret Manager, monitoring automated GitOps deployments.

### Persona B: End-User (Telegram Conversationalist)
* **Profile**: Non-technical or technical user interacting with the AI agent via Telegram.
* **Goals**: Access Gemini model capabilities, execute multi-turn tasks, manage chat context, and receive clear feedback during long-running prompt executions.
* **Key Tasks**: Messaging the bot, issuing slash commands (`/start`, `/help`, `/reset`), receiving structured answers and tool execution results.

---

## 3. Critical User Journeys (CUJs)

### CUJ 1: First-Time Onboarding & Capability Discovery
1. **User Action**: The authorized user opens Telegram and taps **Start** or sends `/start`.
2. **System Response**: The bot returns a friendly welcome message introducing OpenClaw, confirming user authorization, and displaying available commands via `/help`.
3. **Behavioral Constraint**: Leverage native OpenClaw Telegram default handlers where available to avoid duplicating core engine logic.

### CUJ 2: Conversational Task Execution & Session Reset
1. **User Action**: The user sends multi-turn prompts to complete complex tasks or research.
2. **System Response**: The bot maintains persistent conversation state across turns.
3. **Reset Action**: The user issues `/reset` (or native equivalent).
4. **System Response**: The bot clears current session context from RAM/database and acknowledges with *"Conversation context reset."*

### CUJ 3: Access Control & Self-Identification Rejection
1. **User Action**: An unauthorized user (not listed in `TELEGRAM_ALLOWED_USER_IDS`) messages the bot.
2. **System Response**: The bot rejects the request with an explicit rejection message revealing the sender's numeric Telegram User ID:
   > ⛔ **Access Denied**  
   > Your Telegram User ID is `987654321`. Send this ID to your OpenClaw Administrator to request access.
3. **PM Rationale**: Directly solves the onboarding hurdle where non-technical users do not know their Telegram ID.

### CUJ 4: System Error & Availability UX Feedback
1. **Typing Status Indicator**: Immediately upon receiving a prompt, the bot triggers Telegram's `sendChatAction("typing")` status to signal active generation.
2. **Rate Limit Handling (HTTP 429)**: If the Gemini API returns a rate-limit error, the bot responds:
   > ⚠️ **Gemini API Rate Limit Reached**  
   > The model is temporarily rate-limited. Please wait a moment before trying again.
3. **Service Restart Handling**: If the GCE container restarts, user conversation state on the Persistent Disk (`/mnt/disks/openclaw-data`) remains intact upon recovery.
