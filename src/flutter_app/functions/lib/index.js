"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateTts = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const text_to_speech_1 = require("@google-cloud/text-to-speech");
const crypto = require("crypto");
admin.initializeApp();
const tts = new text_to_speech_1.TextToSpeechClient();
exports.generateTts = functions.https.onCall(async (data, context) => {
    var _a, _b, _c, _d, _e;
    try {
        // ALLOW UNAUTHENTICATED ACCESS FOR LOCAL DEV (macOS Keychain workaround)
        const uid = context.auth ? context.auth.uid : "guest_user";
        const text = String((_a = data.text) !== null && _a !== void 0 ? _a : "");
        const languageCode = String((_b = data.languageCode) !== null && _b !== void 0 ? _b : "");
        const voiceName = data.voiceName ? String(data.voiceName) : undefined;
        const speakingRate = Number((_c = data.speakingRate) !== null && _c !== void 0 ? _c : 1.0);
        const pitch = Number((_d = data.pitch) !== null && _d !== void 0 ? _d : 0.0);
        const audioEncoding = String((_e = data.audioEncoding) !== null && _e !== void 0 ? _e : "MP3");
        if (!text || text.length > 5000) {
            throw new functions.https.HttpsError("invalid-argument", "Invalid text length.");
        }
        if (!["de-DE", "en-US"].includes(languageCode)) {
            throw new functions.https.HttpsError("invalid-argument", "Unsupported languageCode.");
        }
        const hash = crypto
            .createHash("sha256")
            .update([text, languageCode, voiceName !== null && voiceName !== void 0 ? voiceName : "", speakingRate, pitch, audioEncoding].join("|"))
            .digest("hex");
        // Explicitly check if bucket exists or capture error
        let bucket;
        try {
            bucket = admin.storage().bucket();
        }
        catch (bucketError) {
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
        }
        catch (ttsError) {
            console.error("TTS API Error:", ttsError);
            throw new functions.https.HttpsError("internal", `Cloud TTS API failed: ${ttsError.message || ttsError}`);
        }
        const audioContent = resp.audioContent;
        if (!audioContent) {
            throw new functions.https.HttpsError("internal", "No audioContent returned from TTS API.");
        }
        const audioBytes = Buffer.isBuffer(audioContent)
            ? audioContent
            : Buffer.from(audioContent, "base64");
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
    }
    catch (err) {
        console.error("Global Handler Error:", err);
        // Re-throw HttpsErrors as is, wrap others
        if (err instanceof functions.https.HttpsError) {
            throw err;
        }
        throw new functions.https.HttpsError("internal", `Unexpected error: ${err.message || err}`);
    }
});
//# sourceMappingURL=index.js.map