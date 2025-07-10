import ExpoModulesCore

// MARK: - Rich Text Input Module
/**
 * RichTextInputModule provides a native rich text editing component for React Native.
 * This module bridges JavaScript and native iOS UITextView functionality, supporting:
 * - Rich text formatting (bold, italic, underline, strikethrough)
 * - Text selection and cursor management
 * - Standard TextInput props compatibility
 * - Imperative API for programmatic control
 * 
 * Data Flow:
 * JavaScript RichTextValue ↔ iOS NSAttributedString ↔ UITextView
 * 
 * Data Structures:
 * - RichTextValue: { text: string, spans: RichTextSpan[] }
 * - RichTextSpan: { start: number, end: number, attributes: RichTextStyle }
 * - RichTextStyle: { bold?: boolean, italic?: boolean, underline?: boolean, strikethrough?: boolean }
 */

public class RichTextInputModule: Module {
  
  // MARK: - Module Definition
  public func definition() -> ModuleDefinition {
    
    // Module name that JavaScript will use to reference this module
    // Accessible via: requireNativeModule('RichTextInput')
    Name("RichTextInput")

    // MARK: - View Component Definition
    // Defines the native view component that can be rendered in React Native
    View(RichTextInputView.self) {
      
      // MARK: - Core Rich Text Props
      
      /**
       * initialValue: RichTextValue | null
       * Sets the initial rich text content when the component is first rendered.
       * This prop is only processed once during initialization.
       * 
       * Expected format:
       * {
       *   text: "Hello world",
       *   spans: [
       *     { start: 0, end: 5, attributes: { bold: true } },
       *     { start: 6, end: 11, attributes: { italic: true } }
       *   ]
       * }
       */
      Prop("initialValue") { (view: RichTextInputView, value: [String: Any]?) in
        guard let value = value else {
          // If null/undefined, clear the text view
          view.setInitialValue(nil)
          return
        }
        
        // Validate that the value has the expected structure
        guard value["text"] as? String != nil else {
          print("RichTextInput: Warning - initialValue.text must be a string")
          return
        }
        
        // Spans are optional - validate they exist (we don't need to use the value here)
        _ = value["spans"] as? [[String: Any]] ?? []
        
        // Set the initial value on the view
        view.setInitialValue(value)
      }
      
      // MARK: - Standard TextInput Props
      
      /**
       * placeholder: string | null
       * Sets the placeholder text shown when the input is empty.
       * Supports multiline placeholders.
       */
      Prop("placeholder") { (view: RichTextInputView, placeholder: String?) in
        view.setPlaceholder(placeholder)
      }
      
      /**
       * editable: boolean
       * Controls whether the text can be edited by the user.
       * When false, the text view becomes read-only but still allows selection.
       * Default: true
       */
      Prop("editable") { (view: RichTextInputView, editable: Bool) in
        view.setEditable(editable)
      }
      
      /**
       * autoCapitalize: "none" | "sentences" | "words" | "characters"
       * Controls automatic capitalization behavior.
       * - "none": No automatic capitalization
       * - "sentences": Capitalize first letter of sentences (default)
       * - "words": Capitalize first letter of each word
       * - "characters": Capitalize all characters
       */
      Prop("autoCapitalize") { (view: RichTextInputView, autoCapitalize: String?) in
        let validValues = ["none", "sentences", "words", "characters"]
        
        guard let autoCapitalize = autoCapitalize else {
          view.setAutoCapitalize("sentences") // Default value
          return
        }
        
        if validValues.contains(autoCapitalize) {
          view.setAutoCapitalize(autoCapitalize)
        } else {
          print("RichTextInput: Warning - autoCapitalize must be one of: \(validValues.joined(separator: ", "))")
          view.setAutoCapitalize("sentences") // Fallback to default
        }
      }
      
      /**
       * multiline: boolean
       * Controls whether the text input allows multiple lines.
       * When false, pressing Enter will not create new lines.
       * Default: true
       */
      Prop("multiline") { (view: RichTextInputView, multiline: Bool) in
        view.setMultiline(multiline)
      }
      
      /**
       * maxLength: number | null
       * Sets the maximum number of characters allowed in the text input.
       * When null, there is no character limit.
       * Default: null (no limit)
       */
      Prop("maxLength") { (view: RichTextInputView, maxLength: Int?) in
        // Validate that maxLength is positive if provided
        if let maxLength = maxLength, maxLength < 0 {
          print("RichTextInput: Warning - maxLength must be non-negative")
          view.setMaxLength(nil) // Ignore negative values
        } else {
          view.setMaxLength(maxLength)
        }
      }
      
      /**
       * autoCorrect: boolean
       * Controls whether auto-correction is enabled.
       * Default: true
       */
      Prop("autoCorrect") { (view: RichTextInputView, autoCorrect: Bool) in
        view.setAutoCorrect(autoCorrect)
      }
      
      /**
       * spellCheck: boolean
       * Controls whether spell checking is enabled.
       * Default: true
       */
      Prop("spellCheck") { (view: RichTextInputView, spellCheck: Bool) in
        view.setSpellCheck(spellCheck)
      }
      
      /**
       * keyboardType: string
       * Controls the type of keyboard displayed.
       * Common values: "default", "number-pad", "decimal-pad", "email-address", "url"
       */
      Prop("keyboardType") { (view: RichTextInputView, keyboardType: String?) in
        view.setKeyboardType(keyboardType ?? "default")
      }
      
      /**
       * returnKeyType: string
       * Controls the return key type on the keyboard.
       * Common values: "default", "done", "go", "next", "search", "send"
       */
      Prop("returnKeyType") { (view: RichTextInputView, returnKeyType: String?) in
        view.setReturnKeyType(returnKeyType ?? "default")
      }

      // MARK: - View Events
      // Events that this specific view instance can dispatch to JavaScript
      // Using custom event names to avoid conflicts with standard React Native events
      Events(
        "onRichTextChange",         // { value: RichTextValue } - Text content changed
        "onRichTextSelectionChange", // { start: number, end: number, activeStyles: RichTextStyle } - Selection changed
        "onRichTextFocus",          // { } - Text view gained focus
        "onRichTextBlur"            // { } - Text view lost focus
      )

      // MARK: - Imperative Commands
      // Methods that can be called from JavaScript via component ref
      
      /**
       * applyStyle(style: RichTextStyle) -> void
       * Applies rich text formatting to the current selection.
       * If no text is selected, the formatting will be applied to new text typed at the cursor.
       * 
       * @param style - Style object: { bold?: boolean, italic?: boolean, underline?: boolean, strikethrough?: boolean }
       * 
       * Example:
       * ref.current.applyStyle({ bold: true, italic: false })
       */
      AsyncFunction("applyStyle") { (view: RichTextInputView, style: [String: Any]) in
        // Validate style parameter
        guard !style.isEmpty else {
          print("RichTextInput: Warning - applyStyle called with empty style object")
          return
        }
        
        // Validate that style contains valid boolean values
        let validKeys = ["bold", "italic", "underline", "strikethrough"]
        let invalidKeys = style.keys.filter { !validKeys.contains($0) }
        
        if !invalidKeys.isEmpty {
          print("RichTextInput: Warning - applyStyle received invalid style keys: \(invalidKeys.joined(separator: ", "))")
        }
        
        // Apply the style to the current selection
        view.applyStyle(style)
      }
      
      /**
       * clear() -> void
       * Clears all text content from the input.
       * This will trigger an onChange event with empty RichTextValue.
       */
      AsyncFunction("clear") { (view: RichTextInputView) in
        view.clear()
      }
      
      /**
       * focus() -> void
       * Programmatically focuses the text input and shows the keyboard.
       * This will trigger an onFocus event.
       */
      AsyncFunction("focus") { (view: RichTextInputView) in
        view.focus()
      }
      
      /**
       * blur() -> void
       * Programmatically removes focus from the text input and hides the keyboard.
       * This will trigger an onBlur event.
       */
      AsyncFunction("blur") { (view: RichTextInputView) in
        view.blur()
      }
      
      /**
       * getSelection() -> Promise<SelectionData>
       * Returns the current selection range and active formatting styles.
       * Useful for determining which toolbar buttons should be highlighted.
       * 
       * @returns Promise<{ start: number, end: number, activeStyles: RichTextStyle }>
       */
      AsyncFunction("getSelection") { (view: RichTextInputView) -> [String: Any] in
        return view.getSelection()
      }
      
      /**
       * insertText(text: string) -> void
       * Inserts plain text at the current cursor position.
       * The text will inherit the formatting of the current selection.
       * 
       * @param text - The text to insert
       */
      AsyncFunction("insertText") { (view: RichTextInputView, text: String) in
        guard !text.isEmpty else {
          print("RichTextInput: Warning - insertText called with empty string")
          return
        }
        
        view.insertText(text)
      }
      
      /**
       * replaceText(start: number, end: number, text: string) -> void
       * Replaces text in the specified range with new text.
       * 
       * @param start - Start position of the range to replace
       * @param end - End position of the range to replace
       * @param text - The replacement text
       */
      AsyncFunction("replaceText") { (view: RichTextInputView, start: Int, end: Int, text: String) in
        // Validate range parameters
        guard start >= 0 && end >= start else {
          print("RichTextInput: Warning - replaceText called with invalid range: start=\(start), end=\(end)")
          return
        }
        
        view.replaceText(start: start, end: end, text: text)
      }
      
      /**
       * setSelection(start: number, end: number) -> void
       * Sets the selection range programmatically.
       * 
       * @param start - Start position of the selection
       * @param end - End position of the selection (same as start for cursor position)
       */
      AsyncFunction("setSelection") { (view: RichTextInputView, start: Int, end: Int) in
        // Validate range parameters
        guard start >= 0 && end >= start else {
          print("RichTextInput: Warning - setSelection called with invalid range: start=\(start), end=\(end)")
          return
        }
        
        view.setSelection(start: start, end: end)
      }
      
      /**
       * getValue() -> Promise<RichTextValue>
       * Returns the current rich text content as a RichTextValue object.
       * 
       * @returns Promise<{ text: string, spans: RichTextSpan[] }>
       */
      AsyncFunction("getValue") { (view: RichTextInputView) -> [String: Any] in
        return view.getValue()
      }
      
      /**
       * setValue(value: RichTextValue) -> void
       * Sets the rich text content programmatically.
       * This will trigger an onChange event.
       * 
       * @param value - The new rich text value
       */
      AsyncFunction("setValue") { (view: RichTextInputView, value: [String: Any]) in
        // Validate value parameter
        guard value["text"] as? String != nil else {
          print("RichTextInput: Warning - setValue called with invalid value (missing text)")
          return
        }
        
        view.setValue(value)
      }
    }
  }
}

// MARK: - Module Extensions
extension RichTextInputModule {
  
  /**
   * Utility method to validate RichTextValue structure
   * This can be used internally to ensure data integrity
   */
  private func validateRichTextValue(_ value: [String: Any]) -> Bool {
    // Check if text exists and is a string
    guard value["text"] is String else {
      return false
    }
    
    // Check if spans exists and is an array (optional)
    if let spans = value["spans"] {
      guard spans is [[String: Any]] else {
        return false
      }
    }
    
    return true
  }
  
  /**
   * Utility method to validate RichTextStyle structure
   */
  private func validateRichTextStyle(_ style: [String: Any]) -> Bool {
    let validKeys = ["bold", "italic", "underline", "strikethrough"]
    
    // Check that all keys are valid
    for key in style.keys {
      if !validKeys.contains(key) {
        return false
      }
      
      // Check that all values are booleans
      if !(style[key] is Bool) {
        return false
      }
    }
    
    return true
  }
}
