# 🛡️ LUKZINT — OSINT Social Analyzer & Cyber-Intelligence Platform

<div align="center">

[![Release](https://img.shields.io/badge/Release-v1.0.0-00F2FE?style=for-the-badge&logo=android&logoColor=black)](https://github.com/lukgutierrez/lukzint-osint)
[![Tests](https://img.shields.io/badge/Tests-48%2F48%20Passed-00E676?style=for-the-badge&logo=checkmarx&logoColor=white)](https://github.com/lukgutierrez/lukzint-osint)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20%26%20DDD-6C5CE7?style=for-the-badge&logo=flutter&logoColor=white)](https://github.com/lukgutierrez/lukzint-osint)
[![Static Analysis](https://img.shields.io/badge/Linter-0%20Issues-0984E3?style=for-the-badge&logo=dart&logoColor=white)](https://github.com/lukgutierrez/lukzint-osint)
[![License](https://img.shields.io/badge/License-MIT-FDCB6E?style=for-the-badge)](LICENSE)

**An enterprise-grade, offline-first Open Source Intelligence (OSINT) and Social Network Analysis platform built with Flutter & Dart.**  
Engineered for digital forensic examiners, cyber threat intelligence (CTI) analysts, and investigative researchers to discover, correlate, and generate court-ready intelligence dossiers with multi-provider AI failover resiliency.

Developed by **Luciano Gutierrez** ([@lukgtz](https://github.com/lukgutierrez)) — *Software Engineer & OSINT Researcher*.

[📥 Download APK (v1.0.0)](#-download--installation) • [🏛️ Architecture](#-software-architecture--engineering-design) • [🧠 AI Engine](#-multi-provider-ai-failover-engine) • [💼 Use Cases](#-real-world-use-cases) • [🧪 Testing](#-testing--quality-assurance) • [📬 Contact](#-author--contact)

</div>

---

## 📱 Visual Overview

<div align="center">
  <table>
    <tr>
      <td align="center"><b>Investigation Command Center</b></td>
      <td align="center"><b>AI-Assisted Intelligence Extraction</b></td>
      <td align="center"><b>Court-Ready Forensic PDF Report</b></td>
    </tr>
    <tr>
      <td><img src="./assets/detail_preview.png" width="280" alt="Investigation Detail View"/></td>
      <td><img src="./assets/ai_preview.png" width="280" alt="AI Analysis Engine"/></td>
      <td><img src="./assets/report_preview.png" width="280" alt="PDF Report Export"/></td>
    </tr>
  </table>
</div>

---

## 📥 Download & Installation

### Option 1: Direct Android APK (Release v1.0.0)
You can directly test and install the production APK on any Android device:

1. **Download the APK:** Download [`releases/lukzint-v1.0.0.apk`](https://github.com/lukgutierrez/lukzint-osint/raw/main/releases/lukzint-v1.0.0.apk) from this repository.
2. **Transfer / Open on Android:** Open the `.apk` file on your Android smartphone or tablet.
3. **Allow Installation:** Enable *"Install from Unknown Sources"* in your security settings when prompted.
4. **Launch:** Enjoy the native offline-first OSINT workspace with the custom cyber-intelligence launcher icon and animated splash screen.

### Option 2: Build from Source
```bash
# Clone repository
git clone https://github.com/lukgutierrez/lukzint-osint.git
cd lukzint-osint

# Install dependencies
flutter pub get

# Run static analysis and automated test suite
flutter analyze
flutter test

# Run on your connected device or desktop
flutter run
```

---

## 🎯 Executive Summary & Mission

Modern cyber investigations and OSINT workflows often suffer from fragmented notes, ephemeral social links, unverified data dumps, and fragile evidence preservation.

**LUKZINT** solves this by enforcing a strict **Digital Chain of Custody**:
* **Every Finding is Immutable & Traceable:** Every insight is cryptographically tied to its originating URL/Source.
* **100% Offline-First Privacy:** Investigations and entity graphs are persisted locally on-device in structured JSON stores—no third-party cloud data harvesting.
* **Passive & Non-Intrusive Intelligence:** Operates strictly over publicly available records, open endpoints, and authorized metadata.

---

## 🏛️ Software Architecture & Engineering Design

LUKZINT is designed following **Clean Architecture** and **Domain-Driven Design (DDD)** principles to guarantee testability, maintainability, and total independence from UI frameworks and external API providers.

```mermaid
flowchart TD
    subgraph Presentation_Layer["Presentation Layer (Flutter / UI)"]
        UI_Screens["Screens\n(Dashboard, Detail, SocialAI, Settings)"]
        UI_Controllers["Controllers (ChangeNotifier)\nState Management & UI Logic"]
        UI_Widgets["Custom Widgets\n(Graph View, Dialogs, Cards)"]
    end

    subgraph Domain_Layer["Domain Layer (Pure Business Logic)"]
        UC["Use Cases\n(AnalyzeUrl, GeneratePdfReport, ManageInvestigations)"]
        Entities["Core Entities\n(Investigation, TargetProfile, Finding, Source)"]
        RepoContracts["Repository Contracts\n(IInvestigationRepository, IAnalysisRepository)"]
    end

    subgraph Data_Layer["Data Layer (Infrastructure & Repositories)"]
        RepoImpl["Repository Implementations\n(InvestigationRepositoryImpl, AnalysisRepositoryImpl)"]
        DTOs["Data Models & JSON Mappers\n(Round-trip DTO serialization)"]
        subgraph Datasources["Datasources"]
            GH_DS["GitHub API Datasource"]
            Scraper_DS["Web Metadata Scraper"]
            AI_Failover["FailoverAiDatasource\n(Gemini, Groq, OpenRouter, Mistral)"]
            JSON_Storage["Offline JSON Storage Engine"]
        end
    end

    subgraph Core_Layer["Core Layer (Cross-Cutting Concerns)"]
        HTTP_Client["Resilient HTTP Client"]
        Crypto_Utils["Base64 & Image Parsers"]
        Theme_Branding["Theme & App Branding"]
        Error_Handling["OSINT Domain Exceptions"]
    end

    UI_Screens --> UI_Controllers
    UI_Controllers --> UC
    UC --> Entities
    UC --> RepoContracts
    RepoImpl -.->|Implements| RepoContracts
    RepoImpl --> DTOs
    RepoImpl --> Datasources
    Datasources --> Core_Layer
```

### Architectural Principles Applied:
1. **Separation of Concerns:** Zero business logic in widgets; all mutations pass through granular Use Cases.
2. **Dependency Inversion Principle (DIP):** Domain layer defines interfaces; Data layer fulfills them.
3. **Fail-Safe Redundancy:** Automatic multi-provider LLM cascade ensuring continuous intelligence extraction even during rate-limits or outages.
4. **Supply Chain Security:** Zero bloat—relies on native Dart/Flutter core capabilities with minimal trusted dependencies.

---

## 🧠 Multi-Provider AI Failover Engine

LUKZINT features an enterprise-grade AI extraction pipeline with **automatic cascading failover**:

```mermaid
sequenceDiagram
    autonumber
    actor Analyst as CTI / OSINT Analyst
    participant App as LUKZINT Controller
    participant Engine as FailoverAiDatasource
    participant P1 as Primary LLM (e.g. Gemini 2.5)
    participant P2 as Secondary LLM (e.g. Groq Llama 3)
    participant P3 as Tertiary LLM (OpenRouter / Mistral)

    Analyst->>App: Submits Public Target Text / Bio
    App->>Engine: extractFindings(text, targetInfo)
    Engine->>P1: Request JSON Extraction
    alt Primary Provider Succeeds
        P1-->>Engine: Structured Findings (JSON)
    else Rate Limited / Network Failure (HTTP 429 / 5xx)
        Engine->>Engine: Log Failure & Trigger Failover
        Engine->>P2: Fallback Request
        alt Secondary Provider Succeeds
            P2-->>Engine: Structured Findings (JSON)
        else Secondary Fails
            Engine->>P3: Tertiary Fallback Request
            P3-->>Engine: Structured Findings (JSON)
        end
    end
    Engine->>App: Normalized Finding Entities + Metadata
    App->>Analyst: Display Categorized Findings with Confidence Levels
```

---

## 💼 Real-World Use Cases

### 1. Cyber Threat Intelligence (CTI) & Threat Actor Profiling
* **Scenario:** Profiling suspected threat actors or exposed contributor footprints.
* **Capabilities:** Automated extraction of developer emails from commit history, identification of leaked repository secrets, and mapping of pseudonym aliases across online handles.

### 2. Executive Exposure & Due Diligence (Anti-Spear Phishing)
* **Scenario:** Assessing C-level digital footprints to mitigate targeted social engineering and business email compromise (BEC).
* **Capabilities:** Auditing publicly indexed personal emails, affiliations, family mentions, and technical routines.

### 3. Digital Forensics & Law Enforcement Support
* **Scenario:** Gathering public open-source corroborating evidence for judicial filings.
* **Capabilities:** Exporting standardized forensic PDF reports containing exact timestamped source URLs, evidentiary quotes, and relationship mapping with zero manual editing errors.

---

## 🔍 Core Feature Matrix

| Module | Technical Capability | Forensic Value |
| :--- | :--- | :--- |
| **Dossier Management** | Multi-case tracking with state machines (`Draft`, `In Progress`, `Completed`). | Enforces audit trails with creation and last-modified metadata. |
| **Target Profiling** | Full identity indexing (Aliases, IDs, Locations, Roles, Local Base64 Avatar). | Centralized target nexus for multi-source correlation. |
| **GitHub Intelligence** | Direct REST integration extracting repos, bio, company, location, and social links. | Passive technical fingerprinting without authentication tokens required. |
| **Web Metadata Harvester** | OpenGraph, schema tags, headers, and semantic text extraction. | Fast triage of corporate websites, portfolio pages, and public blogs. |
| **AI Extraction Engine** | Structured NLP parser with strict JSON protocol & confidence scoring (`Low`, `Medium`, `High`). | Converts unstructured OSINT text dumps into actionable categorized findings. |
| **Multi-Tier Relationship Graph**| Multigenerational link classification (`Parents`, `Spouses`, `Colleagues`, `Children`). | Maps social exposure vectors and intermediary link nodes. |
| **Forensic PDF Generator** | Automated vector PDF layout with clickable sources and evidence blocks. | Immediate executive and courtroom deliverable generation. |
| **Local Encrypted Storage** | Isolated sandbox filesystem storage utilizing `path_provider`. | Zero cloud exposure; data remains strictly confidential on analyst hardware. |

---

## 🧪 Testing & Quality Assurance

LUKZINT is built with a **Test-Driven & Quality-First mindset**. Every layer has automated verification:

```bash
# Execute test suite
flutter test

# Run static linter
flutter analyze
```

### Coverage Highlights:
* **Unit Tests:** Serialization round-trips for all Domain and Data models (`FindingModel`, `SourceModel`, `TargetProfileModel`, `InvestigationModel`).
* **Resilience Tests:** Verified AI failover switching when primary API keys fail or return malformed outputs.
* **PDF Verification:** Generation validated across empty dossiers, partial profiles, and large base64 avatar graphs.
* **Responsive UI Verification:** Tested across compact mobile viewports (320px) to ultra-wide desktop monitors without RenderFlex overflow.

---

## ⚖️ Legal, Ethical & Compliance Framework

LUKZINT is engineered strictly for **defensive cyber-intelligence, authorized due diligence, and lawful research**:

* **Passive Reconnaissance Only:** No port scanning, brute-forcing, credential stuffing, or vulnerability exploitation modules.
* **No Authentication Bypass:** Strictly queries publicly accessible endpoints and user-supplied data.
* **Ethical Scraping:** Complies with HTTP best practices and respect for remote endpoint rate limits.
* **Compliance Ready:** Designed to assist organizations adhering to GDPR, CCPA, and international data governance frameworks.

---

## 🗺️ Project Roadmap

- [x] **v1.0.0 Core Platform:** Complete dossier management, GitHub API, Web Scraper, AI Failover Engine, PDF Export, and Android Release.
- [ ] **Interactive HTML Reports:** Self-contained, offline interactive HTML report exports.
- [ ] **Dynamic Graph Visualizer:** Real-time force-directed node graph for visual link exploration.
- [ ] **Wayback Machine Integration:** Automated archival checks via Internet Archive API for dead links.
- [ ] **Local AES-256 Database Encryption:** At-rest encryption for sensitive investigation files.
- [ ] **Exportable Cryptographic Bundles:** Signed `.lukzint` archive packages for secure peer-to-peer analyst exchange.

---

## 👨‍💻 Author & Contact

<div align="center">

### **Luciano Gutierrez**
*Software Engineer & OSINT Researcher*  
Handle: **`@lukgtz`**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/lucianogutierrezlgtz/)
[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/lukgutierrez/lukzint-osint)
[![Email](https://img.shields.io/badge/Gmail-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:lucianogutierrezlgtz@gmail.com)

</div>

---

<div align="center">
  <sub>Built with engineering precision and dedication to ethical cyber intelligence.</sub>
</div>
