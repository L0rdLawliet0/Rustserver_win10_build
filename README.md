# 🛠️ Rust Server Setup Guide 🛠️

This guide provides step-by-step instructions to set up and run a Rust server using PowerShell and a pre-configured script.

---

## 📋 Prerequisites

1. **👨‍💻 Administrator Access**: You will need administrator privileges on your computer to execute some of the commands in this setup.
2. **📂 Required Files**:
   - `rust-server-carbon.ps1`: The PowerShell script for setting up and configuring the server.
   - `Carbon.Windows.Release.zip`: The Carbon file, used by the server.
   - `miniupnpc.zip`: Contains UPnP utilities required for port mapping.

---

## Step 1: Preparation 🧰

1. **📂 Place all required files in the same folder**:
   - Make sure `rust-server-carbon.ps1`, `Carbon.Windows.Release.zip`, and `miniupnpc.zip` are in the same directory on your computer.

2. **📥 Extract `miniupnpc.zip`**:
   - Right-click on `miniupnpc.zip` and select “Extract All.”
   - Extract it to `C:\miniupnpc`. The extracted folder should contain `upnpc-static.exe`, which the script will use for network configuration.

---

## Step 2: Configuring the Server Script ⚙️

If you want to customize the server’s IP address or directory, you can manually edit the following variables in `rust-server-carbon.ps1`:

- **💻 `$LocalIP`**: Set this to your local IP address (e.g., `192.168.1.115`). If you don’t know your local IP address, you can find it by opening Command Prompt and typing `ipconfig`.
- **📁 `$ServerDir`**: Set this to the path where you want the Rust server files to be installed (e.g., `C:\rust_server`).
- **📄 `$CarbonZipPath`**: Set this to the full path of `Carbon.Windows.Release.zip`.

If you're not comfortable editing these values, the script will use defaults.

---

## Step 3: Run the PowerShell Script 🚀

1. **🔓 Open PowerShell as Administrator**:
   - Right-click on the Start Menu and select **Windows PowerShell (Admin)**. This will open PowerShell with administrator privileges.

2. **📂 Navigate to the Folder**:
   - In PowerShell, navigate to the folder where you placed the `rust-server-carbon.ps1` script. Use the `cd` command to change directories. For example:
     ```powershell
     cd "C:\path\to\your\folder"
     ```

3. **▶️ Temporarily Allow Script Execution**:
   - If you encounter an error about the script not being digitally signed, bypass this restriction temporarily by running:
     ```powershell
     Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
     ```

4. **▶️ Run the Script**:
   - Run the script by typing the following command:
     ```powershell
     .\rust-server-carbon.ps1
     ```
   - This script will do the following:
     - ✅ Check for administrator privileges.
     - 🔗 Set up UPnP port forwarding to allow players to connect to the server.
     - 🛡️ Configure Windows Firewall rules to allow network traffic on the required ports.
     - 📂 Create the Rust server directory.
     - 🛠️ Download and install SteamCMD, a tool for installing dedicated game servers.
     - 🎮 Install the Rust server.
     - 📦 Extract `Carbon.Windows.Release.zip` to the server directory for additional functionalities.
     - 📜 Generate a `start_server.bat` file to start the server with specific configurations.
   - Follow any on-screen prompts. If there are any errors, check if all required files are in place and that PowerShell has the necessary permissions.

---

## Step 4: Start the Server 🕹️

1. **▶️ Run `start_server.bat`**:
   - Once the script completes successfully, navigate to your Rust server directory (default: `C:\rust_server`).
   - Double-click on `start_server.bat` to start your Rust server. This file was created by the script and contains the necessary commands to launch the server with your settings.

2. **✅ Confirm the Server is Running**:
   - A new Command Prompt window should open, showing logs of the server starting up.
   - Look for messages indicating that the server has successfully started. You should see the configured ports (22220 for the game, 22222 for RCON, etc.) and other information.

---

## Step 5: Connecting to Your Server 🌐

1. **🌍 Find Your Public IP Address**:
   - The PowerShell script will display your public IP address at the end of the setup. Alternatively, you can go to [WhatIsMyIP](https://whatismyipaddress.com/) to find it.

2. **🔗 Connect to Your Server**:
   - Launch Rust on your computer.
   - Open the game console (press `F1` in Rust) and type the following command to connect:
     ```
     client.connect [Your Public IP Address]:22220
     ```
     Replace `[Your Public IP Address]` with the IP address you obtained in the previous step.

---

## 🛠️ Troubleshooting

If you encounter issues, here are some common troubleshooting tips:

- **🚪 Ports Not Open**:
   - Ensure that UPnP is enabled on your router. The PowerShell script uses UPnP to open ports automatically.
   - You may need to log into your router and manually forward the ports (22220 for the game, 22222 for RCON, 27015 for Steam, and 22288 for Rust+) if UPnP is not working.

- **🛡️ Firewall Blocking Connection**:
   - Check that Windows Firewall or any third-party firewall is not blocking Rust’s network traffic. The PowerShell script should add firewall rules, but you may need to verify them in Windows Firewall settings.

- **🔄 Server Not Responding**:
   - Double-check that `rust-server-carbon.ps1` is configured correctly and that all paths are accurate.
   - Ensure all required files are present, especially `Carbon.Windows.Release.zip` and `miniupnpc.zip`.

---

This guide provides all the necessary steps for setting up and running a Rust server on Windows. If you have additional questions or encounter specific issues, refer to the Troubleshooting section or reach out for support.

---

Happy hosting! 🎉
