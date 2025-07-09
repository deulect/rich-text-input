import ExpoModulesCore
import UIKit

// MARK: - RichTextInputView
/**
 * Main view class that handles rich text input using UITextView.
 * This view bridges JavaScript RichTextValue format with native iOS NSAttributedString.
 * 
 * Key Features:
 * - Rich text formatting (bold, italic, underline, strikethrough)
 * - Selection tracking with active style detection
 * - TextInput props compatibility
 * - Imperative API for programmatic control
 * - Real-time event dispatching to JavaScript
 */
class RichTextInputView: ExpoView {
  
  // MARK: - UI Components
  private let textView = UITextView()
  private let placeholderLabel = UILabel()
  
  // MARK: - Event Dispatchers
  // These will send events back to JavaScript
  private let onChange = EventDispatcher()
  private let onSelectionChange = EventDispatcher()
  private let onFocus = EventDispatcher()
  private let onBlur = EventDispatcher()
  
  // MARK: - Properties
  private var placeholderText: String?
  private var isEditable: Bool = true
  private var isMultiline: Bool = true
  private var maxLength: Int?
  private var autoCapitalizeType: UITextAutocapitalizationType = .sentences
  private var baseFont: UIFont = UIFont.systemFont(ofSize: 16)
  private var isSettingValue: Bool = false // Flag to prevent infinite loops
  
  // MARK: - Initialization
  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    setupTextView()
    setupPlaceholder()
    setupLayout()
  }
  
  // MARK: - Setup Methods
  private func setupTextView() {
    // Configure the main text view for rich text editing
    textView.delegate = self
    textView.isEditable = true
    textView.isScrollEnabled = true
    textView.font = baseFont
    textView.backgroundColor = UIColor.clear
    textView.textColor = UIColor.label
    
    // Configure text container for rich text
    textView.textContainer.lineFragmentPadding = 0
    textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    
    // Enable rich text features
    textView.allowsEditingTextAttributes = true
    textView.autocorrectionType = .yes
    textView.spellCheckingType = .yes
    textView.smartDashesType = .yes
    textView.smartQuotesType = .yes
    
    // Set up default typing attributes
    textView.typingAttributes = [
      .font: baseFont,
      .foregroundColor: UIColor.label
    ]
    
    addSubview(textView)
  }
  
  private func setupPlaceholder() {
    // Configure placeholder label
    placeholderLabel.font = baseFont
    placeholderLabel.textColor = UIColor.placeholderText
    placeholderLabel.numberOfLines = 0
    placeholderLabel.isHidden = true
    
    addSubview(placeholderLabel)
  }
  
  private func setupLayout() {
    // Set up auto layout constraints
    textView.translatesAutoresizingMaskIntoConstraints = false
    placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      // Text view constraints
      textView.topAnchor.constraint(equalTo: topAnchor),
      textView.leadingAnchor.constraint(equalTo: leadingAnchor),
      textView.trailingAnchor.constraint(equalTo: trailingAnchor),
      textView.bottomAnchor.constraint(equalTo: bottomAnchor),
      
      // Placeholder label constraints (accounting for text container inset)
      placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 8),
      placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 12),
      placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: -12)
    ])
  }
  
  // MARK: - Prop Setters
  // These methods are called when props are set from JavaScript
  
  func setInitialValue(_ value: [String: Any]?) {
    guard let value = value else {
      // Clear the text view if null/undefined
      textView.text = ""
      textView.attributedText = NSAttributedString(string: "")
      updatePlaceholderVisibility()
      return
    }
    
    // Convert JavaScript RichTextValue to NSAttributedString
    let richTextValue = RichTextConverter.RichTextValue(from: value)
    let attributedString = RichTextConverter.toNSAttributedString(richTextValue, baseFont: baseFont)
    
    // Set the attributed text
    isSettingValue = true
    textView.attributedText = attributedString
    isSettingValue = false
    
    updatePlaceholderVisibility()
  }
  
  func setPlaceholder(_ placeholder: String?) {
    placeholderText = placeholder
    placeholderLabel.text = placeholder
    updatePlaceholderVisibility()
  }
  
  func setEditable(_ editable: Bool) {
    isEditable = editable
    textView.isEditable = editable
  }
  
  func setAutoCapitalize(_ autoCapitalize: String?) {
    guard let autoCapitalize = autoCapitalize else {
      autoCapitalizeType = .sentences
      textView.autocapitalizationType = autoCapitalizeType
      return
    }
    
    switch autoCapitalize {
    case "none":
      autoCapitalizeType = .none
    case "sentences":
      autoCapitalizeType = .sentences
    case "words":
      autoCapitalizeType = .words
    case "characters":
      autoCapitalizeType = .allCharacters
    default:
      autoCapitalizeType = .sentences
    }
    
    textView.autocapitalizationType = autoCapitalizeType
  }
  
  func setMultiline(_ multiline: Bool) {
    isMultiline = multiline
    textView.isScrollEnabled = multiline
    
    // Configure text container for single line if needed
    if !multiline {
      textView.textContainer.maximumNumberOfLines = 1
      textView.textContainer.lineBreakMode = .byTruncatingTail
    } else {
      textView.textContainer.maximumNumberOfLines = 0
      textView.textContainer.lineBreakMode = .byWordWrapping
    }
  }
  
  func setMaxLength(_ maxLength: Int?) {
    self.maxLength = maxLength
  }
  
  func setAutoCorrect(_ autoCorrect: Bool) {
    textView.autocorrectionType = autoCorrect ? .yes : .no
  }
  
  func setSpellCheck(_ spellCheck: Bool) {
    textView.spellCheckingType = spellCheck ? .yes : .no
  }
  
  func setKeyboardType(_ keyboardType: String) {
    switch keyboardType {
    case "default":
      textView.keyboardType = .default
    case "number-pad":
      textView.keyboardType = .numberPad
    case "decimal-pad":
      textView.keyboardType = .decimalPad
    case "email-address":
      textView.keyboardType = .emailAddress
    case "url":
      textView.keyboardType = .URL
    case "phone-pad":
      textView.keyboardType = .phonePad
    default:
      textView.keyboardType = .default
    }
  }
  
  func setReturnKeyType(_ returnKeyType: String) {
    switch returnKeyType {
    case "default":
      textView.returnKeyType = .default
    case "done":
      textView.returnKeyType = .done
    case "go":
      textView.returnKeyType = .go
    case "next":
      textView.returnKeyType = .next
    case "search":
      textView.returnKeyType = .search
    case "send":
      textView.returnKeyType = .send
    default:
      textView.returnKeyType = .default
    }
  }
  
  // MARK: - Imperative Methods
  // These methods are called from JavaScript via ref
  
  func applyStyle(_ style: [String: Any]) {
    let selectedRange = textView.selectedRange
    
    // If no selection, set typing attributes for new text
    if selectedRange.length == 0 {
      applyTypingAttributes(style)
      return
    }
    
    // Apply style to selected text
    guard let attributedText = textView.attributedText?.mutableCopy() as? NSMutableAttributedString else {
      return
    }
    
    // Parse style from JavaScript format
    let richTextStyle = RichTextConverter.RichTextStyle(from: style)
    
    // Apply the style to the selected range
    RichTextConverter.applyStyle(richTextStyle, to: attributedText, range: selectedRange)
    
    // Update the text view
    isSettingValue = true
    textView.attributedText = attributedText
    textView.selectedRange = selectedRange // Restore selection
    isSettingValue = false
    
    // Send change event
    sendChangeEvent()
  }
  
  private func applyTypingAttributes(_ style: [String: Any]) {
    let richTextStyle = RichTextConverter.RichTextStyle(from: style)
    var typingAttributes = textView.typingAttributes
    
    // Get current font
    let currentFont = typingAttributes[.font] as? UIFont ?? baseFont
    var fontDescriptor = currentFont.fontDescriptor
    var symbolicTraits = fontDescriptor.symbolicTraits
    
    // Apply bold
    if richTextStyle.bold {
      symbolicTraits.insert(.traitBold)
    } else {
      symbolicTraits.remove(.traitBold)
    }
    
    // Apply italic
    if richTextStyle.italic {
      symbolicTraits.insert(.traitItalic)
    } else {
      symbolicTraits.remove(.traitItalic)
    }
    
    // Create new font with updated traits
    if let newFontDescriptor = fontDescriptor.withSymbolicTraits(symbolicTraits) {
      let newFont = UIFont(descriptor: newFontDescriptor, size: currentFont.pointSize)
      typingAttributes[.font] = newFont
    }
    
    // Apply underline
    if richTextStyle.underline {
      typingAttributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
    } else {
      typingAttributes.removeValue(forKey: .underlineStyle)
    }
    
    // Apply strikethrough
    if richTextStyle.strikethrough {
      typingAttributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
    } else {
      typingAttributes.removeValue(forKey: .strikethroughStyle)
    }
    
    textView.typingAttributes = typingAttributes
  }
  
  func clear() {
    isSettingValue = true
    textView.text = ""
    textView.attributedText = NSAttributedString(string: "")
    isSettingValue = false
    
    updatePlaceholderVisibility()
    sendChangeEvent()
  }
  
  func focus() {
    textView.becomeFirstResponder()
  }
  
  func blur() {
    textView.resignFirstResponder()
  }
  
  func getSelection() -> [String: Any] {
    let selectedRange = textView.selectedRange
    let activeStyles = getActiveStylesAtSelection()
    
    return [
      "start": selectedRange.location,
      "end": selectedRange.location + selectedRange.length,
      "activeStyles": activeStyles
    ]
  }
  
  func insertText(_ text: String) {
    let selectedRange = textView.selectedRange
    
    guard let attributedText = textView.attributedText?.mutableCopy() as? NSMutableAttributedString else {
      return
    }
    
    // Create attributed string with current typing attributes
    let insertText = NSAttributedString(string: text, attributes: textView.typingAttributes)
    
    // Insert the text at the current selection
    attributedText.replaceCharacters(in: selectedRange, with: insertText)
    
    // Update the text view
    isSettingValue = true
    textView.attributedText = attributedText
    textView.selectedRange = NSRange(location: selectedRange.location + text.count, length: 0)
    isSettingValue = false
    
    updatePlaceholderVisibility()
    sendChangeEvent()
  }
  
  func replaceText(start: Int, end: Int, text: String) {
    let textLength = textView.text.count
    
    // Validate range
    guard start >= 0 && end >= start && end <= textLength else {
      return
    }
    
    let range = NSRange(location: start, length: end - start)
    
    guard let attributedText = textView.attributedText?.mutableCopy() as? NSMutableAttributedString else {
      return
    }
    
    // Create attributed string with base font
    let replaceText = NSAttributedString(string: text, attributes: [.font: baseFont])
    
    // Replace the text in the specified range
    attributedText.replaceCharacters(in: range, with: replaceText)
    
    // Update the text view
    isSettingValue = true
    textView.attributedText = attributedText
    textView.selectedRange = NSRange(location: start + text.count, length: 0)
    isSettingValue = false
    
    updatePlaceholderVisibility()
    sendChangeEvent()
  }
  
  func setSelection(start: Int, end: Int) {
    let textLength = textView.text.count
    
    // Validate range
    guard start >= 0 && end >= start && end <= textLength else {
      return
    }
    
    let range = NSRange(location: start, length: end - start)
    textView.selectedRange = range
  }
  
  func getValue() -> [String: Any] {
    guard let attributedText = textView.attributedText else {
      return [
        "text": "",
        "spans": []
      ]
    }
    
    let richTextValue = RichTextConverter.fromNSAttributedString(attributedText)
    return richTextValue.toDictionary()
  }
  
  func setValue(_ value: [String: Any]) {
    // Convert JavaScript RichTextValue to NSAttributedString
    let richTextValue = RichTextConverter.RichTextValue(from: value)
    let attributedString = RichTextConverter.toNSAttributedString(richTextValue, baseFont: baseFont)
    
    // Preserve current selection if possible
    let currentSelection = textView.selectedRange
    
    // Set the attributed text
    isSettingValue = true
    textView.attributedText = attributedString
    
    // Restore selection if still valid
    let newTextLength = attributedString.length
    if currentSelection.location <= newTextLength {
      let newSelectionLength = min(currentSelection.length, newTextLength - currentSelection.location)
      textView.selectedRange = NSRange(location: currentSelection.location, length: newSelectionLength)
    }
    
    isSettingValue = false
    
    updatePlaceholderVisibility()
    sendChangeEvent()
  }
  
  // MARK: - Private Helper Methods
  
  private func updatePlaceholderVisibility() {
    let isEmpty = textView.attributedText?.length == 0
    placeholderLabel.isHidden = !isEmpty
  }
  
  private func sendChangeEvent() {
    // Prevent infinite loops when setting values programmatically
    guard !isSettingValue else { return }
    
    // Convert current attributedText to RichTextValue format
    guard let attributedText = textView.attributedText else {
      onChange([
        "value": [
          "text": "",
          "spans": []
        ]
      ])
      return
    }
    
    let richTextValue = RichTextConverter.fromNSAttributedString(attributedText)
    
    onChange([
      "value": richTextValue.toDictionary()
    ])
  }
  
  private func sendSelectionChangeEvent() {
    // Prevent infinite loops when setting values programmatically
    guard !isSettingValue else { return }
    
    let selection = getSelection()
    onSelectionChange(selection)
  }
  
  private func getActiveStylesAtSelection() -> [String: Any] {
    let selectedRange = textView.selectedRange
    
    // If we have a selection, get styles from the first character
    if selectedRange.length > 0 {
      guard let attributedText = textView.attributedText,
            selectedRange.location < attributedText.length else {
        return createDefaultStyles()
      }
      
      let style = RichTextConverter.getActiveStylesAtPosition(attributedText, position: selectedRange.location)
      return style.toDictionary()
    }
    
    // If no selection, get styles from typing attributes
    return getStylesFromTypingAttributes()
  }
  
  private func getStylesFromTypingAttributes() -> [String: Any] {
    let typingAttributes = textView.typingAttributes
    
    var bold = false
    var italic = false
    var underline = false
    var strikethrough = false
    
    // Check font for bold/italic
    if let font = typingAttributes[.font] as? UIFont {
      let fontTraits = font.fontDescriptor.symbolicTraits
      bold = fontTraits.contains(.traitBold)
      italic = fontTraits.contains(.traitItalic)
    }
    
    // Check for underline
    if let underlineStyle = typingAttributes[.underlineStyle] as? Int {
      underline = underlineStyle != 0
    }
    
    // Check for strikethrough
    if let strikethroughStyle = typingAttributes[.strikethroughStyle] as? Int {
      strikethrough = strikethroughStyle != 0
    }
    
    return [
      "bold": bold,
      "italic": italic,
      "underline": underline,
      "strikethrough": strikethrough
    ]
  }
  
  private func createDefaultStyles() -> [String: Any] {
    return [
      "bold": false,
      "italic": false,
      "underline": false,
      "strikethrough": false
    ]
  }
}

// MARK: - UITextViewDelegate
extension RichTextInputView: UITextViewDelegate {
  
  func textViewDidChange(_ textView: UITextView) {
    updatePlaceholderVisibility()
    sendChangeEvent()
  }
  
  func textViewDidChangeSelection(_ textView: UITextView) {
    sendSelectionChangeEvent()
  }
  
  func textViewDidBeginEditing(_ textView: UITextView) {
    onFocus([:])
  }
  
  func textViewDidEndEditing(_ textView: UITextView) {
    onBlur([:])
  }
  
  func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    // Handle maxLength restriction
    if let maxLength = maxLength {
      let currentText = textView.text ?? ""
      let newLength = currentText.count + text.count - range.length
      if newLength > maxLength {
        return false
      }
    }
    
    // Handle single line mode (reject newlines if not multiline)
    if !isMultiline && text.contains("\n") {
      return false
    }
    
    return true
  }
  
  func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
    // Handle URL interactions if needed in the future
    return true
  }
}
