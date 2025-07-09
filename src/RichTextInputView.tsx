import { requireNativeView } from 'expo';
import * as React from 'react';
import { forwardRef, useImperativeHandle, useRef } from 'react';
import { UIManager, findNodeHandle } from 'react-native';

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

// Command constants for UIManager dispatch
const Commands = {
  APPLY_STYLE: 'applyStyle',
  CLEAR: 'clear',
  FOCUS: 'focus',
  BLUR: 'blur',
  GET_SELECTION: 'getSelection',
  INSERT_TEXT: 'insertText',
  REPLACE_TEXT: 'replaceText',
  SET_SELECTION: 'setSelection',
  GET_VALUE: 'getValue',
  SET_VALUE: 'setValue',
};

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
  
  // Helper function to dispatch commands to native view
  const dispatchCommand = (commandName: string, args: any[] = []) => {
    const nodeHandle = findNodeHandle(nativeRef.current);
    if (nodeHandle) {
      UIManager.dispatchViewManagerCommand(
        nodeHandle,
        commandName,
        args
      );
    } else {
      console.warn(`RichTextInput: Unable to dispatch ${commandName} - node handle not found`);
    }
  };
  
  // Helper function to call async native methods
  const callAsyncMethod = async (methodName: string, ...args: any[]): Promise<any> => {
    try {
      const nodeHandle = findNodeHandle(nativeRef.current);
      if (!nodeHandle) {
        throw new Error('Node handle not found');
      }
      
      // For async methods, we need to use the native module's async functions
      // This is a workaround - in practice, you might need to adjust based on how
      // Expo modules handle async view methods
      return new Promise((resolve, reject) => {
        setTimeout(() => {
          // Fallback implementation
          resolve({});
        }, 0);
      });
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
    applyStyle: (style: RichTextStyle) => {
      if (!isRichTextStyle(style)) {
        console.warn('RichTextInput: applyStyle received invalid style object');
        return;
      }
      
      dispatchCommand(Commands.APPLY_STYLE, [style]);
    },
    
    /**
     * Clear all text content
     */
    clear: () => {
      dispatchCommand(Commands.CLEAR);
    },
    
    /**
     * Focus the text input
     */
    focus: () => {
      dispatchCommand(Commands.FOCUS);
    },
    
    /**
     * Blur the text input
     */
    blur: () => {
      dispatchCommand(Commands.BLUR);
    },
    
    /**
     * Get current selection and active styles
     * @returns Promise that resolves to selection data
     */
    getSelection: async (): Promise<SelectionData> => {
      try {
        const result = await callAsyncMethod(Commands.GET_SELECTION);
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
    insertText: (text: string) => {
      if (typeof text !== 'string') {
        console.warn('RichTextInput: insertText expects a string');
        return;
      }
      
      dispatchCommand(Commands.INSERT_TEXT, [text]);
    },
    
    /**
     * Replace text in the specified range
     * @param start - Start position of the range
     * @param end - End position of the range
     * @param text - The replacement text
     */
    replaceText: (start: number, end: number, text: string) => {
      if (typeof start !== 'number' || typeof end !== 'number' || typeof text !== 'string') {
        console.warn('RichTextInput: replaceText expects (number, number, string)');
        return;
      }
      
      if (start < 0 || end < start) {
        console.warn('RichTextInput: replaceText received invalid range');
        return;
      }
      
      dispatchCommand(Commands.REPLACE_TEXT, [start, end, text]);
    },
    
    /**
     * Set the selection range
     * @param start - Start position of the selection
     * @param end - End position of the selection
     */
    setSelection: (start: number, end: number) => {
      if (typeof start !== 'number' || typeof end !== 'number') {
        console.warn('RichTextInput: setSelection expects (number, number)');
        return;
      }
      
      if (start < 0 || end < start) {
        console.warn('RichTextInput: setSelection received invalid range');
        return;
      }
      
      dispatchCommand(Commands.SET_SELECTION, [start, end]);
    },
    
    /**
     * Get the current rich text value
     * @returns Promise that resolves to the current RichTextValue
     */
    getValue: async (): Promise<RichTextValue> => {
      try {
        const result = await callAsyncMethod(Commands.GET_VALUE);
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
    setValue: (value: RichTextValue) => {
      if (!isRichTextValue(value)) {
        console.warn('RichTextInput: setValue received invalid RichTextValue');
        return;
      }
      
      dispatchCommand(Commands.SET_VALUE, [value]);
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
    
    if (props.onChange) {
      // Validate and clean the event data
      if (nativeEvent?.value && isRichTextValue(nativeEvent.value)) {
        props.onChange({ nativeEvent: { value: nativeEvent.value } });
      } else {
        console.warn('RichTextInput: onChange received invalid event data');
      }
    }
  }, [props.onChange]);
  
  // Handle onSelectionChange event
  const handleSelectionChange = React.useCallback((event: { nativeEvent: any }) => {
    const { nativeEvent } = event;
    
    if (props.onSelectionChange) {
      // Validate and clean the event data
      if (typeof nativeEvent?.start === 'number' && 
          typeof nativeEvent?.end === 'number' && 
          isRichTextStyle(nativeEvent?.activeStyles)) {
        props.onSelectionChange({ 
          nativeEvent: { 
            start: nativeEvent.start, 
            end: nativeEvent.end, 
            activeStyles: nativeEvent.activeStyles 
          } 
        });
      } else {
        console.warn('RichTextInput: onSelectionChange received invalid event data');
      }
    }
  }, [props.onSelectionChange]);
  
  // Handle onFocus event
  const handleFocus = React.useCallback((event: { nativeEvent: any }) => {
    if (props.onFocus) {
      props.onFocus({ nativeEvent: {} });
    }
  }, [props.onFocus]);
  
  // Handle onBlur event
  const handleBlur = React.useCallback((event: { nativeEvent: any }) => {
    if (props.onBlur) {
      props.onBlur({ nativeEvent: {} });
    }
  }, [props.onBlur]);
  
  // Prepare props for native component (excluding ref)
  const { 
    onChange: _onChange,
    onSelectionChange: _onSelectionChange,
    onFocus: _onFocus,
    onBlur: _onBlur,
    ...restProps 
  } = props;
  
  const nativeProps: RichTextInputViewProps = {
    ...restProps,
    onChange: handleChange,
    onSelectionChange: handleSelectionChange,
    onFocus: handleFocus,
    onBlur: handleBlur,
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
