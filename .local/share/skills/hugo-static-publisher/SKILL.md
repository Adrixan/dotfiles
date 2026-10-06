---
name: hugo-static-publisher
description: >-
  Manage, build, and optimize Hugo static sites (themes, archetypes, shortcodes, taxonomies,
  multilingual configurations, asset pipelines, and RSS feeds). Use when creating content,
  maintaining themes, or debugging builds for school portals and static websites like petersgasse.at.
---

# Hugo Static Publisher Skill

This skill provides operational workflows for managing, building, and deploying Hugo static websites (specifically school websites like `petersgasse.at`).

## 1. Directory Structure Conventions

- `archetypes/`: Frontmatter templates for new articles, announcements, and events.
- `content/`: Markdown articles organized by section (e.g., `aktuelles/`, `projekte/`, `schule/`).
- `layouts/` or `themes/`: HTML templates and partials.
- `static/`: Unprocessed static assets (PDFs, downloadable forms, raw images).
- `assets/`: Processed assets via Hugo Pipes (Sass/SCSS, bundled JS, image fingerprinting).

## 2. Common Workflows

### A. Creating New Content
- Run: `hugo new content/<section>/<title-slug>.md`
- Verify frontmatter:
  - `title`, `date`, `draft: false`
  - `tags`, `categories`
  - `featured_image` (if applicable)

### B. Building & Local Testing
- Start local server with draft rendering: `hugo server -D --disableFastRender`
- Production build: `hugo --minify --gc`
- Clean destination directory before production builds to eliminate orphaned files.

## 3. Performance & Asset Best Practices
- Use Hugo image processing (`.Resize`, `.Fill`, `.Process "webp"`) for high-resolution school photos.
- Ensure strict HTML validation and accessibility (alt tags on all school event imagery).
