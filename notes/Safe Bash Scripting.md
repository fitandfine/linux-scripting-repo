# Safe Bash Scripting for Absolute Beginners: `set -euo pipefail`

When writing Bash scripts, **safety and predictability** are critical. A small typo, an unset variable, or an unnoticed command failure can break your automation. The Bash idiom `set -euo pipefail` helps prevent these issues by enforcing strict error handling.

---

## 1. Understanding `set -euo pipefail`

This combination sets three important options in Bash:

### a) `set -e`

* **Meaning:** Exit the script immediately if any command returns a non-zero (failure) status.
* **Why it matters:** Prevents the script from continuing after an error, which could cause unexpected side effects.
* **Example:**

```bash
#!/usr/bin/env bash
set -e

echo "Step 1: OK"
false  # Simulates a command failure
echo "Step 2: This will NOT run because the script exited"
```

### b) `set -u`

* **Meaning:** Treat unset variables as an error.
* **Why it matters:** Helps catch typos and prevents the script from using empty or undefined values.
* **Example:**

```bash
#!/usr/bin/env bash
set -u

echo "Value of MY_VAR is: $MY_VAR"  # Script will exit if MY_VAR is not set
```

### c) `set -o pipefail`

* **Meaning:** Ensures that if any command in a pipeline fails, the pipeline returns a non-zero status.
* **Why it matters:** Without this, pipelines may silently ignore failures of intermediate commands.
* **Example:**

```bash
#!/usr/bin/env bash
set -o pipefail

false | true  # First command fails
echo $?       # Prints non-zero because pipefail catches the failure
```

Without `pipefail`, the above would return 0, hiding the failure of `false`.

---

## 2. How to Use `set -euo pipefail`

Always place it at the **top of your Bash scripts**:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

### Example: Safe File Copy Script

```bash
#!/usr/bin/env bash
set -euo pipefail

SRC_FILE="/path/to/source.txt"
DEST_DIR="/tmp/backup"

# Ensure the destination directory exists
mkdir -p "$DEST_DIR"

# Copy the file safely
cp "$SRC_FILE" "$DEST_DIR/"

echo "File copied successfully!"
```

* Script exits immediately if `mkdir` or `cp` fails.
* Unset variables cause an immediate exit.
* Any pipeline failures are caught.

---

## 3. Benefits of Using `set -euo pipefail`

1. **Safety:** Stops execution on errors to prevent unintended operations.
2. **Predictability:** Scripts behave consistently even in unexpected conditions.
3. **Debugging:** Easier to identify which command caused the script to fail.
4. **Maintainability:** Encourages writing clean and robust scripts.

---

## 4. Best Practices for Beginners

1. **Always enable `set -euo pipefail`** at the top of your scripts.
2. **Quote your variables** to avoid word splitting:

```bash
echo "$VAR"
```

3. **Validate inputs** to functions or scripts to avoid empty or undefined variables.
4. **Use functions** for reusable logic.
5. **Handle errors gracefully** with `trap`:

```bash
#!/usr/bin/env bash
set -euo pipefail
trap 'echo "An error occurred. Exiting..."' ERR
```

6. **Test your scripts** with different scenarios before using them in production.

---

## 5. Summary

`set -euo pipefail` is a **must-know idiom for safe Bash scripting**, especially for beginners. It:

* Exits on command errors (`-e`)
* Prevents use of unset variables (`-u`)
* Catches pipeline failures (`pipefail`)

Using this in every script helps build confidence that your automation will run safely and predictably, making it a professional standard in Bash scripting.
