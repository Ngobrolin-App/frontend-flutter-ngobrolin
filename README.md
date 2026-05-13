# 💬 NGOBROLIN – REAL-TIME CHAT APPLICATION

**Ngobrolin** adalah aplikasi **mobile real-time chat** yang memungkinkan pengguna untuk berkomunikasi secara langsung melalui pesan pribadi.

Aplikasi ini dibangun menggunakan **Flutter** pada sisi mobile dan **Node.js (Express.js)** pada sisi backend dengan **PostgreSQL** sebagai database. Sistem komunikasi real-time diimplementasikan menggunakan **WebSocket melalui Socket.io**, sehingga pesan dapat dikirim dan diterima secara instan antar pengguna.

Selain itu, proses deployment backend telah diotomatisasi menggunakan **Jenkins CI/CD Pipeline** yang terintegrasi dengan **GitHub Webhook**, sehingga setiap perubahan pada repository dapat langsung memicu proses deployment secara otomatis ke server.

---

## 👨‍💻 Maintainer

Project ini dikembangkan oleh:

**Yudha Haryoputranto**  
GitHub: https://github.com/yudhah52

---

## ✨ FITUR UTAMA

### 🔐 User Authentication

- Registrasi dan login pengguna
- Manajemen akun pengguna secara aman
- Password disimpan menggunakan **Bcrypt hashing**

### 💬 Real-time Messaging

- Pengiriman pesan secara **instan**
- Komunikasi **real-time menggunakan WebSocket (Socket.io)**
- Sinkronisasi pesan antar pengguna

### 🔔 Notification System

- Notifikasi pesan masuk menggunakan **Firebase Cloud Messaging (FCM)**
- Pengguna tetap menerima notifikasi meskipun aplikasi sedang tidak aktif

### 👥 User Interaction

- **Private chat** antar pengguna
- **User search** untuk menemukan pengguna lain
- **Private account settings**
- **Blocked user management**
- **Language settings (Indonesia / English)**

### 🚀 CI/CD & Deployment

- Automated backend deployment menggunakan **Jenkins Pipeline**
- Integrasi **GitHub Webhook** untuk trigger deployment otomatis setelah push
- Deployment backend langsung ke VPS/server secara otomatis
- Workflow deployment untuk mempermudah maintenance dan update aplikasi

---

## 🧱 TECH STACK

| Layer / Komponen            | Teknologi yang Digunakan |
|----------------------------|--------------------------|
| **Mobile Application**     | Flutter |
| **Arsitektur Aplikasi**    | MVVM (Model–View–ViewModel) |
| **State Management**       | Provider |
| **Backend API**            | Node.js, Express.js |
| **Realtime Communication** | WebSocket (Socket.io) |
| **Database**               | PostgreSQL |
| **Push Notification**      | Firebase Cloud Messaging |
| **CI/CD & Deployment**     | Jenkins Pipeline, GitHub Webhook |
| **Version Control**        | Git & GitHub |

---

## ⚙️ SYSTEM ARCHITECTURE

Sistem **Ngobrolin** menggunakan arsitektur full-stack yang terdiri dari beberapa komponen utama:

```text
Mobile Application
Flutter + Provider
⬇
Realtime Communication
WebSocket (Socket.io)
⬇
Backend API
Node.js + Express.js
⬇
Database
PostgreSQL
⬇
Notification Service
Firebase Cloud Messaging (FCM)
```

### 🔄 Deployment Workflow

```text
Developer Push Code
⬇
GitHub Repository
⬇
GitHub Webhook
⬇
Jenkins Pipeline
⬇
Automatic Backend Deployment
⬇
VPS / Production Server
```

Arsitektur ini memungkinkan komunikasi pesan secara **real-time**, pengelolaan data pengguna, serta proses deployment backend yang lebih **otomatis, efisien, dan scalable**.

---

## 👨‍💻 MY CONTRIBUTIONS

Pada proyek ini saya bertanggung jawab untuk:

- Merancang dan mengembangkan aplikasi **Ngobrolin** sebagai **real-time chat application** menggunakan **Flutter** dan **Node.js**.
- Mengimplementasikan **WebSocket (Socket.io)** untuk komunikasi pesan secara real-time.
- Mengintegrasikan **Firebase Cloud Messaging (FCM)** untuk sistem notifikasi pesan.
- Mengimplementasikan **Bcrypt hashing** untuk keamanan autentikasi pengguna.
- Mengembangkan berbagai fitur utama seperti **private chat, user search, private account, blocked user, dan pengaturan bahasa (ID/EN)**.
- Mendesain serta mengembangkan **relational database schema** menggunakan **PostgreSQL**.
- Mengimplementasikan proses **CI/CD backend deployment** menggunakan **Jenkins Pipeline** dan **GitHub Webhook**.
- Mengelola deployment backend ke server/VPS agar proses update aplikasi dapat berjalan otomatis.

---

## 📄 DOKUMENTASI

Dokumentasi tambahan mengenai desain antarmuka dapat dilihat pada tautan berikut:

### Figma UI Design
https://www.figma.com/design/dslLxMk9eGFG3uv0J60n8R/Ngobrolin?node-id=0-1&t=8zEPpILNlElecNqd-1

---

## 🔗 REPOSITORY

Source code proyek dapat dilihat pada repository berikut:

### GitHub Repository
https://github.com/Ngobrolin-App
