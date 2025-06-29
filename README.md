 # BedrockServerTermux (Android - Termux & Ubuntu)

 ## Prerequisites  
 -   *Termux* app installed (from F-Droid recommended)  
 -   Stable internet connection 
 -   Basic understanding of Termux commands   

 ---

 ## Step 1: Install Ubuntu in Termux  
1 . Open  *Termux* and run the following commands:  
```bash  
apt update -y  
apt upgrade -y  
apt install wget -y  
wget https://raw.githubusercontent.com/debojitsantra/BedrockServerTermux/refs/heads/main/setup_ubuntu.sh  
bash setup_ubuntu.sh  
  
```
2 . After installation completes, type the following command to log in to Ubuntu:  
```bash  
proot-distro login ubuntu  
  ```

 ---

 ## Step 2: Download and Setup Environment & Minecraft Server  
1 . Inside the  *Ubuntu* session, run these commands:  
```bash  
apt update -y
apt upgrade -y
apt install wget -y  
wget https://raw.githubusercontent.com/debojitsantra/BedrockServerTermux/refs/heads/main/setup_env.sh  
bash setup_env.sh

  ```

2 . This will:  
 - Install necessary packages like  **Box64**,  **Playit**, and  **Git**.  
 - Download and unzip the  **Minecraft Bedrock server** files.  

 ---

 ## Step 3: Running the Minecraft Server  
1 . Open  **two Termux sessions**.  

2 . In  **both sessions**, log in to Ubuntu by running:  
```bash  
proot-distro login ubuntu  
  ```

3 . In the  **first session**, run the following to start the server:  
```bash  
cd /root  
./run  
```  

4 . In the  **second session**, run:  
```bash  
playit  
```  
## Update
- Run this in the root directory of Ubuntu.
```bash
rm server.zip

wget https://github.com/debojitsantra/BedrockServerTermux/releases/download/v3.0/server.zip
unzip -o server.zip -d /Xboyes
```
 ---

 ## Step 4: Connecting Your Server to the World  
1 . After running  **playit**, you'll see a link.  

2 . Copy that link, open it in your browser, and follow the instructions on  **playit.gg** to configure your server.  

 ---

 ## Tips and Troubleshooting  
✅ Make sure you're inside the /root directory before running ./run.  
✅ If any script shows an error, try running apt update first.  
✅ For stability, avoid closing Termux sessions once the server is running.
