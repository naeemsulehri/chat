extends Node
## English / Urdu UI strings, registered with Godot's TranslationServer so
## Controls translate keys automatically and re-translate on language switch.

signal language_changed(code: String)

const LANGS := ["en", "ur"]

# KEY: [English, Urdu]
const STRINGS := {
	"APP_TITLE": ["Shuffle Up", "شفل اپ"],
	"APP_TAGLINE": ["Classic card games", "کلاسک تاش کے کھیل"],
	"MENU_CHOOSE": ["Choose a game", "کھیل منتخب کریں"],
	"COMING_SOON": ["Coming soon", "جلد آ رہا ہے"],
	"LANG_SWITCH": ["اردو", "English"],
	"SOUND_ON": ["Sound: On", "آواز: آن"],
	"SOUND_OFF": ["Sound: Off", "آواز: بند"],

	"GAME_RANG": ["Rang · Court Piece", "رنگ · کورٹ پیس"],
	"GAME_RANG_DESC": ["4 players · 2 teams · trump tricks", "4 کھلاڑی · 2 ٹیمیں · رنگ کی بازیاں"],
	"GAME_SEEP": ["Seep", "سیپ"],
	"GAME_SEEP_DESC": ["Capture cards and build houses", "پتے اٹھائیں اور گھر بنائیں"],
	"GAME_POKER": ["Poker", "پوکر"],
	"GAME_POKER_DESC": ["Texas Hold'em against the house", "ٹیکساس ہولڈم"],
	"GAME_BLUFF": ["Bluff", "بلف"],
	"GAME_BLUFF_DESC": ["Lie, call out, empty your hand", "جھوٹ بولیں، پکڑیں، پتے ختم کریں"],
	"GAME_DAKETI": ["Daketi", "ڈکیتی"],
	"GAME_DAKETI_DESC": ["Rob your rivals' piles", "مخالف کے ڈھیر لوٹیں"],

	"SETUP_TITLE": ["Game Rules", "کھیل کے اصول"],
	"BACK": ["Back", "واپس"],
	"START": ["Start Game", "کھیل شروع کریں"],
	"OPT_DIFFICULTY": ["Computer level", "کمپیوٹر کی سطح"],
	"DIFF_EASY": ["Easy", "آسان"],
	"DIFF_MEDIUM": ["Medium", "درمیانہ"],
	"DIFF_HARD": ["Hard", "مشکل"],
	"OPT_TRICK_MODE": ["Trick counting", "بازیوں کی گنتی"],
	"MODE_SIMPLE": ["Simple", "سادہ"],
	"MODE_SIMPLE_DESC": ["Every trick counts. First team to 7 tricks wins the round.", "ہر بازی گنی جاتی ہے۔ پہلے 7 بازیاں جیتنے والی ٹیم راؤنڈ جیتتی ہے۔"],
	"MODE_SAR": ["Sar", "سر"],
	"MODE_SAR_DESC": ["Tricks pile up in the middle. Win 2 in a row to collect the pile. Last trick takes what's left.", "بازیاں بیچ میں جمع ہوتی ہیں۔ لگاتار 2 جیت کر ڈھیر اٹھائیں۔ آخری بازی باقی سب لے جاتی ہے۔"],
	"MODE_SAR_NO_ACE": ["Sar · no Ace", "سر · اکے کے بغیر"],
	"MODE_SAR_NO_ACE_DESC": ["Like Sar, but a trick won with an Ace can't collect the pile.", "سر کی طرح، مگر اکے سے جیتی بازی ڈھیر نہیں اٹھا سکتی۔"],
	"OPT_SAR_PAIR": ["Two in a row by", "لگاتار دو بازیاں"],
	"PAIR_PLAYER": ["Same player", "ایک ہی کھلاڑی"],
	"PAIR_TEAM": ["Same team", "ایک ہی ٹیم"],
	"OPT_TARGET": ["Points to win the match", "میچ جیتنے کے پوائنٹس"],
	"OPT_COURT_POINTS": ["Court bonus points", "کورٹ کے بونس پوائنٹس"],
	"RULES_SUMMARY_RANG": ["The player after the dealer sees 5 cards and picks trump. Follow suit if you can. Win 7 tricks to take the round. Win the first 7 tricks in a row for a Court; all 13 is a Bavan Court.", "ڈیلر کے بعد والا کھلاڑی 5 پتے دیکھ کر رنگ چنتا ہے۔ ہو سکے تو وہی قسم کھیلیں۔ 7 بازیاں جیت کر راؤنڈ جیتیں۔ پہلی 7 بازیاں لگاتار جیتنا کورٹ ہے، اور تمام 13 باون کورٹ۔"],

	"MENU": ["Menu", "مینو"],
	"TEAM_US": ["Us", "ہم"],
	"TEAM_THEM": ["Them", "وہ"],
	"TRUMP": ["Trump", "رنگ"],
	"TRICKS": ["Tricks", "بازیاں"],
	"TARGET_FMT": ["First to %d", "پہلے %d تک"],
	"PILE_FMT": ["Pile %d", "ڈھیر %d"],
	"NAME_0": ["You", "آپ"],
	"NAME_1": ["Bilal", "بلال"],
	"NAME_2": ["Sara", "سارہ"],
	"NAME_3": ["Hamza", "حمزہ"],
	"PARTNER": ["Partner", "ساتھی"],
	"DEALER": ["Dealer", "ڈیلر"],
	"SUIT_0": ["Spades", "حکم"],
	"SUIT_1": ["Hearts", "پان"],
	"SUIT_2": ["Diamonds", "اینٹ"],
	"SUIT_3": ["Clubs", "چڑیا"],

	"MSG_CHOOSING": ["%s is choosing trump…", "%s رنگ کا انتخاب کر رہے ہیں…"],
	"MSG_CHOOSE_TRUMP": ["Pick trump from your 5 cards", "اپنے 5 پتوں میں سے رنگ چنیں"],
	"MSG_TRUMP_IS": ["Trump is %s", "رنگ ہے %s"],
	"MSG_YOUR_TURN": ["Your turn", "آپ کی باری"],
	"MSG_TAP_AGAIN": ["Tap again to play", "کھیلنے کے لیے دوبارہ ٹیپ کریں"],
	"MSG_MUST_FOLLOW": ["Follow the led suit", "اسی قسم کا پتا کھیلیں"],
	"MSG_TURN_OF": ["%s's turn", "%s کی باری"],
	"MSG_WINS_TRICK": ["%s wins the trick", "%s نے بازی جیتی"],
	"MSG_COLLECTS": ["%s collects %d tricks!", "%s نے %d بازیاں اٹھا لیں!"],
	"MSG_COURT": ["COURT!", "کورٹ!"],
	"MSG_BAVAN": ["BAVAN COURT!", "باون کورٹ!"],

	"ROUND_WON": ["You won the round!", "آپ نے راؤنڈ جیت لیا!"],
	"ROUND_LOST": ["They won the round", "مخالفین نے راؤنڈ جیت لیا"],
	"ROUND_DETAIL": ["Tricks %d – %d  ·  +%d points", "بازیاں %d – %d  ·  +%d پوائنٹس"],
	"NEXT_ROUND": ["Next Round", "اگلا راؤنڈ"],
	"GAME_WON": ["Victory!", "فتح!"],
	"GAME_LOST": ["Defeat", "شکست"],
	"FINAL_SCORE": ["Final score %d – %d", "آخری اسکور %d – %d"],
	"PLAY_AGAIN": ["Play Again", "دوبارہ کھیلیں"],
	"MAIN_MENU": ["Main Menu", "مین مینو"],
	"PAUSED": ["Paused", "وقفہ"],
	"RESUME": ["Resume", "جاری رکھیں"],
	"RESTART": ["Restart", "دوبارہ شروع"],
}

var current: String = "en"


func _ready() -> void:
	for i in LANGS.size():
		var t := Translation.new()
		t.locale = LANGS[i]
		for key in STRINGS:
			t.add_message(key, STRINGS[key][i])
		TranslationServer.add_translation(t)
	set_language(Settings.language, false)


func set_language(code: String, save := true) -> void:
	if not code in LANGS:
		code = "en"
	current = code
	TranslationServer.set_locale(code)
	if save:
		Settings.language = code
		Settings.save_settings()
	language_changed.emit(code)


func toggle() -> void:
	set_language("ur" if current == "en" else "en")


func is_urdu() -> bool:
	return current == "ur"


## Translate a key outside of a Node context.
func t(key: String) -> String:
	return TranslationServer.translate(key)
