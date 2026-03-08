# Strategic Plan: Direct Voice Processing for Telegram Bot

This plan document is a communication tool across multiple different agents. Therefore, every relevant file, every relevant information, and every learning MUST be documented in this file. This file must represent the current state of the effort at all times.

## 1. Understanding the Goal

The objective is to allow the Assisted Intelligence Telegram bot to receive voice memos and process them **directly** using the main Gemini model's native multimodal (audio) capabilities. This eliminates the need for a separate transcription step (e.g., Whisper API), reducing latency and maintaining context better by allowing the model to "hear" the user directly.

**Key Requirements:**
- No intermediate transcription service.
- Support for Telegram's native voice format (.ogg).
- Full integration with existing agent orchestration (tool calling, long-term memory).
- Seamless transition between text and voice interactions.

## 2. Investigation & Analysis

### Current State
- **Telegram Bot (`agent/telegram.js`)**: Uses the `telegraf` library. Currently has a placeholder `handleVoice` method that only acknowledges receipt.
- **AI Brain (`agent/agent.js`)**: Orchestrates the flow between the user message, MCP tools from the Flutter app, and the Gemini model. Currently optimized for text input via `handleUserMessage(text)`.
- **Gemini Service (`agent/gemini.js`)**: Uses `@google/generative-ai` ^0.24.1. Currently supports text-based `chat.sendMessage(prompt)`.
- **Model Support**: The project uses `gemini-2.0-flash` (Fast) and `gemini-3.1-pro-preview` (Smart). Both models are multimodal and support audio input.
- **Audio Format**: Telegram voice memos are typically delivered in Opus-encoded `.ogg` format. Gemini's API supports `audio/ogg` natively.

### Key Files
- `agent/telegram.js`: Entry point for Telegram messages.
- `agent/agent.js`: Core logic for tool discovery and execution.
- `agent/gemini.js`: Wrapper for Google Generative AI SDK.
- `agent/package.json`: Dependencies (includes `node-fetch` and `@google/generative-ai`).
- `data/todos/unsorted/telegram_voice_integration.md`: Existing (outdated) plan mentioning Whisper.

### Critical Questions Answered
- **Does Gemini support .ogg?** Yes, both Flash and Pro models support `audio/ogg`.
- **Can we download files from Telegram?** Yes, `telegraf` provides `getFileLink` to get the URL for `file_id`.
- **Is the SDK ready?** Version 0.24.1 supports `inlineData` parts for base64 audio.

## 3. Proposed Strategic Approach

The implementation will follow a bottom-up approach, starting from the Gemini integration and moving up to the Telegram bot.

### Phase 0: Test-Driven Specification
- **Objective**: Define the expected behavior through tests before any implementation begins.
- **Actions**:
    - Create `agent/test/multimodal.test.js` to define how `GeminiService` should handle audio parts and mixed content.
    - Update `agent/test/system.test.js` to simulate a voice message flowing through the `AgentBrain` to trigger tool calls.
    - Ensure these tests fail as expected (RED state) to provide a clear target for implementation.

### Phase 1: Gemini Service Enhancement (`agent/gemini.js`)
- **Objective**: Allow the service to handle multimodal parts instead of just strings.
- **Actions**:
    - Update `GeminiService.process` to accept `prompt` as either a `string` or an `array` of `Part` objects.
    - Ensure `chat.sendMessage` is called with the appropriate format.
    - Verify history management still works with non-text parts (though typically we only keep text summaries in history to save tokens).

### Phase 2: Brain Orchestration Update (`agent/agent.js`)
- **Objective**: Create a path for audio data to trigger tool discovery and execution.
- **Actions**:
    - Add `handleUserVoice(audioBase64, mimeType)` to `AgentBrain`.
    - Construct the multimodal prompt: `[ { inlineData: { data: audioBase64, mimeType } }, { text: "The user sent this voice memo. Please process it." } ]`.
    - Reuse the existing tool execution loop to handle any actions triggered by the voice command.

### Phase 3: Telegram Bot Implementation (`agent/telegram.js`)
- **Objective**: Connect the Telegram voice event to the AI brain.
- **Actions**:
    - Update `handleVoice(ctx)` to:
        1. Extract `file_id` from `ctx.message.voice`.
        2. Retrieve the file link via `ctx.telegram.getFileLink`.
        3. Download the audio as a buffer using `fetch`.
        4. Convert the buffer to a base64 string.
        5. Send to `brain.handleUserVoice`.
    - Implement user feedback: Send a "typing" or "recording audio" status to indicate processing.

### Phase 4: Error Handling and UX
- **Objective**: Ensure robustness and transparency.
- **Actions**:
    - Handle cases where the audio file is too large or corrupted.
    - Provide clear error messages if the model fails to understand the audio.
    - (Optional) Add a "Fast" vs "Smart" check to ensure the selected model supports audio (both currently do).

## 4. Verification Strategy

### Automated Testing
- **Unit Test (`agent/test/gemini.test.js`)**: Add a test case that passes an `inlineData` part to a mocked Gemini API and verifies the structure.
- **Brain Test (`agent/test/system.test.js`)**: Verify that `handleUserVoice` correctly enters the tool loop.
- **Mocking**: Use `nock` or similar to mock Telegram file downloads during integration tests.

### Manual Verification
- Send a voice memo saying: "Add a task to buy groceries."
- Verify that:
    1. The bot responds confirming the receipt.
    2. The AI identifies the `add_task` or `add_todo` tool.
    3. The task appears in the Flutter app (or logs confirm tool execution).
    4. The bot responds with a text confirmation of the action.

## 5. Anticipated Challenges & Considerations

- **MIME Type**: Ensure we correctly identify the MIME type. Telegram voice messages are almost always `audio/ogg`.
- **Latency**: Downloading from Telegram + Uploading to Gemini adds double network hop. 
- **Privacy**: Audio data remains in memory during processing and is then sent to Google's Gemini API. This should be noted in project documentation if privacy is a top priority.
- **History Management**: We should decide if the audio itself stays in the chat history. To save tokens and avoid repetition, it's better to only keep the *text summary* of the audio in the history for subsequent turns.

## 6. Relevant Information & Findings (To be updated)
- [2026-03-06] Initial plan created. Identified Gemini 1.5+ support for native audio processing.
- [2026-03-06] Confirmed `@google/generative-ai` version 0.24.1 is in use.
- [2026-03-06] Telegram voice memos use `.ogg` format.
- [2026-03-06] **Learning:** `chat.getHistory()` includes the raw `inlineData` (audio bytes). To avoid resending these bytes in every subsequent turn (which wastes tokens and adds latency), the history should be cleaned of `inlineData` parts after the initial processing, or replaced with a lightweight placeholder like `[User sent voice memo]`.
- [2026-03-06] **Implementation Complete:** 
    - `GeminiService` now supports multimodal prompts and cleans history.
    - `AgentBrain` has `handleUserVoice` to orchestrate audio processing.
    - `BotService` handles voice memos by downloading them from Telegram and passing them to the brain.
    - Verified with 52/52 passing tests, including new multimodal integration tests.

- [2026-03-06] **Refactoring Complete:**
    - Unified `AgentBrain.process()` handles both strings and `{ audioBase64, mimeType }` objects.
    - `GeminiService` code reduced by ~20% via `_getChatSession()` and `_handleResponse()` extraction.
    - `BotService` simplified by using the same entry point for all message types.
    - All tests passing (52/52).
