![Windows](https://img.shields.io/badge/OS-Windows-blue?logo=windows) 
![Linux](https://img.shields.io/badge/OS-Linux-yellow?logo=linux)
![macOS](https://img.shields.io/badge/OS-macOS-black?logo=apple)

# DelphiWebDriver

A **modern and lightweight W3C WebDriver client for Delphi**, written from scratch and fully cross-platform.
DelphiWebDriver provides a pure Delphi implementation of the official **W3C WebDriver protocol**, allowing you to automate browsers without Selenium, external dependencies, or .NET bindings.

---

## 📦 Installation

Simply include the `DelphiWebDriver` folder in your Delphi project.
No external libraries required.

---

## 📖 Tutorial

Learn how to get started with DelphiWebDriver in these detailed articles:

- [DelphiWebDriver: The Most Powerful Delphi Library for Browser Automation](https://medium.com/@DA213/delphiwebdriver-the-most-powerful-delphi-library-for-browser-automation-b217e9106acc?postPublishedType=initial)  
- [Automating OCR with DelphiWebDriver: From Screenshot to Text](https://medium.com/@DA213/automating-ocr-with-delphiwebdriver-from-screenshot-to-text-cc74ab84e07c)

More tutorials and guides will be added here soon.

---

## 💬 Support the Project

If you find DelphiWebDriver useful, consider supporting its development ❤️

**PayPal:**  
[![Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif)](https://www.paypal.com/ncp/payment/Q4KSUE7D7SU9N)

**Bitcoin:**  
**Address:** `14r9rqFf5rCW3HMLzT55FAzPVD6vdUDMDs`

<img src="data:image/png;base64,data:image/png;base64,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" width="220">

---

### 🔹 Why DelphiWebDriver?

* Fully cross-platform: Windows, Linux, macOS  
* Pure Delphi implementation: no external dependencies  
* Automates all major browsers: Chrome, Firefox, Edge, Opera, Brave  
* Low-level command access & high-level convenience API  
* Lightweight, modern, and easy to integrate  
