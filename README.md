# Zovetica

**Smart Healthcare for Your Beloved Pets**

Zovetica is a comprehensive pet healthcare application designed to connect pet owners with qualified veterinarians, manage pet health records, and foster a community of pet lovers.

## 🚀 Features

-   **Appointment Booking:** Schedule visits with verified vets.
-   **Health Tracking:** Manage pet profiles, vaccinations, and medication reminders.
-   **Community Forum:** Share tips and stories with other pet owners.
-   **Real-time Chat:** Communicate with friends and doctors.
-   **Emergency Guide:** Offline-first first aid instructions for urgent situations.

## 🛠️ Tech Stack

-   **Frontend:** Flutter (Mobile - Android/iOS)
-   **Backend:** Supabase (Auth, Database, Storage)
-   **State Management:** `setState` / `StreamBuilder` (native)

## 📦 Getting Started

### Prerequisites

-   Flutter SDK (3.0+)
-   Supabase Account

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/zovetica.git
    cd zovetica
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Environment Setup:**
    Create a `.env` file in the root directory and add your Supabase credentials:
    ```env
    SUPABASE_URL=your_supabase_url
    SUPABASE_ANON_KEY=your_supabase_anon_key
    ```

4.  **Run the app:**
    ```bash
    flutter run
    ```

## 🧪 Testing

Run unit and widget tests:

```bash
flutter test
```

## 📄 Documentation

See [srs.md](srs.md) for detailed Software Requirements Specifications.
