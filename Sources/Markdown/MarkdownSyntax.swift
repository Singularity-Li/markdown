import AppKit

/// UTF-16 ranges match NSTextStorage, including Chinese and emoji.
enum MarkdownSyntax {
    static let baseFont = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)

    static func highlighted(_ text: String) -> NSAttributedString {
        let result = NSMutableAttributedString(string: text, attributes: [
            .font: baseFont, .foregroundColor: NSColor.labelColor
        ])
        let full = NSRange(location: 0, length: (text as NSString).length)
        var codeRanges: [NSRange] = []
        func matches(_ pattern: String) -> [NSTextCheckingResult] {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return [] }
            return regex.matches(in: text, range: full)
        }
        func style(_ pattern: String, _ color: NSColor, traits: NSFontTraitMask = [], extra: [NSAttributedString.Key: Any] = [:]) {
            for match in matches(pattern) {
                guard !codeRanges.contains(where: { NSIntersectionRange($0, match.range).length > 0 }) else { continue }
                result.addAttribute(.foregroundColor, value: color, range: match.range)
                if !traits.isEmpty {
                    result.enumerateAttribute(.font, in: match.range) { value, range, _ in
                        let font = value as? NSFont ?? baseFont
                        result.addAttribute(.font, value: NSFontManager.shared.convert(font, toHaveTrait: traits), range: range)
                    }
                }
                result.addAttributes(extra, range: match.range)
            }
        }
        // Fence scanning keeps unmatched fences highlighted while the user types.
        var offset = 0
        var fence: (marker: Character, count: Int, start: Int)?
        for line in text.components(separatedBy: "\n") {
            let length = (line as NSString).length
            let leading = line.prefix(while: { $0 == " " }).count
            let trimmed = line.dropFirst(leading)
            if leading <= 3, let first = trimmed.first, first == "`" || first == "~" {
                let count = trimmed.prefix(while: { $0 == first }).count
                if let opened = fence {
                    if first == opened.marker && count >= opened.count && trimmed.dropFirst(count).trimmingCharacters(in: .whitespaces).isEmpty {
                        codeRanges.append(NSRange(location: opened.start, length: offset + length - opened.start))
                        fence = nil
                    }
                } else if count >= 3 {
                    fence = (first, count, offset)
                }
            }
            offset += length + 1
        }
        if let fence { codeRanges.append(NSRange(location: fence.start, length: full.length - fence.start)) }
        for match in matches(#"(`+)[^`\n]*(?:`(?!\1)[^`\n]*)*?\1"#) {
            if !codeRanges.contains(where: { NSIntersectionRange($0, match.range).length > 0 }) { codeRanges.append(match.range) }
        }
        for match in matches(#"^(?: {4}|\t).+$"#) {
            if !codeRanges.contains(where: { NSIntersectionRange($0, match.range).length > 0 }) { codeRanges.append(match.range) }
        }
        style(#"^ {0,3}#{1,6}(?:[ \t]+.*|$)"#, .systemBlue, traits: .boldFontMask)
        style(#"^.+\n {0,3}(?:=+|-+)[ \t]*$"#, .systemBlue, traits: .boldFontMask)
        style(#"^ {0,3}(?:>[ \t]?)+.*$"#, .systemTeal)
        style(#"^\s*(?:[-+*]|\d+[.)])[ \t]+(?:\[[ xX]\])?"#, .systemOrange)
        style(#"^ {0,3}(?:(?:\*[ \t]*){3,}|(?:-[ \t]*){3,}|(?:_[ \t]*){3,})$"#, .secondaryLabelColor)
        style(#"\|"#, .systemTeal)
        style(#"(?<!\\)\*\*\*[^\n]+?\*\*\*|(?<!\\)___[^\n]+?___"#, .systemPurple, traits: [.boldFontMask, .italicFontMask])
        style(#"(?<!\\)\*\*[^\n]+?\*\*|(?<![\w\\])__[^\n]+?__"#, .systemPurple, traits: .boldFontMask)
        style(#"(?<![\w*\\])\*(?!\*)[^\n*]+?\*(?!\*)|(?<![\w_\\])_(?!_)[^\n_]+?_(?![\w_])"#, .systemPurple, traits: .italicFontMask)
        style(#"~~[^\n]+?~~"#, .secondaryLabelColor, extra: [.strikethroughStyle: NSUnderlineStyle.single.rawValue])
        style(#"!?\[[^\]\n]*\](?:\([^\n]*?\)|\[[^\]\n]*\])"#, .systemBlue)
        style(#"^ {0,3}\[[^\]\n]+\]:.*$|\[\^[^\]\n]+\]"#, .systemBlue)
        style(#"https?://[^\s<>]+|<[^<>\n]+@[^<>\n]+>"#, .systemBlue)
        style(#"</?[A-Za-z][^>]*>|<!--[\s\S]*?-->"#, .systemPink)
        style(##"&(?:#\d+|#x[\da-fA-F]+|[A-Za-z]+);|\\[!\"#$%&'()*+,\-./:;<=>?@\[\]\\^_`{|}~]"##, .systemOrange)
        style(#"\$\$[\s\S]*?\$\$|(?<![\\$])\$[^$\n]+\$|==[^\n]+?==|\^\w+\^|(?<!~)~\w+~(?!~)"#, .systemPink)
        for range in codeRanges {
            result.setAttributes([.font: baseFont, .foregroundColor: NSColor.systemBrown,
                                  .backgroundColor: NSColor.quaternaryLabelColor.withAlphaComponent(0.12)], range: range)
        }
        return result
    }
}
