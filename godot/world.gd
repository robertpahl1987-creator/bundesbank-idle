extends Node3D
## 3D-Werk: Hallen, Maschinen, Lager, Fuhrpark, Schutz

var main
var dirty := true
var mats := {}
var meshes := {}
var dyn: Node3D
var anim := {}
var cam: Camera3D
var zoom := 1.15
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

func sphere(r: float, c: String, x: float, y: float, z: float, p: Node3D) -> MeshInstance3D:
	var key := "s%.3f" % r
	if not meshes.has(key):
		var sm := SphereMesh.new()
		sm.radius = r
		sm.height = r * 2.0
		sm.radial_segments = 10
		sm.rings = 6
		meshes[key] = sm
	var mi := MeshInstance3D.new()
	mi.mesh = meshes[key]
	mi.material_override = mat(c)
	mi.position = Vector3(x, y, z)
	p.add_child(mi)
	return mi

func person(col: String, p: Node3D, helmet := false) -> Node3D:
	var g := Node3D.new()
	B(0.34, 0.3, 0.24, "#2b3436", 0, 0.15, 0, g)
	B(0.4, 0.5, 0.28, col, 0, 0.55, 0, g)
	B(0.28, 0.28, 0.28, "#f1c9a5", 0, 0.95, 0, g)
	if helmet:
		B(0.32, 0.1, 0.32, "#ffd21a", 0, 1.13, 0, g)
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
	apply_quality()
	fit()

func build_static() -> void:
	B(160, 0.2, 160, "#2f7d2b", 0, -0.1, 0)
	B(35, 0.1, 31, "#8e9a9e", 0, 0.05, 0)
	# Münzhalle (warm)
	B(14, 0.14, 14, "#e2b874", -8, 0.12, -6)
	B(14, 1.5, 0.3, "#c8553a", -8, 0.85, -13)
	B(0.3, 1.5, 14, "#c8553a", -15, 0.85, -6)
	B(0.3, 0.5, 14, "#c8553a", -1, 0.35, -6)
	B(14, 0.5, 0.3, "#c8553a", -8, 0.35, 1)
	# Druckhalle (blau)
	B(14, 0.14, 14, "#9fbde6", 8, 0.12, -6)
	B(14, 1.5, 0.3, "#3d6fb0", 8, 0.85, -13)
	B(0.3, 0.5, 14, "#3d6fb0", 1, 0.35, -6)
	B(0.3, 0.5, 14, "#3d6fb0", 15, 0.35, -6)
	B(14, 0.5, 0.3, "#3d6fb0", 8, 0.35, 1)
	# Tresor
	B(10, 0.14, 8, "#c9b27a", -10, 0.12, 7)
	var door := C(1.1, 1.1, 0.3, "#a8b1b4", -4.8, 1.3, 7)
	door.rotation.z = PI / 2
	var dc := C(0.5, 0.5, 0.35, "#ffc23d", -4.75, 1.3, 7)
	dc.rotation.z = PI / 2
	# Hof, Rampe, Straße
	B(19, 0.08, 9, "#4d5559", 6, 0.12, 7.5)
	B(1.2, 0.6, 7, "#a9b0b0", -3.6, 0.4, 7)
	B(80, 0.06, 3, "#4a5154", 30, 0.1, 12.8)
	for i in range(14):
		B(1.4, 0.07, 0.15, "#ffffff", 2 + i * 4, 0.12, 12.8)
	B(3, 0.06, 9, "#4a5154", 14.5, 0.1, 8.5)
	# Bäume
	var trees := [[-22, -18], [-24, -6], [-21, 6], [-23, 17], [-10, -20], [2, -21], [14, -19], [24, -14], [23, -2], [26, 4], [-6, 21], [6, 20], [22, 20], [-16, 20], [30, 22], [-28, 0], [-30, 12], [34, -8]]
	for i in range(trees.size()):
		var x: float = trees[i][0]
		var z: float = trees[i][1]
		C(0.15, 0.2, 0.8, "#7a5532", x, 0.4, z, null, 6)
		C(0.0, 1.1 + (i % 3) * 0.2, 2.4, "#2e7d32" if i % 2 else "#3b8f3a", x, 1.9, z, null, 7)
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
		var ol := OmniLight3D.new()
		ol.position = Vector3(lp[0], 2.9, lp[1])
		ol.light_color = Color("#ffd27a")
		ol.omni_range = 7.0
		ol.light_energy = 0.0
		add_child(ol)
		lamps.append(ol)
	for wx in [-12.0, -8.0, -4.0]:
		var w1 := B(1.6, 0.5, 0.05, "#2a3a40", wx, 1.0, -12.82)
		w1.material_override = win_mat
	for wx in [4.0, 8.0, 12.0]:
		var w2 := B(1.6, 0.5, 0.05, "#2a3a40", wx, 1.0, -12.82)
		w2.material_override = win_mat
	label3d("Münzhalle", -8, 3.4, -14)
	label3d("Druckhalle", 8, 3.4, -14)
	label3d("Tresor", -10, 3.6, 7)
	label3d("Fuhrpark", 6, 2.4, 7.5)
	for i in range(3):
		var r := person("#222831", self)
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
		var z: float = (-11.2 + (i - 5) * 3.2) if note else (-11.4 + i * 2.6)
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
			for k in range(3):
				var sk := sphere(0.26, "#c9b48a", x0 + L + 0.35 + (k % 2) * 0.4, 0.6, z - 0.25 + k * 0.25, dyn)
				sk.scale = Vector3(1, 1.15, 1)
		# Ware auf dem Band
		var its := []
		for k in range(min(10, 3 + int(log(c + 1) / log(2.0)))):
			var m: MeshInstance3D = B(0.55, 0.06, 0.32, l.col, x0, 0.6, z, dyn) if note else C(0.22, 0.22, 0.08, l.col, x0, 0.6, z, dyn)
			its.append(m)
		anim.belts.append({l = l, its = its, x0 = x0, L = L, ph = randf()})
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
				var ram := B(0.36, 0.22, 0.4, "#d9e0e3", mx, 1.15, z, dyn)
				anim.pist.append({m = ram, ph = j * 0.7, y = 1.15, kind = "ram"})
				C(0.22, 0.09, 0.3, "#aeb6b9", mx, 1.05, z - 0.82, dyn, 8)
				C(0.21, 0.21, 0.03, l.col, mx, 1.2, z - 0.82, dyn, 10)
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
				anim.pist.append({m = rl, ph = j, kind = "roll"})
				B(0.5, 0.22, 0.95, "#3a4448", mx, 1.48, z, dyn)
				B(0.44, 0.06, 0.89, INK[j % 5], mx, 1.6, z, dyn)
				B(0.3, 0.3, 0.06, "#d9e0e3", mx, 0.75, z + 0.7, dyn)
				var scr2 := B(0.22, 0.16, 0.02, "#3fd68a", mx, 0.78, z + 0.735, dyn)
				scr2.material_override = mat("#3fd68a", 1.0, true)
				B(0.04, 0.95, 0.04, "#ffc23d", mx + 0.48, 0.68, z + 0.68, dyn)
				if ms > 0:
					var lm2 := B(0.16, 0.12, 0.16, lamp, mx - 0.3, 1.42, z - 0.5, dyn)
					lm2.material_override = mat(lamp, 1.0, true)
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
		for j in range(wk):
			var p := person("#3f6fb5" if note else "#ff7a1a", dyn, true)
			p.position = Vector3(x0 + 1.5 + j * 2.2, 0.2, z + 1.15)
			anim.work.append({p = p, x = x0 + 1.5 + j * 2.2, ph = randf() * 6.0})
	# Tresorlager wächst mit der Stufe
	var lvl: int = min(int(S["lv"]), 6)
	var wh := 0.7 + lvl * 0.12
	B(10, wh, 0.3, "#55626a", -10, wh / 2 + 0.1, 3, dyn)
	B(0.3, 2 + lvl * 0.25, 8, "#55626a", -15, 1.1 + lvl * 0.12, 7, dyn)
	B(0.3, wh, 8, "#55626a", -5, wh / 2 + 0.1, 7, dyn)
	B(10, wh, 0.3, "#55626a", -10, wh / 2 + 0.1, 11, dyn)
	for k in range(lvl):
		B(0.25, 0.25, 0.25, "#ffc23d", -14 + k * 0.45, wh + 0.25, 11, dyn)
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
	build_fleet()
	last_pile = -1

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
		B(6, 0.4, 4, "#e9e2d0", -24, 0.2, -6, dyn)
		for k in range(5):
			C(0.25, 0.25, 2.2, "#f4efe2", -26.4 + k * 1.2, 1.5, -4.3, dyn, 10)
		B(6.2, 0.5, 4.2, "#e9e2d0", -24, 2.85, -6, dyn)
		var roof := C(0.0, 3.3, 1.2, "#c9b27a", -24, 3.7, -6, dyn, 4)
		roof.rotation.y = PI / 4
		var ml := Label3D.new()
		ml.text = "Museum · %d" % (int(S["rep"]) + S["coins"].size())
		ml.font_size = 80
		ml.pixel_size = 0.011
		ml.outline_size = 20
		ml.outline_modulate = Color("#0a4f4a")
		ml.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		ml.no_depth_test = true
		ml.position = Vector3(-24, 5.2, -6)
		dyn.add_child(ml)
	# Zweigwerke (in der Ferne)
	var spots := {"mainz": [34, -22, "#c8553a"], "leipzig": [40, -6, "#0e8a7c"], "muenchen": [36, 10, "#3d6fb0"], "hamburg": [44, 24, "#8a5a9e"]}
	var names := {"mainz": "Mainz", "leipzig": "Leipzig", "muenchen": "München", "hamburg": "Hamburg"}
	for id in spots.keys():
		if S["sites"].get(id, false):
			var sp2: Array = spots[id]
			B(6, 0.12, 5, "#8e9a9e", sp2[0], 0.08, sp2[1], dyn)
			B(4.5, 2.0, 3.2, sp2[2], sp2[0], 1.1, sp2[1], dyn)
			B(4.7, 0.25, 3.4, "#2b3436", sp2[0], 2.2, sp2[1], dyn)
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
			var pm := person("#f4f5f2", dyn)
			B(0.08, 0.32, 0.02, "#c8102e", 0, 0.6, 0.15, pm)
			B(0.42, 0.2, 0.3, "#2b3436", 0, 0.22, 0, pm)
			pm.position = Vector3(mp[0], 0.15, mp[1])

func build_security() -> void:
	var g3 := cnt("g", "g3")
	if g3 > 0:
		B(35, 1, 0.12, "#9aa3a8", 0, 0.6, -15.6, dyn, 0.85)
		B(0.12, 1, 31.2, "#9aa3a8", -17.6, 0.6, 0, dyn, 0.85)
		B(0.12, 1, 26.4, "#9aa3a8", 17.6, 0.6, -2.4, dyn, 0.85)
		B(35, 1, 0.12, "#9aa3a8", 0, 0.6, 15.6, dyn, 0.85)
		anim.gate = B(0.3, 1.3, 3, "#3d4a52", 17.6, 0.75, 12.8, dyn)
	var g1 := cnt("g", "g1")
	if g1 > 0:
		B(1.8, 1.6, 1.8, "#efe7d4", 15.5, 0.9, 15, dyn)
		B(2.1, 0.25, 2.1, "#c8102e", 15.5, 1.8, 15, dyn)
	var ng: int = min(g1, 14)
	for j in range(ng):
		anim.guards.append({p = person("#1f3a5f", dyn), u = float(j) / ng})
	var cams := [[-17, -15], [17, -15], [-17, 15], [17, 11], [0, -15], [0, 2.4], [-17, 0], [17, 0]]
	for j in range(min(cnt("g", "g2"), 8)):
		var x: float = cams[j][0]
		var z: float = cams[j][1]
		C(0.08, 0.1, 3, "#5a6163", x, 1.5, z, dyn, 6)
		anim.cams.append(B(0.6, 0.3, 0.3, "#e8ecee", x, 3.05, z, dyn))
	beacon.visible = cnt("g", "g4") > 0
	if cnt("g", "g5") > 0:
		B(1.4, 1.4, 1.4, "#5a6670", -13.8, 0.85, 9.7, dyn)
		B(1.4, 1.4, 1.4, "#5a6670", -12.2, 0.85, 9.7, dyn)
	for j in range(min(cnt("g", "g6"), 3)):
		var x2 := 20.0 + j * 2.6
		B(2, 0.7, 1, "#f4f5f2", x2, 0.5, 10.2, dyn)
		B(2, 0.12, 1.02, "#2a5bd7", x2, 0.55, 10.2, dyn)
		B(1, 0.4, 0.9, "#f4f5f2", x2, 1.0, 10.2, dyn)
		var bl := B(0.3, 0.15, 0.3, "#3a6fd8", x2, 1.3, 10.2, dyn)
		bl.material_override = mat("#3a6fd8", 1.0, true)
	if cnt("g", "g7") > 0:
		B(2.6, 1.3, 1.2, "#1d2326", 21, 0.8, 16, dyn)
		for j in range(3):
			person("#1d2326", dyn).position = Vector3(19 + j * 0.7, 0.1, 17.5)
	if cnt("g", "g8") > 0:
		B(3, 1.4, 1.3, "#4b5a32", 24, 0.85, 9.6, dyn)
		B(1.2, 1, 1.3, "#4b5a32", 26, 0.65, 9.6, dyn)
		for j in range(min(cnt("g", "g8"), 4)):
			person("#4b5a32", dyn).position = Vector3(19.5 + j * 0.8, 0.1, 14.4)
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
		var tr := Node3D.new()
		var wheels := []
		if k == "v1":
			B(1.5, 0.9, 0.9, "#f2f2f2", -0.1, 0.65, 0, tr)
			B(0.5, 0.6, 0.85, "#bfe3ef", 0.6, 0.7, 0, tr)
			wheels = [[-0.6, 0.45], [0.5, 0.45], [-0.6, -0.45], [0.5, -0.45]]
		elif k == "v2":
			B(1.9, 1.1, 1, "#3d4b4f", -0.3, 0.75, 0, tr)
			B(0.8, 0.8, 0.95, "#e6e9ea", 0.95, 0.6, 0, tr)
			B(1.9, 0.12, 1.02, "#ffc23d", -0.3, 0.6, 0, tr)
			wheels = [[-0.9, 0.5], [0.9, 0.5], [-0.9, -0.5], [0.9, -0.5]]
		elif k == "v3":
			B(2.2, 1.2, 1.1, "#55666b", -0.3, 0.8, 0, tr)
			B(0.8, 0.9, 1.05, "#3d4b4f", 1.1, 0.65, 0, tr)
			var bl := B(0.25, 0.12, 0.25, "#3a6fd8", 1.1, 1.15, 0, tr)
			bl.material_override = mat("#3a6fd8", 1.0, true)
			wheels = [[-1, 0.55], [1, 0.55], [-1, -0.55], [1, -0.55]]
		else:
			B(3, 1.4, 1.1, "#0e8a7c", -0.6, 0.95, 0, tr)
			B(0.9, 1, 1.05, "#e6e9ea", 1.3, 0.7, 0, tr)
			B(3, 0.14, 1.12, "#ffc23d", -0.6, 0.8, 0, tr)
			wheels = [[-1.6, 0.55], [-0.8, 0.55], [1.2, 0.55], [-1.6, -0.55], [-0.8, -0.55], [1.2, -0.55]]
		for w in wheels:
			var wm := C(0.22, 0.22, 0.15, "#1b2224", w[0], 0.22, w[1], tr, 8)
			wm.rotation.x = PI / 2
		if int(main.S["escort"]) > 0 and j % max(1, 4 - int(main.S["escort"]) / 2) == 0:
			var esc := B(0.3, 0.14, 0.3, "#3a6fd8", 0.2, 1.42, 0, tr)
			esc.material_override = mat("#3a6fd8", 1.0, true)
		dyn.add_child(tr)
		anim.trucks.append({t = tr, u = float(j) / fleet.size()})
	if cnt("v", "v5") > 0:
		B(80, 0.08, 0.5, "#7a6a5a", 20, 0.1, 19.5, dyn)
		var train := Node3D.new()
		for j in range(4):
			B(2.6, 1.2, 1, "#c8102e" if j > 0 else "#2f3739", j * -2.8, 0.8, 0, train)
		train.position.z = 19.5
		dyn.add_child(train)
		anim.train = train
	if cnt("v", "v6") > 0:
		var pl := Node3D.new()
		B(3, 0.5, 0.5, "#f4f5f2", 0, 0, 0, pl)
		B(0.8, 0.1, 3.4, "#dfe3e5", 0.2, 0, 0, pl)
		B(0.5, 0.7, 0.1, "#0e8a7c", -1.4, 0.4, 0, pl)
		dyn.add_child(pl)
		anim.plane = pl
	if cnt("v", "v7") > 0:
		B(2.4, 0.1, 2.4, "#5a6163", -10, 2.25, 9, dyn)
		var h := Node3D.new()
		B(1.4, 0.6, 0.7, "#c8102e", 0, 0, 0, h)
		anim.rotor = B(2.6, 0.04, 0.15, "#2b3436", 0, 0.4, 0, h)
		h.position = Vector3(-10, 2.65, 9)
		dyn.add_child(h)
	if cnt("v", "v8") > 0:
		B(4, 2.4, 3.2, "#3f6f7d", 11, 1.3, 5.2, dyn)
		B(4.2, 0.2, 3.4, "#0e8a7c", 11, 2.6, 5.2, dyn)

func piles() -> void:
	var slots: int = 10 + 4 * min(int(main.S["lv"]), 5)
	var n := int(round(min(1.0, float(main.S["stock"]) / main.cap()) * slots))
	if n == last_pile:
		return
	last_pile = n
	if pile_node:
		pile_node.queue_free()
	pile_node = Node3D.new()
	add_child(pile_node)
	for i in range(n):
		B(1.1, 0.45, 0.7, "#6fae8f" if i % 3 == 2 else "#ffc23d", -14 + (i % 5) * 1.7, 0.42, 4.3 + int(i / 5) * 1.1, pile_node)

# ---------------------------------------------------------------- Wege
const TRUCK_PATH := [[-2.8, 5.0], [6.0, 5.5], [14.5, 9.0], [14.5, 12.8], [42.0, 12.8]]
func along(u: float) -> Array:
	var segs := []
	var tot := 0.0
	for i in range(TRUCK_PATH.size() - 1):
		var a: Array = TRUCK_PATH[i]
		var b: Array = TRUCK_PATH[i + 1]
		var l := Vector2(b[0] - a[0], b[1] - a[1]).length()
		segs.append(l)
		tot += l
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

func apply_quality() -> void:
	var high: bool = int(main.S.get("gfx", 1)) == 1
	sun.shadow_enabled = high
	var vp := get_viewport()
	if vp is SubViewport:
		vp.msaa_3d = Viewport.MSAA_2X if high else Viewport.MSAA_DISABLED
	for l in lamps:
		l.visible = high

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
	tx = clamp(tx, -22.0, 26.0)
	tz = clamp(tz, -18.0, 20.0)
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
	if dirty:
		dirty = false
		build()
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
		for k in range(b.its.size()):
			var f := fposmod(t * s + float(k) / b.its.size() + b.ph, 1.0)
			b.its[k].position.x = b.x0 + f * b.L
	for p in anim.pist:
		match p.kind:
			"roll":
				p.m.rotation.y = t * 3.0 + p.ph
			"swing":
				p.m.rotation.z = sin(t * 2.0 + p.ph) * 0.7
			_:
				p.m.position.y = p.y - abs(sin(t * 4.0 + p.ph)) * 0.3
	for w in anim.work:
		w.p.position.x = w.x + sin(t * 0.7 + w.ph) * 1.2
		w.p.rotation.y = PI / 2 if cos(t * 0.7 + w.ph) > 0 else -PI / 2
	for g in anim.guards:
		var pr := perim(g.u + t * 0.012)
		g.p.position = Vector3(pr[0], 0.1, pr[1])
		g.p.rotation.y = pr[2] + PI / 2
	for i in range(anim.cams.size()):
		anim.cams[i].rotation.y = sin(t * 0.6 + i) * 0.9
	var dsp: float = 0.02 + min(0.08, log(main.deliv() + 1.0) / log(10.0) * 0.012)
	for tr in anim.trucks:
		var a := along(fposmod(tr.u + t * dsp, 1.0))
		tr.t.position = Vector3(a[0], 0, a[1])
		tr.t.rotation.y = a[2]
	for d in anim.drones:
		d.d.position = Vector3(cos(t * 0.4 + d.ph) * 12, 6 + sin(t * 2 + d.ph) * 0.3, sin(t * 0.4 + d.ph) * 10)
	if anim.train:
		anim.train.position.x = fposmod(t * 6.0, 90.0) - 40.0
	if anim.plane:
		var u := fposmod(t * 0.04, 1.0)
		anim.plane.position = Vector3(-40 + u * 90, 12, -30 + u * 50)
		anim.plane.rotation.y = -atan2(50, 90)
	if anim.rotor:
		anim.rotor.rotation.y = t * 14.0
	var ph: float = main.day_phase()
	var night := 0.0
	if ph > 0.55:
		night = clamp((ph - 0.55) / 0.08, 0.0, 1.0) * clamp((1.0 - ph) / 0.05, 0.0, 1.0)
	sun.light_energy = lerp(0.95, 0.12, night)
	sun.light_color = Color("#fff4df").lerp(Color("#8fa8ff"), night)
	env.background_color = Color("#7ec8e3").lerp(Color("#0b1530"), night)
	env.ambient_light_color = Color("#d8ecff").lerp(Color("#4a5ea8"), night)
	env.ambient_light_energy = lerp(0.32, 0.22, night)
	lamp_mat.emission_energy_multiplier = night * 3.0
	win_mat.emission_energy_multiplier = night * 2.5
	for l in lamps:
		l.light_energy = night * 1.6
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
