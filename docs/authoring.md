# Authoring guide

This template lets several authors contribute content without touching the site
layout or the shared files. Everything an author writes lives in their own
folder, and the plugins mirror it into the site at build time.

## Who writes what

| Who | Where |
| --- | --- |
| Authors | `authors-src/<author>/` |
| Site owner | category pages at the site root (`author.md`, `guides.md`, ...), `index.html`, `about.md`, `_config.yml`, `docs/` |

## Author folder anatomy

```
authors-src/alice/
├── author.md                  # profile page, categories: [author]
├── _includes/note.html        # partials for {% include_author %}
├── _posts/
│   ├── 2025-01-15-hello.md    # dated post filename
│   └── using-this-template.md # undated: the plugin adds the date prefix
├── _drafts/work-in-progress.md
├── guides/getting-started.md  # page that joins the guides category
└── sandbox.md                 # uncategorized page
```

`authors-src` is the default; change it with `authors.source` in `_config.yml`.
Folder names become part of the site (`_includes/<author>/`), so prefer short
ASCII slugs.

## Mapping rules

| Source file under `authors-src/<author>/` | Published as |
| --- | --- |
| page with `categories: [guides]` and a `title` | `guides/<title slug>.md` → `/guides/<title slug>.html` |
| page with several usable categories | one copy per category, e.g. `guides/...` and `notes/...` |
| page whose categories are not usable | `authors/<author>/<relative path>` |
| `author.md` without categories | `authors/<author>/author.md` |
| `_posts/**` | `_posts/<author>/**` (a real Jekyll post) |
| `_drafts/**` | `_drafts/<author>/**` (built only with `--drafts`) |
| `_includes/**` | `_includes/<author>/**` |
| `_layouts/**`, `_sass/**`, `_data/**` | same directory, namespaced by author |
| `_plugins/**` | skipped (plugins load before the mirror) |

A category is usable only when the site root contains a category page named
after it (`guides.md`, `guides.markdown`, `guides.html` or `guides.htm`).
Usable categories are single level: `categories: [guides, notes]` creates two
copies, never a nested `guides/notes/` directory.

The published file name comes from the front matter `title`, slugified by
Jekyll (Unicode is preserved). Without a title the source file name is used.
Add `permalink:` to the front matter if you need a custom URL.

## Front matter reference

| Key | Used for |
| --- | --- |
| `layout` | `page`, `article` (chapter root / ordered pages), `post` (posts) |
| `title` | Page title, category list label and target file name |
| `categories` / `category` | Category membership; array or space separated string |
| `order` | Order inside a category chapter (`1`, `1.1`, `1.2`, `2`, ...) |
| `tags` | Tag chips and `/tags/<tag>.html` index pages |
| `date` | Publication date; used for posts without a dated filename |
| `modified_date` | "Updated on" date and recency sorting |
| `license` | Per-page license; inherited from the category root when using `layout: article` |
| `main_part` | Numeric section weight for the home page list |
| `category_list` | `false` disables the automatic list on a category page |

## Category pages

Create one page per category at the site root:

```markdown
---
layout: page
title: Guides
main_part: 3
---

Step-by-step guides.
```

During the build the page gets a list of:

- every page in `guides/` (author content and pages committed directly in that
  directory), ordered by `order` when present and by path otherwise;
- every post whose `categories` include `guides`, newest first.

Each item shows the page title and links to it. Options:

- `category_list: false` — no automatic list;
- `{% category_list %}` — insert the list manually where you want it (the
  automatic append is then skipped);
- `{% category_list guides %}` — list another category's members.

## Author profiles

Every author creates `author.md` with `categories: [author]`:

```markdown
---
layout: page
title: Alice
categories: [author]
date: 2025-01-01
---

A short profile.
```

The site owner must create `author.md` at the site root once; after that all
profiles appear at `/author/<title>.html` and on the Authors page.

## Ordered chapters

Give pages in a category an `order` value and add a root page with `order: 0`:

```markdown
---
layout: article
title: Overview
categories: [guides]
order: 0
license: "CC BY 4.0"
---
```

- ordered pages get previous/next links;
- every ordered page links back to the root page ("Back to category");
- the root page shows a nested table of contents with the numbers;
- the category page lists its members in the same `order`;
- `layout: article` pages inherit the root page's license.

`_plugins/CategoryOrder.rb` implements the ordering and chapter navigation,
`_plugins/DefaultLicense.rb` the license inheritance.

## Per-author includes

Put reusable partials in `<author>/_includes/` and include them with:

```liquid
{% include_author note.html title="Tip" body="Rendered from this author's _includes folder." %}
```

The tag looks in `_includes/<author>/` first and falls back to the shared
`_includes/` folder. Author folder names must be ASCII slugs for this to work;
the build logs a warning otherwise.

## Posts, tags and drafts

- `_posts/**` is mirrored to `_posts/<author>/**` and behaves like a normal
  Jekyll post.
- With `categories: [blog]` and the default permalink, posts are published at
  `/blog/<title>.html`.
- Post filenames do not need a date: the plugin prefixes the front matter
  `date` (or `modified_date`, or the file modification time).
- `tags:` generates `/tags/<tag>.html` index pages and tag chips in the footer.
- Drafts in `_drafts/` are mirrored but only built with
  `bundle exec jekyll serve --drafts`.
- `modified_date` adds an "Updated on" line and influences the "Recently
  updated" sidebar.
- Posts keep Jekyll's built-in previous/next links (ordered by date); the
  category `order` only applies to pages.

## Images and assets

There is no automatic mirroring of assets into category folders. Put images next
to your content and reference them under the author path they are published at:

```markdown
![Screenshot](/authors/alice/guides/screenshot.png)
```

Any file that is not a page with front matter (images, PDFs, ...) is mirrored to
`authors/<author>/<relative path>`.

## Warnings and fixes

| Warning | Meaning |
| --- | --- |
| `Category page missing (create <category>.md ...)` | The category page does not exist; the copy was skipped and the page fell back to `authors/<author>/...`. |
| `Invalid category value, skipped` | A category value contains a path separator, starts with `_` or `.`, or is a reserved name. |
| `Target exists and is not managed by this plugin` | A file already exists at the target path; delete it and rebuild to let the plugin map it. |
| `Target was modified externally` | The file was edited after the plugin wrote it; the plugin leaves it alone. |
| `Author folder ... is unsafe for include paths` | Rename the author folder to an ASCII slug. |
| `Skipped N author plugin file(s)` | `_plugins/` inside an author folder is not supported. |

## Removing the demo content

1. Delete `authors-src/alice/` and `authors-src/bob/` (or replace them).
2. Delete `guides/overview.md`.
3. Remove or rename `author.md`, `guides.md`, `blog.md` and update `header_pages`
   in `_config.yml`.
4. Replace the text in `index.html` and `about.md`.
