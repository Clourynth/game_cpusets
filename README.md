# **Force CPU Performance Core for Gaming**  

![Magisk Module](https://img.shields.io/badge/Magisk-Module-blue?logo=android)  
![MIT License](https://img.shields.io/badge/License-MIT-green)  

This module optimizes CPU scheduling to deliver a smoother and more stable gaming experience on Android devices. By detecting compatible CPU cluster configurations, it ensures your device runs efficiently while focusing on performance for gaming.  

With this module, games will no longer rely on slow CPU cores, preventing bottlenecks that can cause frame drops throughout your gaming session.

---

## **Features**  
- Supports devices with **4+4 CPU cluster configurations**.  
- Utilizes **Cpuset** for efficient CPU task scheduling.  
- Easy customization of game lists for targeted optimization.  
- Non-intrusive Magisk-based module that doesn’t modify system partitions.  

---

## **Requirements**  
- **Magisk Manager** (latest version recommended).  
- Android device with a **4+4 CPU cluster configuration**.  
- Kernel support for **Cpuset**.  

---

## **Installation Instructions**  

1. Download the ZIP file from the [latest release](#).  
2. Install the module via **Magisk Manager**:  
   - Open Magisk Manager.  
   - Navigate to *Modules > Install from Storage*.  
   - Select the downloaded ZIP file.  
3. Reboot your device.  

---

## **Adding Games to the List**  

1. After installation, locate the `game_list.txt` file in:  
  ```
  /storage/emulated/0/config/game_list.txt
  ```
2. Add the **package IDs** of the games you want to optimize, one per line.  
- Example:  
  ```
  com.miHoYo.GenshinImpact
  com.tencent.ig
  com.supercell.clashofclans
  ```  
3. Save the file and reboot your device to apply the changes.  

---

## **Notes**  
- This module only works with devices using a **4+4 CPU cluster configuration**.  
- This module works only on devices/kernel with **Cpuset** supported'
- Installation will fail if your device uses a different configuration.  

---

## **License**  
This project is licensed under the **MIT License**. See [LICENSE](LICENSE) for more details.  

---

## **Contributions**  
Contributions are welcome! If you have suggestions, bug fixes, or new feature ideas, feel free to submit a **pull request** or report issues in the [Issues](#) section.  

---

## **Credits**  
- **Developer:** Clourynth  
- **Inspiration & Resources:** Open Source Community  

---

## **Support the Developer**  
If you find this module helpful, consider supporting its development by donating:  
- **[Buy Me a Coffee](https://buymeacoffee.com/username)**  
