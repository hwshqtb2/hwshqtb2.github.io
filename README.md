# Jekyll Authors Template

A multi-author blog and wiki starter for Jekyll. Authors write in their own
folders; small plugins in `_plugins/` merge those folders into the site at build
time, generate category pages, ordered navigation, tag indexes and a "Recently
updated" sidebar.

- **Folder based authoring** — every author owns a folder under `authors-src/`.
- **Category pages** — a site-root page named after a category automatically
  lists its pages and posts.
- **Ordered chapters** — `order:` values give previous/next links, a
  back-to-category link and a nested table of contents; category pages list
  their members in the same order.
- **Author profiles** — pages with `categories: [author]` are published under
  `/author/`.
- **Per-author includes** — `{% include_author file.html %}` resolves partials
  from the current author's `_includes/` folder first.
- **Extras** — tag index pages, RSS feed, license inheritance and a configurable
  recently-updated sidebar.

## Requirements

- Ruby 3.x and Bundler
- Jekyll 4.x (installed by Bundler)

`Gemfile.lock` is git-ignored on purpose: it pins gems for one platform and Ruby
version, so `bundle install` resolves the right versions on your machine. Commit
it (and pin the Ruby version in the workflow) if you prefer reproducible
installs.

## Quick start

```sh
bundle install
bundle exec jekyll serve
```

Open <http://localhost:4000>. Edit `_config.yml` first (title, author, email,
social links, license, author folder), then replace the demo content.

## Project structure

```
.
├── _config.yml            # site + author configuration
├── _includes/             # shared partials (header, footer, lists, ...)
├── _layouts/              # page, article, post, tag pages
├── _plugins/              # the plugins that power the template
├── _sass/                 # Minima theme + _template.scss components
├── assets/main.scss       # Sass entry point
├── authors-src/           # one folder per author (authors.source)
│   ├── alice/author.md
│   ├── alice/_includes/
│   ├── alice/_posts/
│   ├── alice/guides/
│   └── bob/
├── guides/overview.md     # site-owned page inside a category
├── author.md              # category pages (site root, owner maintained)
├── guides.md
├── blog.md
├── about.md
├── index.html
├── 404.html
├── docs/                  # authoring and configuration guides (not published)
├── Gemfile
├── LICENSE.txt
└── README.md
```

## How authoring works

Each author folder may contain:

| Source | Becomes |
| --- | --- |
| `author.md` with `categories: [author]` | `/author/<title>.html` (author profile) |
| pages with `categories: [guides]` | `/guides/<title>.html` (requires `guides.md`) |
| pages without categories | `/authors/<author>/<path>.html` |
| `_posts/**` | real Jekyll posts under `/blog/<title>.html` |
| `_drafts/**` | drafts (only with `bundle exec jekyll serve --drafts`) |
| `_includes/**` | `<author>/`-scoped partials for `{% include_author %}` |
| `_plugins/**` | skipped (plugins load before the mirror) |

Category pages are the switch for categories: create `<category>.md` at the site
root and the category becomes available. See [docs/authoring.md](docs/authoring.md)
for the full writer's guide and [docs/configuration.md](docs/configuration.md)
for every configuration key and plugin.

## Category pages

A category page is a normal page at the site root:

```markdown
---
layout: page
title: Guides
---

Step-by-step guides.
```

During the build every page in `guides/` (mirrored from authors) and every post
with `categories: [guides]` is listed under the content, linked by title. Use
`category_list: false` in the front matter to disable the list, or place
`{% category_list %}` manually to control its position.

## Configuration

Everything lives in `_config.yml`; the important part is:

```yaml
authors:
  source: authors-src   # one sub-folder per author
  page_dir: authors     # fallback for uncategorized content
  keep_mirror: false    # true = keep the generated files after the build
```

See [docs/configuration.md](docs/configuration.md) for the complete reference.

## Deployment

The included GitHub Actions workflow (`.github/workflows/jekyll-gh-pages.yml`)
builds the site with `bundle exec jekyll build` and deploys `_site` to Pages.
That is required because the template relies on custom plugins: the classic
GitHub Pages builder runs Jekyll in safe mode and ignores `_plugins/`.

1. Push the repository to GitHub (branch `main`).
2. Open **Settings → Pages** and set **Build and deployment → Source** to
   **GitHub Actions**. This has to be done once; without it the workflow stops
   at the *Setup Pages* step with `Get Pages site failed ... Not Found`.
3. Run the workflow again (Actions → the failed run → **Re-run all jobs**), or
   push another commit.

> If the log contains `actions/jekyll-build-pages@v1`, `github-pages v232`,
> `jekyll v3.10.0` or `Unknown tag 'include_author'`, the Source is still
> **Deploy from a branch**: that builder runs Jekyll in safe mode and cannot run
> `_plugins/`. Switch the Source to **GitHub Actions** as described above.

Notes:

- The workflow passes the Pages base path to Jekyll
  (`--baseurl "${{ steps.pages.outputs.base_path }}"`), so both user pages
  (`<user>.github.io`) and project pages (`<user>.github.io/<repo>`) work
  without editing `_config.yml`.
- Private repositories need a GitHub plan that supports Pages; otherwise the
  Pages API returns 404 even after enabling it.
- `enablement: true` on `actions/configure-pages` is *not* used: according to
  its documentation it requires a personal access token or GitHub App token
  with repository administration rights, not the default `GITHUB_TOKEN`. Enabling
  Pages in the settings once is simpler and works for forks too.
- If you prefer absolute URLs for the feed/SEO tags, set `url` in `_config.yml`
  to the final site origin (`https://<user>.github.io`).

## Customization

- Site title, author, email, social links and license: `_config.yml`.
- Colours and fonts: `_sass/minima/_settings.scss`.
- Component styles (TOC, previous/next, category lists, tags, notes):
  `_sass/_template.scss`.
- Layouts and partials: `_layouts/`, `_includes/`.
- `favicon.ico`: replace it with your own icon.

## Removing the demo content

1. Delete the author folders you do not need (keep at least one, or `authors-src/`
   can stay empty), and `guides/overview.md`.
2. Delete or rename the demo category pages `author.md`, `guides.md`, `blog.md`
   and update `header_pages` in `_config.yml`.
3. Replace `about.md` and the home page text in `index.html`.
4. Update the placeholders in `_config.yml` and `LICENSE.txt`.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| The Pages run shows `actions/jekyll-build-pages@v1`, `github-pages v232` or `Unknown tag 'include_author'` | GitHub Pages is building from a branch in safe mode, so `_plugins/` is skipped. Set **Settings → Pages → Source** to **GitHub Actions** and re-run the workflow. |
| `Get Pages site failed ... Not Found` at Setup Pages | Pages is not enabled yet (or the repository plan does not support Pages): enable it under **Settings → Pages → Source: GitHub Actions**. |
| `Category page missing ...` | Create `<category>.md` at the site root, or fix the spelling in `categories:`. |
| A page landed in `/authors/<author>/...` | Its category page does not exist, or its category value is invalid. |
| `include_author` cannot find a file | The author folder must be an ASCII slug and the file must live in `<author>/_includes/`. |
| Nothing is mapped on GitHub Pages | Use the bundled workflow (Bundler build); safe mode skips `_plugins/`. |
| A `tmp/` warning appears | You renamed the author folder; move or delete the old `tmp/` directory. |
| Generated files appear in git | They are cleaned after the build; set `authors.keep_mirror: true` only for debugging. |

## Credits

The visual theme started from [Minima](https://github.com/jekyll/minima),
released under the MIT License (© Parker Moore and the minima contributors).

## License

MIT — see `LICENSE.txt`. Content published with the template belongs to its
authors.
