import { NativeModule, requireNativeModule } from 'expo';

import { RichTextInputModuleEvents } from './RichTextInput.types';

/**
 * Native module for RichTextInput functionality
 * 
 * This module provides the bridge between JavaScript and native iOS rich text input functionality.
 * It handles imperative methods that operate on specific view instances.
 */
declare class RichTextInputModule extends NativeModule<RichTextInputModuleEvents> {
  // Note: Most imperative methods are called directly on view instances through the native view manager
  // This module primarily handles events and any global functionality
}

// This call loads the native module object from the JSI.
export default requireNativeModule<RichTextInputModule>('RichTextInput');
