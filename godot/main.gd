extends Control
## Bundesbank Idle – Spiellogik und Oberfläche

const REPO := "robertpahl1987-creator/bundesbank-idle"
const APK_URL := "https://github.com/robertpahl1987-creator/bundesbank-idle/releases/latest/download/BundesbankIdle.apk"
const SAVE_PATH := "user://save.json"
const R := 1.15

const LINES := [
	{id="c1", n="1-Cent-Linie", d="Kupferstahl-Rohlinge", b=15.0, r=0.5, col="#b87333"},
	{id="c10", n="10-Cent-Linie", d="Nordisches Gold", b=120.0, r=3.0, col="#d4a826"},
	{id="c50", n="50-Cent-Linie", d="Größte Cent-Münze", b=1300.0, r=16.0, col="#e8c34a"},
	{id="e1", n="1-Euro-Linie", d="Bimetall, Adler-Motiv", b=14000.0, r=90.0, col="#c9cfd2"},
	{id="e2", n="2-Euro-Linie", d="Mit Randschrift", b=130000.0, r=500.0, col="#dcbf5c"},
	{id="s5", n="5-Euro-Linie", d="Grau, Klassik", b=1.4e6, r=2800.0, note=true, req=2, col="#9aa3a8"},
	{id="s20", n="20-Euro-Linie", d="Blau, Gotik", b=2e7, r=16000.0, note=true, req=4, col="#5b8fd0"},
	{id="s100", n="100-Euro-Linie", d="Grün, Barock", b=3.3e8, r=90000.0, note=true, req=6, col="#6fae8f"},
	{id="s200", n="200-Euro-Linie", d="Gelb, Eisen & Glas", b=5.1e9, r=520000.0, note=true, req=8, col="#e0c25a"},
]
const MS := [10, 25, 50, 100, 150, 200, 300, 400, 500]
const VAN := [
	{id="v1", n="Lieferwagen", d="Kleingeld zur Sparkasse", b=20.0, r=0.8},
	{id="v2", n="Geldtransporter", d="Gepanzert, Touren zu Filialen", b=300.0, r=5.0},
	{id="v3", n="Panzerwagen-Kolonne", d="Versorgt Landeszentralbanken", b=4000.0, r=40.0},
	{id="v4", n="Werttransport-LKW", d="Großmengen für Geschäftsbanken", b=60000.0, r=300.0},
	{id="v5", n="Güterzug", d="Bundesweite Belieferung", b=1e6, r=2200.0},
	{id="v6", n="Frachtflugzeug", d="Euroraum-Lieferungen", b=2e7, r=18000.0},
	{id="v7", n="Hubschrauber-Staffel", d="Eilaufträge in Echtzeit", b=4e8, r=150000.0},
	{id="v8", n="Logistikzentrum", d="Vollautomatische Verteilung", b=8e9, r=1.2e6},
]
const TECH := [
	{id="t1", n="Hydraulische Prägepresse", d="Münzhalle ×2", c=500.0, k="coin", m=2.0},
	{id="t2", n="Routenplanung", d="Auslieferung ×2", c=2500.0, k="del", m=2.0},
	{id="t3", n="Rohling-Stanzautomat", d="Münzhalle ×2", c=5e4, k="coin", m=2.0},
	{id="t4", n="Bimetall-Fügelinie", d="Münzhalle ×2", c=5e5, k="coin", m=2.0},
	{id="t5", n="Bogen-Offsetdruck", d="Druckhalle ×2", c=5e6, k="note", m=2.0},
	{id="t6", n="GPS-Flottensteuerung", d="Auslieferung ×2", c=3e7, k="del", m=2.0},
	{id="t7", n="Stichtiefdruck", d="Druckhalle ×2", c=1e8, k="note", m=2.0},
	{id="t8", n="Robotik-Sortierung", d="Ganzes Werk ×1,5 · Roboterarme", c=5e8, k="all", m=1.5},
	{id="t9", n="Express-Logistik", d="Auslieferung ×3", c=3e9, k="del", m=3.0},
	{id="t10", n="Hochgeschwindigkeits-Zählung", d="Ganzes Werk ×2", c=1e10, k="all", m=2.0},
	{id="t11", n="KI-Qualitätskontrolle", d="Ganzes Werk ×2 · Prüftore", c=1e11, k="all", m=2.0},
	{id="t12", n="Neues Druckzentrum", d="Druckhalle ×3 · neues Gebäude", c=1e12, k="note", m=3.0},
]
const FEAT := [
	{id="f1", n="Randprägung", d="Münzrand mit Rillen", c=150.0, red=3},
	{id="f2", n="Wasserzeichen", d="Im Gegenlicht sichtbar", c=3000.0, red=4},
	{id="f3", n="Sicherheitsfaden", d="Dunkler Streifen im Papier", c=25000.0, red=4},
	{id="f4", n="Mikroschrift", d="Nur mit Lupe lesbar", c=2e5, red=3},
	{id="f5", n="Fühlbares Relief", d="Tastbarer Druck am Rand", c=2e6, red=3},
	{id="f6", n="Hologramm-Streifen", d="Bild wechselt beim Kippen", c=2e7, red=4},
	{id="f7", n="Smaragd-Zahl", d="Farbwechsel grün zu blau", c=2e8, red=3},
	{id="f8", n="Porträt-Fenster", d="Durchsichtiges Fenster", c=2e9, red=3},
	{id="f9", n="UV-Fluoreszenz", d="Leuchtet unter UV-Licht", c=2e10, red=2},
]
const GUARD := [
	{id="g1", n="Wachposten", d="Schutz +5 · patrouilliert am Zaun", b=100.0, v=5},
	{id="g2", n="Überwachungskamera", d="Schutz +12 · Masten am Gelände", b=800.0, v=12},
	{id="g3", n="Stahltor", d="Schutz +40 · Zaun und Tor ums Werk", b=8000.0, v=40},
	{id="g4", n="Alarmanlage", d="Schutz +110 · Alarmlicht auf dem Tresor", b=6e4, v=110},
	{id="g5", n="Hochsicherheitstresor", d="Schutz +350 · senkt Beuteverlust", b=5e5, v=350},
	{id="g6", n="Polizeiwache vor Ort", d="Schutz +1.200 · Streifenwagen am Tor", b=5e6, v=1200},
	{id="g7", n="SEK-Bereitschaft", d="Schutz +4.500", b=5e7, v=4500},
	{id="g8", n="Bundeswehr-Objektschutz", d="Schutz +18.000", b=4e8, v=18000},
	{id="g9", n="Drohnenabwehr", d="Schutz +70.000", b=4e9, v=70000},
	{id="g10", n="Satellitenüberwachung", d="Schutz +300.000", b=5e10, v=300000},
]
const GANGS := [{n="Kleinganoven", m=0.6}, {n="eine Räuberbande", m=1.0}, {n="eine Profi-Crew", m=1.6}, {n="ein Hackerkollektiv", m=2.2}]

const COUNTRIES := [
	{n="Schweiz", cur="Franken", fx=0.95, flag=["#d52b1e", "#ffffff", "#d52b1e"]},
	{n="Großbritannien", cur="Pfund", fx=0.85, flag=["#012169", "#ffffff", "#c8102e"]},
	{n="Norwegen", cur="Kronen", fx=11.5, flag=["#ba0c2f", "#ffffff", "#00205b"]},
	{n="Island", cur="Kronen", fx=150.0, flag=["#02529c", "#ffffff", "#dc1e35"]},
	{n="Türkei", cur="Lira", fx=36.0, flag=["#e30a17", "#ffffff", "#e30a17"]},
	{n="Serbien", cur="Dinar", fx=117.0, flag=["#c6363c", "#0c4076", "#ffffff"]},
	{n="Ukraine", cur="Hrywnja", fx=45.0, flag=["#0057b7", "#0057b7", "#ffd700"]},
	{n="Georgien", cur="Lari", fx=2.9, flag=["#ffffff", "#ff0000", "#ffffff"]},
	{n="Marokko", cur="Dirham", fx=10.8, flag=["#c1272d", "#006233", "#c1272d"]},
	{n="Japan", cur="Yen", fx=160.0, flag=["#ffffff", "#bc002d", "#ffffff"]},
	{n="USA", cur="Dollar", fx=1.08, flag=["#3c3b6e", "#ffffff", "#b22234"]},
	{n="Kanada", cur="Dollar", fx=1.5, flag=["#ff0000", "#ffffff", "#ff0000"]},
	{n="Australien", cur="Dollar", fx=1.65, flag=["#012169", "#ffffff", "#e4002b"]},
	{n="Mexiko", cur="Pesos", fx=21.0, flag=["#006847", "#ffffff", "#ce1126"]},
	{n="Brasilien", cur="Real", fx=6.2, flag=["#009c3b", "#ffdf00", "#002776"]},
]
const ORDER_SHARE := 0.2

const C_PETROL := Color("#0e8a7c")
const C_HEAD := Color("#0a4f4a")
const C_BG := Color("#0c1f24")
const C_CARD := Color("#163840")
const C_CARD2 := Color("#1f4b54")
const C_INK := Color("#f2f7f4")
const C_MUT := Color("#a3c2bb")
const C_MAIN2 := Color("#24525a")
const C_RED := Color("#ff4d5e")
const C_LINE := Color("#2c5d66")
const C_GOLD := Color("#ffc23d")
const C_DARK := Color("#13262a")
const C_GREEN := Color("#3fd68a")

var S: Dictionary = {}
var view := "werk"
var hall := "coin"
var amt := "1"
var confirm_reset := ""
var refs := {}
var ui_t := 0.0
var save_t := 0.0
var shot_t := 0.0
var bold_font: FontVariation

# UI-Elemente
var l_cash: Label
var l_inc: Label
var b_risk: Button
var l_prod: Label
var l_del: Label
var l_stock: Label
var l_stockp: Label
var bar_stock: ProgressBar
var world_box: Control
var world: Node3D
var alarm_panel: PanelContainer
var l_alarm: Label
var l_hint: Label
var content: VBoxContainer
var scroll: ScrollContainer
var nav_btns := {}
var update_panel: PanelContainer
var l_update: Label
var http: HTTPRequest
var manual_check := false
var world_big := false

# ---------------------------------------------------------------- Zustand
func now() -> float:
	return Time.get_unix_time_from_system()

func blank() -> Dictionary:
	return {cash=25.0, stock=0.0, lv=0, total=0.0, life=0.0, l={"c1": 1}, v={"v1": 1}, t={}, f={}, g={"g1": 2},
		rep=0, next=90.0, warn=0.0, gang=0, won=0, lost=0, log=[], ts=now(), mig1=1, orders=[], odone=0}

func load_game() -> void:
	S = blank()
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		var x = JSON.parse_string(f.get_as_text())
		if typeof(x) == TYPE_DICTIONARY:
			apply_state(x)

func apply_state(x: Dictionary) -> void:
	var b := blank()
	for k in x.keys():
		b[k] = x[k]
	for k in ["l", "v", "t", "f", "g"]:
		if typeof(b[k]) != TYPE_DICTIONARY:
			b[k] = {}
	if typeof(b["log"]) != TYPE_ARRAY:
		b["log"] = []
	if typeof(b["orders"]) != TYPE_ARRAY:
		b["orders"] = []
	S = b

func save_game() -> void:
	S["ts"] = now()
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(S))

# ---------------------------------------------------------------- Wirtschaft
func cnt(o: String, id: String) -> int:
	return int(S[o].get(id, 0))

func has_flag(o: String, id: String) -> bool:
	return bool(S[o].get(id, 0))

func tm(k: String) -> float:
	var m := 1.0
	for t in TECH:
		if has_flag("t", t.id) and t.k == k:
			m *= t.m
	return m

func feat_n() -> int:
	var n := 0
	for f in FEAT:
		if has_flag("f", f.id):
			n += 1
	return n

func cf_pct() -> int:
	var red := 0
	for f in FEAT:
		if has_flag("f", f.id):
			red += f.red
	return max(1, 30 - red)

func rep_m() -> float:
	return 1.0 + 0.1 * float(S["rep"])

func ms_n(c: int) -> int:
	var n := 0
	for m in MS:
		if c >= m:
			n += 1
	return n

func next_ms(c: int) -> int:
	for m in MS:
		if c < m:
			return m
	return 0

func base_mul(l: Dictionary) -> float:
	return tm("note" if l.get("note", false) else "coin") * tm("all") * rep_m() * (1.0 - cf_pct() / 100.0)

func line_rate(l: Dictionary) -> float:
	var c := cnt("l", l.id)
	return l.r * c * pow(2.0, ms_n(c)) * base_mul(l)

func prod() -> float:
	var s := 0.0
	for l in LINES:
		s += line_rate(l)
	return s

func del_m() -> float:
	return tm("del") * rep_m()

func deliv() -> float:
	var s := 0.0
	for v in VAN:
		s += v.r * cnt("v", v.id)
	return s * del_m()

func cap() -> float:
	return 300.0 * pow(3.0, int(S["lv"]))

func cap_cost() -> float:
	return 150.0 * pow(4.0, int(S["lv"]))

func income() -> float:
	return min(prod(), deliv())

func defense() -> float:
	var s := 0.0
	for g in GUARD:
		s += g.v * cnt("g", g.id)
	return s

func threat(m := 1.0) -> float:
	return m * (8.0 + 4.0 * pow(income(), 0.8))

func risk() -> float:
	var t := threat()
	return t / (t + defense()) * 100.0

func cost_n(b: float, c: int, n: int) -> float:
	return b * pow(R, c) * (pow(R, n) - 1.0) / (R - 1.0)

func how_many(b: float, c: int) -> int:
	if amt == "max":
		var n := int(floor(log(float(S["cash"]) * (R - 1.0) / (b * pow(R, c)) + 1.0) / log(R)))
		return max(1, n)
	return int(amt)

func earn(v: float) -> void:
	S["cash"] += v
	S["total"] += v
	S["life"] += v

func add_log(t: String, c := "") -> void:
	var tm_s := Time.get_time_string_from_system().substr(0, 5)
	S["log"].push_front({t=t, c=c, time=tm_s})
	if S["log"].size() > 40:
		S["log"].resize(40)
	if view == "bank":
		render()

func active_orders() -> int:
	var n := 0
	for o in S["orders"]:
		if o.get("active", false):
			n += 1
	return n

func gen_order() -> Dictionary:
	var c: Dictionary = COUNTRIES[randi() % COUNTRIES.size()]
	for tries in range(10):
		var dup := false
		for o in S["orders"]:
			if o.get("land", "") == c.n:
				dup = true
		if not dup:
			break
		c = COUNTRIES[randi() % COUNTRIES.size()]
	var base: float = max(prod(), 0.35)
	var dur := 90.0 + randf() * 330.0
	var need := base * ORDER_SHARE * dur
	return {land=c.n, cur=c.cur, fx=c.fx, flag=c.flag, need=need, done=0.0, reward=need * (2.2 + randf() * 1.3), active=false, wait=0.0, dur=dur}

func orders_tick(dt: float) -> void:
	var o_arr: Array = S["orders"]
	while o_arr.size() < 3:
		o_arr.append(gen_order())
	var p := prod()
	for i in range(o_arr.size()):
		var o: Dictionary = o_arr[i]
		if o.get("wait", 0.0) > 0.0:
			o["wait"] -= dt
			if o["wait"] <= 0.0:
				o_arr[i] = gen_order()
				if view == "orders":
					render()
			continue
		if o.get("active", false):
			o["done"] += p * ORDER_SHARE * dt
			if o["done"] >= o["need"]:
				earn(o["reward"])
				S["odone"] = int(S.get("odone", 0)) + 1
				add_log("Auftrag %s erledigt: %s %s geliefert, Lohn %s." % [o.land, num_cur(o.need * o.fx), o.cur, fmt(o.reward)], "good")
				o_arr[i] = {wait=20.0, land="", active=false}
				world.dirty = true
				if view == "orders":
					render()

func num_cur(v: float) -> String:
	return fmt(v).replace(" €", "")

func accept_order(i: int) -> void:
	var o: Dictionary = S["orders"][i]
	if o.get("wait", 0.0) > 0.0 or o.get("active", false):
		return
	o["active"] = true
	add_log("Auftrag aus %s angenommen." % o.land, "good")
	world.dirty = true
	save_game()
	render()

func decline_order(i: int) -> void:
	var o: Dictionary = S["orders"][i]
	if o.get("active", false):
		return
	S["orders"][i] = {wait=45.0, land="", active=false}
	render()

func step(dt: float) -> void:
	orders_tick(dt)
	S["stock"] = min(cap(), float(S["stock"]) + prod() * (1.0 - ORDER_SHARE * active_orders()) * dt)
	var d: float = min(float(S["stock"]), deliv() * dt)
	S["stock"] -= d
	earn(d)

func offline_catchup() -> void:
	var away: float = clamp(now() - float(S["ts"]), 0.0, 8.0 * 3600.0)
	if away > 30.0 and income() > 0.0:
		var v := income() * away * 0.5
		earn(v)
		add_log("Während du weg warst, wurden %s ausgeliefert (50 %%, max. 8 Std.)." % fmt(v), "good")
	S["ts"] = now()

func raid_tick(dt: float) -> void:
	if S["warn"] > 0.0:
		S["warn"] -= dt
		var g: Dictionary = GANGS[int(S["gang"])]
		alarm_panel.visible = true
		l_alarm.text = "Alarm! %s greift in %d s an." % [cap_first(g.n), max(0, ceil(S["warn"]))]
		if S["warn"] <= 0.0:
			alarm_panel.visible = false
			var th := threat(g.m)
			var p := th / (th + defense())
			if randf() < p:
				var vault := cnt("g", "g5")
				var frac := (0.1 + randf() * 0.15) / (1.0 + 0.15 * vault)
				var lc: float = S["cash"] * frac
				var ls: float = S["stock"] * frac
				S["cash"] -= lc
				S["stock"] -= ls
				S["lost"] += 1
				add_log("Überfall! %s erbeutet %s aus Kasse und Lager." % [cap_first(g.n), fmt(lc + ls)], "bad")
			else:
				var rew := income() * 30.0 + 20.0
				earn(rew)
				S["won"] += 1
				add_log("Überfall abgewehrt! Belohnung: %s." % fmt(rew), "good")
			S["next"] = 70.0 + randf() * 80.0
		return
	S["next"] -= dt
	if S["next"] <= 0.0:
		var lvl: int = min(GANGS.size() - 1, int(floor(log(max(1.0, income())) / log(10.0) / 2.0)))
		S["gang"] = randi() % (lvl + 1)
		if randf() < 0.25:
			S["gang"] = min(GANGS.size() - 1, int(S["gang"]) + 1)
		S["warn"] = 12.0
		add_log("Verdächtige Bewegung vor dem Tor: %s." % GANGS[int(S["gang"])].n, "bad")

func dur_txt(sec: float) -> String:
	if sec > 86400.0:
		return "über 1 Tag"
	if sec >= 3600.0:
		return "%d Std. %d Min." % [int(sec / 3600.0), int(fmod(sec, 3600.0) / 60.0)]
	if sec >= 60.0:
		return "%d Min. %d s" % [int(sec / 60.0), int(fmod(sec, 60.0))]
	return "%d s" % int(sec)

func cap_first(t: String) -> String:
	return t.substr(0, 1).to_upper() + t.substr(1)

# ---------------------------------------------------------------- Zahlen
func de_num(v: float, dec: int) -> String:
	var s := ("%." + str(dec) + "f") % v
	if dec > 0 and s.find(".") >= 0:
		s = s.rstrip("0").rstrip(".")
	return s.replace(".", ",")

func group(n: int) -> String:
	var s := str(abs(n))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out

const UNITS := ["", " Tsd.", " Mio.", " Mrd.", " Bio.", " Brd.", " Trio.", " Trd."]
func fmt(n: float) -> String:
	if n < 1000.0:
		return de_num(n, 2 if n < 10.0 else 0) + " €"
	var i := 0
	while n >= 1000.0 and i < UNITS.size() - 1:
		n /= 1000.0
		i += 1
	return de_num(n, 2) + UNITS[i] + " €"

func num(n: float) -> String:
	if n < 1e6:
		return group(int(round(n)))
	return fmt(n).replace(" €", "")

# ---------------------------------------------------------------- Start
func _ready() -> void:
	randomize()
	var base := ThemeDB.fallback_font
	bold_font = FontVariation.new()
	bold_font.base_font = base
	bold_font.variation_embolden = 0.9
	load_game()
	if not S.has("mig1"):
		S["g"]["g1"] = max(cnt("g", "g1"), 2)
		S["mig1"] = 1
	if OS.has_environment("BB_VIEW"):
		view = OS.get_environment("BB_VIEW")
	build_ui()
	offline_catchup()
	render()
	http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_update_response)
	check_update(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if not S.is_empty():
			save_game()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		if not S.is_empty():
			offline_catchup()

func _process(dt: float) -> void:
	dt = min(dt, 1.0)
	step(dt)
	raid_tick(dt)
	ui_t += dt
	if ui_t > 0.25:
		ui_t = 0.0
		update_ui()
	if OS.has_environment("BB_SHOT"):
		shot_t += dt
		if shot_t > float(OS.get_environment("BB_WAIT") if OS.has_environment("BB_WAIT") else "3"):
			get_viewport().get_texture().get_image().save_png(OS.get_environment("BB_SHOT"))
			get_tree().quit()
	save_t += dt
	if save_t > 5.0:
		save_t = 0.0
		save_game()

# ---------------------------------------------------------------- UI-Bausteine
func sbox(bg: Color, radius := 22, border := Color(0, 0, 0, 0), bw := 0, pad := 16) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	if bw > 0:
		s.border_color = border
		s.set_border_width_all(bw)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad * 0.75
	s.content_margin_bottom = pad * 0.75
	return s

func lbl(t: String, size := 26, col := C_INK, bold := false, wrap := false) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if bold:
		l.add_theme_font_override("font", bold_font)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func btn(t: String, cb: Callable, kind := "main", minw := 190) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(minw, 78)
	b.add_theme_font_size_override("font_size", 27)
	b.add_theme_font_override("font", bold_font)
	var bg := C_GOLD
	var fg := C_DARK
	if kind == "red":
		bg = C_RED
		fg = Color.WHITE
	elif kind == "light":
		bg = C_CARD2
		fg = C_INK
	elif kind == "teal":
		bg = C_PETROL
		fg = Color.WHITE
	elif kind == "ghost":
		bg = Color(1, 1, 1, 0.16)
		fg = Color.WHITE
	var st := sbox(bg, 18, C_LINE if kind == "light" else Color(0, 0, 0, 0), 2 if kind == "light" else 0, 14)
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("hover", st)
	b.add_theme_stylebox_override("pressed", sbox(bg.darkened(0.15), 18, C_LINE, 0, 14))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("disabled", sbox(Color("#244349"), 18, C_LINE, 0, 14))
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg)
	b.add_theme_color_override("font_pressed_color", fg)
	b.add_theme_color_override("font_focus_color", fg)
	b.add_theme_color_override("font_disabled_color", C_MUT)
	b.pressed.connect(cb)
	return b

func pbar(h := 10) -> ProgressBar:
	var p := ProgressBar.new()
	p.show_percentage = false
	p.custom_minimum_size = Vector2(0, h)
	p.max_value = 100.0
	p.add_theme_stylebox_override("background", sbox(C_MAIN2, 6, Color(0, 0, 0, 0), 0, 0))
	p.add_theme_stylebox_override("fill", sbox(C_GREEN, 6, Color(0, 0, 0, 0), 0, 0))
	return p

func card(empty := false) -> PanelContainer:
	var p := PanelContainer.new()
	if empty:
		p.add_theme_stylebox_override("panel", sbox(Color("#10282d"), 22, Color("#3a6b73"), 3, 18))
	else:
		var st := sbox(C_CARD, 22, C_LINE, 2, 18)
		st.border_width_left = 8
		st.border_color = C_PETROL
		st.shadow_color = Color(0, 0, 0, 0.35)
		st.shadow_size = 6
		st.shadow_offset = Vector2(0, 3)
		p.add_theme_stylebox_override("panel", st)
	content.add_child(p)
	return p

func hb(sep := 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h

func vb(sep := 6) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v

# ---------------------------------------------------------------- Aufbau
func build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := vb(0)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# Kopfleiste
	var head := PanelContainer.new()
	var hs := sbox(C_HEAD, 0, Color(0, 0, 0, 0), 0, 22)
	hs.content_margin_top = 18
	hs.content_margin_bottom = 16
	head.add_theme_stylebox_override("panel", hs)
	root.add_child(head)
	var hv := vb(10)
	head.add_child(hv)
	var r1 := hb()
	hv.add_child(r1)
	var cv := vb(0)
	cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r1.add_child(cv)
	l_cash = lbl("0 €", 64, C_GOLD, true)
	l_inc = lbl("+0 € pro Sekunde", 25, Color(1, 1, 1, 0.85))
	cv.add_child(l_cash)
	cv.add_child(l_inc)
	b_risk = btn("Risiko 0 %", func(): go("guard"), "ghost", 210)
	b_risk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r1.add_child(b_risk)
	var r2 := hb(10)
	hv.add_child(r2)
	var boxes := []
	for t in ["Herstellung", "Auslieferung", "Tresorlager"]:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", sbox(Color(1, 1, 1, 0.1), 14, Color(0, 0, 0, 0), 0, 12))
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r2.add_child(p)
		var v := vb(2)
		p.add_child(v)
		var a := lbl(t, 21, Color(1, 1, 1, 0.75))
		var b := lbl("0", 27, Color.WHITE, true)
		v.add_child(a)
		v.add_child(b)
		boxes.append([a, b, v])
	l_prod = boxes[0][1]
	l_del = boxes[1][1]
	l_stockp = boxes[2][0]
	l_stock = boxes[2][1]
	bar_stock = pbar(8)
	bar_stock.add_theme_stylebox_override("background", sbox(Color(1, 1, 1, 0.2), 4, Color(0, 0, 0, 0), 0, 0))
	bar_stock.add_theme_stylebox_override("fill", sbox(C_GOLD, 4, Color(0, 0, 0, 0), 0, 0))
	boxes[2][2].add_child(bar_stock)

	# 3D-Werk
	world_box = Control.new()
	world_box.custom_minimum_size = Vector2(0, 470)
	world_box.clip_contents = true
	root.add_child(world_box)
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.set_anchors_preset(Control.PRESET_FULL_RECT)
	world_box.add_child(svc)
	var sv := SubViewport.new()
	sv.msaa_3d = Viewport.MSAA_2X
	svc.add_child(sv)
	world = preload("res://world.gd").new()
	world.main = self
	sv.add_child(world)
	svc.gui_input.connect(world.handle_input)

	l_hint = lbl("", 23, C_RED, true)
	var hint_p := PanelContainer.new()
	hint_p.add_theme_stylebox_override("panel", sbox(Color(1, 1, 1, 0.95), 14, Color(0, 0, 0, 0), 0, 12))
	hint_p.add_child(l_hint)
	hint_p.position = Vector2(14, 14)
	hint_p.name = "HintPanel"
	world_box.add_child(hint_p)

	alarm_panel = PanelContainer.new()
	alarm_panel.add_theme_stylebox_override("panel", sbox(C_RED, 18, Color(0, 0, 0, 0), 0, 16))
	alarm_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	alarm_panel.offset_left = 12
	alarm_panel.offset_right = -12
	alarm_panel.offset_top = 12
	alarm_panel.visible = false
	world_box.add_child(alarm_panel)
	var ah := hb()
	alarm_panel.add_child(ah)
	l_alarm = lbl("", 26, Color.WHITE, true, true)
	ah.add_child(l_alarm)
	ah.add_child(btn("Zum Schutz", func(): go("guard"), "light", 170))

	var tools := vb(10)
	tools.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	tools.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tools.grow_vertical = Control.GROW_DIRECTION_BEGIN
	tools.offset_right = -12
	tools.offset_bottom = -12
	world_box.add_child(tools)
	tools.add_child(btn("⤢", func(): toggle_world(), "light", 72))
	tools.add_child(btn("+", func(): world.zoom_by(1.25), "light", 72))
	tools.add_child(btn("−", func(): world.zoom_by(0.8), "light", 72))
	for b in tools.get_children():
		b.custom_minimum_size = Vector2(72, 72)
		b.add_theme_color_override("font_color", C_GOLD)
	var wh := lbl("Ziehen zum Bewegen · Halle antippen", 21, C_INK)
	var whp := PanelContainer.new()
	whp.add_theme_stylebox_override("panel", sbox(Color(0.05, 0.12, 0.14, 0.75), 12, Color(0, 0, 0, 0), 0, 10))
	whp.add_child(wh)
	whp.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	whp.grow_vertical = Control.GROW_DIRECTION_BEGIN
	whp.offset_left = 12
	whp.offset_bottom = -12
	whp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_box.add_child(whp)

	# Inhalt
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var mc := MarginContainer.new()
	mc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + side, 18)
	scroll.add_child(mc)
	content = vb(12)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mc.add_child(content)

	# Navigation
	var nav_p := PanelContainer.new()
	nav_p.add_theme_stylebox_override("panel", sbox(C_HEAD.darkened(0.35), 0, Color(0, 0, 0, 0), 0, 8))
	root.add_child(nav_p)
	var nav := hb(6)
	nav_p.add_child(nav)
	for it in [["werk", "Werk"], ["orders", "Aufträge"], ["deliv", "Fuhrpark"], ["tech", "Technik"], ["feat", "Merkmale"], ["guard", "Schutz"], ["bank", "Bank"]]:
		var key: String = it[0]
		var b := btn(it[1], func(): go(key), "light", 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 92)
		b.add_theme_font_size_override("font_size", 19)
		b.add_theme_stylebox_override("normal", sbox(Color(0, 0, 0, 0), 16, Color(0, 0, 0, 0), 0, 2))
		nav.add_child(b)
		nav_btns[key] = b

	# Update-Dialog
	update_panel = PanelContainer.new()
	update_panel.add_theme_stylebox_override("panel", sbox(C_CARD, 26, C_GOLD, 4, 28))
	update_panel.set_anchors_preset(Control.PRESET_CENTER)
	update_panel.custom_minimum_size = Vector2(600, 0)
	update_panel.visible = false
	add_child(update_panel)
	var uv := vb(18)
	update_panel.add_child(uv)
	uv.add_child(lbl("Update verfügbar", 36, C_GOLD, true))
	l_update = lbl("", 26, C_INK, false, true)
	uv.add_child(l_update)
	var uh := hb()
	uv.add_child(uh)
	var later := btn("Später", func(): update_panel.visible = false, "light", 200)
	var inst := btn("Herunterladen", func():
		OS.shell_open(APK_URL)
		update_panel.visible = false, "main", 260)
	uh.add_child(later)
	uh.add_child(inst)

func toggle_world() -> void:
	world_big = not world_big
	world_box.custom_minimum_size.y = 860 if world_big else 470

func go(v: String, h := "") -> void:
	view = v
	if h != "":
		hall = h
	confirm_reset = ""
	render()
	scroll.scroll_vertical = 0

# ---------------------------------------------------------------- Ansichten
func clear_content() -> void:
	refs.clear()
	for c in content.get_children():
		content.remove_child(c)
		c.queue_free()

func head_title(t: String, sub: String) -> void:
	content.add_child(lbl(t, 38, C_INK, true))
	content.add_child(lbl(sub, 24, C_MUT, false, true))

func amount_row() -> void:
	var h := hb(10)
	h.alignment = BoxContainer.ALIGNMENT_END
	content.add_child(h)
	h.add_child(lbl("Kaufen:", 24, C_MUT))
	for a in ["1", "10", "max"]:
		var key: String = a
		var b := btn("Max" if a == "max" else "×" + a, func(): set_amt(key), "light", 100)
		b.custom_minimum_size = Vector2(100, 62)
		if a == amt:
			b.add_theme_stylebox_override("normal", sbox(C_CARD2, 16, C_GOLD, 4, 10))
			b.add_theme_color_override("font_color", C_GOLD)
		h.add_child(b)

func set_amt(a: String) -> void:
	amt = a
	render()

func render() -> void:
	if content == null:
		return
	clear_content()
	for k in nav_btns.keys():
		var on: bool = k == view
		nav_btns[k].add_theme_stylebox_override("normal", sbox(C_GOLD if on else Color(0, 0, 0, 0), 16, Color(0, 0, 0, 0), 0, 4))
		nav_btns[k].add_theme_color_override("font_color", C_DARK if on else C_MUT)
	match view:
		"werk":
			render_werk()
		"bank":
			render_bank()
		"orders":
			render_orders()
		_:
			render_list()
	update_ui()

func render_werk() -> void:
	var seg := PanelContainer.new()
	seg.add_theme_stylebox_override("panel", sbox(C_CARD, 20, C_LINE, 2, 6))
	content.add_child(seg)
	var sh := hb(6)
	seg.add_child(sh)
	var hc := 0
	var hn := 0
	for l in LINES:
		if l.get("note", false):
			hn += cnt("l", l.id)
		else:
			hc += cnt("l", l.id)
	for it in [["coin", "Münzhalle\n%d Pressen" % hc], ["note", "Druckhalle\n%d Maschinen" % hn], ["lager", "Lager\nStufe %d" % (int(S["lv"]) + 1)]]:
		var key: String = it[0]
		var on := hall == key
		var b := btn(it[1], func(): go("werk", key), "main" if on else "light", 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 88)
		b.add_theme_font_size_override("font_size", 23)
		if not on:
			b.add_theme_stylebox_override("normal", sbox(Color(0, 0, 0, 0), 16, Color(0, 0, 0, 0), 0, 6))
		sh.add_child(b)
	if hall == "lager":
		render_lager()
		return
	amount_row()
	for l in LINES:
		if bool(l.get("note", false)) == (hall == "note"):
			line_card(l)
	content.add_child(lbl("Jede Linie hat 10 Maschinenplätze. Danach steigt sie bei 25, 50, 100 … Maschinen eine Stufe auf (Produktion ×2, Lampenfarbe wechselt).", 22, C_MUT, false, true))

func line_card(l: Dictionary) -> void:
	var c := cnt("l", l.id)
	var p := card(c == 0)
	var v := vb(6)
	p.add_child(v)
	var top := hb(10)
	v.add_child(top)
	var dot := ColorRect.new()
	dot.color = Color(l.col)
	dot.custom_minimum_size = Vector2(22, 22)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(dot)
	var t := lbl(l.n, 29, C_INK, true)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	var rate := lbl("", 26, C_GOLD, true)
	top.add_child(rate)
	var row := hb(14)
	v.add_child(row)
	var left := vb(6)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	var desc := lbl("", 23, C_MUT, false, true)
	left.add_child(desc)
	var bar: ProgressBar = null
	if c > 0:
		bar = pbar(8)
		left.add_child(bar)
	var id: String = l.id
	var b := btn("", func(): buy("l:" + id), "main", 220)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(b)
	refs["l:" + id] = {btn=b, desc=desc, rate=rate, title=t, bar=bar, line=l}

func render_lager() -> void:
	var p := card()
	var v := vb(8)
	p.add_child(v)
	var top := hb()
	v.add_child(top)
	var t := lbl("Tresorlager", 29, C_INK, true)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	var lvl := lbl("", 26, C_GOLD, true)
	top.add_child(lvl)
	var bar := pbar(12)
	v.add_child(bar)
	var row := hb(14)
	v.add_child(row)
	var desc := lbl("", 23, C_MUT, false, true)
	row.add_child(desc)
	var b := btn("", func(): buy("s:lager"), "main", 240)
	row.add_child(b)
	refs["lager"] = {btn=b, desc=desc, rate=lvl, bar=bar}
	var p2 := card()
	var v2 := vb(8)
	p2.add_child(v2)
	v2.add_child(lbl("Verladerampe", 29, C_INK, true))
	var fl := []
	for x in VAN:
		if cnt("v", x.id) > 0:
			fl.append("%s ×%d" % [x.n, cnt("v", x.id)])
	v2.add_child(lbl(" · ".join(fl) if fl.size() > 0 else "Keine Fahrzeuge", 23, C_MUT, false, true))
	v2.add_child(btn("Zum Fuhrpark", func(): go("deliv"), "main", 240))

const HEAD := {
	"deliv": ["Fuhrpark", "Nur ausgeliefertes Geld landet in der Kasse."],
	"tech": ["Technik", "Einmalige Verbesserungen für Werk und Logistik."],
	"feat": ["Sicherheitsmerkmale", "Senken den Falschgeld-Verlust und schalten die Druckhalle frei."],
	"guard": ["Schutz", "Alles, was du kaufst, steht sichtbar auf dem Gelände."],
}

func list_items() -> Array:
	var out := []
	match view:
		"deliv":
			for x in VAN:
				out.append({k="v:" + x.id, n=x.n, c=cnt("v", x.id), d="%s · %s/s je Fahrzeug" % [x.d, fmt(x.r * del_m())], multi=true, b=x.b})
		"tech":
			for x in TECH:
				out.append({k="t:" + x.id, n=x.n, d=x.d, done=has_flag("t", x.id), price=x.c})
		"feat":
			for x in FEAT:
				out.append({k="f:" + x.id, n=x.n, d="%s · Falschgeld −%d %%" % [x.d, x.red], done=has_flag("f", x.id), price=x.c})
		"guard":
			for x in GUARD:
				out.append({k="g:" + x.id, n=x.n, c=cnt("g", x.id), d=x.d, multi=true, b=x.b})
	return out

func render_list() -> void:
	head_title(HEAD[view][0], HEAD[view][1])
	if view == "guard":
		var p := card()
		var v := vb(8)
		p.add_child(v)
		var top := hb()
		v.add_child(top)
		var t := lbl("Überfallrisiko", 29, C_INK, true)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(t)
		var rk := lbl("", 27, C_GOLD, true)
		top.add_child(rk)
		var bar := pbar(12)
		v.add_child(bar)
		var d := lbl("", 23, C_MUT, false, true)
		v.add_child(d)
		refs["risk"] = {rate=rk, bar=bar, desc=d}
	if view == "deliv" or view == "guard":
		amount_row()
	for it in list_items():
		var p := card()
		var row := hb(14)
		p.add_child(row)
		var left := vb(4)
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(left)
		var t := lbl(it.n, 28, C_INK, true, true)
		left.add_child(t)
		var desc := lbl("", 23, C_MUT, false, true)
		left.add_child(desc)
		var key: String = it.k
		var b := btn("", func(): buy(key), "main", 220)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(b)
		refs[key] = {btn=b, desc=desc, title=t, panel=p}

func render_orders() -> void:
	head_title("Aufträge", "Länder außerhalb der EU bestellen Münzen und Scheine. Jeder laufende Auftrag nutzt 20 % deiner Herstellung und zahlt am Ende einen hohen Lohn.")
	for i in range(S["orders"].size()):
		var o: Dictionary = S["orders"][i]
		var idx := i
		if o.get("wait", 0.0) > 0.0:
			var pe := card(true)
			var le := lbl("", 24, C_MUT, false, true)
			pe.add_child(le)
			refs["o%d" % i] = {wait=le}
			continue
		var p := card()
		var v := vb(8)
		p.add_child(v)
		var top := hb(10)
		v.add_child(top)
		var flag := hb(0)
		for fc in o.flag:
			var cr := ColorRect.new()
			cr.color = Color(fc)
			cr.custom_minimum_size = Vector2(16, 34)
			flag.add_child(cr)
		flag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		top.add_child(flag)
		var t := lbl(o.land, 30, C_INK, true)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(t)
		top.add_child(lbl("Lohn " + fmt(o.reward), 26, C_GOLD, true))
		v.add_child(lbl("%s %s herstellen" % [num_cur(o.need * o.fx), o.cur], 25, C_INK, false, true))
		var bar := pbar(12)
		v.add_child(bar)
		var row := hb(12)
		v.add_child(row)
		var info := lbl("", 23, C_MUT, false, true)
		row.add_child(info)
		if o.get("active", false):
			row.add_child(lbl("läuft", 26, C_GREEN, true))
		else:
			row.add_child(btn("Ablehnen", func(): decline_order(idx), "light", 170))
			row.add_child(btn("Annehmen", func(): accept_order(idx), "main", 190))
		refs["o%d" % i] = {bar=bar, info=info}
	content.add_child(lbl("Bis zu 3 Aufträge werden angeboten. Ist einer erledigt, kommt nach kurzer Zeit ein neuer. Erledigt bisher: %d" % int(S.get("odone", 0)), 22, C_MUT, false, true))

func render_bank() -> void:
	head_title("Bank", "Reform, App, Spielstand und Lagebericht.")
	var gain := int(floor(sqrt(float(S["total"]) / 1e9)))
	var p := card()
	var v := vb(8)
	p.add_child(v)
	v.add_child(lbl("Währungsreform", 29, C_INK, true))
	v.add_child(lbl("Setzt Werk, Fuhrpark, Technik, Merkmale und Schutz zurück. Jeder Reputationspunkt bringt dauerhaft +10 % auf Herstellung und Auslieferung. Ab 1 Mrd. € in dieser Runde.", 23, C_MUT, false, true))
	var row := hb(14)
	v.add_child(row)
	row.add_child(lbl("Reputation %d · Reform bringt +%d" % [int(S["rep"]), gain], 23, C_MUT, false, true))
	var rb := btn("Wirklich?" if confirm_reset == "reform" else "Reform", func(): do_reform(), "red" if confirm_reset == "reform" else "main", 200)
	rb.disabled = gain < 1
	row.add_child(rb)

	var p2 := card()
	var v2 := vb(6)
	p2.add_child(v2)
	v2.add_child(lbl("Statistik", 29, C_INK, true))
	v2.add_child(lbl("Insgesamt ausgeliefert: %s\nDiese Runde: %s\nÜberfälle abgewehrt %d · verloren %d\nFalschgeld-Verlust %d %%" % [fmt(S["life"]), fmt(S["total"]), int(S["won"]), int(S["lost"]), cf_pct()], 23, C_MUT, false, true))

	var p3 := card()
	var v3 := vb(8)
	p3.add_child(v3)
	v3.add_child(lbl("App & Updates", 29, C_INK, true))
	var r3 := hb(14)
	v3.add_child(r3)
	r3.add_child(lbl("Installierte Version %s. Neue Versionen werden beim Start automatisch gesucht." % ProjectSettings.get_setting("application/config/version", "?"), 23, C_MUT, false, true))
	r3.add_child(btn("Jetzt prüfen", func(): check_update(true), "main", 220))

	var p4 := card()
	var v4 := vb(8)
	p4.add_child(v4)
	v4.add_child(lbl("Spielstand sichern", 29, C_INK, true))
	v4.add_child(lbl("Kopiere den Code und bewahre ihn auf. Auch Codes aus der alten App-Version funktionieren.", 23, C_MUT, false, true))
	var msg := lbl("", 23, C_GREEN, true, true)
	var r4 := hb(10)
	v4.add_child(r4)
	var copy_b := btn("Code kopieren", func():
		DisplayServer.clipboard_set(Marshalls.utf8_to_base64(JSON.stringify(S)))
		msg.text = "Code kopiert.", "main", 0)
	copy_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r4.add_child(copy_b)
	var load_b := btn("Code einfügen", func():
		msg.text = import_code(DisplayServer.clipboard_get()), "light", 0)
	load_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r4.add_child(load_b)
	v4.add_child(msg)

	var p5 := card()
	var v5 := vb(6)
	p5.add_child(v5)
	v5.add_child(lbl("Lagebericht", 29, C_INK, true))
	if S["log"].size() == 0:
		v5.add_child(lbl("Noch keine Ereignisse.", 23, C_MUT))
	for e in S["log"]:
		var col := C_INK
		if e.get("c", "") == "bad":
			col = C_RED
		elif e.get("c", "") == "good":
			col = C_GREEN
		v5.add_child(lbl("%s · %s" % [e.get("time", ""), e.get("t", "")], 23, col, false, true))

	var p6 := card()
	var r6 := hb(14)
	p6.add_child(r6)
	var lv6 := vb(2)
	lv6.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r6.add_child(lv6)
	lv6.add_child(lbl("Neu anfangen", 29, C_INK, true))
	lv6.add_child(lbl("Löscht den gesamten Spielstand.", 23, C_MUT, false, true))
	r6.add_child(btn("Sicher?" if confirm_reset == "wipe" else "Löschen", func(): do_wipe(), "red", 200))
	content.add_child(lbl("Fan-Spiel ohne Verbindung zur Deutschen Bundesbank.", 21, C_MUT, false, true))

func import_code(code: String) -> String:
	code = code.strip_edges()
	if code == "":
		return "Die Zwischenablage ist leer."
	var txt := Marshalls.base64_to_utf8(code)
	var x = JSON.parse_string(txt)
	if typeof(x) != TYPE_DICTIONARY or not x.has("cash"):
		return "Der Code ist ungültig."
	apply_state(x)
	S["ts"] = now()
	S["warn"] = 0.0
	world.dirty = true
	save_game()
	add_log("Spielstand aus Code geladen.", "good")
	render()
	return "Spielstand geladen."

func do_reform() -> void:
	if confirm_reset != "reform":
		confirm_reset = "reform"
		render()
		return
	var g := int(floor(sqrt(float(S["total"]) / 1e9)))
	if g < 1:
		return
	var keep := {rep=int(S["rep"]) + g, life=S["life"], won=S["won"], lost=S["lost"], log=S["log"]}
	apply_state(keep)
	confirm_reset = ""
	world.dirty = true
	add_log("Währungsreform! Reputation jetzt %d." % int(S["rep"]), "good")
	render()

func do_wipe() -> void:
	if confirm_reset != "wipe":
		confirm_reset = "wipe"
		render()
		return
	S = blank()
	confirm_reset = ""
	world.dirty = true
	save_game()
	render()

# ---------------------------------------------------------------- Kaufen
func buy(k: String) -> void:
	var parts := k.split(":")
	var t := parts[0]
	var id := parts[1]
	world.dirty = true
	if t == "s":
		var pr := cap_cost()
		if S["cash"] < pr:
			return
		S["cash"] -= pr
		S["lv"] = int(S["lv"]) + 1
		add_log("Tresorlager ausgebaut auf %s." % fmt(cap()), "good")
		save_game()
		render()
		return
	if t == "l" or t == "g" or t == "v":
		var src: Array = LINES if t == "l" else (GUARD if t == "g" else VAN)
		var x: Dictionary = {}
		for y in src:
			if y.id == id:
				x = y
		if x.has("req") and feat_n() < int(x.req):
			return
		var c := cnt(t, id)
		var n := how_many(x.b, c) if (c > 0 or t != "l") else 1
		var pr := cost_n(x.b, c, n)
		if S["cash"] < pr:
			return
		S["cash"] -= pr
		S[t][id] = c + n
		if c == 0:
			var pre := {"l": "Neue Fertigungslinie gebaut: ", "g": "Neuer Schutz: ", "v": "Neues Fahrzeug: "}
			add_log(pre[t] + x.n, "good")
		if t == "l" and ms_n(c + n) > ms_n(c):
			add_log("%s: neue Stufe erreicht, Produktion ×2!" % x.n, "good")
		if t == "l":
			save_game()
			render()
			return
	else:
		var src2: Array = TECH if t == "t" else FEAT
		for y in src2:
			if y.id == id:
				if has_flag(t, id) or S["cash"] < y.c:
					return
				S["cash"] -= y.c
				S[t][id] = 1
				add_log(("Technik eingeführt: " if t == "t" else "Sicherheitsmerkmal eingeführt: ") + y.n, "good")
	save_game()
	update_ui()

# ---------------------------------------------------------------- Aktualisieren
func update_ui() -> void:
	if l_cash == null:
		return
	var p := prod()
	var d := deliv()
	var c := cap()
	var sp: float = float(S["stock"]) / c * 100.0
	var rk := risk()
	l_cash.text = fmt(S["cash"])
	l_inc.text = "+%s pro Sekunde" % fmt(income())
	l_prod.text = fmt(p) + "/s"
	l_del.text = fmt(d) + "/s"
	l_stock.text = fmt(S["stock"])
	l_stockp.text = "Tresorlager %d %%" % int(sp)
	bar_stock.value = sp
	var hint := ""
	if S["warn"] <= 0.0:
		if sp > 95.0 and p > d:
			hint = "Lager voll – mehr Fahrzeuge oder größeres Lager!"
		elif p > d * 1.5:
			hint = "Fuhrpark kommt nicht hinterher."
		elif d > p * 3.0:
			hint = "Fahrzeuge warten – Werk ausbauen."
	l_hint.text = hint
	world_box.get_node("HintPanel").visible = hint != ""
	b_risk.text = ("Alarm · " if S["warn"] > 0.0 else "Risiko ") + "%d %%" % int(round(rk))
	var hot: bool = rk > 50.0 or S["warn"] > 0.0
	b_risk.add_theme_stylebox_override("normal", sbox(C_RED if hot else Color(1, 1, 1, 0.16), 18, Color(0, 0, 0, 0), 0, 14))
	nav_btns["guard"].text = "Schutz •" if hot else "Schutz"
	var open_n := 0
	for o in S["orders"]:
		if o.get("land", "") != "" and not o.get("active", false) and o.get("wait", 0.0) <= 0.0:
			open_n += 1
	nav_btns["orders"].text = "Aufträge %d" % open_n if open_n > 0 else "Aufträge"

	if view == "werk":
		if hall == "lager" and refs.has("lager"):
			var r: Dictionary = refs["lager"]
			var pr := cap_cost()
			r.btn.text = "Ausbauen " + fmt(pr)
			r.btn.disabled = S["cash"] < pr
			r.rate.text = "Stufe %d" % (int(S["lv"]) + 1)
			r.desc.text = "%s von %s · nächste Stufe %s" % [fmt(S["stock"]), fmt(c), fmt(c * 3.0)]
			r.bar.value = sp
			return
		for l in LINES:
			var key: String = "l:" + l.id
			if not refs.has(key):
				continue
			var r: Dictionary = refs[key]
			var c2 := cnt("l", l.id)
			var lk: bool = l.has("req") and feat_n() < int(l.req)
			var n := how_many(l.b, c2) if c2 > 0 else 1
			var pr := cost_n(l.b, c2, n)
			r.btn.text = ("+%d · %s" % [n, fmt(pr)]) if c2 > 0 else "Bauen " + fmt(pr)
			r.btn.disabled = lk or S["cash"] < pr
			if c2 > 0:
				var nm := next_ms(c2)
				var pm: int = MS[ms_n(c2) - 1] if ms_n(c2) > 0 else 0
				r.title.text = "%s ×%d" % [l.n, c2]
				r.rate.text = fmt(line_rate(l)) + "/s"
				if c2 < 10:
					r.desc.text = "%d von 10 Plätzen belegt · Bonus ×2 bei 10" % c2
					r.bar.value = c2 * 10
				elif nm > 0:
					r.desc.text = "Linie voll · nächste Stufe (×2) bei %d Maschinen" % nm
					r.bar.value = float(c2 - pm) / float(nm - pm) * 100.0
				else:
					r.desc.text = "Höchste Stufe erreicht"
					r.bar.value = 100
			else:
				r.rate.text = fmt(l.r * base_mul(l)) + "/s je Maschine"
				r.desc.text = ("Gesperrt: benötigt %d Sicherheitsmerkmale (du hast %d)" % [int(l.req), feat_n()]) if lk else "Bauplatz frei · " + l.d
		return
	if view == "bank":
		return
	if view == "orders":
		var p2 := prod()
		for i in range(S["orders"].size()):
			var key := "o%d" % i
			if not refs.has(key):
				continue
			var o: Dictionary = S["orders"][i]
			var r: Dictionary = refs[key]
			if r.has("wait"):
				r.wait.text = "Neuer Auftrag kommt in %d s …" % int(ceil(max(0.0, o.get("wait", 0.0))))
				continue
			r.bar.value = o.done / o.need * 100.0
			var rest: float = (o.need - o.done) / max(0.001, p2 * ORDER_SHARE)
			if o.get("active", false):
				r.info.text = "%d %% fertig · noch ca. %s" % [int(o.done / o.need * 100.0), dur_txt(rest)]
			else:
				r.info.text = "Dauer ca. %s bei deiner Herstellung" % dur_txt(rest)
		return
	if view == "guard" and refs.has("risk"):
		var r: Dictionary = refs["risk"]
		r.rate.text = "%d %%" % int(round(rk))
		r.bar.value = rk
		var nxt := "Überfall läuft!" if S["warn"] > 0.0 else "nächste Bedrohung in ca. %d s" % int(ceil(S["next"]))
		r.desc.text = "Schutz %s gegen Bedrohung %s · %s · abgewehrt %d, verloren %d" % [num(defense()), num(threat()), nxt, int(S["won"]), int(S["lost"])]
	for it in list_items():
		if not refs.has(it.k):
			continue
		var r: Dictionary = refs[it.k]
		r.desc.text = it.d
		if it.get("multi", false):
			var n := how_many(it.b, it.c)
			var pr := cost_n(it.b, it.c, n)
			r.btn.text = ("%d× " % n if n > 1 else "") + fmt(pr)
			r.btn.disabled = S["cash"] < pr
			r.title.text = "%s ×%d" % [it.n, it.c]
		else:
			r.btn.text = "Aktiv" if it.done else fmt(it.price)
			r.btn.disabled = it.done or S["cash"] < it.price

# ---------------------------------------------------------------- Updates
func check_update(manual: bool) -> void:
	manual_check = manual
	if http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	var err := http.request("https://api.github.com/repos/%s/releases/latest" % REPO, ["Accept: application/vnd.github+json", "User-Agent: BundesbankIdle"])
	if err != OK and manual:
		add_log("Update-Prüfung fehlgeschlagen.", "bad")

func _on_update_response(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		if manual_check:
			add_log("Update-Prüfung fehlgeschlagen. Bist du online?", "bad")
		return
	var j = JSON.parse_string(body.get_string_from_utf8())
	if typeof(j) != TYPE_DICTIONARY:
		return
	var tag: String = str(j.get("tag_name", ""))
	var latest := version_num(tag)
	var mine := version_num(str(ProjectSettings.get_setting("application/config/version", "0")))
	if latest > mine:
		l_update.text = "Version %s ist da. Tippe auf „Herunterladen“, öffne danach die Datei und tippe auf „Installieren“. Dein Spielstand bleibt erhalten." % tag
		update_panel.visible = true
	elif manual_check:
		add_log("Du hast die neueste Version (%s)." % ProjectSettings.get_setting("application/config/version", "?"), "good")

func version_num(v: String) -> int:
	var parts := v.replace("v", "").split(".")
	var n := 0
	for i in range(min(3, parts.size())):
		n = n * 10000 + int(parts[i])
	for i in range(3 - min(3, parts.size())):
		n *= 10000
	return n
