import { NativeModule, requireNativeModule } from 'expo';

import { RichTextInputModuleEvents } from './RichTextInput.types';

/**
 * Native module for RichTextInput functionality
 * 
 * This module provides the bridge between JavaScript and native iOS rich text input functionality.
 * The imperative methods are defined directly on the view component and accessible via the view ref.
 */
declare class RichTextInputModule extends NativeModule<RichTextInputModuleEvents> {
  // Module-level functionality can be added here if needed in the future
}

// This call loads the native module object from the JSI.
export default requireNativeModule<RichTextInputModule>('RichTextInput');
