import { requireNativeView } from 'expo';
import * as React from 'react';
import { forwardRef, useImperativeHandle, useRef } from 'react';

import {
  RichTextInputViewProps,
  RichTextInputRef,
  RichTextStyle,
  RichTextValue,
  SelectionData,
  isRichTextValue,
  isRichTextStyle
} from './RichTextInput.types';

// Get the native component
const NativeRichTextInputView: React.ComponentType<RichTextInputViewProps> = 
  requireNativeView('RichTextInput');

/**
 * RichTextInputView component that provides rich text editing capabilities
 * 
 * This component wraps the native RichTextInput view and provides:
 * - Rich text formatting (bold, italic, underline, strikethrough)
 * - Selection tracking and manipulation
 * - Standard TextInput-like props
 * - Imperative API for programmatic control
 * - Event handling for text changes and selection changes
 */
const RichTextInputView = forwardRef<RichTextInputRef, RichTextInputViewProps>((props, ref) => {
  const nativeRef = useRef<any>(null);
  
  // Helper function to call native view methods
  const callNativeMethod = async (methodName: string, ...args: any[]): Promise<any> => {
    try {
      if (!nativeRef.current) {
        throw new Error('Native view ref not available');
      }
      
      // In Expo Modules, AsyncFunctions defined in Views are callable directly on the view ref
      const method = (nativeRef.current as any)[methodName];
      if (typeof method !== 'function') {
        throw new Error(`Method ${methodName} not found on native view`);
      }
      
      return await method(...args);
    } catch (error) {
      console.warn(`RichTextInput: ${methodName} failed:`, error);
      throw error;
    }
  };
  
  // Expose imperative methods through ref
  useImperativeHandle(ref, () => ({
    /**
     * Apply formatting style to the current selection
     * @param style - The formatting style to apply
     */
    applyStyle: async (style: RichTextStyle) => {
      if (!isRichTextStyle(style)) {
        console.warn('RichTextInput: applyStyle received invalid style object');
        return;
      }
      
      try {
        await callNativeMethod('applyStyle', style);
      } catch (error) {
        console.warn('RichTextInput: applyStyle failed:', error);
      }
    },
    
    /**
     * Clear all text content
     */
    clear: async () => {
      try {
        await callNativeMethod('clear');
      } catch (error) {
        console.warn('RichTextInput: clear failed:', error);
      }
    },
    
    /**
     * Focus the text input
     */
    focus: async () => {
      try {
        await callNativeMethod('focus');
      } catch (error) {
        console.warn('RichTextInput: focus failed:', error);
      }
    },
    
    /**
     * Blur the text input
     */
    blur: async () => {
      try {
        await callNativeMethod('blur');
      } catch (error) {
        console.warn('RichTextInput: blur failed:', error);
      }
    },
    
    /**
     * Get current selection and active styles
     * @returns Promise that resolves to selection data
     */
    getSelection: async (): Promise<SelectionData> => {
      try {
        const result = await callNativeMethod('getSelection');
        if (result && typeof result === 'object') {
          return {
            start: result.start ?? 0,
            end: result.end ?? 0,
            activeStyles: result.activeStyles ?? {}
          };
        }
        
        // Return default selection if native method fails
        return {
          start: 0,
          end: 0,
          activeStyles: {}
        };
      } catch (error) {
        console.warn('RichTextInput: getSelection failed:', error);
        return {
          start: 0,
          end: 0,
          activeStyles: {}
        };
      }
    },
    
    /**
     * Insert text at the current cursor position
     * @param text - The text to insert
     */
    insertText: async (text: string) => {
      if (typeof text !== 'string') {
        console.warn('RichTextInput: insertText expects a string');
        return;
      }
      
      try {
        await callNativeMethod('insertText', text);
      } catch (error) {
        console.warn('RichTextInput: insertText failed:', error);
      }
    },
    
    /**
     * Replace text in the specified range
     * @param start - Start position of the range
     * @param end - End position of the range
     * @param text - The replacement text
     */
    replaceText: async (start: number, end: number, text: string) => {
      if (typeof start !== 'number' || typeof end !== 'number' || typeof text !== 'string') {
        console.warn('RichTextInput: replaceText expects (number, number, string)');
        return;
      }
      
      if (start < 0 || end < start) {
        console.warn('RichTextInput: replaceText received invalid range');
        return;
      }
      
      try {
        await callNativeMethod('replaceText', start, end, text);
      } catch (error) {
        console.warn('RichTextInput: replaceText failed:', error);
      }
    },
    
    /**
     * Set the selection range
     * @param start - Start position of the selection
     * @param end - End position of the selection
     */
    setSelection: async (start: number, end: number) => {
      if (typeof start !== 'number' || typeof end !== 'number') {
        console.warn('RichTextInput: setSelection expects (number, number)');
        return;
      }
      
      if (start < 0 || end < start) {
        console.warn('RichTextInput: setSelection received invalid range');
        return;
      }
      
      try {
        await callNativeMethod('setSelection', start, end);
      } catch (error) {
        console.warn('RichTextInput: setSelection failed:', error);
      }
    },
    
    /**
     * Get the current rich text value
     * @returns Promise that resolves to the current RichTextValue
     */
    getValue: async (): Promise<RichTextValue> => {
      try {
        const result = await callNativeMethod('getValue');
        if (result && isRichTextValue(result)) {
          return result;
        }
        
        // Return default value if native method fails
        return {
          text: '',
          spans: []
        };
      } catch (error) {
        console.warn('RichTextInput: getValue failed:', error);
        return {
          text: '',
          spans: []
        };
      }
    },
    
    /**
     * Set the rich text value
     * @param value - The new rich text value
     */
    setValue: async (value: RichTextValue) => {
      if (!isRichTextValue(value)) {
        console.warn('RichTextInput: setValue received invalid RichTextValue');
        return;
      }
      
      try {
        await callNativeMethod('setValue', value);
      } catch (error) {
        console.warn('RichTextInput: setValue failed:', error);
      }
    }
  }), []);
  
  // Validate props
  React.useEffect(() => {
    if (props.initialValue && !isRichTextValue(props.initialValue)) {
      console.warn('RichTextInput: initialValue prop is not a valid RichTextValue');
    }
  }, [props.initialValue]);
  
  // Handle onChange event to ensure proper data structure
  const handleChange = React.useCallback((event: { nativeEvent: any }) => {
    const { nativeEvent } = event;
    
    // Validate and clean the event data
    if (nativeEvent?.value && isRichTextValue(nativeEvent.value)) {
      const cleanEvent = { nativeEvent: { value: nativeEvent.value } };
      
      // Call both the new event handler and convenience prop for backward compatibility
      if (props.onRichTextChange) {
        props.onRichTextChange(cleanEvent);
      }
      if (props.onChange) {
        props.onChange(cleanEvent);
      }
    } else {
      console.warn('RichTextInput: onChange received invalid event data');
    }
  }, [props.onRichTextChange, props.onChange]);
  
  // Handle onSelectionChange event
  const handleSelectionChange = React.useCallback((event: { nativeEvent: any }) => {
    const { nativeEvent } = event;
    
    // Validate and clean the event data
    if (typeof nativeEvent?.start === 'number' && 
        typeof nativeEvent?.end === 'number' && 
        isRichTextStyle(nativeEvent?.activeStyles)) {
      const cleanEvent = { 
        nativeEvent: { 
          start: nativeEvent.start, 
          end: nativeEvent.end, 
          activeStyles: nativeEvent.activeStyles 
        } 
      };
      
      // Call both the new event handler and convenience prop for backward compatibility
      if (props.onRichTextSelectionChange) {
        props.onRichTextSelectionChange(cleanEvent);
      }
      if (props.onSelectionChange) {
        props.onSelectionChange(cleanEvent);
      }
    } else {
      console.warn('RichTextInput: onSelectionChange received invalid event data:', nativeEvent);
    }
  }, [props.onRichTextSelectionChange, props.onSelectionChange]);
  
  // Handle onFocus event
  const handleFocus = React.useCallback((event: { nativeEvent: any }) => {
    const cleanEvent = { nativeEvent: {} };
    
    // Call both the new event handler and convenience prop for backward compatibility
    if (props.onRichTextFocus) {
      props.onRichTextFocus(cleanEvent);
    }
    if (props.onFocus) {
      props.onFocus(cleanEvent);
    }
  }, [props.onRichTextFocus, props.onFocus]);
  
  // Handle onBlur event
  const handleBlur = React.useCallback((event: { nativeEvent: any }) => {
    const cleanEvent = { nativeEvent: {} };
    
    // Call both the new event handler and convenience prop for backward compatibility
    if (props.onRichTextBlur) {
      props.onRichTextBlur(cleanEvent);
    }
    if (props.onBlur) {
      props.onBlur(cleanEvent);
    }
  }, [props.onRichTextBlur, props.onBlur]);
  
  // Prepare props for native component (excluding both old and new event handlers)
  const { 
    onChange: _onChange,
    onSelectionChange: _onSelectionChange,
    onFocus: _onFocus,
    onBlur: _onBlur,
    onRichTextChange: _onRichTextChange,
    onRichTextSelectionChange: _onRichTextSelectionChange,
    onRichTextFocus: _onRichTextFocus,
    onRichTextBlur: _onRichTextBlur,
    ...restProps 
  } = props;
  
  const nativeProps: any = {
    ...restProps,
    // Use the new event names that match the native implementation
    onRichTextChange: handleChange,
    onRichTextSelectionChange: handleSelectionChange,
    onRichTextFocus: handleFocus,
    onRichTextBlur: handleBlur,
  };
  
  return (
    <NativeRichTextInputView
      ref={nativeRef}
      {...(nativeProps as any)}
    />
  );
});

RichTextInputView.displayName = 'RichTextInputView';

export default RichTextInputView;
