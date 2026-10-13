#!/usr/bin/env python3
"""Capture and apply portable Orca preferences without copying profile state."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sqlite3
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent.parent
CONFIG_PATH = ROOT / "config" / "orca" / "settings.json"
SHARED_SETTINGS = set(
    """
    agentHibernationIdleMs agentStatusHooksEnabled agentWorkspaceTrustEnabled
    alwaysForceDeleteWorktrees appFontFamily appIcon artifactsEnabled
    autoRenameBranchFromWork branchPrefix branchPrefixCustom
    browserClientHostedRemoteEnabled browserGuestWorktreeRetentionBudget
    claudeAgentTeamsMode codexTerminalServerIsolation
    combinedDiffFileTreeVisibleByDefault compactWorktreeCards computerAwakeMode
    confirmClosePinnedTab ctrlTabOrderMode diffCollapseUnchangedRegions
    diffDefaultView diffShowWhitespace diffWordWrap editorAutoSave
    editorAutoSaveDelayMs editorFontFamily editorMinimapEnabled
    editorPreviewTabsEnabled editorWordWrap electronHttp1CompatibilityMode
    experimentalActivity experimentalAgentDashboardPopout
    experimentalAgentHibernation experimentalEphemeralVms experimentalMobile
    experimentalNativeChat experimentalNewWorktreeCardStyle experimentalPet
    experimentalTerminalAttention floatingTerminalEnabled
    floatingTerminalTriggerLocation followSymlinkedDirectories
    geminiCliOAuthEnabled leftSidebarAppearanceMode leftSidebarTintColor
    leftSidebarTintOpacity localhostWorktreeLabelsEnabled
    markdownReviewToolsEnabled minimizeToTrayOnClose nestWorkspaces
    nestedWorkerMaxDepth openLinksInApp openLinksInAppModifierInverts
    primarySelectionMiddleClickPaste promptCacheTimerEnabled promptCacheTtlMs
    refreshLocalBaseRefOnWorktreeCreate richMarkdownSpellcheckEnabled
    rightSidebarOpenByDefault setupScriptLaunchMode showArtifactsButton
    showAutomationsButton showGitIgnoredFiles showMenuBarIcon showMobileButton
    showSkillsButton showTasksButton showTitlebarAppName
    skipCloseTerminalWithRunningProcessConfirm skipCodexRateLimitResetConfirm
    skipDeleteArtifactConfirm skipDeleteAutomationConfirm skipDeleteWorktreeConfirm
    sourceControlCompareAgainstUpstream sourceControlGroupOrder
    sourceControlViewMode tabAutoGenerateTitle tabSwitchKeybindingSeed
    terminalActivePaneOpacity terminalAllowOsc52Clipboard
    terminalClipboardOnSelect terminalCopyTrimsGutter terminalCursorBlink
    terminalCursorStyle terminalDividerColorDark terminalDividerColorLight
    terminalDividerThicknessPx terminalFastScrollSensitivity
    terminalFocusFollowsMouse terminalFontFamily terminalFontSize
    terminalFontWeight terminalFontWeightBold terminalGpuAcceleration
    terminalHiddenDeliveryGate terminalHiddenViewParking
    terminalHiddenWorktreeRetentionBudget terminalInactivePaneOpacity
    terminalInlineImages terminalJISYenToBackslash terminalLigatures
    terminalLineHeight terminalLinkActionPopoverEnabled terminalLinkClickBehavior
    terminalMacOptionAsAlt terminalMouseHideWhileTyping
    terminalPaneOpacityTransitionMs terminalRightClickToPaste
    terminalScopeHistoryByWorktree terminalScrollSensitivity terminalScrollbackRows
    terminalShortcutPolicy terminalSshViewParking terminalThemeDark
    terminalThemeLight terminalTuiScrollSensitivity terminalUrlMiddleClickBehavior
    terminalUseSeparateLightTheme theme uiLanguage windowBackgroundBlur
    defaultTuiAgent disabledTuiAgents keepComputerAwakeWhileAgentsRun
    disabledPlugins pluginSystemEnabled terminalCustomThemes
    """.split()
)
SHARED_SETTING_OBJECTS = {
    "aiVaultSearch": {"enabled", "historyDays"},
    "nativeChatAppearance": {
        "codeFontSize",
        "fontSize",
        "matchTerminalInterface",
        "width",
    },
    "notifications": {
        "agentTaskComplete",
        "enabled",
        "suppressWhenFocused",
        "terminalBell",
        "customSoundVolume",
    },
    "worktreeVisibilityDefaults": {"external"},
}
SHARED_UI = set(
    """
    agentActivityDisplayMode agentsCompactMode agentsGroupBy
    agentsHideAutomationGeneratedWorkspaces agentsHideCliCreatedWorkspaces
    agentsHideWorkspacesFromOtherDevices agentsReadFilter agentsShowChildAgents
    agentsShowSearch alwaysShowDefaultBranchWorkspace browserDefaultZoomLevel
    editorFontZoomLevel hideAutomationGeneratedWorkspaces hideCliCreatedWorkspaces
    hideDefaultBranchWorkspace hideDetachedWorkspaces hideSleepingWorkspaces
    rightSidebarExplorerView showActiveOnly showSleepingWorkspaces sortBy
    statusBarItems statusBarUsageMode statusBarVisible syncTaskStatusFromWorkspaceBoard
    uiZoomLevel usagePercentageDisplay workspaceBoardOpacity worktreeCardProperties
    """.split()
)
DOMAINS = ("settings", "ui")


def app_data_root() -> Path:
    if sys.platform != "darwin":
        raise RuntimeError("Orca config sync currently supports macOS profiles only")
    return Path.home() / "Library" / "Application Support" / "orca"


def profile_databases(root: Path) -> list[Path]:
    return sorted((root / "profiles").glob("*/profile-state.db"))


def legacy_data_files(root: Path) -> list[Path]:
    files = [root / "orca-data.json"]
    files.extend(sorted((root / "profiles").glob("*/orca-data.json")))
    return [path for path in files if path.is_file()]


def selected_database(root: Path, profile: str | None) -> Path:
    databases = profile_databases(root)
    if profile:
        path = root / "profiles" / profile / "profile-state.db"
        if path.is_file():
            return path
        raise RuntimeError(f"Orca profile database not found: {path}")
    preferred = root / "profiles" / "local-default" / "profile-state.db"
    if preferred.is_file():
        return preferred
    if len(databases) == 1:
        return databases[0]
    if databases:
        names = ", ".join(path.parent.name for path in databases)
        raise RuntimeError(f"Multiple Orca profiles found ({names}); pass --profile")
    raise RuntimeError("No Orca profile database found")


def read_database(path: Path) -> dict[str, dict[str, Any]]:
    connection = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
    try:
        connection.execute("BEGIN")
        rows = connection.execute(
            "SELECT domain, payload, content_hash FROM profile_state_documents "
            "WHERE domain IN ('settings', 'ui')"
        ).fetchall()
        result: dict[str, dict[str, Any]] = {}
        for domain, payload, content_hash in rows:
            if hashlib.sha256(payload.encode("utf-8")).hexdigest() != content_hash:
                raise RuntimeError(f"Orca {domain} state hash mismatch in {path}")
            value = json.loads(payload)
            if not isinstance(value, dict):
                raise RuntimeError(f"Orca {domain} state is not an object in {path}")
            result[domain] = value
        if not result:
            raise RuntimeError(f"No Orca settings state found in {path}")
        return result
    finally:
        connection.close()


def read_legacy(path: Path) -> dict[str, dict[str, Any]]:
    value = json.loads(path.read_text(encoding="utf-8"))
    result = {domain: value[domain] for domain in DOMAINS if isinstance(value.get(domain), dict)}
    if not result:
        raise RuntimeError(f"No Orca settings state found in {path}")
    return result


def project_domain(
    domain: str, value: dict[str, Any]
) -> dict[str, Any]:
    if domain == "settings":
        projected = {key: value[key] for key in sorted(SHARED_SETTINGS) if key in value}
        for key, fields in SHARED_SETTING_OBJECTS.items():
            nested = value.get(key)
            if isinstance(nested, dict):
                selected = {field: nested[field] for field in sorted(fields) if field in nested}
                if selected:
                    projected[key] = selected
        return projected
    return {key: value[key] for key in sorted(SHARED_UI) if key in value}


def capture(args: argparse.Namespace) -> None:
    root = app_data_root()
    databases = profile_databases(root)
    if databases:
        source = selected_database(root, args.profile)
        state = read_database(source)
    else:
        files = legacy_data_files(root)
        if not files:
            raise RuntimeError("No Orca profile data found; launch Orca once first")
        if len(files) > 1:
            raise RuntimeError("Multiple legacy Orca profiles found; capture is ambiguous")
        source = files[0]
        state = read_legacy(source)
    portable = {
        "version": 1,
        "settings": project_domain("settings", state.get("settings", {})),
        "ui": project_domain("ui", state.get("ui", {})),
    }
    CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
    CONFIG_PATH.write_text(json.dumps(portable, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Captured {len(portable['settings'])} settings and {len(portable['ui'])} UI preferences from {source.parent.name}")


def load_config() -> dict[str, Any]:
    config = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    if not isinstance(config, dict) or config.get("version") != 1:
        raise RuntimeError(f"Unsupported Orca config format in {CONFIG_PATH}")
    for domain in DOMAINS:
        if not isinstance(config.get(domain, {}), dict):
            raise RuntimeError(f"Orca config field {domain} must be an object")
    allowed = {
        "settings": SHARED_SETTINGS | set(SHARED_SETTING_OBJECTS),
        "ui": SHARED_UI,
    }
    for domain in DOMAINS:
        unknown = set(config.get(domain, {})) - allowed[domain]
        if unknown:
            raise RuntimeError(f"Unsupported shared {domain} keys: {', '.join(sorted(unknown))}")
        for key, fields in SHARED_SETTING_OBJECTS.items() if domain == "settings" else ():
            nested = config.get(domain, {}).get(key, {})
            if not isinstance(nested, dict) or set(nested) - fields:
                raise RuntimeError(f"Unsupported shared settings fields under {key}")
    return config


def merge_domain(domain: str, current: dict[str, Any], incoming: dict[str, Any]) -> int:
    changed = 0
    scalar_keys = SHARED_SETTINGS if domain == "settings" else SHARED_UI
    for key in scalar_keys:
        if key not in incoming or key not in current:
            continue
        if type(current[key]) is not type(incoming[key]):
            continue
        if current[key] != incoming[key]:
            current[key] = incoming[key]
            changed += 1
    if domain == "settings":
        for key, fields in SHARED_SETTING_OBJECTS.items():
            source = incoming.get(key)
            target = current.get(key)
            if not isinstance(source, dict) or not isinstance(target, dict):
                continue
            for field in fields:
                if field not in source or field not in target:
                    continue
                if type(target[field]) is type(source[field]) and target[field] != source[field]:
                    target[field] = source[field]
                    changed += 1
    return changed


def apply_database(path: Path, config: dict[str, Any]) -> int:
    connection = sqlite3.connect(path)
    try:
        connection.execute("PRAGMA busy_timeout = 2000")
        connection.execute("BEGIN IMMEDIATE")
        columns = {
            row[1] for row in connection.execute("PRAGMA table_info(profile_state_documents)")
        }
        required = {"domain", "payload", "revision", "updated_at", "content_hash"}
        if not required.issubset(columns):
            raise RuntimeError(f"Unsupported Orca profile database schema: {path}")
        rows = connection.execute(
            "SELECT domain, payload, revision, content_hash FROM profile_state_documents "
            "WHERE domain IN ('settings', 'ui')"
        ).fetchall()
        updated: list[tuple[str, str, int, str]] = []
        for domain, payload, revision, content_hash in rows:
            if hashlib.sha256(payload.encode("utf-8")).hexdigest() != content_hash:
                raise RuntimeError(f"Orca {domain} state hash mismatch in {path}")
            current = json.loads(payload)
            if not isinstance(current, dict):
                raise RuntimeError(f"Orca {domain} state is not an object in {path}")
            changed = merge_domain(domain, current, config.get(domain, {}))
            if changed:
                serialized = json.dumps(current, ensure_ascii=False, separators=(",", ":"))
                digest = hashlib.sha256(serialized.encode("utf-8")).hexdigest()
                updated.append((domain, serialized, revision + 1, digest))
        now = int(time.time() * 1000)
        for domain, payload, revision, digest in updated:
            connection.execute(
                "UPDATE profile_state_documents SET payload = ?, revision = ?, "
                "updated_at = ?, content_hash = ? WHERE domain = ?",
                (payload, revision, now, digest, domain),
            )
        connection.commit()
        return len(updated)
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()


def write_legacy(path: Path, config: dict[str, Any]) -> int:
    value = json.loads(path.read_text(encoding="utf-8"))
    changed = 0
    for domain in DOMAINS:
        current = value.get(domain)
        if isinstance(current, dict):
            changed += merge_domain(domain, current, config.get(domain, {}))
    if changed:
        mode = path.stat().st_mode & 0o777
        with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", dir=path.parent, delete=False
        ) as temporary:
            json.dump(value, temporary, ensure_ascii=False, separators=(",", ":"))
            temporary.write("\n")
            temp_path = Path(temporary.name)
        os.chmod(temp_path, mode)
        temp_path.replace(path)
    return changed


def orca_is_running() -> bool:
    result = subprocess.run(["pgrep", "-x", "Orca"], capture_output=True, text=True, check=False)
    if result.returncode == 0:
        return True
    if result.returncode == 1:
        return False
    raise RuntimeError(f"Could not check Orca process state: {result.stderr.strip()}")


def apply(_: argparse.Namespace) -> None:
    if orca_is_running():
        print("Orca is open; quit it, then run mise exec -- python ./scripts/orca-config-sync.py apply")
        return
    config = load_config()
    root = app_data_root()
    databases = profile_databases(root)
    if databases:
        changed = 0
        for path in databases:
            changed += apply_database(path, config)
        print(f"Applied Orca preferences to {len(databases)} profile(s); {changed} state document(s) changed")
        return
    files = legacy_data_files(root)
    if files:
        changed = sum(write_legacy(path, config) for path in files)
        print(f"Applied Orca preferences to {len(files)} profile file(s); {changed} value(s) changed")
        return
    print("No Orca profile data yet; launch Orca once, quit, then run ./install")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    capture_parser = commands.add_parser("capture", help="write portable preferences from Orca")
    capture_parser.add_argument("--profile", help="profile name; defaults to local-default")
    capture_parser.set_defaults(run=capture)
    apply_parser = commands.add_parser("apply", help="merge tracked preferences into Orca profiles")
    apply_parser.set_defaults(run=apply)
    args = parser.parse_args()
    try:
        args.run(args)
    except (OSError, sqlite3.Error, json.JSONDecodeError, RuntimeError) as error:
        print(f"orca-config-sync: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
