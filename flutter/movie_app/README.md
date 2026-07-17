# Cinema

> **Your Cinema, Anywhere** — A premium movie streaming Flutter application

## Download
📥 **[Download the latest APK here](https://github.com/Amiry00/IIUC_Industrial_training/releases)**

## Overview

**Cinema** is a premium, cross-platform movie discovery and streaming app built with Flutter. 

It leverages the **TMDb API** for real-time movie data and integrates directly with YouTube for in-app trailer streaming. With a sleek dark theme, local SQLite authentication, and offline watchlist management, Cinema delivers a seamless cinematic experience across mobile and desktop devices.

## Screenshots

| Splash | Login | Register |
|---|---|---|
| <img src="assets/images/splash_screen.jpg" width="250"> | <img src="assets/images/login_screen.jpg" width="250"> | <img src="assets/images/register_screen.jpg" width="250"> |

| Home | Details | Video Player |
|---|---|---|
| <img src="assets/images/home_screen.jpg" width="250"> | <img src="assets/images/movie_detail_screen.jpg" width="250"> | <img src="assets/images/video_player%20screen.jpg" width="250"> |

| Search | Category | Watchlist |
|---|---|---|
| <img src="assets/images/search_screen.jpg" width="250"> | <img src="assets/images/categori_screen.jpg" width="250"> | <img src="assets/images/Watchlist_screen.jpg" width="250"> |

| Profile | Favorites |
|---|---|
| <img src="assets/images/profile_screen.jpg" width="250"> | <img src="assets/images/favorite_screen.jpg" width="250"> |

| Dark Mode | Offline Mode |
|---|---|
| <img src="assets/images/dark_mode.jpg" width="250"> | <img src="assets/images/offline_mode.jpg" width="250"> |

## API Used

**TMDb API v3** — https://api.themoviedb.org/3
- Auth: Free API key  
- Returns: JSON  
- Endpoints: trending, popular, top_rated, now_playing, upcoming, search, movie details, genres, discover

**YouTube Integration**
- Using `youtube_explode_dart` to extract and play trailers directly without requiring the official YouTube API key.

## Features

### Core Features
- User Authentication (Registration & Login via SQLite)
- Home Screen with hero banner and horizontal scrolling sections
- Movie Detail Screen with cast, genres, similar movies, and blurred backdrop
- In-App Video Player for YouTube trailers (via `media_kit`)
- Watchlist Management (Add, Remove via SQLite)
- Debounced Search (500ms) with grid results and pagination
- Infinite Scrolling pagination on all lists
- Share movie functionality
- Error Handling (no internet, API failure, empty/loading states)
- Responsive UI (Mobile, Tablet, Desktop)

### Bonus Features
- Premium Dark Cinematic Theme
- Local Cache with SQLite for offline access
- Dependency Injection (GetIt)
- Scoped State Management (Provider)
- Cross-platform support (Android, iOS, Linux)

## Packages Used

| Package | Purpose |
|---------|---------|
| `dio` | HTTP client |
| `provider` | State management |
| `sqflite` & `sqflite_common_ffi` | Local database & auth |
| `cached_network_image` | Image caching |
| `media_kit` & `media_kit_video` | In-app video player |
| `youtube_explode_dart` | YouTube metadata extraction |
| `share_plus` | Native sharing |
| `url_launcher` | Launch external URLs |
| `flutter_screenutil` | Responsive sizing |
| `get_it` | Dependency injection |
| `connectivity_plus` | Network status |
| `google_fonts` | Poppins typography |
| `shimmer` | Loading effects |

## How to run project

1. **Clone the repository** (if you haven't already).
2. **Get a free TMDb API key** at https://www.themoviedb.org/settings/api
3. **Add the key** in `lib/core/constants/api_constants.dart`
4. **Install dependencies**:
   ```bash
   flutter pub get
   ```
5. **Run the app**:
   ```bash
   flutter run
   ```
6. **Build APK** (Release):
   ```bash
   flutter build apk --release
   ```

## Design

- Theme: Premium dark cinematic
- Colors: Background #0E0E10, Accent #C67A4B
- Font: Poppins (Google Fonts)
- Inspired by Netflix, Apple TV+, HBO Max
