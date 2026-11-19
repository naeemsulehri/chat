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
	# --- Seep ---
	"RULES_SUMMARY_SEEP": ["The bidder sees 4 cards and bids a house value from 9 to King. Capture cards matching your card's value, alone or in sums. Build houses you can capture later. Spades score their value, other Aces 1, the 10 of Diamonds 6: 100 points per deal. Clearing the table is a Seep.", "بولی لگانے والا 4 پتے دیکھ کر 9 سے بادشاہ تک گھر کی قیمت بولتا ہے۔ اپنے پتے کی قیمت کے برابر پتے اکیلے یا جوڑ کر اٹھائیں۔ گھر بنائیں جو بعد میں اٹھا سکیں۔ حکم کے پتے اپنی قیمت، باقی اکے 1، اینٹ کا دہلا 6 — ہر دور میں 100 پوائنٹس۔ میز صاف کرنا سیپ ہے۔"],
	"OPT_PLAYERS": ["Players", "کھلاڑی"],
	"PLAYERS_4": ["4 · teams", "4 · ٹیمیں"],
	"PLAYERS_4_DESC": ["You and Sara vs Bilal and Hamza.", "آپ اور سارہ بمقابلہ بلال اور حمزہ۔"],
	"PLAYERS_2": ["2 · head to head", "2 · آمنے سامنے"],
	"PLAYERS_2_DESC": ["You vs Bilal, 24 cards each, dealt in two halves.", "آپ بمقابلہ بلال، ہر ایک کو دو حصوں میں 24 پتے۔"],
	"OPT_MATCH": ["Match length", "میچ کی طوالت"],
	"MATCH_LEAD100": ["Baazi · lead 100", "بازی · 100 کی برتری"],
	"MATCH_LEAD100_DESC": ["Classic: keep dealing until one side is 100 points ahead.", "کلاسک: اس وقت تک کھیلیں جب تک ایک ٹیم 100 پوائنٹس آگے نہ ہو جائے۔"],
	"MATCH_FIRST200": ["First to 200", "پہلے 200 تک"],
	"MATCH_FIRST200_DESC": ["First side to reach 200 points wins.", "جو پہلے 200 پوائنٹس تک پہنچے وہ جیتے۔"],
	"MATCH_SINGLE": ["One deal", "ایک دور"],
	"MATCH_SINGLE_DESC": ["A single quick deal; most points wins.", "صرف ایک تیز دور؛ زیادہ پوائنٹس والا جیتے۔"],
	"TARGET_LEAD100": ["Lead by 100", "100 کی برتری"],
	"TARGET_FIRST200": ["First to 200", "پہلے 200 تک"],
	"TARGET_SINGLE": ["One deal", "ایک دور"],
	"OPT_SEEP_POINTS": ["Seep bonus", "سیپ بونس"],
	"OPT_HOUSES": ["House values", "گھر کی قیمت"],
	"HOUSES_CLASSIC": ["9 to King", "9 سے بادشاہ"],
	"HOUSES_CLASSIC_DESC": ["Classic: houses are worth 9 to 13.", "کلاسک: گھر کی قیمت 9 سے 13 تک۔"],
	"HOUSES_ANY": ["Any value", "کوئی بھی قیمت"],
	"HOUSES_ANY_DESC": ["Casual: build houses of any value 2 to 13.", "آسان: 2 سے 13 تک کسی بھی قیمت کا گھر۔"],
	"OPT_HOUSE_LOCK": ["House owner can't throw", "گھر والا پتا نہیں پھینک سکتا"],
	"YES": ["Yes", "ہاں"],
	"NO": ["No", "نہیں"],
	"HOUSE_LOCK_DESC": ["While you own a house on the table you must capture, build or cement instead of throwing.", "جب تک میز پر آپ کا گھر ہو، پھینکنے کے بجائے اٹھائیں، بنائیں یا پکا کریں۔"],
	"BID": ["Bid", "بولی"],
	"MSG_CHOOSE_BID": ["Bid a house value", "گھر کی قیمت بولیں"],
	"MSG_BIDDING": ["%s is bidding…", "%s بولی لگا رہے ہیں…"],
	"MSG_BID_IS": ["Bid: %s", "بولی: %s"],
	"MSG_BID_PLAY": ["Play your bid: build %s, capture or throw it", "اپنی بولی کھیلیں: %s کا گھر بنائیں، اٹھائیں یا پھینکیں"],
	"MSG_PICK_CARD": ["Tap a card, then choose a move", "پتا ٹیپ کریں، پھر چال چنیں"],
	"ACT_THROW": ["Throw", "پھینکیں"],
	"ACT_CAPTURE": ["Take %d cards", "%d پتے اٹھائیں"],
	"ACT_BUILD": ["Build house %s", "%s کا گھر بنائیں"],
	"ACT_CEMENT": ["Cement house %s", "%s کا گھر پکا کریں"],
	"ACT_RAISE": ["Raise house to %s", "گھر %s تک بڑھائیں"],
	"POINTS": ["Points", "پوائنٹس"],
	"SEEPS_FMT": ["Seeps %d·%d", "سیپ %d·%d"],
	"MSG_SEEP": ["SEEP!", "سیپ!"],
	"MSG_TAKES": ["%s takes %d cards", "%s نے %d پتے اٹھائے"],
	"MSG_BUILDS": ["%s builds a house of %s", "%s نے %s کا گھر بنایا"],
	"MSG_CEMENTS": ["%s cements the %s house", "%s نے %s کا گھر پکا کیا"],
	"MSG_RAISES": ["%s raises a house to %s", "%s نے گھر %s تک بڑھایا"],
	"MSG_LEFTOVER": ["Last cards go to %s", "باقی پتے %s کو ملے"],
	"DEAL_WON": ["You won the deal!", "آپ نے دور جیت لیا!"],
	"DEAL_LOST": ["They won the deal", "مخالفین نے دور جیت لیا"],
	"DEAL_CARD_POINTS": ["Card points %d – %d", "پتوں کے پوائنٹس %d – %d"],
	"DEAL_SEEPS": ["Seeps %d – %d  (+%d each)", "سیپ %d – %d  (ہر ایک +%d)"],
	"DEAL_TOTAL": ["This deal %d – %d", "اس دور میں %d – %d"],
	"PAKKA": ["Pakka", "پکا"],
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
