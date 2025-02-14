# myapp-updates


# Developer Guide: Setting Up and Managing Updates

## **Purpose of This Document**
This guide provides step-by-step instructions for developers to:
1. **Set up a GitHub repository** to manage update releases.
2. **Upload the update script (`update_app.sh`) and version files.**
3. **Release new updates** with a structured versioning system.
4. **Guide users on how to download and apply updates.**
5. **Ensure the system reboots after running the update script.**

---

## **Key Requirements**
To successfully implement automatic updates, ensure you have:
- A **GitHub account** and a new repository.
- Basic knowledge of **Git** and **command-line operations**.
- An **application binary** that needs version-controlled updates.
- A **Raspberry Pi or Linux system** where updates will be applied.

---

## **1️⃣ Setting Up a GitHub Repository**

### **Step 1: Create a New Repository**
1. Go to [GitHub](https://github.com/) and sign in.
2. Click on **New Repository**.
3. Name the repository (e.g., `myapp-updates`).
4. Set it as **public** or **private**.
5. Click **Create repository**.

### **Step 2: Clone the Repository Locally**
Run the following command on your local machine:
```sh
cd ~/ 
git clone https://github.com/your-username/myapp-updates.git
cd myapp-updates
```

---

## **2️⃣ Uploading `update_app.sh` and Version Files**

### **Step 1: Create the Version File (`version.json`)**
Inside the repository folder, create a new file:
```sh
nano version.json
```
Add the following content:
```json
{
  "version": "1.0.0",
  "url": "https://github.com/your-username/myapp-updates/releases/download/v1.0.0/myapp.tar.gz"
}
```
Save the file (**CTRL+X, Y, ENTER**).

### **Step 2: Create the `update_app.sh` File**
Run:
```sh
nano update_app.sh
```
Paste the update script inside it (ensure it includes auto-update logic and system reboot). Save and exit.

Make it executable:
```sh
chmod +x update_app.sh
```

### **Step 3: Commit and Push Files to GitHub**
```sh
git add version.json update_app.sh
git commit -m "Added update script and version file"
git push origin main
```

---

## **3️⃣ Creating a Release on GitHub**

### **Step 1: Create a New Release**
1. Go to your GitHub repository.
2. Click **Releases** → **Create a new release**.
3. Tag the version (e.g., `v1.0.0`).
4. Add release notes.
5. Upload your application binary (`myapp.tar.gz`).
6. Click **Publish release**.

### **Step 2: Update `version.json` with the New URL**
Modify `version.json` with the new release URL:
```json
{
  "version": "1.1.0",
  "url": "https://github.com/your-username/myapp-updates/releases/download/v1.1.0/myapp.tar.gz"
}
```
Commit and push changes:
```sh
git add version.json
git commit -m "Updated to version 1.1.0"
git push origin main
```

---

## **4️⃣ Running Commands on the Raspberry Pi**

### **Step 1: Download the Update Script**
Run this command on the Raspberry Pi:
```sh
wget -O /home/pi/update_app.sh https://raw.githubusercontent.com/your-username/myapp-updates/main/update_app.sh && chmod +x /home/pi/update_app.sh
```

### **Step 2: Execute the Script to Apply Updates**
```sh
/home/pi/update_app.sh
```

### **Step 3: Reboot the System**
After the update is complete, the system will automatically reboot. If it does not, manually reboot using:
```sh
sudo reboot
```

---

# **User Guide: Running Configuration Command**

## **Purpose**
This guide is for **end-users** who need to apply software updates on their Raspberry Pi or Linux system.

## **🔹 Running the Command**
To download and configure your system, run this command in the terminal:
```sh
wget -O /home/pi/update_app.sh https://raw.githubusercontent.com/your-username/myapp-updates/main/update_app.sh && chmod +x /home/pi/update_app.sh && /home/pi/update_app.sh
```

## **✅ What This Command Does**
1. **Downloads the update script** from the server.
2. **Makes the script executable.**
3. **Runs the script to configure and apply updates.**
4. **Reboots the system after successful update.**

If the system does not reboot automatically, run:
```sh
sudo reboot
```

---

## **🎯 Summary**
### **For Developers:**
- Set up a GitHub repository.
- Upload `update_app.sh` and `version.json`.
- Release new versions on GitHub.
- Guide users to execute the update command.
- Ensure the system reboots after applying updates.

### **For Users:**
- Run a single command to install and apply updates.
- System will handle configurations automatically.
- The system will reboot after applying updates.

🚀 **Now your update system is fully automated!**
