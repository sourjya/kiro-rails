# Kiro Rails - PowerShell Installer
# Usage: irm https://raw.githubusercontent.com/sourjya/kiro-rails/main/install.ps1 -OutFile install.ps1; .\install.ps1

$ErrorActionPreference = "Stop"

$Repo = "sourjya/kiro-rails"
$Branch = "main"
# Overridable via $env:KIRO_RAILS_BASE_URL (e.g. a file:/// or local URL for pre-push
# testing); defaults to this repo's raw GitHub content.
$BaseUrl = if ($env:KIRO_RAILS_BASE_URL) { $env:KIRO_RAILS_BASE_URL } else { "https://raw.githubusercontent.com/$Repo/$Branch" }
$CurrentVersion = "0.14.0"
$VersionFile = ".kiro/.kiro-rails-version"
$OverridesFile = ".kiro/steering/user-project-overrides.md"

$ManagedFiles = @(
    ".kiro/steering/code-organization.md"
    ".kiro/steering/testing-standards.md"
    ".kiro/steering/reusable-architecture.md"
    ".kiro/steering/error-handling-performance.md"
    ".kiro/steering/change-discipline.md"
    ".kiro/steering/documentation-standards.md"
    ".kiro/steering/git-and-focus-discipline.md"
    ".kiro/steering/agent-boundaries.md"
    ".kiro/steering/code-commenting-standards.md"
    ".kiro/steering/project-conventions.md"
    ".kiro/steering/database-conventions.md"
    ".kiro/steering/import-path-rules.md"
    ".kiro/steering/naming-conventions.md"
    ".kiro/steering/versioning.md"
    ".kiro/steering/review-policy.md"
    ".kiro/steering/chokepoint-logging.md"
    ".kiro/steering/session-isolation.md"
    ".kiro/steering/frontend-patterns.md"
    ".kiro/steering/api-contract-discipline.md"
    ".kiro/steering/ux-pattern-registry.md"
    ".kiro/hooks/comment-standards-check.kiro.hook"
    ".kiro/hooks/changelog-maintenance.kiro.hook"
    ".kiro/hooks/lint-python-files.kiro.hook"
    ".kiro/hooks/security-tier1-precommit.kiro.hook"
    ".kiro/hooks/security-tier2-feature.kiro.hook"
    ".kiro/hooks/security-tier3-sprint.kiro.hook"
    ".kiro/hooks/fix-spiral-detector.kiro.hook"
    ".kiro/hooks/type-check-on-stop.kiro.hook"
    ".kiro/hooks/commit-checkpoint-on-stop.kiro.hook"
    ".kiro/hooks/package-manifest-verify.kiro.hook"
    ".kiro/hooks/changelog-consolidation-reminder.kiro.hook"
    ".kiro/hooks/bug-doc-completion-check.kiro.hook"
    ".kiro/hooks/adr-trigger-infra-changes.kiro.hook"
    ".kiro/hooks/ux-preflight-gate.kiro.hook"
    ".kiro/hooks/spec-validation-gate.kiro.hook"
    ".kiro/hooks/focus-guard.kiro.hook"
    ".kiro/hooks/branch-hygiene-check.kiro.hook"
    ".kiro/hooks/variant-search-on-fix-branch.kiro.hook"
    ".kiro/hooks/session-guard-check.kiro.hook"
    ".kiro/hooks/claude-export-freshness.kiro.hook"
    ".kiro/skills/auth-implementation/SKILL.md"
    ".kiro/skills/spec-propose/SKILL.md"
    ".kiro/skills/spec-implement/SKILL.md"
    ".kiro/skills/spec-verify/SKILL.md"
    ".kiro/skills/spec-archive/SKILL.md"
    ".kiro/agents/code-security-reviewer.json"
    ".kiro/agents/ux-red-team.json"
    ".kiro/agents/security-verifier.json"
    ".kiro/prompts/review-code-security.md"
    ".kiro/prompts/review-code-maintainability.md"
    ".kiro/prompts/review-test-quality.md"
    ".kiro/prompts/review-css-architecture.md"
    ".kiro/prompts/review-api-contracts.md"
    ".kiro/prompts/review-dependency-risk.md"
    ".kiro/prompts/review-observability.md"
    ".kiro/prompts/review-iac-consistency.md"
    ".kiro/prompts/review-cicd-pipeline.md"
    ".kiro/prompts/review-frontend-performance.md"
    ".kiro/prompts/review-ux-audit.md"
    ".kiro/prompts/review-ux-preflight.md"
    ".kiro/prompts/review-spec-readiness.md"
    ".kiro/prompts/review-ai-agent-surface.md"
    ".kiro/prompts/review-commit-pr-discipline.md"
    ".kiro/templates/tasks-template-tdd.md"
    "scripts/git-commit-push.sh"
    "scripts/export-to-tools.sh"
    "scripts/branch-check.sh"
    "scripts/session-guard.sh"
    "scripts/export-to-claude.sh"
    "scripts/claude-guard-bash.sh"
    "scripts/check-claude-fresh.sh"
)

$StaleFiles = @(
    ".kiro/steering/engineering-standards.md"
    ".kiro/steering/execution-discipline.md"
    ".kiro/prompts/code-review.md"
    ".kiro/prompts/security-review.md"
    ".kiro/prompts/review-maintainability.md"
    ".kiro/prompts/review-security.md"
    ".kiro/prompts/review-security-periodic.md"
    ".kiro/hooks/security-checkpoint.kiro.hook"
    ".kiro/steering/git-workflow.md"
    ".kiro/steering/focus-and-branch-discipline.md"
)

$Dirs = @(
    ".kiro/steering"; ".kiro/hooks"; ".kiro/agents"; ".kiro/prompts"
    ".kiro/specs"; ".kiro/templates"; ".kiro/settings"
    ".kiro/skills/auth-implementation"
    ".kiro/skills/spec-propose"; ".kiro/skills/spec-implement"
    ".kiro/skills/spec-verify"; ".kiro/skills/spec-archive"
    "docs/decisions"; "docs/architecture"; "docs/roadmap"; "docs/changelogs"
    "docs/bugs"; "docs/ideas"; "docs/technical-debt"; "docs/testing"
    "docs/runbooks"; "docs/references"; "docs/engineering"; "docs/security"
    "docs/backlog"
    "scripts"; "logs"
)

# Safety check
$cwd = (Get-Location).Path
if ($cwd -eq $HOME -or $cwd -eq "C:\") {
    Write-Host "Error: don't run this in your home or root directory. cd into your project first." -ForegroundColor Red
    exit 1
}

# Detect install type
$installType = "fresh"
$installedVersion = ""

if (Test-Path $VersionFile) {
    $installedVersion = (Get-Content $VersionFile -Raw).Trim()
    if ($installedVersion -eq $CurrentVersion) {
        Write-Host "Kiro Rails v$CurrentVersion is already installed. Nothing to do."
        exit 0
    }
    $installType = "upgrade"
    Write-Host "Upgrading Kiro Rails: v$installedVersion -> v$CurrentVersion"
} elseif (Test-Path ".kiro/steering/*.md") {
    $installType = "upgrade"
    Write-Host "Detected existing Kiro Rails files (no version file). Upgrading to v$CurrentVersion"
} else {
    Write-Host "Installing Kiro Rails v$CurrentVersion into $cwd..."
}

# Create directories
foreach ($dir in $Dirs) {
    if (-not (Test-Path $dir)) { [void](New-Item -ItemType Directory -Path $dir -Force) }
}

# Download helper - tries curl.exe first, falls back to Invoke-WebRequest
$useCurl = $true
try { $null = & curl.exe --version 2>&1 } catch { $useCurl = $false }
if ($LASTEXITCODE -ne 0) { $useCurl = $false }

function Get-RemoteFile($relativePath) {
    $url = "$BaseUrl/$relativePath"
    $localPath = $relativePath
    $parentDir = Split-Path $localPath -Parent
    if ($parentDir -and -not (Test-Path $parentDir)) { [void](New-Item -ItemType Directory -Path $parentDir -Force) }
    # Retry transient download failures (flaky networks; IWR keep-alive resets, etc.).
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            if ($script:useCurl) {
                $null = & curl.exe -fsSL $url -o $localPath 2>&1
                if ($LASTEXITCODE -eq 0) { return $true }
            } else {
                Invoke-WebRequest -Uri $url -OutFile $localPath -UseBasicParsing -ErrorAction Stop
                return $true
            }
        } catch { }
        Start-Sleep -Milliseconds 200
    }
    return $false
}

# Download managed files
$downloaded = 0; $updated = 0; $failed = 0
$total = $ManagedFiles.Count; $current = 0

foreach ($file in $ManagedFiles) {
    $current++
    $name = Split-Path $file -Leaf
    Write-Host "`r  Downloading [$current/$total] $name                    " -NoNewline
    $localPath = $file
    if ((Test-Path $localPath) -and $installType -eq "upgrade") {
        if (Get-RemoteFile $file) { $updated++ } else { $failed++; Write-Host ""; Write-Host "  Warning: could not download $file" -ForegroundColor Yellow }
    } else {
        if (Get-RemoteFile $file) { $downloaded++ } else { $failed++; Write-Host ""; Write-Host "  Warning: could not download $file" -ForegroundColor Yellow }
    }
}
Write-Host ""

# Doc templates - download only if missing (never overwrite user content)
$DocTemplates = @(
    "docs/decisions/ADR-000-template.md"
    "docs/bugs/BUG-000-template.md"
    "docs/roadmap/roadmap.md"
    "docs/backlog/INBOX.md"
    ".kiro/settings/mcp.json"
)
foreach ($file in $DocTemplates) {
    $localPath = $file
    if (-not (Test-Path $localPath)) {
        if (Get-RemoteFile $file) { $downloaded++ }
    }
}

# Remove stale files
$removed = 0
if ($installType -eq "upgrade") {
    foreach ($file in $StaleFiles) {
        $localPath = $file
        if (Test-Path $localPath) {
            Remove-Item $localPath -Force
            $removed++
            Write-Host "  Removed stale: $file"
        }
    }
}

# User project overrides
$overridesLocal = $OverridesFile
if (Test-Path $overridesLocal) {
    Write-Host ""
    Write-Host "  user-project-overrides.md exists - not modified."
} else {
    Get-RemoteFile ($OverridesFile.Replace("\", "/")) | Out-Null
    $downloaded++

    # Interactive prompts
    Write-Host ""
    $configure = Read-Host "Configure project settings now? You can skip and edit .kiro/steering/user-project-overrides.md later. [Y/n]"
    if ($configure -eq "" -or $configure -match "^[Yy]") {
        Write-Host ""
        Write-Host "Press Enter to skip any section."
        Write-Host ""
        $content = Get-Content $overridesLocal -Raw

        # Tech Stack
        Write-Host "-- Tech Stack --"
        $backend = Read-Host "  Backend? (e.g., Python 3.12+ with FastAPI)"
        $frontend = Read-Host "  Frontend? (e.g., TypeScript with React + Vite)"
        if ($backend -or $frontend) {
            $block = "## Tech Stack`n"
            if ($backend) { $block += "- **Backend**: $backend`n" }
            if ($frontend) { $block += "- **Frontend**: $frontend`n" }
            $content = $content -replace "## Tech Stack", $block
            $content = $content -replace "(?s)<!-- Uncomment and set your stack:.*?-->", ""
        }

        # Ports
        Write-Host ""
        Write-Host "-- Dev Server Ports --"
        $bPort = Read-Host "  Backend port? (default: 8000)"
        $fPort = Read-Host "  Frontend port? (default: 5173)"
        if ($bPort -or $fPort) {
            if (-not $bPort) { $bPort = "8000" }
            if (-not $fPort) { $fPort = "5173" }
            $block = "## Dev Server Ports`n- Backend: port $bPort`n- Frontend: port $fPort`n"
            $content = $content -replace "## Dev Server Ports", $block
            $content = $content -replace "(?s)<!-- Uncomment and set your ports:.*?-->", ""
        }

        # Database
        Write-Host ""
        Write-Host "-- Database Engine --"
        Write-Host "  1) PostgreSQL  2) MySQL  3) SQLite  4) Skip"
        $db = Read-Host "  Choose [1-4]"
        $dbBlock = switch ($db) {
            "1" { "## Database Engine`n`n### PostgreSQL`n- Host: localhost, Port: 5432`n- Use JSONB over JSON for queryable structured data`n- Enable pg_stat_statements for query monitoring`n" }
            "2" { "## Database Engine`n`n### MySQL`n- Host: localhost, Port: 3306`n- charset=utf8mb4, collation=utf8mb4_unicode_ci`n- Enable strict mode (STRICT_TRANS_TABLES)`n" }
            "3" { "## Database Engine`n`n### SQLite`n- Path: ./data/app.db`n- Enable WAL mode for concurrent access`n" }
            default { "" }
        }
        if ($dbBlock) {
            $content = $content -replace "## Database Engine", $dbBlock
            $content = $content -replace "(?s)<!-- Uncomment your engine.*?-->", ""
        }

        # Migration Tool
        Write-Host ""
        Write-Host "-- Migration Tool --"
        Write-Host "  1) Alembic  2) Prisma Migrate  3) Django Migrations  4) Knex  5) Skip"
        $mig = Read-Host "  Choose [1-5]"
        $migBlock = switch ($mig) {
            "1" { "## Migration Tool`n- **Alembic** (SQLAlchemy) - migrations run with admin credentials via env.py`n" }
            "2" { "## Migration Tool`n- **Prisma Migrate** - schema.prisma is the source of truth`n" }
            "3" { "## Migration Tool`n- **Django Migrations** - manage.py migrate with admin DB URL`n" }
            "4" { "## Migration Tool`n- **Knex** - knexfile.js reads from .env`n" }
            default { "" }
        }
        if ($migBlock) {
            $content = $content -replace "## Migration Tool", $migBlock
            $content = $content -replace "(?s)<!-- Uncomment your migration tool:.*?-->", ""
        }

        [System.IO.File]::WriteAllText((Resolve-Path $overridesLocal).Path, $content)
        Write-Host ""
        Write-Host "Remaining sections can be edited in: .kiro/steering/user-project-overrides.md"
    }
    Write-Host ""
}

# Write version file
[System.IO.File]::WriteAllText((Join-Path $cwd $VersionFile), $CurrentVersion)

# Summary
Write-Host ""
if ($installType -eq "fresh") {
    Write-Host "Done! $downloaded files installed." -ForegroundColor Green
    Write-Host ""
    Write-Host "Your customization file: .kiro/steering/user-project-overrides.md"
    Write-Host "  This is the only file you need to edit. All other steering files are"
    Write-Host "  managed by kiro-rails and will be updated automatically on upgrade."
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Review .kiro/steering/user-project-overrides.md"
    Write-Host "  2. git add .kiro/ docs/ scripts/ && git commit -m 'feat: add kiro-rails steering files'"
} else {
    Write-Host "Done! $downloaded new, $updated updated, $removed removed." -ForegroundColor Green
    if ($removed -gt 0) { Write-Host "  Stale files from previous versions were cleaned up." }
    Write-Host ""
    Write-Host "Your customization file was not modified: .kiro/steering/user-project-overrides.md"
    Write-Host ""
    Write-Host "Review changes with: git diff"
}

# ----------------------------------------------
# Self-cleanup
# Remove the bootstrap installer if it was run as a downloaded file (-File install.ps1),
# so it isn't left behind. Never removes a git-tracked install.ps1 (e.g. the repo's own).
# ----------------------------------------------
if ($PSCommandPath -and (Test-Path $PSCommandPath) -and ((Split-Path $PSCommandPath -Leaf) -eq "install.ps1")) {
    $tracked = $false
    try { & git ls-files --error-unmatch $PSCommandPath *> $null 2>&1; if ($LASTEXITCODE -eq 0) { $tracked = $true } } catch { $tracked = $false }
    if (-not $tracked) {
        Remove-Item -Force -ErrorAction SilentlyContinue $PSCommandPath
        Write-Host ""
        Write-Host "Cleaned up the downloaded installer ($PSCommandPath)."
    }
}
