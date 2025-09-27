

# Line-by-line explanation of `sys_diagnose.sh`

```bash
#!/usr/bin/env bash
```

**What / Why**

* The *shebang* line. It tells the OS which interpreter to use to run the script.
* `/usr/bin/env bash` finds `bash` in the current `PATH` and runs it. This is more portable than hardcoding `/bin/bash` because `bash` might live in different places on some systems.
* Ensures the script runs under Bash (so we can rely on Bash features like arrays, `[[ ... ]]`, arithmetic expansion, etc).

```bash
# sys_diagnose.sh
#
# Comprehensive Linux service diagnostic tool with numeric indexing.
# Lists all services on systemd-based systems and allows interactive
# management (status, start, stop, restart, enable/disable, logs).
#
# Usage:
#   ./sys_diagnose.sh
#   ./sys_diagnose.sh -h | --help
```

**What / Why**

* Top-of-file comments describing the script’s purpose, usage, and audience.
* Good practice for maintainability: other devs / future-you will instantly know what the script is for.

---

### `show_help` function

```bash
# ------------------------------------------------------------
# Function: show_help
# Displays the help/usage message
# ------------------------------------------------------------
show_help() {
    cat <<EOF
System Diagnostic Tool (sys_diagnose.sh)
----------------------------------------
This script lists ALL services installed on your Linux system
(using systemctl) and allows interactive troubleshooting.

USAGE:
  ./sys_diagnose.sh
  ./sys_diagnose.sh -h | --help

FEATURES:
  * Lists all systemd services with numeric indexes
  * Shows if services are enabled/disabled and running/stopped
  * Lets you pick a service by number to:
      - View detailed status
      - Start/Stop/Restart
      - Enable/Disable at boot
      - View logs with journalctl
EOF
}
```

**What / Why**

* Defines a function named `show_help`.
* `cat <<EOF ... EOF` is a **here-document** that prints the enclosed block to stdout. This is an easy way to output multi-line help text.
* `show_help` is called when the user passes `-h` or `--help`.
* Keeping help text in a function makes the main logic clean and allows reuse.

---

### `list_services` function (collecting services)

```bash
# ------------------------------------------------------------
# Function: list_services
# Collects all services and stores in an array
# ------------------------------------------------------------
list_services() {
```

**What / Why**

* Start of the `list_services` function which collects services and prints an indexed list.

```bash
    echo "============================================================"
    echo "📋 Installed Services on this System"
    echo "============================================================"
```

**What / Why**

* Prints a decorative header so the output is readable. These echo lines are purely cosmetic but improve UX.

```bash
    # Initialize array
    SERVICES=()
```

**What / Why**

* Initializes an empty Bash array named `SERVICES`.
* Arrays store each service entry (service name, enable state, active state) as a single string; later parsed with `cut` or `awk`.

```bash
    # Extract services into array
    while IFS= read -r line; do
        service=$(echo "$line" | awk '{print $1}')
        state=$(echo "$line" | awk '{print $2}')
        active=$(systemctl is-active "$service" 2>/dev/null)
        SERVICES+=("$service|$state|$active")
    done < <(systemctl list-unit-files --type=service --no-pager | awk 'NR>1 && $1 ~ /\.service$/ {print $1, $2}' | sort)
```

**Line-by-line explanation & subtleties**

* `while IFS= read -r line; do`

  * Starts a `while` loop that reads lines from stdin one by one into the variable `line`.
  * `IFS=` temporarily sets the Internal Field Separator to empty to preserve leading/trailing whitespace (defensive; service names won’t have leading spaces but good habit).
  * `-r` tells `read` to treat backslashes literally (prevent escape processing).

* `service=$(echo "$line" | awk '{print $1}')`

  * Uses `awk` to print the first field of the `line`. The first field is expected to be the unit file name (e.g., `ssh.service`).
  * Using `awk` here is simple and robust for whitespace-delimited output.

* `state=$(echo "$line" | awk '{print $2}')`

  * Captures the second field from the `line`, which `systemctl list-unit-files` outputs as the enablement state (e.g., `enabled`, `disabled`, `static`, etc.).

* `active=$(systemctl is-active "$service" 2>/dev/null)`

  * Runs `systemctl is-active <service>` to check runtime state: returns `active`, `inactive`, `failed`, etc.
  * `2>/dev/null` discards any error output (e.g., if systemctl throws an error because the unit is unknown), preventing noisy output in the list.

* `SERVICES+=("$service|$state|$active")`

  * Appends a single string to the `SERVICES` array with fields separated by `|`. This delimiter is chosen because service names do not contain `|` and makes later splitting trivial.
  * Example element: `sshd.service|enabled|active`.

* `done < <(systemctl list-unit-files --type=service --no-pager | awk 'NR>1 && $1 ~ /\.service$/ {print $1, $2}' | sort)`

  * This is **process substitution** (`< <(...)`) — it connects the output of the command inside `(...)` to the `while` as if it were a file.
  * `systemctl list-unit-files --type=service --no-pager`: lists all unit files of type `service` (the output includes a header line). `--no-pager` prevents `systemctl` from piping output to `less` or another pager.
  * `| awk 'NR>1 && $1 ~ /\.service$/ {print $1, $2}'`:

    * `NR>1` skips the first output line (header) from `systemctl`.
    * `$1 ~ /\.service$/` matches only unit file names that end with `.service` (filters out stray lines).
    * `{print $1, $2}` prints the service unit name and the enable state separated by a space.
  * `| sort` sorts the output alphabetically so the final displayed list is deterministic and easy to scan.
  * So the `while` loop processes each service line produced by this pipeline.

**Why this approach?**

* Using `systemctl list-unit-files` gives the canonical list of installed unit files (services).
* Separating enablement state and actual runtime active state lets us show both "enabled/disabled" and "active/inactive".

```bash
    # Print indexed list
    for i in "${!SERVICES[@]}"; do
        svc=$(echo "${SERVICES[$i]}" | cut -d'|' -f1)
        state=$(echo "${SERVICES[$i]}" | cut -d'|' -f2)
        active=$(echo "${SERVICES[$i]}" | cut -d'|' -f3)
        printf "%3d) %-40s %-12s %-12s\n" $((i+1)) "$svc" "$state" "$active"
    done
    echo
}
```

**Line-by-line explanation & subtleties**

* `for i in "${!SERVICES[@]}"; do`

  * Iterates over the **indices** of the `SERVICES` array. `${!SERVICES[@]}` expands to `0 1 2 ...` (array indexes). Using indices lets us show numeric numbering and later pick by index.

* `svc=$(echo "${SERVICES[$i]}" | cut -d'|' -f1)`

  * Uses `cut` to split the stored string by delimiter `|` and fetch field 1 — the service unit name.

* `state=$(echo "${SERVICES[$i]}" | cut -d'|' -f2)`

  * Fetches the enablement state — field 2.

* `active=$(echo "${SERVICES[$i]}" | cut -d'|' -f3)`

  * Fetches runtime state (`active`, `inactive`) — field 3.

* `printf "%3d) %-40s %-12s %-12s\n" $((i+1)) "$svc" "$state" "$active"`

  * Nicely formats each line:

    * `%3d)` prints the index number right-aligned in a field of width 3 followed by a `)`. `$((i+1))` prints 1-based numbering (user-friendly).
    * `%-40s` prints the service name left-aligned in a 40-character field (keeps columns neat).
    * `%-12s` prints enablement state in a 12-character field.
    * `%-12s` prints active state in a 12-character field.
  * Using `printf` ensures fixed column widths across terminals and makes the output readable.

* `echo` prints a blank line after the listing for spacing.

**Notes**

* This function builds an indexed, human-friendly table of installed services with both enablement and runtime status.

---

### `interactive_menu` function (user picks a service by number)

```bash
# ------------------------------------------------------------
# Function: interactive_menu
# Lets user select service by number and take actions
# ------------------------------------------------------------
interactive_menu() {
    while true; do
```

**What / Why**

* Defining the `interactive_menu` function. It contains a `while true` infinite loop so the user can manage multiple services in one session; loop exits when the user chooses to quit.

```bash
        echo "============================================================"
        echo "⚙️  Interactive Service Management"
        echo "============================================================"
        echo "Choose a service by NUMBER (from the list above), or 'q' to quit."
        read -rp "Service number: " choice
```

**What / Why**

* Prints header and instructions.
* `read -rp "Service number: " choice`:

  * `-r` prevents backslash escapes from being interpreted (safe for input).
  * `-p` displays the prompt inline (`"Service number: "`).
  * Stores user input into variable `choice`.

```bash
        [[ "$choice" == "q" ]] && break
```

**What / Why**

* Quick check: if the user typed `q`, break out of the infinite loop and return from `interactive_menu`.
* The `[[ ... ]]` syntax is Bash’s preferred conditional test for pattern matching and safe quoting.
* Using `&&` provides a short-circuit: if the test is true, `break` runs.

```bash
        # Validate numeric input
        if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
            echo "❌ Invalid input. Please enter a number."
            continue
        fi
```

**What / Why**

* Validates that the user input is a positive integer:

  * `[[ "$choice" =~ ^[0-9]+$ ]]` uses Bash regex matching (`=~`) to ensure the entire input is digits (one or more).
  * `!` negates the condition: if not numeric, show error message and `continue` to restart loop (ask again).
* Important: using `[[ ... ]]` with `=~` is a Bash-specific feature (not POSIX sh). Good because the script uses Bash.

```bash
        index=$((choice-1))
        if [[ $index -lt 0 || $index -ge ${#SERVICES[@]} ]]; then
            echo "❌ Invalid number. Please pick from the list."
            continue
        fi
```

**What / Why**

* `index=$((choice-1))` converts the user’s 1-based choice into a 0-based array index for `SERVICES`.
* `if [[ $index -lt 0 || $index -ge ${#SERVICES[@]} ]]; then`:

  * `${#SERVICES[@]}` yields the number of elements in the array.
  * Checks that the index is within valid bounds `[0, length-1]`. If out of bounds, prints an error and loops again.
* Defensive checks prevent accidental out-of-range array access which would cause errors.

```bash
        # Extract service name
        svc=$(echo "${SERVICES[$index]}" | cut -d'|' -f1)
```

**What / Why**

* Extracts only the service unit name for the selected index using `cut` (same delimiter `|` used earlier).
* This is the string we pass to `systemctl` for operations.

```bash
        echo "What do you want to do with $svc?"
        echo "1) View status"
        echo "2) Start service"
        echo "3) Stop service"
        echo "4) Restart service"
        echo "5) Enable on boot"
        echo "6) Disable on boot"
        echo "7) Show logs (journalctl)"
        echo "q) Back to service list"
        read -rp "Choose an option: " action
```

**What / Why**

* Presents a menu of actions to perform on the chosen service. These are the most common systemctl actions and viewing logs is essential for troubleshooting.
* Again uses `read -rp` to capture the chosen action into `action`.

```bash
        case "$action" in
            1) systemctl status "$svc" --no-pager ;;
            2) sudo systemctl start "$svc" && echo "✔ Started $svc" ;;
            3) sudo systemctl stop "$svc" && echo "✔ Stopped $svc" ;;
            4) sudo systemctl restart "$svc" && echo "✔ Restarted $svc" ;;
            5) sudo systemctl enable "$svc" && echo "✔ Enabled $svc on boot" ;;
            6) sudo systemctl disable "$svc" && echo "✔ Disabled $svc on boot" ;;
            7) sudo journalctl -u "$svc" -n 20 --no-pager ;;
            q) continue ;;
            *) echo "❌ Invalid option." ;;
        esac
```

**Line-by-line explanation**

* `case "$action" in ... esac` branches based on the user’s numeric choice.
* `1) systemctl status "$svc" --no-pager ;;`

  * Shows detailed status of the service (unit), including recent logs and active state.
  * `--no-pager` prevents the output from being sent to a pager program like `less` — so output prints directly to terminal (good for scripts and predictable behavior).
  * No `sudo` needed for `systemctl status` on most systems (readonly).
* `2) sudo systemctl start "$svc" && echo "✔ Started $svc" ;;`

  * Uses `sudo` because starting a service is privileged; prompts for password if needed.
  * `&& echo ...` prints success message only if the `systemctl start` command succeeded (exit status 0). If command fails, the echo is skipped.
* `3) sudo systemctl stop "$svc" && echo "✔ Stopped $svc" ;;`

  * Stops the service; again privileged.
* `4) sudo systemctl restart "$svc" && echo "✔ Restarted $svc" ;;`

  * Restarts (stop then start) the service. Useful for applying configuration changes.
* `5) sudo systemctl enable "$svc" && echo "✔ Enabled $svc on boot" ;;`

  * Enables the service to start on boot (creates symlinks in `systemd` unit directories).
* `6) sudo systemctl disable "$svc" && echo "✔ Disabled $svc on boot" ;;`

  * Disables the service from starting on boot.
* `7) sudo journalctl -u "$svc" -n 20 --no-pager ;;`

  * Shows the last 20 log lines for that unit using systemd’s journal. `-u` filters by unit name. `-n 20` limits to 20 lines. `--no-pager` same reasoning as above. `sudo` is used to ensure we can read logs if they require root privileges.
* `q) continue ;;`

  * If user picks `q`, just continue — go back to the top of the `while` to pick another service.
* `*) echo "❌ Invalid option." ;;`

  * Default catch-all — if user enters an unexpected value, print an error.

```bash
    done
}
```

**What / Why**

* Closes the `while` loop and the `interactive_menu` function.

---

### Main Program Logic (argument handling)

```bash
# ------------------------------------------------------------
# Main Program Logic
# ------------------------------------------------------------
case "$1" in
    -h|--help)
        show_help
        ;;
    "")
        list_services
        interactive_menu
        ;;
    *)
        echo "Invalid option: $1"
        echo "Use --help to see usage."
        exit 1
        ;;
esac
```

**Line-by-line explanation**

* `case "$1" in ... esac` inspects the script’s first positional argument (if any).
* `-h|--help)`:

  * If `-h` or `--help` passed, call `show_help` and then exit the `case`. `show_help` prints the usage text and returns.
* `"" )`:

  * If `$1` is empty (no arguments passed), this matches the empty string. Then the script calls `list_services` to print the indexed list, and then `interactive_menu` to allow management.
  * Note: Matching `""` is a clear, explicit design choice to handle no-argument invocation. If other positional arguments are passed, the default case handles them.
* `*)`:

  * Any other first argument is considered invalid; the script prints an error and returns exit code 1.

---

## Additional notes, tips, and gotchas

* **Requires `systemd` / `systemctl`** — This script is designed for systems using `systemd`. It won’t work on systems using `sysvinit` or other init systems. You could add a pre-check `command -v systemctl >/dev/null || { echo "Requires systemctl"; exit 1; }`.
* **Permissions** — Actions that change system state (start/stop/enable/disable) use `sudo`. If the script is run as root, `sudo` will not prompt. If not root, the user will be asked for their password the first time `sudo` is used.
* **Internationalization / locale** — `systemctl` output is stable but if the system's locale changed text might differ; this script uses structured commands (like `systemctl is-active`) rather than parsing human text, which is more robust.
* **Large service lists** — On systems with many services, the list may be long. You could pipe the output to a pager or write to a temporary file for paging. The script prints full list; you interact by numeric index.
* **Service names with spaces** — Unit files don’t contain spaces; they are safe to treat as single tokens. That’s why splitting by whitespace and using field 1 from `awk` works.
* **Error handling** — The script prints basic success messages when `systemctl` commands succeed. For production-grade scripts you might check return codes explicitly and provide more elaborate error output or logging.
* **Extending the script**:

  * Add filtering (e.g., search by substring).
  * Allow bulk operations (restart multiple services).
  * Export a report file (`/tmp/sys_diagnose_report.txt`) with timestamps.
  * Add colorized output (ANSI color codes) for readability.

---

## Quick summary (what you now know)

* The script collects the list of installed `systemd` services (`systemctl list-unit-files`), builds an array of entries (`SERVICES`), prints a numbered table and lets the user pick a service by number.
* For the chosen service the user can run `systemctl status`, `start/stop/restart`, `enable/disable` and view recent logs via `journalctl`.
* Input is validated and the script handles common edge cases (invalid number, quitting).
* The code uses modern Bash features: arrays, process substitution, `[[ ... ]]`, arithmetic expansion, and formatted `printf`.

---

