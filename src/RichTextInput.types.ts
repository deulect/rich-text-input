import type { StyleProp, ViewStyle, TextStyle } from 'react-native';

// MARK: - Core Rich Text Data Structures

/**
 * Represents the styling attributes for rich text
 */
export interface RichTextStyle {
  bold?: boolean;
  italic?: boolean;
  underline?: boolean;
  strikethrough?: boolean;
}

/**
 * Represents a formatting span in rich text
 */
export interface RichTextSpan {
  start: number;
  end: number;
  attributes: RichTextStyle;
}

/**
 * Represents rich text content with formatting information
 */
export interface RichTextValue {
  text: string;
  spans: RichTextSpan[];
}

// MARK: - Event Payload Types

/**
 * Event payload for text content changes
 */
export interface ChangeEventPayload {
  value: RichTextValue;
}

/**
 * Event payload for selection changes
 */
export interface SelectionChangeEventPayload {
  start: number;
  end: number;
  activeStyles: RichTextStyle;
}

/**
 * Event payload for focus events
 */
export interface FocusEventPayload {
  // Currently empty, can be extended in the future
}

/**
 * Event payload for blur events
 */
export interface BlurEventPayload {
  // Currently empty, can be extended in the future
}

// MARK: - Module Events

/**
 * Events that the RichTextInput module can emit
 */
export interface RichTextInputModuleEvents {
  onChange: (params: ChangeEventPayload) => void;
  onSelectionChange: (params: SelectionChangeEventPayload) => void;
  onFocus: (params: FocusEventPayload) => void;
  onBlur: (params: BlurEventPayload) => void;
  [key: string]: (...args: any[]) => void;
}

// MARK: - Component Props

/**
 * Props for the RichTextInputView component
 */
export interface RichTextInputViewProps {
  // Core rich text props
  initialValue?: RichTextValue | null;
  
  // Event handlers
  onChange?: (event: { nativeEvent: ChangeEventPayload }) => void;
  onSelectionChange?: (event: { nativeEvent: SelectionChangeEventPayload }) => void;
  onFocus?: (event: { nativeEvent: FocusEventPayload }) => void;
  onBlur?: (event: { nativeEvent: BlurEventPayload }) => void;
  
  // Standard TextInput-like props
  placeholder?: string;
  editable?: boolean;
  multiline?: boolean;
  maxLength?: number;
  autoCapitalize?: 'none' | 'sentences' | 'words' | 'characters';
  autoCorrect?: boolean;
  spellCheck?: boolean;
  keyboardType?: 'default' | 'number-pad' | 'decimal-pad' | 'email-address' | 'url' | 'phone-pad';
  returnKeyType?: 'default' | 'done' | 'go' | 'next' | 'search' | 'send';
  
  // Style props
  style?: StyleProp<ViewStyle>;
  textStyle?: StyleProp<TextStyle>;
}

// MARK: - Imperative Methods

/**
 * Selection data returned by getSelection method
 */
export interface SelectionData {
  start: number;
  end: number;
  activeStyles: RichTextStyle;
}

/**
 * Imperative methods available on the RichTextInput ref
 */
export interface RichTextInputRef {
  /**
   * Apply formatting style to the current selection
   */
  applyStyle: (style: RichTextStyle) => void;
  
  /**
   * Clear all text content
   */
  clear: () => void;
  
  /**
   * Focus the text input
   */
  focus: () => void;
  
  /**
   * Blur the text input
   */
  blur: () => void;
  
  /**
   * Get current selection and active styles
   */
  getSelection: () => Promise<SelectionData>;
  
  /**
   * Insert text at the current cursor position
   */
  insertText: (text: string) => void;
  
  /**
   * Replace text in the specified range
   */
  replaceText: (start: number, end: number, text: string) => void;
  
  /**
   * Set the selection range
   */
  setSelection: (start: number, end: number) => void;
  
  /**
   * Get the current rich text value
   */
  getValue: () => Promise<RichTextValue>;
  
  /**
   * Set the rich text value
   */
  setValue: (value: RichTextValue) => void;
}

// MARK: - Additional Props

/**
 * Props for the main RichTextInput component (extends the view props)
 */
export interface RichTextInputProps extends RichTextInputViewProps {
  // Additional props can be added here for the main component
}

// MARK: - Utility Types

/**
 * Type guard to check if a value is a valid RichTextValue
 */
export function isRichTextValue(value: any): value is RichTextValue {
  return (
    typeof value === 'object' &&
    value !== null &&
    typeof value.text === 'string' &&
    Array.isArray(value.spans) &&
    value.spans.every((span: any) => 
      typeof span === 'object' &&
      span !== null &&
      typeof span.start === 'number' &&
      typeof span.end === 'number' &&
      typeof span.attributes === 'object' &&
      span.attributes !== null
    )
  );
}

/**
 * Type guard to check if a value is a valid RichTextStyle
 */
export function isRichTextStyle(value: any): value is RichTextStyle {
  return (
    typeof value === 'object' &&
    value !== null &&
    (value.bold === undefined || typeof value.bold === 'boolean') &&
    (value.italic === undefined || typeof value.italic === 'boolean') &&
    (value.underline === undefined || typeof value.underline === 'boolean') &&
    (value.strikethrough === undefined || typeof value.strikethrough === 'boolean')
  );
}

/**
 * Helper function to create an empty RichTextValue
 */
export function createEmptyRichTextValue(): RichTextValue {
  return {
    text: '',
    spans: []
  };
}

/**
 * Helper function to create a RichTextValue from plain text
 */
export function createRichTextValue(text: string, spans: RichTextSpan[] = []): RichTextValue {
  return {
    text,
    spans
  };
}

/**
 * Helper function to create a RichTextStyle
 */
export function createRichTextStyle(
  bold?: boolean,
  italic?: boolean,
  underline?: boolean,
  strikethrough?: boolean
): RichTextStyle {
  return {
    bold,
    italic,
    underline,
    strikethrough
  };
}
