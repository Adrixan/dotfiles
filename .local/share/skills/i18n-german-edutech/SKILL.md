---
name: i18n-german-edutech
description: >-
  Design, organize, and validate German language educational content, DaZ (Deutsch als Zweitsprache)
  exercises, Austrian school curriculum standards (BIST, Lehrplan AHS/VS/Digitale Grundbildung),
  and i18next multilingual setups. Use when developing educational games, vocabulary trainers, or school web applications.
---

# German EduTech & DaZ Curriculum Skill

This skill guides the design, structure, and localization of educational learning apps, Austrian curriculum-aligned exercises, and DaZ trainers.

## 1. Austrian Curriculum & Pedagogical Conventions

- **Volksschule & DaZ (USB-DaZ)**: Focus on Sprachförderung, Grundwortschatz, article training (der/die/das with standardized color codes: blue/red/green), noun plural forms, and audio-visual reinforcement.
- **Digitale Grundbildung (DIGGB) & Informatik (AHS)**: Modular competency-oriented structure (Orientierung, Information, Kommunikation, Produktion, Mediengestaltung, Computational Thinking).
- **Gamification & Engagement**: Instant visual feedback, rewarding streaks, non-punitive retry mechanisms, and audio pronunciation aids.

## 2. i18next Project Structure

For React/Vite educational apps:
- Organize translation namespaces logically:
  - `common.json`: UI controls, buttons, generic labels.
  - `curriculum.json`: Topics, modules, exercise descriptions.
  - `feedback.json`: Praise messages, motivational hints, error explanations.
- Ensure interpolation and pluralization rules comply with German grammar:
  - `key_zero`, `key_one`, `key_other`.
- Maintain clean fallback structures (`fallbackLng: 'de'`).

## 3. Audio & Asset Management
- Standardize audio naming schemes (`[topic]_[word_id]_[lang].mp3`).
- Lazy-load audio sprites or IndexedDB blob caches for offline training apps.
- Provide accessible text alternatives (captions / subtitles) alongside all audio cues.
