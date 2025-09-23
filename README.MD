# Bash Scripting Learning Repository

Welcome to my **Bash Scripting Learning Repository**! This repository is designed for beginners to learn Linux Bash scripting from scratch and demonstrate practical scripting skills through real examples. It contains study notes (explanations of fundamental Bash concepts) ready-to-run scripts.

---

## Contents

- **/notes** folder contains study materials on various topics.
- **/scripts** folder contains codes with comments.

---

## Why This Repository is Useful

* Ideal for beginners learning Linux Bash scripting
* Demonstrates key concepts: variables, loops, conditionals, functions, environment variables
* Provides ready-to-run practical scripts for automation
* Implements safety practices (`set -euo pipefail`) and clear documentation



---
## Quick Start

1. Clone the repository:

```bash
git clone https://github.com/fitandfine/linux-scripting-repo
cd linux-scripting-repo
```

2. Make scripts executable:

```bash
chmod +x scripts/*.sh
```
or you can make individual script files executable as well with 
```bash
cd scripts
chmod +x your_script.sh
```


3. Run a script:

```bash
./scripts/your_script.sh --help
```

---

## Bash Syntax Reference for Beginners

### 1. Shebang

Specifies the interpreter to run the script:

```bash
#!/usr/bin/env bash
```

### 2. Variables

```bash
# Assigning a variable
name="Alice"
# Accessing variable
echo "Hello $name"
# Exporting variable to child processes
export MY_VAR="123"
```

### 3. Command Line Arguments

```bash
$0  # script name
$1  # first argument
$2  # second argument
$@  # all arguments as separate words
$*  # all arguments as a single string
$#  # number of arguments
$!  # PID of last background process
$?  # the exit status of the most recently executed foreground command.
     A value of 0 means success. Any other value (from 1 to 255) means failure.
```

### 4. Conditionals

#### If statements

```bash
if [[ -n "$1" ]]; then  # non-empty string
  echo "Argument provided: $1"
elif [[ $1 -eq 0 ]]; then  # numeric comparison
  echo "Argument is zero"
else
  echo "No argument provided"
fi
```

* `-n STRING` $\rightarrow$ true if string is non-empty
* `-f FILE` $\rightarrow$ true if file exists and is a regular file
---
### Numeric operators:
* `-eq` $\rightarrow$ Equal to
* `-ne` $\rightarrow$ Not Equal to
* `-lt` $\rightarrow$ Less than
* `-le` $\rightarrow$ Less than or equal to
* `-gt` $\rightarrow$ Greater than
* `-ge` $\rightarrow$ Greater than or equal to
---
* `[[ ... ]]` $\rightarrow$ recommended for condition tests

#### Case statements*

```bash
case $1 in
  start) echo "Starting service";;
  stop) echo "Stopping service";;
  *) echo "Unknown command";;  # Wild card pattern match (like default case in C)
esac
```

### 5. Loops

#### For loop

```bash
for i in {1..5}; do
  echo "Number $i"
done
```

#### While loop

```bash
count=1
while [[ $count -le 5 ]]; do
  echo "Count $count"
  ((count++))
done
```

#### Until loop

```bash
count=1
until [[ $count -gt 5 ]]; do
  echo "Count $count"
  ((count++))
done
```

### 6. Functions

```bash
my_function() {
  local name=$1
  echo "Hello $name"
}

my_function "Bob"
```

* Use `local` for variables inside functions
* Return values via `echo` and capture with `var=$(my_function)`

### 7. Input and Output

```bash
# Read input from user
read -p "Enter your name: " name
echo "Hello $name"

# Redirect output
echo "Hello" > file.txt      # overwrite
echo "World" >> file.txt     # append

# Redirect errors
command 2> error.log           # stderr
command > output.log 2>&1       # stdout + stderr
```

### 8. Environment Variables

```bash
echo $HOME     # user's home directory
echo $PWD      # current working directory
echo $USER     # username
echo $SHELL    # default shell
export MY_VAR="123"  # set environment variable
```

### 9. Special Variables

* `$?` → exit code of last command
* `$$` → PID of current script
* `$!` → PID of last background process
* `$0` → script name
* `$*` / `$@` → all arguments
* `$#` → number of arguments

### 10. Command Substitution

```bash
files=$(ls *.txt)
echo $files
```

* Captures the output of a command and stores in a variable

### 11. Pipes

```bash
ls -l | grep ".txt"  # send output of ls to grep
```

* Chains commands so output of one becomes input of another

### 12. Combining Loops and Conditionals

```bash
#!/usr/bin/env bash
for file in *.log; do
  if [[ -s $file ]]; then  # check if file is non-empty
    echo "$file is not empty"
  fi
done
```

### 13. Safety and Best Practices

* Use `set -euo pipefail` to catch errors early
* Quote variables: `"$var"` to avoid word splitting
* Validate input arguments
* Provide `--help` usage messages in scripts
* Break scripts into functions for readability
* Test scripts with different scenarios

### 14. Useful Commands in Scripts

* `grep` → search text
* `awk` / `sed` → text processing
* `cut` → extract columns
* `find` → locate files
* `xargs` → construct commands from input
* `rsync` → copy/sync files efficiently

### 15. Example Script

```bash
#!/usr/bin/env bash
# Check if a file exists and print message
FILE=$1
if [[ -f "$FILE" ]]; then
  echo "$FILE exists"
else
  echo "$FILE does not exist"
fi
```

---

## Tips for Beginners

* Always quote variables: `"$var"`
* Use `set -euo pipefail` for safe scripts
* Add comments and clear usage instructions
* Start small: automate basic tasks first
* Gradually add functions, loops, and argument handling

---
# Also check out this website:
# https://explainshell.com/ by Idan Kamara

# https://github.com/idank/explainshell 
