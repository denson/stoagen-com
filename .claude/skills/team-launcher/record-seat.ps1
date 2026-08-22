#requires -Version 7
<#
.SYNOPSIS
  Record (or refresh) one seat row in the durable Stoa seat registry (stoa--p7c / Arc 67, DC2).

.DESCRIPTION
  The registry is a JSONL manifest attached on the `beadwork` branch at
  `attachments/stoa--reg/seat-registry.jsonl` — one JSON object per line, one row per active seat.
  This helper performs a read-modify-rewrite-attach:
    1. `git show beadwork:attachments/stoa--reg/seat-registry.jsonl` -> the current manifest
       (empty if the attachment does not yet exist).
    2. Drop any existing line whose (seat, machine) matches the seat being recorded (idempotent
       re-record / liveness refresh — re-recording a seat REPLACES its row, never appends a dup).
    3. Append the new JSON row to a temp file (existing rows preserved verbatim).
    4. `bw attach stoa--reg <temp> --name seat-registry.jsonl` (overwrites the stored path; commits
       to beadwork with a single-line intent).

  Callable STANDALONE, without spawning a live agent session:
    - the launcher calls it per seat after a launch (terminal path; it minted the SessionId);
    - a desktop seat calls it on activation with its `$CLAUDE_CODE_SESSION_ID`-discovered sid
      (the self-record fallback — see the team-launcher SKILL.md);
    - VERA calls it directly with a synthetic row to exercise the real round-trip (probe P3).

  Identity/signing convention for the recorded seats: `operating-disciplines.md` §28.9.

.PARAMETER Seat
  The canonical ROLE_slug mnemonic (the `[for:]` routing address), e.g. POLYBIUS_the-stoa.
.PARAMETER Name
  The human-friendly, space-free, non-unique display name, e.g. Polybius_the_Stoa.
.PARAMETER SessionId
  The per-machine session-id (the unique handle). May be empty for a not-yet-discovered seat.
.PARAMETER Project
  Project slug, e.g. the-stoa.
.PARAMETER Machine
  Hostname (disambiguates per-machine ids).
.PARAMETER Role
  Free-form role label, e.g. floor-manager / orchestrator.
.PARAMETER Tier
  Tier label, e.g. project / user.
.PARAMETER Composition
  Arc 68 (stoa--pk4, DC4): the team composition this seat belongs to — one of
  'standard' | 'custom-agent' | 'custom-workflow' | 'custom-agent+workflow'.
  Optional; defaults to 'standard' so every existing caller writes a valid row.
.PARAMETER Gauntlet
  Arc 68 (stoa--pk4, DC4): the gauntlet posture at launch — 'required' (default)
  or 'waived:<reason>' (set by the launcher's -GauntletWaiver flag, a POLYBIUS/
  PRINCIPAL action; a seat cannot self-grant it). Optional; defaults to 'required'.
.PARAMETER ChainRole
  Arc 68 (stoa--pk4, DC4): this seat's place in the chain — e.g. floor-manager |
  orchestrator | team-architect | workflow-architect. Optional; falls back to $Role.
.PARAMETER Ticket
  Arc 68 (stoa--pk4, C5): the bw ticket the registry is attached to. Defaults to
  'stoa--reg' (the ONE registry). Parameterized so verification can drive a bogus
  ticket to exercise the real attach-failure branch distinctly from the PATH-miss
  branch — every existing caller's behavior is preserved by the default.

.EXAMPLE
  ./record-seat.ps1 -Seat POLYBIUS_the-stoa -Name Polybius_the_Stoa `
    -SessionId 88cd8c37-f3ff-4904-9b0e-efafaad48f70 -Project the-stoa `
    -Machine $(hostname) -Role floor-manager -Tier project
#>
param(
  [Parameter(Mandatory)] [string] $Seat,
  [Parameter(Mandatory)] [string] $Name,
  [string] $SessionId,
  [Parameter(Mandatory)] [string] $Project,
  [Parameter(Mandatory)] [string] $Machine,
  [string] $Role = '',
  [string] $Tier = '',
  # --- Arc 68 (stoa--pk4) DC4 additive fields (all optional, safe defaults) ---
  [string] $Composition = 'standard',
  [string] $Gauntlet    = 'required',
  [string] $ChainRole   = '',
  # --- Arc 68 (stoa--pk4) C5: parameterized registry ticket (default = the ONE registry) ---
  [string] $Ticket      = 'stoa--reg'
)

$ErrorActionPreference = 'Stop'

# C5 (stoa--pk4): the registry ticket is the -Ticket param (default 'stoa--reg').
# Used throughout below ($readPath, the attach, the warning strings) so a probe can
# drive a bogus ticket without editing the script under test.
$ticket    = $Ticket
# `bw attach <id> <file> --name <attachName>` stores bytes at attachments/<id>/<attachName>.
# So --name is the path-UNDER-attachments/<id>/ (just the filename here); the full read path
# on the beadwork branch is attachments/<id>/<attachName>. Do NOT pass the full attachments/...
# path as --name or it doubles (attachments/<id>/attachments/<id>/<file>).
$attachName = 'seat-registry.jsonl'
$readPath   = "attachments/$ticket/$attachName"

# --- 1. Read the current manifest from the beadwork branch (empty if absent) ---
# `git show` exits non-zero if the path does not exist on the branch; treat that as "no manifest yet".
$current = & git show "beadwork:$readPath" 2>$null
if ($LASTEXITCODE -ne 0) { $current = @() }

# Normalize to an array of non-empty trimmed lines.
$lines = @()
if ($current) {
  $lines = @($current) | ForEach-Object { $_ } | Where-Object { $_ -ne $null -and ([string]$_).Trim().Length -gt 0 }
}

# --- 2. Drop any existing row matching (seat, machine) — idempotent replace ---
$kept = @()
foreach ($line in $lines) {
  $keep = $true
  try {
    $obj = $line | ConvertFrom-Json -ErrorAction Stop
    if ($obj.seat -eq $Seat -and $obj.machine -eq $Machine) { $keep = $false }
  } catch {
    # Unparseable line: keep it verbatim (do not silently discard foreign content).
    $keep = $true
  }
  if ($keep) { $kept += $line }
}

# --- 3. Build the new row + append ---
# Arc 68 (stoa--pk4) DC4: composition/gauntlet/chain_role are ADDITIVE optional
# fields on the SAME stoa--reg row-shape (does NOT rebuild the Arc-67 schema).
# chain_role falls back to $Role when not passed; JSONL tolerates older rows that
# omit these keys, so a caller that does not pass them still writes a valid row.
$chainRoleVal = if ([string]::IsNullOrEmpty($ChainRole)) { $Role } else { $ChainRole }
$row = [ordered]@{
  seat        = $Seat
  name        = $Name
  session_id  = if ([string]::IsNullOrEmpty($SessionId)) { $null } else { $SessionId }
  project     = $Project
  machine     = $Machine
  role        = $Role
  tier        = $Tier
  composition = $Composition
  gauntlet    = $Gauntlet
  chain_role  = $chainRoleVal
  launched_at = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
  status      = 'alive'
}
$newLine = ($row | ConvertTo-Json -Compress -Depth 4)
$kept += $newLine

# --- 4. Write to a temp file + attach (overwrites the stored path; commits to beadwork) ---
# Fixed-name temp file (no $VAR in any destructive op); the attach overwrites the stored path verbatim.
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) "stoa-seat-registry.jsonl"
# Join with `\n` and a trailing newline; write UTF8-no-BOM so the JSONL stays clean.
$content = ($kept -join "`n") + "`n"
[System.IO.File]::WriteAllText($tmp, $content, (New-Object System.Text.UTF8Encoding($false)))

# `bw attach` FAILURE is non-fatal here (defense-in-depth: record-seat.ps1 is ALSO called
# standalone for the consumer desktop self-record path). On a workspace without the stoa--reg
# ticket the attach fails -> Write-Warning + exit non-zero, but WITHOUT an unhandled terminating
# throw (the launcher's try/catch OR a caller's exit-code check then handles it gracefully).
# The SUCCESS path is unchanged: write the row, Write-Host, implicit exit 0.
#
# Arc 68 (stoa--pk4) rev3 / C1 — RESOLVE bw even when it is on the git-bash PATH only,
# WITHOUT touching `Get-Command bash`. The rev2 bug: rev2's fallback used `Get-Command bash`,
# which on this (and many) Windows machines resolves WSL's distro-less, BROKEN
# C:\windows\system32\bash.exe — it SHADOWS git-bash on a fresh-terminal PATH. Invoking it
# failed (execvpe(/bin/bash): No such file -> exit 1) and fix(b) then MIS-bucketed that
# resolution failure as a benign bw/ticket error. rev3 derives git-bash FROM `git` (which is
# never shadowed by WSL), gates each candidate on `command -v bw`, uses a LOGIN shell (-lc) so
# the gate proves bw in the EXACT context the attach uses, and adds a distinct resolution-failure
# bucket so the WSL-broken case reports LOUDLY. $bwExit distinguishes the four outcomes:
#   0     -> success
#   <N>   -> bw resolved + ran, but the attach exited non-zero (real bw/store error)
#   $null -> bw could NOT be resolved (no pwsh-PATH bw AND no git-bash carrying bw) — a
#            PATH/RESOLUTION failure, NOT a missing ticket (the bucket that kills the mis-attribution)
#   threw -> an unexpected pwsh exception

# Arc 68 (stoa--pk4) rev3 / C1: resolve a git-bash that ACTUALLY carries bw, WITHOUT touching
# `Get-Command bash` (which on this and many Windows machines resolves WSL's distro-less,
# broken C:\windows\system32\bash.exe — it SHADOWS git-bash on the PATH). `git` is never
# shadowed by WSL, so we derive git-bash FROM git's own location, then SELECT the first
# candidate where `command -v bw` succeeds in the SAME login-shell invocation the attach uses.
function Resolve-GitBashWithBw {
  $cands = New-Object System.Collections.Generic.List[string]
  $git = Get-Command git -ErrorAction SilentlyContinue
  if ($git) {
    # Walk up from git.exe's dir (git may be at cmd\git.exe OR mingw64\bin\git.exe — do NOT
    # assume a fixed depth); at each level look for the wrapper bash, then the real bash.
    $dir = Split-Path -Parent $git.Source
    for ($i = 0; $i -lt 6 -and $dir; $i++) {
      foreach ($rel in @('bin\bash.exe','usr\bin\bash.exe')) {
        $c = Join-Path $dir $rel
        if ((Test-Path $c) -and -not $cands.Contains($c)) { $cands.Add($c) }
      }
      $dir = Split-Path -Parent $dir
    }
    # Belt-and-suspenders: derive from `git --exec-path` (handles non-standard git.exe placement).
    $ep = (& $git.Source --exec-path 2>$null)
    if ($ep) {
      $epDir = ($ep -replace '/','\').TrimEnd('\')
      for ($j = 0; $j -lt 6 -and $epDir; $j++) {
        foreach ($rel in @('bin\bash.exe','usr\bin\bash.exe')) {
          $c = Join-Path $epDir $rel
          if ((Test-Path $c) -and -not $cands.Contains($c)) { $cands.Add($c) }
        }
        $epDir = Split-Path -Parent $epDir
      }
    }
  }
  # Select the FIRST candidate where bw resolves IN THE LOGIN SHELL (-lc) the attach will use.
  foreach ($c in $cands) {
    & $c -lc 'command -v bw >/dev/null 2>&1' 2>$null
    if ($LASTEXITCODE -eq 0) { return $c }
  }
  # No git-bash carrying bw could be resolved -> distinct from a bw error (see fix(b) bucket).
  return $null
}

$bwExit = $null
$attachThrew = ''
$resolvedBash = $null
try {
  $bwCmd = Get-Command bw -ErrorAction SilentlyContinue
  if ($bwCmd) {
    # bw is directly on the pwsh PATH — invoke it directly.
    & $bwCmd.Source attach $ticket $tmp --name $attachName
    $bwExit = $LASTEXITCODE
  } else {
    # bw NOT on the pwsh PATH — resolve a git-bash that CARRIES bw (skips the WSL shadow).
    $resolvedBash = Resolve-GitBashWithBw
    if ($resolvedBash) {
      # Convert the Windows temp path to the form THIS git-bash understands. cygpath -u THROUGH
      # the resolved bash is robust (it emits git-bash's own mount form). Deterministic fallback:
      # backslashes -> slashes, leading "X:" -> "/x" (LOWERCASE drive = git-bash mount form,
      # NOT WSL's /mnt/c).
      $tmpBash = $null
      & $resolvedBash -lc 'command -v cygpath >/dev/null 2>&1' 2>$null
      if ($LASTEXITCODE -eq 0) {
        $tmpBash = (& $resolvedBash -lc 'cygpath -u "$1"' bash $tmp 2>$null).Trim()
      }
      if ([string]::IsNullOrWhiteSpace($tmpBash)) {
        $tmpBash = $tmp -replace '\\','/'
        $tmpBash = [regex]::Replace($tmpBash, '^([A-Za-z]):', { param($m) '/' + $m.Groups[1].Value.ToLower() })
      }
      # LOGIN shell (-lc): bw lives at /c/Users/<user>/bin/bw, added to PATH by the login profile;
      # a non-login -c may not have it on PATH even via the right bash (FM build detail). Positional
      # args (no interpolation of values into the script body) keep the apostrophe-in-username case safe.
      & $resolvedBash -lc 'bw attach "$1" "$2" --name "$3"' bash $ticket $tmpBash $attachName
      $bwExit = $LASTEXITCODE
    } else {
      # No git-bash carrying bw could be resolved (e.g. only a broken/WSL bash is present,
      # or git-bash has no bw). This is a RESOLUTION failure, NOT a bw/ticket error. Leave
      # $bwExit = $null and $resolvedBash = $null to route the distinct fix(b) bucket below.
      $bwExit = $null
    }
  }
} catch {
  $attachThrew = $_.Exception.Message
}

# Arc 68 (stoa--pk4) rev3 fix (b) — FOUR buckets so a wrong/broken-bash or no-bw-bash failure
# reports AS a resolution error (LOUD), and can NEVER again hide behind the benign
# "no registry ticket" / bw-error label.
$attachOk = $false; $failReason = ''
if ($attachThrew) {
  $failReason = "bw attach threw: $attachThrew"
} elseif ($bwExit -eq 0) {
  $attachOk = $true
} elseif ($null -eq $bwExit) {
  # BUCKET: resolution failure (no bw on pwsh PATH AND no git-bash carrying bw resolvable).
  $failReason = "bw could NOT be resolved: not on the pwsh PATH, and no git-bash carrying bw was found (a git-bash derived from 'git' where 'command -v bw' succeeds). This is a PATH/RESOLUTION failure, NOT a missing-ticket or bw-error case. On this machine bw is on the git-bash PATH only; note WSL's C:\windows\system32\bash.exe (if present) is NOT git-bash and is intentionally skipped (Arc 68 / stoa--pk4 rev3)."
} else {
  # BUCKET: bw RAN (via the resolved git-bash or the pwsh PATH) but the attach exited non-zero.
  $failReason = "bw attach to '$ticket' exited $bwExit (bw resolved and ran, but the attach failed: e.g. an invalid ticket id, or a real bw/store error). NOTE: a non-existent ticket may AUTO-CREATE on this bw version rather than error, so a non-zero exit here is a genuine bw/store error, not the benign no-ticket case."
}
if (-not $attachOk) {
  Write-Warning "record-seat: could not record seat '$Seat' to '$ticket'. $failReason"
  exit 1
}

Write-Host ("recorded seat '{0}' (name {1}, sid {2}, machine {3}) -> {4}" -f $Seat, $Name, $(if($SessionId){$SessionId}else{'<null>'}), $Machine, $readPath) -ForegroundColor Green
