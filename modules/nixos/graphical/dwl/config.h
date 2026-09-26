#define COLOR(hex) { ((hex >> 24) & 0xFF) / 255.0f, ((hex >> 16) & 0xFF) / 255.0f, ((hex >> 8) & 0xFF) / 255.0f, (hex & 0xFF) / 255.0f }

static const int sloppyfocus = 1;
static const int bypass_surface_visibility = 0;
static const unsigned int borderpx = 1;
static const float rootcolor[] = COLOR(0x222222ff);
static const float bordercolor[] = COLOR(0x444444ff);
static const float focuscolor[] = COLOR(0x005577ff);
static const float urgentcolor[] = COLOR(0xff0000ff);
static const float fullscreen_bg[] = { 0.0f, 0.0f, 0.0f, 1.0f };

#define TAGCOUNT 9

static int log_level = WLR_ERROR;

static const Rule rules[] = {
	{ "zen", NULL, 1 << 0, 0, -1 },
	{ "com.mitchellh.ghostty", NULL, 1 << 8, 0, -1 },
	{ NULL, NULL, 0, 0, -1 },
};

static const Layout layouts[] = {
	{ "[]=", tile },
	{ "><>", NULL },
	{ "[M]", monocle },
};

static const MonitorRule monrules[] = {
	{ NULL, 0.55f, 1, 1, &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL, -1, -1 },
};

static const struct xkb_rule_names xkb_rules = { .layout = "us" };
static const int repeat_rate = 25;
static const int repeat_delay = 600;
static const int tap_to_click = 1;
static const int tap_and_drag = 1;
static const int drag_lock = 1;
static const int natural_scrolling = 0;
static const int disable_while_typing = 1;
static const int left_handed = 0;
static const int middle_button_emulation = 0;
static const enum libinput_config_scroll_method scroll_method = LIBINPUT_CONFIG_SCROLL_2FG;
static const enum libinput_config_click_method click_method = LIBINPUT_CONFIG_CLICK_METHOD_BUTTON_AREAS;
static const uint32_t send_events_mode = LIBINPUT_CONFIG_SEND_EVENTS_ENABLED;
static const enum libinput_config_accel_profile accel_profile = LIBINPUT_CONFIG_ACCEL_PROFILE_ADAPTIVE;
static const double accel_speed = 0.0;
static const enum libinput_config_tap_button_map button_map = LIBINPUT_CONFIG_TAP_MAP_LRM;

#define MODKEY WLR_MODIFIER_CTRL
#define TAGKEYS(KEY, SKEY, TAG) \
	{ MODKEY, KEY, view, { .ui = 1 << TAG } }, \
	{ MODKEY | WLR_MODIFIER_SHIFT, SKEY, tag, { .ui = 1 << TAG } }
#define SHCMD(cmd) { .v = (const char *[]){ "/bin/sh", "-c", cmd, NULL } }

static const char *termcmd[] = { "ghostty", NULL };
static const char *menucmd[] = { "@ROFI@", NULL };
static const char *lockcmd[] = { "@LOCK@", NULL };
static const char *screenshotcmd[] = { "@SCREENSHOT@", NULL };
static const char *brightnessdowncmd[] = { "@BRIGHTNESS@", "set", "5%-", NULL };
static const char *brightnessupcmd[] = { "@BRIGHTNESS@", "set", "5%+", NULL };

static const Key keys[] = {
	{ MODKEY, XKB_KEY_space, spawn, { .v = menucmd } },
	{ MODKEY | WLR_MODIFIER_SHIFT, XKB_KEY_Return, spawn, { .v = termcmd } },
	{ MODKEY, XKB_KEY_j, focusstack, { .i = +1 } },
	{ MODKEY, XKB_KEY_k, focusstack, { .i = -1 } },
	{ MODKEY, XKB_KEY_h, setmfact, { .f = -0.05f } },
	{ MODKEY, XKB_KEY_l, setmfact, { .f = +0.05f } },
	{ MODKEY, XKB_KEY_Return, zoom, { 0 } },
	{ MODKEY, XKB_KEY_Tab, view, { 0 } },
	{ MODKEY | WLR_MODIFIER_SHIFT, XKB_KEY_c, killclient, { 0 } },
	{ MODKEY, XKB_KEY_t, setlayout, { .v = &layouts[0] } },
	{ MODKEY, XKB_KEY_f, setlayout, { .v = &layouts[1] } },
	{ MODKEY, XKB_KEY_m, setlayout, { .v = &layouts[2] } },
	{ MODKEY, XKB_KEY_space, setlayout, { 0 } },
	{ MODKEY | WLR_MODIFIER_SHIFT, XKB_KEY_space, togglefloating, { 0 } },
	{ MODKEY, XKB_KEY_e, togglefullscreen, { 0 } },
	{ MODKEY, XKB_KEY_comma, focusmon, { .i = WLR_DIRECTION_LEFT } },
	{ MODKEY, XKB_KEY_period, focusmon, { .i = WLR_DIRECTION_RIGHT } },
	{ MODKEY | WLR_MODIFIER_SHIFT, XKB_KEY_comma, tagmon, { .i = WLR_DIRECTION_LEFT } },
	{ MODKEY | WLR_MODIFIER_SHIFT, XKB_KEY_period, tagmon, { .i = WLR_DIRECTION_RIGHT } },
	TAGKEYS(XKB_KEY_1, XKB_KEY_exclam, 0),
	TAGKEYS(XKB_KEY_2, XKB_KEY_at, 1),
	TAGKEYS(XKB_KEY_3, XKB_KEY_numbersign, 2),
	TAGKEYS(XKB_KEY_4, XKB_KEY_dollar, 3),
	TAGKEYS(XKB_KEY_5, XKB_KEY_percent, 4),
	TAGKEYS(XKB_KEY_6, XKB_KEY_asciicircum, 5),
	TAGKEYS(XKB_KEY_7, XKB_KEY_ampersand, 6),
	TAGKEYS(XKB_KEY_8, XKB_KEY_asterisk, 7),
	TAGKEYS(XKB_KEY_9, XKB_KEY_parenleft, 8),
	{ 0, XKB_KEY_F7, spawn, { .v = brightnessdowncmd } },
	{ 0, XKB_KEY_F8, spawn, { .v = brightnessupcmd } },
	{ 0, XKB_KEY_F11, spawn, { .v = screenshotcmd } },
	{ 0, XKB_KEY_F12, spawn, { .v = lockcmd } },
	{ MODKEY | WLR_MODIFIER_SHIFT, XKB_KEY_q, quit, { 0 } },
	{ WLR_MODIFIER_CTRL | WLR_MODIFIER_ALT, XKB_KEY_Terminate_Server, quit, { 0 } },
#define CHVT(n) { WLR_MODIFIER_CTRL | WLR_MODIFIER_ALT, XKB_KEY_XF86Switch_VT_##n, chvt, { .ui = (n) } }
	CHVT(1), CHVT(2), CHVT(3), CHVT(4), CHVT(5), CHVT(6),
	CHVT(7), CHVT(8), CHVT(9), CHVT(10), CHVT(11), CHVT(12),
};

static const Button buttons[] = {
	{ MODKEY, BTN_LEFT, moveresize, { .ui = CurMove } },
	{ MODKEY, BTN_MIDDLE, togglefloating, { 0 } },
	{ MODKEY, BTN_RIGHT, moveresize, { .ui = CurResize } },
};
