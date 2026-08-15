module.exports = {
  names: ["docs-ascii-only"],
  description: "Documentation must be ASCII only",
  tags: ["docs"],
  parser: "none",
  function: (params, onError) => {
    params.lines.forEach((line, index) => {
      const match = /[^\x00-\x7f]/u.exec(line);
      if (!match) return;

      const codePoint = match[0].codePointAt(0);
      onError({
        lineNumber: index + 1,
        detail: `Use ASCII only; found U+${codePoint
          .toString(16)
          .toUpperCase()
          .padStart(4, "0")}.`,
        context: line,
        range: [match.index + 1, match[0].length],
      });
    });
  },
};
