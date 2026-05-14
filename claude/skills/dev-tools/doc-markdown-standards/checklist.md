# Verification Checklist and AI Output Format

## Document checklist

After generating or editing a document, verify each item:

- [ ] Front matter contains every required field (`id`, `title`, `aliases`,
      `type`, `category`, `tags`, `version`, `created`, `updated`, `author`,
      `status`).
- [ ] `updated` is today's date.
- [ ] `related_docs` is filled in (non-empty; at least one relation).
- [ ] Body internal links use `[[WikiLink]]` format (no `[text](path.md)`).
- [ ] A `## Related` section at the end lists every related document in
      WikiLink format.
- [ ] Major sections have `<!-- @section -->` and `<!-- @end-section -->`
      markers.
- [ ] Code blocks carry a language tag (```` ```go ````, ```` ```json ````,
      etc.).
- [ ] A `docs-index.md` update snippet is provided (index row + keyword row).
- [ ] Referenced documents have their `related_docs` updated reciprocally
      (or the user is prompted to update them manually).

---

## Required output after AI generates a document

```
Document generated

ID:     spec-miniapp-product-001
Path:   docs/prd/wechat/miniapp-product.md
Type:   spec
Status: draft

Relations:
- [[spec-admin-merchant-001]] → docs/prd/admin/merchant-admin-prd.md  (related_to)
```

---

## docs-index.md update format

After every document edit, provide the following two snippets to append to
`docs/docs-index.md`:

### Index-table row

```markdown
| [[spec-miniapp-product-001]] | Miniprogram product specification | spec | `docs/prd/wechat/miniapp-product.md` | miniapp, product, prd |
```

### Keyword-table rows

```markdown
| Product   | [[spec-miniapp-product-001]] |
| Miniapp   | [[spec-miniapp-product-001]] |
```
