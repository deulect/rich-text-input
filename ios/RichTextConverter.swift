import Foundation
import UIKit

// MARK: - RichTextConverter
/**
 * Utility class for converting between JavaScript RichTextValue and iOS NSAttributedString.
 * 
 * This class handles the critical data conversion between the JavaScript rich text format
 * and native iOS attributed strings, ensuring proper formatting preservation and efficient
 * span management.
 * 
 * Key Features:
 * - Bidirectional conversion between RichTextValue and NSAttributedString
 * - Font trait manipulation (bold, italic)
 * - Span merging and optimization
 * - Overlapping span handling
 * - Active style detection at cursor positions
 */
class RichTextConverter {
  
  // MARK: - Data Structure Types
  // These match the TypeScript definitions from the JavaScript side
  
  struct RichTextStyle {
    let bold: Bool
    let italic: Bool
    let underline: Bool
    let strikethrough: Bool
    
    init(bold: Bool = false, italic: Bool = false, underline: Bool = false, strikethrough: Bool = false) {
      self.bold = bold
      self.italic = italic
      self.underline = underline
      self.strikethrough = strikethrough
    }
    
    init(from dictionary: [String: Any]) {
      self.bold = dictionary["bold"] as? Bool ?? false
      self.italic = dictionary["italic"] as? Bool ?? false
      self.underline = dictionary["underline"] as? Bool ?? false
      self.strikethrough = dictionary["strikethrough"] as? Bool ?? false
    }
    
    func toDictionary() -> [String: Any] {
      return [
        "bold": bold,
        "italic": italic,
        "underline": underline,
        "strikethrough": strikethrough
      ]
    }
    
    // Helper method to check if style has any formatting
    func hasFormatting() -> Bool {
      return bold || italic || underline || strikethrough
    }
    
    // Helper method to compare styles for equality
    func isEqual(to other: RichTextStyle) -> Bool {
      return bold == other.bold && 
             italic == other.italic && 
             underline == other.underline && 
             strikethrough == other.strikethrough
    }
  }
  
  struct RichTextSpan {
    let start: Int
    let end: Int
    let attributes: RichTextStyle
    
    init(start: Int, end: Int, attributes: RichTextStyle) {
      self.start = start
      self.end = end
      self.attributes = attributes
    }
    
    init(from dictionary: [String: Any]) {
      self.start = dictionary["start"] as? Int ?? 0
      self.end = dictionary["end"] as? Int ?? 0
      self.attributes = RichTextStyle(from: dictionary["attributes"] as? [String: Any] ?? [:])
    }
    
    func toDictionary() -> [String: Any] {
      return [
        "start": start,
        "end": end,
        "attributes": attributes.toDictionary()
      ]
    }
    
    // Helper method to check if span is valid
    func isValid() -> Bool {
      return start >= 0 && end > start
    }
    
    // Helper method to get span length
    func length() -> Int {
      return end - start
    }
  }
  
  struct RichTextValue {
    let text: String
    let spans: [RichTextSpan]
    
    init(text: String, spans: [RichTextSpan] = []) {
      self.text = text
      self.spans = spans
    }
    
    init(from dictionary: [String: Any]) {
      self.text = dictionary["text"] as? String ?? ""
      
      let spanDictionaries = dictionary["spans"] as? [[String: Any]] ?? []
      self.spans = spanDictionaries.map { RichTextSpan(from: $0) }
    }
    
    func toDictionary() -> [String: Any] {
      return [
        "text": text,
        "spans": spans.map { $0.toDictionary() }
      ]
    }
  }
  
  // MARK: - Conversion Methods
  
  /**
   * Convert JavaScript RichTextValue to iOS NSAttributedString
   * 
   * This method creates a properly formatted NSAttributedString from the JavaScript
   * rich text format, handling font traits and text decorations.
   * 
   * @param richTextValue - The JavaScript RichTextValue to convert
   * @param baseFont - The base font to use for the text
   * @returns NSAttributedString with proper formatting applied
   */
  static func toNSAttributedString(_ richTextValue: RichTextValue, baseFont: UIFont = UIFont.systemFont(ofSize: 16)) -> NSAttributedString {
    let attributedString = NSMutableAttributedString(string: richTextValue.text)
    
    // Set base font and color for entire string
    let baseAttributes: [NSAttributedString.Key: Any] = [
      .font: baseFont,
      .foregroundColor: UIColor.label
    ]
    
    attributedString.addAttributes(baseAttributes, range: NSRange(location: 0, length: richTextValue.text.count))
    
    // Apply each span's formatting
    for span in richTextValue.spans {
      let range = NSRange(location: span.start, length: span.end - span.start)
      
      // Ensure range is valid
      guard range.location >= 0 && range.location + range.length <= richTextValue.text.count else {
        continue
      }
      
      // Apply the style to this range
      applyStyleToRange(span.attributes, to: attributedString, range: range, baseFont: baseFont)
    }
    
    return attributedString
  }
  
  /**
   * Convert iOS NSAttributedString to JavaScript RichTextValue
   * 
   * This method extracts formatting information from an NSAttributedString and
   * converts it to the JavaScript RichTextValue format with optimized spans.
   * 
   * @param attributedString - The NSAttributedString to convert
   * @returns RichTextValue with extracted formatting spans
   */
  static func fromNSAttributedString(_ attributedString: NSAttributedString) -> RichTextValue {
    let text = attributedString.string
    var spans: [RichTextSpan] = []
    
    // Early return for empty strings
    guard !text.isEmpty else {
      return RichTextValue(text: "", spans: [])
    }
    
    // Enumerate attributes to find formatting spans
    attributedString.enumerateAttributes(in: NSRange(location: 0, length: text.count), options: []) { attributes, range, _ in
      let style = extractStyleFromAttributes(attributes)
      
      // Only create span if it has formatting
      if style.hasFormatting() {
        let span = RichTextSpan(start: range.location, end: range.location + range.length, attributes: style)
        spans.append(span)
      }
    }
    
    // Sort spans by start position before merging
    spans.sort { $0.start < $1.start }
    
    // Merge adjacent spans with identical formatting
    let mergedSpans = mergeAdjacentSpans(spans)
    
    return RichTextValue(text: text, spans: mergedSpans)
  }
  
  // MARK: - Helper Methods
  
  /**
   * Extract RichTextStyle from NSAttributedString attributes
   */
  private static func extractStyleFromAttributes(_ attributes: [NSAttributedString.Key: Any]) -> RichTextStyle {
    var bold = false
    var italic = false
    var underline = false
    var strikethrough = false
    
    // Check for bold/italic from font
    if let font = attributes[.font] as? UIFont {
      let fontTraits = font.fontDescriptor.symbolicTraits
      bold = fontTraits.contains(.traitBold)
      italic = fontTraits.contains(.traitItalic)
    }
    
    // Check for underline
    if let underlineStyle = attributes[.underlineStyle] as? Int {
      underline = underlineStyle != 0
    }
    
    // Check for strikethrough
    if let strikethroughStyle = attributes[.strikethroughStyle] as? Int {
      strikethrough = strikethroughStyle != 0
    }
    
    return RichTextStyle(bold: bold, italic: italic, underline: underline, strikethrough: strikethrough)
  }
  
  /**
   * Merge adjacent spans with identical formatting
   * 
   * This method optimizes the span array by merging adjacent spans that have
   * identical formatting, reducing the overall number of spans.
   */
  private static func mergeAdjacentSpans(_ spans: [RichTextSpan]) -> [RichTextSpan] {
    guard spans.count > 1 else { return spans }
    
    var mergedSpans: [RichTextSpan] = []
    var currentSpan = spans[0]
    
    for i in 1..<spans.count {
      let nextSpan = spans[i]
      
      // Check if spans are adjacent and have identical formatting
      if currentSpan.end == nextSpan.start && currentSpan.attributes.isEqual(to: nextSpan.attributes) {
        // Merge the spans
        currentSpan = RichTextSpan(
          start: currentSpan.start,
          end: nextSpan.end,
          attributes: currentSpan.attributes
        )
      } else {
        // Add current span to result and start a new one
        mergedSpans.append(currentSpan)
        currentSpan = nextSpan
      }
    }
    
    // Add the last span
    mergedSpans.append(currentSpan)
    
    return mergedSpans
  }
  
  /**
   * Get the active styles at a specific position in an attributed string
   * 
   * This method determines which formatting styles are active at a given position,
   * useful for updating toolbar button states.
   */
  static func getActiveStylesAtPosition(_ attributedString: NSAttributedString, position: Int) -> RichTextStyle {
    guard position >= 0 && position < attributedString.length else {
      return RichTextStyle()
    }
    
    let attributes = attributedString.attributes(at: position, effectiveRange: nil)
    return extractStyleFromAttributes(attributes)
  }
  
  /**
   * Apply a style to a range in an attributed string
   * 
   * This method modifies the NSMutableAttributedString to apply the specified
   * formatting style to the given range.
   */
  static func applyStyle(_ style: RichTextStyle, to attributedString: NSMutableAttributedString, range: NSRange) {
    guard range.location >= 0 && range.location + range.length <= attributedString.length else {
      return
    }
    
    // Get the base font to use for font trait modifications
    let baseFont = UIFont.systemFont(ofSize: 16)
    applyStyleToRange(style, to: attributedString, range: range, baseFont: baseFont)
  }
  
  /**
   * Apply a style to a specific range with a base font
   */
  private static func applyStyleToRange(_ style: RichTextStyle, to attributedString: NSMutableAttributedString, range: NSRange, baseFont: UIFont) {
    // Handle font traits (bold, italic)
    attributedString.enumerateAttribute(.font, in: range, options: []) { value, subRange, _ in
      guard let currentFont = value as? UIFont else { return }
      
      let newFont = createFontWithTraits(from: currentFont, bold: style.bold, italic: style.italic)
      attributedString.addAttribute(.font, value: newFont, range: subRange)
    }
    
    // Handle underline
    if style.underline {
      attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
    } else {
      attributedString.removeAttribute(.underlineStyle, range: range)
    }
    
    // Handle strikethrough
    if style.strikethrough {
      attributedString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)
    } else {
      attributedString.removeAttribute(.strikethroughStyle, range: range)
    }
  }
  
  /**
   * Create a font with specific traits applied
   */
  private static func createFontWithTraits(from font: UIFont, bold: Bool, italic: Bool) -> UIFont {
    let fontSize = font.pointSize
    
    // Use system fonts for better reliability
    if bold && italic {
      // Bold + Italic - try to create bold italic font
      if let boldItalicFont = UIFont.systemFont(ofSize: fontSize, weight: .bold).withTraits(.traitItalic) {
        return boldItalicFont
      } else {
        // Fallback to just bold if bold italic fails
        return UIFont.boldSystemFont(ofSize: fontSize)
      }
    } else if bold {
      // Bold only
      return UIFont.boldSystemFont(ofSize: fontSize)
    } else if italic {
      // Italic only
      return UIFont.italicSystemFont(ofSize: fontSize)
    } else {
      // Regular
      return UIFont.systemFont(ofSize: fontSize)
    }
  }
  
  // MARK: - Utility Methods
  
  /**
   * Toggle a specific style in the current style set
   */
  static func toggleStyle(_ currentStyle: RichTextStyle, styleType: StyleType) -> RichTextStyle {
    switch styleType {
    case .bold:
      return RichTextStyle(bold: !currentStyle.bold, italic: currentStyle.italic, underline: currentStyle.underline, strikethrough: currentStyle.strikethrough)
    case .italic:
      return RichTextStyle(bold: currentStyle.bold, italic: !currentStyle.italic, underline: currentStyle.underline, strikethrough: currentStyle.strikethrough)
    case .underline:
      return RichTextStyle(bold: currentStyle.bold, italic: currentStyle.italic, underline: !currentStyle.underline, strikethrough: currentStyle.strikethrough)
    case .strikethrough:
      return RichTextStyle(bold: currentStyle.bold, italic: currentStyle.italic, underline: currentStyle.underline, strikethrough: !currentStyle.strikethrough)
    }
  }
  
  /**
   * Validate that a RichTextValue has proper structure
   */
  static func validateRichTextValue(_ value: RichTextValue) -> Bool {
    // Check text length matches span boundaries
    let textLength = value.text.count
    
    for span in value.spans {
      // Check span validity
      guard span.isValid() else { return false }
      
      // Check span is within text bounds
      guard span.start >= 0 && span.end <= textLength else { return false }
    }
    
    return true
  }
  
  /**
   * Clean up overlapping spans by splitting them appropriately
   */
  static func resolveOverlappingSpans(_ spans: [RichTextSpan]) -> [RichTextSpan] {
    guard spans.count > 1 else { return spans }
    
    var resolvedSpans: [RichTextSpan] = []
    let sortedSpans = spans.sorted { $0.start < $1.start }
    
    for span in sortedSpans {
      let currentSpan = span
      
      // Check for overlaps with existing spans
      for i in 0..<resolvedSpans.count {
        let existingSpan = resolvedSpans[i]
        
        if currentSpan.start < existingSpan.end && currentSpan.end > existingSpan.start {
          // Overlapping spans - need to split
          // This is a simplified implementation
          // In a full implementation, you'd need to handle merging styles
          continue
        }
      }
      
      resolvedSpans.append(currentSpan)
    }
    
    return resolvedSpans
  }
}

// MARK: - Supporting Types
extension RichTextConverter {
  
  enum StyleType {
    case bold
    case italic
    case underline
    case strikethrough
  }
}

// MARK: - UIFont Extension
extension UIFont {
  func withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont? {
    let descriptor = fontDescriptor.withSymbolicTraits(traits)
    return descriptor.map { UIFont(descriptor: $0, size: pointSize) }
  }
} 