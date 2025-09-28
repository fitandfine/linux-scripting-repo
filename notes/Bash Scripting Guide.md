
# 🐚 Bash Scripting — Complete Beginner to Advanced Guide

**Author:** Anup Chapain
**Repository:** `linux-scripting-repo/notes/bash_scripting.md`

---

## 📌 Introduction

**Bash** (Bourne Again SHell) is the default shell on most Linux systems.

With Bash scripting, you can:

* Automate **boring repetitive tasks**
* Manage servers and infrastructure
* Write **diagnostic and monitoring tools**
* Glue together Linux commands into something powerful

This guide is **self-contained** — if you carefully read and practice it, you’ll have the knowledge to write your own **any-level Bash script**.

By the end, you will be able to:

✅ Write **reliable Bash scripts**
✅ Automate **system administration tasks**
✅ Use **best practices** for maintainability
✅ Debug and troubleshoot like a pro

---

## 🧩 Chapter 1: Basics of Bash

### 1.1 What is a Bash Script?

A Bash script is just a **text file** that contains a list of commands executed by the Bash shell in order.

Example: `hello.sh`

```bash
#!/usr/bin/env bash
# This is a simple hello world script
echo "Hello, World!"
```

Run it:

```bash
chmod +x hello.sh   # give it execute permission
./hello.sh
```

---

### 1.2 Shebang (`#!`)

The **first line** in almost every script starts with a *shebang*.

Example:

```bash
#!/usr/bin/env bash
```

🔎 **Explanation:**

* `#!` tells Linux: *“use this program to run the file.”*
* `/usr/bin/env bash` is **better** than `/bin/bash` because:

  * It finds Bash wherever it is installed (`env` searches your PATH).
  * More portable across Linux, macOS, BSD.

If you only use:

```bash
#!/bin/bash
```

…it may fail on systems where Bash isn’t installed in `/bin`.

---

### 1.3 Variables

Variables store values (strings, numbers, paths).
No spaces around `=`.

```bash
#!/usr/bin/env bash
name="Anup"
echo "Hello, $name"
```

System environment variables:

```bash
echo "User: $USER"
echo "Home directory: $HOME"
```

💡 **Tip:** Always quote variables (`"$var"`) to avoid word-splitting bugs.

---

### 1.4 Comments

```bash
# This is a single-line comment
```

Comments make your scripts **readable** for:

* Future-you (you’ll forget why you wrote that line)
* Your team

---

### 1.5 Input and Output

Reading user input:

```bash
#!/usr/bin/env bash
read -p "Enter your name: " username
echo "Welcome, $username!"
```

Options:

* `read -s` → hide input (e.g., passwords)
* `read -t 5` → timeout after 5 seconds

---

## 🧩 Chapter 2: Control Structures

### 2.1 If Statements

```bash
#!/usr/bin/env bash
x=10
if [ "$x" -gt 5 ]; then
    echo "x is greater than 5"
fi
```

Operators:

* `-eq` → equal
* `-ne` → not equal
* `-gt` → greater than
* `-lt` → less than
* `-f file` → file exists
* `-d dir` → directory exists

With else:

```bash
if [ -f "/etc/passwd" ]; then
    echo "File exists"
else
    echo "File not found"
fi
```

---

### 2.2 Case Statements

Instead of many `if` checks:

```bash
read -p "Enter a number (1-3): " num
case $num in
    1) echo "One" ;;
    2) echo "Two" ;;
    3) echo "Three" ;;
    *) echo "Invalid choice" ;;
esac
```

---

### 2.3 Loops

**For loop**

```bash
for i in 1 2 3 4 5; do
    echo "Number: $i"
done
```

**While loop**

```bash
count=1
while [ $count -le 5 ]; do
    echo "Count: $count"
    ((count++))
done
```

**Until loop**

```bash
x=1
until [ $x -gt 5 ]; do
    echo "x = $x"
    ((x++))
done
```

---

## 🧩 Chapter 3: Functions

Functions help organize reusable logic.

```bash
#!/usr/bin/env bash
greet() {
    echo "Hello, $1"
}

greet "Anup"
```

* `$1`, `$2`, … = function arguments
* Functions return values via `echo` (or `return <number>` for status codes)

---

## 🧩 Chapter 4: File Operations

Check if file exists:

```bash
if [ -f "file.txt" ]; then
    echo "File exists"
fi
```

Read line by line:

```bash
while IFS= read -r line; do
    echo "Line: $line"
done < file.txt
```

Write to file:

```bash
echo "Hello" > file.txt   # overwrite
echo "World" >> file.txt  # append
```

---

## 🧩 Chapter 5: Useful Commands

* `date` → show date
* `uptime` → show load average
* `df -h` → disk usage
* `free -m` → memory usage
* `ps aux` → running processes
* `grep` → search inside text
* `awk`, `sed` → text processing

Example:

```bash
ps aux | grep apache2
```

---

## 🧩 Chapter 6: Error Handling

Every command returns an **exit code**:

* `0` = success
* non-zero = failure

Check:

```bash
ls /etc/passwd
echo $?   # 0

ls /notexist
echo $?   # non-zero
```

Stop on errors:

```bash
set -e
```

---

## 🧩 Chapter 7: Script Arguments

Scripts accept arguments:

```bash
#!/usr/bin/env bash
echo "Script name: $0"
echo "First arg: $1"
echo "Arg count: $#"
echo "All args: $@"
```

Example:

```bash
./myscript.sh hello world
```

---

## 🧩 Chapter 8: Logging

```bash
LOGFILE="$HOME/script.log"
echo "$(date) - Script started" | tee -a "$LOGFILE"
```

* `tee` = print to screen AND save to file

---

## 🧩 Chapter 9: Scheduling Scripts

Automate with cron:

```bash
crontab -e
```

Example: run every midnight

```
0 0 * * * /home/anup/backup.sh
```

---

## 🧩 Chapter 10: Advanced Concepts

### Arrays

```bash
arr=("apple" "banana" "cherry")
echo "First: ${arr[0]}"
echo "All: ${arr[@]}"
```

### Command substitution

```bash
today=$(date)
echo "Today is $today"
```

### Arithmetic

```bash
x=5; y=3
echo $((x + y))
```

### Debugging

```bash
bash -x myscript.sh
```

---

## 🧩 Chapter 11: Real-World Examples

### Health check script

```bash
#!/usr/bin/env bash
echo "Disk usage:"
df -h
echo "Memory usage:"
free -m
echo "Top 5 processes:"
ps aux --sort=-%mem | head -5
```

### Backup script

```bash
#!/usr/bin/env bash
src="/var/www/html"
dest="$HOME/backup"
mkdir -p "$dest"
cp -r "$src" "$dest/$(date +%F)"
echo "Backup complete"
```

---

## 🧩 Chapter 12: Best Practices

✅ Always start with `#!/usr/bin/env bash`
✅ Quote variables → `"$var"`
✅ Use functions for modularity
✅ Use `set -e` to stop on errors
✅ Add logging with `tee`
✅ Comment your code generously

---

## 🧯 Troubleshooting

* `command not found` → check PATH or install package
* `permission denied` → run `chmod +x script.sh`
* `bad substitution` → using Bash features in `sh`
* `syntax error: unexpected token` → missing `fi`, `done`, `;;`

---

## 📚 Quick Revision Checklist

* [x] Shebang (`#!/usr/bin/env bash`)
* [x] Variables
* [x] Input/output (`read`, `echo`)
* [x] If/else, case
* [x] Loops (for/while/until)
* [x] Functions
* [x] File operations
* [x] Exit codes, `set -e`
* [x] Script arguments
* [x] Logging with `tee`
* [x] Cron automation
* [x] Arrays, substitution, arithmetic
* [x] Debugging (`bash -x`)

---


# Practice Basics here:
## [Basic Bash Scripting Practice](https://github.com/fitandfine/linux-scripting-repo/blob/main/notes/practice_scripts.md)
