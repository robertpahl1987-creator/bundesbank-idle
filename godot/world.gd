extends Node3D
## 3D-Werk: Hallen, Maschinen, Lager, Fuhrpark, Schutz

var main
var dirty := true
var mats := {}
var meshes := {}
var dyn: Node3D
var anim := {}
var cam: Camera3D
var zoom := 1.0
var tx := -1.0
var tz := -3.0
var t := 0.0
var sp_t := 0.0
var sp := []
var robbers := []
var beacon: MeshInstance3D
var beacon_mat: StandardMaterial3D
var pile_node: Node3D
var last_pile := -1
var touches := {}
var moved := 0.0
var pinch := 0.0
var dragging := false
var last_build := -10.0
var last_sig := ""
var dirty_auto := false

## Alles, was im 3D-Werk sichtbar ist, als Text – nur wenn er sich ändert, wird neu aufgebaut
func visual_sig() -> String:
	var S: Dictionary = main.S
	var parts := PackedStringArray()
	parts.append("fw%d,%d" % [int(S.get("fire", 0)), int(main.burning())])
	var fz: int = main.feat_n()
	for l in main.LINES:
		var c := cnt("l", l.id)
		var locked: bool = l.has("req") and fz < int(l.req)
		var wk: int = min(5, 1 + int(log(max(c, 1)) / log(2.0) / 1.4))
		var nit: int = min(10, 3 + int(log(c + 1) / log(2.0)))
		parts.append("%d,%d,%d,%d,%d" % [min(c, 10), main.ms_n(c), wk, nit, int(locked)])
	parts.append("lv%d" % min(int(S["lv"]), 6))
	for k in ["t8", "t11", "t12"]:
		parts.append(k + str(int(main.has_flag("t", k))))
	parts.append("wt%d" % wall_tier())
	parts.append("pt%d" % police_tier())
	parts.append(str(S["rooms"]))
	parts.append("st%d,%d" % [min(int(S["staff"].get("verw", 0)), 6), min(int(S["staff"].get("putz", 0)), 4)])
	parts.append("cart%d" % cart_count())
	var caps := {"g1": 8, "g2": 12, "g4": 1, "g5": 1, "g7": 1, "g8": 4, "g9": 4, "g10": 1}
	for k in caps.keys():
		parts.append(k + str(min(cnt("g", k), caps[k])))
	var tot := 0
	for k in ["v1", "v2", "v3", "v4"]:
		tot += cnt("v", k)
	parts.append("fleet%d,gold%d" % [min(tot, 12), int(int(S["gold"]) > 0)])
	for k in ["v1", "v2", "v3", "v4"]:
		parts.append(k + str(int(cnt("v", k) > 0)))
	for k in ["v5", "v6", "v7", "v8"]:
		parts.append(k + str(int(cnt("v", k) > 0)))
	parts.append("gold%d" % min(int(S["gold"]), 60))
	parts.append("sh%d" % int(S["shred"]))
	parts.append("mu%d,%d" % [int(S["museum"]), int(S["rep"]) + S["coins"].size()])
	parts.append("es%d" % int(S["escort"]))
	parts.append(str(S["sites"].keys()))
	parts.append(str(S["mgr"].keys()))
	var act := ""
	for o in S["orders"]:
		act += "1" if o.get("active", false) else "0"
	parts.append(act)
	return "|".join(parts)
var env: Environment
var sun: DirectionalLight3D
var lamps := []
var lamp_mat: StandardMaterial3D
var win_mat: StandardMaterial3D

const LAMP := ["#9aa3a8", "#3fd68a", "#3fd68a", "#ffc23d", "#ffc23d", "#ff4d5e", "#ff4d5e", "#a46bff", "#a46bff", "#a46bff"]
const ZONES := [
	[-15.0, -13.0, -1.0, 1.0, "werk", "coin"],
	[1.0, -13.0, 15.0, 1.0, "werk", "note"],
	[-15.0, 3.0, -5.0, 11.0, "werk", "lager"],
	[-4.0, 3.0, 16.0, 12.0, "deliv", ""],
	[-16.0, -37.0, 16.0, -27.0, "zentrale", ""],
	[25.0, -4.0, 37.0, 9.5, "guard", ""],
	[-18.0, -16.0, 30.0, 18.0, "guard", ""],
]

# ---------------------------------------------------------------- Bausteine
func mat(c: String, alpha := 1.0, emit := false) -> StandardMaterial3D:
	var k := c + str(alpha) + str(emit)
	if mats.has(k):
		return mats[k]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c)
	m.roughness = 0.78
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color.a = alpha
	if emit:
		m.emission_enabled = true
		m.emission = Color(c)
		m.emission_energy_multiplier = 0.8
	mats[k] = m
	return m

func B(w: float, h: float, d: float, c: String, x: float, y: float, z: float, p: Node3D = null, alpha := 1.0) -> MeshInstance3D:
	var key := "b%.3f|%.3f|%.3f" % [w, h, d]
	if not meshes.has(key):
		var bm := BoxMesh.new()
		bm.size = Vector3(w, h, d)
		meshes[key] = bm
	var mi := MeshInstance3D.new()
	mi.mesh = meshes[key]
	mi.material_override = mat(c, alpha)
	mi.position = Vector3(x, y, z)
	if alpha < 1.0 or w * h * d < 0.03:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(p if p != null else self).add_child(mi)
	return mi

func C(r1: float, r2: float, h: float, c: String, x: float, y: float, z: float, p: Node3D = null, seg := 12) -> MeshInstance3D:
	var key := "c%.3f|%.3f|%.3f|%d" % [r1, r2, h, seg]
	if not meshes.has(key):
		var cm := CylinderMesh.new()
		cm.top_radius = r1
		cm.bottom_radius = r2
		cm.height = h
		cm.radial_segments = seg
		cm.rings = 1
		meshes[key] = cm
	var mi := MeshInstance3D.new()
	mi.mesh = meshes[key]
	mi.material_override = mat(c)
	mi.position = Vector3(x, y, z)
	if max(r1, r2) * h < 0.05:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(p if p != null else self).add_child(mi)
	return mi

func sphere(r: float, c: String, x: float, y: float, z: float, p: Node3D, seg := 10) -> MeshInstance3D:
	var key := "s%.3f|%d" % [r, seg]
	if not meshes.has(key):
		var sm := SphereMesh.new()
		sm.radius = r
		sm.height = r * 2.0
		sm.radial_segments = seg
		sm.rings = 6 if seg >= 10 else 4
		meshes[key] = sm
	var mi := MeshInstance3D.new()
	mi.mesh = meshes[key]
	mi.material_override = mat(c)
	mi.position = Vector3(x, y, z)
	p.add_child(mi)
	return mi

# Echte Euro-Münzen: Metallfarben, Größen und Bimetall-Aufbau
const COIN_SPEC := {
	"c1": {r=0.17, ring="copper", core="copper"},
	"c10": {r=0.2, ring="gold", core="gold"},
	"c50": {r=0.24, ring="gold", core="gold"},
	"e1": {r=0.23, ring="gold", core="silver"},
	"e2": {r=0.26, ring="silver", core="gold"},
}
const METALS := {
	"copper": ["#c8763f", "#a85e30"],
	"gold": ["#e2bf55", "#c9a23a"],
	"silver": ["#d4d9dc", "#aab2b6"],
}

func metal(kind: String, shade := 0) -> StandardMaterial3D:
	var c: String = METALS[kind][shade]
	var k := "metal_" + c
	if mats.has(k):
		return mats[k]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c)
	m.metallic = 0.65
	m.roughness = 0.32
	m.metallic_specular = 0.7
	mats[k] = m
	return m

## Eine Münze flach liegend: Rand, vertiefte Bildfläche, Kern (bei 1 € und 2 € andersfarbig)
func coin(id: String, x: float, y: float, z: float, p: Node3D, scale_f := 1.0) -> void:
	var sp: Dictionary = COIN_SPEC.get(id, COIN_SPEC["c10"])
	var r: float = sp.r * scale_f
	var h := 0.07 * scale_f
	var rim := C(r, r, h, "#000000", x, y, z, p, 20)
	rim.material_override = metal(sp.ring, 0)
	var field := C(r * 0.86, r * 0.86, h + 0.006, "#000000", x, y + 0.001, z, p, 20)
	field.material_override = metal(sp.ring, 1)
	if sp.core != sp.ring:
		var core := C(r * 0.6, r * 0.6, h + 0.014, "#000000", x, y + 0.002, z, p, 18)
		core.material_override = metal(sp.core, 0)
		var core_in := C(r * 0.5, r * 0.5, h + 0.018, "#000000", x, y + 0.003, z, p, 18)
		core_in.material_override = metal(sp.core, 1)
	else:
		var relief := C(r * 0.42, r * 0.42, h + 0.014, "#000000", x, y + 0.002, z, p, 16)
		relief.material_override = metal(sp.ring, 0)

const SKIN := ["#f1c9a5", "#d9a77e", "#a8744f", "#f5d6bd"]
const HAIR := ["#3b2a1e", "#1b1b1b", "#8a5a2b", "#c9a15a", "#5a3a22"]

## Figur mit Beinen, Schuhen, Armen, Händen, Kopf, Haaren und Gesicht
func person(col: String, p: Node3D, helmet := false, style := "") -> Node3D:
	var g := Node3D.new()
	var skin: String = SKIN[randi() % SKIN.size()]
	var hair: String = HAIR[randi() % HAIR.size()]
	var pants := "#2f3a44"
	var top := col
	if style == "guard" or style == "police":
		pants = "#1c2a40"
		top = "#1f3a66" if style == "police" else "#26344a"
	elif style == "soldier":
		pants = "#4a5634"
		top = "#4b5a32"
	elif style == "manager":
		pants = "#262b35"
		top = "#2a2f3a"
	elif style == "fire":
		pants = "#1d2a3f"
		top = "#22314a"
	elif style == "robber":
		pants = "#1e1e22"
		top = "#2a2a2e"
	# Beine (leicht konisch), Schuhe
	C(0.062, 0.072, 0.44, pants, -0.08, 0.28, 0, g, 6)
	C(0.062, 0.072, 0.44, pants, 0.08, 0.28, 0, g, 6)
	B(0.12, 0.07, 0.22, "#17191b", -0.08, 0.035, 0.03, g)
	B(0.12, 0.07, 0.22, "#17191b", 0.08, 0.035, 0.03, g)
	# Hüfte, Gürtel, Oberkörper (breite Schultern)
	B(0.29, 0.12, 0.19, pants, 0, 0.53, 0, g)
	B(0.3, 0.04, 0.2, "#151515", 0, 0.6, 0, g)
	C(0.17, 0.135, 0.36, top, 0, 0.79, 0, g, 8)
	sphere(0.075, top, -0.17, 0.93, 0, g, 6)
	sphere(0.075, top, 0.17, 0.93, 0, g, 6)
	# Arme und Hände
	C(0.05, 0.042, 0.4, top, -0.215, 0.74, 0, g, 6)
	C(0.05, 0.042, 0.4, top, 0.215, 0.74, 0, g, 6)
	sphere(0.045, skin, -0.215, 0.52, 0, g, 6)
	sphere(0.045, skin, 0.215, 0.52, 0, g, 6)
	# Hals, Kopf, Gesicht
	C(0.05, 0.055, 0.08, skin, 0, 1.0, 0, g, 6)
	sphere(0.125, skin, 0, 1.13, 0, g, 8)
	B(0.03, 0.025, 0.01, "#1a1a1a", -0.045, 1.15, 0.118, g)
	B(0.03, 0.025, 0.01, "#1a1a1a", 0.045, 1.15, 0.118, g)
	B(0.03, 0.04, 0.03, skin, 0, 1.11, 0.125, g)
	B(0.06, 0.015, 0.01, "#9a5444", 0, 1.06, 0.116, g)
	match style:
		"police":
			C(0.172, 0.172, 0.06, "#e8ecee", 0, 0.84, 0, g, 8)
			B(0.12, 0.04, 0.01, "#ffd21a", 0, 0.9, 0.155, g)
			C(0.13, 0.13, 0.08, "#1f3a66", 0, 1.26, 0, g, 8)
			C(0.135, 0.135, 0.025, "#ffd21a", 0, 1.23, 0, g, 8)
			B(0.2, 0.02, 0.09, "#111111", 0, 1.22, 0.12, g)
		"guard":
			C(0.125, 0.125, 0.07, "#16233a", 0, 1.25, 0, g, 8)
			B(0.2, 0.02, 0.09, "#16233a", 0, 1.22, 0.12, g)
			B(0.1, 0.06, 0.01, "#c9d2d5", 0.07, 0.86, 0.15, g)
		"soldier":
			sphere(0.145, "#3f4a2a", 0, 1.17, -0.01, g, 8)
			C(0.165, 0.165, 0.2, "#56653a", 0, 0.8, 0, g, 8)
		"manager":
			sphere(0.13, hair, 0, 1.17, -0.025, g, 8)
			B(0.1, 0.18, 0.01, "#f2f2f2", 0, 0.88, 0.148, g)
			B(0.035, 0.17, 0.012, "#c8102e", 0, 0.86, 0.152, g)
		"fire":
			C(0.172, 0.172, 0.05, "#e6ec3a", 0, 0.85, 0, g, 8)
			C(0.172, 0.165, 0.05, "#c9d2d5", 0, 0.7, 0, g, 8)
			C(0.066, 0.066, 0.04, "#e6ec3a", -0.08, 0.15, 0, g, 6)
			C(0.066, 0.066, 0.04, "#e6ec3a", 0.08, 0.15, 0, g, 6)
			sphere(0.145, "#f2f2ee", 0, 1.18, 0, g, 8)
			B(0.24, 0.1, 0.02, "#e6ec3a", 0, 1.2, 0.135, g)
		"robber":
			sphere(0.13, "#111111", 0, 1.135, 0, g, 8)
			B(0.15, 0.04, 0.01, "#f1c9a5", 0, 1.15, 0.125, g)
		_:
			if helmet:
				sphere(0.14, "#ffd21a", 0, 1.18, 0, g, 8)
				B(0.24, 0.02, 0.1, "#ffd21a", 0, 1.17, 0.14, g)
				C(0.172, 0.17, 0.05, "#e8ecee", 0, 0.86, 0, g, 8)
				C(0.168, 0.16, 0.05, "#e8ecee", 0, 0.72, 0, g, 8)
			else:
				sphere(0.13, hair, 0, 1.17, -0.025, g, 8)
	p.add_child(g)
	return g

func label3d(txt: String, x: float, y: float, z: float) -> void:
	var l := Label3D.new()
	l.text = txt
	l.font_size = 120
	l.pixel_size = 0.011
	l.outline_size = 28
	l.modulate = Color("#ffffff")
	l.outline_modulate = Color("#0a4f4a")
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 10
	l.position = Vector3(x, y, z)
	add_child(l)

# ---------------------------------------------------------------- Start
func _ready() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#7ec8e3")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#d8ecff")
	env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.92
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	add_child(sun)
	sun.look_at_from_position(Vector3(18, 32, 12), Vector3.ZERO, Vector3.UP)
	sun.light_energy = 0.95
	sun.light_color = Color("#fff4df")
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 110.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.near = 0.1
	cam.far = 250.0
	add_child(cam)
	cam.current = true
	build_static()
	merge_children(self, {beacon: true})
	apply_quality()
	fit()

# ---------------------------------------------------------------- Einrichtung und Fassaden
func chair(x: float, z: float, p: Node3D = null, rot := 0.0) -> void:
	var c := Node3D.new()
	B(0.32, 0.05, 0.32, "#2b3436", 0, 0.42, 0, c)
	B(0.32, 0.36, 0.05, "#2b3436", 0, 0.62, -0.15, c)
	B(0.04, 0.4, 0.04, "#7a8489", 0, 0.21, 0, c)
	B(0.3, 0.03, 0.04, "#7a8489", 0, 0.03, 0, c)
	B(0.04, 0.03, 0.3, "#7a8489", 0, 0.03, 0, c)
	c.position = Vector3(x, 0.15, z)
	c.rotation.y = rot
	(p if p != null else self).add_child(c)

func office_desk(x: float, z: float, p: Node3D = null) -> void:
	B(1.0, 0.05, 0.55, "#c9b28a", x, 0.88, z, p)
	B(0.05, 0.68, 0.5, "#9aa3a8", x - 0.46, 0.53, z, p)
	B(0.05, 0.68, 0.5, "#9aa3a8", x + 0.46, 0.53, z, p)
	B(0.4, 0.26, 0.03, "#1a1a1a", x, 1.06, z - 0.18, p)
	var scr := B(0.36, 0.22, 0.01, "#4ab0ff", x, 1.06, z - 0.163, p)
	scr.material_override = mat("#4ab0ff", 1.0, true)
	B(0.3, 0.02, 0.12, "#2b3436", x, 0.92, z + 0.05, p)
	chair(x, z + 0.55, p, PI)

func extinguisher(x: float, z: float, p: Node3D = null) -> void:
	C(0.08, 0.08, 0.4, "#d4202a", x, 0.4, z, p, 8)
	B(0.06, 0.06, 0.06, "#1a1a1a", x, 0.63, z, p)

func locker_row(x: float, z: float, n: int, p: Node3D = null) -> void:
	for k in range(n):
		B(0.34, 1.0, 0.4, "#7f8f99" if k % 2 == 0 else "#6f7f89", x + k * 0.36, 0.65, z, p)
		B(0.04, 0.1, 0.02, "#1a1a1a", x + k * 0.36 + 0.1, 0.75, z + 0.21, p)

func workbench(x: float, z: float, p: Node3D = null) -> void:
	B(1.4, 0.08, 0.55, "#8a6a4a", x, 0.85, z, p)
	B(1.4, 0.6, 0.05, "#5a6163", x, 0.5, z - 0.25, p)
	B(1.4, 0.6, 0.05, "#5a6163", x, 0.5, z + 0.25, p)
	B(1.4, 0.7, 0.04, "#9aa3a8", x, 1.25, z - 0.26, p)
	for k in range(5):
		B(0.04, 0.22, 0.03, ["#c8102e", "#3d6fb0", "#e2b53c", "#1a1a1a", "#3b8f3a"][k], x - 0.5 + k * 0.25, 1.2, z - 0.22, p)

## Sozialtrakt hinter jeder Halle: Meisterbüro, Pausenecke, Spinde, Werkbank, Lager
func annex(cx: float, note: bool) -> void:
	var z0 := -14.3
	var wall := "#3d6fb0" if note else "#a8503a"
	B(14, 0.14, 2.4, "#d9d4c8", cx, 0.12, z0)
	B(14, 1.6, 0.25, "#eef0ec", cx, 0.9, z0 - 1.15)
	B(14.1, 0.18, 0.3, wall, cx, 1.75, z0 - 1.15)
	for k in range(6):
		var wnd := B(1.2, 0.55, 0.04, "#2a3a40", cx - 5.5 + k * 2.2, 1.05, z0 - 1.01)
		wnd.material_override = win_mat
	# Trennwände (Glas) und Türen
	for wx in [-3.0, 1.0, 4.4]:
		B(0.06, 1.0, 2.2, "#bfe3ef", cx + wx, 0.65, z0, null, 0.45)
	# Meisterbüro links
	office_desk(cx - 5.4, z0 - 0.55)
	B(0.9, 1.4, 0.35, "#5a3a22", cx - 3.7, 0.85, z0 - 0.85)
	for k in range(3):
		B(0.8, 0.22, 0.28, ["#c8102e", "#3d6fb0", "#e2b53c"][k], cx - 3.7, 0.4 + k * 0.42, z0 - 0.8)
	C(0.12, 0.09, 0.25, "#a8744f", cx - 6.6, 0.3, z0 + 0.6, null, 8)
	var lf := sphere(0.2, "#3b8f3a", cx - 6.6, 0.58, z0 + 0.6, self)
	lf.scale = Vector3(1, 1.3, 1)
	# Pausenecke
	C(0.45, 0.45, 0.05, "#e9e4d8", cx - 1.0, 0.85, z0 + 0.1, null, 14)
	C(0.06, 0.06, 0.7, "#5a6163", cx - 1.0, 0.5, z0 + 0.1, null, 6)
	chair(cx - 1.65, z0 + 0.1, null, PI / 2)
	chair(cx - 0.35, z0 + 0.1, null, -PI / 2)
	chair(cx - 1.0, z0 - 0.55, null, 0.0)
	B(0.4, 0.75, 0.4, "#2b3436", cx + 0.5, 0.55, z0 - 0.8)
	B(0.3, 0.06, 0.04, "#c8102e", cx + 0.5, 0.75, z0 - 0.59)
	# Spinde
	locker_row(cx + 1.35, z0 - 0.8, 8)
	# Lager / Werkbank rechts
	if note:
		for k in range(4):
			var roll := C(0.32, 0.32, 0.9, "#f4f1e6", cx + 5.0 + (k % 2) * 0.7, 0.45 + int(k / 2) * 0.64, z0 - 0.5, null, 14)
			roll.rotation.x = PI / 2
		for k in range(4):
			C(0.22, 0.22, 0.6, ["#00a3d9", "#d6006e", "#f2d100", "#2b2b2b"][k], cx + 4.9 + k * 0.5, 0.45, z0 + 0.55, null, 10)
	else:
		workbench(cx + 5.6, z0 - 0.6)
		for k in range(3):
			C(0.25, 0.25, 0.55, "#9aa3a8", cx + 4.9 + k * 0.6, 0.42, z0 + 0.6, null, 10)
	extinguisher(cx - 6.8, z0 - 0.85)
	extinguisher(cx + 6.8, z0 - 0.85)

## Fußwege und Türen von der Hofseite in die Halle
const HALL_A := [-13.0, -6.4]
const HALL_B := [-5.6, 1.0]
const LINE_Z := {"c1": -11.75, "c10": -9.65, "c50": -7.55, "e1": -3.9, "e2": -1.3, "s5": -11.0, "s20": -8.3, "s100": -3.9, "s200": -1.3}

## Hallenboden mit niedrigen Wänden; Durchgänge zum Mittelgang
func hall_box(cx: float, z0: float, z1: float, floor_c: String, wall: String) -> void:
	var d := z1 - z0
	var cz := (z0 + z1) / 2.0
	B(14, 0.14, d, floor_c, cx, 0.12, cz)
	B(14, 0.5, 0.3, wall, cx, 0.35, z0)
	B(14, 0.5, 0.3, wall, cx, 0.35, z1)
	B(0.3, 0.5, d, wall, cx - 7.0, 0.35, cz)
	B(0.3, 0.5, d, wall, cx + 7.0, 0.35, cz)
	# Tür zum Mittelgang
	var zd := z1 if z1 < -6.0 else z0
	B(1.4, 0.06, 0.34, "#9aa3a8", cx, 0.62, zd)
	B(0.1, 0.5, 0.34, "#5a6163", cx - 0.72, 0.36, zd)
	B(0.1, 0.5, 0.34, "#5a6163", cx + 0.72, 0.36, zd)
	# gelbe Fußwege
	B(0.08, 0.02, d - 0.4, "#ffd21a", cx - 6.65, 0.2, cz)
	B(0.08, 0.02, d - 0.4, "#ffd21a", cx - 5.95, 0.2, cz)
	B(13.4, 0.02, 0.08, "#ffd21a", cx, 0.2, z1 - 0.3)
	B(13.4, 0.02, 0.08, "#ffd21a", cx, 0.2, z0 + 0.3)

func hall_paths(cx: float, note: bool) -> void:
	# Tür in der vorderen Hallenwand
	B(1.4, 0.06, 0.32, "#9aa3a8", cx, 0.62, 1.0)
	B(0.1, 0.5, 0.32, "#5a6163", cx - 0.72, 0.36, 1.0)
	B(0.1, 0.5, 0.32, "#5a6163", cx + 0.72, 0.36, 1.0)
	# Gehweg zum Hof
	B(1.6, 0.05, 2.0, "#c9c3b5", cx, 0.12, 2.0)
	extinguisher(cx + 6.6, 0.6)
	extinguisher(cx - 6.6, -12.5)

## Fassade für geschlossene Gebäude: Fensterbänder, Tür mit Vordach, Dachaggregate, Gehweg
func facade(cx: float, cz: float, w: float, d: float, h: float, p: Node3D) -> void:
	var floors := int(max(1.0, floor(h / 1.2)))
	for f in range(floors):
		var y := 0.7 + f * 1.15
		for k in range(int(w / 0.9)):
			B(0.55, 0.45, 0.04, "#2c3f4d", cx - w / 2.0 + 0.5 + k * 0.9, y, cz + d / 2.0 + 0.02, p)
		for k in range(int(d / 0.9)):
			B(0.04, 0.45, 0.55, "#2c3f4d", cx + w / 2.0 + 0.02, y, cz - d / 2.0 + 0.5 + k * 0.9, p)
	B(0.9, 0.95, 0.06, "#3a4a5a", cx, 0.58, cz + d / 2.0 + 0.03, p)
	B(1.4, 0.07, 0.6, "#5a6163", cx, 1.15, cz + d / 2.0 + 0.3, p)
	B(1.2, 0.05, 1.8, "#c9c3b5", cx, 0.12, cz + d / 2.0 + 0.9, p)
	for k in range(2):
		B(0.6, 0.35, 0.5, "#9aa3a8", cx - w / 4.0 + k * w / 2.0, h + 0.38, cz, p)
		B(0.5, 0.04, 0.4, "#5a6163", cx - w / 4.0 + k * w / 2.0, h + 0.57, cz, p)

const RING_N := -24.0
const RING_S := 19.5
const POL_X := 31.0
const POL_Z := 2.5
const BLOCKED := [
	[-20.0, -18.0, 20.0, 18.0],
	[-25.0, -27.0, 24.0, -21.0], [18.5, -27.0, 24.0, 22.5], [-25.0, 16.5, 24.0, 22.5], [-25.0, -27.0, -19.0, 22.5],
	[-19.0, 10.5, 84.0, 15.2],
	[-19.0, -38.5, 19.0, -26.5],
	[25.0, -4.0, 37.0, 9.5], [23.0, 13.5, 34.0, 19.0],
	[-36.0, -12.0, -26.5, -3.0], [-33.0, 1.5, -25.5, 8.5], [-38.0, 9.5, -25.0, 18.5],
	[-60.0, 25.0, 90.0, 28.5], [7.0, 18.0, 13.0, 55.0], [-25.0, 18.0, -19.0, 55.0],
	[39.0, -36.0, 52.0, -20.0], [44.0, -14.0, 58.0, -1.0], [42.0, 2.0, 56.0, 11.0], [50.0, 15.0, 64.0, 33.0],
]

func tree_free(x: float, z: float) -> bool:
	for r in BLOCKED:
		if x > r[0] - 1.2 and x < r[2] + 1.2 and z > r[1] - 1.2 and z < r[3] + 1.2:
			return false
	return true

## Laubbaum: Stamm, Äste und mehrere Blattballen in unterschiedlichen Grüntönen
func leaf_tree(x: float, z: float, s: float, n: int) -> void:
	var th := 1.3 * s
	C(0.12 * s, 0.2 * s, th, "#5b4330", x, th / 2.0, z, null, 7)
	C(0.05 * s, 0.08 * s, 0.9 * s, "#5b4330", x + 0.25 * s, th + 0.2 * s, z, null, 5)
	C(0.05 * s, 0.08 * s, 0.9 * s, "#5b4330", x - 0.2 * s, th + 0.25 * s, z + 0.15 * s, null, 5)
	var greens := ["#3f6b2a", "#4a7a30", "#365f25", "#57863a"]
	var off := [[0.0, 1.0, 0.0, 1.0], [0.55, 0.75, 0.2, 0.75], [-0.5, 0.8, -0.25, 0.8], [0.1, 0.7, 0.55, 0.7], [-0.15, 1.55, -0.1, 0.7], [0.3, 1.3, -0.5, 0.6]]
	for i in off.size():
		var o: Array = off[i]
		sphere(float(o[3]) * s * 1.25, greens[(i + n) % 4], x + float(o[0]) * s, th + float(o[1]) * s, z + float(o[2]) * s, self, 8)

## Nadelbaum (Fichte): schlanker Stamm, gestufte Kegel
func conifer(x: float, z: float, s: float) -> void:
	C(0.09 * s, 0.14 * s, 0.9 * s, "#4e3a2a", x, 0.45 * s, z, null, 6)
	var lv := [[1.25, 1.5, 1.2], [1.0, 1.35, 2.1], [0.75, 1.15, 2.9], [0.45, 0.9, 3.6]]
	for i in lv.size():
		var l: Array = lv[i]
		C(0.02, float(l[0]) * s, float(l[1]) * s, "#24472a" if i % 2 == 0 else "#2b5230", x, float(l[2]) * s, z, null, 7)

## Birke: weißer Stamm mit dunklen Flecken, hellgrüne, lichte Krone
func birch(x: float, z: float, s: float) -> void:
	var th := 2.2 * s
	C(0.07 * s, 0.11 * s, th, "#e6e2d6", x, th / 2.0, z, null, 7)
	for k in 4:
		B(0.16 * s, 0.05 * s, 0.05, "#2e2b28", x + 0.02, 0.4 * s + k * 0.45 * s, z + 0.09 * s)
	sphere(0.6 * s, "#7a9e45", x, th + 0.2 * s, z, self, 8)
	sphere(0.45 * s, "#6b9140", x + 0.35 * s, th - 0.2 * s, z + 0.1 * s, self, 8)
	sphere(0.42 * s, "#86a84e", x - 0.3 * s, th - 0.05 * s, z - 0.2 * s, self, 8)

## Busch aus zwei, drei Ballen
func bush(x: float, z: float, n: int) -> void:
	var c := ["#3d6a2c", "#47752f", "#35602a"]
	sphere(0.5, c[n % 3], x, 0.35, z, self, 8)
	sphere(0.4, c[(n + 1) % 3], x + 0.45, 0.28, z + 0.15, self, 8)
	sphere(0.35, c[(n + 2) % 3], x - 0.3, 0.25, z + 0.3, self, 8)

## Straße mit Mittelstreifen
func road(x1: float, z1: float, x2: float, z2: float, p: Node3D = null) -> void:
	var horiz: bool = abs(x2 - x1) >= abs(z2 - z1)
	var L: float = max(abs(x2 - x1), abs(z2 - z1))
	var cx := (x1 + x2) / 2.0
	var cz := (z1 + z2) / 2.0
	if horiz:
		B(L + 3.0, 0.08, 0.9, "#8d8f8a", cx, 0.07, cz - 1.95, p)
		B(L + 3.0, 0.08, 0.9, "#8d8f8a", cx, 0.07, cz + 1.95, p)
		B(L + 3.0, 0.06, 3.0, "#3e4447", cx, 0.1, cz, p)
		B(L + 3.0, 0.065, 0.12, "#c9cdd0", cx, 0.105, cz - 1.42, p)
		B(L + 3.0, 0.065, 0.12, "#c9cdd0", cx, 0.105, cz + 1.42, p)
	else:
		B(0.9, 0.08, L + 3.0, "#8d8f8a", cx - 1.95, 0.07, cz, p)
		B(0.9, 0.08, L + 3.0, "#8d8f8a", cx + 1.95, 0.07, cz, p)
		B(3.0, 0.06, L + 3.0, "#3e4447", cx, 0.1, cz, p)
		B(0.12, 0.065, L + 3.0, "#c9cdd0", cx - 1.42, 0.105, cz, p)
		B(0.12, 0.065, L + 3.0, "#c9cdd0", cx + 1.42, 0.105, cz, p)
	var k := 1.0
	while k < L - 0.5:
		if horiz:
			B(1.2, 0.07, 0.14, "#ffffff", min(x1, x2) + k, 0.12, cz, p)
		else:
			B(0.14, 0.07, 1.2, "#ffffff", cx, 0.12, min(z1, z2) + k, p)
		k += 3.0

func build_static() -> void:
	B(320, 0.2, 320, "#3c5e27", 0, -0.1, 0)
	B(35, 0.1, 31, "#8e9a9e", 0, 0.05, 0)
	# Vier Fertigungshallen: Cent, Euro-Münzen, Druckhalle 1 und 2 – getrennt durch einen Mittelgang
	hall_box(-8.0, HALL_A[0], HALL_A[1], "#cdb68a", "#a8503a")
	hall_box(-8.0, HALL_B[0], HALL_B[1], "#d3c29c", "#8f4632")
	hall_box(8.0, HALL_A[0], HALL_A[1], "#a8b6c4", "#41638f")
	hall_box(8.0, HALL_B[0], HALL_B[1], "#b3bfcb", "#35557c")
	# Mittelgang mit Querweg zwischen den Hallen
	B(30.0, 0.05, 0.8, "#c9c3b5", 0.0, 0.12, -6.0)
	B(1.6, 0.05, 14.0, "#c9c3b5", 0.0, 0.12, -6.0)
	# Tresor
	B(10, 0.14, 8, "#c9b27a", -10, 0.12, 7)
	# Hof, Rampe, Straße
	B(19, 0.08, 9, "#4d5559", 6, 0.12, 7.5)
	B(1.2, 0.6, 3.2, "#a9b0b0", -3.6, 0.4, 9.4)
	# Hauptstraße vom Werkstor nach Osten, Hofzufahrt
	road(-10.0, 12.8, 80.0, 12.8)
	B(3, 0.06, 9, "#4a5154", 14.5, 0.1, 8.5)
	# Ringstraße ums Werk
	road(-22.0, RING_N, 21.0, RING_N)
	road(21.0, RING_N, 21.0, RING_S)
	road(-22.0, RING_S, 21.0, RING_S)
	road(-22.0, RING_N, -22.0, RING_S)
	# Zufahrten: Polizei, Museum, Hubschrauberplatz
	road(21.0, 3.0, POL_X - 4.75, 3.0)
	road(-22.0, -8.0, -27.5, -8.0)
	road(-22.0, 5.0, -27.0, 5.0)
	road(-22.0, 14.0, -27.0, 14.0)
	# Ausfahrten für mittlere und schwere Transporte (Süd), Abfahrten über die Bahn
	road(2.0, 12.8, 2.0, RING_S)
	road(10.0, 12.8, 10.0, RING_S)
	road(10.0, RING_S, 10.0, 52.0)
	road(-22.0, RING_S, -22.0, 52.0)
	for ex in [["Ausfahrt leicht", 19.2, 10.6], ["Ausfahrt mittel", 2.0, 17.2], ["Ausfahrt schwer", 10.0, 17.2]]:
		var el := Label3D.new()
		el.text = ex[0]
		el.font_size = 72
		el.pixel_size = 0.011
		el.outline_size = 16
		el.outline_modulate = Color("#13262a")
		el.modulate = Color("#ffc23d")
		el.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		el.no_depth_test = true
		el.position = Vector3(ex[1], 2.2, ex[2])
		add_child(el)
	# Schild der Bundesdruckerei an der Druckerei
	for zz in [-8.6, -3.4]:
		C(0.06, 0.06, 2.3, "#5a6163", 16.3, 1.2, zz, null, 6)
	B(0.12, 1.0, 5.8, "#13336b", 16.3, 2.0, -6.0)
	B(0.13, 0.08, 5.8, "#e9b915", 16.3, 1.48, -6.0)
	var bd := Label3D.new()
	bd.text = "BUNDESDRUCKEREI"
	bd.font_size = 64
	bd.pixel_size = 0.0085
	bd.outline_size = 0
	bd.modulate = Color("#ffffff")
	bd.position = Vector3(16.37, 2.02, -6.0)
	bd.rotation.y = PI / 2
	add_child(bd)
	# Natürliche Vegetation: Laubbäume, Nadelbäume, Birken und Büsche
	var n := 0
	var xg := -46.0
	while xg <= 46.0:
		var zg := -46.0
		while zg <= 36.0:
			var jx := xg + sin(xg * 1.7 + zg * 0.9) * 1.8
			var jz := zg + cos(xg * 0.8 - zg * 1.3) * 1.8
			if tree_free(jx, jz):
				var h := fposmod(sin(jx * 12.9898 + jz * 78.233) * 43758.5453, 1.0)
				var sc := 0.85 + h * 0.4
				if h < 0.45:
					leaf_tree(jx, jz, sc, n)
				elif h < 0.72:
					conifer(jx, jz, sc)
				elif h < 0.88:
					birch(jx, jz, sc)
				else:
					bush(jx, jz, n)
				if n % 3 == 0 and tree_free(jx + 1.6, jz + 1.1):
					bush(jx + 1.6, jz + 1.1, n + 1)
				n += 1
			zg += 5.5
		xg += 5.5
	# Grünflächen mit Farbvariationen (Wiese, trockenere Stellen)
	var gx := -60.0
	while gx <= 60.0:
		var gz := -60.0
		while gz <= 45.0:
			var hv := fposmod(sin(gx * 3.1 + gz * 7.7) * 9187.31, 1.0)
			if hv > 0.55 and tree_free(gx, gz):
				var gc: String = ["#395a24", "#42642a", "#3f6026", "#47662c"][int(hv * 37.0) % 4]
				B(4.0 + hv * 3.0, 0.02, 3.5 + hv * 2.5, gc, gx, 0.005, gz)
			gz += 6.0
		gx += 6.0
	lamp_mat = StandardMaterial3D.new()
	lamp_mat.albedo_color = Color("#fff2c0")
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color("#ffd27a")
	win_mat = StandardMaterial3D.new()
	win_mat.albedo_color = Color("#2a3a40")
	win_mat.emission_enabled = true
	win_mat.emission = Color("#ffc86a")
	for lp in [[-2, 11.2], [6, 11.2], [14, 11.2], [22, 11.2], [30, 11.2], [-16.2, -5], [-16.2, 5], [0, -14.2], [16.2, -6]]:
		C(0.07, 0.09, 3.2, "#3a4448", lp[0], 1.6, lp[1], null, 6)
		var hd := B(0.5, 0.18, 0.5, "#3a4448", lp[0], 3.25, lp[1])
		var bulb := B(0.36, 0.12, 0.36, "#fff2c0", lp[0], 3.12, lp[1])
		bulb.material_override = lamp_mat
	annex(-8.0, false)
	annex(8.0, true)
	hall_paths(-8.0, false)
	hall_paths(8.0, true)
	label3d("Cent-Halle", -8, 3.0, -9.7)
	label3d("Euro-Münzhalle", -8, 3.0, -2.3)
	label3d("Druckhalle 1", 8, 3.0, -9.7)
	label3d("Druckhalle 2", 8, 3.0, -2.3)
	label3d("Tresor", -10, 4.4, 4.0)
	label3d("Fuhrpark", 6, 2.4, 7.5)
	for i in range(3):
		var r := person("#222831", self, false, "robber")
		merge_deep(r)
		r.visible = false
		robbers.append(r)
	beacon = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.35
	sm.height = 0.7
	beacon.mesh = sm
	beacon_mat = StandardMaterial3D.new()
	beacon_mat.albedo_color = Color("#3a6fd8")
	beacon_mat.emission_enabled = true
	beacon_mat.emission = Color.BLACK
	beacon.material_override = beacon_mat
	beacon.position = Vector3(-10, 2.4, 3.4)
	beacon.visible = false
	add_child(beacon)

# ---------------------------------------------------------------- dynamischer Aufbau
func cnt(o: String, id: String) -> int:
	return main.cnt(o, id)

func build() -> void:
	if dyn:
		dyn.queue_free()
	dyn = Node3D.new()
	add_child(dyn)
	anim = {belts = [], pist = [], work = [], guards = [], cams = [], trucks = [], drones = [], train = null, plane = null, rotor = null, gate = null}
	var fz: int = main.feat_n()
	var S: Dictionary = main.S
	for i in range(main.LINES.size()):
		var l: Dictionary = main.LINES[i]
		var note: bool = l.get("note", false)
		var z: float = LINE_Z.get(l.id, -6.0)
		var x0: float = 2.0 if note else -14.0
		var L := 11.0
		var c := cnt("l", l.id)
		var ms: int = main.ms_n(c)
		if c == 0:
			var locked: bool = l.has("req") and fz < int(l.req)
			B(L + 0.6, 0.06, 1.3, "#ff7a7a" if locked else "#5fe0bd", x0 + L / 2, 0.22, z, dyn, 0.6)
			continue
		# Band mit Gestell
		B(L, 0.12, 0.7, "#262d2f", x0 + L / 2, 0.5, z, dyn)
		B(L, 0.1, 0.08, "#9aa3a8", x0 + L / 2, 0.58, z - 0.39, dyn)
		B(L, 0.1, 0.08, "#9aa3a8", x0 + L / 2, 0.58, z + 0.39, dyn)
		var q := 0.0
		while q <= L:
			B(0.08, 0.36, 0.08, "#5a6163", x0 + q, 0.3, z - 0.33, dyn)
			B(0.08, 0.36, 0.08, "#5a6163", x0 + q, 0.3, z + 0.33, dyn)
			q += 2.2
		# Schild mit Stufenwürfeln
		C(0.06, 0.06, 1.4, "#5a6163", x0 - 0.4, 0.7, z, dyn, 6)
		B(0.7, 0.5, 0.08, l.col, x0 - 0.4, 1.45, z + 0.05, dyn)
		for k in range(min(ms, 9)):
			B(0.12, 0.12, 0.12, "#ffc23d", x0 - 0.68 + (k % 5) * 0.14, 1.82 + int(k / 5) * 0.16, z + 0.05, dyn)
		# Palette am Ende
		B(1.0, 0.14, 1.1, "#a5814f", x0 + L + 0.55, 0.26, z, dyn)
		if note:
			for k in range(4):
				B(0.38, 0.22, 0.42, l.col, x0 + L + 0.33 + (k % 2) * 0.45, 0.44 + int(k / 2) * 0.22, z, dyn)
		else:
			var sk := sphere(0.26, "#c9b48a", x0 + L + 0.3, 0.6, z - 0.3, dyn)
			sk.scale = Vector3(1, 1.15, 1)
			for q2 in range(4):
				for st in range(4):
					coin(l.id, x0 + L + 0.42 + (q2 % 2) * 0.42, 0.37 + st * 0.075, z + 0.05 + int(q2 / 2) * 0.4, dyn, 0.85)
		# Ware auf dem Band
		var n_it: int = min(10, 3 + int(log(c + 1) / log(2.0)))
		var spacing := L / n_it
		var ig := Node3D.new()
		dyn.add_child(ig)
		for k in range(n_it):
			if note:
				B(0.55, 0.06, 0.32, l.col, x0 + k * spacing, 0.6, z, ig)
			else:
				coin(l.id, x0 + k * spacing, 0.6, z, ig)
		merge_deep(ig)
		anim.belts.append({l = l, g = ig, spacing = spacing, ph = randf()})
		var ramg := Node3D.new()
		dyn.add_child(ramg)
		# Maschinen: 1:1 bis 10 Plätze
		var mc: int = min(c, 10)
		var lv: int = min(int(ms / 2), 4)
		var lamp: String = LAMP[min(ms, 9)]
		var FR: String = ["#5f7f8c", "#2f8f80", "#6b5fbf", "#b8862f", "#c0453f"][lv]
		var INK := ["#00a3d9", "#d6006e", "#f2d100", "#2b2b2b", l.col]
		for j in range(mc):
			var mx := x0 + 0.75 + j * 1.05
			B(0.95, 0.03, 1.5, "#ffc23d", mx, 0.17, z, dyn)
			if not note:
				B(0.8, 0.14, 1.25, "#3a4448", mx, 0.24, z, dyn)
				B(0.16, 1.15, 0.16, FR, mx, 0.85, z - 0.5, dyn)
				B(0.16, 1.15, 0.16, FR, mx, 0.85, z + 0.5, dyn)
				B(0.7, 0.3, 1.25, FR, mx, 1.55, z, dyn)
				B(0.72, 0.05, 1.27, "#ffc23d", mx, 1.42, z, dyn)
				C(0.15, 0.15, 0.32, "#c9d2d5", mx, 1.86, z, dyn, 10)
				B(0.42, 0.07, 0.46, "#20272a", mx, 0.6, z, dyn)
				coin(l.id, mx, 0.67, z, dyn, 0.9)
				B(0.36, 0.22, 0.4, "#d9e0e3", mx, 1.15, z, ramg)
				C(0.22, 0.09, 0.3, "#aeb6b9", mx, 1.05, z - 0.82, dyn, 8)
				var blank_m := C(0.21, 0.21, 0.03, "#000000", mx, 1.2, z - 0.82, dyn, 10)
				blank_m.material_override = metal(COIN_SPEC.get(l.id, COIN_SPEC["c10"]).ring, 1)
				B(0.06, 0.5, 0.06, "#5a6163", mx, 0.6, z - 0.82, dyn)
				B(0.05, 0.55, 0.05, "#5a6163", mx, 0.45, z + 0.85, dyn)
				B(0.3, 0.22, 0.1, "#d9e0e3", mx, 0.85, z + 0.85, dyn)
				var scr := B(0.22, 0.14, 0.02, "#3fd68a", mx, 0.86, z + 0.9, dyn)
				scr.material_override = mat("#3fd68a", 1.0, true)
				if ms > 0:
					var lm := B(0.16, 0.12, 0.16, lamp, mx + 0.25, 1.77, z + 0.4, dyn)
					lm.material_override = mat(lamp, 1.0, true)
			else:
				B(0.96, 0.95, 0.22, FR, mx, 0.68, z - 0.56, dyn)
				B(0.96, 0.95, 0.22, FR, mx, 0.68, z + 0.56, dyn)
				B(0.96, 0.22, 1.34, "#e3e8ea", mx, 1.26, z, dyn)
				var rl := C(0.17, 0.17, 0.9, "#2b3436", mx, 0.85, z, dyn, 10)
				rl.rotation.x = PI / 2
				B(0.5, 0.22, 0.95, "#3a4448", mx, 1.48, z, dyn)
				B(0.44, 0.06, 0.89, INK[j % 5], mx, 1.6, z, dyn)
				B(0.3, 0.3, 0.06, "#d9e0e3", mx, 0.75, z + 0.7, dyn)
				var scr2 := B(0.22, 0.16, 0.02, "#3fd68a", mx, 0.78, z + 0.735, dyn)
				scr2.material_override = mat("#3fd68a", 1.0, true)
				B(0.04, 0.95, 0.04, "#ffc23d", mx + 0.48, 0.68, z + 0.68, dyn)
				if ms > 0:
					var lm2 := B(0.16, 0.12, 0.16, lamp, mx - 0.3, 1.42, z - 0.5, dyn)
					lm2.material_override = mat(lamp, 1.0, true)
		if ramg.get_child_count() > 0:
			merge_deep(ramg)
			anim.pist.append({m = ramg, ph = i * 0.9, y = 0.0, kind = "ram"})
		if note:
			B(0.7, 0.4, 1, "#3a4448", x0 + 0.2, 0.4, z, dyn)
			B(0.55, 0.3, 0.75, "#f4f1e6", x0 + 0.2, 0.75, z, dyn)
		if main.has_flag("t", "t8"):
			B(0.4, 0.3, 0.4, "#ff7a1a", x0 + L - 0.6, 0.65, z - 0.65, dyn)
			var arm := B(0.15, 0.9, 0.15, "#ff7a1a", x0 + L - 0.6, 1.2, z - 0.65, dyn)
			arm.rotation.z = 0.5
			anim.pist.append({m = arm, ph = i, kind = "swing"})
		if main.has_flag("t", "t11"):
			B(0.12, 1.2, 0.12, "#3a6fd8", x0 + L - 1.6, 0.9, z - 0.5, dyn)
			B(0.12, 1.2, 0.12, "#3a6fd8", x0 + L - 1.6, 0.9, z + 0.5, dyn)
			var g11 := B(0.12, 0.12, 1.12, "#7fb0ff", x0 + L - 1.6, 1.5, z, dyn)
			g11.material_override = mat("#7fb0ff", 1.0, true)
		var wk: int = min(5, 1 + int(log(max(c, 1)) / log(2.0) / 1.4))
		var wg := Node3D.new()
		dyn.add_child(wg)
		for j in range(wk):
			var p := person("#3f6fb5" if note else "#ff7a1a", wg, true)
			p.position = Vector3(x0 + 1.5 + j * 2.2, 0.2, z + (1.0 if not note else 1.25))
		merge_deep(wg)
		anim.work.append({p = wg, x = 0.0, ph = randf() * 6.0})
	# Tresorlager wächst mit der Stufe
	var lvl: int = min(int(S["lv"]), 6)
	var wh := 1.0
	build_vault(lvl)
	for k in range(lvl):
		B(0.25, 0.25, 0.25, "#ffc23d", -14 + k * 0.45, 1.25, 11.3, dyn)
	build_racks(lvl)
	if main.has_flag("t", "t12"):
		B(6, 2.6, 5, "#d9e2e8", 21, 1.3, -6, dyn)
		B(6.2, 0.25, 5.2, "#3a6fd8", 21, 2.7, -6, dyn)
		B(1.6, 1.4, 0.1, "#5a6163", 21, 0.8, -3.45, dyn)
	# Kisten für aktive Exportaufträge (in Landesfarben)
	var oi := 0
	for o in S["orders"]:
		if o.get("active", false):
			var fl: Array = o.get("flag", ["#ffffff"])
			for k in range(3):
				B(1.1, 0.7, 1.1, fl[k % fl.size()], 9.0 + oi * 2.0, 0.5 + k * 0.72, 9.6, dyn)
			oi += 1
	build_extras()
	build_security()
	build_firebrigade()
	build_fleet()
	build_carts()
	build_admin()
	var tb := Time.get_ticks_usec()
	var nodes_before := dyn.get_child_count()
	var skip := {}
	for p in anim.pist:
		skip[p.m] = true
	for c in anim.cams:
		skip[c] = true
	if anim.gate:
		skip[anim.gate] = true
	if anim.has("vdoor"):
		merge_deep(anim.vwheel)
	merge_children(dyn, skip)
	for g in anim.guards:
		merge_deep(g.p)
	for tr in anim.trucks:
		merge_deep(tr.t)
	# alle übrigen unbeweglichen Gruppen (Figuren, Autos, Hubschrauber am Boden …) zusammenfassen
	var keep := {}
	if anim.has("carts"):
		for c in anim.carts:
			keep[c.n] = true
	if anim.has("vdoor"):
		keep[anim.vdoor] = true
	if anim.has("fire_node"):
		keep[anim.fire_node] = true
	for d in anim.drones:
		keep[d.d] = true
	for k2 in ["train", "plane", "patrol", "fork"]:
		if anim.get(k2) != null:
			keep[anim[k2]] = true
	if anim.rotor != null:
		keep[anim.rotor.get_parent()] = true
	for w in anim.work:
		keep[w.p] = true
	for g in anim.guards:
		keep[g.p] = true
	for tr in anim.trucks:
		keep[tr.t] = true
	for b in anim.belts:
		keep[b.g] = true
	for pp in anim.pist:
		keep[pp.m] = true
	for cm in anim.cams:
		keep[cm] = true
	for ch in dyn.get_children():
		if ch is Node3D and not (ch is MeshInstance3D) and not (ch is Label3D) and not keep.has(ch):
			merge_deep(ch)
	if OS.has_environment("BB_PERF"):
		print("MERGE_MS %.1f children=%d" % [(Time.get_ticks_usec() - tb) / 1000.0, nodes_before])
	build_piles()

# ---------------------------------------------------------------- Tresorgebäude mit Tresortür
func build_vault(lvl: int) -> void:
	var conc := "#4f585d"
	var steel := "#6d777c"
	var H := 2.9
	var T := 0.6
	# Boden aus Stahlplatten
	for xi in range(5):
		for zi in range(4):
			B(1.94, 0.03, 1.94, "#9aa3a8" if (xi + zi) % 2 == 0 else "#8a9398", -14 + xi * 2.0, 0.2, 4 + zi * 2.0, dyn)
	# Hintere und linke Wand: hoch, Stahlbeton mit Stahlverkleidung
	B(10.6, H, T, conc, -10, H / 2 + 0.1, 2.75, dyn)
	B(T, H, 8.9, conc, -15.3, H / 2 + 0.1, 7.0, dyn)
	B(10.0, 0.12, 0.08, "#3a4448", -10, H - 0.3, 3.08, dyn)
	B(10.0, 0.12, 0.08, "#3a4448", -10, 0.7, 3.08, dyn)
	for k in range(9):
		B(0.08, H - 0.4, 0.06, steel, -14.5 + k * 1.15, H / 2 + 0.1, 3.08, dyn)
	# Rechte Wand mit Türöffnung (Tür zeigt zum Hof)
	B(T, H, 2.9, conc, -4.7, H / 2 + 0.1, 4.0, dyn)
	B(T, H, 2.9, conc, -4.7, H / 2 + 0.1, 10.0, dyn)
	B(T, 0.6, 3.2, conc, -4.7, H - 0.2, 7.0, dyn)
	# Türrahmen aus Stahl mit Warnstreifen
	B(0.7, 0.2, 2.9, "#3a4448", -4.7, 0.22, 7.0, dyn)
	for k in range(6):
		B(0.72, 0.08, 0.25, "#ffc21a" if k % 2 == 0 else "#1b2224", -4.7, 0.34, 5.85 + k * 0.46, dyn)
	B(0.75, 2.3, 0.25, steel, -4.7, 1.25, 5.62, dyn)
	B(0.75, 2.3, 0.25, steel, -4.7, 1.25, 8.38, dyn)
	B(0.75, 0.25, 3.0, steel, -4.7, 2.42, 7.0, dyn)
	# Vordere Wand niedrig (Einblick), mit dickem Stahlabschluss
	B(10.6, 1.0, T, conc, -10, 0.6, 11.25, dyn)
	B(10.6, 0.1, T + 0.1, steel, -10, 1.15, 11.25, dyn)
	# Schild
	B(2.2, 0.5, 0.06, "#0e8a7c", -4.36, 2.75, 7.0, dyn).rotation.y = PI / 2
	# Runde Tresortür an Scharnier (öffnet nach außen)
	var hinge := Node3D.new()
	hinge.position = Vector3(-4.25, 1.22, 5.85)
	dyn.add_child(hinge)
	var door := Node3D.new()
	door.position = Vector3(0.0, 0.0, 1.15)
	hinge.add_child(door)
	var rim := C(1.2, 1.2, 0.46, "#2b3436", 0, 0, 0, door, 28)
	rim.rotation.z = PI / 2
	var body := C(1.12, 1.12, 0.5, "#c3cbcf", 0, 0, 0, door, 28)
	body.rotation.z = PI / 2
	var face := C(1.0, 1.0, 0.52, "#aeb7bc", 0, 0, 0, door, 28)
	face.rotation.z = PI / 2
	var plate := C(0.62, 0.62, 0.56, "#d9e0e3", 0, 0, 0, door, 24)
	plate.rotation.z = PI / 2
	# Riegelbolzen rundum
	for k in range(12):
		var a := k * PI / 6
		var bolt := C(0.07, 0.07, 0.34, "#e6ebee", 0, sin(a) * 1.0, cos(a) * 1.0, door, 8)
		bolt.rotation.x = PI / 2
		bolt.rotation.z = -a
		bolt.position = Vector3(0.0, sin(a) * 1.16, cos(a) * 1.16)
		bolt.rotation = Vector3(a, 0, 0)
	# Handrad mit drei Speichen
	var wheel := Node3D.new()
	wheel.position = Vector3(0.34, 0, 0)
	door.add_child(wheel)
	var hub := C(0.13, 0.13, 0.12, "#ffc23d", 0, 0, 0, wheel, 12)
	hub.rotation.z = PI / 2
	for k in range(3):
		var sp := B(0.06, 0.9, 0.07, "#ffc23d", 0, 0, 0, wheel)
		sp.rotation.x = k * PI / 3
	for k in range(12):
		var a2 := k * PI / 6
		B(0.07, 0.1, 0.24, "#ffc23d", 0.0, sin(a2) * 0.45, cos(a2) * 0.45, wheel).rotation.x = -a2
	# Scharnier
	C(0.16, 0.16, 1.6, "#5a6670", 0, 0, 0, hinge, 10)
	B(0.5, 0.18, 0.3, "#5a6670", 0.0, 0.5, 0.25, hinge)
	B(0.5, 0.18, 0.3, "#5a6670", 0.0, -0.5, 0.25, hinge)
	anim["vdoor"] = hinge
	anim["vwheel"] = wheel

# ---------------------------------------------------------------- Tresorlager mit Regalen
const RACK_Y := [0.2, 0.92, 1.64]

func rack_sections(lvl: int) -> Array:
	# [mitte_x, mitte_z, quer]  quer=true: Regal an der linken Wand
	var out := []
	for k in range(min(2 + lvl, 5)):
		out.append([-13.6 + k * 1.75, 3.75, false])
	for k in range(min(max(0, lvl - 2), 3)):
		out.append([-14.25, 5.6 + k * 1.75, true])
	return out

func floor_slots(lvl: int) -> Array:
	var out := []
	var grid := [[-11.6, 6.6], [-9.8, 6.6], [-8.0, 6.6], [-11.6, 8.5], [-9.8, 8.5], [-8.0, 8.5], [-11.6, 10.2], [-9.8, 10.2], [-8.0, 10.2]]
	for k in range(min(2 + lvl, 9)):
		out.append(Vector3(grid[k][0], 0.2, grid[k][1]))
	return out

func store_slots(lvl: int) -> Array:
	var out := floor_slots(lvl)
	for sec in rack_sections(lvl):
		for y in RACK_Y:
			if sec[2]:
				out.append(Vector3(sec[0], y + 0.08, sec[1]))
			else:
				out.append(Vector3(sec[0], y + 0.08, sec[1]))
	return out

func build_racks(lvl: int) -> void:
	for sec in rack_sections(lvl):
		var cx: float = sec[0]
		var cz: float = sec[1]
		var quer: bool = sec[2]
		var w := 1.65
		var d := 1.0
		for ox in [-w / 2, w / 2]:
			for oz in [-d / 2, d / 2]:
				var px: float = cx + (oz if quer else ox)
				var pz: float = cz + (ox if quer else oz)
				B(0.08, 2.25, 0.08, "#2f5fbf", px, 1.2, pz, dyn)
		for y in RACK_Y:
			for oz in [-d / 2, d / 2]:
				if quer:
					B(0.07, 0.09, w, "#ff7a1a", cx + oz, y + 0.02, cz, dyn)
				else:
					B(w, 0.09, 0.07, "#ff7a1a", cx, y + 0.02, cz + oz, dyn)
	# Bodenmarkierungen für Stellplätze
	for fs in floor_slots(lvl):
		B(1.35, 0.02, 1.15, "#ffd21a", fs.x, 0.2, fs.z, dyn)
		B(1.2, 0.03, 1.0, "#d8c79a", fs.x, 0.21, fs.z, dyn)
	# Gabelstapler
	var fk := Node3D.new()
	dyn.add_child(fk)
	B(1.0, 0.5, 0.7, "#ffc21a", 0, 0.45, 0, fk)
	B(0.5, 0.45, 0.6, "#2b3436", -0.15, 0.92, 0, fk)
	B(0.06, 1.5, 0.06, "#3a4448", 0.55, 0.9, -0.22, fk)
	B(0.06, 1.5, 0.06, "#3a4448", 0.55, 0.9, 0.22, fk)
	B(0.7, 0.05, 0.1, "#3a4448", 0.95, 0.3, -0.18, fk)
	B(0.7, 0.05, 0.1, "#3a4448", 0.95, 0.3, 0.18, fk)
	B(0.8, 0.12, 0.8, "#3a2a1a", -0.45, 0.25, 0, fk)
	for wpos in [[-0.3, 0.36], [0.3, 0.36], [-0.3, -0.36], [0.3, -0.36]]:
		var wm := C(0.17, 0.17, 0.12, "#1b2224", wpos[0], 0.2, wpos[1], fk, 8)
		wm.rotation.x = PI / 2
	person("#ff7a1a", fk, true).position = Vector3(-0.15, 0.55, 0)
	merge_deep(fk)
	fk.position = Vector3(-10, 0.13, 5.0)
	anim["fork"] = fk

## Eine Palette mit Ware: Banknotenbündel in Folie oder Münzkisten
func pallet(pos: Vector3, kind: int, p: Node3D) -> void:
	B(1.15, 0.12, 0.95, "#a5814f", pos.x, pos.y + 0.06, pos.z, p)
	B(1.15, 0.04, 0.12, "#7d5f37", pos.x, pos.y + 0.0, pos.z - 0.38, p)
	B(1.15, 0.04, 0.12, "#7d5f37", pos.x, pos.y + 0.0, pos.z + 0.38, p)
	var notes := ["#9aa3a8", "#d96a6a", "#5b8fd0", "#e09a3a", "#6fae8f", "#d9c25a"]
	if kind % 3 == 2:
		# Münzkisten mit Münzrollen
		for k in range(4):
			var bx := pos.x - 0.27 + (k % 2) * 0.54
			var bz := pos.z - 0.22 + int(k / 2) * 0.44
			B(0.5, 0.32, 0.4, "#5a6670", bx, pos.y + 0.28, bz, p)
			for q in range(3):
				var roll := C(0.06, 0.06, 0.42, "#e2bf55" if q != 1 else "#c8763f", bx - 0.13 + q * 0.13, pos.y + 0.47, bz, p, 8)
				roll.rotation.z = PI / 2
	else:
		# Banknotenbündel, gestapelt und in Folie
		var col: String = notes[kind % notes.size()]
		for lay in range(3):
			for k in range(4):
				var bx2 := pos.x - 0.27 + (k % 2) * 0.54
				var bz2 := pos.z - 0.22 + int(k / 2) * 0.44
				B(0.5, 0.15, 0.4, col, bx2, pos.y + 0.2 + lay * 0.16, bz2, p)
				B(0.12, 0.152, 0.402, "#f4f1e6", bx2, pos.y + 0.2 + lay * 0.16, bz2, p)
		B(1.08, 0.04, 0.06, "#ffffff", pos.x, pos.y + 0.54, pos.z, p)

## Elektro-Wagen bringen das hergestellte Geld von den Hallen zum Tresor
const CART_COIN := [[-2.4, 0.2], [-2.4, 2.3], [-2.6, 7.0], [-3.9, 7.0]]
const CART_NOTE := [[2.6, 1.6], [2.6, 2.3], [-2.4, 2.3], [-2.6, 7.0], [-3.9, 7.0]]

func cart_count() -> int:
	var p: float = main.prod()
	if p <= 0.0:
		return 0
	return clamp(1 + int(log(p + 1.0) / log(10.0)), 1, 6)

func build_carts() -> void:
	anim["carts"] = []
	var n := cart_count()
	var has_note := false
	for l in main.LINES:
		if l.get("note", false) and cnt("l", l.id) > 0:
			has_note = true
	for j in range(n):
		var note := has_note and j % 2 == 1
		var cart := Node3D.new()
		dyn.add_child(cart)
		var body := Node3D.new()
		cart.add_child(body)
		B(1.0, 0.12, 0.6, "#3a4448", 0, 0.32, 0, body)
		B(0.3, 0.42, 0.56, "#0e8a7c" if not note else "#3d6fb0", 0.42, 0.5, 0, body)
		B(0.05, 0.05, 0.56, "#d9e0e3", 0.6, 0.62, 0, body)
		for w in [[-0.32, 0.3], [0.32, 0.3], [-0.32, -0.3], [0.32, -0.3]]:
			var wm := C(0.11, 0.11, 0.08, "#141414", w[0], 0.14, w[1], body, 8)
			wm.rotation.x = PI / 2
		var dr := person("#ff7a1a" if not note else "#3f6fb5", body, true)
		dr.position = Vector3(0.42, 0.25, 0)
		dr.scale = Vector3(0.8, 0.8, 0.8)
		merge_deep(body)
		var cargo := Node3D.new()
		cart.add_child(cargo)
		if note:
			for k in range(4):
				B(0.28, 0.14, 0.22, ["#5b8fd0", "#6fae8f", "#e09a3a", "#9aa3a8"][k], -0.32 + (k % 2) * 0.3, 0.46 + int(k / 2) * 0.15, 0.0, cargo)
		else:
			for k in range(3):
				var sk := sphere(0.16, "#c9b48a", -0.38 + k * 0.26, 0.52, 0.0, cargo)
				sk.scale = Vector3(1, 1.2, 1)
		merge_deep(cargo)
		anim.carts.append({n = cart, cargo = cargo, path = CART_NOTE if note else CART_COIN, ph = float(j) / max(1, n)})

func path_pos(path: Array, u: float) -> Array:
	var total := 0.0
	var ls := []
	for i in range(path.size() - 1):
		var l := Vector2(path[i + 1][0] - path[i][0], path[i + 1][1] - path[i][1]).length()
		ls.append(l)
		total += l
	var d := u * total
	for i in range(ls.size()):
		if d <= ls[i]:
			var a: Array = path[i]
			var b: Array = path[i + 1]
			var f: float = d / ls[i]
			return [a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f, atan2(-(b[1] - a[1]), b[0] - a[0])]
		d -= ls[i]
	var e: Array = path[path.size() - 1]
	return [e[0], e[1], 0.0]

func build_extras() -> void:
	var S: Dictionary = main.S
	# Goldreserve neben dem Tresor
	var gold: int = int(S["gold"])
	if gold > 0:
		B(5, 0.12, 3, "#3a4448", -13.5, 0.15, 13.6, dyn)
		B(5, 0.9, 0.2, "#55626a", -13.5, 0.55, 12.2, dyn)
		B(5, 0.9, 0.2, "#55626a", -13.5, 0.55, 15.0, dyn)
		B(0.2, 0.9, 3, "#55626a", -16.0, 0.55, 13.6, dyn)
		for i in range(min(gold, 60)):
			var gx := -15.4 + (i % 8) * 0.52
			var gz := 12.8 + int(i / 8) % 4 * 0.6
			var gy := 0.33 + int(i / 32) * 0.2
			var bar := B(0.46, 0.18, 0.26, "#ffcf33", gx, gy, gz, dyn)
			bar.material_override = mat("#ffcf33", 1.0, true)
	# Schredder-Halle
	var sl: int = int(S["shred"])
	if sl > 0:
		B(3.4, 1.4 + sl * 0.08, 2.2, "#8a5a9e", 3.2, 0.85, 3.9, dyn)
		B(3.6, 0.2, 2.4, "#5e3a70", 3.2, 1.6 + sl * 0.08, 3.9, dyn)
		B(1.0, 0.8, 0.6, "#2b3436", 3.2, 0.6, 5.2, dyn)
		facade(3.2, 3.9, 3.4, 2.2, 1.4 + sl * 0.08, dyn)
		var sp_l := Label3D.new()
		sp_l.text = "Schredder %d" % sl
		sp_l.font_size = 64
		sp_l.pixel_size = 0.011
		sp_l.outline_size = 18
		sp_l.outline_modulate = Color("#3a1f48")
		sp_l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sp_l.no_depth_test = true
		sp_l.position = Vector3(3.2, 2.6 + sl * 0.08, 3.9)
		dyn.add_child(sp_l)
		for k in range(min(sl, 6)):
			var sch := sphere(0.18, "#c9e0c0", 2.2 + k * 0.35, 0.3, 5.4, dyn)
			sch.scale = Vector3(1, 0.6, 1)
	# Museum (außerhalb des Zauns, links)
	if int(S["museum"]) > 0:
		# Vorplatz mit Pflaster, Bänken und Laternen
		B(9.5, 0.06, 8.0, "#9a958a", -31.0, 0.08, -8.0, dyn)
		for k in range(5):
			B(9.5, 0.065, 0.05, "#878276", -31.0, 0.085, -11.6 + k * 1.8, dyn)
		# Sockel mit Stufen
		B(6.4, 0.25, 5.2, "#b5aa90", -31.3, 0.2, -8.0, dyn)
		B(0.5, 0.15, 4.0, "#b5aa90", -27.85, 0.15, -8.0, dyn)
		B(0.5, 0.3, 4.0, "#b5aa90", -28.1, 0.22, -8.0, dyn)
		# Baukörper in Sandstein mit hohen Fenstern
		B(4.6, 2.7, 4.6, "#bfae8b", -31.9, 1.65, -8.0, dyn)
		for k in range(3):
			B(0.6, 1.4, 0.05, "#3a4a55", -33.3 + k * 1.4, 1.6, -10.32, dyn)
			B(0.6, 1.4, 0.05, "#3a4a55", -33.3 + k * 1.4, 1.6, -5.68, dyn)
		B(0.06, 1.9, 1.2, "#5b3e28", -29.58, 1.25, -8.0, dyn)
		# Säulenhalle
		for k in range(6):
			var zc := -10.3 + k * 0.92
			C(0.17, 0.2, 2.5, "#d8cdb3", -28.5, 1.6, zc, dyn, 10)
			B(0.46, 0.12, 0.46, "#c9bd9f", -28.5, 0.41, zc, dyn)
			B(0.46, 0.12, 0.46, "#c9bd9f", -28.5, 2.9, zc, dyn)
		B(6.6, 0.4, 5.4, "#c7b998", -31.2, 3.15, -8.0, dyn)
		B(6.7, 0.1, 5.5, "#a99c80", -31.2, 3.38, -8.0, dyn)
		var roof := C(0.0, 3.7, 1.1, "#4a7564", -31.2, 3.98, -8.0, dyn, 4)
		roof.rotation.y = PI / 4
		roof.scale = Vector3(1.0, 1.0, 0.82)
		# Fahnen, Bänke, Laternen
		for zf in [-11.4, -4.6]:
			C(0.04, 0.04, 3.2, "#c9cdd0", -27.0, 1.7, zf, dyn, 6)
			B(0.03, 0.55, 0.9, "#0e3a8a", -27.0, 2.95, zf + 0.47, dyn)
		for zb in [-10.6, -5.4]:
			B(0.4, 0.06, 1.3, "#6b4a2e", -26.6, 0.48, zb, dyn)
			B(0.08, 0.35, 1.3, "#6b4a2e", -26.42, 0.7, zb, dyn)
			B(0.36, 0.4, 0.06, "#2b3033", -26.6, 0.27, zb - 0.55, dyn)
			B(0.36, 0.4, 0.06, "#2b3033", -26.6, 0.27, zb + 0.55, dyn)
		for zl in [-12.0, -4.0]:
			C(0.05, 0.07, 2.4, "#2b3033", -34.8, 1.25, zl, dyn, 6)
			sphere(0.16, "#fff2c0", -34.8, 2.55, zl, dyn, 8)
		var ml := Label3D.new()
		ml.text = "Museum · %d" % (int(S["rep"]) + S["coins"].size())
		ml.font_size = 80
		ml.pixel_size = 0.011
		ml.outline_size = 20
		ml.outline_modulate = Color("#0a4f4a")
		ml.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		ml.no_depth_test = true
		ml.position = Vector3(-31, 5.2, -8)
		dyn.add_child(ml)
	# Zweigwerke (in der Ferne)
	var spots := {"mainz": [45, -28, "#a8503a"], "leipzig": [51, -7.5, "#0e8a7c"], "muenchen": [49, 6.5, "#3d6fb0"], "hamburg": [57, 24, "#8a5a9e"]}
	var names := {"mainz": "Mainz", "leipzig": "Leipzig", "muenchen": "München", "hamburg": "Hamburg"}
	for id in spots.keys():
		if S["sites"].get(id, false):
			var sp2: Array = spots[id]
			B(6, 0.12, 5, "#8e9a9e", sp2[0], 0.08, sp2[1], dyn)
			road(sp2[0], sp2[1] + (2.5 if sp2[1] < 12.8 else -2.5), sp2[0], 12.8, dyn)
			B(4.5, 2.0, 3.2, sp2[2], sp2[0], 1.1, sp2[1], dyn)
			B(4.7, 0.25, 3.4, "#2b3436", sp2[0], 2.2, sp2[1], dyn)
			facade(sp2[0], sp2[1], 4.5, 3.2, 2.0, dyn)
			for k in range(4):
				var cc := vehicle("v1")
				cc.rotation.y = PI / 2
				cc.position = Vector3(sp2[0] - 2.4 + k * 1.2, 0.05, sp2[1] - 2.0)
				dyn.add_child(cc)
			C(0.3, 0.4, 3.0, "#9aa3a8", sp2[0] + 1.6, 2.8, sp2[1] - 0.8, dyn, 8)
			var sl3 := Label3D.new()
			sl3.text = names[id]
			sl3.font_size = 96
			sl3.pixel_size = 0.011
			sl3.outline_size = 24
			sl3.outline_modulate = Color("#0a4f4a")
			sl3.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			sl3.no_depth_test = true
			sl3.position = Vector3(sp2[0], 4.6, sp2[1])
			dyn.add_child(sl3)
	# Werksleiter mit Krawatte
	var mpos := {"coin": [-8.0, 1.8], "note": [8.0, 1.8], "fleet": [4.0, 10.6], "sec": [13.5, 14.8]}
	for id in mpos.keys():
		if S["mgr"].get(id, false):
			var mp: Array = mpos[id]
			var pm := person("#f4f5f2", dyn, false, "manager")
			B(0.08, 0.32, 0.02, "#c8102e", 0, 0.6, 0.15, pm)
			B(0.42, 0.2, 0.3, "#2b3436", 0, 0.22, 0, pm)
			pm.position = Vector3(mp[0], 0.15, mp[1])

func wall_tier() -> int:
	var g3 := cnt("g", "g3")
	if g3 >= 30:
		return 4
	if g3 >= 15:
		return 3
	if g3 >= 5:
		return 2
	if g3 >= 1:
		return 1
	return 0

## Mauer-Abschnitte (Start, Ende) rund ums Werk, mit Lücke für das Tor
const WALL_SEGS := [[-17.6, -15.6, 17.6, -15.6], [-17.6, -15.6, -17.6, 15.6], [-17.6, 15.6, 0.2, 15.6], [3.8, 15.6, 8.2, 15.6], [11.8, 15.6, 17.6, 15.6], [17.6, -15.6, 17.6, 11.2], [17.6, 14.4, 17.6, 15.6]]

func wall_piece(x1: float, z1: float, x2: float, z2: float, h: float, th: float, col: String, y0 := 0.1) -> void:
	var dx := x2 - x1
	var dz := z2 - z1
	var L: float = max(abs(dx), abs(dz))
	if abs(dx) > abs(dz):
		B(L + th, h, th, col, (x1 + x2) / 2.0, y0 + h / 2.0, z1, dyn)
	else:
		B(th, h, L + th, col, x1, y0 + h / 2.0, (z1 + z2) / 2.0, dyn)

func build_wall(wt: int) -> void:
	for sg in WALL_SEGS:
		var x1: float = sg[0]
		var z1: float = sg[1]
		var x2: float = sg[2]
		var z2: float = sg[3]
		var L: float = max(abs(x2 - x1), abs(z2 - z1))
		var horiz: bool = abs(x2 - x1) > abs(z2 - z1)
		if wt == 1:
			# Maschendrahtzaun: Pfosten + Drähte
			var k := 0.0
			while k <= L + 0.01:
				var px: float = x1 + (k if horiz else 0.0)
				var pz: float = z1 + (0.0 if horiz else k)
				C(0.05, 0.05, 1.5, "#7d878c", px, 0.85, pz, dyn, 6)
				k += 2.5
			for y in [0.4, 0.8, 1.2, 1.55]:
				wall_piece(x1, z1, x2, z2, 0.03, 0.03, "#aab3b8", y)
		else:
			var h := 1.6 if wt == 2 else 2.4
			var col := "#c9c2b4" if wt == 2 else "#a9a397"
			wall_piece(x1, z1, x2, z2, h, 0.35, col)
			wall_piece(x1, z1, x2, z2, 0.12, 0.45, "#8a8478", h + 0.1)
			var k2 := 0.0
			while k2 <= L + 0.01:
				var qx: float = x1 + (k2 if horiz else 0.0)
				var qz: float = z1 + (0.0 if horiz else k2)
				B(0.5, h + 0.15, 0.5, "#b3ad9f", qx, (h + 0.15) / 2.0 + 0.1, qz, dyn)
				k2 += 4.0
			if wt >= 3:
				# Stacheldraht oben
				var bw := C(0.12, 0.12, L, "#9aa3a8", (x1 + x2) / 2.0, h + 0.35, (z1 + z2) / 2.0, dyn, 6)
				if horiz:
					bw.rotation.z = PI / 2
				else:
					bw.rotation.x = PI / 2
			if wt >= 4:
				wall_piece(x1, z1, x2, z2, 0.15, 0.37, "#c8102e", h * 0.5)
	# Tor
	anim.gate = B(0.3, 1.6 if wt >= 2 else 1.3, 3.2, "#3d4a52", 17.6, 0.9, 12.8, dyn)
	if wt >= 2:
		B(0.6, 2.6, 0.6, "#8a8478", 17.6, 1.4, 10.9, dyn)
		B(0.6, 2.6, 0.6, "#8a8478", 17.6, 1.4, 14.7, dyn)
	# Ausfahrten Süd (mittel und schwer) mit Schranken
	if wt >= 1:
		for gx in [2.0, 10.0]:
			for o in [-1.8, 1.8]:
				B(0.5, 2.0 if wt >= 2 else 1.5, 0.5, "#8a8478", gx + o, 1.1, 15.6, dyn)
			B(3.2, 0.08, 0.08, "#c8102e", gx, 1.0, 15.9, dyn)
			B(0.3, 0.9, 0.3, "#e9e4d8", gx - 2.4, 0.55, 16.1, dyn)
	# Wachtürme an den Ecken
	if wt >= 3:
		for c in [[-17.6, -15.6], [17.6, -15.6], [-17.6, 15.6], [17.6, 15.6]]:
			for o in [[-0.5, -0.5], [0.5, -0.5], [-0.5, 0.5], [0.5, 0.5]]:
				B(0.14, 4.0, 0.14, "#5a6163", c[0] + o[0], 2.1, c[1] + o[1], dyn)
			B(1.6, 0.12, 1.6, "#5a6163", c[0], 4.1, c[1], dyn)
			B(1.5, 0.9, 1.5, "#d9d2c2", c[0], 4.6, c[1], dyn)
			B(1.3, 0.35, 1.52, "#2a3a40", c[0], 4.75, c[1], dyn)
			B(1.8, 0.12, 1.8, "#c8102e", c[0], 5.12, c[1], dyn)
			if wt >= 4:
				var sl := B(0.35, 0.3, 0.35, "#fff2c0", c[0], 5.35, c[1], dyn)
				sl.material_override = lamp_mat

# ---------------------------------------------------------------- Verwaltungsgebäude
const ROOM_FLOOR := {"lobby": "#d8cfc0", "chef": "#7a5a3a", "hr": "#c9d6e3", "umk": "#b9c4c9", "putz": "#a9b8a3", "kantine": "#e8d9b0", "pause": "#c7b9d9", "leit": "#5a6670", "buch": "#d3d9cf"}

func desk(x: float, z: float, p: Node3D, pc := true) -> void:
	B(0.9, 0.06, 0.5, "#8a6a4a", x, 0.62, z, p)
	B(0.06, 0.5, 0.06, "#5a4a3a", x - 0.4, 0.36, z - 0.2, p)
	B(0.06, 0.5, 0.06, "#5a4a3a", x + 0.4, 0.36, z - 0.2, p)
	B(0.06, 0.5, 0.06, "#5a4a3a", x - 0.4, 0.36, z + 0.2, p)
	B(0.06, 0.5, 0.06, "#5a4a3a", x + 0.4, 0.36, z + 0.2, p)
	if pc:
		B(0.36, 0.24, 0.03, "#1a1a1a", x, 0.8, z - 0.15, p)
		var scr := B(0.32, 0.2, 0.01, "#4ab0ff", x, 0.8, z - 0.133, p)
		scr.material_override = mat("#4ab0ff", 1.0, true)
	B(0.34, 0.06, 0.34, "#2b3436", x, 0.42, z + 0.45, p)
	B(0.34, 0.36, 0.06, "#2b3436", x, 0.62, z + 0.6, p)

func plant(x: float, z: float, p: Node3D) -> void:
	C(0.13, 0.1, 0.25, "#a8744f", x, 0.33, z, p, 8)
	var lf := sphere(0.22, "#3b8f3a", x, 0.62, z, p)
	lf.scale = Vector3(1, 1.3, 1)

func build_admin() -> void:
	var S: Dictionary = main.S
	var z0 := -32.5
	var depth := 7.0
	var w := 3.5
	var x0 := -15.75
	# Gesamtgebäude: Bodenplatte, Rückwand mit Fenstern, Dachkante
	B(9 * w + 0.6, 0.18, depth + 0.6, "#8e9a9e", 0.0, 0.1, z0, dyn)
	B(9 * w + 0.6, 2.4, 0.3, "#e9e4d8", 0.0, 1.3, z0 - depth / 2.0, dyn)
	B(9 * w + 0.6, 0.25, 0.4, "#0e8a7c", 0.0, 2.55, z0 - depth / 2.0, dyn)
	for k in range(18):
		B(0.9, 0.7, 0.04, "#2c3f4d", x0 + 0.9 + k * 1.75, 1.55, z0 - depth / 2.0 + 0.17, dyn)
	B(0.3, 1.2, depth, "#e9e4d8", x0 - 0.15, 0.7, z0, dyn)
	B(0.3, 1.2, depth, "#e9e4d8", x0 + 9 * w + 0.15, 0.7, z0, dyn)
	for k in range(8):
		B(0.08, 0.02, 1.6, "#ffffff", -14.0 + k * 4.0, 0.12, z0 + depth / 2.0 + 1.6, dyn)
	B(9 * w + 0.6, 0.05, 3.4, "#454b4e", 0.0, 0.1, z0 + depth / 2.0 + 1.6, dyn)
	var civ := ["#c8102e", "#e8ecee", "#2a2f3a", "#3d6fb0", "#e2b53c", "#6fae8f"]
	for k in range(6):
		var car := police_car(civ[k], civ[k], false, false)
		car.rotation.y = PI / 2
		car.position = Vector3(-12.0 + k * 4.4, 0.0, z0 + depth / 2.0 + 1.6)
		dyn.add_child(car)
		merge_deep(car)
	var vl := Label3D.new()
	vl.text = "Verwaltung"
	vl.font_size = 120
	vl.pixel_size = 0.011
	vl.outline_size = 28
	vl.outline_modulate = Color("#0a4f4a")
	vl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	vl.no_depth_test = true
	vl.position = Vector3(0.0, 4.0, z0 - depth / 2.0)
	dyn.add_child(vl)
	var i := 0
	for r in main.ROOMS:
		var id: String = r.id
		var lv: int = int(S["rooms"].get(id, 0))
		var cx := x0 + w / 2.0 + i * w
		i += 1
		# Trennwand
		if i < 9:
			B(0.12, 0.7, depth, "#d9d2c2", cx + w / 2.0, 0.55, z0, dyn)
		if lv == 0:
			B(w - 0.4, 0.04, depth - 0.6, "#6f7a7e", cx, 0.2, z0, dyn)
			B(w - 0.2, 0.03, 0.08, "#ffd21a", cx, 0.21, z0 + depth / 2.0 - 0.3, dyn)
			B(w - 0.2, 0.03, 0.08, "#ffd21a", cx, 0.21, z0 - depth / 2.0 + 0.5, dyn)
			continue
		B(w - 0.15, 0.04, depth - 0.4, ROOM_FLOOR.get(id, "#cccccc"), cx, 0.21, z0, dyn)
		var rl := Label3D.new()
		rl.text = "%s %d" % [r.n, lv]
		rl.font_size = 44
		rl.pixel_size = 0.011
		rl.outline_size = 12
		rl.outline_modulate = Color("#13262a")
		rl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		rl.no_depth_test = true
		rl.position = Vector3(cx, 2.2, z0 + 1.5)
		dyn.add_child(rl)
		match id:
			"lobby":
				B(1.8, 0.7, 0.5, "#0e8a7c", cx, 0.55, z0 - 1.0, dyn)
				B(1.9, 0.06, 0.6, "#e9e4d8", cx, 0.92, z0 - 1.0, dyn)
				B(2.0, 0.02, 2.4, "#c8102e", cx, 0.24, z0 + 1.2, dyn)
				for k in range(min(lv, 4)):
					plant(cx - 1.3 + (k % 2) * 2.6, z0 - 2.6 + int(k / 2) * 4.6, dyn)
				if lv >= 2:
					B(1.2, 0.35, 0.5, "#2a3a5a", cx, 0.4, z0 + 2.6, dyn)
				person("#0e8a7c", dyn).position = Vector3(cx, 0.22, z0 - 1.5)
			"chef":
				B(1.6, 0.08, 0.8, "#4a2f1a", cx, 0.72, z0 - 1.2, dyn)
				B(1.6, 0.6, 0.08, "#3a2412", cx, 0.42, z0 - 0.82, dyn)
				B(0.5, 0.75, 0.5, "#111111", cx, 0.58, z0 - 2.0, dyn)
				B(1.2, 1.8, 0.35, "#5a3a22", cx - 1.0, 1.1, z0 - 3.1, dyn)
				for k in range(4):
					B(1.1, 0.25, 0.3, ["#c8102e", "#3d6fb0", "#e2b53c", "#3b8f3a"][k], cx - 1.0, 0.45 + k * 0.4, z0 - 3.05, dyn)
				B(2.2, 0.02, 2.0, "#8a1a2a", cx, 0.24, z0 + 0.8, dyn)
				plant(cx + 1.3, z0 - 2.8, dyn)
				if lv >= 3:
					B(1.4, 0.4, 0.6, "#2a2f3a", cx, 0.42, z0 + 2.4, dyn)
				if lv >= 5:
					var tre := B(0.6, 0.6, 0.6, "#ffc23d", cx + 1.2, 0.5, z0 + 2.6, dyn)
					tre.material_override = mat("#ffc23d", 1.0, true)
				person("#f4f5f2", dyn, false, "manager").position = Vector3(cx, 0.22, z0 - 2.0)
			"hr", "buch":
				for k in range(min(lv + 1, 6)):
					desk(cx - 0.8 + (k % 2) * 1.6, z0 - 2.4 + int(k / 2) * 1.8, dyn)
				if id == "buch":
					for k in range(lv):
						B(0.5, 1.2, 0.5, "#9aa3a8", cx + 1.4, 0.8, z0 - 3.0 + k * 0.55, dyn)
				var nv: int = min(int(S["staff"].get("verw", 0)), lv + 1)
				for k in range(nv if id == "hr" else min(lv, 3)):
					person("#3d6fb0", dyn, false, "manager").position = Vector3(cx - 0.8 + (k % 2) * 1.6, 0.22, z0 - 1.95 + int(k / 2) * 1.8)
			"umk":
				for k in range(min(lv * 3, 15)):
					var lx := cx - 1.4 + (k % 5) * 0.7
					var lz := z0 - 3.0 + int(k / 5) * 2.2
					B(0.6, 1.6, 0.45, "#7f8f99" if k % 2 == 0 else "#6f7f89", lx, 1.0, lz, dyn)
					B(0.05, 0.12, 0.02, "#1a1a1a", lx + 0.2, 1.1, lz + 0.24, dyn)
				B(2.4, 0.12, 0.4, "#a5814f", cx, 0.45, z0 + 2.4, dyn)
			"putz":
				B(1.4, 1.5, 0.4, "#9aa3a8", cx - 0.9, 0.95, z0 - 3.0, dyn)
				for k in range(4):
					C(0.13, 0.11, 0.25, ["#ffd21a", "#3d6fb0", "#c8102e", "#3b8f3a"][k], cx - 1.3 + k * 0.28, 0.85, z0 - 2.9, dyn, 8)
				for k in range(min(lv, 4)):
					var ccx := cx - 0.8 + (k % 2) * 1.6
					var ccz := z0 + int(k / 2) * 1.8 - 0.6
					B(0.7, 0.5, 0.45, "#5a4a8a", ccx, 0.5, ccz, dyn)
					C(0.12, 0.12, 0.3, "#ffd21a", ccx - 0.2, 0.9, ccz, dyn, 8)
				var np: int = min(int(S["staff"].get("putz", 0)), 4)
				for k in range(np):
					person("#7a4a9a", dyn).position = Vector3(cx - 1.0 + k * 0.7, 0.22, z0 + 2.4)
			"kantine":
				B(2.6, 0.8, 0.5, "#c9d2d5", cx, 0.6, z0 - 3.0, dyn)
				for k in range(min(lv * 2, 8)):
					var tx2 := cx - 0.8 + (k % 2) * 1.6
					var tz2 := z0 - 1.6 + int(k / 2) * 1.3
					C(0.4, 0.4, 0.06, "#e9e4d8", tx2, 0.66, tz2, dyn, 12)
					C(0.05, 0.05, 0.42, "#5a6163", tx2, 0.42, tz2, dyn, 6)
					B(0.25, 0.3, 0.25, "#c8102e", tx2 - 0.45, 0.38, tz2, dyn)
					B(0.25, 0.3, 0.25, "#c8102e", tx2 + 0.45, 0.38, tz2, dyn)
				for k in range(min(lv, 4)):
					person("#ff7a1a", dyn, true).position = Vector3(cx - 1.25 + (k % 2) * 2.5, 0.22, z0 - 1.6 + int(k / 2) * 1.3)
			"pause":
				B(1.8, 0.45, 0.7, "#4a5a8a", cx, 0.45, z0 - 2.6, dyn)
				B(1.8, 0.5, 0.2, "#3a4a7a", cx, 0.75, z0 - 3.0, dyn)
				B(0.9, 0.06, 0.5, "#a5814f", cx, 0.5, z0 - 1.6, dyn)
				B(0.4, 0.7, 0.4, "#2b3436", cx + 1.3, 0.6, z0 + 0.5, dyn)
				if lv >= 2:
					var tv := B(1.4, 0.8, 0.06, "#111111", cx, 1.4, z0 - 3.3, dyn)
					var tvs := B(1.3, 0.7, 0.01, "#4ab0ff", cx, 1.4, z0 - 3.26, dyn)
					tvs.material_override = mat("#4ab0ff", 1.0, true)
				for k in range(min(lv, 3)):
					plant(cx - 1.3, z0 - 0.5 + k * 1.2, dyn)
			"leit":
				for k in range(min(lv * 2, 10)):
					var mx2 := cx - 1.3 + (k % 5) * 0.65
					var my2 := 0.9 + int(k / 5) * 0.55
					B(0.6, 0.5, 0.06, "#111111", mx2, my2, z0 - 3.2, dyn)
					var ms2 := B(0.54, 0.44, 0.01, "#3fd68a" if k % 3 else "#4ab0ff", mx2, my2, z0 - 3.16, dyn)
					ms2.material_override = mat("#3fd68a" if k % 3 else "#4ab0ff", 1.0, true)
				desk(cx - 0.7, z0 - 1.5, dyn)
				desk(cx + 0.7, z0 - 1.5, dyn)
				for k in range(min(lv, 2)):
					person("#1f3a5f", dyn, false, "guard").position = Vector3(cx - 0.7 + k * 1.4, 0.22, z0 - 1.05)

const ADMIN_SIG := 1

# ---------------------------------------------------------------- Polizeiwache
func police_tier() -> int:
	var n := cnt("g", "g6")
	if n >= 10:
		return 4
	if n >= 6:
		return 3
	if n >= 3:
		return 2
	if n >= 1:
		return 1
	return 0

var police_mat: StandardMaterial3D

func police_light() -> StandardMaterial3D:
	if police_mat == null:
		police_mat = StandardMaterial3D.new()
		police_mat.albedo_color = Color("#2f6bff")
		police_mat.emission_enabled = true
		police_mat.emission = Color("#2f6bff")
		police_mat.emission_energy_multiplier = 0.4
	return police_mat

## Realistischer Streifenwagen: Karosserie, Kabine mit Scheiben, Motorhaube, Lichter, Lichtbalken
func police_car(body_col := "#e8ecee", band_col := "#1f4fbf", van := false, lights := true) -> Node3D:
	var c := Node3D.new()
	var L := 2.4 if van else 2.0
	var cabin_h := 0.55 if van else 0.38
	# Fahrgestell und Karosserie
	B(L, 0.12, 0.92, "#1b1f22", 0, 0.2, 0, c)
	B(L, 0.36, 0.9, body_col, 0, 0.42, 0, c)
	# Zierstreifen (Polizei-Design)
	B(L + 0.01, 0.12, 0.91, band_col, 0, 0.45, 0, c)
	if lights:
		B(L * 0.5, 0.04, 0.912, "#ffd21a" if not van else band_col, -0.1, 0.53, 0, c)
	# Kabine mit Scheiben
	var cab_l := L * (0.7 if van else 0.5)
	var cab_x := -0.15 if van else -0.08
	B(cab_l, cabin_h, 0.84, body_col, cab_x, 0.6 + cabin_h / 2.0, 0, c)
	B(cab_l + 0.02, cabin_h * 0.62, 0.86, "#1e2a33", cab_x, 0.62 + cabin_h * 0.45, 0, c)
	B(0.05, cabin_h * 0.6, 0.78, "#2c3f4d", cab_x + cab_l / 2.0 + 0.01, 0.62 + cabin_h * 0.45, 0, c)
	# Dach und Lichtbalken
	B(cab_l, 0.04, 0.84, body_col, cab_x, 0.6 + cabin_h + 0.02, 0, c)
	if lights:
		var bar := B(0.24, 0.08, 0.7, "#2f6bff", cab_x, 0.66 + cabin_h, 0, c)
		bar.material_override = police_light()
	# Front/Heck: Scheinwerfer, Rücklichter, Stoßstangen
	var hl := L / 2.0
	for zz in [-0.3, 0.3]:
		var h1 := B(0.03, 0.08, 0.18, "#fffbe0", hl + 0.005, 0.45, zz, c)
		h1.material_override = mat("#fffbe0", 1.0, true)
		var h2 := B(0.03, 0.08, 0.16, "#ff2030", -hl - 0.005, 0.45, zz, c)
		h2.material_override = mat("#ff2030", 1.0, true)
	B(0.06, 0.1, 0.94, "#2b3033", hl, 0.27, 0, c)
	B(0.06, 0.1, 0.94, "#2b3033", -hl, 0.27, 0, c)
	# Räder mit Felgen
	for w in [[-L * 0.32, 0.46], [L * 0.32, 0.46], [-L * 0.32, -0.46], [L * 0.32, -0.46]]:
		var tire := C(0.19, 0.19, 0.14, "#141414", w[0], 0.19, w[1], c, 12)
		tire.rotation.x = PI / 2
		var rim := C(0.11, 0.11, 0.15, "#b8c0c4", w[0], 0.19, w[1], c, 10)
		rim.rotation.x = PI / 2
	# Seitenspiegel
	B(0.08, 0.06, 0.06, "#1b1f22", cab_x + cab_l / 2.0 - 0.05, 0.75, 0.48, c)
	B(0.08, 0.06, 0.06, "#1b1f22", cab_x + cab_l / 2.0 - 0.05, 0.75, -0.48, c)
	return c

func police_label(txt: String, pos: Vector3, size := 72) -> void:
	var l := Label3D.new()
	l.text = txt
	l.font_size = size
	l.pixel_size = 0.011
	l.outline_size = 20
	l.modulate = Color("#ffffff")
	l.outline_modulate = Color("#1f3a66")
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = pos
	dyn.add_child(l)

func build_police(pt: int) -> void:
	# Grundstück neben dem Werk (rechts, nördlich der Straße)
	var gx := POL_X
	var gz := POL_Z
	B(9.5, 0.08, 9.0, "#8e9a9e", gx, 0.09, gz, dyn)
	B(9.5, 0.06, 2.2, "#4a5154", gx, 0.12, gz + 3.7, dyn)
	# Parkplatzmarkierungen
	for k in range(6):
		B(0.08, 0.02, 1.6, "#ffffff", gx - 3.9 + k * 1.6, 0.16, gz + 3.3, dyn)
	# Hauptgebäude: wächst mit der Stufe
	var floors := 1 if pt == 1 else (2 if pt <= 3 else 3)
	var bw := 4.2 if pt == 1 else 6.0
	var bd := 3.2
	var bx := gx - (0.0 if pt == 1 else 0.9)
	var bz := gz - 1.6
	for f in range(floors):
		var y0 := 0.12 + f * 1.25
		B(bw, 1.2, bd, "#eef0ec", bx, y0 + 0.6, bz, dyn)
		B(bw + 0.02, 0.22, bd + 0.02, "#1f4fbf", bx, y0 + 1.08, bz, dyn)
		# Fensterreihe vorne und seitlich
		for k in range(int(bw / 0.9)):
			B(0.55, 0.45, 0.04, "#2c3f4d", bx - bw / 2.0 + 0.55 + k * 0.9, y0 + 0.62, bz + bd / 2.0 + 0.01, dyn)
		for k in range(3):
			B(0.04, 0.45, 0.55, "#2c3f4d", bx + bw / 2.0 + 0.01, y0 + 0.62, bz - 1.0 + k * 1.0, dyn)
	var top := 0.12 + floors * 1.25
	B(bw + 0.2, 0.14, bd + 0.2, "#5a6163", bx, top + 0.05, bz, dyn)
	# Eingang mit Vordach und blauem Schild
	B(1.2, 0.9, 0.06, "#3a4a5a", bx, 0.57, bz + bd / 2.0 + 0.02, dyn)
	B(1.8, 0.08, 0.8, "#1f4fbf", bx, 1.2, bz + bd / 2.0 + 0.4, dyn)
	var sign := B(1.6, 0.35, 0.05, "#1f4fbf", bx, top - 0.35, bz + bd / 2.0 + 0.04, dyn)
	sign.material_override = mat("#2f6bff", 1.0, true)
	police_label("POLIZEI", Vector3(bx, top + 1.0, bz + bd / 2.0), 80)
	# Fahnenmast
	C(0.04, 0.05, 3.2, "#c9d2d5", bx + bw / 2.0 + 0.8, 1.7, bz + bd / 2.0 + 0.6, dyn, 6)
	B(0.04, 0.22, 0.5, "#111111", bx + bw / 2.0 + 0.8, 3.05, bz + bd / 2.0 + 0.85, dyn)
	B(0.04, 0.22, 0.5, "#dd0000", bx + bw / 2.0 + 0.8, 2.83, bz + bd / 2.0 + 0.85, dyn)
	B(0.04, 0.22, 0.5, "#ffce00", bx + bw / 2.0 + 0.8, 2.61, bz + bd / 2.0 + 0.85, dyn)
	# Garagen ab Stufe 2
	if pt >= 2:
		var gx2 := bx + bw / 2.0 + 1.6
		B(2.8, 1.5, 3.0, "#d9dcd6", gx2, 0.87, bz, dyn)
		for k in range(2):
			B(1.0, 1.0, 0.05, "#5a6163", gx2 - 0.7 + k * 1.4, 0.65, bz + 1.52, dyn)
		B(3.0, 0.12, 3.2, "#5a6163", gx2, 1.68, bz, dyn)
	# Funkmast ab Stufe 3
	if pt >= 3:
		for o in [[-0.25, -0.25], [0.25, -0.25], [-0.25, 0.25], [0.25, 0.25]]:
			B(0.06, 3.6, 0.06, "#c8102e" if int(o[0] * 4) % 2 == 0 else "#e8ecee", bx - bw / 2.0 + 0.6 + o[0], top + 1.9, bz - 0.8 + o[1], dyn)
		var tip := B(0.2, 0.2, 0.2, "#ff2030", bx - bw / 2.0 + 0.6, top + 3.8, bz - 0.8, dyn)
		tip.material_override = mat("#ff2030", 1.0, true)
	# Hubschrauber-Landeplatz auf dem Dach ab Stufe 4
	if pt >= 4:
		B(2.4, 0.06, 2.4, "#2b3436", bx + 1.2, top + 0.15, bz, dyn)
		B(1.2, 0.07, 0.2, "#ffffff", bx + 1.2, top + 0.19, bz, dyn)
		var heli := Node3D.new()
		dyn.add_child(heli)
		B(1.3, 0.55, 0.6, "#1f4fbf", 0, 0.35, 0, heli)
		B(0.9, 0.12, 0.12, "#1f4fbf", -0.95, 0.45, 0, heli)
		B(0.5, 0.3, 0.55, "#2c3f4d", 0.45, 0.42, 0, heli)
		B(2.4, 0.03, 0.12, "#2b3436", 0, 0.72, 0, heli)
		heli.position = Vector3(bx + 1.2, top + 0.18, bz)
		merge_deep(heli)
	# Streifenwagen auf dem Parkplatz
	var ncar: int = [0, 1, 3, 5, 7][pt]
	for k in range(ncar):
		var car := police_car()
		car.rotation.y = PI / 2
		car.position = Vector3(gx - 3.1 + k * 1.6 if k < 6 else gx - 5.5, 0.0, gz + 3.3 if k < 6 else gz - 2.0)
		dyn.add_child(car)
		merge_deep(car)
	# Ein Streifenwagen fährt Streife
	var pc := police_car()
	dyn.add_child(pc)
	merge_deep(pc)
	anim["patrol"] = pc
	# Polizisten vor der Wache
	var nofc: int = [0, 2, 4, 6, 8][pt]
	for k in range(nofc):
		var cop := person("#1f3a66", dyn, false, "police")
		cop.position = Vector3(bx - 1.6 + k * 0.55, 0.12, bz + bd / 2.0 + 1.3 + (k % 2) * 0.4)
		cop.rotation.y = randf() * 0.6 - 0.3

const PATROL := [[21.6, 3.0], [21.6, -24.6], [-22.6, -24.6], [-22.6, 20.1], [21.6, 20.1], [21.6, 3.0]]

func build_security() -> void:
	var g3 := cnt("g", "g3")
	var wt := wall_tier()
	if wt > 0:
		build_wall(wt)
	var g1 := cnt("g", "g1")
	if g1 > 0:
		B(1.8, 1.6, 1.8, "#efe7d4", 15.5, 0.9, 15, dyn)
		B(2.1, 0.25, 2.1, "#c8102e", 15.5, 1.8, 15, dyn)
	var ng: int = min(g1, 8)
	for j in range(ng):
		anim.guards.append({p = person("#1f3a5f", dyn, false, "guard"), u = float(j) / ng})
	var cams := [[-16.8, -14.8], [16.8, -14.8], [-16.8, 14.8], [16.6, 10.6], [0, -14.8], [-3.6, 2.2], [-16.8, 0], [16.8, 0], [-4.2, 11.6], [8, 2.2], [-8, -12.6], [8, -12.6]]
	for j in range(min(cnt("g", "g2"), 12)):
		var x: float = cams[j][0]
		var z: float = cams[j][1]
		C(0.07, 0.09, 3.2, "#4a5257", x, 1.6, z, dyn, 8)
		B(0.12, 0.12, 0.5, "#4a5257", x, 3.15, z + 0.2, dyn)
		var head := Node3D.new()
		head.position = Vector3(x, 3.05, z + 0.4)
		dyn.add_child(head)
		B(0.26, 0.24, 0.55, "#eef1f2", 0, 0, 0.12, head)
		B(0.32, 0.04, 0.62, "#d0d6d9", 0, 0.14, 0.12, head)
		var lens := C(0.08, 0.08, 0.06, "#101418", 0, 0, 0.42, head, 10)
		lens.rotation.x = PI / 2
		var led := B(0.04, 0.04, 0.02, "#ff2030", 0.09, 0.07, 0.4, head)
		led.material_override = mat("#ff2030", 1.0, true)
		head.rotation.x = 0.35
		merge_deep(head)
		anim.cams.append(head)
	beacon.visible = cnt("g", "g4") > 0
	if cnt("g", "g5") > 0:
		for k in range(4):
			var las := B(0.03, 0.03, 2.0, "#ff2030", -5.9, 0.45 + k * 0.4, 7, dyn)
			las.material_override = mat("#ff2030", 1.0, true)
		B(0.18, 1.9, 0.18, "#2b3436", -5.9, 1.0, 5.95, dyn)
		B(0.18, 1.9, 0.18, "#2b3436", -5.9, 1.0, 8.05, dyn)
	var pt := police_tier()
	if pt > 0:
		build_police(pt)
	if cnt("g", "g7") > 0:
		var sek := police_car("#1d2326", "#1d2326", true)
		sek.position = Vector3(31.5, 0.0, 16.2)
		dyn.add_child(sek)
		merge_deep(sek)
		for j in range(3):
			person("#1d2326", dyn, false, "guard").position = Vector3(29.6 + j * 0.7, 0.1, 17.4)
	if cnt("g", "g8") > 0:
		B(9.0, 0.06, 4.5, "#5d666a", 29.0, 0.09, 16.2, dyn)
		var bw := vehicle("v4", true)
		bw.position = Vector3(26.5, 0.0, 16.2)
		dyn.add_child(bw)
		merge_deep(bw)
		for j in range(min(cnt("g", "g8"), 4)):
			person("#4b5a32", dyn, false, "soldier").position = Vector3(24.5 + j * 0.8, 0.1, 17.6)
	for j in range(min(cnt("g", "g9"), 4)):
		var d := Node3D.new()
		B(0.6, 0.15, 0.6, "#2b3436", 0, 0, 0, d)
		for o in [[-0.4, -0.4], [0.4, -0.4], [-0.4, 0.4], [0.4, 0.4]]:
			C(0.2, 0.2, 0.04, "#c9d2d5", o[0], 0.1, o[1], d, 8)
		dyn.add_child(d)
		anim.drones.append({d = d, ph = j * PI / 2})
	if cnt("g", "g10") > 0:
		var dish := C(1, 0.2, 0.4, "#e8ecee", -7, 2.6, 5, dyn, 14)
		dish.rotation.x = -0.6

# ---------------------------------------------------------------- Fahrzeuge (Vorderseite = +x)
func wheel(x: float, z: float, r: float, p: Node3D, dual := false) -> void:
	var w := 0.22 if dual else 0.14
	var t := C(r, r, w, "#121212", x, r, z, p, 14)
	t.rotation.x = PI / 2
	var rim := C(r * 0.55, r * 0.55, w + 0.01, "#b8c0c4", x, r, z, p, 10)
	rim.rotation.x = PI / 2
	var hub := C(r * 0.18, r * 0.18, w + 0.02, "#3a4448", x, r, z, p, 6)
	hub.rotation.x = PI / 2

func lights(xf: float, xr: float, y: float, zs: float, p: Node3D) -> void:
	for zz in [-zs, zs]:
		var h := B(0.03, 0.09, 0.16, "#fffbe0", xf + 0.015, y, zz, p)
		h.material_override = mat("#fffbe0", 1.0, true)
		var r := B(0.03, 0.12, 0.1, "#ff2030", xr - 0.015, y, zz, p)
		r.material_override = mat("#ff2030", 1.0, true)

func windshield(x: float, y: float, h: float, w: float, p: Node3D, lean := 0.25) -> void:
	var g := B(0.05, h, w, "#22323d", x, y, 0, p)
	g.rotation.z = lean

## Gepanzerter Werttransporter: Kurzhauber mit großem Kühlergrill, schräger Panzerscheibe,
## durchgehendem Panzeraufbau, Schießscharten, Lüftungsgittern und Rundumleuchte
func armored(v: Node3D, L: float, big: bool, body_c := "", stripe_c := "#e9b915") -> void:
	var Y := "#4a5459" if big else "#e9b915"
	var Yd := "#2f373b" if big else "#c99a0c"
	if body_c != "":
		Y = body_c
		Yd = Color(body_c).darkened(0.3).to_html(false)
	var W := 1.08 if big else 0.98
	var H := 1.35 if big else 1.2
	var fx := L / 2.0
	var hood := 0.55
	var cab_x := fx - hood
	# Fahrgestell
	B(L - 0.2, 0.14, W - 0.3, "#1b1f22", -0.05, 0.3, 0, v)
	# Motorhaube (Kurzhauber) und Front
	B(hood, 0.62, W - 0.06, Y, fx - hood / 2.0, 0.72, 0, v)
	B(hood + 0.02, 0.05, W - 0.1, Yd, fx - hood / 2.0, 1.04, 0, v)
	# großer Kühlergrill mit Querstreben
	B(0.04, 0.44, W * 0.62, "#1c2023", fx + 0.005, 0.78, 0, v)
	for k in 3:
		B(0.05, 0.05, W * 0.6, "#3a4247", fx + 0.02, 0.66 + k * 0.12, 0, v)
	# Stoßfänger mit Lufteinlass
	B(0.16, 0.24, W + 0.04, Y, fx + 0.05, 0.43, 0, v)
	B(0.03, 0.08, W * 0.55, "#1c2023", fx + 0.135, 0.43, 0, v)
	# runde Scheinwerfer und Blinker
	for zz in [-1.0, 1.0]:
		var hl := C(0.07, 0.07, 0.04, "#fffbe0", fx + 0.01, 0.62, zz * (W * 0.38), v, 10)
		hl.rotation.z = PI / 2
		hl.material_override = mat("#fffbe0", 1.0, true)
		var bl := B(0.03, 0.08, 0.07, "#ff8a1a", fx + 0.01, 0.62, zz * (W * 0.44), v)
		bl.material_override = mat("#ff8a1a", 1.0, true)
		var rl := B(0.03, 0.14, 0.1, "#ff2030", -fx - 0.01, 0.65, zz * (W * 0.4), v)
		rl.material_override = mat("#ff2030", 1.0, true)
	# Fahrerhaus mit schräger Panzerscheibe (zweigeteilt)
	B(0.7, H - 0.12, W, Y, cab_x - 0.35, 0.36 + (H - 0.12) / 2.0, 0, v)
	var ws := B(0.05, 0.36, W * 0.4, "#24343f", cab_x + 0.02, 0.36 + H - 0.38, W * 0.22, v)
	ws.rotation.z = 0.5
	var ws2 := B(0.05, 0.36, W * 0.4, "#24343f", cab_x + 0.02, 0.36 + H - 0.38, -W * 0.22, v)
	ws2.rotation.z = 0.5
	B(0.12, 0.08, W - 0.02, Y, cab_x - 0.06, 0.36 + H - 0.1, 0, v)
	# kleine Seitenfenster und Spiegel
	for zz in [-1.0, 1.0]:
		B(0.22, 0.22, 0.02, "#24343f", cab_x - 0.25, 0.36 + H - 0.4, zz * (W / 2.0 + 0.005), v)
		B(0.04, 0.04, 0.2, "#1b1f22", cab_x - 0.05, 0.36 + H - 0.35, zz * (W / 2.0 + 0.08), v)
		B(0.05, 0.22, 0.1, "#1b1f22", cab_x - 0.05, 0.36 + H - 0.4, zz * (W / 2.0 + 0.2), v)
	# Panzeraufbau
	var bl_len := L - hood - 0.7
	var bx := cab_x - 0.7 - bl_len / 2.0
	B(bl_len, H, W + 0.02, Y, bx, 0.36 + H / 2.0, 0, v)
	B(bl_len + 0.7, 0.05, W + 0.03, Yd, bx + 0.35, 0.36 + H, 0, v)
	if big:
		B(bl_len + 0.7, 0.12, W + 0.04, stripe_c, bx + 0.35, 0.36 + H * 0.3, 0, v)
	for zz in [-1.0, 1.0]:
		var zs: float = zz * (W / 2.0 + 0.015)
		# Schießscharten und Lüftungsgitter
		for k in (3 if big else 2):
			B(0.12, 0.08, 0.01, "#15181a", bx + bl_len / 2.0 - 0.35 - k * 0.55, 0.36 + H * 0.62, zs, v)
		B(0.36, 0.14, 0.01, "#2a2f33", cab_x - 0.95, 0.36 + H * 0.45, zs, v)
		# Türfuge, Trittstufe, Radkästen
		B(0.015, H * 0.8, 0.012, Yd, cab_x - 0.68, 0.36 + H * 0.5, zs, v)
		B(0.25, 0.04, 0.12, "#2b3033", cab_x - 0.4, 0.4, zz * (W / 2.0 + 0.03), v)
	# Hecktür mit Mittelfuge
	B(0.012, H * 0.85, 0.02, Yd, -fx - 0.005, 0.36 + H / 2.0, 0, v)
	B(0.06, 0.12, W, "#2b3033", -fx, 0.38, 0, v)
	# Rundumleuchte und Antenne
	var bc := C(0.06, 0.07, 0.1, "#ff8a1a", cab_x - 0.2, 0.36 + H + 0.08, 0, v, 8)
	bc.material_override = mat("#ff8a1a", 1.0, true)
	C(0.01, 0.01, 0.35, "#1b1f22", bx - bl_len * 0.3, 0.36 + H + 0.18, 0.3, v, 4)
	# Räder
	var r := 0.3 if big else 0.26
	var axles := [fx - 0.45, -fx + 0.55]
	if big:
		axles.append(-fx + 1.15)
	for ax in axles:
		wheel(ax, W / 2.0 - 0.05, r, v)
		wheel(ax, -W / 2.0 + 0.05, r, v)

# ---------------------------------------------------------------- Feuerwehr
const FW_X := -31.5
const FW_Z := 14.0

## Feuerwehrfahrzeuge: lf = Löschfahrzeug, dlk = Drehleiter, rw = Rüstwagen, elw = Einsatzleitwagen
func fire_truck(kind: String) -> Node3D:
	var v := Node3D.new()
	var R := "#c8141e"
	if kind == "elw":
		B(2.1, 0.1, 0.9, "#1b1f22", 0, 0.22, 0, v)
		B(2.1, 0.45, 0.92, R, 0, 0.5, 0, v)
		B(1.5, 0.48, 0.9, R, -0.25, 0.96, 0, v)
		B(2.11, 0.1, 0.93, "#f2f2f2", 0, 0.62, 0, v)
		windshield(0.55, 0.95, 0.4, 0.82, v, 0.45)
		B(0.4, 0.26, 0.925, "#22323d", 0.2, 0.98, 0, v)
		var bl := B(0.25, 0.07, 0.6, "#2f6bff", 0.15, 1.24, 0, v)
		bl.material_override = police_light()
		lights(1.05, -1.05, 0.55, 0.32, v)
		for ww in [[0.65, 0.44], [-0.65, 0.44], [0.65, -0.44], [-0.65, -0.44]]:
			wheel(ww[0], ww[1], 0.21, v)
		return v
	var L := 3.6 if kind == "dlk" else 3.2
	var fx := L / 2.0
	B(L - 0.2, 0.16, 0.8, "#1b1f22", 0, 0.38, 0, v)
	# Fahrerhaus (Doppelkabine) mit großer Frontscheibe
	B(1.1, 1.15, 1.1, R, fx - 0.55, 1.0, 0, v)
	B(0.04, 0.5, 1.0, "#22323d", fx + 0.005, 1.25, 0, v)
	for zz in [-0.56, 0.56]:
		B(0.35, 0.35, 0.02, "#22323d", fx - 0.3, 1.25, zz, v)
		B(0.35, 0.35, 0.02, "#22323d", fx - 0.8, 1.25, zz, v)
		B(0.05, 0.3, 0.05, "#1b1f22", fx + 0.03, 1.3, zz * 1.18, v)
	B(1.11, 0.1, 1.11, "#f2f2f2", fx - 0.55, 0.62, 0, v)
	B(0.04, 0.3, 0.9, "#2b3033", fx + 0.01, 0.7, 0, v)
	var bar := B(0.3, 0.09, 0.9, "#2f6bff", fx - 0.4, 1.62, 0, v)
	bar.material_override = police_light()
	B(0.06, 0.12, 1.12, "#2b3033", fx + 0.05, 0.42, 0, v)
	# Aufbau mit silbernen Rollläden
	var bl_len := L - 1.15
	var bx := fx - 1.1 - bl_len / 2.0
	B(bl_len, 1.2, 1.12, R, bx, 1.0, 0, v)
	B(bl_len + 0.01, 0.1, 1.13, "#f2f2f2", bx, 0.62, 0, v)
	for zz in [-0.565, 0.565]:
		for k in 3:
			B(bl_len / 3.0 - 0.08, 0.8, 0.012, "#b9c0c4", bx - bl_len / 3.0 + k * bl_len / 3.0, 1.05, zz, v)
			for q in 4:
				B(bl_len / 3.0 - 0.08, 0.015, 0.015, "#8e979b", bx - bl_len / 3.0 + k * bl_len / 3.0, 0.75 + q * 0.18, zz, v)
	lights(fx, -fx, 0.62, 0.42, v)
	match kind:
		"dlk":
			# Drehleiter: Drehkranz und eingefahrener Leiterpark über dem Fahrerhaus
			C(0.3, 0.3, 0.15, "#3a4448", bx - 0.5, 1.68, 0, v, 10)
			B(3.0, 0.18, 0.5, "#c9d2d5", bx + 0.6, 1.85, 0, v)
			B(3.0, 0.06, 0.06, "#9aa3a8", bx + 0.6, 1.97, 0.22, v)
			B(3.0, 0.06, 0.06, "#9aa3a8", bx + 0.6, 1.97, -0.22, v)
			for k in 10:
				B(0.03, 0.05, 0.44, "#9aa3a8", bx - 0.85 + k * 0.3, 1.97, 0, v)
			B(0.4, 0.3, 0.55, "#c8141e", bx + 2.0, 1.85, 0, v)
		"rw":
			B(0.6, 0.3, 0.9, "#c9d2d5", bx, 1.75, 0, v)
			var lm := B(0.2, 0.25, 0.6, "#fffbe0", bx - 0.6, 1.75, 0, v)
			lm.material_override = mat("#fffbe0", 1.0, true)
		_:
			# Löschfahrzeug: Steckleiter und Saugschläuche auf dem Dach
			B(bl_len - 0.2, 0.06, 0.4, "#c9d2d5", bx, 1.65, 0.2, v)
			var hs := C(0.07, 0.07, bl_len - 0.3, "#2b3033", bx, 1.68, -0.3, v, 8)
			hs.rotation.z = PI / 2
	var r := 0.3
	wheel(fx - 0.6, 0.48, r, v)
	wheel(fx - 0.6, -0.48, r, v)
	for ax in ([-fx + 0.5, -fx + 1.1] if kind == "dlk" else [-fx + 0.6]):
		wheel(ax, 0.46, r, v, true)
		wheel(ax, -0.46, r, v, true)
	return v

func build_firebrigade() -> void:
	var S: Dictionary = main.S
	var lvl := int(S.get("fire", 0))
	if lvl > 0:
		var gx := FW_X
		var gz := FW_Z
		var bays: int = min(1 + lvl, 4) if lvl < 5 else 5
		B(11.0, 0.08, 8.0, "#8e9a9e", gx, 0.09, gz, dyn)
		# Fahrzeughalle in Klinker mit roten Toren, Wachgebäude, Schlauchturm
		var hw := bays * 1.6 + 0.4
		var hz := gz - 0.4
		B(4.2, 2.3, hw, "#9c4a35", gx - 2.4, 1.2, hz, dyn)
		B(4.3, 0.15, hw + 0.1, "#6d6d6d", gx - 2.4, 2.4, hz, dyn)
		for k in bays:
			var zb := hz - hw / 2.0 + 1.0 + k * 1.6
			B(0.05, 1.7, 1.3, "#22262a", gx - 0.27, 0.95, zb, dyn)
			B(0.06, 0.25, 1.3, "#c8141e", gx - 0.26, 1.95, zb, dyn)
			B(0.07, 0.02, 1.3, "#f2f2f2", gx - 0.25, 1.8, zb, dyn)
		B(0.06, 0.35, hw * 0.7, "#f2f2f2", gx - 0.25, 2.25, hz, dyn)
		# Wachgebäude mit Fenstern
		B(3.0, 1.9 if lvl < 3 else 3.1, 2.6, "#e9e4d8", gx - 2.9, (1.9 if lvl < 3 else 3.1) / 2.0 + 0.1, hz + hw / 2.0 + 1.3, dyn)
		for k in (1 if lvl < 3 else 2):
			for q in 3:
				B(0.05, 0.4, 0.5, "#2c3f4d", gx - 1.38, 0.9 + k * 1.2, hz + hw / 2.0 + 0.5 + q * 0.8, dyn)
		if lvl >= 2:
			B(1.1, 5.2, 1.1, "#9c4a35", gx - 4.4, 2.6, hz - hw / 2.0 - 0.3, dyn)
			B(1.3, 0.3, 1.3, "#6d6d6d", gx - 4.4, 5.3, hz - hw / 2.0 - 0.3, dyn)
			for q in 3:
				B(0.05, 0.5, 0.3, "#2c3f4d", gx - 3.84, 1.2 + q * 1.4, hz - hw / 2.0 - 0.3, dyn)
		# Fahnenmast, Schild
		C(0.04, 0.04, 3.4, "#c9cdd0", gx + 4.6, 1.8, gz - 3.4, dyn, 6)
		B(0.03, 0.55, 0.9, "#c8141e", gx + 4.6, 3.15, gz - 2.95, dyn)
		B(0.08, 0.45, 2.6, "#c8141e", gx - 0.24, 2.7, hz, dyn)
		var fl := Label3D.new()
		fl.text = "FEUERWEHR"
		fl.font_size = 72
		fl.pixel_size = 0.011
		fl.outline_size = 20
		fl.outline_modulate = Color("#7a0a10")
		fl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		fl.no_depth_test = true
		fl.position = Vector3(gx - 2.4, 4.6, hz)
		dyn.add_child(fl)
		# Fahrzeuge vor den Toren (außer bei einem Einsatz)
		var kinds := ["lf", "dlk", "rw", "elw", "lf"]
		for k in bays:
			if main.burning() and k < 2:
				continue
			var tr := fire_truck(kinds[k])
			tr.position = Vector3(gx + 1.6, 0.0, hz - hw / 2.0 + 1.0 + k * 1.6)
			dyn.add_child(tr)
			merge_deep(tr)
		for k in min(lvl + 1, 5):
			var fp := person("#22314a", dyn, false, "fire")
			fp.position = Vector3(gx + 3.4 + (k % 2) * 0.6, 0.1, gz + 2.0 - k * 0.7)
			fp.rotation.y = -PI / 2
	# Brand in der Druckerei: Flammen, Rauch, Einsatzkräfte
	anim["fire"] = []
	if main.burning():
		var fxn := Node3D.new()
		dyn.add_child(fxn)
		anim["fire_node"] = fxn
		var flame := StandardMaterial3D.new()
		flame.albedo_color = Color("#ff4a10")
		flame.emission_enabled = true
		flame.emission = Color("#ff5a00")
		flame.emission_energy_multiplier = 2.0
		var flame2 := StandardMaterial3D.new()
		flame2.albedo_color = Color("#ffa020")
		flame2.emission_enabled = true
		flame2.emission = Color("#ff8a00")
		flame2.emission_energy_multiplier = 2.0
		var smoke := StandardMaterial3D.new()
		smoke.albedo_color = Color(0.18, 0.18, 0.2, 0.55)
		smoke.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		smoke.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		for spot in [[5.5, -11.0], [9.5, -8.3], [12.0, -3.9]]:
			for k in 3:
				var f := C(0.0, 0.45 - k * 0.1, 1.4 - k * 0.3, "#ff7a1a", spot[0] + (k - 1) * 0.35, 1.9 + (1.4 - k * 0.3) / 2.0, spot[1] + (k % 2) * 0.3, fxn, 7)
				f.material_override = flame if k != 1 else flame2
				anim.fire.append({m = f, ph = randf() * 6.0, kind = "flame", base = f.position.y})
			for k in 4:
				var sm := sphere(0.6, "#333333", spot[0], 3.0, spot[1], fxn, 8)
				sm.material_override = smoke
				sm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				anim.fire.append({m = sm, ph = float(k) / 4.0, kind = "smoke", x = spot[0], z = spot[1]})
		if int(S.get("fire", 0)) > 0:
			# Löschfahrzeug und Drehleiter im Hof, Wasserstrahl auf die Halle
			var t1 := fire_truck("lf")
			t1.position = Vector3(10.0, 0.0, 4.2)
			dyn.add_child(t1)
			merge_deep(t1)
			if int(S["fire"]) >= 2:
				var t2 := fire_truck("dlk")
				t2.position = Vector3(5.0, 0.0, 4.2)
				dyn.add_child(t2)
				merge_deep(t2)
			var water := StandardMaterial3D.new()
			water.albedo_color = Color(0.6, 0.8, 1.0, 0.6)
			water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			water.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			for k in min(int(S["fire"]) + 1, 4):
				var ff := person("#22314a", dyn, false, "fire")
				var px: float = 6.5 + k * 1.6
				ff.position = Vector3(px, 0.1, 2.4)
				ff.rotation.y = PI
				var jet := B(0.08, 0.08, 5.0, "#99ccff", px, 2.2, -1.2, fxn)
				jet.rotation.x = -0.35
				jet.material_override = water
				anim.fire.append({m = jet, ph = randf() * 6.0, kind = "jet"})

# ---------------------------------------------------------------- Bahn
const RAIL_Z := 26.5

## Gleis: Schotterbett, Betonschwellen, Schienen und Oberleitung; Güterzug mit E-Lok
func build_railway() -> void:
	var tr := Node3D.new()
	dyn.add_child(tr)
	var x0 := -60.0
	var x1 := 110.0
	var L := x1 - x0
	var cx := (x0 + x1) / 2.0
	B(L, 0.12, 2.6, "#7d776e", cx, 0.06, RAIL_Z, tr)
	B(L, 0.12, 2.0, "#8f897f", cx, 0.17, RAIL_Z, tr)
	var x := x0
	while x < x1:
		B(0.22, 0.08, 1.7, "#a7a59f", x, 0.27, RAIL_Z, tr)
		x += 0.65
	for zz in [-0.36, 0.36]:
		B(L, 0.05, 0.12, "#5a5550", cx, 0.33, RAIL_Z + zz, tr)
		B(L, 0.06, 0.07, "#9aa1a5", cx, 0.385, RAIL_Z + zz, tr)
	# Oberleitungsmasten mit Ausleger und Fahrdraht
	x = x0 + 5.0
	while x < x1:
		B(0.18, 3.4, 0.18, "#7f8a8f", x, 1.8, RAIL_Z - 1.6, tr)
		B(0.08, 0.08, 1.75, "#7f8a8f", x, 3.35, RAIL_Z - 0.75, tr)
		B(0.05, 0.25, 0.05, "#5a6266", x, 3.18, RAIL_Z, tr)
		x += 12.0
	B(L, 0.025, 0.025, "#2b3033", cx, 3.05, RAIL_Z, tr)
	B(L, 0.02, 0.02, "#2b3033", cx, 3.3, RAIL_Z, tr)
	# Bahnübergänge der Ausfahrten mit Andreaskreuz
	for cx2 in [10.0, -22.0]:
		B(3.4, 0.06, 2.4, "#5f6466", cx2, 0.42, RAIL_Z, tr)
		for sd in [-1.0, 1.0]:
			C(0.04, 0.04, 1.6, "#e8ecee", cx2 + sd * 2.1, 0.8, RAIL_Z + sd * 2.0, tr, 6)
			var xa := B(0.06, 0.06, 0.8, "#c8102e", cx2 + sd * 2.1, 1.5, RAIL_Z + sd * 2.0, tr)
			xa.rotation.x = 0.8
			var xb := B(0.06, 0.06, 0.8, "#e8ecee", cx2 + sd * 2.1, 1.5, RAIL_Z + sd * 2.0, tr)
			xb.rotation.x = -0.8
	merge_deep(tr)
	var train := Node3D.new()
	# E-Lok (vorne, Fahrtrichtung +x)
	rail_bogie(1.2, train)
	rail_bogie(-1.2, train)
	B(4.2, 0.2, 1.3, "#2b3033", 0, 0.98, 0, train)
	B(3.6, 1.35, 1.3, "#c8141e", 0, 1.75, 0, train)
	B(0.5, 1.2, 1.3, "#c8141e", 1.95, 1.65, 0, train)
	B(0.5, 1.2, 1.3, "#c8141e", -1.95, 1.65, 0, train)
	var fw := B(0.06, 0.5, 1.1, "#22323d", 2.2, 2.0, 0, train)
	fw.rotation.z = 0.25
	var rw := B(0.06, 0.5, 1.1, "#22323d", -2.2, 2.0, 0, train)
	rw.rotation.z = -0.25
	B(3.6, 0.1, 1.32, "#f2f2f2", 0, 1.25, 0, train)
	B(4.1, 0.12, 1.2, "#7f8a8f", 0, 2.5, 0, train)
	for zz in [-0.66, 0.66]:
		for k in 4:
			B(0.5, 0.35, 0.02, "#5a6266", -1.1 + k * 0.7, 1.85, zz, train)
	for sx in [2.21, -2.21]:
		for zz in [-0.4, 0.4]:
			var hl := B(0.03, 0.1, 0.14, "#fffbe0", sx, 1.25, zz, train)
			hl.material_override = mat("#fffbe0", 1.0, true)
	# Stromabnehmer
	B(0.6, 0.06, 0.06, "#2b3033", 0.8, 2.75, 0, train)
	var pa := B(0.05, 0.7, 0.05, "#2b3033", 0.8, 2.9, 0, train)
	pa.rotation.z = 0.6
	B(0.08, 0.04, 0.9, "#2b3033", 1.0, 3.05, 0, train)
	# Güterwagen: gesicherte Wertcontainer
	for j in range(4):
		var wx := -4.7 - j * 4.6
		rail_bogie(wx + 1.4, train)
		rail_bogie(wx - 1.4, train)
		B(4.3, 0.18, 1.2, "#2b3033", wx, 0.98, 0, train)
		var cc: String = ["#6b7478", "#0e5a8a", "#6b7478", "#7a3b2e"][j]
		B(4.0, 1.5, 1.3, cc, wx, 1.85, 0, train)
		for k in 9:
			B(0.03, 1.4, 1.32, "#4a5357", wx - 1.8 + k * 0.45, 1.85, 0, train)
		B(0.05, 1.3, 0.02, "#e9b915", wx + 0.6, 1.85, 0.66, train)
		B(0.05, 1.3, 0.02, "#e9b915", wx + 0.6, 1.85, -0.66, train)
		B(0.35, 0.08, 0.08, "#2b3033", wx + 2.3, 0.98, 0, train)
	train.position.z = RAIL_Z
	dyn.add_child(train)
	merge_deep(train)
	anim.train = train

func rail_bogie(x: float, p: Node3D) -> void:
	B(1.4, 0.22, 1.0, "#2b3033", x, 0.72, 0, p)
	for wx in [x - 0.45, x + 0.45]:
		for zz in [-0.36, 0.36]:
			var w := C(0.24, 0.24, 0.08, "#3a3f42", wx, 0.64, zz, p, 10)
			w.rotation.x = PI / 2

## Realistische Fahrzeuge: Lieferwagen, Geldtransporter, Panzerwagen, LKW mit Kofferaufbau
func vehicle(k: String, army := false) -> Node3D:
	var v := Node3D.new()
	var body := "#56653a" if army else "#f4f6f7"
	var cab := "#4b5a32" if army else "#e8ecee"
	var band := "#3f4a2a" if army else "#0e8a7c"
	var band2 := "#3f4a2a" if army else "#ffc23d"
	match k:
		"v1":
			# kleiner weißer Kastenwagen
			B(1.75, 0.08, 0.86, "#1b1f22", 0, 0.2, 0, v)
			B(1.75, 0.42, 0.88, "#2f6fb8", 0, 0.45, 0, v)
			B(1.3, 0.5, 0.86, "#2f6fb8", -0.2, 0.9, 0, v)
			B(0.42, 0.18, 0.86, "#2f6fb8", 0.66, 0.72, 0, v)
			windshield(0.5, 0.92, 0.42, 0.8, v, 0.45)
			B(0.36, 0.26, 0.885, "#22323d", 0.22, 0.92, 0, v)
			B(1.0, 0.1, 0.89, "#f2f4f5", -0.35, 0.62, 0, v)
			B(0.05, 0.12, 0.6, "#2b3033", 0.88, 0.32, 0, v)
			lights(0.875, -0.875, 0.5, 0.32, v)
			for ww in [[0.55, 0.44], [-0.55, 0.44], [0.55, -0.44], [-0.55, -0.44]]:
				wheel(ww[0], ww[1], 0.2, v)
			B(0.06, 0.08, 0.06, "#1b1f22", 0.42, 0.95, 0.47, v)
			B(0.06, 0.08, 0.06, "#1b1f22", 0.42, 0.95, -0.47, v)
		"v2":
			armored(v, 2.5, false)
		"v3":
			armored(v, 3.0, true)
		_:
			# Werttransport-LKW: Frontlenker-Fahrerhaus, Kofferaufbau, Doppelreifen
			B(3.8, 0.14, 0.7, "#1b1f22", -0.1, 0.36, 0, v)
			# Fahrerhaus
			B(0.85, 1.25, 1.1, cab, 1.45, 1.05, 0, v)
			B(0.04, 0.6, 1.0, "#22323d", 1.88, 1.28, 0, v)
			B(0.05, 0.12, 1.1, "#c9d2d5", 1.9, 1.66, 0, v)
			B(0.04, 0.35, 0.9, "#2b3033", 1.885, 0.75, 0, v)
			for gg in range(4):
				B(0.045, 0.03, 0.86, "#7a8489", 1.9, 0.64 + gg * 0.08, 0, v)
			B(0.86, 0.2, 1.11, band, 1.45, 0.52, 0, v)
			B(0.86, 0.06, 1.11, band2, 1.45, 0.64, 0, v)
			B(0.3, 0.35, 0.02, "#22323d", 1.6, 1.3, 0.56, v)
			B(0.3, 0.35, 0.02, "#22323d", 1.6, 1.3, -0.56, v)
			B(0.06, 0.3, 0.05, "#1b1f22", 1.92, 1.35, 0.66, v)
			B(0.06, 0.3, 0.05, "#1b1f22", 1.92, 1.35, -0.66, v)
			B(0.8, 0.12, 1.12, "#c9d2d5", 1.45, 1.72, 0, v)
			# Tank, Kotflügel
			C(0.16, 0.16, 0.6, "#c9d2d5", 1.0, 0.5, 0.5, v, 10).rotation.z = PI / 2
			# Kofferaufbau
			B(2.7, 1.45, 1.12, body, -0.55, 1.2, 0, v)
			B(2.71, 0.16, 1.13, band, -0.55, 0.62, 0, v)
			B(2.71, 0.08, 1.13, band2, -0.55, 0.74, 0, v)
			B(0.02, 1.35, 0.02, "#9aa3a8", -1.91, 1.2, 0, v)
			B(0.02, 1.35, 0.02, "#9aa3a8", -1.91, 1.2, 0.3, v)
			B(0.02, 1.35, 0.02, "#9aa3a8", -1.91, 1.2, -0.3, v)
			lights(1.9, -1.92, 0.62, 0.42, v)
			wheel(1.35, 0.5, 0.3, v)
			wheel(1.35, -0.5, 0.3, v)
			for wx in [-1.05, -1.7]:
				wheel(wx, 0.48, 0.3, v, true)
				wheel(wx, -0.48, 0.3, v, true)
	return v

func build_fleet() -> void:
	var own := []
	var tot := 0
	for k in ["v1", "v2", "v3", "v4"]:
		if cnt("v", k) > 0:
			own.append(k)
			tot += cnt("v", k)
	var N: int = min(tot, 12)
	var fleet := []
	for k in own:
		for q in range(max(1, int(round(float(cnt("v", k)) / tot * N)))):
			fleet.append(k)
	fleet.shuffle()
	fleet = fleet.slice(0, 12)
	for j in range(fleet.size()):
		var k: String = fleet[j]
		var tr := vehicle(k)
		if int(main.S["escort"]) > 0 and j % max(1, 4 - int(main.S["escort"]) / 2) == 0:
			var esc := B(0.3, 0.14, 0.3, "#3a6fd8", 0.2, 1.42, 0, tr)
			esc.material_override = mat("#3a6fd8", 1.0, true)
		dyn.add_child(tr)
		var pid: String = {"v1": "light", "v2": "light", "v3": "mid", "v4": "heavy"}[k]
		var u0 := float(j) / fleet.size()
		anim.trucks.append({t = tr, u = u0, path = pid})
		if k == "v3" or k == "v4":
			heavy_escort(pid, u0)
	if int(main.S["gold"]) > 0:
		# Goldtransport: schwarzer Panzerwagen mit Goldstreifen, immer mit Polizei und SEK
		var gt := Node3D.new()
		armored(gt, 3.0, true, "#1f2326", "#d4a826")
		dyn.add_child(gt)
		anim.trucks.append({t = gt, u = 0.5, path = "heavy"})
		heavy_escort("heavy", 0.5)
	if cnt("v", "v5") > 0:
		build_railway()
	if cnt("v", "v6") > 0:
		var pl := Node3D.new()
		B(3, 0.5, 0.5, "#f4f5f2", 0, 0, 0, pl)
		B(0.8, 0.1, 3.4, "#dfe3e5", 0.2, 0, 0, pl)
		B(0.5, 0.7, 0.1, "#0e8a7c", -1.4, 0.4, 0, pl)
		dyn.add_child(pl)
		anim.plane = pl
	if cnt("v", "v7") > 0:
		B(3.2, 0.1, 3.2, "#5a6163", -29, 0.12, 5, dyn)
		B(1.6, 0.11, 0.25, "#ffffff", -29, 0.14, 5, dyn)
		var h := Node3D.new()
		B(1.4, 0.6, 0.7, "#c8102e", 0, 0, 0, h)
		anim.rotor = B(2.6, 0.04, 0.15, "#2b3436", 0, 0.4, 0, h)
		h.position = Vector3(-29, 0.55, 5)
		dyn.add_child(h)
	if cnt("v", "v8") > 0:
		B(4, 2.4, 3.2, "#3f6f7d", 11, 1.3, 5.2, dyn)
		B(4.2, 0.2, 3.4, "#0e8a7c", 11, 2.6, 5.2, dyn)
		facade(11.0, 5.2, 4.0, 3.2, 2.4, dyn)
		for k in range(3):
			B(0.9, 1.1, 0.05, "#9aa3a8", 9.9 + k * 1.1, 0.7, 6.83, dyn)

## Begleitschutz für schwere Geld- und Goldtransporte: Streifenwagen voraus, SEK dahinter
func heavy_escort(pid: String, u0: float) -> void:
	var gap: float = 3.2 / float(PATHS_LEN_EST.get(pid, 60.0))
	var pc := police_car()
	dyn.add_child(pc)
	anim.trucks.append({t = pc, u = u0 + gap, path = pid})
	if cnt("g", "g7") > 0:
		var sek := police_car("#1d2326", "#3a4046", true)
		dyn.add_child(sek)
		anim.trucks.append({t = sek, u = u0 - gap * 1.1, path = pid})

const PATHS_LEN_EST := {"light": 56.0, "mid": 75.0, "heavy": 60.0}

var pile_slots := []

## Paletten einmal pro Ausbau bauen, danach nur ein- und ausblenden
func build_piles() -> void:
	pile_slots = []
	var lvl: int = min(int(main.S["lv"]), 6)
	var all := store_slots(lvl)
	for i in range(all.size()):
		var n := Node3D.new()
		dyn.add_child(n)
		pallet(all[i], i, n)
		merge_deep(n)
		n.visible = false
		pile_slots.append(n)
	last_pile = -1

func piles() -> void:
	var slots: int = pile_slots.size()
	if slots == 0:
		return
	var n := int(ceil(min(1.0, float(main.S["stock"]) / main.cap()) * slots))
	if n == last_pile:
		return
	last_pile = n
	for i in range(slots):
		pile_slots[i].visible = i < n

# ---------------------------------------------------------------- Wege
const TRUCK_PATH := [[-2.8, 5.0], [6.0, 5.5], [14.5, 9.0], [14.5, 12.8], [42.0, 12.8]]
const PATHS := {
	"light": [[-2.8, 5.0], [6.0, 5.5], [14.5, 9.0], [14.5, 12.8], [42.0, 12.8]],
	"mid": [[-2.8, 5.0], [2.0, 6.5], [2.0, 12.8], [2.0, 19.5], [-22.0, 19.5], [-22.0, 50.0]],
	"heavy": [[-2.8, 5.0], [10.0, 6.5], [10.0, 12.8], [10.0, 19.5], [10.0, 50.0]],
}
var path_len := {}

func along_path(pid: String, u: float) -> Array:
	var P: Array = PATHS[pid]
	if not path_len.has(pid):
		var tot := 0.0
		for i in range(P.size() - 1):
			tot += Vector2(P[i + 1][0] - P[i][0], P[i + 1][1] - P[i][1]).length()
		path_len[pid] = tot
	var d: float = clamp(u, 0.0, 1.0) * float(path_len[pid])
	for i in range(P.size() - 1):
		var a: Array = P[i]
		var b: Array = P[i + 1]
		var l := Vector2(b[0] - a[0], b[1] - a[1]).length()
		if d <= l:
			var f: float = d / l
			return [a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f, atan2(-(b[1] - a[1]), b[0] - a[0])]
		d -= l
	var e: Array = P[P.size() - 1]
	return [e[0], e[1], 0.0]

var segs := []
var seg_tot := 0.0
func along(u: float) -> Array:
	if segs.is_empty():
		for i in range(TRUCK_PATH.size() - 1):
			var a: Array = TRUCK_PATH[i]
			var b: Array = TRUCK_PATH[i + 1]
			var l := Vector2(b[0] - a[0], b[1] - a[1]).length()
			segs.append(l)
			seg_tot += l
	var tot := seg_tot
	var d := u * tot
	for i in range(segs.size()):
		if d <= segs[i]:
			var a: Array = TRUCK_PATH[i]
			var b: Array = TRUCK_PATH[i + 1]
			var f: float = d / segs[i]
			return [a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f, atan2(-(b[1] - a[1]), b[0] - a[0])]
		d -= segs[i]
	return [42.0, 12.8, 0.0]

func perim(u: float) -> Array:
	var P := [[-16.6, -14.6], [16.6, -14.6], [16.6, 14.6], [-16.6, 14.6]]
	var L := [33.2, 29.2, 33.2, 29.2]
	var d := fposmod(u, 1.0) * 124.8
	for i in range(4):
		if d <= L[i]:
			var a: Array = P[i]
			var b: Array = P[(i + 1) % 4]
			var f: float = d / L[i]
			return [a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f, atan2(-(b[1] - a[1]), b[0] - a[0])]
		d -= L[i]
	return [P[0][0], P[0][1], 0.0]

var vc_mat: StandardMaterial3D

func vc_material() -> StandardMaterial3D:
	if vc_mat == null:
		vc_mat = StandardMaterial3D.new()
		vc_mat.vertex_color_use_as_albedo = true
		vc_mat.vertex_color_is_srgb = true
		vc_mat.roughness = 0.78
	return vc_mat

func mergeable(m: Material) -> bool:
	return m is StandardMaterial3D and not m.emission_enabled and m.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and m.metallic < 0.5

var deidx := {}

## Ecken und Normalen eines Grundkörpers ohne Index (einmal pro Form berechnet)
func flat_arrays(mesh: Mesh) -> Array:
	if deidx.has(mesh):
		return deidx[mesh]
	var st := SurfaceTool.new()
	st.create_from(mesh, 0)
	st.deindex()
	var arr := st.commit_to_arrays()
	var res := [arr[Mesh.ARRAY_VERTEX], arr[Mesh.ARRAY_NORMAL]]
	deidx[mesh] = res
	return res

## Baut aus vielen Teilen ein Mesh: einfarbige Teile mit Vertex-Farben, Sonderteile je Material
func bake_into(root: Node3D, items: Array) -> void:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var shadow := false
	var others := {}
	var order := []
	var tmpc := PackedColorArray()
	for it in items:
		var mesh: Mesh = it[0]
		var xf: Transform3D = it[1]
		var m: Material = it[3]
		if m == vc_mat and vc_mat != null:
			# bereits zusammengefasstes Mesh: Vertex-Farben übernehmen
			var arr := mesh.surface_get_arrays(0)
			verts.append_array(xf * (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array))
			norms.append_array(Transform3D(xf.basis, Vector3.ZERO) * (arr[Mesh.ARRAY_NORMAL] as PackedVector3Array))
			cols.append_array(arr[Mesh.ARRAY_COLOR])
			if it[4]:
				shadow = true
		elif mergeable(m):
			var fa := flat_arrays(mesh)
			var v: PackedVector3Array = fa[0]
			verts.append_array(xf * v)
			norms.append_array(Transform3D(xf.basis, Vector3.ZERO) * (fa[1] as PackedVector3Array))
			tmpc.resize(v.size())
			tmpc.fill(m.albedo_color)
			cols.append_array(tmpc)
			if it[4]:
				shadow = true
		else:
			if not others.has(m):
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				others[m] = st
				order.append(m)
			others[m].append_from(mesh, 0, xf)
	for it in items:
		var node = it[2]
		if node != null and is_instance_valid(node) and node.get_parent():
			node.get_parent().remove_child(node)
			node.free()
	if verts.size() > 0:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = norms
		arrays[Mesh.ARRAY_COLOR] = cols
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var out := MeshInstance3D.new()
		out.mesh = am
		out.material_override = vc_material()
		out.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(out)
	for m in order:
		var mi2 := MeshInstance3D.new()
		mi2.mesh = others[m].commit()
		mi2.material_override = m
		mi2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi2)

## Fasst alle direkten Mesh-Kinder (außer den beweglichen) zusammen
func merge_children(parent: Node3D, skip: Dictionary) -> void:
	var items := []
	for c in parent.get_children():
		if c is MeshInstance3D and not skip.has(c) and c.mesh != null:
			items.append([c.mesh, c.transform, c, c.material_override, c.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF])
	bake_into(parent, items)

## Fasst alle Meshes unterhalb eines Knotens (auch verschachtelt) zusammen
func merge_deep(root: Node3D) -> void:
	var inv := root.global_transform.affine_inverse()
	var found := []
	collect_meshes(root, found)
	var items := []
	for c in found:
		items.append([c.mesh, inv * c.global_transform, null, c.material_override, c.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF])
	for ch in root.get_children():
		root.remove_child(ch)
		ch.free()
	bake_into(root, items)

func collect_meshes(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is MeshInstance3D and c.mesh != null:
			out.append(c)
		collect_meshes(c, out)

func apply_quality() -> void:
	var g: int = int(main.S.get("gfx", 2))
	sun.shadow_enabled = g >= 1
	sun.directional_shadow_max_distance = 75.0 if g == 2 else 110.0
	sun.shadow_blur = 0.6 if g == 2 else 1.0
	RenderingServer.directional_shadow_atlas_set_size(4096 if g == 2 else 2048, true)

# ---------------------------------------------------------------- Kamera & Eingabe
func fit() -> void:
	if cam == null:
		return
	var s := get_viewport().get_visible_rect().size
	if s.y <= 0:
		return
	var a := s.x / s.y
	cam.size = max(24.0, 48.0 / a / 1.0) / zoom
	cam.position = Vector3(tx + 30, 30, tz + 30)
	cam.look_at(Vector3(tx, 0, tz), Vector3.UP)

func zoom_by(f: float) -> void:
	zoom = clamp(zoom * f, 0.7, 3.2)
	fit()

func pan(rel: Vector2) -> void:
	var s := get_viewport().get_visible_rect().size
	var u := cam.size * (s.x / s.y) / s.x
	var k := 0.7071
	tx += -rel.x * u * k - rel.y * u * 1.73 * k
	tz += rel.x * u * k - rel.y * u * 1.73 * k
	tx = clamp(tx, -40.0, 60.0)
	tz = clamp(tz, -40.0, 34.0)
	fit()

func tap(pos: Vector2) -> void:
	var o := cam.project_ray_origin(pos)
	var n := cam.project_ray_normal(pos)
	if abs(n.y) < 0.001:
		return
	var hit := o + n * (-o.y / n.y)
	for zn in ZONES:
		if hit.x >= zn[0] and hit.z >= zn[1] and hit.x <= zn[2] and hit.z <= zn[3]:
			main.go(zn[4], zn[5])
			return

func handle_input(ev: InputEvent) -> void:
	# Ein Finger kommt als (emulierte) Maus an: Verschieben und Antippen.
	# Zwei Finger werden über die Touch-Ereignisse zum Zoomen ausgewertet.
	if ev is InputEventScreenTouch:
		if ev.pressed:
			touches[ev.index] = ev.position
		else:
			touches.erase(ev.index)
		if touches.size() == 2:
			var ps := touches.values()
			pinch = ps[0].distance_to(ps[1])
		elif touches.size() < 2:
			pinch = 0.0
	elif ev is InputEventScreenDrag:
		touches[ev.index] = ev.position
		if touches.size() >= 2:
			var ps2 := touches.values()
			var d: float = ps2[0].distance_to(ps2[1])
			if pinch > 0.0:
				zoom_by(d / pinch)
			pinch = d
			moved = 99.0
	elif ev is InputEventMouseButton:
		if ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				dragging = true
				moved = 0.0
			else:
				dragging = false
				if moved < 12.0 and touches.size() <= 1:
					tap(ev.position)
		elif ev.button_index == MOUSE_BUTTON_WHEEL_UP and ev.pressed:
			zoom_by(1.1)
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN and ev.pressed:
			zoom_by(0.9)
	elif ev is InputEventMouseMotion and dragging:
		moved += ev.relative.length()
		if touches.size() < 2:
			pan(ev.relative)

# ---------------------------------------------------------------- Animation
func _process(dt: float) -> void:
	t += dt
	if dirty_auto and t - last_build > 20.0:
		dirty_auto = false
		dirty = true
	if dirty and t - last_build > 1.5:
		dirty = false
		var sig := visual_sig()
		if sig != last_sig:
			last_sig = sig
			last_build = t
			var t0 := Time.get_ticks_usec()
			build()
			if OS.has_environment("BB_PERF"):
				print("BUILD_MS %.1f" % ((Time.get_ticks_usec() - t0) / 1000.0))
	fit()
	piles()
	sp_t -= dt
	if sp_t <= 0.0:
		sp_t = 0.5
		sp = []
		for b in anim.belts:
			sp.append(0.06 + min(0.5, log(main.line_rate(b.l) + 1.0) / log(10.0) * 0.07))
	for i in range(anim.belts.size()):
		var b: Dictionary = anim.belts[i]
		var s: float = sp[i] if i < sp.size() else 0.1
		b.g.position.x = fposmod(t * s * 11.0 + b.ph * b.spacing, b.spacing)
	for p in anim.pist:
		match p.kind:
			"roll":
				p.m.rotation.y = t * 3.0 + p.ph
			"swing":
				p.m.rotation.z = sin(t * 2.0 + p.ph) * 0.7
			_:
				p.m.position.y = -abs(sin(t * 4.0 + p.ph)) * 0.3
	for w in anim.work:
		w.p.position.x = sin(t * 0.7 + w.ph) * 1.0
	for g in anim.guards:
		var pr := perim(g.u + t * 0.012)
		g.p.position = Vector3(pr[0], 0.1, pr[1])
		g.p.rotation.y = pr[2] + PI / 2
	for i in range(anim.cams.size()):
		anim.cams[i].rotation.y = sin(t * 0.6 + i) * 0.9
	var dsp: float = 0.02 + min(0.08, log(main.deliv() + 1.0) / log(10.0) * 0.012)
	for tr in anim.trucks:
		var pid: String = tr.get("path", "light")
		var a := along_path(pid, fposmod(tr.u + t * dsp * (110.0 / float(path_len.get(pid, 110.0))), 1.0))
		tr.t.position = Vector3(a[0], 0, a[1])
		tr.t.rotation.y = a[2]
	for f in anim.get("fire", []):
		if not is_instance_valid(f.m):
			continue
		match f.kind:
			"flame":
				var k := 1.0 + sin(t * 9.0 + f.ph) * 0.18 + sin(t * 15.0 + f.ph * 2.0) * 0.1
				f.m.scale = Vector3(1.0 / sqrt(k), k, 1.0 / sqrt(k))
				f.m.position.y = f.base + (k - 1.0) * 0.4
			"smoke":
				var u := fposmod(t * 0.18 + f.ph, 1.0)
				f.m.position = Vector3(f.x + u * 2.0, 2.6 + u * 6.0, f.z - u * 1.0)
				f.m.scale = Vector3.ONE * (0.6 + u * 2.2)
			"jet":
				f.m.scale.y = 1.0 + sin(t * 20.0 + f.ph) * 0.15
	for d in anim.drones:
		d.d.position = Vector3(cos(t * 0.4 + d.ph) * 12, 6 + sin(t * 2 + d.ph) * 0.3, sin(t * 0.4 + d.ph) * 10)
	if anim.train:
		anim.train.position.x = fposmod(t * 6.0, 150.0) - 50.0
		if OS.has_environment("BB_TRAIN"):
			anim.train.position.x = float(OS.get_environment("BB_TRAIN"))
	if anim.plane:
		var u := fposmod(t * 0.04, 1.0)
		anim.plane.position = Vector3(-40 + u * 90, 12, -30 + u * 50)
		anim.plane.rotation.y = -atan2(50, 90)
	if anim.has("patrol") and is_instance_valid(anim.patrol):
		var pp2 := path_pos(PATROL, fposmod(t * 0.02, 1.0))
		anim.patrol.position = Vector3(pp2[0], 0.0, pp2[1])
		anim.patrol.rotation.y = pp2[2]
	if police_mat != null:
		var alarm: bool = main.S["warn"] > 0.0
		police_mat.emission_energy_multiplier = (4.0 if fposmod(t * 4.0, 1.0) < 0.5 else 0.3) if alarm else 0.35
	if anim.has("carts"):
		for c in anim.carts:
			var u := fposmod(t * 0.045 + c.ph, 1.0)
			var going := u < 0.5
			var f: float = u * 2.0 if going else (1.0 - u) * 2.0
			var pp := path_pos(c.path, f)
			c.n.position = Vector3(pp[0], 0.05, pp[1])
			c.n.rotation.y = pp[2] if going else pp[2] + PI
			c.cargo.visible = going
	if anim.has("vdoor") and is_instance_valid(anim.vdoor):
		var target := 0.0 if main.S["warn"] > 0.0 else 1.45
		anim.vdoor.rotation.y = lerp(anim.vdoor.rotation.y, target, min(1.0, 0.04 * 60.0 * get_process_delta_time()))
		anim.vwheel.rotation.x = t * (2.5 if main.S["warn"] > 0.0 else 0.25)
	if anim.has("fork") and is_instance_valid(anim.fork):
		var fu := fposmod(t * 0.08, 2.0)
		var fx: float = -12.5 + (fu if fu < 1.0 else 2.0 - fu) * 5.0
		anim.fork.position.x = fx
		anim.fork.rotation.y = 0.0 if fu < 1.0 else PI
	if anim.rotor:
		anim.rotor.rotation.y = t * 14.0
	var ph: float = main.day_phase()
	var night := 0.0
	if ph > 0.55:
		night = clamp((ph - 0.55) / 0.08, 0.0, 1.0) * clamp((1.0 - ph) / 0.05, 0.0, 1.0)
	sun.light_energy = lerp(0.82, 0.12, night)
	sun.light_color = Color("#fff4df").lerp(Color("#8fa8ff"), night)
	env.background_color = Color("#7ec8e3").lerp(Color("#0b1530"), night)
	env.ambient_light_color = Color("#d8ecff").lerp(Color("#4a5ea8"), night)
	env.ambient_light_energy = lerp(0.27, 0.2, night)
	lamp_mat.emission_energy_multiplier = night * 3.0
	win_mat.emission_energy_multiplier = night * 2.5
	var al: bool = main.S["warn"] > 0.0
	if anim.gate:
		anim.gate.position.z = 12.8 if al else 15.4
	beacon_mat.albedo_color = Color("#ff3040") if al else Color("#3a6fd8")
	beacon_mat.emission = Color("#ff2030") if (al and sin(t * 12.0) > 0.0) else Color.BLACK
	for i in range(robbers.size()):
		var r: Node3D = robbers[i]
		r.visible = al
		if al:
			r.position = Vector3(20 + max(0.0, main.S["warn"]) / 12.0 * 20.0 + i * 0.8, 0.1, 12 + i * 0.6)
			r.rotation.y = -PI / 2
