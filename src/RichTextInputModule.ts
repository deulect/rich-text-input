import { NativeModule, requireNativeModule } from 'expo';

import { RichTextInputModuleEvents } from './RichTextInput.types';

declare class RichTextInputModule extends NativeModule<RichTextInputModuleEvents> {
  PI: number;
  hello(): string;
  setValueAsync(value: string): Promise<void>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<RichTextInputModule>('RichTextInput');
