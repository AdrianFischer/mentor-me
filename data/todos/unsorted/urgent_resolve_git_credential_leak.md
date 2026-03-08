---

id: f8d27526-1a06-453c-9ce7-9829b3d711b9

version: 1

---


# Urgent: Resolve Git Credential Leak


DEV

- [ ] Remove .env from Git tracking (git rm --cached ../.env) <!-- id: 35080dda-defe-4939-9c7b-b392232721db -->

- [ ] Add *.env to .gitignore <!-- id: e8707010-7ddc-428e-abe0-7ac6fffd1795 -->

- [ ] Rotate and Revoke Google API Key (GEMINI_API_KEY) <!-- id: 3428674c-41bb-4537-9c49-e8baa4e1a0a6 -->

- [ ] Audit git history and rewrite if key was pushed remotely <!-- id: 7a81c43a-5b9d-45ff-bcdd-55a8dd56852c -->

