# Strategic Plan: Bidirectional Image Handling (Visual Intelligence)

This plan document is a communication tool across multiple different agents. Therefore, every relevant file, every relevant information, and every learning MUST be documented in this file. This file must represent the current state of the effort at all times.

## 1. Understanding the Goal

The goal is to enable the Assisted Intelligence system to receive, process, and send images. This allows the user to send photos of receipts, whiteboard sketches, or products to the agent, and the agent to retrieve and show images related to tasks.

**Key Requirements:**
- **Receiving Images:** Telegram bot accepts photos and passes them to the AI brain.
- **Visual Analysis:** Gemini uses native multimodal capabilities to "see" and describe or extract info from images.
- **Storing Images:** Images are saved locally in the project's data directory and linked to tasks/projects.
- **Sending Images:** The agent can send images back to the user via Telegram (e.g., "Show me the photo from yesterday's meeting").

## 2. Investigation & Analysis

### Current State
- **Flutter App:** Already has basic infrastructure for `localImagePaths` in `Task` and `Subtask` models.
- **MCP:** A tool `manage_todo_images` exists to link/unlink local file paths.
- **AI Brain:** `process()` method is now polymorphic (handles text and voice), but not yet image-ready.
- **Gemini:** We are using `gemini-2.0-flash` and `gemini-3.1-pro-preview`, both of which support `image/jpeg`, `image/png`, etc. via `inlineData`.

### Key Files
- `agent/telegram.js`: Needs to handle `ctx.message.photo`.
- `agent/agent.js`: Needs to handle `{ imageBase64, mimeType }` in the polymorphic `process` input.
- `agent/gemini.js`: Needs to ensure `inlineData` for images is cleaned from history (just like audio).
- `app/lib/ai_tools/implementations/manage_todo_images_tool.dart`: Existing tool for linking images.

## 3. Proposed Strategic Approach

### Phase 1: AI Brain & Gemini Enhancement (`agent/`)
- **Objective**: Make the brain "Visual-Ready."
- **Actions**:
    - Update `GeminiService._cleanHistory` to also strip `image/*` inlineData.
    - Update `AgentBrain.process` to handle an `image` input type:
      ```javascript
      if (input.imageBase64) {
        prompt = [
          { inlineData: { data: input.imageBase64, mimeType: input.mimeType } },
          { text: input.text || "Please analyze this image." }
        ];
      }
      ```

### Phase 2: Telegram Photo Reception (`agent/telegram.js`)
- **Objective**: Listen for images from the user.
- **Actions**:
    - Add `this.telegraf.on('photo', ...)` handler.
    - Implementation:
        1. Get the highest resolution `file_id`.
        2. Download via `getFileLink` (same pattern as voice).
        3. Convert to base64.
        4. Pass to `brain.process({ imageBase64, mimeType, text: ctx.message.caption })`.

### Phase 3: Image Storage MCP Tool (`app/`)
- **Objective**: Save images received via Telegram into the app's local storage.
- **Actions**:
    - Create a new MCP tool `upload_image(base64, filename)` that saves the file to a standard directory (e.g., `data/artifacts/images/`) and returns the absolute local path.
    - The AI can then use the existing `manage_todo_images` tool to link this path to a specific task.

### Phase 4: Bidirectional Image Sending (`agent/telegram.js`)
- **Objective**: Allow the agent to send images back to the user.
- **Actions**:
    - Update `BotService.safeReply`: If the text contains a special marker or if the brain returns a specific `imagePath`, use `ctx.replyWithPhoto`.
    - Create an MCP tool `get_image_data(path)` that reads a local image and returns it as base64 so the agent can "see" it again if needed.

## 4. Verification Strategy

### Automated Testing
- **Unit Test (`agent/test/multimodal.test.js`)**: Add a test for `brain.process` with an image input.
- **Gemini Test**: Verify history cleaning for images.

### Manual Verification
- Send a photo of a shopping list to the bot with the caption "Add these to my grocery task."
- Verify the AI extracts the items and calls the appropriate tools.
- Ask "Show me the images for the Logimat project" and verify the bot sends the photo back.

## 5. Anticipated Challenges & Considerations
- **Image Compression**: Telegram sends multiple sizes; always use the largest for AI analysis.
- **Storage Management**: Images take space. We should ensure unique filenames (UUIDs) to prevent overwriting.
- **Context Window**: Multiple images in one session can quickly bloat history if not cleaned properly.

## 6. Relevant Information & Findings (To be updated)
- [2026-03-06] Initial plan created.
- [2026-03-08] **Implementation Complete:**
    - `GeminiService` now strips both image and audio inlineData from history.
    - `AgentBrain.process()` handles `{ imageBase64, mimeType, text }` input.
    - `BotService` handles `photo` messages and uses `withTyping` for continuous feedback.
    - New MCP tools `upload_image` and `get_image_data` implemented in Flutter app.
    - `BotService.safeReply` supports sending photos back via Telegram.
    - Switched from Markdown to HTML for superior response reliability.
    - Verified with 53/53 passing tests.

- [2026-03-08] **Codebase Simplification & Optimization Complete:**
    - Unified Telegram media pipeline via `_downloadAndProcessMedia`.
    - Optimized Gemini history cleaning to skip turns without multimodal data.
    - Implemented standardized media protocol between tools and Brain.
    - All tests passing (53/53).
