import { Telegram } from 'telegraf';
console.log(Object.keys(Telegram.prototype).includes('editMessageText') ? "Exists" : "No");
console.log(Telegram.prototype.editMessageText.toString());