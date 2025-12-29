import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { TextToSpeechClient } from "@google-cloud/text-to-speech";
import * as crypto from "crypto";

admin.initializeApp();
const tts = new TextToSpeechClient();

export const generateTts = functions.https.onCall(async (data, context) => {
  try {
    // ALLOW UNAUTHENTICATED ACCESS FOR LOCAL DEV (macOS Keychain workaround)
    const uid = context.auth ? context.auth.uid : "guest_user";
    const text = String(data.text ?? "");
    const languageCode = String(data.languageCode ?? "");
    const voiceName = data.voiceName ? String(data.voiceName) : undefined;
    const speakingRate = Number(data.speakingRate ?? 1.0);
    const pitch = Number(data.pitch ?? 0.0);
    const audioEncoding = String(data.audioEncoding ?? "MP3");

    if (!text || text.length > 5000) {
      throw new functions.https.HttpsError("invalid-argument", "Invalid text length.");
    }
    if (!["de-DE", "en-US"].includes(languageCode)) {
      throw new functions.https.HttpsError("invalid-argument", "Unsupported languageCode.");
    }

    const hash = crypto
      .createHash("sha256")
      .update([text, languageCode, voiceName ?? "", speakingRate, pitch, audioEncoding].join("|"))
      .digest("hex");

    // Explicitly check if bucket exists or capture error
    let bucket;
    try {
        bucket = admin.storage().bucket();
    } catch (bucketError) {
        console.error("Bucket init error:", bucketError);
        throw new functions.https.HttpsError("internal", `Storage bucket initialization failed: ${bucketError}`);
    }

    const storagePath = `tts/${uid}/${hash}.mp3`;
    const file = bucket.file(storagePath);

    const [exists] = await file.exists();
    if (exists) {
      return { storagePath, contentType: "audio/mpeg", chars: text.length, cached: true };
    }

    // Call Cloud TTS
    let resp;
    try {
        [resp] = await tts.synthesizeSpeech({
            input: { text },
            voice: voiceName ? { languageCode, name: voiceName } : { languageCode },
            audioConfig: { audioEncoding: "MP3", speakingRate, pitch },
        });
    } catch (ttsError: any) {
        console.error("TTS API Error:", ttsError);
        throw new functions.https.HttpsError("internal", `Cloud TTS API failed: ${ttsError.message || ttsError}`);
    }

    const audioContent = resp.audioContent;
    if (!audioContent) {
      throw new functions.https.HttpsError("internal", "No audioContent returned from TTS API.");
    }

    const audioBytes = Buffer.isBuffer(audioContent)
      ? audioContent
      : Buffer.from(audioContent as unknown as string, "base64");

    await file.save(audioBytes, {
      contentType: "audio/mpeg",
      resumable: false,
      metadata: {
        metadata: {
          uid,
          languageCode,
          hash,
        },
      },
    });

    return { storagePath, contentType: "audio/mpeg", chars: text.length, cached: false };

  } catch (err: any) {
    console.error("Global Handler Error:", err);
    // Re-throw HttpsErrors as is, wrap others
    if (err instanceof functions.https.HttpsError) {
      throw err;
    }
    throw new functions.https.HttpsError("internal", `Unexpected error: ${err.message || err}`);
  }
});