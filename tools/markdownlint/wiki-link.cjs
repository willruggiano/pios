module.exports = {
  names: ["docs-wiki-link"],
  description: "Internal doc references must use [[wiki-link]] format.",
  tags: ["links"],
  parser: "none",
  function: (params, onError) => {
    // A standard Markdown link whose target is a relative *.md path.
    const relMdLink = /\]\(\s*(?!https?:|#|mailto:)[^)]*?\.md(?:#[^)]*)?\s*\)/g;
    params.lines.forEach((line, index) => {
      for (const match of line.matchAll(relMdLink)) {
        onError({
          lineNumber: index + 1,
          detail: "Use [[file.md]] wiki-link syntax for internal references.",
          context: match[0],
        });
      }
    });
  },
};
