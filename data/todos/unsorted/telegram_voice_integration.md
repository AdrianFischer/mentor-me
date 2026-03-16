---
id: 9dbd3a36-d46f-4018-b845-89f4fefc9bf3
is_completed: true
version: 1
---

# Telegram Voice Integration

- [x] Catch the Voice Message (Extract file_id) <!-- id: 22add269-1f7c-43f1-ae47-5f758388e4a9 -->

- [x] Download the Audio File (.ogg format) <!-- id: f3cbc8e4-c6cb-4504-b404-658e448e3fe7 -->

- [x] Convert Speech to Text (via Whisper API) <!-- id: 6a33d346-9610-42ab-8542-2eb2316eba7f -->

- [x] Feed the Text to the AI <!-- id: 2d3b545c-e113-4219-87be-0d9601d0ccd6 -->

- [x] Build middleware for Execute and Respond <!-- id: d663a29c-e434-44eb-9579-1f39efafd4f5 -->

- [x] Pass context of last 20 messages to Telegram bot <!-- id: 41e2e144-763f-457e-91a9-c57f0ad5e86f -->
  Ensure the bot always gets the context of the last 20 messages whenever the user texts it. This makes it easier for the bot to maintain conversational context.

