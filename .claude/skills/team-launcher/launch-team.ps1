#requires -Version 7
<#
.SYNOPSIS
  Launch a Stoa agent team (POLYBIUS + PLINY — the STANDARD composition) in terminals —
  consumer-generic. Derives the project dir + slug from where it is deployed, so it works in
  ANY workspace with no editing. Defaults to SAY-TRIGGER activation: each pane is pre-seeded
  with the bare word ("polybius" / "pliny") so the workspace CLAUDE.md auto-loads the role.

  Arc 68 (stoa--pk4) launcher-correctness:
    - Chain-of-command preamble (L1) is injected on the ARC + PASTE paths only (which already
      force -Layout Windows). The SAY path stays a BARE word and inherits the chain via the
      role-file canon (operating-disciplines.md §37) — Option B, so the Panes default is
      PRESERVED for standard say launches.
    - -Composition selects a variable team: 'standard' (POLYBIUS+PLINY), 'custom-agent' (adds
      MAJOR_CHIRON), 'custom-workflow' (adds MAJOR_HAMILTON), 'custom-agent+workflow' (both).
      CHIRON/HAMILTON are launcher-spun design-time terminal seats that answer to POLYBIUS
      (parallel to PLINY); carrying full prompts, they force -Layout Windows (the prompt class
      only — not the say path).
    - The full gauntlet is the DEFAULT; -GauntletWaiver "<reason>" records gauntlet=waived:<reason>
      (a POLYBIUS/PRINCIPAL action; a seat cannot self-grant solo).
    - The launch records composition / gauntlet / chain_role per seat to the ONE registry stoa--reg.

  Layouts:
    Panes   (DEFAULT) - side-by-side split panes in ONE Windows Terminal window
    Tabs              - one tab per seat in ONE Windows Terminal window
    Windows           - one separate OS window per seat (no wt needed; fallback target)

  Each session runs:  claude --dangerously-skip-permissions --model <model> --name <seat>
                      --session-id <uuid> [--remote-control] [<say-word>]

.DESCRIPTION
  stoa--h8w: this is the consumer-generic successor to the the-stoa-specific root launcher.
  It ships INSIDE the team-launcher skill subtree so install.sh deploys it to every workspace.

  Project + slug resolution (when -ProjectDir is not passed): walk up from this script's
  location to the first ancestor containing a `.claude/` dir (the workspace root). Slug
  defaults to that dir's leaf name (e.g. `origindex` -> seats POLYBIUS_origindex / PLINY_origindex).

  Session-identity (stoa--p7c, Arc 67 — the HYBRID DC1 launcher half):
    Each terminal seat is minted a per-seat UUID (`SessionId = [guid]::NewGuid()`), launched with
    `claude --session-id <uuid>`, and recorded to the durable bw seat registry (`stoa--reg`) via
    `record-seat.ps1` after launch. The launcher KNOWS the id deterministically before the seat
    activates (it minted it), so the registry row exists at launch with no activation-ordering
    window. Desktop-UI sessions, which this launcher cannot reach (they are created outside it),
    SELF-RECORD on activation by reading `$CLAUDE_CODE_SESSION_ID` (the whoami skill + this same
    `record-seat.ps1`) — the env-var-powered fallback that covers the case the launcher pin cannot.

  Activation:
    say   (DEFAULT) - pre-seed the bare word ("polybius"/"pliny") as claude's positional prompt;
                      the workspace CLAUDE.md say-trigger loads the role. Works in all layouts.
    paste           - open sessions ready for a manual activation paste (the-stoa-style). With
                      -AutoPaste + -Layout Windows, feeds each seat's Paste file as the first prompt.

  wt mechanics verified against Microsoft's Windows Terminal docs + smoke test (2026-06-04):
    split-pane -V => side-by-side; ';' delimits wt commands; Start-Process => non-blocking.

.EXAMPLE
  ./launch-team.ps1                  # panes, say-trigger, project+slug auto-derived
.EXAMPLE
  ./launch-team.ps1 -Layout Tabs
.EXAMPLE
  ./launch-team.ps1 -DryRun          # print the wt/pwsh command + the record-seat step (executes neither)
.EXAMPLE
  ./launch-team.ps1 -ProjectDir C:\path\to\proj -Slug proj
.EXAMPLE
  ./launch-team.ps1 -Activation paste -Layout Windows -AutoPaste
.EXAMPLE
  ./launch-team.ps1 -RemoteControl   # add --remote-control to each launched session
.EXAMPLE
  ./launch-team.ps1 -ArcId stoa--xyz -Composition custom-agent  # POLYBIUS+PLINY+CHIRON, gauntlet arc
.EXAMPLE
  ./launch-team.ps1 -GauntletWaiver "pair-programming spike per PRINCIPAL"  # records gauntlet=waived:<reason>

.NOTES
  Model: 'opus' is an alias; if rejected, pass -Model 'claude-opus-4-8'.
  Paths/names with SPACES are not quoted by this script — keep them space-free.
  Arc 68 (stoa--pk4): the chain-of-command preamble rides ARC + PASTE launches only (Option B);
  a standard SAY launch stays a bare word + the Panes default (the chain comes from the role
  file's §37 canon). -Composition adds CHIRON (custom-agent) / HAMILTON (custom-workflow) as
  design-time terminal seats answering to POLYBIUS; -GauntletWaiver opts out of the gauntlet
  default (a POLYBIUS/PRINCIPAL action, recorded to the registry). See operating-disciplines.md §37.
  If a pane's say-trigger pre-seed ever misfires, the pane is still named + in the project dir
  at a ready claude prompt — just type the bare word yourself.
  Seat-identity scheme: each terminal seat is minted a `--session-id` UUID + a space-free name
  and recorded to the bw seat registry `stoa--reg`. The signing/identity convention is
  `operating-disciplines.md` §28.9 (terminal seats sign `[from: <Name> | sid $CLAUDE_CODE_SESSION_ID | <project>]`;
  the sid is read at runtime from `$CLAUDE_CODE_SESSION_ID`). See the team-launcher SKILL.md for
  the registry read recipe + the desktop self-record fallback.
#>
param(
  [string]   $ProjectDir,
  [string]   $Slug,
  [string]   $Model      = 'opus',
  [ValidateSet('Panes','Tabs','Windows')]
  [string]   $Layout     = 'Panes',
  [ValidateSet('say','paste')]
  [string]   $Activation = 'say',
  [object[]] $Seats,
  [switch]   $AutoPaste,
  [switch]   $DryRun,
  [int]      $StaggerSeconds = 4,
  [string]   $ArcId,
  [string]   $OnlySeat,
  [switch]   $RemoteControl,
  # --- Arc 68 (stoa--pk4) DC3: variable team composition ---
  # 'standard' = POLYBIUS + PLINY; 'custom-agent' adds MAJOR_CHIRON (the arc designs
  # custom agents); 'custom-workflow' adds MAJOR_HAMILTON (the arc designs custom
  # workflows); 'custom-agent+workflow' adds both. CHIRON/HAMILTON are launcher-spun
  # design-time terminal seats that answer to POLYBIUS (parallel to PLINY).
  [ValidateSet('standard','custom-agent','custom-workflow','custom-agent+workflow')]
  [string]   $Composition = 'standard',
  # --- Arc 68 (stoa--pk4) DC2: gauntlet-by-default opt-out (POLYBIUS/PRINCIPAL action) ---
  # Absent -> gauntlet=required (the default). Passed with a <reason> -> the launch is
  # recorded gauntlet=waived:<reason> AND the chain preamble's gauntlet line is replaced
  # with a WAIVED notice. A seat cannot self-grant this; only this launch flag writes it.
  [string]   $GauntletWaiver
)

# --- Resolve the project dir: param, else walk up from the script to the workspace root ---
if (-not $ProjectDir) {
  $d = $PSScriptRoot
  while ($d -and -not (Test-Path -LiteralPath (Join-Path $d '.claude'))) {
    $parent = Split-Path $d -Parent
    if ($parent -eq $d) { $d = $null; break }
    $d = $parent
  }
  $ProjectDir = if ($d) { $d } else { (Get-Location).Path }
}
if (-not (Test-Path -LiteralPath $ProjectDir)) { throw "ProjectDir not found: $ProjectDir" }
$ProjectDir = (Resolve-Path -LiteralPath $ProjectDir).Path

# --- Slug (seat suffix / titles): param, else the project dir leaf ---
if (-not $Slug) { $Slug = Split-Path $ProjectDir -Leaf }

# --- claude on PATH ---
$claude = Get-Command claude -ErrorAction SilentlyContinue
if (-not $claude) { throw "claude not found on PATH." }
$claudeExe = $claude.Source

# --- Machine (hostname) for the registry row ---
$machine = [System.Net.Dns]::GetHostName()

# --- record-seat.ps1 (the registry write helper) lives beside this launcher ---
$recordSeat = Join-Path $PSScriptRoot 'record-seat.ps1'

# --- Arc 68 (stoa--pk4) DC2: gauntlet posture for the launch (recorded + preamble) ---
# Default 'required'; -GauntletWaiver "<reason>" makes it 'waived:<reason>'. This is the
# structural-at-launch opt-out gate: only the launch flag (a POLYBIUS/PRINCIPAL action)
# writes a waiver; a seat cannot self-grant solo. Recorded to stoa--reg per seat (DC4).
$gauntletPosture = if ($GauntletWaiver) { "waived:$GauntletWaiver" } else { 'required' }

# --- Arc 68 (stoa--pk4) DC1: the chain-of-command preamble (L1 layer) ---
# Get-ChainPreamble builds the fixed chain-of-command block injected into the ARC + PASTE
# seat activation prompts (the paths that already force -Layout Windows; the multi-line
# block passes robustly there). Under Option B (BLESSED) the SAY path stays a bare word
# and inherits the chain via the role-file canon (operating-disciplines.md §37 + the
# substantive MAJOR_POLYBIUS.md / MAJOR_PLINY.md chain paragraphs) — NOT via this preamble.
# The gauntlet line reflects $gauntletPosture: required -> the gauntlet-default line; a
# waiver -> a WAIVED-by-launch-flag notice (the waiver authority is the launch flag).
function Get-ChainPreamble {
  param([string]$Role, [string]$Slug)
  $roleLine = switch ($Role) {
    'floor-manager'      { "POLYBIUS_${Slug}: you SUPERVISE PLINY (direct + independently verify hand-backs via bw). The PRINCIPAL/user-tier addresses YOU; you never dispatch CAPTAINs yourself." }
    'orchestrator'       { "PLINY_${Slug}: you take direction from + surface to POLYBIUS via bw, NOT the PRINCIPAL. You spin up the CAPTAINs and run the gauntlet." }
    'team-architect'     { "MAJOR_CHIRON: design-time team-architect. You answer to POLYBIUS; you co-design the cast with HAMILTON, then step back so PLINY runs the team. You do NOT dispatch CAPTAINs." }
    'workflow-architect' { "MAJOR_HAMILTON: design-time workflow-architect. You answer to POLYBIUS; you co-design the choreography with CHIRON, then step back so PLINY runs the team." }
    default              { "a Stoa team seat - take your place in the chain above and coordinate via bw." }
  }
  $gauntletLine = if ($GauntletWaiver) {
    "GAUNTLET WAIVED by launch flag: $GauntletWaiver (POLYBIUS/PRINCIPAL-authorized)."
  } else {
    "The full gauntlet (DAEDALUS->ARGUS->ADA->VERA->CATO->NOMOS) is the DEFAULT; running solo`n  with one checker requires an explicit POLYBIUS/PRINCIPAL waiver recorded on bw."
  }
  return @"
CHAIN OF COMMAND (Stoa, established at launch - do not deviate):
  PRINCIPAL -> POLYBIUS (chief/floor-manager) -> PLINY (orchestrator) -> CAPTAINs.
You are $roleLine
You coordinate via bw (positional 'bw comment'), NOT by the PRINCIPAL relaying messages.
$gauntletLine
"@
}

# --- Gauntlet arc launch: build the two seats with full beadwork-read activation prompts ---
# (-ArcId set + no explicit -Seats). The brief is a bw attachment on the `beadwork` branch; the
# seat reads it with `git show beadwork:attachments/<ArcId>/<paste>` then assumes its role.
# Floor-manager paste carries the slug; the PLINY paste does not (gauntlet-setup naming).
if (-not $Seats -and $ArcId) {
  # Resolve each brief filename robustly (stoa--eh4): the historical attachment naming is
  # inconsistent (arc-NN / short-id / full-id), so PREFER the canonical name but FALL BACK to a
  # glob of the beadwork attachment dir, and FAIL LOUD on zero/ambiguous. Prevents the silent
  # "-ArcId path can't find the brief" failure when a brief was attached under a non-canonical name.
  function Resolve-Brief([string]$pattern, [string]$canonical) {
    $names = @(git -C $ProjectDir ls-tree -r --name-only beadwork "attachments/$ArcId/" 2>$null |
      ForEach-Object { Split-Path $_ -Leaf } | Where-Object { $_ -like $pattern })
    if ($names -contains $canonical) { return $canonical }                 # canonical present -> use it
    if ($names.Count -eq 1) {
      Write-Warning "[-ArcId] brief '$canonical' not found; resolved by glob to the single match '$($names[0])'."
      return $names[0]
    }
    if ($names.Count -eq 0) {
      throw "[-ArcId] no brief matching '$pattern' under beadwork:attachments/$ArcId (expected '$canonical'); attach the brief first."
    }
    throw "[-ArcId] ambiguous brief: $($names.Count) match '$pattern' under beadwork:attachments/$ArcId ($($names -join ', ')) and none is the canonical '$canonical'; rename to the canonical form or remove the extras."
  }
  $fmFile = Resolve-Brief 'HUMAN_paste-polybius_*instruction.md' "HUMAN_paste-polybius_${Slug}-${ArcId}-instruction.md"
  $plFile = Resolve-Brief 'HUMAN_paste-pliny-*instruction.md'    "HUMAN_paste-pliny-${ArcId}-instruction.md"
  $Seats = @(
    @{ Name = "POLYBIUS_$Slug"; Role = 'floor-manager'; Prompt = "Read .claude/MAJOR_POLYBIUS.md. Then read your engagement brief from the beadwork branch by running: git show beadwork:attachments/$ArcId/$fmFile then assume the project-tier floor-manager role for $Slug on arc $ArcId and follow it." },
    @{ Name = "PLINY_$Slug";    Role = 'orchestrator'; Prompt = "Read .claude/MAJOR_PLINY.md. Then read your engagement brief from the beadwork branch by running: git show beadwork:attachments/$ArcId/$plFile then assume the orchestrator role for $Slug on arc $ArcId and follow it." }
  )
  # Full multi-word prompts pass robustly ONLY through the Windows (per-seat pwsh window) path;
  # wt panes/tabs re-split a positional prompt on spaces (the original hand-rolled-launch break).
  # Force Windows for arc launches so the brief reference reaches claude intact.
  if ($Layout -ne 'Windows') { Write-Warning "[-ArcId] full activation prompts require robust passing; forcing -Layout Windows."; $Layout = 'Windows' }
}

# --- Default seats from slug + activation (floor-manager FIRST) ---
if (-not $Seats) {
  if ($Activation -eq 'say') {
    $Seats = @(
      @{ Name = "POLYBIUS_$Slug"; Role = 'floor-manager'; Say = 'polybius' },
      @{ Name = "PLINY_$Slug";    Role = 'orchestrator';  Say = 'pliny' }
    )
  } else {
    $Seats = @(
      @{ Name = "POLYBIUS_$Slug"; Role = 'floor-manager' },
      @{ Name = "PLINY_$Slug";    Role = 'orchestrator' }
    )
  }
}

# --- Arc 68 (stoa--pk4) DC3: variable composition — add design-time architect seats ---
# CHIRON (custom agents) / HAMILTON (custom workflows) are launcher-spun TERMINAL design-time
# seats answering to POLYBIUS (parallel to PLINY). They have NO CLAUDE.md say-trigger, so the
# launcher MUST seed a full activation prompt naming the role file (carried as $seat.Prompt =
# the arc-class path, which gets the chain preamble via Get-SeatPrompt). Added BEFORE the
# -OnlySeat filter so the existing floor-manager-first single-seat launch still works.
$compositionSeats = @()
if ($Composition -in @('custom-agent','custom-agent+workflow')) {
  $chironTail = if ($ArcId) { " on arc $ArcId; read your brief: git show beadwork:attachments/$ArcId/HUMAN_paste-chiron-$ArcId-instruction.md and follow it." } else { "." }
  $compositionSeats += @{ Name = "CHIRON_$Slug"; Role = 'team-architect';
    Prompt = "Read .claude/MAJOR_CHIRON.md and assume the team-architect role for $Slug$chironTail" }
}
if ($Composition -in @('custom-workflow','custom-agent+workflow')) {
  $hamiltonTail = if ($ArcId) { " on arc $ArcId; read your brief: git show beadwork:attachments/$ArcId/HUMAN_paste-hamilton-$ArcId-instruction.md and follow it." } else { "." }
  $compositionSeats += @{ Name = "HAMILTON_$Slug"; Role = 'workflow-architect';
    Prompt = "Read .claude/MAJOR_HAMILTON.md and assume the workflow-architect role for $Slug$hamiltonTail" }
}
if ($compositionSeats.Count -gt 0) {
  $Seats = @($Seats) + $compositionSeats
  # The architect seats carry full multi-word prompts, so they REQUIRE the robust Windows
  # (per-seat pwsh window) path exactly like the -ArcId arc path. Forcing Windows here is a
  # property of the multi-word-prompt class ONLY — it does NOT touch the bare-word say path
  # (Option B): a standard say launch with no composition stays Panes.
  if ($Layout -ne 'Windows') { Write-Warning "[-Composition $Composition] architect seats carry full activation prompts; forcing -Layout Windows."; $Layout = 'Windows' }
}

# --- Optional single-seat launch (so the caller can do floor-manager FIRST, verify on bw, then PLINY) ---
if ($OnlySeat) {
  $Seats = @($Seats | Where-Object { [string]$_.Name -eq $OnlySeat })
  if (-not $Seats) { throw "OnlySeat '$OnlySeat' matched no seat name." }
}

# --- Session-identity: mint a per-seat UUID for each seat (the launcher pins it via --session-id) ---
# Each seat gets its own GUID; the launcher knows it deterministically before the seat activates,
# so the registry row (recorded after launch) exists with no activation-ordering window.
foreach ($seat in $Seats) {
  if (-not $seat.ContainsKey('SessionId') -or -not $seat.SessionId) {
    $seat.SessionId = [guid]::NewGuid().ToString()
  }
  if (-not $seat.ContainsKey('Role')) { $seat.Role = $null }
}

# --- wt availability + fallback ---
$haveWt = [bool](Get-Command wt -ErrorAction SilentlyContinue)
if ($Layout -in @('Panes','Tabs') -and -not $haveWt) {
  Write-Warning "Windows Terminal (wt) not found - falling back to -Layout Windows."
  $Layout = 'Windows'
}
if ($AutoPaste -and $Layout -ne 'Windows') {
  Write-Warning "-AutoPaste is supported only in -Layout Windows; $Layout opens for manual paste."
}

function Get-SeatPrompt($seat) {
  # Arc 68 (stoa--pk4) DC1/Option B: PREPEND the chain-of-command preamble on the ARC path
  # ($seat.Prompt — the full multi-word activation prompt, which already forces -Layout Windows).
  # The SAY path returns the BARE word UNCHANGED (no preamble, no Windows force) — the chain is
  # established for the say path via the role-file canon (operating-disciplines.md §37 + the
  # substantive MAJOR_POLYBIUS.md / MAJOR_PLINY.md paragraphs), per the BLESSED Option B.
  if ($seat.Prompt) {
    return (Get-ChainPreamble -Role ([string]$seat.Role) -Slug $Slug) + "`n" + [string]$seat.Prompt
  }
  if ($Activation -eq 'say' -and $seat.Say) { return [string]$seat.Say }   # bare word — Option B
  return $null
}

if ($Layout -in @('Panes','Tabs')) {
  # One wt invocation: new-tab for seat 1, then split-pane (Panes) / new-tab (Tabs) for the rest.
  $wtArgs = @()
  $idx = 0
  foreach ($seat in $Seats) {
    $idx++
    $name = [string]$seat.Name
    if ($idx -eq 1) { $wtArgs += 'new-tab' }
    elseif ($Layout -eq 'Panes') { $wtArgs += @(';', 'split-pane', '-V') }
    else { $wtArgs += @(';', 'new-tab') }
    $wtArgs += @('--title', $name, '--startingDirectory', $ProjectDir,
                 $claudeExe, '--dangerously-skip-permissions', '--model', $Model, '--name', $name,
                 '--session-id', [string]$seat.SessionId)
    if ($RemoteControl) { $wtArgs += '--remote-control' }
    $p = Get-SeatPrompt $seat
    if ($p) { $wtArgs += $p }   # positional bare-word prompt = say-trigger activation
    Write-Host ("[{0}] {1}  ({2}{3}) sid={4}" -f $idx, $name, $Layout, $(if($seat.Prompt){' (activation prompt seeded)'}elseif($p){", say:'$p'"}else{''}), $seat.SessionId) -ForegroundColor Green
  }
  if ($DryRun) {
    Write-Host ("[dry-run] wt {0}" -f ($wtArgs -join ' ')) -ForegroundColor Yellow
  } else {
    Start-Process wt -ArgumentList $wtArgs | Out-Null   # non-blocking
  }
}
else {
  # Windows: one pwsh window per seat (supports -AutoPaste in paste mode).
  $i = 0
  foreach ($seat in $Seats) {
    $i++
    $name = [string]$seat.Name
    $cmd  = "& '$claudeExe' --dangerously-skip-permissions --model $Model --name '$name' --session-id $($seat.SessionId)"
    if ($RemoteControl) { $cmd += " --remote-control" }
    $p = Get-SeatPrompt $seat
    if ($p) {
      $cmd += " '" + ($p -replace "'", "''") + "'"   # Arc-70 fix: escape single quotes (the chain preamble carries 'bw comment') so the positional prompt is not truncated — mirrors the paste-path escaping below
    } elseif ($AutoPaste -and $seat.Paste) {
      $paste = Join-Path $ProjectDir $seat.Paste
      if (Test-Path -LiteralPath $paste) {
        # Arc 68 (stoa--pk4) DC1/Option B: PREPEND the chain preamble to the paste brief content.
        # The paste path is Windows-only by construction (-AutoPaste warns + falls back outside
        # -Layout Windows), so the multi-line preamble passes robustly through the per-seat pwsh
        # window's single-quote-wrapped string. The preamble is wrapped in a single-quoted literal
        # (apostrophes doubled) and concatenated ahead of the brief content the seat reads.
        $pastemble = (Get-ChainPreamble -Role ([string]$seat.Role) -Slug $Slug) + "`n"
        $pastembleLit = "'" + ($pastemble -replace "'", "''") + "'"
        $cmd += " ($pastembleLit + (Get-Content -LiteralPath '$paste' -Raw))"
      }
      else { Write-Warning "Seat '$name': paste file missing ($paste) - opening for manual paste." }
    }
    $inner = "Set-Location -LiteralPath '$ProjectDir'; $cmd"
    if ($DryRun) {
      Write-Host ("[dry-run] pwsh -NoExit -Command: {0}" -f $inner) -ForegroundColor Yellow
    } else {
      Start-Process pwsh -WorkingDirectory $ProjectDir -ArgumentList '-NoExit','-Command',$inner | Out-Null
      if ($i -lt $Seats.Count -and $StaggerSeconds -gt 0) { Start-Sleep -Seconds $StaggerSeconds }
    }
    Write-Host ("[{0}] {1}  (Windows{2}) sid={3}" -f $i, $name, $(if($seat.Prompt){' (activation prompt seeded)'}elseif($p){", say:'$p'"}else{''}), $seat.SessionId) -ForegroundColor Green
  }
}

# --- Record each launched terminal seat to the durable bw seat registry (stoa--reg) ---
# Serial, one record-seat.ps1 call per seat (the launcher knows every minted id, so no race).
# -DryRun PRINTS the intended invocation but EXECUTES NEITHER the launch nor the record step.
$launchedAt = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
foreach ($seat in $Seats) {
  $name = [string]$seat.Name
  $role = if ($seat.Role) { [string]$seat.Role } else { '' }
  # Arc 68 (stoa--pk4) DC3/DC4: pass the composition, the gauntlet posture, and the chain_role
  # (= the seat's role, its place in the chain) through to the registry row.
  if ($DryRun) {
    Write-Host ("[dry-run] record-seat: -Seat {0} -Name {1} -SessionId {2} -Project {3} -Machine {4} -Role {5} -Tier project -Composition {6} -Gauntlet {7} -ChainRole {5} (status:alive, launched_at {8})" -f $name, $name, $seat.SessionId, $Slug, $machine, $role, $Composition, $gauntletPosture, $launchedAt) -ForegroundColor Yellow
  } else {
    if (Test-Path -LiteralPath $recordSeat) {
      # Recording is BEST-EFFORT; the launch (above) is the PRIMARY job. record-seat.ps1 now
      # fails LOUD with the SPECIFIC cause (PATH-miss vs missing-ticket vs bw error); we echo
      # its exit + let its own message stand, rather than asserting "benign" unconditionally
      # (the Arc-68 fail-open fix: a total registry-write failure must not hide behind "benign").
      try {
        & $recordSeat -Seat $name -Name $name -SessionId ([string]$seat.SessionId) -Project $Slug -Machine $machine -Role $role -Tier 'project' -Composition $Composition -Gauntlet $gauntletPosture -ChainRole $role
        if ($LASTEXITCODE -ne 0) {
          Write-Warning "record-seat.ps1 returned non-zero for seat '$name' (see its message above for the specific cause: PATH-miss vs missing-ticket vs bw error); seat LAUNCHED but NOT recorded."
        }
      } catch {
        Write-Warning "record-seat.ps1 failed for seat '$name' ($($_.Exception.Message)); seat LAUNCHED but NOT recorded (see record-seat's message above for the specific cause)."
      }
    } else {
      Write-Warning "record-seat.ps1 not found beside the launcher ($recordSeat); seat '$name' was launched but NOT recorded to stoa--reg."
    }
  }
}

Write-Host ''
Write-Host ("Team launched ({0} layout, project '{1}')." -f $Layout, $Slug) -ForegroundColor Cyan
$anyPrompt = @($Seats | Where-Object { $_.Prompt }).Count -gt 0
if ($anyPrompt) {
  Write-Host 'Arc launch: each session was pre-seeded its FULL activation prompt (it reads its brief from the beadwork branch, then assumes its role). Floor-manager first. If a session did not auto-run the prompt, paste the printed activation line yourself.' -ForegroundColor Cyan
} elseif ($Activation -eq 'say') {
  Write-Host 'Say-trigger: each pane was pre-seeded its bare word; the workspace CLAUDE.md auto-loads the role (floor-manager = left pane / first tab). If one did not fire, type the word yourself.' -ForegroundColor Cyan
} else {
  Write-Host 'Paste each activation file into its session - floor-manager first (left pane / first tab).' -ForegroundColor Cyan
}
