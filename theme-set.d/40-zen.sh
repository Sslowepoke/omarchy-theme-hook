#!/bin/bash

# ---- 1. Check for Zen Browser binary ----
ZEN_BIN=""
if command -v zen >/dev/null 2>&1; then
    ZEN_BIN=$(command -v zen)
elif command -v zen-browser >/dev/null 2>&1; then
    ZEN_BIN=$(command -v zen-browser)
else
    echo "Zen Browser not found. Skipping.."
    exit 0
fi

# ---- 2. Find default Zen profile ----
find_zen_profile() {
    local ini="$HOME/.zen/profiles.ini"
    if [[ ! -f "$ini" ]]; then
        echo "No Zen profiles.ini found" >&2
        return 1
    fi

    awk -F= '
    /^\[Profile/ { in_profile=1; is_default=0; path="" }
    in_profile && /^Default=1/ { is_default=1 }
    in_profile && /^Path=/ { path=$2 }
    in_profile && is_default==1 { print path; exit }
    ' "$ini"
}

zen_profile=$(find_zen_profile)
if [[ -z "$zen_profile" ]]; then
    echo "No default Zen profile found" >&2
    exit 1
fi
zen_profile=42c6ss4d.Default\ \(release\)-1

zen_path="$HOME/.zen/$zen_profile"
echo "Using Zen profile: $zen_path"

# ---- 3. Ensure chrome folder exists ----
mkdir -p "$zen_path/chrome"

# ---- 4. Enable userChrome.css ----
enable_userchrome() {
    local prefs_file="$zen_path/prefs.js"
    local pref_name="toolkit.legacyUserProfileCustomizations.stylesheets"
    local pref_line="user_pref(\"$pref_name\", true);"

    if [[ -f "$prefs_file" ]]; then
        if grep -q "user_pref(\"$pref_name\", false)" "$prefs_file"; then
            sed -i.bak "s/user_pref(\"$pref_name\", false);/user_pref(\"$pref_name\", true);/" "$prefs_file"
        elif ! grep -q "user_pref(\"$pref_name\"" "$prefs_file"; then
            echo "$pref_line" >> "$prefs_file"
        fi
    else
        # Create prefs.js if it doesn't exist
        echo "$pref_line" > "$prefs_file"
    fi
}

enable_userchrome

# ---- 5. Write colors.css ----
output_file="$zen_path/chrome/colors.css"

cat > "$output_file" << EOF
:root {
--color00: #${primary_background};
--color01: #${primary_background};
--color02: #${primary_background};
--color03: #${normal_white};
--color04: #${bright_white};
--color05: #${primary_foreground};
--color06: #${bright_white};
--color07: #${bright_white};
--color08: #${normal_red};
--color09: #${normal_yellow};
--color0A: #${bright_yellow};
--color0B: #${normal_green};
--color0C: #${normal_cyan};
--color0D: #${normal_blue};
--color0E: #${normal_magenta};
--color0F: #${bright_red};
}
EOF

# ---- 6. Write userChrome.css if missing ----
userChrome_file="$zen_path/chrome/userChrome.css"

if [[ ! -f "$userChrome_file" ]]; then
    cat > "$userChrome_file" << 'EOF'
@import url("./colors.css");

:root {
    --base00: var(--color00);
    --base01: color-mix(in srgb, var(--color00) 98%, white);
    --base02: color-mix(in srgb, var(--color00) 94%, white);
    --base03: var(--color03);
    --base04: var(--color04);
    --base05: var(--color05);
    --base06: var(--color06);
    --base07: var(--color07);
    --base08: var(--color08);
    --base09: var(--color09);
    --base0A: var(--color0A);
    --base0B: var(--color0B);
    --base0C: var(--color0C);
    --base0D: var(--color0D);
    --base0E: var(--color0E);
    --base0F: var(--color0F);
}

:root {
    --panel-separator-zap-gradient: linear-gradient(
        90deg,
        var(--base0E) 0%,
        var(--base0F) 52.08%,
        var(--base0A) 100%
    ) !important;
    --toolbarbutton-border-radius: 6px !important;
    --toolbarbutton-icon-fill: var(--base04) !important;
    --urlbarView-separator-color: var(--base01) !important;
    --urlbar-box-bgcolor: var(--base01) !important;
}

/* Tabs colors  */
#tabbrowser-tabs:not([movingtab])
    > #tabbrowser-arrowscrollbox
    > .tabbrowser-tab
    > .tab-stack
    > .tab-background[multiselected="true"],
#tabbrowser-tabs:not([movingtab])
    > #tabbrowser-arrowscrollbox
    > .tabbrowser-tab
    > .tab-stack
    > .tab-background[selected="true"] {
    background-image: none !important;
    background-color: var(--toolbar-bgcolor) !important;
}

/* Inactive tabs color */
#navigator-toolbox {
    background-color: var(--base00) !important;
}

/* Window colors  */
:root {
    --toolbar-bgcolor: var(--base01) !important;
    --tabs-border-color: var(--base01) !important;
    --lwt-sidebar-background-color: var(--base00) !important;
    --lwt-toolbar-field-focus: var(--base01) !important;
}

/* Sidebar color  */
#sidebar-box,
.sidebar-placesTree {
    background-color: var(--base00) !important;
}

.tab-background {
    border-radius: 6px !important;
    border: 0px solid rgba(0, 0, 0, 0) !important;
}
.tab-background[selected] {
    background-color: var(--base02) !important;
}

#tabbrowser-tabs {
    margin-left: 1px;
    margin-top: 3px;
    margin-bottom: 3px;
}

.tabbrowser-tab[last-visible-tab="true"] {
    border: 0px solid rgba(0, 0, 0, 0) !important;
}

toolbarbutton {
    border-radius: 6px !important;
}

/* Url Bar  */
#urlbar-input {
    accent-color: var(--base0D) !important;
}
#urlbar-input-container {
    background-color: var(--base01) !important;
    border: 0px solid rgba(0, 0, 0, 0) !important;
}

#urlbar[focused="true"] > #urlbar-background {
    box-shadow: none !important;
}

#urlbar-background {
    border-radius: 6px !important;
}

#navigator-toolbox {
    border: none !important;
}

.urlbarView-url {
    color: var(--base05) !important;
}

#star-button {
    --toolbarbutton-icon-fill-attention: var(--base0D) !important;
}

#vertical-tabs.customization-target {
    background-color: var(--base00) !important;
}
splitter#sidebar-tools-and-extensions-splitter {
    display: none !important;
}
.tools-and-extensions[aria-orientation="vertical"] {
    background-color: var(--base00) !important;
}
.tools-and-extensions.actions-list {
    background-color: var(--base00) !important;
}
#identity-box,
#trust-icon-container,
#tracking-protection-icon-container {
    fill: var(--base04) !important;
}

.logo-and-wordmark {
    display: none !important;
}
.search-inner-wrapper {
    margin-top: 10% !important;
}

.urlbar-input::placeholder,
.searchbar-textbox::placeholder {
    opacity: 1;
    color: var(--base03) !important;
}

.urlbar-input {
    color: var(--base05) !important;
}

:root {
    --arrowpanel-background: var(--base01) !important;
    --arrowpanel-border-color: var(--base00) !important;
    --color-accent-primary-active: var(--base0D) !important;
    --color-accent-primary-hover: var(--base0D) !important;
    --color-accent-primary: var(--base0D) !important;
    --focus-outline-color: var(--base00) !important;
    --icon-color-critical: var(--base08) !important;
    --icon-color-information: var(--base0D) !important;
    --icon-color-success: var(--base0B) !important;
    --icon-color-warning: var(--base0A) !important;
    --outline-color-error: var(--base08) !important;
    --tab-block-margin: 0 !important;
    --tab-border-radius: 0 !important;
    --text-color-error: var(--base08) !important;
    --toolbar-field-border-color: var(--base00) !important;
    --toolbar-field-focus-background-color: var(--base02) !important;
    --toolbar-field-focus-border-color: var(--base00) !important;
    --toolbarbutton-border-radius: 6px !important;
    --in-content-page-background: var(--base01) !important;
    --input-text-background-color: var(--base02) !important;
}
EOF
fi

# ---- 7. Write userContent.css if missing ----
userContent_file="$zen_path/chrome/userContent.css"

if [[ ! -f "$userContent_file" ]]; then
    cat > "$userContent_file" << 'EOF'
@import url("./colors.css");

:root {
    --base00: var(--color00);
    --base01: color-mix(in srgb, var(--color00) 98%, white);
    --base02: color-mix(in srgb, var(--color00) 94%, white);
    --base03: var(--color03);
    --base04: var(--color04);
    --base05: var(--color05);
    --base06: var(--color06);
    --base07: var(--color07);
    --base08: var(--color08);
    --base09: var(--color09);
    --base0A: var(--color0A);
    --base0B: var(--color0B);
    --base0C: var(--color0C);
    --base0D: var(--color0D);
    --base0E: var(--color0E);
    --base0F: var(--color0F);
}

:root {
    --color-accent-primary-active: var(--base0D) !important;
    --color-accent-primary-hover: var(--base0D) !important;
    --color-accent-primary: var(--base0D) !important;
    --focus-outline-color: var(--base00) !important;
    --icon-color-critical: var(--base08) !important;
    --icon-color-information: var(--base0D) !important;
    --icon-color-success: var(--base0B) !important;
    --icon-color-warning: var(--base0A) !important;
    --in-content-page-background: var(--base00) !important;
    --input-text-background-color: var(--base02) !important;
    --newtab-background-color-secondary: var(--base02) !important;
    --newtab-background-color: var(--base01) !important;
    --newtab-text-primary-color: var(--base05) !important;
    --newtab-text-secondary-text: var(--base04) !important;
    --newtab-wallpaper-color: var(--base01) !important;
    --outline-color-error: var(--base08) !important;
    --tab-block-margin: 0 !important;
    --tab-border-radius: 0 !important;
    --text-color-error: var(--base08) !important;
    --toolbar-field-border-color: var(--base00) !important;
    --toolbar-field-border-color: var(--base01) !important;
    --toolbar-field-focus-background-color: var(--base02) !important;
    --toolbar-field-focus-border-color: var(--base01) !important;
    --toolbarbutton-border-radius: 6px !important;
}

body {
    border: none;
}

.logo-and-wordmark {
    display: none !important;
}
.search-inner-wrapper {
    margin-top: 10% !important;
}
EOF
fi

# ---- 8. Restart Zen Browser if running ----
if pgrep -x "$(basename "$ZEN_BIN")" >/dev/null; then
    pkill -x "$(basename "$ZEN_BIN")"
    sleep 2
    # Force kill if still running
    if pgrep -x "$(basename "$ZEN_BIN")" >/dev/null; then
        pkill -9 -x "$(basename "$ZEN_BIN")"
        sleep 1
    fi
fi

# Start Zen Browser
"$ZEN_BIN" >/dev/null &

echo "Zen Browser theme updated!"
