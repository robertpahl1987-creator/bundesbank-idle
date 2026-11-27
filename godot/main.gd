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
	{id="g6", n="Polizeiwache vor Ort", d="Schutz +1.200 · baut die Wache aus (ab 3, 6, 10: größer)", b=5e6, v=1200},
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
	{n="Japan", far=true, cur="Yen", fx=160.0, flag=["#ffffff", "#bc002d", "#ffffff"]},
	{n="USA", far=true, cur="Dollar", fx=1.08, flag=["#3c3b6e", "#ffffff", "#b22234"]},
	{n="Kanada", far=true, cur="Dollar", fx=1.5, flag=["#ff0000", "#ffffff", "#ff0000"]},
	{n="Australien", far=true, cur="Dollar", fx=1.65, flag=["#012169", "#ffffff", "#e4002b"]},
	{n="Mexiko", far=true, cur="Pesos", fx=21.0, flag=["#006847", "#ffffff", "#ce1126"]},
	{n="Brasilien", far=true, cur="Real", fx=6.2, flag=["#009c3b", "#ffdf00", "#002776"]},
]
const ORDER_SHARE := 0.2
const MGR := [
	{id="coin", n="Leiterin Münzhalle", d="Münzhalle ×1,5 · kauft Pressen nach", c=5000.0},
	{id="fleet", n="Fuhrparkchef", d="Auslieferung ×1,5 · kauft auf Wunsch Fahrzeuge nach (Automatik standardmäßig aus)", c=20000.0},
	{id="sec", n="Sicherheitschefin", d="Schutz ×1,25 · kauft Schutz nach, wenn das Risiko über 40 % steigt", c=50000.0},
	{id="note", n="Leiter Druckhalle", d="Druckhalle ×1,5 · kauft Druckwerke nach", c=5e6},
]
const SITES := [
	{id="mainz", n="Zweigwerk Mainz", d="Münzprägung: Münzhalle ×2", c=5e6},
	{id="leipzig", n="Logistik Leipzig", d="Verteilzentrum: Auslieferung ×2", c=5e7},
	{id="muenchen", n="Druckerei München", d="Banknotendruck: Druckhalle ×2", c=5e8},
	{id="hamburg", n="Hafen Hamburg", d="Export: Auftragslohn ×1,5", c=2e9},
]
const EVENTS := [
	{id="strike", t="Streik in der Münzhalle", d="Die Belegschaft legt die Arbeit nieder und fordert mehr Lohn.", a="Lohnerhöhung zahlen", mins=5.0, b="Abwarten (Münzhalle 2 Min. halbiert)", fx={k="coin", m=0.5, dur=120.0}},
	{id="power", t="Stromausfall", d="Ein Umspannwerk in der Nähe ist ausgefallen.", a="Notstrom mieten", mins=4.0, b="Abwarten (Werk 60 s still)", fx={k="prod", m=0.0, dur=60.0}},
	{id="break", t="Maschinenschaden", d="An einer Linie ist ein Hydraulikschlauch geplatzt.", a="Techniker rufen", mins=3.0, b="Selbst reparieren (Linie 3 Min. aus)", fx={k="line", m=0.0, dur=180.0}},
	{id="paper", t="Papierknappheit", d="Der Lieferant für Banknotenpapier ist im Verzug.", a="Express-Lieferung", mins=5.0, b="Abwarten (Druckhalle 3 Min. halbiert)", fx={k="note", m=0.5, dur=180.0}},
	{id="xmas", t="Großbestellung zu Weihnachten", d="Die Geschäftsbanken brauchen dringend Bargeld für die Feiertage.", a="Sonderschicht (Auslieferung ×2 für 3 Min.)", good=true, fxa={k="del", m=2.0, dur=180.0}, b="Ablehnen"},
	{id="audit", t="Besuch vom Rechnungshof", d="Die Prüfer wollen die Bücher sehen.", a="Alles offenlegen (Bonus)", bonus=3.0, b="Vertrösten (Werk 2 Min. ×0,8)", fx={k="prod", m=0.8, dur=120.0}},
	{id="heat", t="Hitzewelle", d="In den Hallen wird es über 35 Grad heiß.", a="Klimageräte mieten", mins=3.0, b="Durchhalten (Werk 2 Min. ×0,7)", fx={k="prod", m=0.7, dur=120.0}},
]
const COMMEMS := ["2 € Kölner Dom", "2 € Brandenburger Tor", "2 € Elbphilharmonie", "2 € Schloss Sanssouci", "2 € Wartburg", "2 € Fußball-EM", "2 € Mauerfall-Jubiläum", "2 € Holstentor", "2 € Zugspitze", "2 € Bremer Stadtmusikanten", "2 € Semperoper", "2 € Rügen-Kreidefelsen"]
const FEATNAMES := [["Wasserzeichen", "Wasserzeichn"], ["Sicherheitsfaden", "Sicherheitsfadn"], ["Hologramm", "Hologram"], ["Smaragd-Zahl", "Smaragt-Zahl"], ["Mikroschrift", "Mikroschift"], ["Relief", "Releif"]]
const ACH := [
	{id="a1", n="Erste Million", d="1 Mio. € ausgeliefert"},
	{id="a2", n="Erste Milliarde", d="1 Mrd. € ausgeliefert"},
	{id="a3", n="Billionär", d="1 Bio. € ausgeliefert"},
	{id="a4", n="Wachsam", d="10 Überfälle abgewehrt"},
	{id="a5", n="Festung", d="50 Überfälle abgewehrt"},
	{id="a6", n="Druckerpresse", d="Erste Druckhalle-Linie gebaut"},
	{id="a7", n="Volles Werk", d="Alle 9 Linien gebaut"},
	{id="a8", n="Linie voll", d="Eine Linie mit 10 Maschinen"},
	{id="a9", n="Großserie", d="100 Maschinen in einer Linie"},
	{id="a10", n="Exporteur", d="5 Aufträge erledigt"},
	{id="a11", n="Welthandel", d="25 Aufträge erledigt"},
	{id="a12", n="Sammler", d="Erste Gedenkmünze geprägt"},
	{id="a13", n="Fälschungssicher", d="Alle Sicherheitsmerkmale"},
	{id="a14", n="Falschgeld-Jäger", d="10 Fälschungen erkannt"},
	{id="a15", n="Reformer", d="Erste Währungsreform"},
	{id="a16", n="Goldschatz", d="10 Goldbarren"},
	{id="a17", n="Bundesweit", d="Alle Standorte eröffnet"},
	{id="a18", n="Treue", d="7 Tage in Folge gespielt"},
]
const DAY_LEN := 480.0

const ROOMS := [
	{id="lobby", n="Eingangshalle", d="Empfang für Kunden und Besucher: +2 % Auftragslohn je Stufe. Voraussetzung für alle anderen Räume.", c=2000.0},
	{id="chef", n="Büro des Managers", d="Chefbüro: +4 % Herstellung je Stufe.", c=8000.0},
	{id="hr", n="Personalbüro", d="+4 Plätze für Verwaltungskräfte je Stufe.", c=5000.0},
	{id="umk", n="Umkleideraum", d="Spinde für 20 weitere Mitarbeiter je Stufe.", c=4000.0},
	{id="putz", n="Putzraum", d="Platz für 3 Reinigungskräfte je Stufe.", c=3000.0},
	{id="kantine", n="Kantine", d="+8 Zufriedenheit je Stufe.", c=15000.0},
	{id="pause", n="Pausenraum", d="+6 Zufriedenheit je Stufe.", c=10000.0},
	{id="leit", n="Sicherheitszentrale", d="Bildschirmwand und Funk: +10 % Schutz je Stufe.", c=25000.0},
	{id="buch", n="Buchhaltung", d="Spart Lohnkosten: −5 % Löhne je Stufe.", c=20000.0},
	{id="it", n="IT-Abteilung", d="Wehrt Hackerangriffe ab: 22 % Abwehr je Stufe, ab Stufe 5 komplett.", c=30000.0},
	{id="sani", n="Sanitätsraum", d="Betriebssanitäter: Arbeitsunfälle sind je Stufe deutlich kürzer.", c=12000.0},
]
const STAFF := [
	{id="arb", n="Produktionsmitarbeiter", d="Ohne sie steht jede Maschine still. Mehr Maschinen brauchen mehr Personal.", fee=50.0},
	{id="fahr", n="Fahrer", d="Ohne Fahrer wird nichts ausgeliefert – und ohne Auslieferung kein Geld.", fee=60.0},
	{id="wach", n="Wachleute", d="+4 % Schutz je Person (bis +100 %).", fee=80.0},
	{id="putz", n="Reinigungskräfte", d="+2 % Herstellung je Person (bis +20 %), weniger Maschinenschäden. Braucht den Putzraum.", fee=40.0},
	{id="spr", n="Springer", d="Springen ein, wenn Kollegen krank oder im Urlaub sind.", fee=55.0},
	{id="azubi", n="Auszubildende", d="Günstig, zählen halb. Alle 4 Minuten wird einer zum Produktionsmitarbeiter.", fee=20.0},
	{id="tech", n="Techniker", d="Warten die Maschinen: seltenere und kürzere Maschinenschäden.", fee=90.0},
	{id="verw", n="Verwaltungskräfte", d="+3 % Auftragslohn je Person (bis +60 %), −2 % Löhne (bis −40 %). Braucht das Personalbüro.", fee=100.0},
]
const PAY_PERIOD := 300.0
const SHIFT_N := ["Einschicht", "Zweischicht", "Dreischicht (mit Nacht)"]
const SHIFT_PROD := [0.7, 1.0, 1.3]
const SHIFT_NEED := [0.6, 1.0, 1.5]
const SHIFT_WAGE := [0.7, 1.0, 1.5]
const UPG := [
	{id="power", n="Notstromaggregat", d="Springt bei Stromausfall automatisch an: Stufe 1 hält 50 %, Stufe 2 85 %, Stufe 3 die volle Produktion.", c=5e4, k=8.0, mx=3},
	{id="ctrl", n="Ausgangskontrolle", d="Durchleuchtung und Taschenkontrolle: erwischt Innentäter, die Scheine rausschmuggeln (30 % je Stufe).", c=3e4, k=6.0, mx=3},
	{id="raw", n="Rohstofflager & Lieferverträge", d="Mehr Lieferungen von Metallrohlingen, Banknotenpapier und Farbe. Ohne Nachschub laufen die Linien langsamer.", c=2e4, k=5.0, mx=4},
	{id="winter", n="Winterdienst", d="Streufahrzeuge räumen bei Schnee: Auslieferung bleibt fast voll.", c=1e5, k=6.0, mx=3},
	{id="park", n="Mitarbeiter-Parkhaus", d="+3 Zufriedenheit je Stufe. Füllt sich sichtbar mit Autos.", c=2e5, k=6.0, mx=3},
	{id="terr", n="Kantinen-Terrasse", d="+4 Zufriedenheit je Stufe. Tische und Sonnenschirme hinter der Verwaltung.", c=8e4, k=5.0, mx=2},
	{id="bus", n="Museumsbusse & Schulklassen", d="+5 % Museumsbonus je Stufe. Busse und Schulklassen besuchen das Museum.", c=3e5, k=5.0, mx=3},
]
const LZB := ["Saarland", "Bremen", "Hamburg", "Mecklenburg-Vorpommern", "Thüringen", "Sachsen-Anhalt", "Brandenburg", "Schleswig-Holstein", "Berlin", "Sachsen", "Rheinland-Pfalz", "Niedersachsen", "Hessen", "Baden-Württemberg", "Bayern", "Nordrhein-Westfalen"]
const SERIES := ["Banknotenserie „Europa III“", "Serie „Kulturerbe“", "Serie „Hybrid-Sicherheit“"]
const WX := {"sun": ["Sonnig", 1.0], "cloud": ["Bewölkt", 1.0], "rain": ["Regen", 0.92], "storm": ["Gewitter", 0.85], "snow": ["Schnee", 0.75]}

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
var upd_bar: ProgressBar
var upd_btn: Button
var upd_browser: Button
var dl: HTTPRequest
const UPD_FILE := "user://update.apk"

## Lädt die neue APK in den App-Speicher und öffnet direkt die Android-Installation
func cleanup_old_apk() -> void:
	if FileAccess.file_exists(UPD_FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(UPD_FILE))

func start_download() -> void:
	# Kein Installieren aus der App heraus mehr (Play Protect stuft das als verdächtig ein):
	# die neue Version wird im Browser geladen und von Android installiert.
	save_game()
	OS.shell_open(APK_URL)
	l_update.text = "Der Download läuft im Browser. Öffne danach die Datei „BundesbankIdle.apk“ und tippe auf „Aktualisieren“. Dein Spielstand bleibt erhalten."
	upd_btn.text = "Nochmal laden"

func download_tick() -> void:
	if dl == null or not upd_bar.visible or dl.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		return
	var total := dl.get_body_size()
	if total > 0:
		upd_bar.value = float(dl.get_downloaded_bytes()) / float(total) * 100.0
		upd_btn.text = "Lädt … %d %%" % int(upd_bar.value)

func _on_download_done(result: int, code: int, _h: PackedStringArray, _b: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200 or not FileAccess.file_exists(UPD_FILE):
		download_failed()
		return
	upd_bar.value = 100
	upd_bar.visible = false
	upd_btn.text = "Installation startet …"
	save_game()
	var err := OS.shell_open(ProjectSettings.globalize_path(UPD_FILE))
	if err != OK:
		download_failed()
		return
	l_update.text = "Fast fertig: Android verlangt aus Sicherheitsgründen noch einen Tipp auf „Aktualisieren“ bzw. „Installieren“. Beim ersten Mal musst du einmalig erlauben, dass diese App Updates installieren darf.\nErscheint nichts, tippe auf „Im Browser laden“."
	upd_btn.disabled = false
	upd_btn.text = "Erneut öffnen"
	upd_browser.visible = true

func download_failed() -> void:
	upd_bar.visible = false
	upd_btn.disabled = false
	upd_btn.text = "Im Browser laden"
	l_update.text = "Das direkte Update hat nicht geklappt. Tippe auf „Im Browser laden“ – danach die Datei öffnen und installieren."
	upd_browser.visible = true
var world_big := false
var world_svc: SubViewportContainer

const GFX_NAMES := ["Sparsam", "Hoch", "Ultra"]
const GFX_RES := [0.5, 0.8, 1.0]

## Das 3D-Werk in der echten Pixel-Auflösung des Handys zeichnen (statt hochskaliert)
func update_world_res() -> void:
	if world_svc == null or world == null:
		return
	var sc: float = get_viewport().get_final_transform().get_scale().x
	if sc <= 0.0:
		sc = 1.0
	var q: float = GFX_RES[clamp(int(S.get("gfx", 2)), 0, 2)]
	var f: float = max(sc * q, 0.5)
	var px := Vector2i(max(1, int(world_box.size.x * f)), max(1, int(world_box.size.y * f)))
	var sv: SubViewport = world.get_viewport()
	sv.size = px
	world_svc.size = Vector2(px)
	world_svc.scale = Vector2.ONE / f
	world_svc.position = Vector2.ZERO
	var g := int(S.get("gfx", 2))
	sv.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][clamp(g, 0, 2)]
	sv.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED

# ---------------------------------------------------------------- Zustand
func now() -> float:
	return Time.get_unix_time_from_system()

func blank() -> Dictionary:
	return {cash=25.0, stock=0.0, lv=0, total=0.0, life=0.0, l={"c1": 1}, v={"v1": 1}, t={}, f={}, g={"g1": 2},
		rep=0, next=90.0, warn=0.0, gang=0, won=0, lost=0, log=[], ts=now(), mig1=1, orders=[], odone=0,
		mgr={}, auto={}, sites={}, shred=0, gold=0, zins=2, fx=[], gt=0.0, ev_next=240.0, ev_cur="", daily_day=0, streak=0,
		box_ts=0.0, ach={}, coins=[], fakes=0, gfx=2, rooms={}, staff={"arb": 1, "fahr": 1}, owed=0.0, payday=300.0, unpaid_until=0.0, paid_total=0.0, hunt_next=60.0, escort=0, museum=0, amb_next=300.0, comm_next=300.0, fire=0, fire_t=0.0, fire_next=480.0, fires=0, shift=1, up={}, raw=100.0, wx="sun", wx_t=240.0, esc_share=0, series=0, series_t=0.0, ezb=0, hack_next=600.0, ins_next=480.0, sick_next=420.0, wear_next=360.0, acc_next=540.0, azubi_t=240.0}

func load_game() -> void:
	S = blank()
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		var x = JSON.parse_string(f.get_as_text())
		if typeof(x) == TYPE_DICTIONARY:
			apply_state(x)
			# Falls die Datei nur ein frischer Start nach dem Update ist, alten Stand trotzdem holen
			if S.get("migrated", false):
				return
	var old := migrate_webview()
	if not old.is_empty():
		var life_new := float(S.get("life", 0.0))
		if float(old.get("life", 0.0)) > life_new:
			apply_state(old)
			S["ts"] = now()
			S["warn"] = 0.0
			S["migrated"] = true
			S["log"].push_front({t="Spielstand aus der alten App-Version übernommen.", c="good", time=Time.get_time_string_from_system().substr(0, 5)})
			save_game()
	S["migrated"] = true

## Liest den Spielstand der früheren HTML-App (WebView-Speicher im selben App-Ordner)
func migrate_webview() -> Dictionary:
	var base := OS.get_user_data_dir().get_base_dir()
	var files := []
	for root in [base + "/app_webview", base.get_base_dir() + "/app_webview", OS.get_user_data_dir() + "/../app_webview"]:
		collect_files(root, files, 0)
	var best := {}
	var best_life := -1.0
	for path in files:
		var fa := FileAccess.open(path, FileAccess.READ)
		if fa == null:
			continue
		var data := fa.get_buffer(fa.get_length())
		for cand in [data.get_string_from_ascii(), utf16_text(data)]:
			for js in extract_states(cand):
				var x = JSON.parse_string(js)
				if typeof(x) == TYPE_DICTIONARY and x.has("cash") and x.has("l"):
					var lf := float(x.get("life", 0.0))
					if lf >= best_life:
						best_life = lf
						best = x
	return best

func collect_files(dir: String, out: Array, depth: int) -> void:
	if depth > 6:
		return
	var d := DirAccess.open(dir)
	if d == null:
		return
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		if n != "." and n != "..":
			var full := dir + "/" + n
			if d.current_is_dir():
				collect_files(full, out, depth + 1)
			elif n.ends_with(".log") or n.ends_with(".ldb") or n.find("localstorage") >= 0:
				out.append(full)
		n = d.get_next()
	d.list_dir_end()

func utf16_text(data: PackedByteArray) -> String:
	# Chromium legt Texte mit Sonderzeichen als UTF-16 ab: jedes zweite Byte ist dann 0
	var out := PackedByteArray()
	var i := 0
	while i + 1 < data.size():
		if data[i + 1] == 0 and data[i] >= 32 and data[i] < 127:
			out.append(data[i])
			i += 2
		elif data[i + 1] == 0 and data[i] >= 128:
			out.append(63)
			i += 2
		else:
			out.append(10)
			i += 1
	return out.get_string_from_ascii()

func extract_states(txt: String) -> Array:
	var res := []
	var pos := txt.find("{\"cash\":")
	while pos >= 0:
		var depth := 0
		var in_str := false
		var esc := false
		var end := -1
		for i in range(pos, min(txt.length(), pos + 200000)):
			var ch := txt[i]
			if in_str:
				if esc:
					esc = false
				elif ch == "\\":
					esc = true
				elif ch == "\"":
					in_str = false
			else:
				if ch == "\"":
					in_str = true
				elif ch == "{":
					depth += 1
				elif ch == "}":
					depth -= 1
					if depth == 0:
						end = i
						break
		if end > pos:
			res.append(txt.substr(pos, end - pos + 1))
		pos = txt.find("{\"cash\":", pos + 8)
	return res

func apply_state(x: Dictionary) -> void:
	var b := blank()
	for k in x.keys():
		b[k] = x[k]
	for k in ["l", "v", "t", "f", "g", "mgr", "auto", "sites", "ach", "rooms", "staff", "up"]:
		if typeof(b[k]) != TYPE_DICTIONARY:
			b[k] = {}
	if typeof(b["log"]) != TYPE_ARRAY:
		b["log"] = []
	for k in ["orders", "fx", "coins"]:
		if typeof(b[k]) != TYPE_ARRAY:
			b[k] = []
	if not b.has("staff_need_v1"):
		# Umstellung „ohne Personal kein Verdienst“: vorhandene Spielstände bekommen einmalig genug Personal
		b["staff_need_v1"] = true
		var keep_s := S
		S = b
		if typeof(S["staff"]) != TYPE_DICTIONARY:
			S["staff"] = {}
		S["staff"]["arb"] = max(staff("arb"), need_arb())
		S["staff"]["fahr"] = max(staff("fahr"), need_fahr())
		S = keep_s
	if not b.has("fleet_auto_off"):
		b["auto"]["fleet"] = false
		b["fleet_auto_off"] = true
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

func has_d(o: String, id: String) -> bool:
	return bool(S[o].get(id, false))

func fx_m(k: String) -> float:
	var m := 1.0
	for f in S["fx"]:
		if f.k == k and f.until > S["gt"]:
			m *= f.m
	return m

func line_off(id: String) -> bool:
	for f in S["fx"]:
		if f.k == "line" and f.get("id", "") == id and f.until > S["gt"]:
			return true
	return false

func ach_n() -> int:
	return S["ach"].size()

func museum_m() -> float:
	return (1.0 + 0.05 * float(S["rep"])) * (1.0 + 0.05 * up("bus")) if int(S["museum"]) > 0 else 1.0

func up(id: String) -> int:
	return int(S["up"].get(id, 0))

func upg_cost(id: String) -> float:
	for u in UPG:
		if u.id == id:
			return u.c * pow(u.k, up(id))
	return 1e30

func lzb_n() -> int:
	var n := 0
	for i in LZB.size():
		if float(S["life"]) >= lzb_need(i):
			n += 1
	return n

func lzb_need(i: int) -> float:
	return 1e5 * pow(8.0, float(i))

func ezb_m() -> float:
	return 1.0 + 0.5 * int(S["ezb"])

func shift_i() -> int:
	return clamp(int(S["shift"]), 0, 2)

## Rohstoffe: Verbrauch bei laufender Produktion, Nachschub je nach Lieferverträgen (in % pro Sekunde)
func raw_supply() -> float:
	return [0.22, 0.3, 0.4, 0.55, 0.75][min(up("raw"), 4)]

func raw_use() -> float:
	return 0.3 * SHIFT_PROD[shift_i()]

func raw_m() -> float:
	if float(S["raw"]) > 0.5:
		return 1.0
	return min(1.0, raw_supply() / raw_use())

func is_winter() -> bool:
	var m: int = Time.get_date_dict_from_system().month
	return m == 11 or m == 12 or m == 1 or m == 2

func wx_m() -> float:
	var w: String = S["wx"]
	if w == "snow":
		return 0.75 + 0.08 * up("winter")
	return float(WX.get(w, ["", 1.0])[1])

func fx_active(k: String) -> bool:
	for f in S["fx"]:
		if f.k == k and f.until > S["gt"]:
			return true
	return false

func absent_frac() -> float:
	var a := 0.0
	for f in S["fx"]:
		if (f.k == "absent" or f.k == "acc") and f.until > S["gt"]:
			a += float(f.m)
	return min(0.6, a)

## Wirksames Personal nach Krankheit, Urlaub, Unfällen; Springer füllen Lücken
func eff_staff(id: String) -> float:
	var a := absent_frac()
	var arb: float = staff("arb") + 0.5 * staff("azubi")
	var spr: float = staff("spr")
	var miss_a: float = arb * a
	var use_a: float = min(spr, miss_a)
	if id == "arb":
		return arb - miss_a + use_a
	var fahr: float = staff("fahr")
	var miss_f: float = fahr * a
	return fahr - miss_f + min(spr - use_a, miss_f)

func need_tech() -> int:
	var m := machines_total()
	return 0 if m == 0 else int(ceil(sqrt(float(m)) / 3.0))

func cov_tech() -> float:
	var n := need_tech()
	return 1.0 if n == 0 else min(1.0, float(staff("tech")) / n)

func esc_cost() -> float:
	return deliv() * pay_m() * 0.05 * float(S["esc_share"]) / 100.0

func series_cost() -> float:
	return 2e8 * pow(25.0, float(S["series"]))

func glob_m() -> float:
	return (1.0 + 0.03 * int(S["gold"])) * (1.0 + 0.02 * ach_n()) * museum_m() * fx_m("prod") * cov_arb() * (1.0 + staff_prod_bonus()) * (1.0 + 0.04 * room("chef")) * SHIFT_PROD[shift_i()] * raw_m() * (1.0 + 0.02 * lzb_n()) * ezb_m()

func hall_m(note: bool) -> float:
	var m := 1.0
	if note and float(S.get("fire_t", 0.0)) > 0.0:
		return 0.0
	if note:
		m *= 1.0 + 0.3 * int(S["series"])
		m *= (1.5 if has_d("mgr", "note") else 1.0) * (2.0 if has_d("sites", "muenchen") else 1.0) * fx_m("note")
	else:
		m *= (1.5 if has_d("mgr", "coin") else 1.0) * (2.0 if has_d("sites", "mainz") else 1.0) * fx_m("coin")
	return m

func base_mul(l: Dictionary) -> float:
	var note: bool = l.get("note", false)
	return tm("note" if note else "coin") * tm("all") * rep_m() * (1.0 - cf_pct() / 100.0) * glob_m() * hall_m(note)

func line_rate(l: Dictionary) -> float:
	var c := cnt("l", l.id)
	if line_off(l.id):
		return 0.0
	return l.r * c * pow(2.0, ms_n(c)) * base_mul(l)

func room(id: String) -> int:
	return int(S["rooms"].get(id, 0))

func staff(id: String) -> int:
	return int(S["staff"].get(id, 0))

func staff_total() -> int:
	var n := 0
	for st in STAFF:
		n += staff(st.id)
	return n

func staff_cap(id: String) -> int:
	match id:
		"putz":
			return 3 * room("putz")
		"verw":
			return 2 + 4 * room("hr")
	return 10 + 20 * room("umk")

func total_cap() -> int:
	return 10 + 20 * room("umk")

func morale() -> float:
	var m := 55.0 + 8.0 * room("kantine") + 6.0 * room("pause") + 3.0 * up("park") + 4.0 * up("terr")
	if float(S["gt"]) < float(S["unpaid_until"]):
		m -= 40.0
	return clamp(m, 0.0, 100.0)

func morale_f() -> float:
	return 0.5 + morale() / 200.0

func machines_total() -> int:
	var n := 0
	for l in LINES:
		n += cnt("l", l.id)
	return n

func vans_total() -> int:
	var n := 0
	for v in VAN:
		n += cnt("v", v.id)
	return n

## Ohne Personal kein Verdienst: Maschinen brauchen Bedienpersonal, Fahrzeuge brauchen Fahrer
func need_arb() -> int:
	var m := machines_total()
	return 0 if m == 0 else int(ceil(sqrt(float(m)) * SHIFT_NEED[shift_i()]))

func need_fahr() -> int:
	var v := vans_total()
	return 0 if v == 0 else int(ceil(sqrt(float(v))))

func cov_arb() -> float:
	var n := need_arb()
	return 1.0 if n == 0 else min(1.0, eff_staff("arb") / n)

func cov_fahr() -> float:
	var n := need_fahr()
	return 1.0 if n == 0 else min(1.0, eff_staff("fahr") / n)

## Zusatzbonus (Zufriedenheit, Reinigung) – nur wenn genug Personal da ist
func staff_prod_bonus() -> float:
	return (0.3 * morale() / 100.0 + min(0.2, 0.02 * staff("putz"))) * cov_arb()

func staff_del_bonus() -> float:
	return 0.25 * morale() / 100.0 * cov_fahr()

## Lohnkosten pro Sekunde: ein Teil des Mehrertrags, den das Personal bringt
func wage_rate() -> float:
	if staff_total() == 0:
		return 0.0
	var base_w: float = income() * 0.1 + staff_total() * 0.05
	var cut: float = min(0.4, 0.02 * staff("verw")) + 0.05 * room("buch")
	return base_w * max(0.3, 1.0 - cut) * SHIFT_WAGE[shift_i()]

func zins() -> int:
	return int(S["zins"])

func pay_m() -> float:
	return (1.1 - 0.04 * zins()) * (1.0 + 0.05 * int(S["shred"]))

func order_m() -> float:
	return (1.4 - 0.1 * zins()) * (1.5 if has_d("sites", "hamburg") else 1.0) * (1.0 + min(0.6, 0.03 * staff("verw"))) * (1.0 + 0.02 * room("lobby"))

func day_phase() -> float:
	return fposmod(float(S["gt"]) / DAY_LEN, 1.0)

func is_night() -> bool:
	return day_phase() > 0.62

var _pf := -1
var _pv := 0.0
var _df := -1
var _dv := 0.0
func prod() -> float:
	var fr := Engine.get_process_frames()
	if fr == _pf:
		return _pv
	_pf = fr
	_pv = prod_calc()
	return _pv

func deliv() -> float:
	var fr := Engine.get_process_frames()
	if fr == _df:
		return _dv
	_df = fr
	_dv = deliv_calc()
	return _dv

func invalidate() -> void:
	_pf = -1
	_df = -1

func prod_calc() -> float:
	var s := 0.0
	for l in LINES:
		s += line_rate(l)
	return s

func del_m() -> float:
	return tm("del") * rep_m() * (2.0 if has_d("sites", "leipzig") else 1.0) * (1.5 if has_d("mgr", "fleet") else 1.0) * fx_m("del") * cov_fahr() * (1.0 + staff_del_bonus()) * wx_m() * ezb_m()

func deliv_calc() -> float:
	var s := 0.0
	for v in VAN:
		s += v.r * cnt("v", v.id)
	return s * del_m()

func cap() -> float:
	return 300.0 * pow(3.0, int(S["lv"]))

func cap_cost() -> float:
	return 150.0 * pow(4.0, int(S["lv"]))

func income() -> float:
	return min(prod(), deliv()) * pay_m()

func defense() -> float:
	var s := 0.0
	for g in GUARD:
		s += g.v * cnt("g", g.id)
	return s * (1.25 if has_d("mgr", "sec") else 1.0) * (1.0 + min(1.0, 0.04 * staff("wach"))) * (1.0 + 0.1 * room("leit"))

func threat(m := 1.0) -> float:
	return m * (8.0 + 4.0 * pow(income(), 0.8)) * (1.0 + 0.02 * int(S["gold"])) * (1.3 - 0.1 * zins()) * (1.25 if is_night() else 1.0)

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

func gen_order(easy := false) -> Dictionary:
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
	var reqs := []
	var cm := hall_machines(false)
	var nm := hall_machines(true)
	var kind := "coin"
	if nm > 0 and randf() < 0.5:
		kind = "note"
	if kind == "coin":
		reqs.append({t="coin", n=max(1, int(round(cm * ((0.5 + randf() * 0.4) if easy else (0.8 + randf() * 0.5)))))})
		if randf() < 0.4:
			var lines_built := 0
			for l in LINES:
				if not l.get("note", false) and cnt("l", l.id) > 0:
					lines_built += 1
			reqs.append({t="clines", n=min(5, lines_built + (0 if easy else (1 if randf() < 0.5 else 0)))})
	else:
		reqs.append({t="note", n=max(1, int(round(nm * ((0.5 + randf() * 0.4) if easy else (0.8 + randf() * 0.5)))))})
		reqs.append({t="feat", n=min(FEAT.size(), feat_n() if easy else max(2, feat_n() + (1 if randf() < 0.4 else 0)))})
	if c.get("far", false) and not (easy and cnt("v", "v6") == 0 and not has_d("sites", "hamburg")):
		reqs.append({t="far"})
	elif easy and c.get("far", false):
		c = COUNTRIES[0]
	if randf() < 0.5:
		reqs.append({t="def", n=max(5, round_nice(defense() * ((0.4 + randf() * 0.4) if easy else (0.7 + randf() * 0.6))))})
	var bonus := 1.0 + 0.25 * reqs.size()
	return {land=c.n, cur=c.cur, fx=c.fx, flag=c.flag, need=need, done=0.0, reward=need * (2.2 + randf() * 1.3) * order_m() * bonus, active=false, wait=0.0, dur=dur, kind=kind, reqs=reqs}

func any_ok_offer() -> bool:
	for o in S["orders"]:
		if o.get("land", "") != "" and not o.get("active", false) and o.get("wait", 0.0) <= 0.0 and order_ok(o):
			return true
	return false

func hall_machines(note: bool) -> int:
	var n := 0
	for l in LINES:
		if bool(l.get("note", false)) == note:
			n += cnt("l", l.id)
	return n

func round_nice(v: float) -> int:
	if v < 100.0:
		return int(round(v / 5.0) * 5.0)
	var p := pow(10.0, floor(log(v) / log(10.0)) - 1.0)
	return int(round(v / p) * p)

## Liefert für jede Voraussetzung [Text, erfüllt]
func req_status(o: Dictionary) -> Array:
	var out := []
	for r in o.get("reqs", []):
		match r.t:
			"coin":
				out.append(["%d Pressen in der Münzhalle (du hast %d)" % [r.n, hall_machines(false)], hall_machines(false) >= r.n])
			"note":
				out.append(["%d Druckmaschinen in der Druckhalle (du hast %d)" % [r.n, hall_machines(true)], hall_machines(true) >= r.n])
			"clines":
				var b := 0
				for l in LINES:
					if not l.get("note", false) and cnt("l", l.id) > 0:
						b += 1
				out.append(["%d verschiedene Münzlinien (du hast %d)" % [r.n, b], b >= r.n])
			"feat":
				out.append(["%d Sicherheitsmerkmale (du hast %d)" % [r.n, feat_n()], feat_n() >= r.n])
			"far":
				var ok := cnt("v", "v6") > 0 or has_d("sites", "hamburg")
				out.append(["Übersee: Frachtflugzeug oder Hafen Hamburg", ok])
			"def":
				out.append(["Schutz mindestens %s (du hast %s)" % [num(r.n), num(defense())], defense() >= r.n])
			"e2":
				out.append(["2-Euro-Linie gebaut", cnt("l", "e2") > 0])
	return out

func order_ok(o: Dictionary) -> bool:
	for st in req_status(o):
		if not st[1]:
			return false
	return true

func orders_tick(dt: float) -> void:
	var o_arr: Array = S["orders"]
	while o_arr.size() < 3:
		o_arr.append(gen_order(not any_ok_offer()))
	var p := prod()
	for i in range(o_arr.size()):
		var o: Dictionary = o_arr[i]
		if o.get("special", false) and not o.get("active", false) and S["gt"] > o.get("deadline", 1e18):
			o_arr[i] = {wait=20.0, land="", active=false}
			continue
		if o.get("wait", 0.0) > 0.0:
			o["wait"] -= dt
			if o["wait"] <= 0.0:
				o_arr[i] = gen_order(not any_ok_offer())
				if view == "orders":
					render()
			continue
		if o.get("active", false):
			o["done"] += p * ORDER_SHARE * dt
			if o.get("special", false) and S["gt"] > o.get("deadline", 1e18) and o["done"] < o["need"]:
				add_log("Gedenkmünze %s verpasst – die Frist ist abgelaufen." % o.name, "bad")
				o_arr[i] = {wait=20.0, land="", active=false}
				world.dirty = true
				continue
			if o["done"] >= o["need"]:
				earn(o["reward"])
				S["odone"] = int(S.get("odone", 0)) + 1
				if o.get("special", false):
					S["coins"].append(o.name)
					add_log("Gedenkmünze %s geprägt! Sie steht jetzt in der Sammelvitrine." % o.name, "good")
				add_log("Auftrag %s erledigt: %s %s geliefert, Lohn %s." % [o.land, num_cur(o.need * o.fx), o.cur, fmt(o.reward)], "good")
				o_arr[i] = {wait=20.0, land="", active=false}
				world.dirty = true
				if view == "orders":
					render()

func num_cur(v: float) -> String:
	return fmt(v).replace(" €", "")

func accept_order(i: int) -> void:
	var o: Dictionary = S["orders"][i]
	if o.get("wait", 0.0) > 0.0 or o.get("active", false) or not order_ok(o):
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

func gen_commem() -> Dictionary:
	var left := []
	for n in COMMEMS:
		if not S["coins"].has(n):
			left.append(n)
	if left.is_empty():
		left = COMMEMS.duplicate()
	var nm: String = left[randi() % left.size()]
	var base: float = max(prod(), 0.35)
	var need := base * ORDER_SHARE * (120.0 + randf() * 120.0)
	var creqs := [{t="e2"}, {t="coin", n=max(10, int(hall_machines(false) * 0.8))}]
	return {reqs=creqs, kind="coin", land="Sonderprägung", name=nm, cur="Stück", fx=0.5, flag=["#ffc23d", "#c9cfd2", "#ffc23d"], need=need, done=0.0, reward=need * 4.0 * order_m(), active=false, wait=0.0, special=true, deadline=S["gt"] + 600.0}

func step(dt: float) -> void:
	orders_tick(dt)
	S["stock"] = min(cap(), float(S["stock"]) + prod() * (1.0 - ORDER_SHARE * active_orders()) * dt)
	var d: float = min(float(S["stock"]), deliv() * dt)
	S["stock"] -= d
	earn(d * pay_m())

func offline_catchup() -> void:
	# Offline-Einnahmen sind abgeschaltet: Geld gibt es nur, solange das Spiel läuft
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
	S["next"] -= dt * (1.5 if is_night() else 1.0)
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
	cleanup_old_apk()
	var base := ThemeDB.fallback_font
	bold_font = FontVariation.new()
	bold_font.base_font = base
	bold_font.variation_embolden = 0.9
	load_game()
	if not S.has("gfx_v3"):
		S["gfx"] = 2
		S["gfx_v3"] = 1
	if not S.has("mig1"):
		S["g"]["g1"] = max(cnt("g", "g1"), 2)
		S["mig1"] = 1
	if OS.has_environment("BB_VIEW"):
		view = OS.get_environment("BB_VIEW")
	build_ui()
	call_deferred("update_world_res")
	offline_catchup()
	render()
	http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_update_response)
	check_update(false)
	if OS.has_environment("BB_TEST"):
		get_tree().create_timer(3.0).timeout.connect(Callable(self, OS.get_environment("BB_TEST")))

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if not S.is_empty():
			save_game()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		if not S.is_empty():
			offline_catchup()

var touch_active := false
var drag_dist := 0.0
var drag_scrolled := false
var fling := 0.0
var scroll_pos := 0.0

func _clear_hold() -> void:
	hold_fired = false

func _input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and not ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		hold_active = false
		call_deferred("_clear_hold")
	if scroll == null:
		return
	if ev is InputEventScreenTouch and ev.index == 0:
		if ev.pressed:
			touch_active = scroll.get_global_rect().has_point(ev.position) and not dlg_root.visible
			drag_dist = 0.0
			drag_scrolled = false
			fling = 0.0
			scroll_pos = scroll.scroll_vertical
		else:
			touch_active = false
			hold_active = false
			call_deferred("_clear_hold")
	elif ev is InputEventScreenDrag and ev.index == 0 and touch_active:
		drag_dist += abs(ev.relative.y) + abs(ev.relative.x) * 0.5
		if drag_dist > 14.0:
			drag_scrolled = true
		if drag_scrolled:
			scroll_pos = clamp(scroll_pos - ev.relative.y, 0.0, max_scroll())
			scroll.scroll_vertical = int(scroll_pos)
			fling = -ev.velocity.y
	elif ev is InputEventMouseButton and ev.pressed and scroll.get_global_rect().has_point(ev.position):
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll.scroll_vertical -= 90
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll.scroll_vertical += 90

func max_scroll() -> float:
	return max(0.0, scroll.get_v_scroll_bar().max_value - scroll.size.y)

func fling_tick(dt: float) -> void:
	if touch_active or abs(fling) < 20.0:
		fling = 0.0 if not touch_active else fling
		return
	scroll_pos = clamp(float(scroll.scroll_vertical) + fling * dt, 0.0, max_scroll())
	scroll.scroll_vertical = int(scroll_pos)
	fling *= pow(0.04, dt)
	if scroll_pos <= 0.0 or scroll_pos >= max_scroll():
		fling = 0.0

func test_count() -> void:
	var counts := {}
	for n in world.find_children("*", "MeshInstance3D", true, false):
		var par: Node = n.get_parent()
		var key: String = par.name if par != world else "world"
		if par.get_parent() == world.dyn or par == world.dyn:
			key = "dyn/" + (par.name if par != world.dyn else "")
		counts[key] = counts.get(key, 0) + 1
	var arr := []
	for k in counts.keys():
		arr.append([counts[k], k])
	arr.sort()
	arr.reverse()
	print("COUNT ", arr.slice(0, 12))

func test_betr() -> void:
	zsub = "betr"
	render()
	scroll.scroll_vertical = int(OS.get_environment("BB_SCROLL")) if OS.has_environment("BB_SCROLL") else 0

func test_lead() -> void:
	zsub = "mehr"
	render()
	call_deferred("_scroll_end")

func _scroll_end() -> void:
	scroll.scroll_vertical = 100000

func test_pers() -> void:
	zsub = "pers"
	render()

func test_zoom() -> void:
	world.zoom = float(OS.get_environment("BB_Z")) if OS.has_environment("BB_Z") else 3.2
	world.tx = float(OS.get_environment("BB_TX")) if OS.has_environment("BB_TX") else -6.0
	world.tz = float(OS.get_environment("BB_TZ")) if OS.has_environment("BB_TZ") else -6.5
	toggle_world()

func test_scroll() -> void:
	var a := InputEventScreenTouch.new()
	a.index = 0
	a.pressed = true
	a.position = Vector2(360, 1200)
	Input.parse_input_event(a)
	for i in range(10):
		var d := InputEventScreenDrag.new()
		d.index = 0
		d.position = Vector2(360, 1200 - i * 40)
		d.relative = Vector2(0, -40)
		d.velocity = Vector2(0, -1500)
		Input.parse_input_event(d)
	var r := InputEventScreenTouch.new()
	r.index = 0
	r.pressed = false
	r.position = Vector2(360, 800)
	Input.parse_input_event(r)

var last_scroll := 0
var scroll_quiet := 0.0
var wframe := 0
func world_render_tick(dt: float) -> void:
	var sv: SubViewport = world.get_viewport()
	if scroll.scroll_vertical != last_scroll:
		last_scroll = scroll.scroll_vertical
		scroll_quiet = 0.0
	else:
		scroll_quiet += dt
	wframe += 1
	if scroll_quiet < 0.35:
		sv.render_target_update_mode = SubViewport.UPDATE_DISABLED
	elif int(S.get("gfx", 2)) >= 1 or wframe % 2 == 0:
		sv.render_target_update_mode = SubViewport.UPDATE_ONCE
	else:
		sv.render_target_update_mode = SubViewport.UPDATE_DISABLED

func _process(dt: float) -> void:
	dt = min(dt, 1.0)
	fling_tick(dt)
	hold_tick(dt)
	world_render_tick(dt)
	download_tick()
	S["gt"] = float(S["gt"]) + dt
	step(dt)
	raid_tick(dt)
	extras_tick(dt)
	ui_t += dt
	if ui_t > 0.25:
		ui_t = 0.0
		update_ui()
	if OS.has_environment("BB_PERF") and Engine.get_process_frames() % 120 == 0:
		print("PROC_MS %.2f" % (Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0))
	if OS.has_environment("BB_PERF") and shot_t > 5.0 and Engine.get_process_frames() % 5 == 0:
		var vrid: RID = world.get_viewport().get_viewport_rid()
		print("PERF world_draws=%d world_objs=%d nodes=%d" % [RenderingServer.viewport_get_render_info(vrid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE, RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME), RenderingServer.viewport_get_render_info(vrid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE, RenderingServer.VIEWPORT_RENDER_INFO_OBJECTS_IN_FRAME), Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
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

func btn(t: String, cb: Callable, kind := "main", minw := 190, rep := false) -> Button:
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
	b.pressed.connect(func():
		if not drag_scrolled and not hold_fired:
			cb.call())
	if rep:
		b.button_down.connect(func():
			hold_cb = cb
			hold_active = true
			hold_fired = false
			hold_t = 0.45
			hold_n = 0)
	return b

## Gedrückt halten: wiederholt kaufen, immer schneller, bis das Geld nicht mehr reicht
var hold_cb: Callable
var hold_active := false
var hold_fired := false
var hold_t := 0.0
var hold_n := 0

func hold_tick(dt: float) -> void:
	if not hold_active:
		return
	if drag_scrolled:
		hold_active = false
		return
	hold_t -= dt
	if hold_t > 0.0:
		return
	var c0: float = float(S["cash"])
	if hold_cb.is_valid():
		hold_cb.call()
	hold_fired = true
	hold_n += 1
	if is_equal_approx(float(S["cash"]), c0):
		hold_active = false
		return
	hold_t = max(0.03, 0.16 - hold_n * 0.012)

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
	l_inc.clip_text = true
	l_inc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l_inc.custom_minimum_size = Vector2(10, 0)
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
	world_svc = SubViewportContainer.new()
	var svc := world_svc
	svc.stretch = false
	world_box.add_child(svc)
	var sv := SubViewport.new()
	sv.msaa_3d = Viewport.MSAA_2X
	sv.name = "WorldViewport"
	svc.add_child(sv)
	world_box.resized.connect(update_world_res)
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
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	for it in [["werk", "Werk"], ["orders", "Aufträge"], ["deliv", "Fuhrpark"], ["tech", "Technik"], ["guard", "Schutz"], ["zentrale", "Zentrale"], ["bank", "Bank"]]:
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
	var upd_root := overlay(update_panel)
	upd_root.name = "UpdRoot"
	var uv := vb(18)
	update_panel.add_child(uv)
	uv.add_child(lbl("Update verfügbar", 36, C_GOLD, true))
	l_update = lbl("", 26, C_INK, false, true)
	uv.add_child(l_update)
	var uh := hb()
	uv.add_child(uh)
	upd_bar = pbar(16)
	upd_bar.visible = false
	uv.add_child(upd_bar)
	var later := btn("Später", func(): get_node("UpdRoot").visible = false, "light", 200)
	upd_btn = btn("Herunterladen", func(): start_download(), "main", 300)
	uh.add_child(later)
	uh.add_child(upd_btn)
	upd_browser = btn("Im Browser laden", func(): OS.shell_open(APK_URL), "light", 0)
	upd_browser.visible = false
	uv.add_child(upd_browser)
	build_dialog()

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
	scroll_pos = 0.0
	fling = 0.0

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
		"zentrale":
			render_zentrale()
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
			if tsub == "feat":
				for x in FEAT:
					out.append({k="f:" + x.id, n=x.n, d="%s · Falschgeld −%d %%" % [x.d, x.red], done=has_flag("f", x.id), price=x.c})
			else:
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
	if view == "tech":
		var seg := PanelContainer.new()
		seg.add_theme_stylebox_override("panel", sbox(C_CARD, 20, C_LINE, 2, 6))
		content.add_child(seg)
		var sh := hb(6)
		seg.add_child(sh)
		for it in [["tech", "Technik"], ["feat", "Sicherheitsmerkmale %d/%d" % [feat_n(), FEAT.size()]]]:
			var key: String = it[0]
			var on := tsub == key
			var b := btn(it[1], func():
				tsub = key
				render(), "main" if on else "light", 0)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if not on:
				b.add_theme_stylebox_override("normal", sbox(Color(0, 0, 0, 0), 16, Color(0, 0, 0, 0), 0, 6))
			sh.add_child(b)
		var hk := "feat" if tsub == "feat" else "tech"
		content.add_child(lbl(HEAD[hk][1], 24, C_MUT, false, true))
	else:
		head_title(HEAD[view][0], HEAD[view][1])
	if view == "deliv":
		if has_d("mgr", "fleet"):
			var fa: bool = S["auto"].get("fleet", false)
			extra_card("Automatischer Fahrzeugkauf", "Der Fuhrparkchef kauft selbstständig Fahrzeuge nach." if fa else "Aus – Fahrzeuge kaufst du nur selbst.", "auto:fleet", "An – ausschalten" if fa else "Aus – einschalten", true)
		var el := int(S["escort"])
		extra_card("Begleitschutz Stufe %d/6" % el, "Polizei begleitet die Geldtransporter. Senkt die Gefahr von Überfällen unterwegs.", "escort", "Voll" if el >= 6 else fmt(escort_cost()), S["cash"] >= escort_cost(), el >= 6)
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
		fire_card()
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
		var b := btn("", func(): buy(key), "main", 220, true)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(b)
		refs[key] = {btn=b, desc=desc, title=t, panel=p}
		# Fahrzeug-Upgrade zum nächsthöheren Typ
		if view == "deliv":
			var vi := van_index(key.split(":")[1])
			if vi >= 0 and vi < VAN.size() - 1:
				var urow := hb(14)
				var outer := vb(8)
				p.remove_child(row)
				p.add_child(outer)
				outer.add_child(row)
				outer.add_child(urow)
				var ud := lbl("", 23, C_MUT, false, true)
				urow.add_child(ud)
				var idx := vi
				var ub := btn("", func(): upgrade_van(idx), "teal", 220)
				ub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				urow.add_child(ub)
				refs["up:" + key] = {btn=ub, desc=ud, i=vi}

func render_orders() -> void:
	head_title("Aufträge", "Länder außerhalb der EU bestellen Münzen und Scheine. Annehmen kannst du nur, wenn dein Werk die Voraussetzungen erfüllt. Jeder laufende Auftrag nutzt 20 % deiner Herstellung; je mehr Voraussetzungen, desto höher der Lohn.")
	var hp := card()
	var hr := hb(14)
	hp.add_child(hr)
	var hl := vb(4)
	hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hr.add_child(hl)
	hl.add_child(lbl("Falschgeld-Jagd", 28, C_INK, true))
	var hd := lbl("", 23, C_MUT, false, true)
	hl.add_child(hd)
	var hb2 := btn("Starten", func(): start_hunt(), "main", 200)
	hb2.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hr.add_child(hb2)
	refs["hunt"] = {btn=hb2, desc=hd}
	while S["orders"].size() < 3:
		S["orders"].append(gen_order(not any_ok_offer()))
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
		var t := lbl(o.get("name", o.land) if o.get("special", false) else o.land, 30, C_GOLD if o.get("special", false) else C_INK, true, true)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(t)
		top.add_child(lbl("Lohn " + fmt(o.reward), 26, C_GOLD, true))
		if o.get("special", false):
			v.add_child(lbl("Sonderprägung für die Sammelvitrine · Lohn ×4 · begrenzte Zeit", 25, C_INK, false, true))
		else:
			v.add_child(lbl("%s %s in %s herstellen" % [num_cur(o.need * o.fx), o.cur, "Banknoten" if o.get("kind", "coin") == "note" else "Münzen"], 25, C_INK, false, true))
		var req_lbls := []
		if not o.get("active", false) and o.get("reqs", []).size() > 0:
			v.add_child(lbl("Voraussetzungen:", 23, C_MUT, true))
			for st in req_status(o):
				var rl := lbl("", 23, C_GREEN, false, true)
				v.add_child(rl)
				req_lbls.append(rl)
		var bar := pbar(12)
		v.add_child(bar)
		var row := hb(12)
		v.add_child(row)
		var info := lbl("", 23, C_MUT, false, true)
		row.add_child(info)
		var acc: Button = null
		if o.get("active", false):
			row.add_child(lbl("läuft", 26, C_GREEN, true))
		else:
			row.add_child(btn("Ablehnen", func(): decline_order(idx), "light", 170))
			acc = btn("Annehmen", func(): accept_order(idx), "main", 190)
			row.add_child(acc)
		refs["o%d" % i] = {bar=bar, info=info, acc=acc, reqs=req_lbls}
	content.add_child(lbl("Bis zu 3 Aufträge werden angeboten. Ist einer erledigt, kommt nach kurzer Zeit ein neuer. Erledigt bisher: %d" % int(S.get("odone", 0)), 22, C_MUT, false, true))

func render_bank() -> void:
	head_title("Bank", "Belohnungen, Erfolge, Reform, Spielstand und Lagebericht.")
	var rp := card()
	var rv := vb(10)
	rp.add_child(rv)
	rv.add_child(lbl("Belohnungen", 29, C_INK, true))
	var r1 := hb(12)
	rv.add_child(r1)
	var dl := lbl("Tägliche Belohnung · Tag %d in Folge" % max(1, int(S["streak"]) + (1 if daily_ready() else 0)), 23, C_MUT, false, true)
	r1.add_child(dl)
	var db := btn("Abholen" if daily_ready() else "Morgen wieder", func(): claim_daily(), "main", 230)
	db.disabled = not daily_ready()
	r1.add_child(db)
	var r2b := hb(12)
	rv.add_child(r2b)
	var bl := lbl("", 23, C_MUT, false, true)
	r2b.add_child(bl)
	var bb := btn("Glückskiste öffnen", func(): open_box(), "main", 230)
	r2b.add_child(bb)
	refs["box"] = {btn=bb, desc=bl}
	var ap := card()
	var av := vb(6)
	ap.add_child(av)
	av.add_child(lbl("Erfolge %d/%d · +%d %% Herstellung" % [ach_n(), ACH.size(), ach_n() * 2], 29, C_INK, true))
	for a in ACH:
		var got: bool = S["ach"].has(a.id)
		av.add_child(lbl(("★ " if got else "☆ ") + a.n + " – " + a.d, 23, C_GOLD if got else C_MUT, got, true))
	var cp := card()
	var cv2 := vb(6)
	cp.add_child(cv2)
	cv2.add_child(lbl("Sammelvitrine: Gedenkmünzen %d" % S["coins"].size(), 29, C_INK, true))
	cv2.add_child(lbl(" · ".join(PackedStringArray(S["coins"])) if S["coins"].size() > 0 else "Noch leer. Sonderaufträge für Gedenkmünzen erscheinen bei den Aufträgen.", 23, C_GOLD if S["coins"].size() > 0 else C_MUT, false, true))
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

	var pg := card()
	var rg := hb(14)
	pg.add_child(rg)
	var lg := vb(2)
	lg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rg.add_child(lg)
	lg.add_child(lbl("Grafik", 29, C_INK, true))
	lg.add_child(lbl("Ultra: volle Bildschirmschärfe, 4-fache Kantenglättung, feine Schatten. Hoch: etwas weniger scharf, schneller. Sparsam: für ältere Handys.", 23, C_MUT, false, true))
	rg.add_child(btn(GFX_NAMES[clamp(int(S["gfx"]), 0, 2)], func():
		S["gfx"] = (int(S["gfx"]) + 2) % 3
		world.apply_quality()
		update_world_res()
		save_game()
		render(), "light", 200))

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
	var keep := {rep=int(S["rep"]) + g, life=S["life"], won=S["won"], lost=S["lost"], log=S["log"], ezb=int(S["ezb"]), staff_need_v1=true, fleet_auto_off=true}
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
	invalidate()
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
	l_inc.text = ("+%s/s · Löhne −%s/s" % [fmt(income()), fmt(wage_rate())]) if wage_rate() > 0.0 else "+%s pro Sekunde" % fmt(income())
	l_prod.text = fmt(p) + "/s"
	l_del.text = fmt(d) + "/s"
	l_stock.text = fmt(S["stock"])
	l_stockp.text = "Tresorlager %d %%" % int(sp)
	bar_stock.value = sp
	var hint := ""
	if S["warn"] <= 0.0:
		if cov_arb() < 1.0 or cov_fahr() < 1.0:
			hint = "Zu wenig Personal: %s einstellen (Zentrale → Personal)!" % ("Produktionsmitarbeiter und Fahrer" if cov_arb() < 1.0 and cov_fahr() < 1.0 else ("Produktionsmitarbeiter" if cov_arb() < 1.0 else "Fahrer"))
		elif sp > 95.0 and p > d:
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
	nav_btns["bank"].text = "Bank •" if (daily_ready() or box_wait() <= 0.0) else "Bank"

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
	update_extras()
	if view == "zentrale":
		update_staff_ui()
		update_betrieb_ui()
	if view == "bank":
		if refs.has("box"):
			var w := box_wait()
			refs["box"].btn.disabled = w > 0.0
			refs["box"].desc.text = "Glückskiste bereit!" if w <= 0.0 else "Glückskiste in %s" % dur_txt(w)
		return
	if view == "orders":
		if refs.has("hunt"):
			var hr2: Dictionary = refs["hunt"]
			hr2.btn.disabled = not hunt_ready()
			hr2.desc.text = ("Erkenne die gefälschte Banknote · %d bisher erkannt" % int(S["fakes"])) if hunt_ready() else "Nächste Runde in %s" % dur_txt(float(S["hunt_next"]) - float(S["gt"]))
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
			if r.acc != null:
				var st_list := req_status(o)
				for q in range(min(st_list.size(), r.reqs.size())):
					r.reqs[q].text = ("✓ " if st_list[q][1] else "✗ ") + st_list[q][0]
					r.reqs[q].add_theme_color_override("font_color", C_GREEN if st_list[q][1] else C_RED)
				r.acc.disabled = not order_ok(o)
			var rest: float = (o.need - o.done) / max(0.001, p2 * ORDER_SHARE)
			var frist := ""
			if o.get("special", false):
				frist = " · Frist %s" % dur_txt(max(0.0, o.deadline - S["gt"]))
			if o.get("active", false):
				r.info.text = "%d %% fertig · noch ca. %s%s" % [int(o.done / o.need * 100.0), dur_txt(rest), frist]
			else:
				r.info.text = "Dauer ca. %s bei deiner Herstellung%s" % [dur_txt(rest), frist]
		return
	if view == "guard" and refs.has("risk"):
		var r: Dictionary = refs["risk"]
		r.rate.text = "%d %%" % int(round(rk))
		r.bar.value = rk
		var nxt := "Überfall läuft!" if S["warn"] > 0.0 else "nächste Bedrohung in ca. %d s" % int(ceil(S["next"]))
		r.desc.text = "Schutz %s gegen Bedrohung %s · %s · abgewehrt %d, verloren %d" % [num(defense()), num(threat()), nxt, int(S["won"]), int(S["lost"])]
	if view == "deliv":
		for key in refs.keys():
			if not key.begins_with("up:"):
				continue
			var ur: Dictionary = refs[key]
			var i: int = ur.i
			var cur: Dictionary = VAN[i]
			var nxt: Dictionary = VAN[i + 1]
			var plan := up_plan(i)
			var gain: float = (nxt.r - cur.r) * del_m()
			if int(plan[0]) <= 0:
				ur.desc.text = "Upgrade zu %s: kein %s vorhanden" % [nxt.n, cur.n]
				ur.btn.text = "Upgrade"
				ur.btn.disabled = true
			else:
				ur.desc.text = "Upgrade zu %s · +%s/s je Fahrzeug · 30 %% günstiger als neu" % [nxt.n, fmt(gain)]
				ur.btn.text = ("↑ %d× " % plan[0] if int(plan[0]) > 1 else "↑ ") + fmt(plan[1])
				ur.btn.disabled = float(S["cash"]) < float(plan[1])
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
		l_update.text = "Version %s ist da. Tippe auf „Herunterladen“ – die neue Version wird im Browser geladen. Danach die Datei öffnen und „Aktualisieren“ tippen. Dein Spielstand bleibt erhalten." % tag
		upd_btn.text = "Herunterladen"
		upd_btn.disabled = false
		upd_bar.visible = false
		get_node("UpdRoot").visible = true
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

# ================================================================ Zusatzsysteme
var extra_t := 0.0
var dlg: PanelContainer
var dlg_box: VBoxContainer
var tsub := "tech"

func extras_tick(dt: float) -> void:
	var gt: float = S["gt"]
	# abgelaufene Effekte entfernen
	var keep := []
	for f in S["fx"]:
		if f.until > gt:
			keep.append(f)
	S["fx"] = keep
	# Löhne und Zahltag
	S["owed"] = float(S["owed"]) + wage_rate() * dt
	S["payday"] = float(S["payday"]) - dt
	if S["payday"] <= 0.0:
		S["payday"] = PAY_PERIOD
		var owed: float = S["owed"]
		if owed > 0.0:
			if float(S["cash"]) >= owed:
				S["cash"] -= owed
				S["paid_total"] = float(S["paid_total"]) + owed
				add_log("Zahltag: %s Löhne an %d Mitarbeiter gezahlt." % [fmt(owed), staff_total()], "good")
			else:
				S["paid_total"] = float(S["paid_total"]) + float(S["cash"])
				S["cash"] = 0.0
				S["unpaid_until"] = gt + 300.0
				add_log("Zahltag: Löhne konnten nicht voll gezahlt werden! Die Belegschaft ist 5 Minuten unzufrieden.", "bad")
		S["owed"] = 0.0
	fire_tick(dt)
	ops_tick(dt)
	# Ereignisse
	if S["ev_cur"] == "" and S["warn"] <= 0.0:
		S["ev_next"] = float(S["ev_next"]) - dt
		if S["ev_next"] <= 0.0 and income() > 0.5:
			S["ev_next"] = 180.0 + randf() * 240.0
			var ev: Dictionary = EVENTS[randi() % EVENTS.size()]
			if ev.id == "break" and randf() < min(0.8, 0.1 * staff("putz")):
				ev = EVENTS[5]
			if morale() < 50.0 and randf() < 0.4:
				ev = EVENTS[0]
			if ev.id == "power" and up("power") > 0:
				var pm: float = [0.0, 0.5, 0.85, 1.0][up("power")]
				if pm < 1.0:
					S["fx"].append({k="prod", m=pm, until=float(S["gt"]) + 60.0})
				add_log("Stromausfall! Das Notstromaggregat springt an – Produktion läuft mit %d %%." % int(pm * 100), "good")
				world.dirty = true
			elif ev.id == "break" and staff("tech") > 0:
				machine_break(true)
			else:
				S["ev_cur"] = ev.id
				show_event(ev)
	# Gedenkmünzen
	S["comm_next"] = float(S["comm_next"]) - dt
	if S["comm_next"] <= 0.0 and prod() > 1.0:
		S["comm_next"] = 600.0 + randf() * 300.0
		var has_special := false
		for o in S["orders"]:
			if o.get("special", false):
				has_special = true
		if not has_special:
			for i in range(S["orders"].size()):
				var o: Dictionary = S["orders"][i]
				if not o.get("active", false):
					S["orders"][i] = gen_commem()
					add_log("Sonderauftrag: Gedenkmünze %s – 10 Minuten Zeit!" % S["orders"][i].name, "good")
					if view == "orders":
						render()
					break
	# Überfall auf Geldtransport
	S["amb_next"] = float(S["amb_next"]) - dt
	if S["amb_next"] <= 0.0:
		S["amb_next"] = 200.0 + randf() * 220.0
		if income() > 1.0:
			var chance := 0.6 / (1.0 + int(S["escort"])) * (1.0 - 0.8 * float(S["esc_share"]) / 100.0)
			if randf() < chance:
				var loss: float = min(float(S["cash"]) * 0.12, income() * 45.0)
				S["cash"] -= loss
				add_log("Ein Geldtransport wurde unterwegs überfallen! Verlust: %s. Begleitschutz im Fuhrpark hilft." % fmt(loss), "bad")
			else:
				var rew := income() * 10.0
				earn(rew)
				add_log("Überfall auf einen Geldtransport vereitelt! Prämie: %s." % fmt(rew), "good")
	# alle 2 s: Werksleiter und Erfolge
	extra_t += dt
	if extra_t >= 2.0:
		extra_t = 0.0
		managers_tick()
		check_ach()

func managers_tick() -> void:
	var bought := false
	for hall_note in [false, true]:
		var mid := "note" if hall_note else "coin"
		if not (has_d("mgr", mid) and S["auto"].get(mid, true)):
			continue
		var best := {}
		var best_c := 1e30
		for l in LINES:
			if bool(l.get("note", false)) != hall_note:
				continue
			var c := cnt("l", l.id)
			if c == 0:
				continue
			var pr := cost_n(l.b, c, 1)
			if pr < best_c:
				best_c = pr
				best = l
		if not best.is_empty() and best_c < float(S["cash"]) * 0.2:
			S["cash"] -= best_c
			S["l"][best.id] = cnt("l", best.id) + 1
			bought = true
	if has_d("mgr", "fleet") and S["auto"].get("fleet", false) and prod() > deliv() * 1.05:
		var bv := {}
		var bs := 0.0
		for v in VAN:
			var pr := cost_n(v.b, cnt("v", v.id), 1)
			if pr < float(S["cash"]) * 0.2 and v.r / pr > bs:
				bs = v.r / pr
				bv = v
		if not bv.is_empty():
			S["cash"] -= cost_n(bv.b, cnt("v", bv.id), 1)
			S["v"][bv.id] = cnt("v", bv.id) + 1
			bought = true
	if has_d("mgr", "sec") and S["auto"].get("sec", true) and risk() > 40.0:
		var bg := {}
		var bs2 := 0.0
		for g in GUARD:
			var pr := cost_n(g.b, cnt("g", g.id), 1)
			if pr < float(S["cash"]) * 0.2 and g.v / pr > bs2:
				bs2 = g.v / pr
				bg = g
		if not bg.is_empty():
			S["cash"] -= cost_n(bg.b, cnt("g", bg.id), 1)
			S["g"][bg.id] = cnt("g", bg.id) + 1
			bought = true
	if bought:
		invalidate()
		world.dirty_auto = true

func ach_done(id: String) -> bool:
	match id:
		"a1": return S["life"] >= 1e6
		"a2": return S["life"] >= 1e9
		"a3": return S["life"] >= 1e12
		"a4": return int(S["won"]) >= 10
		"a5": return int(S["won"]) >= 50
		"a6":
			for l in LINES:
				if l.get("note", false) and cnt("l", l.id) > 0:
					return true
			return false
		"a7":
			for l in LINES:
				if cnt("l", l.id) == 0:
					return false
			return true
		"a8", "a9":
			for l in LINES:
				if cnt("l", l.id) >= (10 if id == "a8" else 100):
					return true
			return false
		"a10": return int(S["odone"]) >= 5
		"a11": return int(S["odone"]) >= 25
		"a12": return S["coins"].size() >= 1
		"a13": return feat_n() >= FEAT.size()
		"a14": return int(S["fakes"]) >= 10
		"a15": return int(S["rep"]) >= 1
		"a16": return int(S["gold"]) >= 10
		"a17": return S["sites"].size() >= SITES.size()
		"a18": return int(S["streak"]) >= 7
	return false

func check_ach() -> void:
	for a in ACH:
		if not S["ach"].has(a.id) and ach_done(a.id):
			S["ach"][a.id] = 1
			add_log("Erfolg freigeschaltet: %s (+2 %% Herstellung für immer)" % a.n, "good")

# ---------------------------------------------------------------- Dialoge
var dlg_root: Control

func overlay(panel: PanelContainer) -> Control:
	var root := ColorRect.new()
	root.color = Color(0, 0, 0, 0.55)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.visible = false
	add_child(root)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(cc)
	panel.custom_minimum_size = Vector2(650, 0)
	cc.add_child(panel)
	return root

func build_dialog() -> void:
	dlg = PanelContainer.new()
	dlg.add_theme_stylebox_override("panel", sbox(C_CARD, 26, C_GOLD, 4, 28))
	dlg_root = overlay(dlg)
	dlg_box = vb(16)
	dlg.add_child(dlg_box)

func open_dialog(title: String, text: String) -> void:
	for c in dlg_box.get_children():
		dlg_box.remove_child(c)
		c.queue_free()
	dlg_box.add_child(lbl(title, 36, C_GOLD, true, true))
	if text != "":
		dlg_box.add_child(lbl(text, 26, C_INK, false, true))
	dlg_root.visible = true

func close_dialog() -> void:
	dlg_root.visible = false

func show_event(ev: Dictionary) -> void:
	var cost: float = max(50.0, income() * 60.0 * float(ev.get("mins", 0.0)))
	open_dialog(ev.t, ev.d)
	var col := vb(10)
	dlg_box.add_child(col)
	var a_txt: String = ev.a
	if ev.has("mins"):
		a_txt += " (%s)" % fmt(cost)
	if ev.has("bonus"):
		a_txt += " (+%s)" % fmt(max(50.0, income() * 60.0 * float(ev.bonus)))
	var ba := btn(a_txt, func(): event_choice(ev, true, cost), "main", 0)
	ba.disabled = ev.has("mins") and float(S["cash"]) < cost
	col.add_child(ba)
	col.add_child(btn(ev.b, func(): event_choice(ev, false, cost), "light", 0))
	for b in col.get_children():
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(590, 84)

func event_choice(ev: Dictionary, a: bool, cost: float) -> void:
	close_dialog()
	S["ev_cur"] = ""
	var gt: float = S["gt"]
	if a:
		if ev.has("mins"):
			S["cash"] -= cost
			add_log("%s: bezahlt (%s)." % [ev.t, fmt(cost)], "good")
		if ev.has("fxa"):
			S["fx"].append({k=ev.fxa.k, m=ev.fxa.m, until=gt + ev.fxa.dur})
			add_log("%s: Sonderschicht läuft!" % ev.t, "good")
		if ev.has("bonus"):
			var b: float = max(50.0, income() * 60.0 * float(ev.bonus))
			earn(b)
			add_log("%s: Lob vom Rechnungshof, Bonus %s." % [ev.t, fmt(b)], "good")
	elif ev.has("fx"):
		var f := {k=ev.fx.k, m=ev.fx.m, until=gt + ev.fx.dur}
		if ev.fx.k == "line":
			var built := []
			for l in LINES:
				if cnt("l", l.id) > 0:
					built.append(l.id)
			if built.is_empty():
				return
			f["id"] = built[randi() % built.size()]
		S["fx"].append(f)
		add_log("%s: abgewartet." % ev.t, "bad")
	world.dirty = true
	save_game()
	update_ui()

# ---------------------------------------------------------------- Falschgeld-Jagd
func hunt_ready() -> bool:
	return float(S["gt"]) >= float(S["hunt_next"])

func start_hunt() -> void:
	open_dialog("Falschgeld-Jagd", "Eine dieser Banknoten ist gefälscht: Bei einem Sicherheitsmerkmal stimmt etwas nicht. Tippe auf die Fälschung!")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	dlg_box.add_child(grid)
	var fake := randi() % 4
	var vals := [[5, "#9aa3a8"], [10, "#d96a6a"], [20, "#5b8fd0"], [50, "#e09a3a"], [100, "#6fae8f"], [200, "#d9c25a"]]
	var feats := FEATNAMES.duplicate()
	feats.shuffle()
	feats = feats.slice(0, 4)
	var bad_feat := randi() % 4
	for i in range(4):
		var v: Array = vals[randi() % vals.size()]
		var idx := i
		var b := Button.new()
		b.custom_minimum_size = Vector2(285, 250)
		var st := sbox(Color(v[1]), 16, Color("#ffffff"), 3, 10)
		b.add_theme_stylebox_override("normal", st)
		b.add_theme_stylebox_override("hover", st)
		b.add_theme_stylebox_override("pressed", sbox(Color(v[1]).darkened(0.2), 16, Color("#ffffff"), 3, 10))
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var txt := "%d EURO\n" % v[0]
		for k in range(4):
			var fn: Array = feats[k]
			txt += "✓ " + (fn[1] if (i == fake and k == bad_feat) else fn[0]) + "\n"
		b.text = txt.strip_edges()
		b.add_theme_font_size_override("font_size", 22)
		b.add_theme_color_override("font_color", Color("#13262a"))
		b.add_theme_color_override("font_hover_color", Color("#13262a"))
		b.add_theme_color_override("font_pressed_color", Color("#13262a"))
		b.pressed.connect(func(): hunt_pick(idx == fake))
		grid.add_child(b)
	dlg_box.add_child(btn("Abbrechen", func(): close_dialog(), "light", 0))

func hunt_pick(ok: bool) -> void:
	close_dialog()
	S["hunt_next"] = float(S["gt"]) + 180.0
	if ok:
		var rew: float = max(100.0, income() * 120.0)
		earn(rew)
		S["fakes"] = int(S["fakes"]) + 1
		add_log("Fälschung erkannt! Belohnung %s." % fmt(rew), "good")
	else:
		add_log("Das war eine echte Banknote. In 3 Minuten gibt es eine neue Chance.", "bad")
	render()

# ---------------------------------------------------------------- Belohnungen
func today() -> int:
	return int(now() / 86400.0)

func daily_ready() -> bool:
	return int(S["daily_day"]) != today()

func claim_daily() -> void:
	if not daily_ready():
		return
	S["streak"] = int(S["streak"]) + 1 if int(S["daily_day"]) == today() - 1 else 1
	S["daily_day"] = today()
	var st: int = min(int(S["streak"]), 7)
	var rew: float = max(100.0 * st, income() * 60.0 * 5.0 * st)
	earn(rew)
	add_log("Tägliche Belohnung (Tag %d in Folge): %s." % [int(S["streak"]), fmt(rew)], "good")
	save_game()
	render()

func box_wait() -> float:
	return max(0.0, 14400.0 - (now() - float(S["box_ts"])))

func open_box() -> void:
	if box_wait() > 0.0:
		return
	S["box_ts"] = now()
	var r := randf()
	if r < 0.5:
		var rew: float = max(200.0, income() * 60.0 * (15.0 + randf() * 30.0))
		earn(rew)
		add_log("Glückskiste: %s Bargeld!" % fmt(rew), "good")
	elif r < 0.75:
		S["gold"] = int(S["gold"]) + 1
		add_log("Glückskiste: ein Goldbarren für die Goldreserve!", "good")
		world.dirty = true
	else:
		var any := false
		for o in S["orders"]:
			if o.get("active", false):
				o["done"] = min(o["need"], o["done"] + o["need"] * 0.5)
				any = true
		if any:
			add_log("Glückskiste: Alle laufenden Aufträge sind 50 % weiter!", "good")
		else:
			var rew2: float = max(300.0, income() * 60.0 * 30.0)
			earn(rew2)
			add_log("Glückskiste: %s Bargeld!" % fmt(rew2), "good")
	save_game()
	render()

# ---------------------------------------------------------------- Zentrale
func gold_cost() -> float:
	return 10000.0 * pow(1.25, int(S["gold"]))

func shred_cost() -> float:
	return 2000.0 * pow(6.0, int(S["shred"]))

func escort_cost() -> float:
	return 500.0 * pow(5.0, int(S["escort"]))

# ---------------------------------------------------------------- Fahrzeug-Upgrade
const UP_DISCOUNT := 0.7

func van_index(id: String) -> int:
	for i in range(VAN.size()):
		if VAN[i].id == id:
			return i
	return -1

## Wie viele Fahrzeuge (Typ i -> i+1) und zu welchem Preis
func up_plan(i: int) -> Array:
	var cur: Dictionary = VAN[i]
	var nxt: Dictionary = VAN[i + 1]
	var own := cnt("v", cur.id)
	var cn := cnt("v", nxt.id)
	if own <= 0:
		return [0, 0.0]
	var n := 1
	if amt == "max":
		n = 0
		while n < own and cost_n(nxt.b, cn, n + 1) * UP_DISCOUNT <= float(S["cash"]):
			n += 1
		n = max(1, n)
	else:
		n = min(int(amt), own)
	return [n, cost_n(nxt.b, cn, n) * UP_DISCOUNT]

func upgrade_van(i: int) -> void:
	invalidate()
	var plan := up_plan(i)
	var n: int = plan[0]
	var price: float = plan[1]
	if n <= 0 or float(S["cash"]) < price:
		return
	var cur: Dictionary = VAN[i]
	var nxt: Dictionary = VAN[i + 1]
	S["cash"] -= price
	S["v"][cur.id] = cnt("v", cur.id) - n
	S["v"][nxt.id] = cnt("v", nxt.id) + n
	add_log("%d× %s zu %s umgebaut (%s)." % [n, cur.n, nxt.n, fmt(price)], "good")
	world.dirty = true
	save_game()
	update_ui()

func room_cost(id: String) -> float:
	for r in ROOMS:
		if r.id == id:
			return r.c * pow(4.0, room(id))
	return 1e30

func hire(id: String, delta: int) -> void:
	invalidate()
	var cur := staff(id)
	if delta > 0:
		var room_left: int = min(staff_cap(id) - cur, total_cap() - staff_total())
		if id in ["putz", "verw"]:
			room_left = min(staff_cap(id) - cur, total_cap() - staff_total())
		var n: int = min(delta, room_left)
		if n <= 0:
			add_log("Kein Platz: Umkleideraum, Putzraum oder Personalbüro ausbauen.", "bad")
			return
		var fee: float = 0.0
		for st in STAFF:
			if st.id == id:
				fee = st.fee * n * max(1.0, income() / 200.0)
		if float(S["cash"]) < fee:
			return
		S["cash"] -= fee
		S["staff"][id] = cur + n
		add_log("%d neue %s eingestellt." % [n, staff_name(id)], "good")
	else:
		S["staff"][id] = max(0, cur + delta)
	world.dirty = true
	save_game()
	render()

func staff_name(id: String) -> String:
	for st in STAFF:
		if st.id == id:
			return st.n
	return id

func hire_fee(id: String, n: int) -> float:
	for st in STAFF:
		if st.id == id:
			return st.fee * n * max(1.0, income() / 200.0)
	return 0.0

func buy_extra(k: String) -> void:
	invalidate()
	var parts := k.split(":")
	var t := parts[0]
	var id := parts[1] if parts.size() > 1 else ""
	match t:
		"mgr":
			for m in MGR:
				if m.id == id and not has_d("mgr", id) and S["cash"] >= m.c:
					S["cash"] -= m.c
					S["mgr"][id] = true
					S["auto"][id] = id != "fleet"
					add_log("Eingestellt: %s." % m.n, "good")
		"auto":
			S["auto"][id] = not S["auto"].get(id, true)
		"site":
			for m in SITES:
				if m.id == id and not has_d("sites", id) and S["cash"] >= m.c:
					S["cash"] -= m.c
					S["sites"][id] = true
					add_log("Standort eröffnet: %s." % m.n, "good")
		"gold":
			if S["cash"] >= gold_cost():
				S["cash"] -= gold_cost()
				S["gold"] = int(S["gold"]) + 1
				add_log("Goldbarren Nr. %d eingelagert." % int(S["gold"]), "good")
		"shred":
			if int(S["shred"]) < 10 and S["cash"] >= shred_cost():
				S["cash"] -= shred_cost()
				S["shred"] = int(S["shred"]) + 1
				add_log("Schredder-Halle auf Stufe %d ausgebaut." % int(S["shred"]), "good")
		"escort":
			if int(S["escort"]) < 6 and S["cash"] >= escort_cost():
				S["cash"] -= escort_cost()
				S["escort"] = int(S["escort"]) + 1
				add_log("Begleitschutz verstärkt (Stufe %d)." % int(S["escort"]), "good")
		"room":
			if room(id) < 5 and (id == "lobby" or room("lobby") > 0) and S["cash"] >= room_cost(id):
				S["cash"] -= room_cost(id)
				S["rooms"][id] = room(id) + 1
				add_log("%s auf Stufe %d ausgebaut." % [room_title(id), room(id)], "good")
		"shift":
			S["shift"] = clamp(int(id), 0, 2)
			add_log("Schichtbetrieb: %s." % SHIFT_N[shift_i()], "good")
		"esc":
			S["esc_share"] = clamp(int(id), 0, 100)
		"up":
			for u in UPG:
				if u.id == id and up(id) < u.mx and S["cash"] >= upg_cost(id):
					S["cash"] -= upg_cost(id)
					S["up"][id] = up(id) + 1
					add_log("%s auf Stufe %d ausgebaut." % [u.n, up(id)], "good")
		"series":
			if float(S["series_t"]) <= 0.0 and int(S["series"]) < SERIES.size() and cnt("l", "s5") > 0 and S["cash"] >= series_cost():
				S["cash"] -= series_cost()
				S["series_t"] = 600.0
				add_log("Entwicklung gestartet: %s." % SERIES[int(S["series"])], "good")
		"fire":
			if int(S["fire"]) < 5 and S["cash"] >= fire_cost():
				S["cash"] -= fire_cost()
				S["fire"] = int(S["fire"]) + 1
				add_log("Feuerwehr ausgebaut: %s." % FIRE_NAMES[int(S["fire"])], "good")
				if burning():
					S["fire_t"] = min(float(S["fire_t"]), FIRE_TIME[int(S["fire"])])
		"museum":
			if int(S["museum"]) == 0 and int(S["rep"]) >= 1 and S["cash"] >= 1e6:
				S["cash"] -= 1e6
				S["museum"] = 1
				add_log("Das Bundesbank-Museum ist eröffnet!", "good")
	world.dirty = true
	save_game()
	render()

# ---------------------------------------------------------------- Betrieb: Personal-Ausfälle, Wartung, Angriffe, Rohstoffe, Wetter
func machine_break(auto: bool) -> void:
	var built := []
	for l in LINES:
		if cnt("l", l.id) > 0:
			built.append(l)
	if built.is_empty():
		return
	var l: Dictionary = built[randi() % built.size()]
	var dur: float = 180.0 * (1.0 - 0.85 * cov_tech())
	S["fx"].append({k="line", id=l.id, m=0.0, until=float(S["gt"]) + dur})
	add_log("Maschinenschaden an der %s – %s (%d s)." % [l.n, "die Techniker reparieren sofort" if auto else "Reparatur läuft", int(dur)], "bad" if dur > 60.0 else "good")
	world.dirty = true

func ops_tick(dt: float) -> void:
	var gt: float = S["gt"]
	# Rohstoffe
	var use: float = raw_use() if machines_total() > 0 else 0.0
	S["raw"] = clamp(float(S["raw"]) + (raw_supply() - use) * dt, 0.0, 100.0)
	# Begleitschutz-Fahrplan kostet laufend
	S["cash"] = max(0.0, float(S["cash"]) - esc_cost() * dt)
	# Auszubildende werden fertig
	if staff("azubi") > 0:
		S["azubi_t"] = float(S["azubi_t"]) - dt
		if S["azubi_t"] <= 0.0:
			S["azubi_t"] = 240.0
			S["staff"]["azubi"] = staff("azubi") - 1
			S["staff"]["arb"] = staff("arb") + 1
			add_log("Ausbildung bestanden: ein Azubi ist jetzt Produktionsmitarbeiter.", "good")
	if income() <= 0.5:
		return
	# Krankheit und Urlaub
	S["sick_next"] = float(S["sick_next"]) - dt
	if S["sick_next"] <= 0.0:
		S["sick_next"] = 420.0 + randf() * 360.0
		var winter := is_winter()
		var a: float = (0.15 if winter else 0.1) + randf() * 0.05
		S["fx"].append({k="absent", m=a, until=gt + 180.0})
		add_log("%s: %d %% der Belegschaft fehlen für 3 Minuten.%s" % ["Grippewelle" if winter else "Urlaubszeit", int(a * 100), " Springer helfen aus." if staff("spr") > 0 else " Springer würden einspringen."], "bad")
	# Arbeitsunfall
	S["acc_next"] = float(S["acc_next"]) - dt
	if S["acc_next"] <= 0.0:
		S["acc_next"] = 540.0 + randf() * 420.0
		var dur: float = 120.0 / (1.0 + room("sani"))
		S["fx"].append({k="acc", m=0.05, until=gt + dur})
		add_log("Arbeitsunfall in der Halle! Der Rettungsdienst ist da, ein Teil der Schicht steht %d s still.%s" % [int(dur), "" if room("sani") > 0 else " Ein Sanitätsraum verkürzt das."], "bad")
		world.dirty = true
	# Verschleiß: ohne Techniker öfter Maschinenschäden
	S["wear_next"] = float(S["wear_next"]) - dt
	if S["wear_next"] <= 0.0:
		S["wear_next"] = (300.0 + randf() * 300.0) * (1.0 + 2.0 * cov_tech())
		machine_break(staff("tech") > 0)
	# Hackerangriff
	S["hack_next"] = float(S["hack_next"]) - dt
	if S["hack_next"] <= 0.0:
		S["hack_next"] = 600.0 + randf() * 480.0
		if room("it") >= 5 or randf() < 0.22 * room("it"):
			add_log("Hackerangriff auf das Zahlungssystem – die IT-Abteilung hat ihn abgewehrt.", "good")
		else:
			var loss: float = min(float(S["cash"]) * 0.02, income() * 60.0)
			S["cash"] -= loss
			add_log("Hackerangriff! Verlust: %s. Eine IT-Abteilung in der Verwaltung schützt davor." % fmt(loss), "bad")
	# Innentäter
	S["ins_next"] = float(S["ins_next"]) - dt
	if S["ins_next"] <= 0.0:
		S["ins_next"] = 480.0 + randf() * 480.0
		if randf() < min(0.9, 0.3 * up("ctrl")):
			var rew := income() * 15.0
			earn(rew)
			add_log("Ausgangskontrolle: Ein Mitarbeiter wollte Scheine rausschmuggeln und wurde erwischt. Belohnung: %s." % fmt(rew), "good")
		elif up("ctrl") > 0 or randf() < 0.6:
			var l2: float = min(float(S["cash"]) * 0.01, income() * 30.0)
			S["cash"] -= l2
			add_log("Innentäter: Scheine wurden aus dem Werk geschmuggelt. Verlust: %s." % fmt(l2), "bad")
	# Wetter
	S["wx_t"] = float(S["wx_t"]) - dt
	if S["wx_t"] <= 0.0:
		S["wx_t"] = 180.0 + randf() * 240.0
		var opts := ["sun", "sun", "sun", "cloud", "cloud", "rain", "rain", "storm"]
		if is_winter():
			opts += ["snow", "snow", "snow", "cloud"]
		var w: String = opts[randi() % opts.size()]
		if w != S["wx"]:
			S["wx"] = w
			if w == "snow":
				add_log("Es schneit! Auslieferung %d %%%s." % [int(wx_m() * 100), " – der Winterdienst streut" if up("winter") > 0 else ""], "bad")
			elif w == "storm":
				add_log("Gewitter zieht auf – die Transporter fahren langsamer.", "bad")
			world.dirty = true
	# Banknotenserie
	if float(S["series_t"]) > 0.0:
		S["series_t"] = float(S["series_t"]) - dt
		if S["series_t"] <= 0.0:
			S["series_t"] = 0.0
			S["series"] = int(S["series"]) + 1
			add_log("%s ist fertig entwickelt und geht in Druck: Druckhallen +30 %%!" % SERIES[int(S["series"]) - 1], "good")

func do_ezb() -> void:
	if confirm_reset != "ezb":
		confirm_reset = "ezb"
		render()
		return
	if int(S["rep"]) < 10:
		return
	var keep := {ezb=int(S["ezb"]) + 1, life=S["life"], won=S["won"], lost=S["lost"], log=S["log"], staff_need_v1=true, fleet_auto_off=true}
	apply_state(keep)
	confirm_reset = ""
	world.dirty = true
	add_log("Die Europäische Zentralbank übernimmt! EZB-Stern Nr. %d: dauerhaft +50 %% auf alles." % int(S["ezb"]), "good")
	render()

func choice_row(title: String, desc: String, opts: Array, cur, key: String) -> void:
	var p := card()
	var v := vb(8)
	p.add_child(v)
	v.add_child(lbl(title, 28, C_INK, true, true))
	v.add_child(lbl(desc, 23, C_MUT, false, true))
	var h := hb(6)
	v.add_child(h)
	for o in opts:
		var val = o[0]
		var b := btn(o[1], func(): buy_extra(key + ":" + str(val)), "main" if str(val) == str(cur) else "light", 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 22)
		h.add_child(b)

func render_betrieb() -> void:
	head_title("Betrieb", "Schichten, Rohstoffe, Wetter, Notstrom, Kontrollen und Entwicklung.")
	choice_row("Schichtbetrieb", "Mehr Schichten = mehr Herstellung, aber mehr Personal und höhere Löhne (Nachtzuschlag). Jetzt: %s · Herstellung ×%s · Personalbedarf ×%s · Löhne ×%s" % [SHIFT_N[shift_i()], de_num(SHIFT_PROD[shift_i()], 1), de_num(SHIFT_NEED[shift_i()], 1), de_num(SHIFT_WAGE[shift_i()], 1)], [[0, "1 Schicht"], [1, "2 Schichten"], [2, "3 Schichten"]], shift_i(), "shift")
	var wp := card()
	var wv := vb(6)
	wp.add_child(wv)
	var wname: String = WX.get(S["wx"], ["?", 1.0])[0]
	wv.add_child(lbl("Wetter: %s" % wname, 28, C_INK, true))
	wv.add_child(lbl("Auslieferung %d %%. Regen und Gewitter bremsen die Transporter, Schnee (nur im Winter) am stärksten – außer mit Winterdienst." % int(wx_m() * 100), 23, C_MUT, false, true))
	var rp := card()
	var rv := vb(6)
	rp.add_child(rv)
	rv.add_child(lbl("Rohstoffe", 28, C_INK, true))
	var rl := lbl("", 23, C_MUT, false, true)
	rv.add_child(rl)
	var rb := pbar(12)
	rv.add_child(rb)
	refs["raw"] = {desc=rl, bar=rb}
	for u in UPG:
		if u.id == "bus" and int(S["museum"]) == 0:
			continue
		var lv := up(u.id)
		extra_card("%s · Stufe %d/%d" % [u.n, lv, u.mx], u.d, "up:" + u.id, "Voll" if lv >= u.mx else fmt(upg_cost(u.id)), S["cash"] >= upg_cost(u.id), lv >= u.mx)
	choice_row("Begleitschutz-Fahrplan", "Anteil der Transporte, die zusätzlich von Polizei begleitet werden. Senkt Überfälle unterwegs (bis −80 %%), kostet laufend %s/s." % fmt(esc_cost()), [[0, "0 %"], [25, "25 %"], [50, "50 %"], [75, "75 %"], [100, "100 %"]], int(S["esc_share"]), "esc")
	section("Entwicklung")
	var sn := int(S["series"])
	if float(S["series_t"]) > 0.0:
		extra_card(SERIES[sn], "In Entwicklung: noch %s. Danach Druckhallen dauerhaft +30 %%." % dur_txt(float(S["series_t"])), "series", "Läuft …", false)
	elif sn < SERIES.size():
		var ok := cnt("l", "s5") > 0
		extra_card(SERIES[sn], "Neue Banknotenserie mit besseren Sicherheitsmerkmalen entwickeln (10 Minuten). Danach Druckhallen dauerhaft +30 %%." + ("" if ok else " Braucht die 5-Euro-Linie."), "series", fmt(series_cost()), ok and S["cash"] >= series_cost())
	else:
		extra_card("Alle Banknotenserien entwickelt ✓", "Druckhallen +%d %%." % (30 * sn), "series", "Fertig", false, true)

func update_betrieb_ui() -> void:
	if refs.has("raw"):
		var r: Dictionary = refs["raw"]
		if not is_instance_valid(r.bar):
			return
		r.bar.value = float(S["raw"])
		r.desc.text = "Lager %d %% · Nachschub %s %%/s · Verbrauch %s %%/s%s" % [int(S["raw"]), de_num(raw_supply(), 2), de_num(raw_use(), 2), " · LEER: Linien laufen nur mit %d %%!" % int(raw_m() * 100) if raw_m() < 1.0 else ""]

# ---------------------------------------------------------------- Feuerwehr und Brände
const FIRE_NAMES := ["keine Feuerwache", "Löschgruppe", "Feuerwache mit Drehleiter", "Hauptwache mit Rüstwagen", "Berufsfeuerwehr", "Werkfeuerwehr rund um die Uhr"]
const FIRE_TIME := [150.0, 70.0, 45.0, 28.0, 16.0, 8.0]

func fire_cost() -> float:
	return 2e5 * pow(7.0, float(S["fire"]))

func burning() -> bool:
	return float(S.get("fire_t", 0.0)) > 0.0

func fire_tick(dt: float) -> void:
	var lvl := int(S["fire"])
	if burning():
		S["fire_t"] = float(S["fire_t"]) - dt
		if S["fire_t"] <= 0.0:
			S["fire_t"] = 0.0
			add_log("Brand in der Druckerei gelöscht – die Druckmaschinen laufen wieder." if lvl > 0 else "Das Feuer in der Druckerei ist endlich aus. Eine Feuerwache hätte viel schneller gelöscht.", "good")
			world.dirty = true
		return
	if hall_machines(true) <= 0:
		return
	S["fire_next"] = float(S["fire_next"]) - dt
	if S["fire_next"] <= 0.0:
		S["fire_next"] = (360.0 + randf() * 420.0) * (1.0 + lvl * 0.35)
		S["fire_t"] = FIRE_TIME[min(lvl, 5)]
		S["fires"] = int(S["fires"]) + 1
		var loss: float = 0.0
		if lvl == 0:
			loss = float(S["cash"]) * 0.03
			S["cash"] -= loss
		add_log("Brand in der Druckerei! Die Druckmaschinen stehen still. %s" % ("Die %s rückt aus." % FIRE_NAMES[lvl] if lvl > 0 else "Ohne Feuerwehr dauert das Löschen lange – Schaden: %s." % fmt(loss)), "bad")
		world.dirty = true

func fire_card() -> void:
	var lvl := int(S["fire"])
	var d := "Brände in der Druckerei legen die Scheinproduktion lahm. Jetzt: %s, Löschzeit ca. %d s." % [FIRE_NAMES[lvl], int(FIRE_TIME[lvl])]
	if lvl < 5:
		d += " Nächste Stufe: %s (Löschzeit %d s, seltener Brände)." % [FIRE_NAMES[lvl + 1], int(FIRE_TIME[lvl + 1])]
	if burning():
		d = "ES BRENNT in der Druckerei! Noch ca. %d s bis gelöscht. " % int(ceil(float(S["fire_t"]))) + d
	extra_card("Feuerwehr Stufe %d/5" % lvl, d, "fire", "Voll" if lvl >= 5 else fmt(fire_cost()), S["cash"] >= fire_cost(), lvl >= 5)

func room_title(id: String) -> String:
	for r in ROOMS:
		if r.id == id:
			return r.n
	return id

func extra_card(title: String, desc: String, key: String, label: String, ok: bool, done := false) -> void:
	var p := card()
	var row := hb(14)
	p.add_child(row)
	var left := vb(4)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	left.add_child(lbl(title, 28, C_INK, true, true))
	left.add_child(lbl(desc, 23, C_MUT, false, true))
	var b := btn(label, func(): buy_extra(key), "main", 220, not key.begins_with("auto"))
	b.disabled = not ok or done
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(b)
	refs["x:" + key] = {btn=b}

func section(t: String) -> void:
	var l := lbl(t, 30, C_GOLD, true)
	content.add_child(l)

var zsub := "geb"

func render_zentrale() -> void:
	var seg := PanelContainer.new()
	seg.add_theme_stylebox_override("panel", sbox(C_CARD, 20, C_LINE, 2, 6))
	content.add_child(seg)
	var sh := hb(6)
	seg.add_child(sh)
	for it in [["geb", "Gebäude"], ["pers", "Personal"], ["betr", "Betrieb"], ["mehr", "Leitung"]]:
		var key: String = it[0]
		var on := zsub == key
		var b := btn(it[1], func():
			zsub = key
			render(), "main" if on else "light", 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if not on:
			b.add_theme_stylebox_override("normal", sbox(Color(0, 0, 0, 0), 16, Color(0, 0, 0, 0), 0, 6))
		sh.add_child(b)
	if zsub == "geb":
		render_rooms()
		return
	if zsub == "pers":
		render_staff()
		return
	if zsub == "betr":
		render_betrieb()
		return
	head_title("Leitung & mehr", "Werksleiter, Standorte, Gold, Schredder, Leitzins und Museum.")
	section("Werksleitung")
	for m in MGR:
		if has_d("mgr", m.id):
			var on: bool = S["auto"].get(m.id, m.id != "fleet")
			extra_card(m.n + " ✓", m.d, "auto:" + m.id, "Automatik an" if on else "Automatik aus", true)
		else:
			extra_card(m.n, m.d, "mgr:" + m.id, "Einstellen " + fmt(m.c), S["cash"] >= m.c)
	section("Standorte")
	for m in SITES:
		var own := has_d("sites", m.id)
		extra_card(m.n + (" ✓" if own else ""), m.d, "site:" + m.id, "Eröffnet" if own else fmt(m.c), S["cash"] >= m.c, own)
	section("Goldreserve und Schredder")
	extra_card("Goldbarren kaufen (%d im Tresor)" % int(S["gold"]), "Jeder Barren: +3 % Herstellung, lockt aber Räuber an (+2 % Bedrohung).", "gold", fmt(gold_cost()), S["cash"] >= gold_cost())
	var sl := int(S["shred"])
	extra_card("Schredder-Halle Stufe %d/10" % sl, "Vernichtet abgenutzte Scheine: +5 % Erlös je Stufe auf jede Auslieferung.", "shred", "Voll" if sl >= 10 else fmt(shred_cost()), S["cash"] >= shred_cost(), sl >= 10)
	section("Leitzins")
	var zp := card()
	var zv := vb(8)
	zp.add_child(zv)
	var zl := lbl("", 28, C_INK, true)
	zv.add_child(zl)
	var sl2 := HSlider.new()
	sl2.min_value = 0
	sl2.max_value = 5
	sl2.step = 1
	sl2.value = zins()
	sl2.custom_minimum_size = Vector2(0, 60)
	sl2.add_theme_icon_override("grabber", make_grabber())
	sl2.add_theme_icon_override("grabber_highlight", make_grabber())
	sl2.add_theme_stylebox_override("slider", sbox(C_MAIN2, 8, Color(0, 0, 0, 0), 0, 6))
	sl2.add_theme_stylebox_override("grabber_area", sbox(C_GOLD, 8, Color(0, 0, 0, 0), 0, 6))
	sl2.add_theme_stylebox_override("grabber_area_highlight", sbox(C_GOLD, 8, Color(0, 0, 0, 0), 0, 6))
	zv.add_child(sl2)
	var zd := lbl("", 23, C_MUT, false, true)
	zv.add_child(zd)
	var upd := func(v: float):
		S["zins"] = int(v)
		zl.text = "Leitzins: %d %%" % int(v)
		zd.text = "Erlös ×%s · Bedrohung ×%s · Auftragslohn ×%s\nNiedriger Zins: mehr Geschäft, mehr Risiko. Hoher Zins: weniger Erlös, mehr Sicherheit." % [de_num(1.1 - 0.04 * v, 2), de_num(1.3 - 0.1 * v, 2), de_num(1.4 - 0.1 * v, 2)]
	upd.call(sl2.value)
	sl2.value_changed.connect(upd)
	section("Museum")
	if int(S["museum"]) > 0:
		var mp := card()
		var mv := vb(6)
		mp.add_child(mv)
		mv.add_child(lbl("Bundesbank-Museum ✓", 28, C_INK, true))
		mv.add_child(lbl("Ausstellungsstücke: %d Währungsreformen, %d Gedenkmünzen. Bonus: +%d %% auf alles." % [int(S["rep"]), S["coins"].size(), int(S["rep"]) * 5], 23, C_MUT, false, true))
	else:
		extra_card("Bundesbank-Museum", "Ab der ersten Währungsreform baubar. Jede Reform wird ausgestellt: +5 % Herstellung je Reform.", "museum", fmt(1e6), int(S["rep"]) >= 1 and S["cash"] >= 1e6)
	section("Landeszentralbanken")
	var ln := lzb_n()
	var lp := card()
	var lv2 := vb(6)
	lp.add_child(lv2)
	lv2.add_child(lbl("%d von %d Bundesländern versorgt · +%d %% Herstellung" % [ln, LZB.size(), ln * 2], 28, C_INK, true, true))
	var names := PackedStringArray()
	for i in LZB.size():
		names.append(("✓ " if i < ln else "") + LZB[i])
	lv2.add_child(lbl(" · ".join(names), 22, C_MUT, false, true))
	if ln < LZB.size():
		var lb := pbar(12)
		lb.value = clamp(log(max(1.0, float(S["life"]))) / log(lzb_need(ln)) * 100.0, 0.0, 100.0)
		lv2.add_child(lb)
		lv2.add_child(lbl("Nächstes: %s ab %s insgesamt ausgeliefert." % [LZB[ln], fmt(lzb_need(ln))], 22, C_GOLD, false, true))
	section("Europäische Zentralbank")
	var ep := card()
	var ev2 := vb(8)
	ep.add_child(ev2)
	ev2.add_child(lbl("EZB-Gründung · Sterne: %d" % int(S["ezb"]), 29, C_INK, true))
	ev2.add_child(lbl("Der große Neustart: Alles wird zurückgesetzt, auch die Reputation. Dafür gibt jeder EZB-Stern dauerhaft +50 %% auf Herstellung und Auslieferung (jetzt ×%s). Ab 10 Reputation." % de_num(ezb_m(), 1), 23, C_MUT, false, true))
	var eb := btn("Wirklich alles neu?" if confirm_reset == "ezb" else "EZB gründen", func(): do_ezb(), "red" if confirm_reset == "ezb" else "main", 0)
	eb.disabled = int(S["rep"]) < 10
	ev2.add_child(eb)

func render_rooms() -> void:
	head_title("Verwaltungsgebäude", "Baue die Räume der Bundesbank aus. Du siehst sie im 3D-Werk oben hinter den Hallen.")
	for r in ROOMS:
		var lv := room(r.id)
		var locked: bool = r.id != "lobby" and room("lobby") == 0
		var label := "Voll" if lv >= 5 else ("Bauen " if lv == 0 else "Stufe %d · " % (lv + 1)) + fmt(room_cost(r.id))
		var d: String = r.d + ("  (erst Eingangshalle bauen)" if locked else "")
		extra_card("%s · Stufe %d/5" % [r.n, lv], d, "room:" + r.id, label, not locked and S["cash"] >= room_cost(r.id), lv >= 5)

func render_staff() -> void:
	head_title("Personal", "Mehr Mitarbeiter bringen mehr Leistung – aber sie wollen jeden Zahltag ihren Lohn.")
	var p := card()
	var v := vb(6)
	p.add_child(v)
	v.add_child(lbl("Belegschaft", 29, C_INK, true))
	var info := lbl("", 23, C_MUT, false, true)
	v.add_child(info)
	var mb := pbar(12)
	v.add_child(mb)
	refs["staffinfo"] = {desc=info, bar=mb}
	amount_row()
	for st in STAFF:
		var c := card()
		var cv := vb(6)
		c.add_child(cv)
		var top := hb(10)
		cv.add_child(top)
		var t := lbl(st.n, 28, C_INK, true, true)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(t)
		var cnt_l := lbl("", 27, C_GOLD, true)
		top.add_child(cnt_l)
		cv.add_child(lbl(st.d, 22, C_MUT, false, true))
		var row := hb(10)
		cv.add_child(row)
		var eff := lbl("", 22, C_GREEN, false, true)
		row.add_child(eff)
		var id: String = st.id
		var minus := btn("−", func(): hire(id, -(int(amt) if amt != "max" else 10)), "light", 80)
		row.add_child(minus)
		var plus := btn("", func(): hire(id, hire_count(id)), "main", 230, true)
		row.add_child(plus)
		refs["st:" + id] = {cnt=cnt_l, eff=eff, plus=plus, minus=minus}

func hire_count(id: String) -> int:
	var room_left: int = max(0, min(staff_cap(id) - staff(id), total_cap() - staff_total()))
	if amt == "max":
		var n := room_left
		while n > 0 and hire_fee(id, n) > float(S["cash"]):
			n -= 1
		return max(1, n)
	return max(1, min(int(amt), max(1, room_left)))

func update_staff_ui() -> void:
	if refs.has("staffinfo"):
		var r: Dictionary = refs["staffinfo"]
		var unpaid := float(S["gt"]) < float(S["unpaid_until"])
		r.desc.text = "%d von %d Plätzen belegt (Umkleideraum) · Lohnkosten %s/s · Zahltag in %s, offen %s · Zufriedenheit %d %%%s" % [staff_total(), total_cap(), fmt(wage_rate()), dur_txt(float(S["payday"])), fmt(S["owed"]), int(morale()), " · Löhne nicht gezahlt!" if unpaid else ""]
		r.bar.value = morale()
	for st in STAFF:
		var key: String = "st:" + st.id
		if not refs.has(key):
			continue
		var r2: Dictionary = refs[key]
		var n := staff(st.id)
		r2.cnt.text = "%d / %d" % [n, staff_cap(st.id)]
		var e := ""
		match st.id:
			"arb":
				e = "Benötigt: %d · Maschinen laufen zu %d %%" % [need_arb(), int(cov_arb() * 100)]
			"fahr":
				e = "Benötigt: %d · Fahrzeuge fahren zu %d %%" % [need_fahr(), int(cov_fahr() * 100)]
			"wach":
				e = "Schutz +%d %%" % int(min(1.0, 0.04 * n) * 100)
			"spr":
				e = "Fehlen gerade: %d %% · Springer füllen die Lücke" % int(absent_frac() * 100)
			"azubi":
				e = ("Nächster Abschluss in %s" % dur_txt(float(S["azubi_t"]))) if n > 0 else "Zählen halb als Produktionsmitarbeiter"
			"tech":
				e = "Benötigt: %d · Wartung %d %%" % [need_tech(), int(cov_tech() * 100)]
			"putz":
				e = "Herstellung +%d %%" % int(min(0.2, 0.02 * n) * 100) if room("putz") > 0 else "Erst den Putzraum bauen"
			"verw":
				e = "Auftragslohn +%d %% · Löhne −%d %%" % [int(min(0.6, 0.03 * n) * 100), int(min(0.4, 0.02 * n) * 100)]
		r2.eff.text = e
		var hc := hire_count(st.id)
		var full: bool = staff_cap(st.id) - n <= 0 or total_cap() - staff_total() <= 0
		r2.plus.text = "Kein Platz" if full else ("+%d · %s" % [hc, fmt(hire_fee(st.id, hc))])
		r2.plus.disabled = full or float(S["cash"]) < hire_fee(st.id, hc)
		r2.minus.disabled = n <= 0

func make_grabber() -> Texture2D:
	var img := Image.create(44, 44, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(44):
		for x in range(44):
			if Vector2(x - 21.5, y - 21.5).length() < 20.0:
				img.set_pixel(x, y, C_GOLD)
	return ImageTexture.create_from_image(img)

func update_extras() -> void:
	for key in refs.keys():
		if not key.begins_with("x:"):
			continue
		var k: String = key.substr(2)
		var b: Button = refs[key].btn
		if k.begins_with("mgr:"):
			for m in MGR:
				if "mgr:" + m.id == k:
					b.disabled = S["cash"] < m.c
		elif k.begins_with("site:"):
			for m in SITES:
				if "site:" + m.id == k and not has_d("sites", m.id):
					b.disabled = S["cash"] < m.c
		elif k == "gold":
			b.disabled = S["cash"] < gold_cost()
		elif k == "shred" and int(S["shred"]) < 10:
			b.disabled = S["cash"] < shred_cost()
		elif k == "escort" and int(S["escort"]) < 6:
			b.disabled = S["cash"] < escort_cost()
		elif k == "museum":
			b.disabled = int(S["rep"]) < 1 or S["cash"] < 1e6
