# 🐚 MyShell – A Custom Interactive Linux Shell  

A lightweight, educational, and extendable mini-shell built using Bash.  
Designed to demonstrate core OS concepts like command parsing, file operations, interactive loops, system control commands, and safe privileged execution.

---

## 🚀 Overview  
**MyShell** is a custom command-line shell environment created as part of an Operating Systems project.  
It simulates essential shell behaviors while adding safe wrappers around useful Linux system commands.

This project is perfect for students learning:
- Linux shell scripting  
- OS-level command execution  
- Safe system control  
- Parsing user input  
- Building interactive CLI tools  

---


## ✨ Features

### 🔹 File Management Commands  
| Command | Description |
|---------|-------------|
| `my_ls` | List files (supports flags like `-l`, `-a`) |
| `my_cat <file>` | Show file content |
| `my_cat > <file>` | Create/overwrite file (Ctrl+D to save) |
| `my_cp <src> <dst>` | Copy file |
| `my_mv <src> <dst>` | Move/Rename file |
| `my_rm <file>` | Remove file with safety confirmation |

---


### 🔹 System Commands  
| Command | Action |
|---------|--------|
| `update` | Auto-detects apt/pacman → refreshes package lists |
| `upgrade` | Performs system upgrade |
| `shutdown` / `poweroff` | Safe shutdown with confirmation |
| `restart` | Restart the machine |
| `sleep` | Suspend to RAM |

All system commands include:
- **sudo privilege checks**
- **user confirmation prompts**
- **action logging**

---


### 🔹 Built-in Utilities  
| Command | Purpose |
|---------|---------|
| `help` | Shows full documentation |
| `features` | Prints topics from *Linux Performance Tweaks.md* |
| `exit` | Quits MyShell |

---


## 🛡 Safety Mechanisms  
MyShell prevents unintentional destructive actions using:

- 🔒 **Sudo elevation only when needed**
- 🛑 **Are you sure?** confirmations
- 📝 **Logged actions** in `~/.myshell.log`
- 📦 **Argument-safe parsing** using `read -a argv`

---


## 📦 Installation

### 1. Clone the repository

    git clone https://github.com/mahinrezvi8943/My-Shell
    cd My-Shell

### 2. Add execution permission

    chmod +x myshell.sh

### 3. Run the shell

    ./myshell.sh

## 📁 Project Structure

    myshell/
    │
    ├── myshell.sh                     # Main shell script
    ├── README.md                      # Documentation


## 🧠 Learning Goals

-   Building a custom CLI shell\
-   Interactive loops & decision-making\
-   Writing safe shell scripts\
-   System-level command wrappers\
-   Package manager detection\
-   Logging & user experience design
  

## 👨‍💻 Author

 ### Syed Mahin Hossain Rezvi
    Batch-231, Section-64_I, Department of CSE, Daffodil International University


## ⭐ Like the project?

    Give it a star ⭐ on GitHub and share with other Linux learners!
