# **Force CPU Performance Core for Gaming**  

![Magisk Module](https://img.shields.io/badge/Magisk-Module-blue?logo=android)  
![MIT License](https://img.shields.io/badge/License-MIT-green)  

This module optimizes CPU scheduling to deliver a smoother and more stable gaming experience on Android devices. By detecting compatible CPU cluster configurations, it ensures your device runs efficiently while focusing on performance for gaming.  

With this module, games will no longer rely on slow CPU cores, preventing bottlenecks that can cause frame drops throughout your gaming session.

Unlike many other gaming modules, this module does not rely on placebo effects; it provides a real and measurable FPS increase (you can check the tested devices and benchmark results near the bottom of the page)

---

## **Features**  
- Supports devices with **4+4 CPU cluster configurations**.  
- Utilizes **Cpuset** for efficient CPU task scheduling.  
- Easy customization of game lists for targeted optimization.  

## **Requirements**  
- **Magisk Manager** version 24.0 or higher required.  
- Android device with a **4+4 CPU cluster configuration**.  
- Kernel support for **Cpuset**.  

---

## **Installation Instructions**  

1. Download the ZIP file from the [latest release](https://github.com/Clourynth/game_cpusets/releases).  
2. Install the module via **Magisk Manager**:  
   - Open Magisk Manager.  
   - Navigate to *Modules > Install from Storage*.  
   - Select the downloaded ZIP file.  
3. Reboot your device.  

## **Adding Games to the List**  

1. After installation, locate the `game_list.txt` file in:  
  ```
  /storage/emulated/0/game_list.txt
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

## Tested on

- **Device:** Redmi Note 5 Pro
- **Processor:** Snapdragon 636
- **Custom ROM:** Derpfest Android 12L

## Benchmark Results

- **Minecraft**: Increased from 30 fps to 45 fps.
- **Squad Busters**: Improved from 40 fps to stable performance at 60 fps.

Note: Both games were downscaled to 0.5x for proper CPU benchmarking, ensuring the performance improvements are clearly noticeable.

---

## **License**  
This project is licensed under the **MIT License**. See [LICENSE](LICENSE) for more details.  

## **Contributions**  
Contributions are welcome! If you have suggestions, bug fixes, or new feature ideas, feel free to submit a **pull request** or report issues in the [Issues](#) section.  

## **Credits**  
- **Magisk:** A powerful systemless interface for Android that allows you to modify your system without altering the system partition.
Magisk GitHub

- **AOSP (Android Open Source Project):** The open-source initiative that forms the foundation of Android.
AOSP GitHub

## **Support the Developer**  
If you find this module helpful, consider supporting its development by donating:  
- **[Buy Me a Coffee](https://buymeacoffee.com/username)**  
