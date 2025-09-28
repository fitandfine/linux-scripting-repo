

# 🧑‍💻 Bash Scripting Exercises with Solutions

Author: **Anup Chapain**


---

## 📌 1. Hello User (Beginner)

**Task:**
Write a script that asks for your name and prints a personalized greeting.

```bash
#!/usr/bin/env bash
read -p "Enter your name: " name
echo "Hello, $name! Welcome to Bash scripting 🚀"
```

✅ *Concepts used:* `read`, variables, echo.

---

## 📌 2. Even or Odd (Beginner)

**Task:**
Ask the user for a number and print whether it’s even or odd.

```bash
#!/usr/bin/env bash
read -p "Enter a number: " num
if (( num % 2 == 0 )); then
    echo "$num is Even"
else
    echo "$num is Odd"
fi
```

✅ *Concepts used:* `if`, arithmetic expansion.

---

## 📌 3. Simple Calculator (Beginner → Intermediate)

**Task:**
Take two numbers and an operator (+,-,*,/) as arguments and print the result.

```bash
#!/usr/bin/env bash
num1=$1
op=$2
num2=$3

case $op in
    +) echo "$((num1 + num2))" ;;
    -) echo "$((num1 - num2))" ;;
    \*) echo "$((num1 * num2))" ;;
    /) echo "$((num1 / num2))" ;;
    *) echo "Invalid operator" ;;
esac
```

Usage:

```bash
./calc.sh 10 + 5   # Output: 15
```

✅ *Concepts used:* arguments (`$1`), `case`, arithmetic.

---

## 📌 4. File Existence Check (Intermediate)

**Task:**
Write a script that checks if a file exists and tells its size.

```bash
#!/usr/bin/env bash
file=$1
if [ -f "$file" ]; then
    echo "✅ $file exists"
    ls -lh "$file" | awk '{print "Size:", $5}'
else
    echo "❌ $file not found"
fi
```

✅ *Concepts used:* file test `-f`, `ls`, `awk`.

---

## 📌 5. Countdown Timer (Intermediate)

**Task:**
Write a countdown timer from 10 to 1.

```bash
#!/usr/bin/env bash
for i in {10..1}; do
    echo "⏳ $i"
    sleep 1
done
echo "🚀 Time's up!"
```

✅ *Concepts used:* loops, `sleep`.

---

## 📌 6. System Health Check (Intermediate → Advanced)

**Task:**
Print CPU load, memory usage, and disk usage.

```bash
#!/usr/bin/env bash
echo "===== 🖥 System Health ====="
echo "CPU Load:"; uptime
echo
echo "Memory Usage:"; free -h
echo
echo "Disk Usage:"; df -h /
```

✅ *Concepts used:* `uptime`, `free`, `df`.

---

## 📌 7. Log Monitor (Advanced)

**Task:**
Monitor `/var/log/syslog` and show only new errors (`ERROR`).

```bash
#!/usr/bin/env bash
tail -f /var/log/syslog | grep --line-buffered "ERROR"
```

✅ *Concepts used:* `tail -f`, `grep`.

---

## 📌 8. Backup Script (Advanced)

**Task:**
Backup `/etc` into `~/backup` with today’s date.

```bash
#!/usr/bin/env bash
src="/etc"
dest="$HOME/backup/$(date +%F)"
mkdir -p "$dest"
cp -r "$src" "$dest"
echo "✅ Backup completed: $dest"
```

✅ *Concepts used:* variables, `date`, `mkdir -p`, `cp -r`.

---

## 📌 9. User Manager (Advanced)

**Task:**
Interactive script to create a new Linux user.

```bash
#!/usr/bin/env bash
read -p "Enter new username: " user
if id "$user" &>/dev/null; then
    echo "❌ User already exists"
else
    sudo adduser "$user"
    echo "✅ User $user created"
fi
```

✅ *Concepts used:* `id`, `adduser`, conditionals, sudo.

---

## 📌 10. Mini Menu Tool (Advanced)

**Task:**
Create a script that shows a menu with options.

```bash
#!/usr/bin/env bash
while true; do
    echo "===== MENU ====="
    echo "1. Show date"
    echo "2. Show uptime"
    echo "3. Show disk usage"
    echo "4. Exit"
    read -p "Choose an option: " choice

    case $choice in
        1) date ;;
        2) uptime ;;
        3) df -h ;;
        4) echo "Bye 👋"; exit 0 ;;
        *) echo "Invalid choice" ;;
    esac
    echo
done
```

✅ *Concepts used:* loops, `case`, interactive menus.

---

# 📚 How to Practice

1. Create a new folder in your repo:
   `mkdir -p linux-scripting-repo/exercises && cd linux-scripting-repo/exercises`
2. Save each exercise as a separate `.sh` file.
3. Make it executable:
   `chmod +x script.sh`
4. Run and test different inputs.
5. Try modifying them for your own use cases.


