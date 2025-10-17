
# 📘 Oracle Docs Language Checker — Technical Documentation

**Author:** Anup Chapain
**Date:** October 18, 2025

---

## 🧭 Overview

This Bash script automates the process of **checking which languages are supported** on the [Oracle Cloud Documentation Portal](https://docs.oracle.com/).
It systematically replaces the `/en/` (English) language code in Oracle’s documentation URL pattern with various other language codes, then sends HTTP requests to check if the corresponding page exists.

If a URL returns a `200 OK` response, that language is considered **supported**; otherwise, it’s marked **unsupported**.

---

## ⚙️ High-Level Workflow

1. Read a list of language codes and their human-readable names from `languages.txt`.
2. For each language:

   * Construct a URL using its two-letter code.
   * Use `curl` to check the HTTP response code.
3. Record results in:

   * `supported_languages.txt`
   * `unsupported_languages.txt`
4. Run checks **in parallel** (using background jobs) to significantly reduce total execution time.

---

## 📁 Files Used

| File                        | Purpose                                                         |
| --------------------------- | --------------------------------------------------------------- |
| `languages.txt`             | Input list of languages (e.g., `en English`, `fr French`, etc.) |
| `supported_languages.txt`   | Output file containing all URLs that returned `HTTP 200`        |
| `unsupported_languages.txt` | Output file containing URLs that did **not** return `HTTP 200`  |
| `check_languages.sh`        | The main executable script (documented here)                    |

---

## 🧩 Key Features

* ✅ **Parallel Execution:** Uses Bash background jobs (`&`) for concurrent HTTP requests.
* ✅ **Concurrency Control:** Prevents system overload using a job limit (`MAX_JOBS`).
* ✅ **Error Handling:** Enabled via `set -euo pipefail`.
* ✅ **Dynamic Reporting:** Generates clean output and saves categorized results.
* ✅ **Extensibility:** Can easily adapt to any website that uses a language code URL structure.

---

## 🧠 Bash Concepts Demonstrated

| Concept                               | Explanation                                                             |                                                               |
| ------------------------------------- | ----------------------------------------------------------------------- | ------------------------------------------------------------- |
| **Subshells**                         | Each background job (`&`) runs in its own isolated environment.         |                                                               |
| **Redirections (`>`, `>>`)**          | Used to write to and append results in output files.                    |                                                               |
| **Job Control**                       | `jobs -r                                                                | wc -l` checks how many background jobs are currently running. |
| **Pipelines & Parallelization**       | Simulates GNU Parallel behavior using native Bash.                      |                                                               |
| **Exit Safety (`set -euo pipefail`)** | Ensures early exit on any error or undefined variable.                  |                                                               |
| **Process Synchronization (`wait`)**  | Ensures all background tasks finish before proceeding.                  |                                                               |
| **HTTP Response Handling**            | Uses `curl -w "%{http_code}"` to extract HTTP status codes efficiently. |                                                               |

---

## 🧾 Full Script with Explanations

### 1. Script Header and Metadata

```bash
#!/usr/bin/env bash
#
# Author: Anup Chapain
# Date: 2025-10-18
# Description:
#   This script tests which Oracle Cloud documentation language URLs return HTTP 200 (OK).
#   It reads a list of language codes and names from a file (languages.txt),
#   replaces the "en" in the base URL with each code,
#   and performs the check in parallel.
#
#   Supported URLs are written to supported_languages.txt
#   Unsupported URLs are written to unsupported_languages.txt
#
#   This demonstrates parallel execution and robust reporting.
```

🧩 **Explanation:**

* The shebang (`#!/usr/bin/env bash`) ensures the script runs using the system’s default Bash interpreter.
* The metadata block serves as professional documentation — describing author, date, and functionality.

---

### 2. Safety Settings

```bash
set -euo pipefail
```

| Option        | Meaning                                                    |         |
| ------------- | ---------------------------------------------------------- | ------- |
| `-e`          | Exit immediately if any command returns a non-zero status. |         |
| `-u`          | Treat unset variables as errors.                           |         |
| `-o pipefail` | Prevents pipelines from hiding errors (e.g., `cmd1         | cmd2`). |

✅ **Purpose:** Guarantees robust error handling and prevents undefined behavior in large automation workflows.

---

### 3. Configuration Section

```bash
BASE_URL="https://docs.oracle.com"
LANG_FILE="languages.txt"
SUPPORTED_FILE="supported_languages.txt"
UNSUPPORTED_FILE="unsupported_languages.txt"
MAX_JOBS=10
```

📘 **Explanation:**

* Defines the **core variables** used throughout the script.
* `MAX_JOBS` controls concurrency — only 10 HTTP checks will run at once.
* This makes the script fast yet resource-safe.

---

### 4. Pre-run Validation

```bash
> "$SUPPORTED_FILE"
> "$UNSUPPORTED_FILE"
```

* The `>` operator truncates the files if they already exist (creates empty placeholders).

```bash
if [ ! -f "$LANG_FILE" ]; then
  echo "❌ Error: Language list file ($LANG_FILE) not found!"
  exit 1
fi
```

🧩 **Purpose:** Verifies that `languages.txt` exists before proceeding. Exiting early avoids unnecessary network requests.

```bash
TOTAL_LANGS=$(wc -l < "$LANG_FILE")
COMPLETED=0
```

* `wc -l` counts total lines (languages) in the file.
* `COMPLETED` was meant to track completed checks, but due to **subshell isolation** (explained below), it remains static in parallel jobs.

---

### 5. Function Definition: `check_language()`

```bash
check_language() {
  local code="$1"
  local name="$2"
  local test_url="${BASE_URL}/${code}/cloud/"
  local status_code

  status_code=$(curl -s -o /dev/null -w "%{http_code}" "$test_url")
```

🧩 **Step Breakdown:**

1. Each function call handles **one language**.
2. `curl` is used silently (`-s`) to prevent output.
3. The flag `-w "%{http_code}"` prints only the HTTP status code.
4. `-o /dev/null` discards the downloaded content, saving bandwidth.

---

### 6. Handling Results

```bash
if [ "$status_code" -eq 200 ]; then
    echo "✅ Supported: $name ($code) -> $test_url"
    echo "$name ($code): $test_url" >> "$SUPPORTED_FILE"
else
    echo "❌ Not supported: $name ($code) [$status_code]"
    echo "$name ($code): $test_url [$status_code]" >> "$UNSUPPORTED_FILE"
fi
```

* If `200`, it’s a valid page — appended to `supported_languages.txt`.
* Otherwise, it’s logged in `unsupported_languages.txt` for analysis.

---

### 7. Understanding Subshell Isolation

```bash
# 🛑 PROGRESS TRACKING FAILURE NOTE
# Each background job ('&') runs in its own isolated environment (subshell).
# When ((COMPLETED++)) is executed inside a subshell, the parent’s variable remains unchanged.
# Thus, "COMPLETED" never increases globally.
```

**In short:**

* Parallelization causes the script to “fork” subprocesses.
* Each subprocess has its own copy of variables — changes inside them vanish after exit.
* Therefore, the counter never increments as expected.

🧠 **Solution (Theoretical):**
To fix this, use an **IPC (Inter-Process Communication)** method such as:

* A shared counter file protected by `flock`.
* A named pipe (FIFO).
* A dedicated parent process monitoring completions.

---

### 8. Parallel Execution Logic

```bash
while read -r code name; do
  check_language "$code" "$name" &
  
  while (( $(jobs -r | wc -l) >= MAX_JOBS )); do
    sleep 0.2
  done
done < "$LANG_FILE"
```

🧩 **What’s Happening:**

1. `read -r code name` reads each line (e.g., `en English`) into variables.
2. Each call to `check_language` is executed **in the background** using `&`.
3. The inner `while` loop monitors running jobs:

   * `jobs -r` lists active jobs.
   * If active jobs exceed `MAX_JOBS`, the script sleeps briefly.
4. This maintains **controlled concurrency**, similar to `GNU parallel`.

---

### 9. Synchronization & Completion

```bash
wait
```

* `wait` pauses the parent process until **all** background jobs finish.
* Only after this point are the output files guaranteed complete.

---

### 10. Final Output

```bash
echo
echo "-------------------------------------------"
echo "✅ Scan complete!"
echo "📄 $(wc -l < "$SUPPORTED_FILE") Supported languages:  see  $SUPPORTED_FILE"
echo "📄 $(wc -l < "$UNSUPPORTED_FILE") Unsupported languages: see $UNSUPPORTED_FILE"
```

🧩 **Explanation:**

* Summarizes the results using dynamic line counts.
* Provides clear paths to the generated reports.

---

## 🧱 Limitations & Future Improvements

| Limitation                                | Suggested Fix                                           |
| ----------------------------------------- | ------------------------------------------------------- |
| **`COMPLETED` counter doesn’t increment** | Use a named pipe (FIFO) or lock-protected counter file. |
| **Unordered console output**              | Use `wait -n` or queue system for controlled printing.  |
| **No real progress bar**                  | Integrate `pv`, `dialog`, or a progress FIFO reader.    |
| **Hardcoded job limit**                   | Make `MAX_JOBS` configurable via CLI arguments.         |

---

## 💡 Example Output

```
🔍 Checking Oracle Docs language support...
-------------------------------------------
Total languages to check: 118

✅ Supported: English (en) -> https://docs.oracle.com/en/cloud/
❌ Not supported: Afrikaans (af) [404]
✅ Supported: Japanese (ja) -> https://docs.oracle.com/ja/cloud/
✅ Supported: Arabic (ar) -> https://docs.oracle.com/ar/cloud/

-------------------------------------------
✅ Scan complete!
📄 7 Supported languages: see supported_languages.txt
📄 111 Unsupported languages: see unsupported_languages.txt
```

---

## 🧭 Takeaways

* This script reflects **real-world DevOps scripting practices** — concurrency, safety, and structured output.
* The problem of shared variable scope in subshells teaches a fundamental Linux scripting concept:
  **Parallelism requires explicit communication channels.**
* The design is easily extensible to check for:

  * API health statuses,
  * Website localization,
  * Service availability testing.

---

## 🏁 Author’s Note

> *“This script was written as part of my pointless curiosity to know the supported languages, i.e Website localization.”*
>
> — **Anup Chapain**

---
