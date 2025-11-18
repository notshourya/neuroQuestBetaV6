# NeuroQuest

**NeuroQuest** is an underdevelopment iOS application designed for cognitive wellness, helping Parkinson's patients with immersive training games and progress analysis&tracking.

---

## Project Status
This project is currently **in development**. Features are actively being added and refined.

**Note:** This repo showcases the proposed UI/UX design of the app. For information about converting this SwiftUI implementation to programmatic UIKit, see the [Programmatic UI Conversion Documentation](./PROGRAMMATIC_UI_README.md).

> **Recommendation:** The comprehensive analysis in the conversion documentation suggests **keeping the SwiftUI implementation** unless specific requirements emerge. See [CONVERSION_DECISION_GUIDE.md](./CONVERSION_DECISION_GUIDE.md) for details.

---

## Features
- **AR Training Games:** A library of engaging & immersive AR games and activities designed to integrate cognitive tasks with physical movement and real-world interaction (yet added to the app).
- **Progress Tracking:** Visual charts and statistics to monitor progress over time.
- **Daily Dashboard:** A motivating home screen that summarizes daily activity.
- **Admin Panel:** A dedicated interface for caregivers to view comprehensive data and monitor patient engagement.
- **Mindfulness:** A section for wellness activities such as guided breathing and doodling.

---

## Current Technology Stack
- **Language:** Swift  
- **UI Framework:** SwiftUI
- **PencilKit**
- **WebKit**
- **SpriteKit**

---

## How to Run
1. Clone this repository:

   ```bash
   git clone https://github.com/notshourya/neuroQuestBetaV
   
2.  Open the NeuroQuest.xcodeproj file in Xcode.
3.	Select a target simulator.
4.	Press the Run button.

## Test Credentials

To log in to the app for testing, use the following credentials:

- **Email:** Any correctly formatted email (e.g., user@example.com)
- **Password:** password123

---

## 📚 Programmatic UI Conversion Documentation

This repository includes comprehensive documentation for converting from SwiftUI to programmatic UIKit:

### 📖 Documentation Files

1. **[PROGRAMMATIC_UI_README.md](./PROGRAMMATIC_UI_README.md)** - Start here! Overview and navigation guide
2. **[CONVERSION_DECISION_GUIDE.md](./CONVERSION_DECISION_GUIDE.md)** - Should you convert? Pros, cons, and decision framework
3. **[PROGRAMMATIC_UI_CONVERSION_GUIDE.md](./PROGRAMMATIC_UI_CONVERSION_GUIDE.md)** - Complete 8-week conversion strategy
4. **[IMPLEMENTATION_EXAMPLES.md](./IMPLEMENTATION_EXAMPLES.md)** - Production-ready code examples
5. **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** - Fast lookup table for SwiftUI ↔ UIKit conversions

### 🎯 Key Findings

- **Conversion Estimate:** 8 weeks, 320 hours, ~$33,600
- **Code Increase:** ~4.7x more code in UIKit vs SwiftUI
- **Recommendation:** **Keep SwiftUI** unless specific requirements emerge

### 💡 Use Cases for This Documentation

- 📖 Learning resource for UIKit patterns
- 🔍 Reference material for SwiftUI to UIKit conversions
- 📋 Implementation guide if conversion becomes necessary
- 🎓 Educational comparison of declarative vs imperative UI

**Read [PROGRAMMATIC_UI_README.md](./PROGRAMMATIC_UI_README.md) to get started!**
