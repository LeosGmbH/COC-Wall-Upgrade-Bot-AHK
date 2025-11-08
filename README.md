# 🛡️ COC Wall Upgrade Bot (AutoHotkey)

An automation script for Clash of Clans (COC) designed to streamline and automate the **Wall Upgrade process** by farming resources and subsequently spending them directly on wall upgrades as long as they are available.

---

## ⚙️ How It Works

The script operates in a continuous, automated loop, designed to run until manually interrupted or an error occurs.

### 1. Initialization & Start Condition

The script does **not** start immediately upon launch. It is designed to wait for the appearance of the "Back to Home" button, which signifies the end of an attack.

* **Initial Requirement:** The user must manually start one Clash of Clans attack (and either finish it or surrender) to trigger the initial "Back to Home" button.
* **Loop Start:** The script constantly searches for the **`popup.png`** (the "Back to Home" button). Once found, it clicks the button, waits briefly for the village to load, and the main automated loop begins.

### 2. Main Automated Cycle

The core automation combines two phases:

#### 2.1 Attack Cycle (Farming)

* The script executes the separate macro **`Angriff.exe`** (your custom attack recording) consecutively a set number of times (currently configured for **10 runs**) to gather Gold and Elixir.
* After each run, it waits for the **`popup.png`** to reappear and clicks it to return to the village before launching the next attack.

#### 2.2 Upgrade Cycle (Spending)

After the Attack Cycle completes and the script is back in the village, it initiates the spending phase:

* **Find Builder:** Searches for a **free Builder** and clicks on it.
* **Find Wall:** Scrolls down and searches for a Wall that can be upgraded.
* **Check Resources & Upgrade (Crucial Step):** Searches for the **Upgrade Button** image.
    * The PNG screenshots in the `gold/` and `elexier/` folders must show the button with **white text/resource cost**. This signifies **sufficient resources are available**.
    * If the button text is red (insufficient resources), the required image is not found, the upgrade loop terminates, and the script switches back to the Attack Cycle.
    * If the white-text image is found, the upgrade is confirmed and executed.
* **Repeat:** This upgrade sequence (Find Builder, Find Wall, Upgrade) repeats until the resource check fails (i.e., no more Gold/Elixir is available).

The script then automatically returns to the **Attack Cycle** to farm more resources.

---

## 📸 Image Setup and Logic

For the script to function correctly, precise image recognition is required. The dedicated folders must contain screenshots matching the desired game state.

| Folder | Target Image | Key Functionality |
| :--- | :--- | :--- |
| **`popup/`** | The "Back to Home" button. | **Initializes the script and resets the loop after every attack.** |
| **`builder/`** | The "Free Builder" icon. | Finds a Builder to begin the upgrade process. |
| **`mauer/`** | An upgradable Wall tile. | Finds the object to be upgraded (includes scrolling). |
| **`gold/` / `elexier/`** | The "Upgrade" button showing **WHITE text**. | **Crucial:** Confirms that sufficient resources are available for the upgrade. (Red button text will cause the ImageSearch to fail.) |

---

## ⚠️ Important Notes & Prerequisites

**This is an automation script, and its use may violate Supercell's Terms of Service.** Use is at your **own risk** and responsibility.

### Prerequisites

1.  **Game Platform:** The script is specifically designed for **Clash of Clans (COC) running through Google Play Games for PC**.
    * It targets the window handle **`ahk_class CROSVM_1 ahk_exe crosvm.exe`**, which is the default name used by Google Play Games for the COC window.
    * If you experience issues, you may need to confirm this window title is correct on your system and adjust the `TargetWin` variable in the code.
2.  **AutoHotkey:** The main script file (`COC-Wall-Upgrade-Bot.ahk`) requires **AutoHotkey v1** to run.
3.  **Graphics (PNGs):** The folders **`builder/`, `mauer/`, `gold/`, `elexier/`, `popup/`** must be present in the script's root directory and contain the corresponding `.png` images used for precise object recognition (ImageSearch).
4.  **Attack Macro:** The file **`Angriff.exe`** (your custom attack recording) must be in the same directory.
---

### 1. Clone the Repository

```bash
git clone [https://github.com/YOUR-GITHUB-NAME/COC-Wall-Upgrade-Bot-AHK.git](https://github.com/YOUR-GITHUB-NAME/COC-Wall-Upgrade-Bot-AHK.git)
cd COC-Wall-Upgrade-Bot-AHK
